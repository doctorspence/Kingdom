class_name EnemyArrow
extends Node3D
## An arrow shot by an archer. Flies straight and fast enough to read, and stops at the
## first wall, barrel or player. Only the host's copy deals damage; the rest are for show.

var shooter: Enemy
var attack_index := 0
var direction := Vector3.FORWARD
var speed := 22.0
var max_range := 22.0
var damaging := true

var _travelled := 0.0
var _stuck := -1.0


func _ready() -> void:
	var shaft := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.03, 0.03, 0.8)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.38, 0.22)
	box.material = mat
	shaft.mesh = box
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shaft)
	_face()


func _physics_process(delta: float) -> void:
	if _stuck >= 0.0:
		_stuck += delta
		if _stuck > 6.0:
			queue_free()
		return
	var step := direction * speed * delta
	var from := global_position
	var q := PhysicsRayQueryParameters3D.create(from, from + step, 1 | 2)
	if is_instance_valid(shooter):
		q.exclude = [shooter.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		global_position = hit.position
		var c := hit.collider as Node
		if damaging and c is Player and is_instance_valid(shooter):
			shooter.arrow_hit_player(c as Player, attack_index, _origin())
			queue_free()
		elif damaging and c and c.has_method(&"arrow_triggered"):
			c.call(&"arrow_triggered", shooter)
			queue_free()
		elif c is Player:
			queue_free()  # a friend's copy: just vanish
		else:
			_stuck = 0.0
		return
	global_position = from + step
	_travelled += step.length()
	if _travelled > max_range:
		queue_free()


func _origin() -> Vector3:
	return shooter.global_position if is_instance_valid(shooter) else global_position


func _face() -> void:
	look_at(global_position + direction, Vector3.UP if absf(direction.y) < 0.99 else Vector3.RIGHT)
