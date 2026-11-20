class_name Targeting
extends Node
## Lock-on and soft targeting.
##
## Anything in the "lock_targets" group with a get_lock_point() function can be
## locked onto (training dummies now, enemies later).
##  - Lock-on: Q / R3 toggles. Mouse wheel or a right-stick flick switches target.
##    It breaks when the target is too far away or out of sight for too long.
##  - Soft target: when you attack (Phase 3), you turn toward the best enemy
##    close by in the direction you're pushing. No camera lock.

signal target_changed(new_target: Node3D)

const GROUP := &"lock_targets"

@export var acquire_distance := 20.0
@export var break_distance := 25.0
@export var lose_sight_time := 2.0
## How far off the center of the screen (degrees) a target can be to lock on.
@export var acquire_angle := 50.0
@export var soft_target_range := 4.0
@export var soft_target_angle := 60.0
## Line-of-sight checks only look at world geometry (layer 1).
@export_flags_3d_physics var sight_mask := 1

var target: Node3D
var camera: Camera3D

var _out_of_sight := 0.0
var _flick_ready := true

@onready var _owner: Node3D = get_parent()


func has_target() -> bool:
	return target != null


func target_point() -> Vector3:
	return target.call(&"get_lock_point") if target else Vector3.ZERO


## Lock on if nothing is locked, otherwise let go. Returns false if nothing was found.
func toggle() -> bool:
	if target:
		clear()
		return true
	var best := _best_target()
	if best:
		_set_target(best)
		return true
	return false


func clear() -> void:
	_set_target(null)


## Switch to the next target to the right (+1) or left (-1) on screen.
func switch_target(direction: int) -> void:
	if target == null or camera == null:
		return
	var current_x := camera.unproject_position(target_point()).x
	var best: Node3D
	var best_dx := INF
	for c in _candidates(acquire_distance + 5.0):
		if c == target:
			continue
		var point: Vector3 = c.call(&"get_lock_point")
		if camera.is_position_behind(point):
			continue
		var dx := (camera.unproject_position(point).x - current_x) * direction
		if dx > 0.0 and dx < best_dx:
			best_dx = dx
			best = c
	if best:
		_set_target(best)


## The best enemy to swing at, in the direction you're pushing (or facing).
func find_soft_target(direction: Vector3) -> Node3D:
	var origin := _owner.global_position
	var best: Node3D
	var best_score := INF
	for c in _candidates(soft_target_range):
		var to: Vector3 = c.call(&"get_lock_point") - origin
		to.y = 0.0
		var angle := rad_to_deg(direction.angle_to(to)) if direction.length_squared() > 0.001 else 0.0
		if angle > soft_target_angle:
			continue
		var score := angle + to.length() * 10.0
		if score < best_score:
			best_score = score
			best = c
	return best


func _physics_process(delta: float) -> void:
	if target == null:
		return
	if not is_instance_valid(target) or not target.is_inside_tree() \
			or (target.has_method("can_be_locked") and not target.call(&"can_be_locked")):
		clear()
		return
	var point := target_point()
	if _owner.global_position.distance_to(point) > break_distance:
		clear()
		return
	_out_of_sight = 0.0 if _can_see(point) else _out_of_sight + delta
	if _out_of_sight > lose_sight_time:
		clear()
		return
	# Right-stick flick switches targets while locked on.
	var stick_x := Input.get_axis("look_left", "look_right")
	if _flick_ready and absf(stick_x) > 0.75:
		_flick_ready = false
		switch_target(1 if stick_x > 0.0 else -1)
	elif absf(stick_x) < 0.3:
		_flick_ready = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("target_next"):
		switch_target(1)
	elif event.is_action_pressed("target_prev"):
		switch_target(-1)


func _best_target() -> Node3D:
	if camera == null:
		return null
	var cam_forward := -camera.global_transform.basis.z
	var best: Node3D
	var best_score := INF
	for c in _candidates(acquire_distance):
		var point: Vector3 = c.call(&"get_lock_point")
		var to := point - camera.global_position
		var angle := rad_to_deg(cam_forward.angle_to(to))
		var dist := _owner.global_position.distance_to(point)
		# Very close targets count even if they're off to the side.
		if angle > acquire_angle and dist > 4.0:
			continue
		var score := angle + dist * 1.5
		if score < best_score:
			best_score = score
			best = c
	return best


func _candidates(max_distance: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for n in get_tree().get_nodes_in_group(GROUP):
		var c := n as Node3D
		if c == null or not c.has_method("get_lock_point"):
			continue
		if c.has_method("can_be_locked") and not c.call(&"can_be_locked"):
			continue
		var point: Vector3 = c.call(&"get_lock_point")
		if _owner.global_position.distance_to(point) > max_distance:
			continue
		if not _can_see(point):
			continue
		result.append(c)
	return result


func _can_see(point: Vector3) -> bool:
	var from := _owner.global_position + Vector3.UP * 1.5
	var query := PhysicsRayQueryParameters3D.create(from, point, sight_mask)
	return _owner.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _set_target(t: Node3D) -> void:
	if t == target:
		return
	target = t
	_out_of_sight = 0.0
	target_changed.emit(target)
