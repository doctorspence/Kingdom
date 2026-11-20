class_name Player
extends CharacterBody3D
## The player character: movement, rolling, jumping, stamina, health, falls,
## attacks, blocking, parrying, flasks and taking hits.
##
## Movement numbers come from data/balance/player_tuning.tres; weapon numbers
## from the weapon and shield files in data/.
## The character is in one "state" at a time:
##   MOVE        on the ground: walk, run, sprint, block
##   AIR         jumping or falling
##   ROLL        dodge roll (invincible for the first part)
##   LANDING     stumbling after a hard landing
##   ATTACK      swinging (also ripostes)
##   DRINK       drinking a flask
##   STAGGER     knocked off balance by a hit
##   GUARD_BREAK shield knocked aside after running out of stamina
##   DOWNED      at 0 health in co-op: crawling, bleeding out, waiting for a revive
##   DEAD        waiting to respawn
##
## Multiplayer: each player's own game runs their character ("authority") and
## shares its position, animation and health. Everyone else's copy of that
## character is a "proxy" that just mirrors what it's told.

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal flasks_changed(current: int, maximum: int)
signal died
signal respawned

enum State { MOVE, AIR, ROLL, LANDING, ATTACK, DRINK, STAGGER, GUARD_BREAK, DOWNED, DEAD }

const RESPAWN_DELAY := 3.0
## Below this height you've fallen out of the world.
const KILL_HEIGHT := -60.0
## Test equip loads that F3 cycles through (gear weight ÷ capacity).
const TEST_LOADS := [0.2, 0.5, 0.9, 1.2]
const INTERACT_RANGE := 2.2

@export var tuning: PlayerTuning = preload("res://data/balance/player_tuning.tres")
@export var weapon: WeaponData = preload("res://data/weapons/weapon_rusty_sword.tres")
@export var shield: ShieldData = preload("res://data/shields/shield_round_wood.tres")
## Gear weight ÷ carrying capacity. Phase 6 will compute this from your gear.
@export var equip_load := 0.2

var state := State.MOVE
var health := 100.0
var stamina := 100.0
var flasks := 4
var is_sprinting := false
var is_walking := false
var is_blocking := false
## Show debug visuals (invincibility tint). The HUD's F2 toggles this.
var show_debug := false
var last_fall_height := 0.0

var _state_time := 0.0
var _iframe_timer := 0.0
var _regen_cooldown := 0.0
var _sprint_locked := false
var _off_floor_time := 0.0
var _fall_peak_y := 0.0
var _jumped := false
var _roll_dir := Vector3.FORWARD
var _roll_duration := 0.6
var _roll_distance := 3.5
var _since_roll := 99.0
var _buffered := &""
var _buffer_timer := 0.0
var _dodge_held := -1.0
var _spawn: Transform3D
# Combat
var _attack := AttackRunner.new()
var _combo_index := 0
var _charge := 0.0
var _charging := false
var _is_riposte := false
var _riposte_victim: Node3D
var _poise := 30.0
var _poise_timer := 0.0
var _hitstop := 0.0
var _block_started := -99.0
var _block_released := -99.0
var _clock := 0.0
var _drink_healed := false
var _stun_time := 0.0
# Co-op
var _downs := 0
var _bleed := 0.0
var _revive_target: Player
var _revive_progress := 0.0

## Shared with everyone (see the Sync node in player.tscn).
var net_pos := Vector3.ZERO
var net_yaw := 0.0
var net_anim := &""
var net_anim_speed := 1.0
var net_anim_count := 0
var net_state := 0
var net_health := 100.0
var net_bleed := 0.0
var spawn_yaw := 0.0
var player_name := ""

var _name_label: Label3D

@onready var model: CharacterModel = $Visual
@onready var camera_rig: PlayerCamera = $CameraRig
@onready var targeting: Targeting = $Targeting


func _enter_tree() -> void:
	# Characters are named after their owner's network id ("1" = host).
	if name.is_valid_int():
		set_multiplayer_authority(name.to_int())


func _ready() -> void:
	add_to_group(&"player")
	# The body itself never rotates; only the visible model turns.
	if net_pos != Vector3.ZERO:
		global_position = net_pos
		global_rotation.y = spawn_yaw
	_spawn = global_transform
	global_basis = Basis.IDENTITY
	health = tuning.max_health
	stamina = tuning.max_stamina
	flasks = tuning.flask_count
	_poise = tuning.poise
	camera_rig.follow = self
	camera_rig.targeting = targeting
	targeting.camera = camera_rig.camera
	if weapon and weapon.visual_scene:
		model.attach_to_hand(weapon.visual_scene.instantiate(), "r")
	if shield and shield.visual_scene:
		model.attach_to_hand(shield.visual_scene.instantiate(), "l")
	player_name = Net.name_of(get_multiplayer_authority())
	Net.names_changed.connect(func() -> void: player_name = Net.name_of(get_multiplayer_authority()))
	_spawn_pos = net_pos
	if is_multiplayer_authority():
		add_to_group(&"local_player")
		camera_rig.activate()
		_face_spawn_direction()
		if not multiplayer.is_server():
			# Joined a friend's game: wait for the host to say where we start.
			_placed = false
			visible = false
			_request_placement.rpc_id(1)
		else:
			_write_net_state()
	else:
		_become_proxy()


var _placed := true
var _spawn_pos := Vector3.ZERO


@rpc("any_peer", "call_remote", "reliable")
func _request_placement() -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == get_multiplayer_authority():
		_net_place.rpc_id(get_multiplayer_authority(), _spawn_pos, spawn_yaw)


@rpc("any_peer", "call_remote", "reliable")
func _net_place(where: Vector3, yaw: float) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	global_position = where
	_spawn = Transform3D(Basis(Vector3.UP, yaw), where)
	_face_spawn_direction()
	_placed = true
	visible = true
	_write_net_state()


## Someone else's character on this machine: no camera, no input, just mirroring.
func _become_proxy() -> void:
	camera_rig.camera.current = false
	camera_rig.set_process(false)
	camera_rig.set_process_unhandled_input(false)
	targeting.set_physics_process(false)
	targeting.set_process_unhandled_input(false)
	set_process_unhandled_input(false)
	collision_mask = 0
	_name_label = Label3D.new()
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.pixel_size = 0.004
	_name_label.font_size = 48
	_name_label.outline_size = 10
	_name_label.position = Vector3(0, 2.25, 0)
	_name_label.modulate = Color(0.85, 0.9, 1.0)
	add_child(_name_label)
	global_position = net_pos


# --- Public -------------------------------------------------------------------

func is_invulnerable() -> bool:
	return _iframe_timer > 0.0 or (state == State.ATTACK and _is_riposte)


func is_dead() -> bool:
	return state == State.DEAD


## Down (co-op) or dead: enemies leave you alone.
func is_out_of_fight() -> bool:
	return state == State.DEAD or state == State.DOWNED


func is_downed() -> bool:
	return state == State.DOWNED


func bleed_time_left() -> float:
	return _bleed if is_multiplayer_authority() else net_bleed


## Revive progress 0..1 (for the HUD), and who you're reviving.
func revive_progress() -> float:
	return _revive_progress / tuning.revive_time if _revive_target else 0.0


func revive_target() -> Player:
	return _revive_target


func load_tier() -> PlayerTuning.LoadTier:
	return tuning.load_tier(equip_load)


func state_name() -> String:
	return State.keys()[state]


func hit_radius() -> float:
	return 0.35


## Is the parry window open right now?
func is_parrying() -> bool:
	return is_blocking and _clock - _block_started <= (shield.parry_window if shield else 0.12)


## An enemy blow arrives. The player's own game decides what happened
## ("favor the dodger").
func receive_hit(hit: HitInfo) -> HitInfo.Result:
	if state == State.DEAD or state == State.DOWNED:
		return HitInfo.Result.IGNORED
	var chest := global_position + Vector3.UP * 1.3
	if is_invulnerable():
		return HitInfo.Result.DODGED
	var to_attacker := hit.origin - global_position
	to_attacker.y = 0.0
	var in_front := rad_to_deg(model.forward().angle_to(to_attacker)) <= tuning.block_arc * 0.5
	if is_blocking and in_front and not hit.unblockable:
		if hit.parryable and is_parrying():
			CombatFx.sparks(chest + model.forward() * 0.4, to_attacker, true)
			_share_fx(2, chest + model.forward() * 0.4, to_attacker)
			CombatFx.word(chest + Vector3.UP * 0.5, "Parry!")
			freeze(0.12)
			camera_rig.add_shake(0.25)
			return HitInfo.Result.PARRIED
		var reduction := shield.block_reduction if shield else weapon.block_reduction
		var stamina_cost := hit.damage * (shield.stamina_per_damage if shield else 1.0)
		_spend_stamina(stamina_cost)
		CombatFx.sparks(chest + model.forward() * 0.4, to_attacker)
		_share_fx(1, chest + model.forward() * 0.4, to_attacker)
		freeze(hit.hit_stop)
		camera_rig.add_shake(0.2)
		var chip := hit.damage * (1.0 - reduction)
		if chip > 0.0:
			_apply_damage(chip)
		if state == State.DEAD:
			return HitInfo.Result.KILLED
		if stamina <= 0.0:
			_guard_break()
		else:
			CombatFx.word(chest + Vector3.UP * 0.5, "Blocked")
		return HitInfo.Result.BLOCKED

	# Clean hit.
	CombatFx.blood(chest, -to_attacker.normalized())
	_share_fx(0, chest, -to_attacker.normalized())
	camera_rig.add_shake(0.45 if hit.damage >= 30.0 else 0.3)
	freeze(hit.hit_stop)
	_apply_damage(hit.damage)
	if state == State.DEAD:
		return HitInfo.Result.KILLED
	_poise -= hit.poise_damage
	_poise_timer = tuning.poise_regen_delay
	if _poise <= 0.0:
		_poise = tuning.poise
		_stagger(tuning.stagger_time)
	return HitInfo.Result.HIT


## Fall damage and other unblockable harm.
func take_damage(amount: float, ignore_iframes := false) -> void:
	if state == State.DEAD or amount <= 0.0:
		return
	if is_invulnerable() and not ignore_iframes:
		return
	_apply_damage(amount)


## Hit-stop: freeze in place for a moment on impact.
func freeze(duration: float) -> void:
	_hitstop = maxf(_hitstop, duration)


## Rest at a shrine: full health and flasks, and it becomes your respawn point.
func rest_at(spawn_point: Transform3D) -> void:
	_spawn = spawn_point
	_downs = 0
	health = tuning.max_health
	stamina = tuning.max_stamina
	flasks = tuning.flask_count
	health_changed.emit(health, tuning.max_health)
	stamina_changed.emit(stamina, tuning.max_stamina)
	flasks_changed.emit(flasks, tuning.flask_count)


func respawn() -> void:
	global_position = _spawn.origin
	velocity = Vector3.ZERO
	health = tuning.max_health
	stamina = tuning.max_stamina
	flasks = tuning.flask_count
	_poise = tuning.poise
	_sprint_locked = false
	_iframe_timer = 0.0
	_hitstop = 0.0
	is_blocking = false
	targeting.clear()
	_face_spawn_direction()
	_set_state(State.MOVE)
	health_changed.emit(health, tuning.max_health)
	stamina_changed.emit(stamina, tuning.max_stamina)
	flasks_changed.emit(flasks, tuning.flask_count)
	respawned.emit()


## The closest thing you can interact with (shrine, later doors, loot...).
func nearest_interactable() -> Node3D:
	var best: Node3D
	var best_d := INTERACT_RANGE
	for n in get_tree().get_nodes_in_group(&"interactables"):
		var node := n as Node3D
		if node == null:
			continue
		var d := node.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = node
	return best


func _face_spawn_direction() -> void:
	var facing := -_spawn.basis.z
	model.face_instantly(facing)
	camera_rig.yaw = atan2(-facing.x, -facing.z)
	camera_rig.global_position = global_position + Vector3.UP * camera_rig.pivot_height
	model.reset_physics_interpolation()
	reset_physics_interpolation()


# --- Input --------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if Net.typing:
		return
	if event.is_action_pressed("jump"):
		_buffer(&"jump")
	elif event.is_action_pressed("light_attack"):
		_buffer(&"light")
	elif event.is_action_pressed("heavy_attack"):
		_buffer(&"heavy")
	elif event.is_action_pressed("flask"):
		_buffer(&"flask")
	elif event.is_action_pressed("interact"):
		_buffer(&"interact")
	elif event.is_action_pressed("lock_on"):
		if state != State.DEAD and not targeting.toggle():
			camera_rig.recenter(model.forward())
	elif event.is_action_pressed("debug_equip_load"):
		var i := TEST_LOADS.find(equip_load)
		equip_load = TEST_LOADS[(i + 1) % TEST_LOADS.size()]
	elif event.is_action_pressed("debug_reset"):
		respawn()


## Remember a button press briefly, so pressing it slightly early still works.
func _buffer(action: StringName) -> void:
	_buffered = action
	_buffer_timer = tuning.input_buffer_time


func _consume(action: StringName) -> bool:
	if _buffered == action and _buffer_timer > 0.0:
		_buffered = &""
		return true
	return false


func _has_buffered(action: StringName) -> bool:
	return _buffered == action and _buffer_timer > 0.0


## Shift / gamepad B: tap to roll (on release), hold to sprint.
func _read_dodge_button(delta: float) -> void:
	if Input.is_action_just_pressed("dodge_sprint"):
		_dodge_held = 0.0
	elif _dodge_held >= 0.0:
		if Input.is_action_pressed("dodge_sprint"):
			_dodge_held += delta
		else:
			if _dodge_held < tuning.dodge_hold_time:
				_buffer(&"roll")
			_dodge_held = -1.0


func _move_input() -> Vector2:
	if Net.typing:
		return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")


## Turn stick/WASD input into a world direction, relative to the camera.
func _input_direction() -> Vector3:
	var v := _move_input()
	return camera_rig.flat_basis() * Vector3(v.x, 0.0, v.y)


func _wants_sprint() -> bool:
	return _dodge_held >= tuning.dodge_hold_time


# --- Main loop ----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		_proxy_update(delta)
		return
	if not _placed:
		return
	_authority_update(delta)
	_write_net_state()


## Share what this character is doing with everyone else.
func _write_net_state() -> void:
	net_pos = global_position
	net_yaw = model.rotation.y
	net_anim = model.current_anim()
	net_anim_speed = model.get_speed()
	net_anim_count = model.play_count
	net_state = state
	net_health = health
	net_bleed = _bleed


## Copy what the owner's machine says this character is doing.
func _proxy_update(delta: float) -> void:
	if global_position.distance_to(net_pos) > 4.0:
		global_position = net_pos
	else:
		global_position = global_position.lerp(net_pos, 1.0 - exp(-18.0 * delta))
	model.rotation.y = lerp_angle(model.rotation.y, net_yaw, 1.0 - exp(-18.0 * delta))
	model.mirror(net_anim, net_anim_speed, net_anim_count)
	state = net_state as State
	health = net_health
	if _name_label:
		_name_label.text = player_name + ("  (DOWN)" if state == State.DOWNED else "")


func _authority_update(delta: float) -> void:
	_clock += delta
	_buffer_timer = maxf(0.0, _buffer_timer - delta)
	_read_dodge_button(delta)

	# Hit-stop: everything about this character pauses for a moment.
	if _hitstop > 0.0:
		_hitstop -= delta
		model.hold(true)
		return
	model.hold(false)

	_state_time += delta
	_since_roll += delta
	_iframe_timer = maxf(0.0, _iframe_timer - delta)
	_poise_timer -= delta
	if _poise_timer <= 0.0:
		_poise = tuning.poise

	match state:
		State.MOVE:
			_state_move(delta)
		State.AIR:
			_state_air(delta)
		State.ROLL:
			_state_roll(delta)
		State.LANDING:
			_state_stunned(delta, tuning.hard_landing_time)
		State.ATTACK:
			_state_attack(delta)
		State.DRINK:
			_state_drink(delta)
		State.STAGGER, State.GUARD_BREAK:
			_state_stunned(delta, _stun_time)
		State.DOWNED:
			_state_downed(delta)
		State.DEAD:
			_state_dead(delta)

	if state != State.MOVE and is_blocking:
		_stop_blocking()
	if global_position.y < KILL_HEIGHT and state != State.DEAD:
		health = 0.0
		_die()
	_update_stamina(delta)
	if show_debug and is_invulnerable():
		model.set_overlay("iframes", Color(0.4, 0.8, 1.0, 0.35))
	elif model.overlay_kind() == "iframes":
		model.set_overlay("")


func _set_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0


func _state_move(delta: float) -> void:
	# Walked off a ledge? A short grace period still lets you jump.
	if is_on_floor():
		_off_floor_time = 0.0
	else:
		_off_floor_time += delta
		if _off_floor_time > tuning.coyote_time:
			_enter_air(false)
			_state_air(delta)
			return

	var dir := _input_direction()
	var amount := minf(dir.length(), 1.0)

	if _consume(&"roll") and _can_roll():
		_start_roll(dir)
		return
	if _consume(&"jump") and _can_jump():
		_start_jump()
		return
	if _has_buffered(&"light") and stamina > 0.0:
		_consume(&"light")
		_start_light_attack(dir)
		return
	if _has_buffered(&"heavy") and stamina > 0.0 and weapon.heavy:
		_consume(&"heavy")
		_start_attack(weapon.heavy, dir)
		_charging = true
		_charge = 0.0
		return
	if _update_revive(delta):
		move_and_slide()
		return
	if _consume(&"flask"):
		_start_drink()
		return
	if _consume(&"interact") and _nearest_downed_friend() == null:
		var thing := nearest_interactable()
		if thing:
			thing.call(&"interact", self)

	# Blocking
	var wants_block := Input.is_action_pressed("block")
	if wants_block and not is_blocking:
		is_blocking = true
		# No parry window if you only just let go of block (no mashing).
		_block_started = _clock if _clock - _block_released > tuning.parry_lockout else -99.0
	elif not wants_block and is_blocking:
		_stop_blocking()

	var locked := targeting.has_target()
	var overloaded := load_tier() == PlayerTuning.LoadTier.OVERLOADED
	is_walking = Input.is_action_pressed("walk") or (amount > 0.0 and amount < tuning.walk_stick_threshold)
	is_sprinting = _wants_sprint() and amount > 0.3 and not overloaded and not _sprint_locked \
			and stamina > 0.0 and not is_blocking

	var speed := tuning.run_speed
	if is_sprinting:
		speed = tuning.sprint_speed
	elif is_blocking:
		speed = tuning.block_move_speed
	elif is_walking:
		speed = tuning.walk_speed
	elif locked:
		speed = tuning.lock_on_speed

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var target_velocity := Vector3.ZERO
	if is_sprinting:
		# Sprinting turns in wide arcs: you go where your body points.
		model.turn_toward(dir, deg_to_rad(tuning.sprint_turn_speed) * delta)
		target_velocity = model.forward() * speed
	else:
		if amount > 0.0:
			target_velocity = dir.normalized() * speed
		if locked:
			model.turn_toward(targeting.target_point() - global_position, deg_to_rad(tuning.turn_speed) * delta)
		elif amount > 0.0:
			model.turn_toward(dir, deg_to_rad(tuning.turn_speed) * delta)

	horizontal = _steer(horizontal, target_velocity, speed, amount > 0.0 and not is_sprinting, delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	move_and_slide()

	if is_sprinting and horizontal.length() > 1.0:
		_spend_stamina(tuning.sprint_stamina_per_second * delta)
		if stamina <= 0.0:
			_sprint_locked = true
	if is_blocking:
		model.play(CharacterModel.ANIM_BLOCK, 0.12)
	else:
		model.update_locomotion(Vector3(velocity.x, 0.0, velocity.z).length(), is_sprinting, is_walking)


## Move the current velocity toward the wanted one. While walking or running,
## keep your speed through turns instead of slowing to a stop.
func _steer(horizontal: Vector3, target_velocity: Vector3, speed: float, keep_speed: bool, delta: float) -> Vector3:
	if keep_speed and horizontal.length() > 0.1:
		var cur_speed := horizontal.length()
		var cur_dir := horizontal / cur_speed
		var want_dir := target_velocity.normalized()
		var max_turn := deg_to_rad(tuning.direction_change_speed) * delta
		var angle := cur_dir.signed_angle_to(want_dir, Vector3.UP)
		if absf(angle) > PI - 0.05:
			angle = PI  # straight reversal: pick a side
		cur_dir = cur_dir.rotated(Vector3.UP, clampf(angle, -max_turn, max_turn))
		var rate := tuning.acceleration if cur_speed < speed else tuning.deceleration
		return cur_dir * move_toward(cur_speed, speed, rate * delta)
	var rate2 := tuning.acceleration if target_velocity.length() >= horizontal.length() else tuning.deceleration
	return horizontal.move_toward(target_velocity, rate2 * delta)


func _stop_blocking() -> void:
	is_blocking = false
	_block_released = _clock


# --- Attacks ------------------------------------------------------------------

func _start_light_attack(dir: Vector3) -> void:
	# Riposte a stunned enemy in front of you.
	var victim := _find_riposte_victim()
	if victim and weapon.riposte:
		_is_riposte = true
		_riposte_victim = victim
		model.face_instantly(victim.global_position - global_position)
		victim.call(&"begin_riposte", self)
		_start_attack(weapon.riposte, Vector3.ZERO, false)
		return
	if is_sprinting and weapon.running_attack:
		_start_attack(weapon.running_attack, dir)
	elif _since_roll <= tuning.rolling_attack_window and weapon.rolling_attack:
		_start_attack(weapon.rolling_attack, dir)
	else:
		_combo_index = 0
		_start_attack(weapon.light_combo[0], dir)


func _start_attack(a: AttackData, dir: Vector3, aim := true) -> void:
	if aim:
		_aim_attack(dir)
	_spend_stamina(a.stamina_cost)
	_charging = false
	_charge = 0.0
	if a != weapon.riposte:
		_is_riposte = false
	is_sprinting = false
	_set_state(State.ATTACK)
	_attack.start(a, model)


## Turn toward the locked target, or the best nearby enemy, or where you push.
func _aim_attack(dir: Vector3) -> void:
	if targeting.has_target():
		model.face_instantly(targeting.target_point() - global_position)
		return
	var soft := targeting.find_soft_target(dir if dir.length() > 0.1 else model.forward())
	if soft:
		model.face_instantly(soft.global_position - global_position)
	elif dir.length() > 0.1:
		model.face_instantly(dir)


func _state_attack(delta: float) -> void:
	var a := _attack.attack
	# Heavy attack: holding the button at the wind-up point charges it.
	var mult := 1.0
	if _charging:
		if Input.is_action_pressed("heavy_attack") and _attack.t >= a.windup_until \
				and _charge < weapon.heavy_charge_time:
			_charge += delta
			mult = 0.12
		elif _attack.t >= a.windup_until:
			_charging = false
	_attack.step(delta, mult)

	# Stay locked toward the target during the wind-up.
	if targeting.has_target() and not _attack.past(a.hit_start):
		model.turn_toward(targeting.target_point() - global_position, deg_to_rad(360.0) * delta)

	# Lunge forward (but don't shove through whoever you're hitting).
	var lunge := _attack.lunge_speed()
	if lunge > 0.0 and _something_close_in_front(1.1):
		lunge = 0.0
	velocity.x = model.forward().x * lunge
	velocity.z = model.forward().z * lunge
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	move_and_slide()

	if _attack.in_hit_window():
		for target in _attack.find_new_targets(self, model.forward(), &"hittable"):
			_land_hit(target)

	# What comes next: chain, cancel or finish.
	if _attack.past(a.chain_time) and _has_buffered(&"light") and not _is_riposte \
			and a in weapon.light_combo and stamina > 0.0:
		_consume(&"light")
		_combo_index = (weapon.light_combo.find(a) + 1) % weapon.light_combo.size()
		_start_attack(weapon.light_combo[_combo_index], _input_direction())
		return
	if _attack.past(a.chain_time) and _has_buffered(&"heavy") and not _is_riposte and stamina > 0.0:
		_consume(&"heavy")
		_start_attack(weapon.heavy, _input_direction())
		_charging = true
		return
	if _attack.past(a.cancel_time) and not _is_riposte:
		if _has_buffered(&"roll") and _can_roll():
			_consume(&"roll")
			_start_roll(_input_direction())
			return
		if Input.is_action_pressed("block"):
			_finish_attack()
			return
	if _attack.done():
		_finish_attack()


func _finish_attack() -> void:
	_is_riposte = false
	_riposte_victim = null
	_set_state(State.MOVE)


func _land_hit(target: Node3D) -> void:
	var a := _attack.attack
	var hit := HitInfo.new()
	hit.attacker = self
	hit.attack = a
	hit.origin = global_position
	hit.is_riposte = _is_riposte
	var dmg := weapon.damage * a.damage_mult
	if _charging or _charge > 0.0:
		dmg *= 1.0 + weapon.heavy_charge_bonus * clampf(_charge / weapon.heavy_charge_time, 0.0, 1.0)
	hit.is_crit = _is_riposte or randf() < weapon.crit_chance
	if hit.is_crit and not _is_riposte:
		dmg *= weapon.crit_multiplier
	hit.damage = dmg
	hit.poise_damage = weapon.poise_damage * a.poise_mult
	hit.hit_stop = 0.15 if hit.is_crit else a.hit_stop
	var result: HitInfo.Result = target.call(&"receive_hit", hit)
	if result == HitInfo.Result.HIT or result == HitInfo.Result.KILLED:
		freeze(hit.hit_stop)
		camera_rig.add_shake(0.35 if hit.is_crit else (0.25 if a == weapon.heavy else 0.15))


func _find_riposte_victim() -> Node3D:
	for n in get_tree().get_nodes_in_group(&"hittable"):
		var e := n as Node3D
		if e == null or not e.has_method("can_be_riposted") or not e.call(&"can_be_riposted"):
			continue
		var to := e.global_position - global_position
		to.y = 0.0
		if to.length() <= tuning.riposte_range:
			return e
	return null


func _something_close_in_front(distance: float) -> bool:
	for n in get_tree().get_nodes_in_group(&"hittable"):
		var e := n as Node3D
		if e == null:
			continue
		var to := e.global_position - global_position
		to.y = 0.0
		if to.length() < distance and model.forward().dot(to.normalized()) > 0.5:
			return true
	return false


# --- Flasks -------------------------------------------------------------------

func _start_drink() -> void:
	if flasks <= 0:
		CombatFx.word(global_position + Vector3.UP * 2.0, "No flasks")
		return
	flasks -= 1  # used up at the start, even if you get hit mid-drink
	flasks_changed.emit(flasks, tuning.flask_count)
	_drink_healed = false
	is_sprinting = false
	_set_state(State.DRINK)
	model.play_fitted(CharacterModel.ANIM_DRINK, tuning.drink_time)


func _state_drink(delta: float) -> void:
	var dir := _input_direction()
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(dir.normalized() * tuning.drink_move_speed if dir.length() > 0.1 else Vector3.ZERO,
			tuning.acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	move_and_slide()
	if not _drink_healed and _state_time >= tuning.drink_heal_at:
		_drink_healed = true
		var amount := minf(tuning.max_health * tuning.flask_heal, tuning.max_health - health)
		health += amount
		health_changed.emit(health, tuning.max_health)
		CombatFx.damage_number(global_position + Vector3.UP * 2.0, amount, CombatFx.NumberKind.HEAL)
	if _state_time >= tuning.drink_time:
		_set_state(State.MOVE)


# --- Being hit ----------------------------------------------------------------

func _apply_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	health_changed.emit(health, tuning.max_health)
	if health <= 0.0:
		if _someone_else_standing():
			_go_down()
		else:
			_die()


func _stagger(duration: float) -> void:
	_stun_time = duration
	_set_state(State.STAGGER)
	velocity = Vector3(velocity.x * 0.2, velocity.y, velocity.z * 0.2)
	model.play_fitted(CharacterModel.ANIM_HIT, duration * 1.2, 0.05)


func _guard_break() -> void:
	_stun_time = tuning.guard_break_time
	_set_state(State.GUARD_BREAK)
	CombatFx.word(global_position + Vector3.UP * 2.0, "Guard broken")
	model.play_fitted(CharacterModel.ANIM_GUARD_BREAK, tuning.guard_break_time, 0.05)


## Stunned states: no control until the time is up.
func _state_stunned(delta: float, duration: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(Vector3.ZERO, tuning.deceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	move_and_slide()
	if _state_time >= duration:
		_set_state(State.MOVE)


# --- Roll ---------------------------------------------------------------------

func _can_roll() -> bool:
	return stamina > 0.0 and load_tier() != PlayerTuning.LoadTier.OVERLOADED


func _start_roll(dir: Vector3) -> void:
	var tier := load_tier()
	_roll_duration = tuning.roll_duration[tier]
	_roll_distance = tuning.roll_distance[tier]
	_iframe_timer = tuning.roll_iframes[tier]
	_roll_dir = dir.normalized() if dir.length() > 0.1 else model.forward()
	model.face_instantly(_roll_dir)
	_spend_stamina(tuning.roll_stamina)
	is_sprinting = false
	_set_state(State.ROLL)
	model.play_roll(_roll_duration)


func _state_roll(delta: float) -> void:
	var u := _state_time / _roll_duration
	# Fast at the start, easing down to running speed at the end (so you come out
	# of the roll still moving). Covers exactly the roll distance.
	var average := _roll_distance / _roll_duration
	var end_speed := minf(tuning.run_speed, average)
	var start_speed := end_speed + 1.5 * (average - end_speed)
	if u >= 1.0:
		# Hand the momentum straight back to normal movement.
		velocity.x = _roll_dir.x * end_speed
		velocity.z = _roll_dir.z * end_speed
		_since_roll = 0.0
		_set_state(State.MOVE)
		_state_move(delta)
		return
	var speed := end_speed + (start_speed - end_speed) * (1.0 - u * u)
	velocity.x = _roll_dir.x * speed
	velocity.z = _roll_dir.z * speed
	if is_on_floor():
		_off_floor_time = 0.0
	else:
		velocity.y -= tuning.gravity * delta
		_off_floor_time += delta
	move_and_slide()
	if _off_floor_time > tuning.coyote_time:
		_enter_air(false)  # rolled off a ledge


# --- Jump, fall, land ---------------------------------------------------------

func _can_jump() -> bool:
	return stamina > 0.0 and (is_on_floor() or _off_floor_time <= tuning.coyote_time)


func _start_jump() -> void:
	velocity.y = sqrt(2.0 * tuning.gravity * tuning.jump_height)
	_iframe_timer = maxf(_iframe_timer, tuning.jump_iframes)
	_spend_stamina(tuning.jump_stamina)
	_enter_air(true)
	model.play_jump()


func _enter_air(jumped: bool) -> void:
	_jumped = jumped
	_fall_peak_y = global_position.y
	is_sprinting = false
	_set_state(State.AIR)
	if not jumped:
		model.play_fall()


func _state_air(delta: float) -> void:
	_fall_peak_y = maxf(_fall_peak_y, global_position.y)
	velocity.y -= tuning.gravity * delta

	# A little steering in the air, but you can't stop or turn around.
	var dir := _input_direction()
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var cap := maxf(horizontal.length(), tuning.walk_speed)
	horizontal = horizontal.move_toward(dir.normalized() * cap if dir.length() > 0.1 else horizontal,
			tuning.acceleration * tuning.air_control * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if horizontal.length() > 0.5:
		model.turn_toward(horizontal, deg_to_rad(tuning.turn_speed) * 0.25 * delta)
	move_and_slide()

	if _jumped and velocity.y < -1.0:
		_jumped = false
		model.play_fall()
	if is_on_floor() and velocity.y <= 0.0:
		_land()


func _land() -> void:
	last_fall_height = maxf(0.0, _fall_peak_y - global_position.y)
	_off_floor_time = 0.0
	var damage := tuning.fall_damage_fraction(last_fall_height) * tuning.max_health
	if damage > 0.0:
		take_damage(damage, true)
		if state == State.DEAD:
			return
	if last_fall_height >= tuning.hard_landing_height:
		velocity.x *= 0.2
		velocity.z *= 0.2
		_set_state(State.LANDING)
		model.play_land(true)
	else:
		_set_state(State.MOVE)
		if last_fall_height > 0.8:
			model.play_land(false)


# --- Downed and revive (co-op) ------------------------------------------------

func _someone_else_standing() -> bool:
	for n in get_tree().get_nodes_in_group(&"player"):
		var p := n as Player
		if p and p != self and not p.is_out_of_fight():
			return true
	return false


func _go_down() -> void:
	var times := tuning.downed_bleed_times
	_bleed = times[mini(_downs, times.size() - 1)]
	_downs += 1
	is_sprinting = false
	is_blocking = false
	targeting.clear()
	_set_state(State.DOWNED)
	model.play(&"Crouch_Idle", 0.2)
	CombatFx.word(global_position + Vector3.UP * 1.8, "Down!")


func _state_downed(delta: float) -> void:
	_bleed -= delta
	if _bleed <= 0.0 or not _someone_else_standing():
		_die()
		return
	var dir := _input_direction()
	var h := Vector3(velocity.x, 0.0, velocity.z).move_toward(
			dir.normalized() * tuning.downed_crawl_speed if dir.length() > 0.1 else Vector3.ZERO, 8.0 * delta)
	velocity.x = h.x
	velocity.z = h.z
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	move_and_slide()
	if h.length() > 0.1:
		model.turn_toward(h, deg_to_rad(180.0) * delta)
		model.play(&"Crouch_Fwd", 0.2, 0.5)
	else:
		model.play(&"Crouch_Idle", 0.2)


## Holding Interact next to a downed friend revives them (costs one flask).
## Returns true while reviving (you stand still).
func _update_revive(delta: float) -> bool:
	var target := _nearest_downed_friend() if Input.is_action_pressed("interact") and flasks > 0 else null
	if target == null or target != _revive_target:
		_revive_target = target
		_revive_progress = 0.0
		if target == null:
			return false
	_revive_progress += delta
	velocity.x = 0.0
	velocity.z = 0.0
	model.turn_toward(target.global_position - global_position, deg_to_rad(360.0) * delta)
	model.play(&"Interact", 0.15)
	if _revive_progress >= tuning.revive_time:
		flasks -= 1
		flasks_changed.emit(flasks, tuning.flask_count)
		target.revive_by(self)
		_revive_target = null
		_revive_progress = 0.0
	return true


func _nearest_downed_friend() -> Player:
	var best: Player
	var best_d := tuning.revive_range
	for n in get_tree().get_nodes_in_group(&"player"):
		var p := n as Player
		if p == null or p == self or not p.is_downed():
			continue
		var d := p.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = p
	return best


## Get this (downed) player back on their feet. Works across the network.
func revive_by(reviver: Player) -> void:
	if is_multiplayer_authority():
		_on_revived(reviver.player_name)
	else:
		_net_revive.rpc_id(get_multiplayer_authority(), reviver.player_name)


@rpc("any_peer", "call_remote", "reliable")
func _net_revive(reviver_name: String) -> void:
	_on_revived(reviver_name)


func _on_revived(reviver_name: String) -> void:
	if state != State.DOWNED:
		return
	health = tuning.max_health * tuning.revive_health
	health_changed.emit(health, tuning.max_health)
	_set_state(State.MOVE)
	CombatFx.word(global_position + Vector3.UP * 2.0, "Revived by %s" % reviver_name)


# --- Network messages -----------------------------------------------------------

## The host says an enemy's blow reached this player. This player's own game
## decides what really happened (rolled through it? blocked? parried?).
@rpc("any_peer", "call_remote", "reliable")
func _net_enemy_hit(enemy_path: NodePath, attack_index: int, origin: Vector3) -> void:
	if multiplayer.get_remote_sender_id() != 1 or not is_multiplayer_authority():
		return
	var enemy := get_node_or_null(enemy_path) as Enemy
	if enemy == null:
		return
	var hit := enemy.make_hit(attack_index)
	hit.origin = origin
	# Favor the dodger: if on our screen we're already out of reach, it missed.
	var result := HitInfo.Result.DODGED
	if enemy.reaches(self, attack_index, 0.8):
		result = receive_hit(hit)
	enemy.report_hit_result.rpc_id(1, result)


## Let everyone else see this player's blood / sparks.
func _share_fx(kind: int, where: Vector3, dir: Vector3) -> void:
	if Net.is_online():
		_net_fx.rpc(kind, where, dir)


@rpc("authority", "call_remote", "unreliable")
func _net_fx(kind: int, where: Vector3, dir: Vector3) -> void:
	match kind:
		0:
			CombatFx.blood(where, dir)
		1:
			CombatFx.sparks(where, dir)
		2:
			CombatFx.sparks(where, dir, true)


# --- Death --------------------------------------------------------------------

func _die() -> void:
	_set_state(State.DEAD)
	is_sprinting = false
	is_blocking = false
	targeting.clear()
	model.play_death()
	died.emit()


func _state_dead(delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(Vector3.ZERO, tuning.deceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	move_and_slide()
	if _state_time >= RESPAWN_DELAY:
		respawn()


# --- Stamina ------------------------------------------------------------------

func _spend_stamina(amount: float) -> void:
	stamina = maxf(0.0, stamina - amount)
	_regen_cooldown = tuning.stamina_regen_delay
	stamina_changed.emit(stamina, tuning.max_stamina)


func _update_stamina(delta: float) -> void:
	if state == State.DEAD or state == State.ATTACK:
		return
	if _regen_cooldown > 0.0:
		_regen_cooldown -= delta
	elif stamina < tuning.max_stamina:
		var rate := tuning.stamina_regen * (tuning.block_regen_mult if is_blocking else 1.0)
		stamina = minf(tuning.max_stamina, stamina + rate * delta)
		stamina_changed.emit(stamina, tuning.max_stamina)
	if _sprint_locked and stamina >= tuning.sprint_restart_stamina:
		_sprint_locked = false
