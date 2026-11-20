class_name TrainingDummy
extends AnimatableBody3D
## A straw training dummy you can lock on to. Optionally walks back and forth.

## How far it walks to each side (meters). 0 = stands still.
@export var patrol_distance := 0.0
@export var patrol_speed := 1.5
## Height of the lock-on marker.
@export var lock_height := 1.3

var _start: Vector3
var _time := 0.0


func _ready() -> void:
	add_to_group(&"lock_targets")
	_start = global_position


func get_lock_point() -> Vector3:
	return global_position + Vector3.UP * lock_height


func can_be_locked() -> bool:
	return true


func _physics_process(delta: float) -> void:
	if patrol_distance <= 0.0:
		return
	_time += delta
	var omega := patrol_speed / patrol_distance
	global_position = _start + global_basis.x * sin(_time * omega) * patrol_distance
