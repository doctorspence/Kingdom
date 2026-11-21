class_name Enemy
extends CharacterBody3D
## A melee enemy. Its numbers and attacks come from an EnemyData file.
##
## Behavior, one state at a time:
##   IDLE     standing guard, watching for players
##   CHASE    closing in, circling while waiting to attack
##   ATTACK   a telegraphed attack (white glint = parryable, red glow = unblockable)
##   STAGGER  knocked off balance (poise broken)
##   PARRIED  reeling from a parry: open to a riposte
##   RIPOSTED knocked down by a riposte
##   RETURN   walking home after you ran too far away
##   DEAD     dead until someone rests at a shrine
##   CALL     blowing a horn / howling for help (callers only)
##
## Multiplayer: the host runs every enemy and shares its state. Players report
## their hits to the host; the host sends enemy blows to the player's own game,
## which decides whether it really landed ("favor the dodger").

signal died

enum State { IDLE, CHASE, ATTACK, STAGGER, PARRIED, RIPOSTED, RETURN, DEAD, CALL }

const HEALTH_BAR_SHOW_TIME := 6.0
## Group scaling (DESIGN.md 8.4): extra health and poise per extra player.
const HEALTH_PER_EXTRA_PLAYER := 0.6
const POISE_PER_EXTRA_PLAYER := 0.25
## At most this many enemies attack the same player at once; the rest circle.
const MAX_ATTACKERS := 2
## Night makes everyone harder to see (set by the day/night cycle).
static var sight_mult := 1.0
## This enemy sees farther or shorter than normal (camp Watchfires level 3
## shorten raiders' sight).
var sight_scale := 1.0

@export var data: EnemyData
## Optional patrol route (world points). Empty = stand guard.
@export var patrol_points := PackedVector3Array()

var state := State.IDLE
var health := 100.0
var max_health := 100.0
var max_poise := 40.0
var target: Player

## Shared with everyone (see the Sync node in marauder.tscn).
var net_pos := Vector3.ZERO
var net_yaw := 0.0
var net_anim := &""
var net_anim_speed := 1.0
var net_anim_count := 0
var net_state := 0
var net_overlay := ""

var _state_time := 0.0
var _attack := AttackRunner.new()
var _cooldown := 0.0
var _poise := 40.0
var _poise_timer := 0.0
var _hitstop := 0.0
var _spawn: Transform3D
var _strafe_dir := 1.0
var _telegraphed := false
var _bar_timer := 0.0
var _weapon: Node3D
var _party_size := 1
var effects := Effects.new()
## Threat table (host only): player network id -> threat.
var threat := {}
var _taunt_peer := 0
var _taunt_time := 0.0
var _threat_check := 0.0
var _patrol_i := 0
var _called := false
var _shot := false  # this attack already loosed its arrow
var _fury := false
var _phase := 1
var _fire_dropped := false
var net_phase := 1
var _roaring := false
var _engaged := false
var _adds: Array[Node] = []
## Boss: true while it is fighting (shared so fog gates and bars work for everyone).
var net_engaged := false

@onready var model: CharacterModel = $Visual


func _ready() -> void:
	add_to_group(&"hittable")
	add_to_group(&"lock_targets")
	add_to_group(&"enemies")
	add_to_group(&"respawn_on_rest")
	if data.boss:
		add_to_group(&"bosses")
	_spawn = global_transform
	global_basis = Basis.IDENTITY
	model.face_instantly(-_spawn.basis.z)
	model.scale = Vector3.ONE * data.scale
	if model.audio:
		model.audio.voice = &"boss" if data.boss else (&"beast" if "hound" in String(data.id) else &"raider")
	if data.weapon_scene:
		_weapon = data.weapon_scene.instantiate()
		model.attach_to_hand(_weapon, "r")
	if data.offhand_scene:
		model.attach_to_hand(data.offhand_scene.instantiate(), "l")
	max_health = data.max_health
	max_poise = data.poise
	_reset()
	net_pos = global_position


func _is_host() -> bool:
	return multiplayer.is_server()


## The attacks in use right now (bosses change them in phase 2).
func _attacks() -> Array[AttackData]:
	return data.phase2_attacks if _phase == 2 and not data.phase2_attacks.is_empty() else data.attacks


func _reset() -> void:
	health = max_health
	_poise = max_poise
	_cooldown = 0.5
	target = null
	effects.clear_all()
	threat.clear()
	_taunt_time = 0.0
	_called = false
	_fury = false
	_phase = 1
	net_engaged = false
	_set_engaged(false)
	_free_adds()
	_patrol_i = 0
	collision_layer = 4
	_set_state(State.IDLE)
	model.set_overlay("")
	model.play(model.idle_anim, 0.2)


# --- Used by players, the HUD and shrines --------------------------------------

func get_lock_point() -> Vector3:
	return global_position + Vector3.UP * data.lock_height * data.scale


func can_be_locked() -> bool:
	return state != State.DEAD


func hit_radius() -> float:
	return 0.4 * data.scale


func can_be_riposted() -> bool:
	return state == State.PARRIED


func health_ratio() -> float:
	return health / max_health


## Show the health bar above its head? (When hurt recently.)
func wants_health_bar() -> bool:
	return state != State.DEAD and (_bar_timer > 0.0 or health < max_health)


func bar_point() -> Vector3:
	return global_position + Vector3.UP * data.bar_height * data.scale


func display_name() -> String:
	return data.display_name


func armor() -> float:
	return data.armor


func is_bleeding() -> bool:
	return effects.buildup[Effects.Status.BLEED] > 0.0


# --- Threat and taunts ------------------------------------------------------------

## Force this enemy to fight `peer`'s player for a while (Challenge, Rallying Bellow).
func taunt(peer: int, duration: float) -> void:
	if _is_host():
		_taunt(peer, duration)
	else:
		_net_taunt.rpc_id(1, peer, duration)


@rpc("any_peer", "call_remote", "reliable")
func _net_taunt(peer: int, duration: float) -> void:
	if _is_host():
		_taunt(peer, duration)


func _taunt(peer: int, duration: float) -> void:
	if state == State.DEAD:
		return
	var top := 0.0
	for v in threat.values():
		top = maxf(top, v)
	threat[peer] = top + 50.0
	_taunt_peer = peer
	_taunt_time = duration
	var p := _player_of_peer(peer)
	if p:
		target = p
		if state == State.IDLE or state == State.RETURN:
			_set_state(State.CHASE)


## A timed buff or curse on this enemy (Hex). The host keeps it.
func apply_effect(id: StringName, duration: float, values: Dictionary) -> void:
	if _is_host():
		effects.add_mod(id, duration, values)
	else:
		_net_effect.rpc_id(1, id, duration, values)


@rpc("any_peer", "call_remote", "reliable")
func _net_effect(id: StringName, duration: float, values: Dictionary) -> void:
	if _is_host() and state != State.DEAD:
		effects.add_mod(id, duration, values)


## Multiply one player's threat (Flare halves it, Feint drops it).
func scale_threat(peer: int, mult: float) -> void:
	if _is_host():
		threat[peer] = threat.get(peer, 0.0) * mult
	else:
		_net_scale_threat.rpc_id(1, peer, mult)


@rpc("any_peer", "call_remote", "reliable")
func _net_scale_threat(peer: int, mult: float) -> void:
	if _is_host():
		threat[peer] = threat.get(peer, 0.0) * mult


## Host: healing someone this enemy is fighting makes it a little angry at the healer.
func on_ally_healed(healed_peer: int, healer_peer: int, amount: float) -> void:
	if target and is_fighting() and target.get_multiplayer_authority() == healed_peer:
		threat[healer_peer] = threat.get(healer_peer, 0.0) + amount * 0.5


func add_threat(peer: int, amount: float) -> void:
	threat[peer] = threat.get(peer, 0.0) + amount


## Normal enemies switch to whoever has the most threat once they pass the
## current target by 10%. A taunt overrides this while it lasts.
func _update_target(delta: float) -> void:
	_taunt_time -= delta
	if _taunt_time > 0.0:
		var forced := _player_of_peer(_taunt_peer)
		if forced and not forced.is_out_of_fight():
			target = forced
			return
	_threat_check -= delta
	if _threat_check > 0.0:
		return
	# Bosses only switch at the start of an attack (see _boss_retarget).
	if data.boss and target and not target.is_out_of_fight():
		return
	_threat_check = 0.5
	var best: Player
	var best_threat := 0.0
	for n in get_tree().get_nodes_in_group(&"player"):
		var p := n as Player
		if p == null or p.is_out_of_fight():
			continue
		var t: float = threat.get(p.get_multiplayer_authority(), 0.0)
		if t > best_threat:
			best_threat = t
			best = p
	if best == null or best == target:
		return
	var current: float = threat.get(target.get_multiplayer_authority(), 0.0) if target else 0.0
	if target == null or target.is_out_of_fight() or best_threat > current * 1.1:
		target = best


## Is it fighting someone right now? (Resting is blocked near angry enemies.)
func is_fighting() -> bool:
	return target != null and state in [State.CHASE, State.ATTACK, State.STAGGER, State.PARRIED, State.RIPOSTED]


## Tougher with more players (host only; health keeps the same percentage).
func set_party_size(count: int) -> void:
	if data.boss and _engaged:
		return  # the arena's head count was taken when the fight began
	_party_size = count
	var ratio := health / max_health
	var per := data.boss_health_per_player if data.boss else HEALTH_PER_EXTRA_PLAYER
	max_health = data.max_health * (1.0 + per * (count - 1))
	max_poise = data.poise * (1.0 + POISE_PER_EXTRA_PLAYER * (count - 1))
	health = max_health * ratio


## A player is starting a riposte on us: hold still for it.
func begin_riposte(attacker: Node3D) -> void:
	if _is_host():
		_start_riposted(attacker.global_position)
	else:
		_net_begin_riposte.rpc_id(1, attacker.global_position)


@rpc("any_peer", "call_remote", "reliable")
func _net_begin_riposte(attacker_pos: Vector3) -> void:
	if _is_host():
		_start_riposted(attacker_pos)


func _start_riposted(attacker_pos: Vector3) -> void:
	_set_state(State.RIPOSTED)
	model.set_overlay("")
	model.face_instantly(attacker_pos - global_position)
	model.play(CharacterModel.ANIM_STAGGER, 0.1, 0.5, true)


## Someone rested at a shrine: come back to life at the starting spot (host only).
func reset_from_rest() -> void:
	if not _is_host():
		return
	global_position = _spawn.origin
	velocity = Vector3.ZERO
	model.face_instantly(-_spawn.basis.z)
	reset_physics_interpolation()
	_reset()


## A player's weapon reached us. On the host this is applied for real; on a
## friend's machine we show the hit straight away and ask the host to apply it.
func receive_hit(hit: HitInfo) -> HitInfo.Result:
	if state == State.DEAD:
		return HitInfo.Result.IGNORED
	if _is_host():
		_show_hit(hit.damage, hit.is_crit, hit.origin)
		_net_hit_fx.rpc(hit.damage, hit.is_crit, hit.origin, multiplayer.get_unique_id())
		return _apply_hit(hit)
	_show_hit(hit.damage, hit.is_crit, hit.origin)
	_hitstop = maxf(_hitstop, hit.hit_stop)
	_net_hit.rpc_id(1, hit.to_dict())
	return HitInfo.Result.KILLED if health - hit.damage <= 0.0 else HitInfo.Result.HIT


@rpc("any_peer", "call_remote", "reliable")
func _net_hit(hit_data: Dictionary) -> void:
	if not _is_host() or state == State.DEAD:
		return
	var sender := multiplayer.get_remote_sender_id()
	var hit := HitInfo.from_dict(hit_data)
	hit.attacker = _player_of_peer(sender)
	# Show it on the host's screen and everyone else's (the attacker already saw it).
	_show_hit(hit.damage, hit.is_crit, hit.origin)
	_net_hit_fx.rpc(hit.damage, hit.is_crit, hit.origin, sender)
	_apply_hit(hit)


@rpc("authority", "call_remote", "unreliable")
func _net_hit_fx(damage: float, is_crit: bool, origin: Vector3, skip_peer: int) -> void:
	if multiplayer.get_unique_id() != skip_peer:
		_show_hit(damage, is_crit, origin)


func _show_hit(damage: float, is_crit: bool, origin: Vector3) -> void:
	var chest := global_position + Vector3.UP * 1.3 * data.scale
	var away := global_position - origin
	away.y = 0.0
	CombatFx.blood(chest, away.normalized(), 1.6 if is_crit else 1.0)
	CombatFx.damage_number(chest + Vector3.UP * 0.6, damage,
			CombatFx.NumberKind.CRIT if is_crit else CombatFx.NumberKind.NORMAL)
	_bar_timer = HEALTH_BAR_SHOW_TIME


## Host only: take the damage, poise and state changes.
func _apply_hit(hit: HitInfo) -> HitInfo.Result:
	# Shield-bearers block blows from the front when they aren't swinging.
	if data.block_chance > 0.0 and not hit.is_riposte and state in [State.IDLE, State.CHASE, State.RETURN]:
		var from := hit.origin - global_position
		from.y = 0.0
		if rad_to_deg(model.forward().angle_to(from)) < 60.0 and randf() < data.block_chance:
			hit.damage *= 0.15
			hit.poise_damage *= 0.5
			_status_fx("Blocked", 0.0)
			_net_status_fx.rpc("Blocked", 0.0)
			CombatFx.sparks(global_position + Vector3.UP * 1.3 + model.forward() * 0.5, from)
			model.play(&"ual2/Sword_Block", 0.05, 1.5, true)
	var damage := hit.damage * effects.damage_taken_mult()
	health = maxf(0.0, health - damage)
	_bar_timer = HEALTH_BAR_SHOW_TIME
	_hitstop = maxf(_hitstop, hit.hit_stop)
	if hit.attacker is Player:
		add_threat(hit.attacker.get_multiplayer_authority(), damage * hit.threat_mult)
		if target == null:
			target = hit.attacker
	if hit.slow > 0.0:
		effects.add_mod(&"slow", hit.slow_time, {"move": 1.0 - hit.slow})
	if health > 0.0:
		_apply_status(hit.status, hit.status_amount)
	if health <= 0.0:
		_die()
		return HitInfo.Result.KILLED
	if state == State.RIPOSTED:
		return HitInfo.Result.HIT  # stays down for the rest of the knockdown
	if data.boss:
		_boss_after_hit(hit)
		return HitInfo.Result.HIT
	_poise -= hit.poise_damage
	_poise_timer = data.poise_regen_delay
	if _poise <= 0.0:
		_poise = max_poise
		_set_state(State.STAGGER)
		model.set_overlay("")
		model.play_fitted(CharacterModel.ANIM_STAGGER, data.stagger_time, 0.05)
	elif state != State.ATTACK:
		model.play(CharacterModel.ANIM_HIT, 0.05, 1.0, true)
		if state == State.IDLE:
			if target:
				_aggro(target)
	return HitInfo.Result.HIT


## Host: status buildup from a hit; bursts when the meter fills.
func _apply_status(status: Effects.Status, amount: float) -> void:
	var triggered := effects.add_buildup(status, amount)
	if triggered == Effects.Status.NONE:
		return
	var burst := 0.0
	var label := ""
	match triggered:
		Effects.Status.BLEED:
			burst = max_health * Effects.BLEED_BURST
			label = "Bleed!"
		Effects.Status.POISON:
			label = "Poisoned!"
		Effects.Status.FROST:
			burst = max_health * Effects.FROST_BURST
			label = "Frostbite!"
	health = maxf(0.0, health - burst)
	_status_fx(label, burst)
	_net_status_fx.rpc(label, burst)


func _status_fx(label: String, burst: float) -> void:
	var head := global_position + Vector3.UP * 2.4 * data.scale
	CombatFx.word(head, label)
	if burst > 0.0:
		CombatFx.damage_number(head + Vector3.UP * 0.3, burst, CombatFx.NumberKind.CRIT)
		CombatFx.blood(global_position + Vector3.UP * 1.3 * data.scale, Vector3.UP, 2.0)


@rpc("authority", "call_remote", "unreliable")
func _net_status_fx(label: String, burst: float) -> void:
	_status_fx(label, burst)


## Build the hit for one of our attacks (used by players' machines too).
func make_hit(attack_index: int) -> HitInfo:
	var a: AttackData = _attacks()[clampi(attack_index, 0, _attacks().size() - 1)]
	var hit := HitInfo.new()
	hit.attacker = self
	hit.attack = a
	hit.origin = global_position
	hit.damage = a.base_damage * (1.3 if _fury else 1.0) * effects.product("damage_dealt")
	hit.status = a.status
	hit.status_amount = a.status_amount
	hit.poise_damage = a.base_poise_damage
	hit.parryable = a.parryable
	hit.slow = a.slow
	hit.slow_time = a.slow_time
	hit.unblockable = a.unblockable
	hit.hit_stop = a.hit_stop
	hit.attacker_level = data.level
	return hit


## Could this attack reach that player from where we are? (`margin` forgives lag.)
func reaches(p: Node3D, attack_index: int, margin: float) -> bool:
	var a: AttackData = _attacks()[clampi(attack_index, 0, _attacks().size() - 1)]
	var to := p.global_position - global_position
	to.y = 0.0
	return to.length() <= a.reach + hit_radius() + margin


## A player's game tells the host what happened when we swung at them.
@rpc("any_peer", "call_remote", "reliable")
func report_hit_result(result: int) -> void:
	if not _is_host():
		return
	_on_hit_result(result as HitInfo.Result)


func _on_hit_result(result: HitInfo.Result) -> void:
	match result:
		HitInfo.Result.PARRIED:
			if data.boss and state == State.ATTACK:
				_boss_parried()
			elif state == State.ATTACK:
				_set_state(State.PARRIED)
				model.set_overlay("")
				model.play_fitted(CharacterModel.ANIM_GUARD_BREAK, data.riposte_window, 0.05)
		HitInfo.Result.HIT, HitInfo.Result.BLOCKED, HitInfo.Result.KILLED:
			if state == State.ATTACK:
				_hitstop = maxf(_hitstop, _attack.attack.hit_stop)


# --- Main loop ----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not _is_host():
		_mirror(delta)
		return
	_bar_timer -= delta
	if _hitstop > 0.0:
		_hitstop -= delta
		model.hold(true)
		_write_net_state()
		return
	model.hold(false)
	_state_time += delta
	_cooldown -= delta
	_poise_timer -= delta
	if _poise_timer <= 0.0:
		_poise = max_poise
	if state != State.DEAD:
		var dot := effects.tick(delta)
		if dot > 0.0:
			health = maxf(0.0, health - max_health * dot)
			_bar_timer = HEALTH_BAR_SHOW_TIME
			if health <= 0.0:
				_die()
	if state in [State.CHASE, State.ATTACK]:
		_update_target(delta)

	match state:
		State.IDLE:
			_state_idle(delta)
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack(delta)
		State.STAGGER:
			_state_wait(delta, data.stagger_time)
		State.PARRIED:
			_state_wait(delta, data.stance_time if data.boss else data.riposte_window)
		State.RIPOSTED:
			_state_wait(delta, data.riposted_time)
		State.RETURN:
			_state_return(delta)
		State.CALL:
			_state_call(delta)
		State.DEAD:
			_move(Vector3.ZERO, delta)
	_write_net_state()


func _write_net_state() -> void:
	var now := target != null and state in [State.CHASE, State.ATTACK, State.STAGGER, State.PARRIED, State.RIPOSTED, State.CALL]
	if data.boss and now != _engaged:
		_set_engaged(now)
	net_phase = _phase
	net_pos = global_position
	net_yaw = model.rotation.y
	net_anim = model.current_anim()
	net_anim_speed = model.get_speed()
	net_anim_count = model.play_count
	net_state = state
	net_overlay = model.overlay_kind()


## On a friend's machine: copy what the host says.
func _mirror(delta: float) -> void:
	_bar_timer -= delta
	if global_position.distance_to(net_pos) > 4.0:
		global_position = net_pos
	else:
		global_position = global_position.lerp(net_pos, 1.0 - exp(-18.0 * delta))
	model.rotation.y = lerp_angle(model.rotation.y, net_yaw, 1.0 - exp(-18.0 * delta))
	model.mirror(net_anim, net_anim_speed, net_anim_count)
	state = net_state as State
	if net_phase == 2 and not _tinted:
		_tinted = true
		model.set_tint(Color(1.0, 0.55, 0.25))
	collision_layer = 0 if state == State.DEAD else 4
	if net_overlay != model.overlay_kind():
		model.set_overlay(net_overlay, Color(1.0, 0.1, 0.05, 0.35))


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0


func _state_idle(delta: float) -> void:
	# Walk the patrol route, or stand guard.
	if patrol_points.size() >= 2:
		var goal := patrol_points[_patrol_i]
		var to := goal - global_position
		to.y = 0.0
		if to.length() < 1.0:
			_patrol_i = (_patrol_i + 1) % patrol_points.size()
		else:
			model.turn_toward(to, deg_to_rad(data.turn_speed) * 0.5 * delta)
			_move(to.normalized() * data.walk_speed, delta)
			model.update_locomotion(Vector3(velocity.x, 0, velocity.z).length(), false, true)
	else:
		_move(Vector3.ZERO, delta)
		model.play(model.idle_anim, 0.25)
	var p := _find_player()
	if p:
		_aggro(p)


## Noticed a player: callers raise the alarm first.
func _aggro(p: Player) -> void:
	target = p
	if data.caller and not _called:
		_called = true
		model.face_instantly(p.global_position - global_position)
		model.play(data.call_anim, 0.15, 1.0, true)
		_set_state(State.CALL)
		return
	_set_state(State.CHASE)


func _state_call(delta: float) -> void:
	_move(Vector3.ZERO, delta)
	if _roaring:
		if _state_time >= data.call_time:
			_finish_roar()
		return
	if _state_time < data.call_time:
		return
	# Everyone of its kind nearby joins the fight.
	for n in get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Enemy
		if e and e != self and (e.data.id == data.id or (data.call_family != &"" and e.data.call_family == data.call_family)) and e.state in [State.IDLE, State.RETURN] \
				and e.global_position.distance_to(global_position) <= data.call_range:
			e._called = true  # one horn is enough
			e.target = target
			e._set_state(State.CHASE)
	_set_state(State.CHASE)


## How many enemies are swinging at this player right now.
func _attackers_on(p: Player) -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group(&"enemies"):
		if e != self and (e as Enemy).state == State.ATTACK and (e as Enemy).target == p and (e as Enemy).data.keep_distance <= 0.0:
			n += 1
	return n


## A nearby ally died: martyr's fury (faster, harder hits, shorter pauses).
func _enrage() -> void:
	if _fury or state == State.DEAD:
		return
	_fury = true
	effects.add_mod(&"fury", 99999.0, {"move": 1.25})
	_status_fx("Fury!", 0.0)
	_net_status_fx.rpc("Fury!", 0.0)


func _state_chase(delta: float) -> void:
	if target == null or not is_instance_valid(target) or target.is_out_of_fight():
		# Switch to another player if one is close, otherwise go home.
		target = _find_player()
		if target == null:
			_set_state(State.RETURN)
			return
	if global_position.distance_to(_spawn.origin) > data.leash_range:
		target = null
		_set_state(State.RETURN)
		return
	var to := target.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	model.turn_toward(to, deg_to_rad(data.turn_speed) * delta)
	var archer := data.keep_distance > 0.0
	var can_swing := _attackers_on(target) < MAX_ATTACKERS or archer
	if archer and dist < data.keep_distance and dist > 2.6 and _step_back(to, delta):
		return
	if dist <= data.attack_range and _cooldown <= 0.0 and _facing_error(to) < 30.0 and can_swing and not _ally_in_the_way(to) and (not archer or dist <= 2.6 or _can_see(target)):
		_start_attack(dist)
		return
	if dist > data.attack_range * 0.9:
		# Close in: run when far, walk when near; near the target, head for our own
		# spot in the ring so the group spreads out around it.
		var speed := data.run_speed if dist > 5.0 else data.walk_speed * 1.4
		var heading := to.normalized()
		if dist < 7.0:
			var spot := _slot_point() - global_position
			spot.y = 0.0
			if spot.length() > 0.3:
				heading = spot.normalized()
		_move(heading * speed, delta)
		model.update_locomotion(Vector3(velocity.x, 0, velocity.z).length(), false, speed < 3.0)
	else:
		# In range but waiting: slide along the ring toward our own spot (so the group
		# spreads evenly); once there, circle slowly.
		var spot := _slot_point() - global_position
		spot.y = 0.0
		if spot.length() > 0.5:
			_move(spot.normalized() * data.walk_speed * 1.1, delta)
		else:
			if randf() < delta * 0.5:
				_strafe_dir = -_strafe_dir
			var side := to.normalized().cross(Vector3.UP) * _strafe_dir
			_move(side * data.walk_speed * 0.4, delta)
		model.update_locomotion(Vector3(velocity.x, 0, velocity.z).length(), false, true)


## Archers: back away from a player who is too close. False when cornered (then they stab).
func _step_back(to: Vector3, delta: float) -> bool:
	var away := -to.normalized()
	var ahead := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.6, global_position + Vector3.UP * 0.6 + away * 1.2, 1)
	if not get_world_3d().direct_space_state.intersect_ray(ahead).is_empty():
		return false  # a wall behind us
	_move(away * data.run_speed * 0.8, delta)
	model.update_locomotion(Vector3(velocity.x, 0, velocity.z).length(), false, false)
	return true

## Enemies are solid and don't stand inside each other. Everyone chasing the same
## player is given an evenly spaced spot on a ring around them (kept close to where
## they already are, so they don't swap places).
static var _slot_frame := -1
static var _slot_cache := {}


func _slot_point() -> Vector3:
	var frame := Engine.get_physics_frames()
	if frame != _slot_frame:
		_slot_frame = frame
		_slot_cache.clear()
	if not _slot_cache.has(target):
		_slot_cache[target] = _assign_slots(target)
	var angle: float = _slot_cache[target].get(self, _angle_around(target.global_position, global_position))
	var radius := maxf(data.attack_range * 0.85, 1.4)
	return target.global_position + Vector3(cos(angle), 0.0, sin(angle)) * radius


static func _angle_around(center: Vector3, p: Vector3) -> float:
	return atan2(p.z - center.z, p.x - center.x)


func _assign_slots(on: Player) -> Dictionary:
	var mates: Array = []
	for n in get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Enemy
		if e and e.target == on and e.state in [State.CHASE, State.ATTACK, State.STAGGER, State.PARRIED, State.RIPOSTED]:
			mates.append(e)
	var out := {}
	var count := mates.size()
	if count < 2:
		return out
	var center := on.global_position
	mates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return _angle_around(center, a.global_position) < _angle_around(center, b.global_position))
	var sx := 0.0
	var sy := 0.0
	for i in count:
		var off := _angle_around(center, (mates[i] as Enemy).global_position) - TAU * i / count
		sx += cos(off)
		sy += sin(off)
	var base := atan2(sy, sx)
	for i in count:
		out[mates[i]] = base + TAU * i / count
	return out


## Is another enemy standing between us and the target (so we couldn't swing at them anyway)?
func _ally_in_the_way(to: Vector3) -> bool:
	var dist := to.length()
	if dist < 0.01:
		return false
	var dir := to / dist
	for n in get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Enemy
		if e == null or e == self or e.state == State.DEAD:
			continue
		var rel := e.global_position - global_position
		rel.y = 0.0
		var along := rel.dot(dir)
		if along > 0.3 and along < dist and (rel - dir * along).length() < 0.5 * (data.scale + e.data.scale):
			return true
	return false


## A gentle push away from enemies we overlap, so bodies never sit inside each other.
func _separation() -> Vector3:
	var push := Vector3.ZERO
	for n in get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Enemy
		if e == null or e == self or e.state == State.DEAD:
			continue
		var away := global_position - e.global_position
		away.y = 0.0
		var need := 0.55 * (data.scale + e.data.scale)
		var d := away.length()
		if d < need:
			push += (away / maxf(d, 0.05)) * (need - d) / need
	return push


func _start_attack(dist: float) -> void:
	if data.boss:
		_boss_retarget()
	var choices: Array[AttackData] = []
	var total := 0.0
	for a in _attacks():
		if dist <= a.max_use_distance:
			choices.append(a)
			total += a.weight
	if choices.is_empty():
		return
	var roll := randf() * total
	var pick := choices[0]
	for a in choices:
		roll -= a.weight
		if roll <= 0.0:
			pick = a
			break
	start_attack(_attacks().find(pick))


## Begin attack number `index` (also used by tests).
func start_attack(index: int) -> void:
	_telegraphed = false
	_shot = false
	_fire_dropped = false
	_set_state(State.ATTACK)
	_attack.start(_attacks()[index], model)


func _state_attack(delta: float) -> void:
	var a := _attack.attack
	_attack.step(delta)
	# Track the target during the wind-up, then commit to the swing.
	if target and not _attack.past(a.track_until):
		var to := target.global_position - global_position
		model.turn_toward(to, deg_to_rad(data.turn_speed) * delta)
	# Warning: white glint (parryable) or red glow (unblockable).
	if not _telegraphed and _attack.past(a.telegraph_time):
		_telegraphed = true
		if a.unblockable:
			model.set_overlay("danger", Color(1.0, 0.1, 0.05, 0.35))
		elif a.parryable:
			_glint()
			_net_glint.rpc()
	if model.overlay_kind() == "danger" and _attack.past(a.hit_end):
		model.set_overlay("")
	var lunge := _attack.lunge_speed()
	_move(model.forward() * lunge, delta, true)
	if _attack.in_hit_window():
		var index := _attacks().find(a)
		if a.fire_radius > 0.0 and not _fire_dropped:
			_fire_dropped = true
			var at := global_position + model.forward() * a.fire_ahead
			_net_fire.rpc(at, a.fire_radius, a.fire_time)
		if a.projectile_speed > 0.0:
			if not _shot:
				_shot = true
				_shoot(a, index)
		else:
			for n in _attack.find_new_targets(self, model.forward(), &"player"):
				var p := n as Player
				if p.is_multiplayer_authority():
					_on_hit_result(p.receive_hit(make_hit(index)))
				else:
					p._net_enemy_hit.rpc_id(p.get_multiplayer_authority(), get_path(), index, global_position)
				if state != State.ATTACK:
					return
	if _attack.done():
		_cooldown = randf_range(data.attack_cooldown_min, data.attack_cooldown_max) * (0.6 if _fury else 1.0)
		_set_state(State.CHASE)


## Archers: loose an arrow at where the target is now (it flies, so a roll or a sidestep beats it).
func _shoot(a: AttackData, index: int) -> void:
	if target == null:
		return
	var from := global_position + Vector3.UP * 1.45 * data.scale + model.forward() * 0.5
	var aim := target.global_position + Vector3.UP * 1.1
	var dir := (aim - from).normalized()
	_spawn_arrow(from, dir, a.projectile_speed, a.projectile_range, true, index)
	_net_arrow.rpc(from, dir, a.projectile_speed, a.projectile_range)


@rpc("authority", "call_remote", "unreliable")
func _net_arrow(from: Vector3, dir: Vector3, speed: float, reach: float) -> void:
	_spawn_arrow(from, dir, speed, reach, false, 0)


func _spawn_arrow(from: Vector3, dir: Vector3, speed: float, reach: float, damaging: bool, index: int) -> void:
	var arrow := EnemyArrow.new()
	arrow.shooter = self
	arrow.direction = dir
	arrow.speed = speed
	arrow.max_range = reach
	arrow.damaging = damaging
	arrow.attack_index = index
	get_parent().add_child(arrow)
	arrow.global_position = from
	Audio.sfx(&"swing_dash", from)


## Host: our arrow reached a player. Same path as a melee hit (their machine decides, favoring the dodger).
func arrow_hit_player(p: Player, index: int, origin: Vector3) -> void:
	if state == State.DEAD:
		return
	if p.is_multiplayer_authority():
		var hit := make_hit(index)
		hit.origin = origin
		p.receive_hit(hit)
	else:
		p._net_enemy_hit.rpc_id(p.get_multiplayer_authority(), get_path(), index, origin)


@rpc("authority", "call_remote", "unreliable")
func _net_glint() -> void:
	_glint()


func _glint() -> void:
	CombatFx.glint(Vector3.ZERO, Color(1.0, 0.97, 0.85), _weapon_tip())


func _state_wait(delta: float, duration: float) -> void:
	_move(Vector3.ZERO, delta)
	if _state_time >= duration:
		_cooldown = 0.3
		_set_state(State.CHASE if target else State.IDLE)


func _state_return(delta: float) -> void:
	var to := _spawn.origin - global_position
	to.y = 0.0
	if to.length() < 0.5:
		_reset()
		model.face_instantly(-_spawn.basis.z)
		return
	model.turn_toward(to, deg_to_rad(data.turn_speed) * delta)
	_move(to.normalized() * data.walk_speed * 1.6, delta)
	model.update_locomotion(Vector3(velocity.x, 0, velocity.z).length(), false, true)
	# Heal up on the way home; jump back in if a player comes close again.
	health = minf(max_health, health + max_health * 0.2 * delta)
	var p := _find_player()
	if p and global_position.distance_to(_spawn.origin) < data.leash_range * 0.6:
		target = p
		_set_state(State.CHASE)


func _die() -> void:
	_set_state(State.DEAD)
	collision_layer = 0
	model.set_overlay("")
	model.play_death()
	died.emit()
	if data.boss:
		_set_engaged(false)
		Net.system_message("%s has fallen." % data.display_name)
		if data.kill_flag != &"":
			WorldState.set_flag(data.kill_flag, true)
	# White Knights nearby fly into a martyr's fury.
	for n in get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Enemy
		if e and e != self and e.data.martyr_fury and e.global_position.distance_to(global_position) < 12.0:
			e._enrage()
	# Loot, coins, souls and XP for everyone nearby (DESIGN.md 6.4 and 9).
	Loot.enemy_died(self, data.loot_table, data.xp)


# --- Helpers ------------------------------------------------------------------

func _move(horizontal_velocity: Vector3, delta: float, instant := false) -> void:
	var h := Vector3(velocity.x, 0, velocity.z)
	horizontal_velocity *= effects.move_mult()
	if not instant:
		horizontal_velocity += _separation() * 3.0
	h = horizontal_velocity if instant else h.move_toward(horizontal_velocity, 20.0 * delta)
	velocity.x = h.x
	velocity.z = h.z
	velocity.y = velocity.y - 22.0 * delta if not is_on_floor() else -0.1
	move_and_slide()


func _facing_error(to: Vector3) -> float:
	return rad_to_deg(model.forward().angle_to(Vector3(to.x, 0, to.z)))


## Spot a player: in the sight cone (shorter at night) with a clear view, or
## close enough to hear (twice as far if they sprint or fight).
func _find_player() -> Player:
	var best: Player
	var best_d := INF
	for n in get_tree().get_nodes_in_group(&"player"):
		var p := n as Player
		if p == null or p.is_out_of_fight():
			continue
		if data.boss and not _in_arena(p):
			continue  # a boss waits for you to step into his arena
		var to := p.global_position - global_position
		var d := to.length()
		if data.ambush_range > 0.0 and state == State.IDLE and d > data.ambush_range:
			continue  # lying in wait: only wakes when you are right on top of him
		var loud := p.is_sprinting or p.state == Player.State.ATTACK or p.state == Player.State.ROLL
		var hears := d <= data.hearing_range * (2.0 if loud else 1.0)
		var in_cone := d <= data.sight_range * sight_mult * sight_scale \
				and rad_to_deg(model.forward().angle_to(Vector3(to.x, 0, to.z))) <= data.sight_angle * 0.5
		if (hears or in_cone) and d < best_d and _can_see(p):
			best_d = d
			best = p
	return best


func _player_of_peer(peer: int) -> Player:
	for n in get_tree().get_nodes_in_group(&"player"):
		var p := n as Player
		if p and p.get_multiplayer_authority() == peer:
			return p
	return null


func _can_see(p: Node3D) -> bool:
	var from := global_position + Vector3.UP * 1.6
	var to := p.global_position + Vector3.UP * 1.3
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _weapon_tip() -> Node3D:
	if _weapon:
		var tip := _weapon.find_child("Tip", true, false) as Node3D
		return tip if tip else _weapon
	return model


# --- Bosses ---------------------------------------------------------------------------

var _tinted := false


## Fight starts or ends (host). A new fight counts the players in the arena and scales to them.
func _set_engaged(on: bool) -> void:
	if on == _engaged:
		return
	if on:
		_scale_to(_arena_count())
	_engaged = on
	net_engaged = on


## Players inside this boss's arena (or everyone, if it has none).
func _arena_count() -> int:
	var count := 0
	var room: BossRoom
	for n in get_tree().get_nodes_in_group(&"boss_rooms"):
		if (n as BossRoom).contains(_spawn.origin):
			room = n
	for n in get_tree().get_nodes_in_group(&"player"):
		var p := n as Player
		if p and not p.is_dead() and (room == null or room.contains(p.global_position)):
			count += 1
	return maxi(count, 1)


func _scale_to(count: int) -> void:
	var was := _engaged
	_engaged = false
	set_party_size(count)
	_engaged = was


## Bosses switch target only as an attack begins: the taunted player, else the top of the threat table.
func _boss_retarget() -> void:
	var forced := _player_of_peer(_taunt_peer) if _taunt_time > 0.0 else null
	if forced and not forced.is_out_of_fight():
		target = forced
		return
	var best: Player
	var best_threat := 0.0
	for n in get_tree().get_nodes_in_group(&"player"):
		var p := n as Player
		if p == null or p.is_out_of_fight():
			continue
		var t: float = threat.get(p.get_multiplayer_authority(), 0.0)
		if t > best_threat:
			best_threat = t
			best = p
	if best and best != target:
		target = best


func _boss_after_hit(hit: HitInfo) -> void:
	if state != State.PARRIED:
		_poise -= hit.poise_damage
		_poise_timer = data.poise_regen_delay
		if _poise <= 0.0:
			_poise = max_poise
			_stance_break()
	if _phase == 1 and data.phase2_at > 0.0 and health <= max_health * data.phase2_at:
		_start_phase2()


## Parrying a boss attack chips its poise instead of staggering it.
func _boss_parried() -> void:
	_poise -= data.parry_poise_damage
	_poise_timer = data.poise_regen_delay
	_status_fx("Parried", 0.0)
	_net_status_fx.rpc("Parried", 0.0)
	if _poise <= 0.0:
		_poise = max_poise
		_stance_break()


## Poise gone: it kneels, open to a critical hit (riposte).
func _stance_break() -> void:
	if state in [State.PARRIED, State.RIPOSTED, State.CALL, State.DEAD]:
		return
	_set_state(State.PARRIED)
	model.set_overlay("")
	model.play_fitted(CharacterModel.ANIM_GUARD_BREAK, data.stance_time, 0.05)
	_status_fx("Stance broken!", 0.0)
	_net_status_fx.rpc("Stance broken!", 0.0)


func _start_phase2() -> void:
	_phase = 2
	_roaring = true
	_set_state(State.CALL)
	model.set_overlay("")
	model.face_instantly(model.forward())
	model.play(data.call_anim, 0.15, 1.0, true)
	_status_fx("Ablaze!", 0.0)
	_net_status_fx.rpc("Ablaze!", 0.0)


func _finish_roar() -> void:
	_roaring = false
	effects.add_mod(&"phase2", 99999.0, {"move": data.phase2_speed_mult})
	if data.adds_scene and get_parent():
		var n := data.adds_count + _party_size - 1
		for i in n:
			var e := data.adds_scene.instantiate() as Enemy
			e.name = "%s_add%d_%d" % [name, i, Time.get_ticks_msec() % 100000]
			var a := TAU * i / maxf(n, 1)
			e.position = global_position + Vector3(cos(a), 0.2, sin(a)) * 5.0
			get_parent().add_child(e, true)
			e.remove_from_group(&"respawn_on_rest")
			e.set_party_size(_party_size)
			e.target = target
			e._set_state(State.CHASE)
			_adds.append(e)
	_set_state(State.CHASE)


func _free_adds() -> void:
	for e in _adds:
		if is_instance_valid(e):
			e.queue_free()
	_adds.clear()


@rpc("authority", "call_local", "reliable")
func _net_fire(at: Vector3, radius: float, time: float) -> void:
	var patch := FirePatch.new()
	patch.radius = radius
	patch.time = time
	var root := get_parent().get_parent() if get_parent() and get_parent().get_parent() else get_tree().root
	root.add_child(patch)
	patch.global_position = at


func _in_arena(p: Node3D) -> bool:
	var found := false
	for n in get_tree().get_nodes_in_group(&"boss_rooms"):
		var room := n as BossRoom
		if room.contains(_spawn.origin):
			found = true
			if room.contains(p.global_position):
				return true
	return not found
