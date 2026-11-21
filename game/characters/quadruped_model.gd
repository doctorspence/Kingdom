class_name QuadrupedModel
extends CharacterModel
## A stand-in four-legged body (Gaunt Hound) made of boxes, animated by code
## instead of animation files. Works with everything that drives a
## CharacterModel; "animations" are just names: idle, walk, run, bite, lunge,
## howl, hit, stagger, death. Swap for a real rigged wolf later.

const LENGTHS := {&"bite": 0.75, &"lunge": 1.0, &"howl": 1.2, &"hit": 0.3, &"stagger": 0.8, &"death": 1.0}

@export var coat := Color(0.22, 0.2, 0.18)

var _body: Node3D
var _head: Node3D
var _legs: Array[Node3D] = []
var _t := 0.0
var _speed := 1.0
var _frozen := false
var _stride := 0.0


func _ready() -> void:
	idle_anim = &"idle"
	var mat := StandardMaterial3D.new()
	mat.albedo_color = coat
	mat.roughness = 0.95
	_body = Node3D.new()
	_body.position.y = 0.75
	add_child(_body)
	_box(_body, Vector3(0.36, 0.34, 1.05), Vector3.ZERO, mat)  # torso
	_box(_body, Vector3(0.12, 0.12, 0.55), Vector3(0, 0.05, -0.75), mat, Vector3(-30, 0, 0))  # tail
	_head = Node3D.new()
	_head.position = Vector3(0, 0.22, 0.62)
	_body.add_child(_head)
	_box(_head, Vector3(0.26, 0.26, 0.32), Vector3(0, 0, 0.1), mat)
	_box(_head, Vector3(0.16, 0.14, 0.3), Vector3(0, -0.05, 0.38), mat)  # snout
	_box(_head, Vector3(0.07, 0.14, 0.05), Vector3(0.09, 0.18, 0.05), mat)  # ears
	_box(_head, Vector3(0.07, 0.14, 0.05), Vector3(-0.09, 0.18, 0.05), mat)
	for p in [Vector3(0.14, 0, 0.4), Vector3(-0.14, 0, 0.4), Vector3(0.14, 0, -0.42), Vector3(-0.14, 0, -0.42)]:
		var hip := Node3D.new()
		hip.position = p + Vector3(0, -0.12, 0)
		_body.add_child(hip)
		_box(hip, Vector3(0.09, 0.62, 0.09), Vector3(0, -0.31, 0), mat)
		_legs.append(hip)
	for m in find_children("*", "MeshInstance3D", true, false):
		_meshes.append(m)
	_overlay = StandardMaterial3D.new()
	_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	play(&"idle", 0.0)


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	b.material = mat
	mi.mesh = b
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)


func _process(delta: float) -> void:
	if not _frozen:
		_t += delta * _speed
	var phase := 0.0
	var clip_len: float = LENGTHS.get(_current, 1.0)
	var u := clampf(_t / clip_len, 0.0, 1.0)
	_body.rotation = Vector3.ZERO
	_body.position = Vector3(0, 0.75, 0)
	_head.rotation = Vector3.ZERO
	var swing := 0.0
	match _current:
		&"walk":
			_stride += delta * 7.0 * _speed
			swing = 0.45
		&"run":
			_stride += delta * 13.0 * _speed
			swing = 0.85
			_body.position.y += absf(sin(_stride)) * 0.08
		&"bite":
			# Wind up (head back), snap forward.
			var snap := sin(clampf((u - 0.25) / 0.3, 0.0, 1.0) * PI)
			_head.rotation.x = deg_to_rad(-25.0) * (1.0 - u * 3.0 if u < 0.33 else 0.0) + deg_to_rad(20.0) * snap
			_body.position.z = 0.25 * snap
		&"lunge":
			var leap := sin(clampf((u - 0.2) / 0.35, 0.0, 1.0) * PI)
			_body.position.y += leap * 0.45
			_body.rotation.x = deg_to_rad(-15.0) * leap
			swing = 0.7 * leap
			_stride += delta * 10.0
		&"howl":
			_head.rotation.x = deg_to_rad(-55.0) * sin(u * PI)
			_body.rotation.x = deg_to_rad(-10.0) * sin(u * PI)
		&"hit", &"stagger":
			_body.rotation.z = deg_to_rad(12.0) * sin(u * PI)
		&"death":
			_body.rotation.z = deg_to_rad(90.0) * u
			_body.position.y = 0.75 - 0.4 * u
		_:
			_head.rotation.x = sin(_t * 1.5) * 0.05
	phase = _stride
	for i in _legs.size():
		var off := PI if i in [1, 2] else 0.0
		_legs[i].rotation.x = sin(phase + off) * swing


func play(anim_name: StringName, _blend := 0.15, speed := 1.0, restart := false) -> void:
	var mapped := _map(anim_name)
	_speed = speed
	if mapped == _current and not restart:
		return
	_current = mapped
	_t = 0.0
	play_count += 1


## Names from humanoid code map to our own (Idle -> idle, Jog_Fwd -> run...).
func _map(anim_name: StringName) -> StringName:
	match anim_name:
		ANIM_IDLE, &"Sword_Idle", &"idle":
			return &"idle"
		ANIM_WALK, &"walk":
			return &"walk"
		ANIM_RUN, ANIM_SPRINT, &"run":
			return &"run"
		ANIM_DEATH, &"death":
			return &"death"
		ANIM_HIT, &"hit":
			return &"hit"
		ANIM_STAGGER, ANIM_GUARD_BREAK, &"stagger":
			return &"stagger"
	return anim_name


func update_locomotion(ground_speed: float, _sprinting: bool, _walking: bool) -> void:
	if ground_speed < 0.15:
		play(&"idle")
	elif ground_speed < 3.0:
		play(&"walk", 0.2, ground_speed / 1.8)
	else:
		play(&"run", 0.2, ground_speed / 6.0)


func set_speed(speed: float) -> void:
	_speed = speed


func get_speed() -> float:
	return _speed


func hold(frozen: bool) -> void:
	_frozen = frozen


func seek(time: float) -> void:
	_t = time


func anim_length(anim_name: StringName) -> float:
	return LENGTHS.get(_map(anim_name), 1.0)


func mirror(anim_name: StringName, speed: float, count: int) -> void:
	if count != _mirrored_count:
		_mirrored_count = count
		_current = _map(anim_name)
		_t = 0.0
	_speed = speed


func attach_to_hand(item: Node3D, _side: String) -> void:
	item.queue_free()  # hounds don't hold things


func set_body(_slender: bool) -> void:
	pass
