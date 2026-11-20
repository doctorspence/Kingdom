@tool
class_name GrayboxStairs
extends Node3D
## A staircase for test maps, rising along local +X.
## The steps are only visual; you actually walk on a hidden smooth ramp under
## them, which is how most games make stairs feel smooth.

@export var steps := 15:
	set(v):
		steps = maxi(v, 1)
		_rebuild()
@export var rise := 0.2:
	set(v):
		rise = maxf(v, 0.02)
		_rebuild()
@export var tread := 0.3:
	set(v):
		tread = maxf(v, 0.05)
		_rebuild()
@export var width := 3.0:
	set(v):
		width = maxf(v, 0.1)
		_rebuild()
@export var material: Material:
	set(v):
		material = v
		_rebuild()

var _built: Node


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _built:
		_built.queue_free()
	var body := StaticBody3D.new()
	for i in steps:
		var box := BoxMesh.new()
		box.size = Vector3(tread, rise * (i + 1), width)
		box.material = material
		var mi := MeshInstance3D.new()
		mi.mesh = box
		mi.position = Vector3(tread * (i + 0.5), rise * (i + 1) * 0.5, 0.0)
		body.add_child(mi)
	var run := tread * steps
	var h := rise * steps
	var w := width * 0.5
	var shape := ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array([
		Vector3(-tread * 0.5, 0, -w), Vector3(-tread * 0.5, 0, w),
		Vector3(run, 0, -w), Vector3(run, 0, w),
		Vector3(run, h, -w), Vector3(run, h, w),
		Vector3(run - tread * 0.5, h, -w), Vector3(run - tread * 0.5, h, w),
	])
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	_built = body
