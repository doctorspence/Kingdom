extends RefCounted
## Low-poly mesh builder for the bandit. Units are meters, in the UAL1 skeleton's rest (T-pose)
## space: +Y up, the body faces +Z, +X is the character's left.
##
## Everything is flat-shaded (chunky facets). Every shape is its own "chart": a small rectangle of
## the texture atlas that keeps the shape's real proportions, so the painter (bandit_paint.gd) can
## draw seams, stitches and wear where they belong. Skin weights are written by hand: each point
## comes with {bone name: weight}, so joints bend the way we decide.

## One entry per shape: {group, style, tris: [[v, v, v]...], size (m), dens, inside}
## where v = {p: Vector3, uv: Vector2 (m), w: Dictionary}.
var charts: Array = []
## The mesh the next shapes belong to ("Body", "Head", "Hair", "Clothing", "Armor").
var group := "Body"
## Texture detail multiplier for the next shapes (the face gets more texels).
var density := 1.0


func _chart(style: String, size: Vector2) -> Dictionary:
	var c := {"group": group, "style": style, "tris": [], "size": size.max(Vector2(0.004, 0.004)), "dens": density}
	charts.append(c)
	return c


## Adds a triangle facing away from `inside`.
func _tri(c: Dictionary, a: Dictionary, b: Dictionary, d: Dictionary, inside: Vector3) -> void:
	var fn: Vector3 = (b.p - a.p).cross(d.p - a.p)
	if fn.length_squared() < 1e-12:
		return
	var mid: Vector3 = (a.p + b.p + d.p) / 3.0
	# Godot's front faces are clockwise: swap when the counter-clockwise normal points outward.
	if fn.dot(mid - inside) > 0.0:
		c.tris.append([a, d, b])
	else:
		c.tris.append([a, b, d])


static func _v(p: Vector3, uv: Vector2, w: Dictionary) -> Dictionary:
	return {"p": p, "uv": uv, "w": w}


## A weight argument may be a Dictionary (same for every point), a Callable(point) -> Dictionary,
## or an Array holding one of those per ring.
static func _weight(w: Variant, ring: int, p: Vector3) -> Dictionary:
	var x: Variant = w[ring] if w is Array else w
	if x is Callable:
		return x.call(p)
	return x


## Skin rings (each an Array / PackedVector3Array of the same length) into a surface.
## opts: closed (the ring wraps, default true), cap_start, cap_end (default false), cap_style.
func loft(style: String, rings: Array, weights: Variant, opts := {}) -> void:
	var closed: bool = opts.get("closed", true)
	var n: int = rings[0].size()
	var cols := n + 1 if closed else n
	var cents: Array[Vector3] = []
	for r in rings:
		var c := Vector3.ZERO
		for p in r:
			c += p
		cents.append(c / n)
	# u = average distance around, v = average distance from ring to ring
	var us := PackedFloat32Array([0.0])
	for i in range(1, cols):
		var d := 0.0
		for r in rings:
			d += (r[i % n] as Vector3).distance_to(r[i - 1])
		us.append(us[i - 1] + d / rings.size())
	var vs := PackedFloat32Array([0.0])
	for k in range(1, rings.size()):
		var d2 := 0.0
		for i in n:
			d2 += (rings[k][i] as Vector3).distance_to(rings[k - 1][i])
		vs.append(vs[k - 1] + d2 / n)
	var chart := _chart(style, Vector2(us[cols - 1], vs[rings.size() - 1]))
	var inside_override: Variant = opts.get("inside", null)
	for k in rings.size() - 1:
		for i in cols - 1:
			var j := (i + 1) % n
			var a := _v(rings[k][i % n], Vector2(us[i], vs[k]), _weight(weights, k, rings[k][i % n]))
			var b := _v(rings[k][j], Vector2(us[i + 1], vs[k]), _weight(weights, k, rings[k][j]))
			var c := _v(rings[k + 1][j], Vector2(us[i + 1], vs[k + 1]), _weight(weights, k + 1, rings[k + 1][j]))
			var d3 := _v(rings[k + 1][i % n], Vector2(us[i], vs[k + 1]), _weight(weights, k + 1, rings[k + 1][i % n]))
			var inside: Vector3 = inside_override if inside_override != null else (cents[k] + cents[k + 1]) * 0.5
			_tri(chart, a, b, c, inside)
			_tri(chart, a, c, d3, inside)
	var cap_style: String = opts.get("cap_style", style)
	if opts.get("cap_start", false):
		var w0 := []
		for p in rings[0]:
			w0.append(_weight(weights, 0, p))
		poly(cap_style, rings[0], w0, cents[1])
	if opts.get("cap_end", false):
		var last := rings.size() - 1
		var w1 := []
		for p in rings[last]:
			w1.append(_weight(weights, last, p))
		poly(cap_style, rings[last], w1, cents[last - 1])


## A flat (or nearly flat) polygon, fanned from its middle. weights: Dictionary, Callable or one per point.
func poly(style: String, pts: Array, weights: Variant, inside: Vector3) -> void:
	var n := pts.size()
	var mid := Vector3.ZERO
	for p in pts:
		mid += p
	mid /= n
	# a plane for the texture: the polygon's average normal
	var nm := Vector3.ZERO
	for i in n:
		nm += (pts[i] - mid).cross(pts[(i + 1) % n] - mid)
	if nm.length_squared() < 1e-14:
		return
	nm = nm.normalized()
	if nm.dot(mid - inside) < 0.0:
		nm = -nm
	var down := Vector3.DOWN if absf(nm.y) < 0.92 else Vector3.FORWARD
	var v_axis := (down - nm * nm.dot(down)).normalized()
	var u_axis := v_axis.cross(nm).normalized()
	var q: Array[Vector2] = []
	var lo := Vector2(1e9, 1e9)
	var hi := -lo
	for p in pts:
		var t := Vector2((p - mid).dot(u_axis), (p - mid).dot(v_axis))
		q.append(t)
		lo = lo.min(t)
		hi = hi.max(t)
	var chart := _chart(style, hi - lo)
	var ws := []
	for i in n:
		var x: Variant = weights[i] if weights is Array else weights
		ws.append(x.call(pts[i]) if x is Callable else x)
	if n == 3:
		_tri(chart, _v(pts[0], q[0] - lo, ws[0]), _v(pts[1], q[1] - lo, ws[1]), _v(pts[2], q[2] - lo, ws[2]), inside)
		return
	if n == 4:
		var four := []
		for i in 4:
			four.append(_v(pts[i], q[i] - lo, ws[i]))
		_tri(chart, four[0], four[1], four[2], inside)
		_tri(chart, four[0], four[2], four[3], inside)
		return
	var mw := {}
	for w in ws:
		for bone in w:
			mw[bone] = mw.get(bone, 0.0) + w[bone] / n
	var centre := _v(mid, -lo, mw)
	for i in n:
		var j := (i + 1) % n
		_tri(chart, centre, _v(pts[i], q[i] - lo, ws[i]), _v(pts[j], q[j] - lo, ws[j]), inside)


## A box (six faces).
func box(style: String, center: Vector3, size: Vector3, weights: Variant, basis := Basis.IDENTITY) -> void:
	var h := size * 0.5
	var p: Array[Vector3] = []
	for i in 8:
		p.append(center + basis * Vector3(h.x * (1 if i & 1 else -1), h.y * (1 if i & 2 else -1), h.z * (1 if i & 4 else -1)))
	for f in [[0, 1, 3, 2], [4, 6, 7, 5], [0, 2, 6, 4], [1, 5, 7, 3], [0, 4, 5, 1], [2, 3, 7, 6]]:
		poly(style, [p[f[0]], p[f[1]], p[f[2]], p[f[3]]], weights, center)


## A thin box running from a to b (straps, laces, brows). `face` is roughly where its front points.
func bar(style: String, a: Vector3, b: Vector3, width: float, thick: float, face: Vector3, weights: Variant) -> void:
	var up := (b - a).normalized()
	var fwd := (face - up * face.dot(up)).normalized()
	var right := up.cross(fwd).normalized()
	box(style, (a + b) * 0.5, Vector3(width, a.distance_to(b), thick), weights, Basis(right, up, fwd))


## A ring of n points around `c`, in the plane of the axes x and y, with radii rx and ry.
## squareness: 2 = round, higher = boxier. `turn` rotates the starting point (radians).
static func ring(c: Vector3, x: Vector3, y: Vector3, rx: float, ry: float, n: int, squareness := 2.0, turn := 0.0) -> Array:
	var out := []
	for i in n:
		var a := TAU * i / n + turn
		var ca := cos(a)
		var sa := sin(a)
		var e := 2.0 / squareness
		out.append(c + x * (signf(ca) * pow(absf(ca), e) * rx) + y * (signf(sa) * pow(absf(sa), e) * ry))
	return out


## Number of triangles added so far.
func triangle_count() -> int:
	var t := 0
	for c in charts:
		t += c.tris.size()
	return t


# ------------------------------------------------------------------ output

## Packs every chart into a size x size atlas. Sets chart.org (texels) and returns texels per meter.
func pack(size: int, pad := 2) -> float:
	var order: Array = range(charts.size())
	var k := 900.0
	while k > 20.0:
		order.sort_custom(func(a, b):
			var ha: float = charts[a].size.y * charts[a].dens
			var hb: float = charts[b].size.y * charts[b].dens
			return a < b if is_equal_approx(ha, hb) else ha > hb)
		var x := 0
		var y := 0
		var row := 0
		var fits := true
		for i in order:
			var c: Dictionary = charts[i]
			var w := int(ceilf(c.size.x * k * c.dens)) + pad * 2
			var h := int(ceilf(c.size.y * k * c.dens)) + pad * 2
			if x + w > size:
				x = 0
				y += row
				row = 0
			if w > size or y + h > size:
				fits = false
				break
			c.org = Vector2(x + pad, y + pad)
			c.k = k * c.dens
			x += w
			row = maxi(row, h)
		if fits:
			return k
		k *= 0.97
	push_error("bandit_mesh: the atlas is too small")
	return k


## {group name: ArrayMesh}. Call pack() first. bone_index: {bone name: index}; empty = no skinning.
func meshes(size: int, material: Material, bone_index := {}) -> Dictionary:
	var groups := {}
	for c in charts:
		if not groups.has(c.group):
			groups[c.group] = {"v": PackedVector3Array(), "n": PackedVector3Array(), "t": PackedVector2Array(),
					"b": PackedInt32Array(), "w": PackedFloat32Array()}
		var g: Dictionary = groups[c.group]
		for tri in c.tris:
			# clockwise winding, so the outward normal is (c - a) x (b - a)
			var nm: Vector3 = (tri[2].p - tri[0].p).cross(tri[1].p - tri[0].p).normalized()
			for vert in tri:
				g.v.append(vert.p)
				g.n.append(nm)
				g.t.append((c.org + vert.uv * c.k) / float(size))
				if not bone_index.is_empty():
					_append_weights(g, vert.w, bone_index)
	var out := {}
	for name_ in groups:
		var g: Dictionary = groups[name_]
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = g.v
		arr[Mesh.ARRAY_NORMAL] = g.n
		arr[Mesh.ARRAY_TEX_UV] = g.t
		if not bone_index.is_empty():
			arr[Mesh.ARRAY_BONES] = g.b
			arr[Mesh.ARRAY_WEIGHTS] = g.w
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(0, material)
		out[name_] = mesh
	return out


static func _append_weights(g: Dictionary, w: Dictionary, bone_index: Dictionary) -> void:
	var list: Array = []
	for bone in w:
		if w[bone] > 0.001:
			list.append([bone_index[bone], w[bone]])
	list.sort_custom(func(a, b): return a[1] > b[1])
	var total := 0.0
	for i in mini(4, list.size()):
		total += list[i][1]
	for i in 4:
		g.b.append(list[i][0] if i < list.size() else 0)
		g.w.append(list[i][1] / total if i < list.size() else 0.0)
