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

static var _cache := {}


func _ready() -> void:
	_build.call_deferred()


func _build() -> void:
	if not is_inside_tree():
		return
	var p := global_position
	var index := int(absf(p.x * 31.0 + p.z * 17.0)) % VARIANTS
	var mesh := _variant(kind, index)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	add_child(mi)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 4.5
	shape.shape = capsule
	shape.position.y = 2.25
	add_child(shape)


static func _variant(tree_kind: String, index: int) -> ArrayMesh:
	var key := "%s%d" % [tree_kind, index]
	if not _cache.has(key):
		var rng := RandomNumberGenerator.new()
		rng.seed = 9000 + index * 77 + (0 if tree_kind == "pine" else 500)
		_cache[key] = _make_pine(rng) if tree_kind == "pine" else _make_dead(rng)
	return _cache[key]


# --- The fir ---------------------------------------------------------------------------

static func _make_pine(rng: RandomNumberGenerator) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var bark := SurfaceTool.new()
	bark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var needles := SurfaceTool.new()
	needles.begin(Mesh.PRIMITIVE_TRIANGLES)
	var height := rng.randf_range(8.0, 10.5)
	var lean := Vector2(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.25, 0.25))
	var points := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in 7:
		var t := float(i) / 6.0
		points.append(Vector3(lean.x * t * t, t * height, lean.y * t * t))
		radii.append(lerpf(0.36, 0.06, t))
	_tube(bark, points, radii, 8)
	var tiers := rng.randi_range(7, 9)
	for k in tiers:
		var t := float(k) / tiers
		var y0 := 1.7 + t * (height - 2.8)
		var reach := lerpf(2.7, 0.55, pow(t, 0.8)) * rng.randf_range(0.88, 1.15)
		var h := rng.randf_range(1.7, 2.2)
		var center := Vector3(lean.x * (y0 / height) * (y0 / height), 0.0, lean.y * (y0 / height) * (y0 / height))
		_tier(needles, rng, center, y0, reach, h)
	bark.generate_normals()
	needles.generate_normals()
	bark.set_material(BARK)
	needles.set_material(NEEDLES)
	bark.commit(mesh)
	needles.commit(mesh)
	return mesh


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
