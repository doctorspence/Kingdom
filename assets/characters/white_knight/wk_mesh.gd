extends RefCounted
## The White Knight's own mesh builder (metres; one surface per material). Shapes are made from
## triangles, boxes, lathes, lofts and tubes; windings are fixed from an "inside" point, so
## nothing comes out inside-out.
##
## Skinning: every part names the bones it follows (set_bones: nearest bone segments, or
## set_skin_fn: a weight function of the rest position). Texturing: every triangle gets UVs
## from a function per material (uv_fns), which sees the triangle at rest and in `pose` (the
## pose the owner's sheet was drawn in), so a picture of the sheet can be projected onto it.
## Vertex colours: an optional function per material (dirt, wear).

var _s := {}              # material -> {"v": PackedVector3Array, "n": PackedVector3Array, "g": Array}
var _groups: Array = []   # [segments, power, max bones] or Callable(p) -> [bones, weights]
var _group := -1
var color_fns := {}       # material -> Callable(p: Vector3) -> Color
## material -> Callable(rest: Array[3], posed: Array[3], n_rest: Vector3, n_posed: Vector3) -> Array[3] of Vector2
var uv_fns := {}
## bone index -> Transform3D (in skeleton space; missing bones stay put) for posed positions
var pose := {}
var _w := {}              # material -> [PackedInt32Array, PackedFloat32Array]
var _posed := {}          # material -> PackedVector3Array
var _prepared := false


func _surf(mat: Material) -> Dictionary:
	if not _s.has(mat):
		_s[mat] = {"v": PackedVector3Array(), "n": PackedVector3Array(), "g": []}
	return _s[mat]


# ------------------------------------------------------------------ skinning groups

## Following geometry follows these bone segments [index, from, to].
func set_bones(segments: Array, power := 4.0, max_bones := 2) -> void:
	_groups.append([segments, power, max_bones])
	_group = _groups.size() - 1


## Following geometry is weighted by fn(rest position) -> [PackedInt32Array(4), PackedFloat32Array(4)].
func set_skin_fn(fn: Callable) -> void:
	_groups.append(fn)
	_group = _groups.size() - 1


# ------------------------------------------------------------------ primitives

## One triangle. `inside` is a point inside the solid (it sets the facing). Flat normals unless
## na / nb / nc are given.
func tri(mat: Material, a: Vector3, b: Vector3, c: Vector3, inside: Vector3, na := Vector3.ZERO, nb := Vector3.ZERO, nc := Vector3.ZERO) -> void:
	var fn := (b - a).cross(c - a)
	if fn.length_squared() < 1e-14:
		return
	fn = fn.normalized()
	var out := fn.dot((a + b + c) / 3.0 - inside) > 0.0
	var s := _surf(mat)
	var smooth := na != Vector3.ZERO
	var f := fn if out else -fn
	# Godot's front faces wind clockwise: when the counter-clockwise normal points out, swap.
	if out:
		s.v.append_array([a, c, b])
		s.n.append_array([na, nc, nb] if smooth else [f, f, f])
	else:
		s.v.append_array([a, b, c])
		s.n.append_array([na, nb, nc] if smooth else [f, f, f])
	var g: Array = s.g
	g.append(_group)


func quad(mat: Material, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
	tri(mat, a, b, c, inside)
	tri(mat, a, c, d, inside)


const _FACES := [[0, 1, 3, 2], [4, 6, 7, 5], [0, 2, 6, 4], [1, 5, 7, 3], [0, 4, 5, 1], [2, 3, 7, 6]]


func box(mat: Material, center: Vector3, size: Vector3, basis := Basis.IDENTITY) -> void:
	var h := size * 0.5
	var p: Array[Vector3] = []
	for i in 8:
		p.append(center + basis * Vector3(h.x * (1 if i & 1 else -1), h.y * (1 if i & 2 else -1), h.z * (1 if i & 4 else -1)))
	for fc in _FACES:
		quad(mat, p[fc[0]], p[fc[1]], p[fc[2]], p[fc[3]], center)


## Surface of revolution round local Y. profile = [[radius, y], ...] bottom to top.
func lathe(mat: Material, xf: Transform3D, profile: Array, seg := 12, smooth := true, cap := true) -> void:
	var rings: Array = []
	var axis := PackedVector3Array()
	for pr in profile:
		var ring := PackedVector3Array()
		for i in seg:
			var t := TAU * i / seg
			ring.append(xf * Vector3(cos(t) * pr[0], pr[1], sin(t) * pr[0]))
		rings.append(ring)
		axis.append(xf * Vector3(0, pr[1], 0))
	_connect(mat, rings, axis, smooth, cap, cap, true)


## Loft rings (each a PackedVector3Array of the same size) into a skin. wrap = closed rings.
func loft(mat: Material, rings: Array, smooth := false, cap_start := true, cap_end := true, wrap := true, centers := PackedVector3Array()) -> void:
	var cents := centers
	if cents.is_empty():
		for r in rings:
			var c := Vector3.ZERO
			for p in r:
				c += p
			cents.append(c / r.size())
	_connect(mat, rings, cents, smooth, cap_start, cap_end, wrap)


func _connect(mat: Material, rings: Array, cents: PackedVector3Array, smooth: bool, cap_start: bool, cap_end: bool, wrap: bool) -> void:
	var n: int = rings[0].size()
	var norms: Array = []
	if smooth:
		for k in rings.size():
			var arr := PackedVector3Array()
			for i in n:
				var p: Vector3 = rings[k][i]
				var radial := p - cents[k]
				var along: Vector3 = rings[mini(k + 1, rings.size() - 1)][i] - rings[maxi(k - 1, 0)][i]
				var i1 := (i + 1) % n if wrap else mini(i + 1, n - 1)
				var i0 := (i + n - 1) % n if wrap else maxi(i - 1, 0)
				var side: Vector3 = rings[k][i1] - rings[k][i0]
				var nm := along.cross(side)
				if nm.length_squared() < 1e-14:
					nm = radial
				if nm.length_squared() < 1e-14:
					nm = Vector3.UP
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


func sphere(mat: Material, center: Vector3, radius: float, seg := 8, rings := 5) -> void:
	var prof: Array = []
	for i in rings + 1:
		var a := PI * i / rings
		prof.append([maxf(sin(a) * radius, 0.0001), -cos(a) * radius])
	lathe(mat, Transform3D(Basis.IDENTITY, center), prof, seg, true, false)


## A round tube along a path, a radius at every point (arms, rolls, straps, rings).
func tube(mat: Material, pts: Array, radii: Array, sides := 10, smooth := true, cap_a := false, cap_b := false, squash := Vector2.ONE, ref := Vector3.UP) -> void:
	var rings: Array = []
	var cents := PackedVector3Array()
	for i in pts.size():
		var t: Vector3 = (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var r := ref
		if absf(t.dot(r)) > 0.95:
			r = Vector3.BACK if absf(t.dot(Vector3.BACK)) < 0.95 else Vector3.RIGHT
		var u := t.cross(r).normalized()
		var v := t.cross(u).normalized()
		var ring := PackedVector3Array()
		for k in sides:
			var a := TAU * k / sides
			ring.append(pts[i] + u * cos(a) * radii[i] * squash.x + v * sin(a) * radii[i] * squash.y)
		rings.append(ring)
		cents.append(pts[i])
	_connect(mat, rings, cents, smooth, cap_a, cap_b, true)


# ------------------------------------------------------------------ skinning and posing

static func pack(pairs: Array) -> Array:
	var merged := {}
	for pr in pairs:
		if pr[1] > 0.0:
			merged[pr[0]] = merged.get(pr[0], 0.0) + float(pr[1])
	var list: Array = []
	for k in merged:
		list.append([k, merged[k]])
	list.sort_custom(func(x, y): return x[1] > y[1])
	var bones := PackedInt32Array([0, 0, 0, 0])
	var weights := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
	var total := 0.0
	var n := mini(4, list.size())
	for i in n:
		total += list[i][1]
	for i in n:
		bones[i] = list[i][0]
		weights[i] = list[i][1] / maxf(total, 1e-9)
	if n == 0:
		weights[0] = 1.0
	return [bones, weights]


static func nearest(p: Vector3, segments: Array, power: float, max_bones: int) -> Array:
	var cand: Array = []
	for sb in segments:
		var a: Vector3 = sb[1]
		var ab: Vector3 = sb[2] - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
		cand.append([sb[0], 1.0 / (pow(p.distance_to(a + ab * t), power) + 1e-5)])
	cand.sort_custom(func(x, y): return x[1] > y[1])
	return pack(cand.slice(0, mini(max_bones, cand.size())))


## Weights and posed positions for every vertex (run once, before finish()).
func prepare() -> void:
	if _prepared:
		return
	_prepared = true
	for mat in _s:
		var s: Dictionary = _s[mat]
		var bones := PackedInt32Array()
		var weights := PackedFloat32Array()
		var posed := PackedVector3Array()
		var g: Array = s.g
		for i in s.v.size():
			var p: Vector3 = s.v[i]
			var grp: int = g[i / 3]
			var w: Array
			if grp < 0:
				w = pack([[0, 1.0]])
			elif _groups[grp] is Callable:
				w = (_groups[grp] as Callable).call(p)
			else:
				w = nearest(p, _groups[grp][0], _groups[grp][1], _groups[grp][2])
			bones.append_array(w[0])
			weights.append_array(w[1])
			var q := Vector3.ZERO
			for k in 4:
				var wk: float = w[1][k]
				if wk > 0.0:
					q += (pose.get(w[0][k], Transform3D.IDENTITY) as Transform3D) * p * wk
			posed.append(q)
		_w[mat] = [bones, weights]
		_posed[mat] = posed


func materials() -> Array:
	return _s.keys()


func rest_verts(mat: Material) -> PackedVector3Array:
	return _s[mat].v


func posed_verts(mat: Material) -> PackedVector3Array:
	prepare()
	return _posed[mat]


func finish() -> ArrayMesh:
	prepare()
	var mesh := ArrayMesh.new()
	for mat in _s:
		var s: Dictionary = _s[mat]
		if s.v.is_empty():
			continue
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = s.v
		arr[Mesh.ARRAY_NORMAL] = s.n
		arr[Mesh.ARRAY_BONES] = _w[mat][0]
		arr[Mesh.ARRAY_WEIGHTS] = _w[mat][1]
		var posed: PackedVector3Array = _posed[mat]
		var uvs := PackedVector2Array()
		uvs.resize(s.v.size())
		if uv_fns.has(mat):
			var fn: Callable = uv_fns[mat]
			for i in range(0, s.v.size(), 3):
				var rest := [s.v[i], s.v[i + 1], s.v[i + 2]]
				var pz := [posed[i], posed[i + 1], posed[i + 2]]
				# both normals from the same winding, turned to match the stored (outward) normals
				var nr: Vector3 = (rest[1] - rest[0]).cross(rest[2] - rest[0]).normalized()
				var np_: Vector3 = (pz[1] - pz[0]).cross(pz[2] - pz[0]).normalized()
				if nr.dot(s.n[i] + s.n[i + 1] + s.n[i + 2]) < 0.0:
					nr = -nr
					np_ = -np_
				if np_ == Vector3.ZERO:
					np_ = nr
				var uv: Array = fn.call(rest, pz, nr, np_)
				uvs[i] = uv[0]
				uvs[i + 1] = uv[1]
				uvs[i + 2] = uv[2]
		arr[Mesh.ARRAY_TEX_UV] = uvs
		if color_fns.has(mat):
			var cf: Callable = color_fns[mat]
			var cols := PackedColorArray()
			cols.resize(s.v.size())
			for i in s.v.size():
				cols[i] = cf.call(s.v[i])
			arr[Mesh.ARRAY_COLOR] = cols
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
	return mesh


func triangle_count() -> int:
	var t := 0
	for mat in _s:
		t += _s[mat].v.size() / 3
	return t
