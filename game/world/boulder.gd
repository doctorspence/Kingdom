class_name Boulder
extends StaticBody3D
## A natural-looking boulder made from noise: a lumpy, flattened sphere half
## buried in the ground, with real rock texture (triplanar, so it never
## stretches) and matching collision. Each one is shaped by where it stands,
## so a field of them never repeats, and every player sees the same rocks.

@export var radius := 1.3
## Stretch before the noise: (wide, tall, deep).
@export var squash := Vector3(1.0, 0.72, 0.9)
## How lumpy it is (0 = a smooth ball).
@export var roughness := 0.3
## How many times the sphere is split (2 is plenty for a boulder).
@export_range(1, 4) var detail := 2
@export var material: Material = preload("res://levels/common/materials/rock.tres")
## Extra shape variation added to the position-based seed.
@export var shape_seed := 0


func _ready() -> void:
	_build.call_deferred()


func _build() -> void:
	if not is_inside_tree():
		return
	var p := global_position
	var seed_value := int(absf(p.x * 73.0 + p.z * 191.0 + p.y * 31.0)) + shape_seed
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.9
	noise.fractal_octaves = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# Every rock gets its own proportions.
	var stretch := Vector3(squash.x * rng.randf_range(0.8, 1.25), squash.y * rng.randf_range(0.8, 1.2), squash.z * rng.randf_range(0.8, 1.25))
	var mesh_data := _icosphere(detail)
	var verts: PackedVector3Array = mesh_data[0]
	var indices: PackedInt32Array = mesh_data[1]
	var shaped := PackedVector3Array()
	shaped.resize(verts.size())
	for i in verts.size():
		var d := verts[i]
		var lump := 1.0 + noise.get_noise_3d(d.x * 2.0, d.y * 2.0, d.z * 2.0) * roughness * 2.2
		var v := d * radius * lump * stretch
		if v.y < -radius * 0.25:
			v.y = -radius * 0.25 + (v.y + radius * 0.25) * 0.2  # a flat, buried base
		shaped[i] = v
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = shaped
	arrays[Mesh.ARRAY_INDEX] = indices
	var st := SurfaceTool.new()
	st.create_from_arrays(arrays)
	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, material)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	add_child(mi)
	var shape := CollisionShape3D.new()
	var hull := ConvexPolygonShape3D.new()
	hull.points = shaped  # (the physics engine builds the hull itself: much faster than simplifying the mesh)
	shape.shape = hull
	add_child(shape)


## A sphere made of triangles, split `levels` times: [vertices, indices].
static func _icosphere(levels: int) -> Array:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var verts := PackedVector3Array([
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)])
	for i in verts.size():
		verts[i] = verts[i].normalized()
	var faces := PackedInt32Array([
		0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11,
		1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8,
		3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9,
		4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1])
	var cache := {}
	for _level in levels:
		var next := PackedInt32Array()
		for f in range(0, faces.size(), 3):
			var a := faces[f]
			var b := faces[f + 1]
			var c := faces[f + 2]
			var ab := _midpoint(verts, cache, a, b)
			var bc := _midpoint(verts, cache, b, c)
			var ca := _midpoint(verts, cache, c, a)
			next.append_array(PackedInt32Array([a, ab, ca, b, bc, ab, c, ca, bc, ab, bc, ca]))
		faces = next
	# Wind the triangles so they face outward.
	var out := PackedInt32Array()
	for f in range(0, faces.size(), 3):
		out.append_array(PackedInt32Array([faces[f], faces[f + 2], faces[f + 1]]))
	return [verts, out]


static func _midpoint(verts: PackedVector3Array, cache: Dictionary, a: int, b: int) -> int:
	var key := mini(a, b) * 100000 + maxi(a, b)
	if cache.has(key):
		return cache[key]
	verts.append(((verts[a] + verts[b]) * 0.5).normalized())
	cache[key] = verts.size() - 1
	return verts.size() - 1
