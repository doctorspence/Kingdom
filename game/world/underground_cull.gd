extends Node
## Draws the underground level only while the camera is underground, and the
## surface's woods and clutter only while it is above. The Gullet lies under
## the Tithelands' ground; without this it was drawn through the earth from
## the whole zone (about 20 million triangles a frame).

## Shown only underground.
@export var underground: Array[NodePath] = []
## Shown only on the surface.
@export var surface: Array[NodePath] = []
## The camera counts as underground below this height (meters).
@export var below_y := -12.0

var _under := -1


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var under := 1 if cam.global_position.y < below_y else 0
	if under == _under:
		return
	_under = under
	for p in underground:
		var n := get_node_or_null(p) as Node3D
		if n:
			n.visible = under == 1
	for p in surface:
		var n := get_node_or_null(p) as Node3D
		if n:
			n.visible = under == 0
