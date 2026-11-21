class_name BossRoom
extends Node3D
## Marks a boss arena (used from Phase 9). If you die inside it, your death
## pile appears at the boss door instead, so you can recover it without
## fighting the boss again.
##   - `size`: the arena's box (centered on this node).
##   - Child Marker3D named "Door": where piles go.

@export var size := Vector3(30, 12, 30)


func _ready() -> void:
	add_to_group(&"boss_rooms")


func contains(point: Vector3) -> bool:
	var local := global_transform.affine_inverse() * point
	var half := size * 0.5
	return absf(local.x) <= half.x and absf(local.y) <= half.y and absf(local.z) <= half.z


func pile_point() -> Vector3:
	var door := get_node_or_null("Door") as Node3D
	return door.global_position if door else global_position
