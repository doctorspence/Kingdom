@tool
class_name Ladder
extends Node3D
## A ladder. Interact to grab it, then W / S (or the stick) to climb.
## Jump (or Space) lets go. At the top you step off onto `top_exit`.
## The ladder goes up along this node's +Y; you stand on its +Z side.

@export var height := 6.0:
	set(v):
		height = maxf(v, 1.0)
		_build()
## Where you step off at the top, relative to the ladder's base.
@export var top_exit := Vector3(0, 0, -0.9)
## If set, the height is measured from the ground here (relative to the base) instead.
@export var terrain: ZoneTerrain
@export var top_ground_point := Vector3.ZERO

var _visual: Node3D


func _ready() -> void:
	add_to_group(&"interactables")
	if terrain:
		_fit_to_terrain.call_deferred()
	else:
		_build()


func _fit_to_terrain() -> void:
	var p := global_transform * top_ground_point
	height = terrain.height_at(p.x, p.z) - terrain.height_at(global_position.x, global_position.z)
	top_exit = Vector3(top_ground_point.x, height, top_ground_point.z)


func _build() -> void:
	if not is_inside_tree():
		return
	if _visual:
		_visual.queue_free()
	_visual = Node3D.new()
	var mat := load("res://levels/common/materials/wood.tres") as Material
	for side in [-0.3, 0.3]:
		var rail := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(0.07, height + 0.8, 0.07)
		m.material = mat
		rail.mesh = m
		rail.position = Vector3(side, (height + 0.8) * 0.5, 0)
		_visual.add_child(rail)
	var rungs := int(height / 0.35)
	for i in rungs:
		var rung := MeshInstance3D.new()
		var m2 := BoxMesh.new()
		m2.size = Vector3(0.6, 0.05, 0.05)
		m2.material = mat
		rung.mesh = m2
		rung.position = Vector3(0, 0.3 + i * 0.35, 0)
		_visual.add_child(rung)
	add_child(_visual)


## Where a climber's feet go at a given height (0..height).
func climb_point(h: float) -> Vector3:
	return global_transform * Vector3(0, h, 0.42)


func top_exit_point() -> Vector3:
	return global_transform * top_exit


func facing() -> Vector3:
	return -global_transform.basis.z


func get_interact_text() -> String:
	return "Climb the ladder"


func interact(player: Node3D) -> void:
	player.call(&"start_climb", self)


## You can grab it at the bottom or at the top.
func interact_position(player: Node3D) -> Vector3:
	if player.global_position.y > global_position.y + height * 0.5:
		return top_exit_point()
	return climb_point(0.0)
