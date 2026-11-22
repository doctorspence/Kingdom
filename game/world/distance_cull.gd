class_name DistanceCull
extends Node
## Stops drawing small props from far away. Once the zone's props exist, every
## mesh under the listed roots gets a draw distance based on its size: a crate
## is gone past about 90 m, a cottage is kept to 450 m. Cuts draw calls and
## triangles in busy views. Skips things that already have a range, batched
## MultiMeshes (they have their own) and anything under "keep_names".

@export var roots: Array[NodePath] = []
## Draw distance = largest side of the mesh times this, within the limits below.
@export var meters_per_size := 28.0
@export var min_range := 70.0
@export var max_range := 450.0
## Wait this long after the zone loads, so props built in _ready have appeared.
@export var delay := 1.5

var culled := 0


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_apply.call_deferred()


func _apply() -> void:
	await get_tree().create_timer(delay).timeout
	culled = 0
	for p in roots:
		var root := get_node_or_null(p)
		if root:
			_walk(root)
	print("DistanceCull: %d meshes given a draw distance" % culled)


func _walk(n: Node) -> void:
	if n is MultiMeshInstance3D:
		return
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh != null and mi.visibility_range_end <= 0.0:
			var box := mi.mesh.get_aabb().size * mi.global_transform.basis.get_scale()
			var side := maxf(box.x, maxf(box.y, box.z))
			mi.visibility_range_end = clampf(side * meters_per_size, min_range, max_range)
			mi.visibility_range_end_margin = 8.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
			culled += 1
	for c in n.get_children():
		_walk(c)
