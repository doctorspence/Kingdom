class_name TrainingDummy
extends AnimatableBody3D
## A straw training dummy. Lock on to it, hit it, read the numbers.
## It never dies. Optionally walks back and forth.

## How far it walks to each side (meters). 0 = stands still.
@export var patrol_distance := 0.0
@export var patrol_speed := 1.5
## Height of the lock-on marker.
@export var lock_height := 1.3

var _start: Vector3
var _time := 0.0
var _wobble := 0.0
var _wobble_vel := 0.0
var _wobble_axis := Vector3.RIGHT


func _ready() -> void:
	add_to_group(&"lock_targets")
	add_to_group(&"hittable")
	_start = global_position


func get_lock_point() -> Vector3:
	return global_position + Vector3.UP * lock_height


func can_be_locked() -> bool:
	return true


func hit_radius() -> float:
	return 0.35


func receive_hit(hit: HitInfo) -> HitInfo.Result:
	var top := global_position + Vector3.UP * 1.9
	CombatFx.damage_number(top, hit.damage, CombatFx.NumberKind.CRIT if hit.is_crit else CombatFx.NumberKind.NORMAL)
	CombatFx.sparks(global_position + Vector3.UP * 1.2, hit.origin - global_position)
	var away := global_position - hit.origin
	away.y = 0.0
	_wobble_axis = away.normalized().cross(Vector3.DOWN).normalized() if away.length() > 0.01 else Vector3.RIGHT
	_wobble_vel += 4.0 + hit.damage * 0.05
	return HitInfo.Result.HIT


func _physics_process(delta: float) -> void:
	# Springy wobble when hit.
	_wobble_vel += (-_wobble * 60.0 - _wobble_vel * 6.0) * delta
	_wobble += _wobble_vel * delta
	var tilt := Basis(_wobble_axis, clampf(_wobble, -0.5, 0.5)) if absf(_wobble) > 0.0005 else Basis.IDENTITY
	for c in get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).basis = tilt
	if patrol_distance > 0.0:
		_time += delta
		var omega := patrol_speed / patrol_distance
		global_position = _start + Vector3.RIGHT * sin(_time * omega) * patrol_distance
