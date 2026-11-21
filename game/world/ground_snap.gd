@tool
class_name GroundSnap
extends Node3D
## Puts every child on the ground: its height becomes the terrain height under
## it (plus an optional "y_offset" set in the child's metadata). Move things
## around freely in the editor; they stay standing on the ground.

@export var terrain: ZoneTerrain
@export var snap_now := false:
	set(v):
		snap()


func _ready() -> void:
	snap.call_deferred()


func snap() -> void:
	if terrain == null:
		return
	for c in get_children():
		var n := c as Node3D
		if n == null:
			continue
		var p := n.global_position
		n.global_position = Vector3(p.x, terrain.height_at(p.x, p.z) + float(n.get_meta("y_offset", 0.0)), p.z)
