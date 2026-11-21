class_name SecretWall
extends StaticBody3D
## A cracked section of rock that hides a passage (the Gullet's hidden chest room).
## Interact to push it open; it then stays open (saved with the world).

@export var wall_id := &"secret_wall"
@export var width := 3.4
@export var wall_height := 3.6

var _mesh: MeshInstance3D
var _shape: CollisionShape3D


func _ready() -> void:
	add_to_group(&"interactables")
	_mesh = MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = Vector3(0.4, wall_height, width)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.17, 0.14, 0.11)
	mat.roughness = 1.0
	m.material = mat
	_mesh.mesh = m
	_mesh.position.y = wall_height * 0.5
	add_child(_mesh)
	# A pale crack, easy to miss.
	var crack := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(0.05, 1.8, 0.06)
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.4, 0.34, 0.26)
	cm.material = cmat
	crack.mesh = cm
	crack.position = Vector3(0.22, 1.5, 0.4)
	crack.rotation.x = 0.2
	add_child(crack)
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.4, wall_height, width)
	_shape.shape = box
	_shape.position.y = wall_height * 0.5
	add_child(_shape)
	WorldState.flag_changed.connect(func(key: StringName, _v: Variant) -> void:
		if key == _flag():
			_show_open(true))
	if is_open():
		_show_open(false)


func _flag() -> StringName:
	return StringName("opened_" + String(wall_id))


func is_open() -> bool:
	return WorldState.get_flag(_flag(), false)


func get_interact_text() -> String:
	return "" if is_open() else "Push the cracked wall"


func interact(_player: Node3D) -> void:
	if is_open():
		return
	WorldState.set_flag(_flag(), true)
	Audio.sfx(&"shield_bash", global_position, -2.0)
	CombatFx.word(global_position + Vector3.UP * 2.0, "The wall gives way")


func _show_open(animate: bool) -> void:
	_shape.set_deferred(&"disabled", true)
	remove_from_group(&"interactables")
	if animate:
		var tween := create_tween()
		tween.tween_property(_mesh, "position:y", -wall_height * 0.5, 1.0).set_trans(Tween.TRANS_SINE)
	else:
		_mesh.position.y = -wall_height * 0.5
