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


## Where you stand when you arrive through this door.
func arrival_point() -> Vector3:
	return global_transform * arrive_offset


func interact(player: Node3D) -> void:
	var dest := get_node_or_null(other) as CaveDoor
	if dest == null:
		return
	player.global_position = dest.arrival_point() + Vector3.UP * 0.4
	player.velocity = Vector3.ZERO
	if player.has_method(&"face_toward"):
		player.call(&"face_toward", -dest.global_transform.basis.z)
