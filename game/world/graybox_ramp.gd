@tool
class_name GrayboxRamp
extends Node3D
## A solid ramp for test maps. It rises along its local +X axis.
## Change height, angle and width in the Inspector; it rebuilds itself.

@export var height := 3.0:
	set(v):
		height = maxf(v, 0.1)
		_rebuild()
@export_range(5.0, 75.0) var angle_deg := 30.0:
	set(v):
		angle_deg = v
		_rebuild()
@export var width := 4.0:
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


func run_length() -> float:
	return height / tan(deg_to_rad(angle_deg))


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _built:
		_built.queue_free()
	var run := run_length()
	var w := width * 0.5
	var body := StaticBody3D.new()
	var mesh := PrismMesh.new()
	mesh.left_to_right = 1.0
	mesh.size = Vector3(run, height, width)
	mesh.material = material
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = Vector3(run * 0.5, height * 0.5, 0.0)
	body.add_child(mi)
	var shape := ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array([
		Vector3(0, 0, -w), Vector3(0, 0, w),
		Vector3(run, 0, -w), Vector3(run, 0, w),
		Vector3(run, height, -w), Vector3(run, height, w),
	])
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	_built = body
