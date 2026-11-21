extends Node3D
## An arrow in flight. Flies straight, drops a little, and stops at the first
## wall or enemy it touches. Only the shooter's copy deals damage; everyone
## else's copy is just for show.

const GRAVITY := 3.0

var shooter: Player
var attack: AttackData
var charge := 0.0
var direction := Vector3.FORWARD
var speed := 40.0
var max_range := 40.0

var _velocity := Vector3.ZERO
var _travelled := 0.0
var _stuck := -1.0


func _ready() -> void:
	_velocity = direction.normalized() * speed
	var shaft := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.02, 0.02, 0.75)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.25, 0.15)
	box.material = mat
	shaft.mesh = box
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shaft)
	_face()


func _physics_process(delta: float) -> void:
	if _stuck >= 0.0:
		_stuck += delta
		if _stuck > 8.0:
			queue_free()
		return
	_velocity.y -= GRAVITY * delta
	var step := _velocity * delta
	var from := global_position
	var to := from + step
	var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 4)
	if is_instance_valid(shooter):
		q.exclude = [shooter.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		global_position = hit.position
		var target := hit.collider as Node3D
		if target and target.has_method("receive_hit"):
			if is_instance_valid(shooter) and attack:
				shooter.arrow_hit(target, attack, charge)
			queue_free()
		else:
			_stuck = 0.0  # stuck in a wall
		return
	global_position = to
	_face()
	_travelled += step.length()
	if _travelled > max_range * 1.5:
		queue_free()


func _face() -> void:
	if _velocity.length() > 0.01:
		look_at(global_position + _velocity, Vector3.UP if absf(_velocity.normalized().y) < 0.99 else Vector3.RIGHT)
