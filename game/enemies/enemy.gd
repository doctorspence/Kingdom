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

signal died

enum State { IDLE, CHASE, ATTACK, STAGGER, PARRIED, RIPOSTED, RETURN, DEAD }

const HEALTH_BAR_SHOW_TIME := 6.0

@export var data: EnemyData

var state := State.IDLE
var health := 100.0
var target: Player

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

@onready var model: CharacterModel = $Visual


func _ready() -> void:
	add_to_group(&"hittable")
	add_to_group(&"lock_targets")
	add_to_group(&"enemies")
	add_to_group(&"respawn_on_rest")
	_spawn = global_transform
	global_basis = Basis.IDENTITY
	model.face_instantly(-_spawn.basis.z)
	model.scale = Vector3.ONE * data.scale
	if data.weapon_scene:
		_weapon = data.weapon_scene.instantiate()
		model.attach_to_hand(_weapon, "r")
	_reset()


func _reset() -> void:
	health = data.max_health
	_poise = data.poise
	_cooldown = 0.5
	target = null
	collision_layer = 4
	_set_state(State.IDLE)
	model.set_overlay("")
	model.play(model.idle_anim, 0.2)


# --- Used by players, the HUD and shrines --------------------------------------

func get_lock_point() -> Vector3:
	return global_position + Vector3.UP * 1.35 * data.scale


func can_be_locked() -> bool:
	return state != State.DEAD


func hit_radius() -> float:
	return 0.4 * data.scale


func can_be_riposted() -> bool:
	return state == State.PARRIED


func health_ratio() -> float:
	return health / data.max_health


## Show the health bar above its head? (When hurt recently.)
func wants_health_bar() -> bool:
	return state != State.DEAD and _bar_timer > 0.0


func bar_point() -> Vector3:
	return global_position + Vector3.UP * 2.25 * data.scale


func display_name() -> String:
	return data.display_name


## A player is starting a riposte on us: hold still for it.
func begin_riposte(attacker: Node3D) -> void:
	_set_state(State.RIPOSTED)
	model.face_instantly(attacker.global_position - global_position)
	model.play(CharacterModel.ANIM_STAGGER, 0.1, 0.5, true)


## Someone rested at a shrine: come back to life at the starting spot.
func reset_from_rest() -> void:
	global_position = _spawn.origin
	velocity = Vector3.ZERO
	model.face_instantly(-_spawn.basis.z)
	reset_physics_interpolation()
	_reset()


func receive_hit(hit: HitInfo) -> HitInfo.Result:
	if state == State.DEAD:
		return HitInfo.Result.IGNORED
	var chest := global_position + Vector3.UP * 1.3 * data.scale
	var damage := hit.damage
	health = maxf(0.0, health - damage)
	_bar_timer = HEALTH_BAR_SHOW_TIME
	var away := global_position - hit.origin
	away.y = 0.0
	CombatFx.blood(chest, away.normalized(), 1.6 if hit.is_crit else 1.0)
	CombatFx.damage_number(chest + Vector3.UP * 0.6, damage,
			CombatFx.NumberKind.CRIT if hit.is_crit else CombatFx.NumberKind.NORMAL)
	_hitstop = maxf(_hitstop, hit.hit_stop)
	if target == null and hit.attacker is Player:
		target = hit.attacker
	if health <= 0.0:
		_die()
		return HitInfo.Result.KILLED
	if state == State.RIPOSTED:
		return HitInfo.Result.HIT  # stays down for the rest of the knockdown
	_poise -= hit.poise_damage
	_poise_timer = data.poise_regen_delay
	if _poise <= 0.0:
		_poise = data.poise
		_set_state(State.STAGGER)
		model.set_overlay("")
		model.play_fitted(CharacterModel.ANIM_STAGGER, data.stagger_time, 0.05)
	elif state != State.ATTACK:
		model.play(CharacterModel.ANIM_HIT, 0.05, 1.0, true)
		if state == State.IDLE:
			_set_state(State.CHASE)
	return HitInfo.Result.HIT


# --- Main loop ----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _hitstop > 0.0:
		_hitstop -= delta
		model.hold(true)
		return
	model.hold(false)
	_state_time += delta
	_cooldown -= delta
	_bar_timer -= delta
	_poise_timer -= delta
	if _poise_timer <= 0.0:
		_poise = data.poise

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
			_state_wait(delta, data.riposte_window)
		State.RIPOSTED:
			_state_wait(delta, data.riposted_time)
		State.RETURN:
			_state_return(delta)
		State.DEAD:
			_move(Vector3.ZERO, delta)


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0


func _state_idle(delta: float) -> void:
	_move(Vector3.ZERO, delta)
	model.play(model.idle_anim, 0.25)
	var p := _find_player()
	if p:
		target = p
		_set_state(State.CHASE)


func _state_chase(delta: float) -> void:
	if target == null or target.is_dead():
		target = null
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
	if dist <= data.attack_range and _cooldown <= 0.0 and _facing_error(to) < 30.0:
		_start_attack(dist)
		return
	if dist > data.attack_range * 0.9:
		# Close in: run when far, walk when near.
		var speed := data.run_speed if dist > 5.0 else data.walk_speed * 1.4
		_move(to.normalized() * speed, delta)
		model.update_locomotion(Vector3(velocity.x, 0, velocity.z).length(), false, speed < 3.0)
	else:
		# In range but waiting: circle slowly, sometimes switching direction.
		if randf() < delta * 0.5:
			_strafe_dir = -_strafe_dir
		var side := to.normalized().cross(Vector3.UP) * _strafe_dir
		_move(side * data.walk_speed * 0.6, delta)
		model.update_locomotion(Vector3(velocity.x, 0, velocity.z).length(), false, true)


func _start_attack(dist: float) -> void:
	var choices: Array[AttackData] = []
	var total := 0.0
	for a in data.attacks:
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
	_telegraphed = false
	_set_state(State.ATTACK)
	_attack.start(pick, model)


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
			CombatFx.glint(Vector3.ZERO, Color(1.0, 0.97, 0.85), _weapon_tip())
	if model.overlay_kind() == "danger" and _attack.past(a.hit_end):
		model.set_overlay("")
	var lunge := _attack.lunge_speed()
	_move(model.forward() * lunge, delta, true)
	if _attack.in_hit_window():
		for p in _attack.find_new_targets(self, model.forward(), &"player"):
			_hit_player(p as Player)
			if state != State.ATTACK:
				return
	if _attack.done():
		_cooldown = randf_range(data.attack_cooldown_min, data.attack_cooldown_max)
		_set_state(State.CHASE)


func _hit_player(p: Player) -> void:
	var a := _attack.attack
	var hit := HitInfo.new()
	hit.attacker = self
	hit.attack = a
	hit.origin = global_position
	hit.damage = a.base_damage
	hit.poise_damage = a.base_poise_damage
	hit.parryable = a.parryable
	hit.unblockable = a.unblockable
	hit.hit_stop = a.hit_stop
	var result := p.receive_hit(hit)
	match result:
		HitInfo.Result.PARRIED:
			_set_state(State.PARRIED)
			model.set_overlay("")
			model.play_fitted(CharacterModel.ANIM_GUARD_BREAK, data.riposte_window, 0.05)
		HitInfo.Result.HIT, HitInfo.Result.BLOCKED, HitInfo.Result.KILLED:
			_hitstop = maxf(_hitstop, a.hit_stop)


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
	health = minf(data.max_health, health + data.max_health * 0.2 * delta)
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


# --- Helpers ------------------------------------------------------------------

func _move(horizontal_velocity: Vector3, delta: float, instant := false) -> void:
	var h := Vector3(velocity.x, 0, velocity.z)
	h = horizontal_velocity if instant else h.move_toward(horizontal_velocity, 20.0 * delta)
	velocity.x = h.x
	velocity.z = h.z
	velocity.y = velocity.y - 22.0 * delta if not is_on_floor() else -0.1
	move_and_slide()


func _facing_error(to: Vector3) -> float:
	return rad_to_deg(model.forward().angle_to(Vector3(to.x, 0, to.z)))


func _find_player() -> Player:
	var best: Player
	var best_d := data.aggro_range
	for n in get_tree().get_nodes_in_group(&"player"):
		var p := n as Player
		if p == null or p.is_dead():
			continue
		var d := p.global_position.distance_to(global_position)
		if d < best_d and _can_see(p):
			best_d = d
			best = p
	return best


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
