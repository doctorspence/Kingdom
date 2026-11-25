extends Node
## Draws the underground level only while the camera is underground, and the
## surface's woods and clutter only while it is above. The Gullet lies under
## the Tithelands' ground; without this it was drawn through the earth from
## the whole zone (about 20 million triangles a frame).
##
## The way down (QuarryDescent) is one continuous space, so the two overlap there:
## the Gullet is drawn from the descent's first bend on, and the surface only gives
## way once the camera is well below it.

## Shown only underground.
@export var underground: Array[NodePath] = []
## Shown only on the surface.
@export var surface: Array[NodePath] = []
## The surface is hidden below this height (meters).
@export var below_y := 0.0
## The underground level is drawn this far (meters) into the descent.
@export var descent_from := 8.0

var _draw_under := -1
var _draw_surface := -1


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var deep := cam.global_position.y < below_y
	var in_descent := QuarryDescent.path_s(cam.global_position) > descent_from
	var want_under := 1 if (deep or in_descent) else 0
	var want_surface := 0 if deep else 1
	if want_under != _draw_under:
		_draw_under = want_under
		for p in underground:
			var n := get_node_or_null(p) as Node3D
			if n:
				n.visible = want_under == 1
	if want_surface != _draw_surface:
		_draw_surface = want_surface
		for p in surface:
			var n := get_node_or_null(p) as Node3D
			if n:
				n.visible = want_surface == 1
