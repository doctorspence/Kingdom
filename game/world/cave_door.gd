class_name CaveDoor
extends Node3D
## A way between the surface and the cave below (the Gullet is built under the
## quarry). Interact to go through to the matching door.

@export var door_name := "the Gullet"
@export var verb := "Descend into"
## The door on the other side (NodePath from this node).
@export var other: NodePath
## Where you stand when you arrive here (relative to this door).
@export var arrive_offset := Vector3(0, 0, 2)


func _ready() -> void:
	add_to_group(&"interactables")


func get_interact_text() -> String:
	return "%s %s" % [verb, door_name]


## Height doesn't matter for reaching a door (the cave mouth sits on a steep slope).
func interact_position(player: Node3D) -> Vector3:
	return Vector3(global_position.x, player.global_position.y, global_position.z)


## Where you stand when you arrive through this door (on the ground, if it's on the surface).
func arrival_point() -> Vector3:
	var p := global_transform * arrive_offset
	var zone := get_tree().get_first_node_in_group(&"zone_terrain") as ZoneTerrain
	if zone and global_position.y > -20.0:
		p.y = zone.height_at(p.x, p.z) + 0.1
	return p


func interact(player: Node3D) -> void:
	var dest := get_node_or_null(other) as CaveDoor
	if dest == null:
		return
	player.global_position = dest.arrival_point() + Vector3.UP * 0.4
	player.velocity = Vector3.ZERO
	if player.has_method(&"face_toward"):
		player.call(&"face_toward", -dest.global_transform.basis.z)
