class_name LootChest
extends Node3D
## A chest that rolls its drop table when opened (once, until someone rests at a shrine).
## Coins and souls go to everyone nearby; items drop on the floor for need/greed.

@export var table: LootTable
@export var chest_name := "Chest"

var opened := false
var _lid: Node3D


func _ready() -> void:
	add_to_group(&"interactables")
	add_to_group(&"respawn_on_rest")
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.1, 0.6, 0.7)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.38, 0.25, 0.13)
	bm.material = mat
	body.mesh = bm
	body.position.y = 0.3
	add_child(body)
	_lid = Node3D.new()
	_lid.position = Vector3(0, 0.6, -0.35)
	var lm := MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(1.1, 0.2, 0.7)
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.3, 0.2, 0.1)
	lb.material = lmat
	lm.mesh = lb
	lm.position = Vector3(0, 0.1, 0.35)
	_lid.add_child(lm)
	add_child(_lid)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.1, 0.8, 0.7)
	shape.shape = box
	shape.position.y = 0.4
	var sb := StaticBody3D.new()
	sb.add_child(shape)
	add_child(sb)


func get_interact_text() -> String:
	return "" if opened else "Open the %s" % chest_name


func interact(_player: Node3D) -> void:
	if opened:
		return
	if multiplayer.is_server():
		_open_on_host()
	else:
		_net_open.rpc_id(1)
		_show_open()


@rpc("any_peer", "call_remote", "reliable")
func _net_open() -> void:
	if multiplayer.is_server() and not opened:
		_open_on_host()


func _open_on_host() -> void:
	if opened:
		return
	_show_open()
	if Net.is_online():
		_net_opened.rpc()
	if table:
		Loot.enemy_died(self, table, 0)


@rpc("authority", "call_remote", "reliable")
func _net_opened() -> void:
	_show_open()


func _show_open() -> void:
	opened = true
	_lid.rotation_degrees.x = 100.0
	Audio.sfx(&"pickup", global_position)


## Someone rested: the chest is full again.
func reset_from_rest() -> void:
	if Net.is_online():
		_net_reset.rpc()
	_reset()


@rpc("authority", "call_remote", "reliable")
func _net_reset() -> void:
	_reset()


func _reset() -> void:
	opened = false
	_lid.rotation_degrees.x = 0.0
