class_name PlayerCamera
extends Node3D
## Over-the-shoulder camera. Mouse or right stick to look around.
##
## A "spring arm" pulls the camera in when a wall gets between it and you,
## so it never ends up inside walls. When you lock on, the camera turns
## itself to keep the target in view.

@export var mouse_sensitivity := 0.0025
## Right-stick turn speed (radians per second at full tilt).
@export var stick_sensitivity := 3.2
@export var invert_y := false
@export var pitch_min_deg := -65.0
@export var pitch_max_deg := 50.0
## Height of the point the camera orbits around (about shoulder height).
@export var pivot_height := 1.55
## How tightly the camera follows you sideways / up and down (higher = tighter).
@export var follow_sharpness := 14.0
@export var vertical_sharpness := 8.0
## How fast the camera swings toward a locked target.
@export var lock_turn_sharpness := 9.0

var yaw := 0.0
var pitch := deg_to_rad(-12.0)
var follow: Node3D
var targeting: Targeting

var _recenter_yaw := NAN

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D


func _ready() -> void:
	top_level = true
	# The camera moves every rendered frame, not on the physics clock.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if follow:
		global_position = follow.global_position + Vector3.UP * pivot_height
		yaw = follow.global_rotation.y


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if not _is_locked():
			yaw -= event.relative.x * mouse_sensitivity
			pitch -= event.relative.y * mouse_sensitivity * (-1.0 if invert_y else 1.0)
			_recenter_yaw = NAN


## Swing the camera behind the given direction (used when lock-on finds nothing).
func recenter(direction: Vector3) -> void:
	if direction.length_squared() > 0.001:
		_recenter_yaw = atan2(-direction.x, -direction.z)


## The way the camera is looking, flattened (for turning stick input into movement).
func flat_basis() -> Basis:
	return Basis(Vector3.UP, yaw)


func _process(delta: float) -> void:
	if follow == null:
		return
	if not _is_locked():
		var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
		if look.length_squared() > 0.0:
			yaw -= look.x * stick_sensitivity * delta
			pitch -= look.y * stick_sensitivity * 0.7 * delta * (-1.0 if invert_y else 1.0)
			_recenter_yaw = NAN

	var pivot := follow.get_global_transform_interpolated().origin + Vector3.UP * pivot_height
	var t := 1.0 - exp(-lock_turn_sharpness * delta)
	if _is_locked():
		var to_target := targeting.target_point() - pivot
		var flat_len := Vector2(to_target.x, to_target.z).length()
		if flat_len > 0.5:
			yaw = lerp_angle(yaw, atan2(-to_target.x, -to_target.z), t)
			var target_pitch := clampf(atan2(to_target.y, flat_len) - 0.18, -0.7, 0.35)
			pitch = lerpf(pitch, target_pitch, t)
	elif not is_nan(_recenter_yaw):
		yaw = lerp_angle(yaw, _recenter_yaw, t)
		if absf(wrapf(_recenter_yaw - yaw, -PI, PI)) < 0.01:
			_recenter_yaw = NAN

	pitch = clampf(pitch, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
	rotation = Vector3(pitch, yaw, 0.0)

	# Follow smoothly: quick sideways, a little softer up and down (stairs, landings).
	var flat_t := 1.0 - exp(-follow_sharpness * delta)
	var up_t := 1.0 - exp(-vertical_sharpness * delta)
	var p := global_position
	p.x = lerpf(p.x, pivot.x, flat_t)
	p.z = lerpf(p.z, pivot.z, flat_t)
	p.y = lerpf(p.y, pivot.y, up_t)
	global_position = p


func _is_locked() -> bool:
	return targeting != null and targeting.has_target()
