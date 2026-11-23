class_name QuarryKit
extends RefCounted
## The Greenwood's worked-stone kit, built in code: squared limestone blocks
## (whole, broken, half-cut), flat slabs and angular rubble for scree, and the
## materials they share (pale limestone matched to the terrain's quarry faces,
## old oak for timbers). Meshes are built once and cached.
##
## mesh(name, variant) -> ArrayMesh for "block", "block_broken", "slab", "rubble".
## Base sits at y = 0, centered on x/z.

const STONE_TEX := "res://assets/textures/cliff/color.jpg"
const STONE_NRM := "res://assets/textures/cliff/normal.jpg"

static var _cache := {}
static var _mats := {}


static func mesh(kind: String, variant: int) -> ArrayMesh:
	var key := "%s%d" % [kind, variant]
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key) + 77
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	match kind:
		"block":
			var s := Vector3(rng.randf_range(1.2, 1.8), rng.randf_range(0.6, 0.8), rng.randf_range(0.7, 0.9))
			rock_box(st, Vector3(0, s.y * 0.5, 0), s, 0.0, rng, 0.03)
		"block_broken":
			var s := Vector3(rng.randf_range(0.9, 1.5), rng.randf_range(0.5, 0.75), rng.randf_range(0.6, 0.85))
			rock_box(st, Vector3(0, s.y * 0.5, 0), s, 0.0, rng, 0.14)
		"slab":
			var s := Vector3(rng.randf_range(1.4, 2.4), rng.randf_range(0.18, 0.32), rng.randf_range(1.0, 1.7))
			rock_box(st, Vector3(0, s.y * 0.5, 0), s, rng.randf_range(-0.3, 0.3), rng, 0.1)
		_:  # rubble: a few angular chunks in a heap
			for i in rng.randi_range(4, 7):
				var s := Vector3.ONE * rng.randf_range(0.25, 0.6) * Vector3(rng.randf_range(0.8, 1.4), rng.randf_range(0.6, 1.0), rng.randf_range(0.8, 1.3))
				var p := Vector3(rng.randf_range(-0.7, 0.7), s.y * 0.35, rng.randf_range(-0.7, 0.7))
				rock_box(st, p, s, rng.randf() * TAU, rng, 0.22)
	st.generate_normals()
	st.index()
	st.set_material(stone_material())
	var m := st.commit()
	_cache[key] = m
	return m


## A box with every corner pushed about a little (jag = how much, as a share of size),
## so blocks read as hewn stone rather than perfect cubes. Flat-shaded faces.
static func rock_box(st: SurfaceTool, center: Vector3, size: Vector3, yaw: float, rng: RandomNumberGenerator, jag: float) -> void:
	var h := size * 0.5
	var c: Array[Vector3] = []
	for i in 8:
		var v := Vector3(h.x if i & 1 else -h.x, h.y if i & 2 else -h.y, h.z if i & 4 else -h.z)
		v += Vector3(rng.randf_range(-1, 1) * size.x, rng.randf_range(-1, 1) * size.y, rng.randf_range(-1, 1) * size.z) * jag * 0.5
		c.append(center + v.rotated(Vector3.UP, yaw))
	var faces := [[0, 2, 3, 1], [4, 5, 7, 6], [0, 1, 5, 4], [2, 6, 7, 3], [0, 4, 6, 2], [1, 3, 7, 5]]
	for f: Array in faces:
		var a: Vector3 = c[f[0]]
		var b: Vector3 = c[f[1]]
		var cc: Vector3 = c[f[2]]
		var d: Vector3 = c[f[3]]
		var n := (b - a).cross(cc - a)
		var mid := (a + b + cc + d) * 0.25
		# Godot faces are clockwise from outside: flip if the normal points inward.
		if n.dot(mid - center) > 0.0:
			for v in [a, cc, b, a, d, cc]:
				st.add_vertex(v)
		else:
			for v in [a, b, cc, a, cc, d]:
				st.add_vertex(v)


static func stone_material() -> StandardMaterial3D:
	if _mats.has("stone"):
		return _mats.stone
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(STONE_TEX)
	m.albedo_color = Color(1.35, 1.32, 1.22)  # the dark scan lifted to pale limestone (#B5B1A3 / #777C78)
	m.normal_enabled = true
	m.normal_texture = load(STONE_NRM)
	m.normal_scale = 0.8
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.45, 0.45, 0.45)
	m.roughness = 0.92
	m.metallic_specular = 0.2
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats.stone = m
	return m


static func timber_material() -> Material:
	if not _mats.has("timber"):
		_mats.timber = load("res://assets/hideout/Materials/wood_aged.tres")
	return _mats.timber
