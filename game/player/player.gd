class_name Player
extends CharacterBody3D
## The player character: movement, rolling, jumping, stamina, health and falls.
##
## All the numbers come from data/balance/player_tuning.tres.
## The character can be in one "state" at a time:
##   MOVE    on the ground: walk, run, sprint
##   AIR     jumping or falling
##   ROLL    dodge roll (invincible for the first part)
##   LANDING stumbling after a hard landing
##   DEAD    waiting to respawn

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal died
signal respawned

enum State { MOVE, AIR, ROLL, LANDING, DEAD }

const RESPAWN_DELAY := 3.0
## Below this height you've fallen out of the world.
const KILL_HEIGHT := -60.0
## Test equip loads that F3 cycles through (gear weight ÷ capacity).
const TEST_LOADS := [0.2, 0.5, 0.9, 1.2]

@export var tuning: PlayerTuning = preload("res://data/balance/player_tuning.tres")
## Gear weight ÷ carrying capacity. Phase 6 will compute this from your gear.
@export var equip_load := 0.2

var state := State.MOVE
var health := 100.0
var stamina := 100.0
var is_sprinting := false
var is_walking := false
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
var _buffered := &""
var _buffer_timer := 0.0
var _dodge_held := -1.0
var _spawn: Transform3D

@onready var model: PlayerModel = $Visual
@onready var camera_rig: PlayerCamera = $CameraRig
@onready var targeting: Targeting = $Targeting


func _ready() -> void:
	add_to_group(&"player")
	# The body itself never rotates; only the visible model turns.
	_spawn = global_transform
	global_basis = Basis.IDENTITY
	health = tuning.max_health
	stamina = tuning.max_stamina
	camera_rig.follow = self
	camera_rig.targeting = targeting
	targeting.camera = camera_rig.camera
	_face_spawn_direction()


# --- Public -------------------------------------------------------------------

func is_invulnerable() -> bool:
	return _iframe_timer > 0.0


func load_tier() -> PlayerTuning.LoadTier:
	return tuning.load_tier(equip_load)


func state_name() -> String:
	return State.keys()[state]


## Take damage. Falls ignore invincibility; attacks (Phase 3) don't.
func take_damage(amount: float, ignore_iframes := false) -> void:
	if state == State.DEAD or amount <= 0.0:
		return
	if is_invulnerable() and not ignore_iframes:
		return
	health = maxf(0.0, health - amount)
	health_changed.emit(health, tuning.max_health)
	if health <= 0.0:
		_die()


func respawn() -> void:
	global_position = _spawn.origin
	velocity = Vector3.ZERO
	health = tuning.max_health
	stamina = tuning.max_stamina
	_sprint_locked = false
	_iframe_timer = 0.0
	targeting.clear()
	_face_spawn_direction()
	_set_state(State.MOVE)
	health_changed.emit(health, tuning.max_health)
	stamina_changed.emit(stamina, tuning.max_stamina)
	respawned.emit()


func _face_spawn_direction() -> void:
	var facing := -_spawn.basis.z
	model.face_instantly(facing)
	camera_rig.yaw = atan2(-facing.x, -facing.z)
	camera_rig.global_position = global_position + Vector3.UP * camera_rig.pivot_height
	model.reset_physics_interpolation()
	reset_physics_interpolation()


# --- Input --------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		_buffer(&"jump")
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
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")


## Turn stick/WASD input into a world direction, relative to the camera.
func _input_direction() -> Vector3:
	var v := _move_input()
	return camera_rig.flat_basis() * Vector3(v.x, 0.0, v.y)


func _wants_sprint() -> bool:
	return _dodge_held >= tuning.dodge_hold_time


# --- Main loop ----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_state_time += delta
	_iframe_timer = maxf(0.0, _iframe_timer - delta)
	_buffer_timer = maxf(0.0, _buffer_timer - delta)
	_read_dodge_button(delta)

	match state:
		State.MOVE:
			_state_move(delta)
		State.AIR:
			_state_air(delta)
		State.ROLL:
			_state_roll(delta)
		State.LANDING:
			_state_landing(delta)
		State.DEAD:
			_state_dead(delta)

	if global_position.y < KILL_HEIGHT and state != State.DEAD:
		take_damage(health, true)
	_update_stamina(delta)
	model.show_iframes(show_debug and is_invulnerable())


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

	var locked := targeting.has_target()
	var overloaded := load_tier() == PlayerTuning.LoadTier.OVERLOADED
	is_walking = Input.is_action_pressed("walk") or (amount > 0.0 and amount < tuning.walk_stick_threshold)
	is_sprinting = _wants_sprint() and amount > 0.3 and not overloaded and not _sprint_locked and stamina > 0.0

	var speed := tuning.run_speed
	if is_sprinting:
		speed = tuning.sprint_speed
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

	if amount > 0.0 and not is_sprinting and horizontal.length() > 0.1:
		# Swing the current movement toward the new direction, keeping speed.
		var cur_speed := horizontal.length()
		var cur_dir := horizontal / cur_speed
		var want_dir := target_velocity.normalized()
		var max_turn := deg_to_rad(tuning.direction_change_speed) * delta
		var angle := cur_dir.signed_angle_to(want_dir, Vector3.UP)
		if absf(angle) > PI - 0.05:
			angle = PI  # straight reversal: pick a side
		cur_dir = cur_dir.rotated(Vector3.UP, clampf(angle, -max_turn, max_turn))
		var rate := tuning.acceleration if cur_speed < speed else tuning.deceleration
		horizontal = cur_dir * move_toward(cur_speed, speed, rate * delta)
	else:
		var rate := tuning.acceleration if target_velocity.length() >= horizontal.length() else tuning.deceleration
		horizontal = horizontal.move_toward(target_velocity, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	move_and_slide()

	if is_sprinting and horizontal.length() > 1.0:
		_spend_stamina(tuning.sprint_stamina_per_second * delta)
		if stamina <= 0.0:
			_sprint_locked = true
	model.update_locomotion(Vector3(velocity.x, 0.0, velocity.z).length(), is_sprinting, is_walking)


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


func _state_landing(delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(Vector3.ZERO, tuning.deceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	move_and_slide()
	if _state_time >= tuning.hard_landing_time:
		_set_state(State.MOVE)


# --- Death --------------------------------------------------------------------

func _die() -> void:
	_set_state(State.DEAD)
	is_sprinting = false
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
	if state == State.DEAD:
		return
	if _regen_cooldown > 0.0:
		_regen_cooldown -= delta
	elif stamina < tuning.max_stamina:
		stamina = minf(tuning.max_stamina, stamina + tuning.stamina_regen * delta)
		stamina_changed.emit(stamina, tuning.max_stamina)
	if _sprint_locked and stamina >= tuning.sprint_restart_stamina:
		_sprint_locked = false
