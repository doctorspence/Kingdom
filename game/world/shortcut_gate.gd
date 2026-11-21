class_name ShortcutGate
extends StaticBody3D
## A gate that only opens from one side (the node's -Z side). Once opened it
## stays open for everyone in this world, and the host's world save remembers.

@export var gate_id := &"gate"
@export var width := 6.0
@export var gate_height := 3.4
## If set, nobody opens it by hand: it opens by itself when this world flag turns on (a boss kill).
@export var open_flag := &""

var _door: MeshInstance3D
var _shape: CollisionShape3D


func _ready() -> void:
	if open_flag == &"":
		add_to_group(&"interactables")
	_door = MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = Vector3(width, gate_height, 0.3)
	m.material = load("res://levels/common/materials/dark_wood.tres")
	_door.mesh = m
	_door.position.y = gate_height * 0.5
	add_child(_door)
	_dress_door()
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, gate_height, 0.4)
	_shape.shape = box
	_shape.position.y = gate_height * 0.5
	add_child(_shape)
	WorldState.flag_changed.connect(func(key: StringName, _v: Variant) -> void:
		if key == _flag():
			_show_open(true))
	if is_open():
		_show_open(false)


## Iron straps across both faces and heavy posts at the edges, so it reads as
## a barred gate and not a slab. They are children of the door, so they move with it.
func _dress_door() -> void:
	var iron: Material = load("res://levels/common/materials/iron.tres")
	var timber: Material = load("res://levels/common/materials/wood.tres")
	for face in [-1.0, 1.0]:
		for frac in [0.18, 0.5, 0.82]:
			var strap := MeshInstance3D.new()
			var sm := BoxMesh.new()
			sm.size = Vector3(width * 0.98, 0.2, 0.06)
			sm.material = iron
			strap.mesh = sm
			strap.position = Vector3(0, (frac - 0.5) * gate_height, face * 0.18)
			_door.add_child(strap)
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.4, gate_height + 0.5, 0.55)
		pm.material = timber
		post.mesh = pm
		post.position = Vector3(side * (width * 0.5 + 0.1), 0.25, 0)
		_door.add_child(post)
	var lintel := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(width + 0.9, 0.4, 0.6)
	lm.material = timber
	lintel.mesh = lm
	lintel.position = Vector3(0, gate_height * 0.5 + 0.3, 0)
	_door.add_child(lintel)


func _flag() -> StringName:
	if open_flag != &"":
		return open_flag
	return StringName("opened_" + String(gate_id))


func is_open() -> bool:
	return WorldState.get_flag(_flag(), false)


func get_interact_text() -> String:
	if is_open():
		return ""
	return "Open the gate"


func interact(player: Node3D) -> void:
	if is_open() or open_flag != &"":
		return
	var to_player := player.global_position - global_position
	if to_player.dot(global_transform.basis.z) > 0.0:
		CombatFx.word(global_position + Vector3.UP * 3.0, "It won't open from this side")
		return
	WorldState.set_flag(_flag(), true)
	Net.system_message("A shortcut has opened.")


func _show_open(animate: bool) -> void:
	_shape.disabled = true
	remove_from_group(&"interactables")
	if animate:
		var tween := create_tween()
		tween.tween_property(_door, "position:y", -gate_height * 0.5 + 0.1, 1.2).set_trans(Tween.TRANS_SINE)
	else:
		_door.position.y = -gate_height * 0.5 + 0.1
