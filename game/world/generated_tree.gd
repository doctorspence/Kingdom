class_name GeneratedTree
extends StaticBody3D
## A tree built from code: a ragged, drooping fir, or a gnarled dead tree. A
## handful of shapes are built once and shared, and each tree picks one from
## where it stands, so the woods vary but cost almost nothing. Real bark
## texture; the fir's needles use a dark moss texture.

@export_enum("pine", "dead") var kind := "pine"

const BARK := preload("res://levels/common/materials/bark.tres")
const NEEDLES := preload("res://levels/common/materials/leaves.tres")
const VARIANTS := 5
## Trees farther than this are not drawn (the fog hides them anyway).
const SEEN_FROM := 175.0

static var _cache := {}


func _ready() -> void:
	_build.call_deferred()


func _build() -> void:
	if not is_inside_tree():
		return
	var p := global_position
	var index := int(absf(p.x * 31.0 + p.z * 17.0)) % VARIANTS
	var parts := _variant(kind, index)
	# Solid parts (trunk, dark core) cast shadows; the needle fans (the most
	# expensive to shadow) do not. Far trees vanish into the fog, so they are
	# not drawn at all beyond SEEN_FROM meters.
	for i in parts.size():
		var mi := MeshInstance3D.new()
		mi.mesh = parts[i]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if i == 0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = SEEN_FROM
		add_child(mi)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 4.5
	shape.shape = capsule
	shape.position.y = 2.25
	add_child(shape)


## [solid mesh, needle-fan mesh (fir only)].
static func _variant(tree_kind: String, index: int) -> Array:
	var key := "%s%d" % [tree_kind, index]
	if not _cache.has(key):
		var rng := RandomNumberGenerator.new()
		rng.seed = 9000 + index * 77 + (0 if tree_kind == "pine" else 500)
		var full := _make_pine(rng) if tree_kind == "pine" else _make_dead(rng)
		_cache[key] = _split(full)
	return _cache[key]


## Surfaces 0 and 1 (trunk, core) become the solid mesh; surface 2 (the fans) its own.
static func _split(full: ArrayMesh) -> Array:
	var solid := ArrayMesh.new()
	var fans: ArrayMesh = null
	for s in full.get_surface_count():
		var target := solid
		if s >= 2:
			if fans == null:
				fans = ArrayMesh.new()
			target = fans
		target.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, full.surface_get_arrays(s))
		target.surface_set_material(target.get_surface_count() - 1, full.surface_get_material(s))
	return [solid] if fans == null else [solid, fans]

# --- The fir ---------------------------------------------------------------------------

static func _make_pine(rng: RandomNumberGenerator) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var bark := SurfaceTool.new()
	bark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var core := SurfaceTool.new()
	core.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fans := SurfaceTool.new()
	fans.begin(Mesh.PRIMITIVE_TRIANGLES)
	var height := rng.randf_range(8.5, 11.0)
	var lean := Vector2(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.25, 0.25))
	var points := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in 7:
		var t := float(i) / 6.0
		points.append(Vector3(lean.x * t * t, t * height, lean.y * t * t))
		radii.append(lerpf(0.36, 0.06, t))
	_tube(bark, points, radii, 8)
	# A dark, narrow inner mass so the tree never looks hollow between branches.
	var tiers := rng.randi_range(6, 8)
	for k in tiers:
		var t := float(k) / tiers
		var y0 := 1.9 + t * (height - 3.2)
		var reach := lerpf(1.5, 0.3, pow(t, 0.8)) * rng.randf_range(0.9, 1.1)
		var center := Vector3(lean.x * (y0 / height) * (y0 / height), 0.0, lean.y * (y0 / height) * (y0 / height))
		_tier(core, rng, center, y0, reach, rng.randf_range(1.8, 2.3))
	# The branches: whorls of drooping needle fans, long at the bottom, short at the top.
	var whorls := rng.randi_range(10, 13)
	for k in whorls:
		var t := float(k) / (whorls - 1)
		var y := 1.4 + t * (height - 2.2)
		var reach := lerpf(2.9, 0.45, pow(t, 0.85)) * rng.randf_range(0.9, 1.12)
		var count := roundi(lerpf(9.0, 5.0, t))
		var offset := rng.randf() * TAU
		var center := Vector3(lean.x * (y / height) * (y / height), y, lean.y * (y / height) * (y / height))
		for i in count:
			var a := offset + TAU * i / count + rng.randf_range(-0.25, 0.25)
			var dir := Vector3(cos(a), 0.0, sin(a))
			var length := reach * rng.randf_range(0.85, 1.15)
			_fan(fans, center + dir * 0.12 + Vector3.UP * rng.randf_range(-0.15, 0.15), dir, length, length * rng.randf_range(0.32, 0.42), length * lerpf(0.5, 0.25, t), rng)
	# The leader at the very top.
	for i in 5:
		var a := TAU * i / 5.0 + rng.randf()
		_fan(fans, Vector3(lean.x, height - 0.9, lean.y), Vector3(cos(a), 0.0, sin(a)), 0.7, 0.28, -0.25, rng)
	bark.generate_normals()
	core.generate_normals()
	bark.set_material(BARK)
	core.set_material(NEEDLES)
	fans.set_material(_fan_material())
	bark.commit(mesh)
	core.commit(mesh)
	fans.commit(mesh)
	return mesh


## One branch: a tapering strip bending down toward its tip, textured with needles.
static func _fan(st: SurfaceTool, base: Vector3, dir: Vector3, length: float, width: float, droop: float, rng: RandomNumberGenerator) -> void:
	var side := Vector3.UP.cross(dir).normalized()
	var rows := 4
	var left: Array[Vector3] = []
	var right: Array[Vector3] = []
	for r in rows + 1:
		var t := float(r) / rows
		var center := base + dir * length * t + Vector3.DOWN * droop * t * t
		var w := width * (1.0 - 0.72 * t) * (0.55 + 0.45 * minf(t * 4.0, 1.0))
		left.append(center - side * w)
		right.append(center + side * w)
	var normal := (Vector3.UP * 0.85 + dir * 0.25).normalized()
	for r in rows:
		var v0 := 1.0 - float(r) / rows
		var v1 := 1.0 - float(r + 1) / rows
		var quad := [[left[r], Vector2(0, v0)], [right[r], Vector2(1, v0)], [right[r + 1], Vector2(1, v1)],
				[left[r], Vector2(0, v0)], [right[r + 1], Vector2(1, v1)], [left[r + 1], Vector2(0, v1)]]
		for q in quad:
			st.set_normal(normal)
			st.set_uv(q[1])
			st.add_vertex(q[0])


static var _fan_mat: StandardMaterial3D


## Fir needles, drawn once into a texture: a thin stem with short needles
## sweeping forward on both sides; everything else is see-through.
static func _fan_material() -> StandardMaterial3D:
	if _fan_mat:
		return _fan_mat
	var w := 96
	var h := 192
	var img := Image.create(w, h, true, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var stem := Color(0.2, 0.17, 0.1, 1.0)
	for y in range(h - 1, 2, -1):
		var along := float(h - 1 - y) / (h - 1)
		# The stem.
		for dx in 2:
			img.set_pixel(w / 2 - 1 + dx, y, stem)
		if y % 3 != 0:
			continue
		var length := 40.0 * (1.0 - pow(along, 2.0)) * (0.3 + 0.7 * smoothstep(0.0, 0.2, along))
		for side: int in [-1, 1]:
			var needle_len := length * rng.randf_range(0.8, 1.05)
			var ang := deg_to_rad(rng.randf_range(42.0, 62.0))
			var shade := rng.randf()
			var col := Color(0.09, 0.15, 0.06).lerp(Color(0.2, 0.3, 0.11), shade * 0.7 + along * 0.3)
			var steps := int(needle_len)
			for s in steps:
				var px := w / 2 + side * int(cos(ang) * s)
				var py := y - int(sin(ang) * s * 1.1)
				for thick in 2:
					if px >= 0 and px < w and py - thick >= 0 and py - thick < h:
						img.set_pixel(px, py - thick, col)
	img.generate_mipmaps()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_HASH
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	mat.metallic_specular = 0.05
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_fan_mat = mat
	return mat

## One drooping skirt of branches: a ragged outer ring, an inner ring, a tip.
static func _tier(st: SurfaceTool, rng: RandomNumberGenerator, center: Vector3, y0: float, reach: float, h: float) -> void:
	var n := 13
	var outer: Array[Vector3] = []
	var inner: Array[Vector3] = []
	for i in n:
		var a := TAU * i / n + rng.randf_range(-0.12, 0.12)
		var spike := 1.0 if i % 2 == 0 else 0.68  # alternate long and short branches
		var r := reach * spike * rng.randf_range(0.85, 1.12)
		outer.append(center + Vector3(cos(a) * r, y0 - rng.randf_range(0.0, 0.35), sin(a) * r))
		var r2 := reach * 0.55 * rng.randf_range(0.85, 1.1)
		inner.append(center + Vector3(cos(a) * r2, y0 + h * 0.55, sin(a) * r2))
	var tip := center + Vector3(0, y0 + h, 0)
	var under := center + Vector3(0, y0 + 0.15, 0)
	for i in n:
		var j := (i + 1) % n
		_tri(st, outer[i], outer[j], inner[j], center)
		_tri(st, outer[i], inner[j], inner[i], center)
		_tri(st, inner[i], inner[j], tip, center)
		_tri(st, under, outer[j], outer[i], center + Vector3.DOWN * 5.0)  # the underside faces down


# --- The dead tree -----------------------------------------------------------------------

static func _make_dead(rng: RandomNumberGenerator) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var bark := SurfaceTool.new()
	bark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var height := rng.randf_range(5.0, 7.5)
	var points := PackedVector3Array()
	var radii := PackedFloat32Array()
	var wander := Vector2.ZERO
	var steps := 8
	for i in steps + 1:
		var t := float(i) / steps
		wander += Vector2(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.25, 0.25))
		points.append(Vector3(wander.x, t * height, wander.y))
		radii.append(lerpf(0.34, 0.07, t))
	_tube(bark, points, radii, 7)
	# Crooked, broken branches.
	var branches := rng.randi_range(4, 7)
	for b in branches:
		var from_i := rng.randi_range(2, steps - 1)
		var start := points[from_i]
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.2, 0.9), rng.randf_range(-1, 1)).normalized()
		var length := rng.randf_range(1.2, 2.8) * (1.2 - float(from_i) / steps * 0.6)
		var bp := PackedVector3Array()
		var br := PackedFloat32Array()
		var pos := start
		for s in 4:
			bp.append(pos)
			br.append(lerpf(0.11, 0.018, float(s) / 3.0))
			dir = (dir + Vector3(rng.randf_range(-0.35, 0.35), rng.randf_range(-0.1, 0.25), rng.randf_range(-0.35, 0.35))).normalized()
			pos += dir * length / 3.0
		_tube(bark, bp, br, 5)
	bark.generate_normals()
	bark.set_material(BARK)
	bark.commit(mesh)
	return mesh


# --- Shared pieces ---------------------------------------------------------------------------

## A tube along a path, thick to thin (`radii` per point).
static func _tube(st: SurfaceTool, points: PackedVector3Array, radii: PackedFloat32Array, sides: int) -> void:
	var rings: Array = []
	for i in points.size():
		var dir := (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
		var side := dir.cross(Vector3.RIGHT if absf(dir.x) < 0.9 else Vector3.FORWARD).normalized()
		var up := dir.cross(side).normalized()
		var ring: Array[Vector3] = []
		for s in sides:
			var a := TAU * s / sides
			ring.append(points[i] + (side * cos(a) + up * sin(a)) * radii[i])
		rings.append(ring)
	for i in points.size() - 1:
		for s in sides:
			var s2 := (s + 1) % sides
			var a: Vector3 = rings[i][s]
			var b: Vector3 = rings[i][s2]
			var c: Vector3 = rings[i + 1][s2]
			var d: Vector3 = rings[i + 1][s]
			var axis := points[i]
			_tri(st, a, b, c, axis)
			_tri(st, a, c, d, axis)


## A triangle that faces away from `inside`.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	var n := (b - a).cross(c - a)
	var outward := (a + b + c) / 3.0 - inside
	# Godot draws clockwise triangles: the cross product then points inward.
	if n.dot(outward) > 0.0:
		var t := b
		b = c
		c = t
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
