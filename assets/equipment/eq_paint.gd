extends RefCounted
## Hand-painting for armor pieces. Takes a piece's triangles, lays each one out in a unique texture atlas
## (no tiling), and paints the atlas the way a miniature painter would: steel as non-metallic metal (a
## bright sky band, a dark horizon line, a warm ground bounce), chain mail ring by ring with drybrushed
## highlights, leather with worn tan edges and stitching, cloth with soft folds, gold as a dark-to-bright
## gradient. On top of every material: a baked key light, ambient occlusion from the piece's own layers,
## bright lines along convex edges and dark lines in crevices, scratches and grime.
##
## bake() returns {"uv": per-vertex UVs, "paint": albedo Image, "mask": Image (R metallic, G roughness)}.

const KEY := Vector3(-0.45, 0.75, 0.5)
const AO_CELL := 0.012

# material name -> [kind, base color, metallic, roughness]
const STYLES := {
	"chainmail": ["mail", Color(0.5, 0.52, 0.56), 0.5, 0.55],
	"steel": ["steel", Color(1, 1, 1), 0.4, 0.4],
	"dark_steel": ["steel", Color(0.55, 0.56, 0.64), 0.4, 0.45],
	"iron": ["iron", Color(0.6, 0.56, 0.52), 0.4, 0.55],
	"bronze": ["gold", Color(1, 0.8, 0.5), 0.45, 0.4],
	"leather": ["leather", Color(0.3, 0.18, 0.1), 0.0, 0.72],
	"leather_dark": ["leather", Color(0.17, 0.11, 0.075), 0.0, 0.72],
	"cloth_coarse": ["cloth", Color(0.5, 0.42, 0.32), 0.0, 0.92],
	"cloth_blue": ["cloth", Color(0.15, 0.22, 0.5), 0.0, 0.9],
	"cloth_grey": ["cloth", Color(0.4, 0.4, 0.44), 0.0, 0.9],
	"cloth_red": ["cloth", Color(0.56, 0.13, 0.1), 0.0, 0.9],
	"cloth_trim": ["cloth", Color(0.72, 0.53, 0.2), 0.1, 0.7],
}


static func style_names() -> Array:
	return STYLES.keys()


# ------------------------------------------------------------------ bake

## P / N: 3 vertices per triangle. tri_style: index into style_list (an Array of STYLES names).
static func bake(P: PackedVector3Array, N: PackedVector3Array, tri_style: PackedInt32Array, style_list: Array, size: int) -> Dictionary:
	var T := P.size() / 3
	var hard := _edge_hardness(P, N, T)
	var layout := _layout(P, T, size)

	var tuv: PackedVector2Array = layout.uv
	var ao := _AO.new()
	ao.build(P, T)
	var paint := PackedByteArray()
	paint.resize(size * size * 4)
	var mask := PackedByteArray()
	mask.resize(size * size * 4)
	var covered := PackedByteArray()
	covered.resize(size * size)
	var noise := _Noise.new()
	var kinds: Array = []
	for nm in style_list:
		kinds.append(STYLES[nm])
	for t in T:
		var a := P[t * 3]
		var b := P[t * 3 + 1]
		var c := P[t * 3 + 2]
		var ua := tuv[t * 3]
		var ub := tuv[t * 3 + 1]
		var uc := tuv[t * 3 + 2]
		var area2 := (ub - ua).cross(uc - ua)
		if absf(area2) < 1e-6:
			continue
		var x0 := maxi(int(floorf(minf(ua.x, minf(ub.x, uc.x))) - 2), 0)
		var x1 := mini(int(ceilf(maxf(ua.x, maxf(ub.x, uc.x))) + 2), size - 1)
		var y0 := maxi(int(floorf(minf(ua.y, minf(ub.y, uc.y))) - 2), 0)
		var y1 := mini(int(ceilf(maxf(ua.y, maxf(ub.y, uc.y))) + 2), size - 1)
		# edge lengths in texels, for the padding test
		var h0 := absf(area2) / maxf((ub - uc).length(), 1e-6)   # height above edge bc (bary a)
		var h1 := absf(area2) / maxf((uc - ua).length(), 1e-6)
		var h2 := absf(area2) / maxf((ua - ub).length(), 1e-6)
		var kind: Array = kinds[tri_style[t]]
		var he0 := hard[t * 3]
		var he1 := hard[t * 3 + 1]
		var he2 := hard[t * 3 + 2]
		var na := N[t * 3]
		var nb := N[t * 3 + 1]
		var nc := N[t * 3 + 2]
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				var p2 := Vector2(x + 0.5, y + 0.5)
				var w0 := (ub - p2).cross(uc - p2) / area2
				var w1 := (uc - p2).cross(ua - p2) / area2
				var w2 := 1.0 - w0 - w1
				var inside := w0 >= 0.0 and w1 >= 0.0 and w2 >= 0.0
				if not inside and (w0 * h0 < -1.6 or w1 * h1 < -1.6 or w2 * h2 < -1.6):
					continue
				var idx := y * size + x
				if covered[idx] == 2 and not inside:
					continue
				if not inside:
					w0 = clampf(w0, 0.0, 1.0)
					w1 = clampf(w1, 0.0, 1.0)
					w2 = clampf(w2, 0.0, 1.0)
					var s := w0 + w1 + w2
					w0 /= s
					w1 /= s
					w2 /= s
				var pos := a * w0 + b * w1 + c * w2
				var nrm := (na * w0 + nb * w1 + nc * w2).normalized()
				# distance to this triangle's feature edges (3D)
				var hi: float
				var lo: float
				var rim: float
				var e := _edges(pos, a, b, c, he0, he1, he2)
				hi = e[0]
				lo = e[1]
				rim = e[2]
				var occl := ao.occlusion(pos, nrm)
				var col := _paint(kind, pos, nrm, hi, lo, rim, occl, noise)
				var o := idx * 4
				paint[o] = int(clampf(col[0], 0.0, 1.0) * 255.0)
				paint[o + 1] = int(clampf(col[1], 0.0, 1.0) * 255.0)
				paint[o + 2] = int(clampf(col[2], 0.0, 1.0) * 255.0)
				paint[o + 3] = 255
				mask[o] = int(clampf(col[3], 0.0, 1.0) * 255.0)
				mask[o + 1] = int(clampf(col[4], 0.0, 1.0) * 255.0)
				mask[o + 2] = 0
				mask[o + 3] = 255
				covered[idx] = 2 if inside else maxi(covered[idx], 1)
	_dilate(paint, mask, covered, size)
	var uv := PackedVector2Array()
	uv.resize(P.size())
	for i in P.size():
		uv[i] = tuv[i] / float(size)
	return {"uv": uv, "paint": Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, paint),
			"mask": Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, mask), "texel_mm": layout.texel_mm}


## Texels nobody painted copy their nearest painted neighbor, so mip-maps and filtering never pick up black.
static func _dilate(paint: PackedByteArray, mask: PackedByteArray, covered: PackedByteArray, size: int) -> void:
	# average color for the far-away empty texels
	var sr := 0.0
	var sg := 0.0
	var sb := 0.0
	var n := 0
	for i in range(0, size * size, 97):
		if covered[i] > 0:
			sr += paint[i * 4]
			sg += paint[i * 4 + 1]
			sb += paint[i * 4 + 2]
			n += 1
	var avg := [int(sr / maxf(n, 1)), int(sg / maxf(n, 1)), int(sb / maxf(n, 1))]
	for pass_ in 4:
		var changed := PackedInt32Array()
		for y in size:
			for x in size:
				var i := y * size + x
				if covered[i] > 0:
					continue
				for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
					var xx: int = x + d[0]
					var yy: int = y + d[1]
					if xx < 0 or yy < 0 or xx >= size or yy >= size:
						continue
					var j := yy * size + xx
					if covered[j] > 0 and covered[j] != 3:
						for k in 4:
							paint[i * 4 + k] = paint[j * 4 + k]
							mask[i * 4 + k] = mask[j * 4 + k]
						changed.append(i)
						break
		for i in changed:
			covered[i] = 3
	for i in size * size:
		if covered[i] == 0:
			paint[i * 4] = avg[0]
			paint[i * 4 + 1] = avg[1]
			paint[i * 4 + 2] = avg[2]
			paint[i * 4 + 3] = 255
			mask[i * 4] = 60
			mask[i * 4 + 1] = 160
			mask[i * 4 + 3] = 255


# ------------------------------------------------------------------ edges

static func _qkey(p: Vector3) -> int:
	var x := int(roundf(p.x * 2000.0))
	var y := int(roundf(p.y * 2000.0))
	var z := int(roundf(p.z * 2000.0))
	return (x * 73856093) ^ (y * 19349663) ^ (z * 83492791)


static func _ekey(a: Vector3, b: Vector3) -> Vector2i:
	var ka := _qkey(a)
	var kb := _qkey(b)
	return Vector2i(mini(ka, kb), maxi(ka, kb))


## Per triangle edge (v_i to v_i+1): +hardness for a convex hard edge, -hardness for a concave one,
## 2 for an open boundary (the rim of a plate), 0 for a smooth join.
static func _edge_hardness(P: PackedVector3Array, N: PackedVector3Array, T: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(T * 3)
	var emap := {}
	for t in T:
		for e in 3:
			var key := _ekey(P[t * 3 + e], P[t * 3 + (e + 1) % 3])
			if not emap.has(key):
				emap[key] = []
			emap[key].append(t * 3 + e)
	for key in emap:
		var l: Array = emap[key]
		if l.size() == 1:
			out[l[0]] = 2.0
		elif l.size() == 2:
			var ta: int = l[0] / 3
			var ea: int = l[0] % 3
			var tb: int = l[1] / 3
			var eb: int = l[1] % 3
			var a := P[ta * 3 + ea]
			var b := P[ta * 3 + (ea + 1) % 3]
			var na0 := N[ta * 3 + ea]
			var na1 := N[ta * 3 + (ea + 1) % 3]
			# B's vertex normals at the same two points
			var nb0 := N[tb * 3 + eb]
			var nb1 := N[tb * 3 + (eb + 1) % 3]
			if P[tb * 3 + eb].distance_squared_to(a) > P[tb * 3 + eb].distance_squared_to(b):
				var tmp := nb0
				nb0 = nb1
				nb1 = tmp
			var ang := maxf(na0.angle_to(nb0), na1.angle_to(nb1))
			var h := clampf((ang - 0.3) / 0.6, 0.0, 1.0)
			if h > 0.0:
				var fa := (P[ta * 3 + 1] - P[ta * 3]).cross(P[ta * 3 + 2] - P[ta * 3]).normalized()
				var third := P[tb * 3 + (eb + 2) % 3]
				var convex := (third - a).dot(fa) < 0.0
				if (na0 + na1).dot(fa) < 0.0:
					convex = not convex
				var v := h if convex else -h
				out[l[0]] = v
				out[l[1]] = v
	return out


static func _seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
	return p.distance_to(a + ab * t)




## [convex edge highlight, concave crevice, open rim] at p, from the triangle's three edges.
static func _edges(p: Vector3, a: Vector3, b: Vector3, c: Vector3, h0: float, h1: float, h2: float) -> Array:
	var hi := 0.0
	var lo := 0.0
	var rim := 0.0
	var hs := [h0, h1, h2]
	var vs := [[a, b], [b, c], [c, a]]
	for i in 3:
		var h: float = hs[i]
		if h == 0.0:
			continue
		var d := _seg_dist(p, vs[i][0], vs[i][1])
		if h >= 2.0:
			rim = maxf(rim, smoothstep(0.007, 0.0012, d))
		elif h > 0.0:
			hi = maxf(hi, h * smoothstep(0.006, 0.0012, d))
		else:
			lo = maxf(lo, -h * smoothstep(0.007, 0.001, d))
	return [hi, lo, rim]


# ------------------------------------------------------------------ atlas layout

## Lays every triangle (or edge-sharing pair) out in an atlas. Returns {uv: 3 per triangle in texels, texel_mm}.
static func _layout(P: PackedVector3Array, T: int, size: int) -> Dictionary:
	var charts: Array = []   # {tris: [..], pts: [Vector2 x3 per tri, meters], min, size}
	var used := PackedByteArray()
	used.resize(T)
	var area_sum := 0.0
	for t in T:
		if used[t] == 1:
			continue
		used[t] = 1
		var chart := _make_chart(P, t, t + 1 if (t + 1 < T and used[t + 1] == 0) else -1)
		if chart.tris.size() == 2:
			used[t + 1] = 1
		charts.append(chart)
		area_sum += chart.size.x * chart.size.y
	# texels per meter so the charts fill ~62% of the atlas
	var k := sqrt(0.62 * size * size / maxf(area_sum, 1e-9))
	var placed: Array = []
	var ok := false
	for attempt in 14:
		placed = _pack(charts, k, size)
		if not placed.is_empty():
			ok = true
			break
		k *= 0.93
	var uv := PackedVector2Array()
	uv.resize(T * 3)
	if ok:
		for i in charts.size():
			var ch: Dictionary = charts[i]
			var org: Vector2 = placed[i]
			for ti in ch.tris.size():
				var t: int = ch.tris[ti]
				for v in 3:
					var q: Vector2 = ch.pts[ti * 3 + v]
					uv[t * 3 + v] = org + (q - ch.min) * k + Vector2(2, 2)
	return {"uv": uv, "offset": PackedVector2Array(), "texel_mm": 1000.0 / k}


static func _make_chart(P: PackedVector3Array, t: int, t2: int) -> Dictionary:
	var a := P[t * 3]
	var b := P[t * 3 + 1]
	var c := P[t * 3 + 2]
	var tris := [t]
	var pts: Array = []
	var paired := false
	if t2 >= 0:
		var d := [P[t2 * 3], P[t2 * 3 + 1], P[t2 * 3 + 2]]
		var A := [a, b, c]
		var shared_a: Array = []
		for i in 3:
			for j in 3:
				if A[i].distance_squared_to(d[j]) < 1e-9:
					shared_a.append(i)
					break
		if shared_a.size() == 2:
			paired = true
			var ip: int = shared_a[0]
			var iq: int = shared_a[1]
			var p: Vector3 = A[ip]
			var q: Vector3 = A[iq]
			var s: Vector3 = A[3 - ip - iq]
			var r := Vector3.ZERO
			for j in 3:
				if d[j].distance_squared_to(p) > 1e-9 and d[j].distance_squared_to(q) > 1e-9:
					r = d[j]
			var L := maxf(p.distance_to(q), 1e-6)
			var ex := (q - p) / L
			var sx := (s - p).dot(ex)
			var sy := sqrt(maxf((s - p).length_squared() - sx * sx, 0.0))
			var rx := (r - p).dot(ex)
			var ry := -sqrt(maxf((r - p).length_squared() - rx * rx, 0.0))
			var P2 := Vector2(0, 0)
			var Q2 := Vector2(L, 0)
			var S2 := Vector2(sx, sy)
			var R2 := Vector2(rx, ry)
			var m := {ip: P2, iq: Q2, 3 - ip - iq: S2}
			for i in 3:
				pts.append(m[i])
			tris.append(t2)
			for j in 3:
				if d[j].distance_squared_to(p) <= 1e-9:
					pts.append(P2)
				elif d[j].distance_squared_to(q) <= 1e-9:
					pts.append(Q2)
				else:
					pts.append(R2)
	if not paired:
		var L2 := maxf(a.distance_to(b), 1e-6)
		var ex2 := (b - a) / L2
		var cx := (c - a).dot(ex2)
		var cy := sqrt(maxf((c - a).length_squared() - cx * cx, 0.0))
		pts = [Vector2(0, 0), Vector2(L2, 0), Vector2(cx, cy)]
	# turn the chart to the angle with the smallest bounding box (less wasted atlas)
	var best_a := 0.0
	var best_area := 1e18
	for step in 12:
		var ang := step * PI / 12.0
		var lo2 := Vector2(1e9, 1e9)
		var hi2 := Vector2(-1e9, -1e9)
		for q in pts:
			var r2: Vector2 = (q as Vector2).rotated(ang)
			lo2 = lo2.min(r2)
			hi2 = hi2.max(r2)
		var ar := (hi2.x - lo2.x) * (hi2.y - lo2.y)
		if ar < best_area:
			best_area = ar
			best_a = ang
	for i in pts.size():
		pts[i] = (pts[i] as Vector2).rotated(best_a)
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for q2 in pts:
		lo = lo.min(q2)
		hi = hi.max(q2)
	return {"tris": tris, "pts": pts, "min": lo, "size": hi - lo}


## Shelf packing. Returns each chart's origin in texels, or [] when it does not fit.
static func _pack(charts: Array, k: float, size: int) -> Array:
	var order: Array = range(charts.size())
	order.sort_custom(func(x, y): return charts[x].size.y > charts[y].size.y)
	var placed: Array = []
	placed.resize(charts.size())
	var x := 0.0
	var y := 0.0
	var row_h := 0.0
	for i in order:
		var w: float = ceilf(charts[i].size.x * k) + 4.0
		var h: float = ceilf(charts[i].size.y * k) + 4.0
		if x + w > size:
			x = 0.0
			y += row_h
			row_h = 0.0
		if y + h > size:
			return []
		placed[i] = Vector2(x, y)
		x += w
		row_h = maxf(row_h, h)
	return placed


# ------------------------------------------------------------------ occlusion

class _AO:
	var origin := Vector3.ZERO
	var dim := Vector3i.ZERO
	var grid := PackedByteArray()

	func build(P: PackedVector3Array, T: int) -> void:
		var lo := Vector3(1e9, 1e9, 1e9)
		var hi := -lo
		for p in P:
			lo = lo.min(p)
			hi = hi.max(p)
		origin = lo - Vector3(0.06, 0.06, 0.06)
		var ext := hi + Vector3(0.06, 0.06, 0.06) - origin
		dim = Vector3i(int(ext.x / AO_CELL) + 1, int(ext.y / AO_CELL) + 1, int(ext.z / AO_CELL) + 1)
		grid.resize(dim.x * dim.y * dim.z)
		for t in T:
			var a := P[t * 3]
			var b := P[t * 3 + 1]
			var c := P[t * 3 + 2]
			var n := clampi(int(ceilf(maxf(a.distance_to(b), maxf(b.distance_to(c), c.distance_to(a))) / 0.005)), 1, 40)
			for i in n + 1:
				for j in n + 1 - i:
					mark(a + (b - a) * (float(i) / n) + (c - a) * (float(j) / n))

	func mark(p: Vector3) -> void:
		var q := (p - origin) / AO_CELL
		var ix := int(q.x)
		var iy := int(q.y)
		var iz := int(q.z)
		if ix >= 0 and iy >= 0 and iz >= 0 and ix < dim.x and iy < dim.y and iz < dim.z:
			grid[(iz * dim.y + iy) * dim.x + ix] = 1

	func hit(p: Vector3) -> int:
		var q := (p - origin) / AO_CELL
		var ix := int(q.x)
		var iy := int(q.y)
		var iz := int(q.z)
		if ix >= 0 and iy >= 0 and iz >= 0 and ix < dim.x and iy < dim.y and iz < dim.z:
			return grid[(iz * dim.y + iy) * dim.x + ix]
		return 0

	## 1 = open, lower = other layers or folds close above this point.
	func occlusion(p: Vector3, n: Vector3) -> float:
		var ref := Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT
		var tg := n.cross(ref).normalized()
		var bt := n.cross(tg)
		var dirs := [n, (n + tg * 0.8).normalized(), (n - tg * 0.8).normalized(), (n + bt * 0.8).normalized(), (n - bt * 0.8).normalized(), (n + (tg + bt) * 0.6).normalized()]
		var occ := 0
		for d in dirs:
			for dist in [0.021, 0.04]:
				occ += hit(p + d * dist)
		return 1.0 - occ / 12.0 * 0.85


# ------------------------------------------------------------------ painting

class _Noise:
	var a := FastNoiseLite.new()
	var b := FastNoiseLite.new()
	var c := FastNoiseLite.new()

	func _init() -> void:
		a.seed = 11
		a.frequency = 1.0
		b.seed = 23
		b.frequency = 1.0
		c.seed = 37
		c.frequency = 1.0


static func _mix(x: Color, y: Color, t: float) -> Color:
	return x.lerp(y, clampf(t, 0.0, 1.0))


## [r, g, b, metallic, roughness] for one texel.
static func _paint(kind: Array, P: Vector3, N: Vector3, hi: float, lo: float, rim: float, ao: float, nz: _Noise) -> Array:
	var k: String = kind[0]
	var base: Color = kind[1]
	var metal: float = kind[2]
	var rough: float = kind[3]
	var key := N.dot(KEY.normalized())
	var shade := clampf(key * 0.5 + 0.5, 0.0, 1.0)
	var col := Color(0.5, 0.5, 0.5)
	var scr := 0.0
	match k:
		"steel", "iron":
			# non-metallic metal: sky above, a dark horizon line, warm ground bounce below
			var v := N.y * 0.85 + N.x * 0.22 + N.z * 0.08 + (P.y - 0.9) * 0.1
			var sky := Color(0.82, 0.88, 0.98)
			var mid := Color(0.5, 0.54, 0.62)
			var hor := Color(0.04, 0.055, 0.1)
			var gnd := Color(0.42, 0.32, 0.24)
			col = _mix(mid, sky, smoothstep(0.25, 0.95, v))
			col = _mix(col, gnd, smoothstep(-0.12, -0.75, v))
			col = _mix(col, hor, (1.0 - smoothstep(0.0, 0.14, absf(v - 0.02))) * 0.6)
			var streak := nz.a.get_noise_3d(P.x * 70.0, P.y * 5.0, P.z * 70.0)
			col *= (1.0 + 0.1 * streak) * (0.72 + 0.5 * shade)
			scr = smoothstep(0.8, 0.86, absf(nz.b.get_noise_3d(P.x * 38.0 + 3.0, P.y * 38.0, P.z * 38.0)))
			col = _mix(col, Color(0.95, 0.96, 1.0), scr * 0.55)
			if k == "iron":
				col = col * Color(0.82, 0.76, 0.7)
				var rust := smoothstep(0.1, 0.4, nz.c.get_noise_3d(P.x * 26.0, P.y * 26.0, P.z * 26.0) + (0.25 - shade * 0.3))
				col = _mix(col, Color(0.42, 0.2, 0.09) * (0.6 + 0.6 * shade), rust * 0.7)
			col = col * base
			col = _mix(col, Color(1.0, 0.99, 0.94), hi * 0.9 + rim * 0.75)
			col = _mix(col, col * Color(0.12, 0.12, 0.16), lo * 0.85)
		"gold":
			var v2 := N.y * 0.8 + N.x * 0.2 + (shade - 0.5) * 0.4
			var dk := Color(0.22, 0.1, 0.03)
			var md := Color(0.8, 0.5, 0.12)
			var lt := Color(1.0, 0.93, 0.6)
			col = _mix(dk, md, smoothstep(-0.5, 0.25, v2))
			col = _mix(col, lt, smoothstep(0.35, 0.95, v2))
			col = _mix(col, Color(1, 0.97, 0.8), hi * 0.9 + rim * 0.7)
			col = _mix(col, dk * 0.5, lo * 0.8)
			scr = 0.0
		"mail":
			# one ring per cell, offset every other row; dark hole, lit upper rim (drybrush)
			var u: float
			var w: float
			if absf(N.y) > absf(N.x) and absf(N.y) > absf(N.z):
				u = P.x
				w = P.z
			elif absf(N.x) > absf(N.z):
				u = P.z
				w = P.y
			else:
				u = P.x
				w = P.y
			var S := 0.0085
			var row := floorf(w / S)
			var uu := u / S + (0.5 if int(row) % 2 != 0 else 0.0)
			var fx := (uu - floorf(uu)) - 0.5
			var fy := (w / S - row) - 0.5
			var r := sqrt(fx * fx + fy * fy) * 2.0
			var body := smoothstep(0.42, 0.56, r) * (1.0 - smoothstep(0.9, 1.02, r))
			var ang := Vector2(fx, fy).normalized().dot(Vector2(-0.5, -0.85).normalized())
			var lit := clampf(ang * 0.5 + 0.5, 0.0, 1.0)
			var hole := Color(0.04, 0.045, 0.06)
			var dark := Color(0.2, 0.22, 0.27)
			var silver := Color(0.86, 0.9, 0.95)
			var ring := _mix(dark, silver, pow(lit, 1.6) * (0.3 + 0.9 * shade) + hi * 0.4)
			col = _mix(hole, ring, body)
			col *= 0.65 + 0.55 * (0.4 + 0.6 * shade)
			col = _mix(col, col * Color(0.8, 0.85, 1.1), (1.0 - shade) * 0.3)
			col *= base * 1.55
			col = _mix(col, Color(0.9, 0.92, 0.96), rim * 0.35)
			col = _mix(col, col * 0.2, lo * 0.8)
		"leather":
			var grain := nz.a.get_noise_3d(P.x * 190.0, P.y * 190.0, P.z * 190.0)
			var blot := nz.b.get_noise_3d(P.x * 9.0, P.y * 9.0, P.z * 9.0)
			var shadow := base * Color(0.55, 0.5, 0.7)
			var light := base * Color(1.5, 1.32, 1.05)
			col = _mix(shadow, light, smoothstep(0.1, 0.95, shade))
			col *= 1.0 + 0.16 * grain + 0.2 * blot
			col = _mix(col, light * Color(1.35, 1.25, 1.1), hi * 0.85)    # worn edges go pale
			col = _mix(col, shadow * 0.35, lo * 0.9)
			if rim > 0.0:
				col = _mix(col, light * 1.7, rim * 0.5)
			# stitching: dashes just inside an open edge are handled by the rim term; creases get a dark line
			col = _mix(col, Color(0.08, 0.05, 0.04), (1.0 - ao) * 0.35)
		"cloth":
			var fold := nz.a.get_noise_3d(P.x * 15.0, P.y * 2.6, P.z * 15.0) * 0.5 + 0.5
			var fine := nz.b.get_noise_3d(P.x * 260.0, P.y * 260.0, P.z * 260.0)
			var sh := clampf(shade * 0.62 + fold * 0.55 - 0.15, 0.0, 1.0)
			var shadow2 := base * Color(0.42, 0.45, 0.75)
			var light2 := base * Color(1.7, 1.6, 1.4)
			col = _mix(shadow2, light2, smoothstep(0.15, 0.92, sh))
			col *= 1.0 + 0.07 * fine
			col = _mix(col, light2 * 1.25, hi * 0.6 + rim * 0.5)
			col = _mix(col, shadow2 * 0.4, lo * 0.85)
	col *= lerpf(0.42, 1.0, ao)
	# grime gathers low on the body and in the hollows
	var grime := smoothstep(1.05, 0.7, P.y) * 0.25 + (1.0 - ao) * 0.15
	col = col * (1.0 - grime * 0.6)
	var m := metal
	var rr := clampf(rough - scr * 0.25 + (0.08 if k == "leather" else 0.0), 0.05, 1.0)
	return [col.r, col.g, col.b, m, rr]
