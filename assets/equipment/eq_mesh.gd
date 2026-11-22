extends RefCounted
## Small procedural mesh builder for the equipment pack. Units are meters.
## One ArrayMesh, one surface per material. Normals are explicit (flat or smooth) and windings
## are fixed automatically from an "inside" hint, so shapes never come out inside-out.
## Optional skinning: fill `skin_bones` with [bone_index, from, to] segments and every vertex
## gets blended weights from its nearest bone segments when finish() runs.

var _s := {}   # material -> {v, n}
var skin_bones: Array = []
var skin_max := 2
var skin_power := 3.0


func _surf(mat: Material) -> Dictionary:
	if not _s.has(mat):
		_s[mat] = {"v": PackedVector3Array(), "n": PackedVector3Array()}
	return _s[mat]


## One triangle. `inside` is a point inside the solid (used to orient it). Normals are flat
## unless na/nb/nc are given.
func tri(mat: Material, a: Vector3, b: Vector3, c: Vector3, inside: Vector3, na := Vector3.ZERO, nb := Vector3.ZERO, nc := Vector3.ZERO) -> void:
	var fn := (b - a).cross(c - a)
	if fn.length_squared() < 1e-12:
		return
	fn = fn.normalized()
	var mid := (a + b + c) / 3.0
	var out := fn.dot(mid - inside) > 0.0
	var s := _surf(mat)
	var smooth := na != Vector3.ZERO
	var fnorm := fn if out else -fn
	# Godot front faces are clockwise: when fn (counter-clockwise normal) points outward, swap.
	if out:
		s.v.append_array([a, c, b])
		s.n.append_array([na, nc, nb] if smooth else [fnorm, fnorm, fnorm])
	else:
		s.v.append_array([a, b, c])
		s.n.append_array([na, nb, nc] if smooth else [fnorm, fnorm, fnorm])


func quad(mat: Material, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
	tri(mat, a, b, c, inside)
	tri(mat, a, c, d, inside)


const _FACES := [[0, 1, 3, 2], [4, 6, 7, 5], [0, 2, 6, 4], [1, 5, 7, 3], [0, 4, 5, 1], [2, 3, 7, 6]]


func box(mat: Material, center: Vector3, size: Vector3, basis := Basis.IDENTITY) -> void:
	var h := size * 0.5
	var p: Array[Vector3] = []
	for i in 8:
		p.append(center + basis * Vector3(h.x * (1 if i & 1 else -1), h.y * (1 if i & 2 else -1), h.z * (1 if i & 4 else -1)))
	for f in _FACES:
		quad(mat, p[f[0]], p[f[1]], p[f[2]], p[f[3]], center)


## A tapered box: bottom size -> top size (x, z) along local Y.
func frustum(mat: Material, center: Vector3, bottom: Vector2, top: Vector2, height: float, basis := Basis.IDENTITY) -> void:
	var p: Array[Vector3] = []
	for i in 8:
		var yy := height * 0.5 * (1 if i & 2 else -1)
		var sz := top if i & 2 else bottom
		p.append(center + basis * Vector3(sz.x * 0.5 * (1 if i & 1 else -1), yy, sz.y * 0.5 * (1 if i & 4 else -1)))
	for f in _FACES:
		quad(mat, p[f[0]], p[f[1]], p[f[2]], p[f[3]], center)


## Surface of revolution around local Y. profile = [[radius, y], ...] bottom to top.
func lathe(mat: Material, xf: Transform3D, profile: Array, seg := 12, smooth := true, cap := true) -> void:
	var rings: Array = []
	var axis_pts := PackedVector3Array()
	for pr in profile:
		var r: float = pr[0]
		var y: float = pr[1]
		var ring := PackedVector3Array()
		for i in seg:
			var t := TAU * i / seg
			ring.append(xf * Vector3(cos(t) * r, y, sin(t) * r))
		rings.append(ring)
		axis_pts.append(xf * Vector3(0, y, 0))
	_connect(mat, rings, axis_pts, smooth, cap, cap)


## Loft closed rings (each a PackedVector3Array of equal size) into a skin.
func loft(mat: Material, rings: Array, smooth := false, cap_start := true, cap_end := true, wrap := true, centers := PackedVector3Array()) -> void:
	var cents := PackedVector3Array()
	for r in rings:
		var c := Vector3.ZERO
		for p in r:
			c += p
		cents.append(c / r.size())
	_connect(mat, rings, centers if not centers.is_empty() else cents, smooth, cap_start, cap_end, wrap)


func _connect(mat: Material, rings: Array, cents: PackedVector3Array, smooth: bool, cap_start: bool, cap_end: bool, wrap := true) -> void:
	var n: int = rings[0].size()
	var norms: Array = []
	if smooth:
		for k in rings.size():
			var arr := PackedVector3Array()
			for i in n:
				var p: Vector3 = rings[k][i]
				var radial := p - cents[k]
				var kn := mini(k + 1, rings.size() - 1)
				var kp := maxi(k - 1, 0)
				var along: Vector3 = rings[kn][i] - rings[kp][i]
				var side: Vector3 = rings[k][mini(i + 1, n - 1) if not wrap else (i + 1) % n] - rings[k][maxi(i - 1, 0) if not wrap else (i + n - 1) % n]
				var nm := along.cross(side)
				if nm.length_squared() < 1e-14:
					nm = radial
				nm = nm.normalized()
				if nm.dot(radial) < 0.0:
					nm = -nm
				arr.append(nm)
			norms.append(arr)
	for k in rings.size() - 1:
		for i in (n if wrap else n - 1):
			var j := (i + 1) % n
			var a: Vector3 = rings[k][i]
			var b: Vector3 = rings[k][j]
			var c: Vector3 = rings[k + 1][j]
			var d: Vector3 = rings[k + 1][i]
			var ins := (cents[k] + cents[k + 1]) * 0.5
			if smooth:
				tri(mat, a, b, c, ins, norms[k][i], norms[k][j], norms[k + 1][j])
				tri(mat, a, c, d, ins, norms[k][i], norms[k + 1][j], norms[k + 1][i])
			else:
				tri(mat, a, b, c, ins)
				tri(mat, a, c, d, ins)
	if cap_start:
		_cap(mat, rings[0], cents[mini(1, cents.size() - 1)])
	if cap_end:
		_cap(mat, rings[rings.size() - 1], cents[maxi(cents.size() - 2, 0)])


func _cap(mat: Material, ring: PackedVector3Array, toward_inside: Vector3) -> void:
	var cc := Vector3.ZERO
	for p in ring:
		cc += p
	cc /= ring.size()
	for i in ring.size():
		tri(mat, cc, ring[i], ring[(i + 1) % ring.size()], toward_inside)


func sphere(mat: Material, center: Vector3, radius: float, seg := 10, rings := 6) -> void:
	var prof: Array = []
	for i in range(rings + 1):
		var a := PI * i / rings
		prof.append([sin(a) * radius, -cos(a) * radius])
	lathe(mat, Transform3D(Basis.IDENTITY, center), prof, seg, true, false)


func cone(mat: Material, base: Vector3, tip: Vector3, radius: float, seg := 6) -> void:
	rod(mat, base, tip, radius, 0.0, seg)


## Rod between two points (round section, can taper).
func rod(mat: Material, a: Vector3, b: Vector3, ra: float, rb: float, seg := 8) -> void:
	var up := (b - a).normalized()
	var xf := Transform3D(Basis(Quaternion(Vector3.UP, up)), a)
	var h := (b - a).length()
	lathe(mat, xf, [[ra, 0.0], [rb, h]], seg, true, true)


func finish() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	for mat in _s:
		var s: Dictionary = _s[mat]
		if s.v.is_empty():
			continue
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = s.v
		arr[Mesh.ARRAY_NORMAL] = s.n
		if not skin_bones.is_empty():
			var bones := PackedInt32Array()
			var weights := PackedFloat32Array()
			for p in s.v:
				var w := _weights(p)
				bones.append_array(w[0])
				weights.append_array(w[1])
			arr[Mesh.ARRAY_BONES] = bones
			arr[Mesh.ARRAY_WEIGHTS] = weights
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
	return mesh


func triangle_count() -> int:
	var t := 0
	for mat in _s:
		t += _s[mat].v.size() / 3
	return t


func _weights(p: Vector3) -> Array:
	var cand: Array = []
	for sb in skin_bones:
		var a: Vector3 = sb[1]
		var b: Vector3 = sb[2]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
		var d := p.distance_to(a + ab * t)
		cand.append([sb[0], 1.0 / (pow(d, skin_power) + 1e-5)])
	cand.sort_custom(func(x, y): return x[1] > y[1])
	var bones := PackedInt32Array([0, 0, 0, 0])
	var weights := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
	var total := 0.0
	var n := mini(skin_max, cand.size())
	for i in n:
		total += cand[i][1]
	for i in n:
		bones[i] = cand[i][0]
		weights[i] = cand[i][1] / total
	return [bones, weights]
