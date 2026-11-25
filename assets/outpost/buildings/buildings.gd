extends RefCounted
## Outpost buildings (B01-B10, see assets/outpost/MANIFEST.md). The civilian village: poorer and
## more weathered than the Knights' things (weathered oak, limewashed daub, thatch, rubble stone).
##
## Origins: the centre of the ground floor on y = 0, the front door facing +Z.
## Buildings are drawn in real-world meters and built SIZE times bigger (k), so doors, rooms and
## eaves leave room for the over-the-shoulder camera: doors about 1.4 x 2.6 m. Decided 2026-11-25
## (OUTPOST_PLAN.md section 2). Props and furniture stay real-world size: they relate to the body.

## How much bigger than real-world every building is.
const SIZE := 1.3

const HK := preload("res://assets/hideout/Materials/kit.gd")
const K := preload("res://assets/outpost/materials/outpost_kit.gd")


# ---------------------------------------------------------------- timber-framed walls

## [u0, u1] minus the gaps, as a list of Vector2(a, b) intervals.
static func _segments(u0: float, u1: float, gaps: Array) -> Array:
	var out := [Vector2(u0, u1)]
	for g: Vector2 in gaps:
		var nxt := []
		for s: Vector2 in out:
			if g.y <= s.x or g.x >= s.y:
				nxt.append(s)
				continue
			if g.x > s.x:
				nxt.append(Vector2(s.x, g.x))
			if g.y < s.y:
				nxt.append(Vector2(g.y, s.y))
		out = nxt
	return out


## The rectangle (u0..u1, y0..y1) minus openings [o0, o1, oy0, oy1], as Rect2s (u, y).
static func _panels(u0: float, u1: float, y0: float, y1: float, ops: Array) -> Array:
	var breaks := [u0, u1]
	for o in ops:
		for e in [o[0], o[1]]:
			if e > u0 and e < u1:
				breaks.append(e)
	breaks.sort()
	var out := []
	for i in breaks.size() - 1:
		var a: float = breaks[i]
		var c: float = breaks[i + 1]
		if c - a < 0.01:
			continue
		var mid := (a + c) * 0.5
		var free := [Vector2(y0, y1)]
		for o in ops:
			if mid > o[0] and mid < o[1]:
				free = _segments(free[0].x, free[0].y, [Vector2(o[2], o[3])]) if free.size() == 1 else free
		for f: Vector2 in free:
			if f.y - f.x > 0.02:
				out.append(Rect2(a, f.x, c - a, f.y - f.x))
	return out


## One timber-framed wall from a to b (seen from above; the outside is on the left when walking
## from a to b, i.e. dir x UP). ops: [u0, u1, y0, y1, kind] openings ("door" or "window").
## full: this wall covers the corners (front and back); the side walls fit between them.
## Adds its collision boxes to cols.
static func _wall(b: HK.MB, a2: Vector2, b2: Vector2, ops: Array, full: bool, d: Dictionary, cols: Array) -> void:
	var A := Vector3(a2.x, 0, a2.y)
	var Bp := Vector3(b2.x, 0, b2.y)
	var L := A.distance_to(Bp)
	var dir := (Bp - A) / L
	var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP))
	var oak := K.oak("weathered")
	var py: float = d.py
	var plate: float = d.plate
	var e0 := -0.17 if full else 0.17
	var e1 := L + 0.17 if full else L - 0.17
	var gaps := []
	for o in ops:
		if o[4] == "door":
			gaps.append(Vector2(o[0], o[1]))
	# Rubble plinth and the sill beam on it (broken at the door).
	for s: Vector2 in _segments(e0, e1, gaps):
		var m := (s.x + s.y) * 0.5
		b.box(K.rubble(), A + dir * m + Vector3(0, (py - 0.15) * 0.5, 0), Vector3(s.y - s.x, py + 0.15, 0.34), bas, 0.01)
		b.box(oak, A + dir * m + Vector3(0, py + 0.08, 0), Vector3(s.y - s.x, 0.16, 0.2), bas, 0.006)
	b.box(oak, A + dir * (e0 + e1) * 0.5 + Vector3(0, plate, 0), Vector3(e1 - e0, 0.2, 0.22), bas, 0.006)
	# Posts: corners, jambs, and evenly between them.
	var posts := []
	if full:
		posts.append_array([0.0, L])
	for o in ops:
		posts.append_array([o[0] - 0.09, o[1] + 0.09])
	posts.sort()
	var edges := [0.09 if not full else 0.0] + posts + [L - 0.09 if not full else L]
	var extra := []
	for i in edges.size() - 1:
		var gap: float = edges[i + 1] - edges[i]
		var n := int(gap / 1.7)
		for j in n:
			var u: float = edges[i] + gap * (j + 1) / (n + 1)
			var inside := false
			for o in ops:
				if u > o[0] - 0.1 and u < o[1] + 0.1:
					inside = true
			if not inside:
				extra.append(u)
	posts.append_array(extra)
	posts.sort()
	for u: float in posts:
		var door_jamb := false
		for o in ops:
			if o[4] == "door" and (absf(u - (o[0] - 0.09)) < 0.01 or absf(u - (o[1] + 0.09)) < 0.01):
				door_jamb = true
		var yb := -0.05 if door_jamb else py + 0.16
		b.box(oak, A + dir * u + Vector3(0, (yb + plate - 0.1) * 0.5, 0), Vector3(0.18, plate - 0.1 - yb, 0.18), bas, 0.006)
	# Mid rail between posts, except across openings.
	var rail_y := 1.45
	var stops := [0.0 if full else 0.09] + posts + [L if full else L - 0.09]
	for i in stops.size() - 1:
		var ua: float = stops[i]
		var ub: float = stops[i + 1]
		var blocked := false
		for o in ops:
			if (ua + ub) * 0.5 > o[0] - 0.1 and (ua + ub) * 0.5 < o[1] + 0.1:
				blocked = true
		if not blocked and ub - ua > 0.2:
			b.box(oak, A + dir * (ua + ub) * 0.5 + Vector3(0, rail_y, 0), Vector3(ub - ua, 0.14, 0.18), bas, 0.005)
	# Heads and sills of the openings; bars and open shutters on the windows.
	for o in ops:
		var w: float = o[1] - o[0]
		var m: float = (o[0] + o[1]) * 0.5
		b.box(oak, A + dir * m + Vector3(0, o[3] + 0.07, 0), Vector3(w + 0.36, 0.14, 0.19), bas, 0.005)
		if o[4] == "window":
			b.box(oak, A + dir * m + Vector3(0, o[2] - 0.07, 0), Vector3(w + 0.36, 0.14, 0.19), bas, 0.005)
			for f in [0.33, 0.67]:
				b.box(oak, A + dir * (o[0] + w * f) + Vector3(0, (o[2] + o[3]) * 0.5, 0), Vector3(0.05, o[3] - o[2], 0.05), bas)
			for side in [-1.0, 1.0]:
				var hinge: Vector3 = A + dir * (o[0] if side < 0.0 else o[1]) + bas.z * 0.11
				var sb := bas * Basis(Vector3.UP, -side * 0.35)
				b.box(oak, hinge + sb * Vector3(side * w * 0.25, (o[2] + o[3]) * 0.5, 0.02), Vector3(w * 0.5, o[3] - o[2] + 0.06, 0.035), sb, 0.004)
	# Daub infill between the timbers.
	var rects := _panels(e0 if full else 0.0, e1 if full else L, py + 0.16, plate - 0.1, ops.map(func(o): return [o[0], o[1], -1.0 if o[4] == "door" else o[2], o[3]]))
	for r: Rect2 in rects:
		b.box(K.daub(), A + dir * (r.position.x + r.size.x * 0.5) + Vector3(0, r.position.y + r.size.y * 0.5, 0), Vector3(r.size.x, r.size.y, 0.12), bas)
	# Collision: the wall, open at the door.
	for s: Vector2 in _segments(e0, e1, gaps):
		cols.append(["box", A + dir * (s.x + s.y) * 0.5 + Vector3(0, (plate - 0.05) * 0.5, 0), Vector3(s.y - s.x, plate + 0.25, 0.3), bas])
	for g: Vector2 in gaps:
		var top: float = d.door_top
		cols.append(["box", A + dir * (g.x + g.y) * 0.5 + Vector3(0, (top + plate + 0.1) * 0.5, 0), Vector3(g.y - g.x, plate + 0.1 - top, 0.3), bas])


## A gable end above the wall plate: a daub triangle with a king post, collar and raking timbers.
static func _gable(b: HK.MB, a2: Vector2, b2: Vector2, y0: float, apex: float) -> void:
	var A := Vector3(a2.x, 0, a2.y)
	var Bp := Vector3(b2.x, 0, b2.y)
	var L := A.distance_to(Bp)
	var dir := (Bp - A) / L
	var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP))
	var oak := K.oak("weathered")
	b.push(Transform3D(bas, A))
	K.extrude(b, K.daub(), K.daub(), PackedVector2Array([Vector2(0.05, y0), Vector2(L - 0.05, y0), Vector2(L * 0.5, apex)]), -0.06, 0.12, Rect2(0, y0, L, apex - y0), true)
	b.pop()
	var p := func(u: float, y: float) -> Vector3: return A + dir * u + Vector3(0, y, 0)
	b.box(oak, p.call(L * 0.5, (y0 + apex) * 0.5), Vector3(0.16, apex - y0, 0.17), bas, 0.005)
	var cy := lerpf(y0, apex, 0.45)
	var half := L * 0.5 * (1.0 - 0.45)
	b.box(oak, p.call(L * 0.5, cy), Vector3(half * 2.0, 0.14, 0.17), bas, 0.005)
	for s in [0.0, L]:
		var a: Vector3 = p.call(s, y0)
		var c: Vector3 = p.call(L * 0.5, apex)
		b.box(oak, (a + c) * 0.5, Vector3(a.distance_to(c), 0.16, 0.18), bas * Basis(Vector3(0, 0, 1), atan2(apex - y0, L * 0.5) * (1.0 if s == 0.0 else -1.0)), 0.005)


## A thatched gable roof: two thick slabs from the eaves to the ridge with a rolled ridge,
## rafters, a ridge beam and two tie beams inside. Returns the height of the ridge top.
## Adds collision for the two slabs and the tie beams: out of the player's reach, but it keeps
## the camera's arm from passing through the thatch or a beam indoors.
static func _thatch_roof(b: HK.MB, hx: float, hz: float, plate: float, pitch_deg: float, cols: Array) -> float:
	var p := deg_to_rad(pitch_deg)
	var t := tan(p)
	var y0 := plate + 0.1
	var zw := hz + 0.1
	var ov := 0.55
	var gov := 0.42
	var th := 0.36
	var ylo := func(az: float) -> float: return y0 + (zw - az) * t
	var x0 := -hx - gov
	var x1 := hx + gov
	var aze := zw + ov
	var slope := aze / cos(p)
	for s in [1.0, -1.0]:
		var n := Vector3(0, cos(p), s * sin(p))
		var r0 := Vector3(x0, ylo.call(0.0), 0)
		var r1 := Vector3(x1, ylo.call(0.0), 0)
		var e0 := Vector3(x0, ylo.call(aze), s * aze)
		var e1 := Vector3(x1, ylo.call(aze), s * aze)
		var nt := n * th
		var w := x1 - x0
		b.tri(K.thatch(), r0 + nt, r1 + nt, e1 + nt, n, Vector2(0, 0), Vector2(w, 0), Vector2(w, slope))
		b.tri(K.thatch(), r0 + nt, e1 + nt, e0 + nt, n, Vector2(0, 0), Vector2(w, slope), Vector2(0, slope))
		b.tri(K.thatch(), r0, r1, e1, -n, Vector2(0, 0), Vector2(w, 0), Vector2(w, slope))
		b.tri(K.thatch(), r0, e1, e0, -n, Vector2(0, 0), Vector2(w, slope), Vector2(0, slope))
		var down := Vector3(0, -sin(p), s * cos(p))
		cols.append(["box", (r0 + e0) * 0.5 + Vector3((x0 + x1) * 0.5 - x0, 0, 0) + nt * 0.5, Vector3(w, th, slope), Basis(Vector3(1, 0, 0), s * p)])
		b.tri(K.thatch(), e0, e1, e1 + nt, down, Vector2(0, 0), Vector2(w, 0), Vector2(w, th))
		b.tri(K.thatch(), e0, e1 + nt, e0 + nt, down, Vector2(0, 0), Vector2(w, th), Vector2(0, th))
		for g in [[r0, e0, -1.0], [r1, e1, 1.0]]:
			var ra: Vector3 = g[0]
			var ea: Vector3 = g[1]
			var out := Vector3(g[2], 0, 0)
			b.tri(K.thatch(), ra, ea, ea + nt, out, Vector2(0, 0), Vector2(slope, 0), Vector2(slope, th))
			b.tri(K.thatch(), ra, ea + nt, ra + nt, out, Vector2(0, 0), Vector2(slope, th), Vector2(0, th))
		# Rafters under the thatch.
		var x := -hx + 0.3
		while x < hx - 0.2:
			var lo := Vector3(x, y0 - 0.04, s * (hz - 0.02))
			var hi := Vector3(x, ylo.call(0.0) - 0.12, 0)
			b.box(K.oak("weathered"), (lo + hi) * 0.5 - n * 0.05, Vector3(0.1, 0.12, lo.distance_to(hi)), Basis(Vector3(1, 0, 0), s * p), 0.004)
			x += 0.9
	var top: float = ylo.call(0.0) + th / cos(p)
	b.cyl(K.thatch(), Vector3(x0 - 0.03, top - 0.12, 0), Vector3(x1 + 0.03, top - 0.12, 0), 0.26, 0.26, 10)
	b.box(K.oak("weathered"), Vector3(0, ylo.call(0.0) - 0.16, 0), Vector3(hx * 2.0, 0.16, 0.16), Basis(), 0.005)
	for tx in [-hx * 0.36, hx * 0.36]:
		b.box(K.oak("weathered"), Vector3(tx, plate, 0), Vector3(0.16, 0.18, hz * 2.0 + 0.2), Basis(), 0.006)
		cols.append(["box", Vector3(tx, plate, 0), Vector3(0.16, 0.18, hz * 2.0)])
	return top + 0.14



# ---------------------------------------------------------------- shared house parts

## Earth floor, a stone threshold and step, and a plank door standing open into the room.
static func _floor_and_door(b: HK.MB, hx: float, hz: float, fl: float, door_x: float, door_w: float, cols: Array) -> void:
	b.box(K.earth_floor(), Vector3(0, fl - 0.06, 0), Vector3(hx * 2.0 - 0.16, 0.12, hz * 2.0 - 0.16))
	b.box(K.limestone(), Vector3(door_x, fl - 0.02, hz), Vector3(door_w + 0.1, 0.09, 0.36), Basis(), 0.006)
	b.box(K.limestone(), Vector3(door_x, 0.03, hz + 0.5), Vector3(door_w + 0.3, 0.07, 0.5), Basis(Vector3.UP, 0.05), 0.01)
	cols.append(["box", Vector3(0, fl - 0.06, 0), Vector3(hx * 2.0, 0.12, hz * 2.0)])
	var hinge := Vector3(door_x - door_w * 0.5 + 0.02, fl + 0.01, hz - 0.05)
	var db := Basis(Vector3.UP, deg_to_rad(72.0))
	b.box(K.oak("weathered"), hinge + db * Vector3(0.53, 0.99, 0), Vector3(1.06, 1.97, 0.05), db, 0.004)
	for y in [0.4, 1.55]:
		b.box(K.iron(), hinge + db * Vector3(0.45, y, 0.03), Vector3(0.9, 0.06, 0.012), db)
	K.ring(b, K.iron(), hinge + db * Vector3(0.95, 1.0, 0.045), db * Vector3(0, 0, 1), 0.04, 0.007, 8)


## A rubble chimney outside one gable (s = -1 west, +1 east) and the hearth inside it: stone jambs,
## an oak lintel, a stone breast, logs and embers. Returns where the fire burns (unscaled).
static func _chimney_and_hearth(b: HK.MB, s: float, hx: float, plate: float, top: float, fl: float, cols: Array) -> Vector3:
	var cx := s * (hx + 0.09 + 0.42)
	b.box(K.rubble(), Vector3(cx, (plate + 0.2 - 0.15) * 0.5, 0), Vector3(0.84, plate + 0.35, 1.3), Basis(), 0.012)
	b.box(K.rubble(), Vector3(cx - s * 0.05, (plate + 0.2 + top + 0.85) * 0.5, 0), Vector3(0.62, top + 0.85 - plate - 0.2, 0.72), Basis(), 0.01)
	b.box(K.limestone(), Vector3(cx - s * 0.05, top + 0.9, 0), Vector3(0.76, 0.1, 0.86), Basis(), 0.008)
	cols.append(["box", Vector3(cx, (plate + 0.2 - 0.15) * 0.5, 0), Vector3(0.84, plate + 0.35, 1.3)])
	var hw := s * (hx - 0.09)
	b.box(K.limestone(), Vector3(hw - s * 0.42, fl + 0.03, 0), Vector3(0.8, 0.06, 1.6), Basis(), 0.008)
	for z in [-0.62, 0.62]:
		b.box(K.rubble(), Vector3(hw - s * 0.25, fl + 0.6, z), Vector3(0.5, 1.2, 0.26), Basis(), 0.008)
	b.box(K.oak("weathered"), Vector3(hw - s * 0.33, fl + 1.28, 0), Vector3(0.2, 0.2, 1.64), Basis(), 0.006)
	b.box(K.rubble(), Vector3(hw - s * 0.2, (fl + 1.38 + plate) * 0.5, 0), Vector3(0.4, plate - fl - 1.38, 1.3), Basis(), 0.008)
	var bx := hw - s * 0.01
	K.face(b, HK.plain(Color(0.05, 0.045, 0.04), 1.0), Vector3(bx, fl + 1.18, -0.49), Vector3(bx, fl + 1.18, 0.49),
		Vector3(bx, fl + 0.06, 0.49), Vector3(bx, fl + 0.06, -0.49), Vector3(-s, 0, 0))
	for i in 3:
		var z := -0.22 + i * 0.22
		b.cyl(K.oak("weathered"), Vector3(hw - s * 0.15, fl + 0.12, z - 0.05), Vector3(hw - s * 0.62, fl + 0.1, z + 0.05), 0.055, 0.05, 6)
	for i in 6:
		b.blob(HK.ember(), Vector3(hw - s * (0.3 + (i % 3) * 0.1), fl + 0.07, -0.18 + (i / 3) * 0.3), Vector3(0.07, 0.035, 0.06), i, 0.3, 2.0, 3, 6)
	cols.append(["box", Vector3(hw - s * 0.3, fl + 0.7, 0), Vector3(0.62, 1.4, 1.6)])
	return Vector3(hw - s * 0.4, fl + 0.18, 0)


## A shingled gable roof (ridge along x): thin slabs with oak undersides, fascia boards and a
## ridge board. Eaves pass over the wall plates at height y0. Returns the ridge top height.
static func _shingle_roof(b: HK.MB, hx: float, hz: float, y0: float, pitch_deg: float, cols: Array, ov := 0.5, gov := 0.35) -> float:
	var p := deg_to_rad(pitch_deg)
	var t := tan(p)
	var zw := hz + 0.1
	var aze := zw + ov
	var ylo := func(az: float) -> float: return y0 + (zw - az) * t
	var x0 := -hx - gov
	var x1 := hx + gov
	var w := x1 - x0
	var slope := aze / cos(p)
	var th := 0.07
	for s in [1.0, -1.0]:
		var n := Vector3(0, cos(p), s * sin(p))
		var r0 := Vector3(x0, ylo.call(0.0), 0)
		var r1 := Vector3(x1, ylo.call(0.0), 0)
		var e0 := Vector3(x0, ylo.call(aze), s * aze)
		var e1 := Vector3(x1, ylo.call(aze), s * aze)
		var nt := n * th
		b.tri(K.shingles(), r0 + nt, r1 + nt, e1 + nt, n, Vector2(0, 0), Vector2(w, 0), Vector2(w, slope))
		b.tri(K.shingles(), r0 + nt, e1 + nt, e0 + nt, n, Vector2(0, 0), Vector2(w, slope), Vector2(0, slope))
		b.tri(K.oak("weathered"), r0, r1, e1, -n, Vector2(0, 0), Vector2(w, 0), Vector2(w, slope))
		b.tri(K.oak("weathered"), r0, e1, e0, -n, Vector2(0, 0), Vector2(w, slope), Vector2(0, slope))
		b.box(K.oak("weathered"), (e0 + e1) * 0.5 + nt * 0.5, Vector3(w, 0.16, 0.05), Basis(Vector3(1, 0, 0), s * p), 0.004)
		for x in [x0, x1]:
			var a := Vector3(x, ylo.call(0.0), 0) + nt * 0.5
			var c := Vector3(x, ylo.call(aze), s * aze) + nt * 0.5
			b.box(K.oak("weathered"), (a + c) * 0.5, Vector3(0.05, 0.16, slope), Basis(Vector3(1, 0, 0), s * p), 0.004)
		cols.append(["box", (r0 + e0) * 0.5 + Vector3(-x0, 0, 0) + nt * 0.5, Vector3(w, th, slope), Basis(Vector3(1, 0, 0), s * p)])
	var top: float = ylo.call(0.0) + th / cos(p)
	b.box(K.oak("weathered"), Vector3(0, top, 0), Vector3(w + 0.04, 0.12, 0.22), Basis(), 0.004)
	return top + 0.06


## Vertical oak boards between a and b (outside = dir x UP), from y0 up to a top that runs from
## top_a to top_b, leaving openings [u0, u1, y0, y1]. Corner posts, a top rail, collision.
static func _plank_wall(b: HK.MB, a2: Vector2, b2: Vector2, y0: float, top_a: float, top_b: float, ops: Array, cols: Array) -> void:
	var A := Vector3(a2.x, 0, a2.y)
	var Bp := Vector3(b2.x, 0, b2.y)
	var L := A.distance_to(Bp)
	var dir := (Bp - A) / L
	var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP))
	var oak := K.oak("weathered")
	var u := 0.0
	var i := 0
	while u < L - 0.01:
		var bw := minf(0.2 + 0.06 * HK.MB.new(i).rng.randf(), L - u)
		var m := u + bw * 0.5
		var top := lerpf(top_a, top_b, m / L)
		var segs := [Vector2(y0, top)]
		for o in ops:
			if m > o[0] and m < o[1]:
				segs = _segments(y0, top, [Vector2(o[2], o[3])])
		for sg: Vector2 in segs:
			if sg.y - sg.x > 0.02:
				b.box(oak, A + dir * m + Vector3(0, (sg.x + sg.y) * 0.5, 0), Vector3(bw - 0.012, sg.y - sg.x, 0.04), bas, 0.004)
		u += bw
		i += 1
	for e in [0.0, L]:
		var top := lerpf(top_a, top_b, e / L)
		b.box(oak, A + dir * e + Vector3(0, (y0 + top) * 0.5, 0), Vector3(0.14, top - y0, 0.14), bas, 0.005)
	var ta := A + Vector3(0, top_a - 0.05, 0)
	var tb := Bp + Vector3(0, top_b - 0.05, 0)
	b.box(oak, (ta + tb) * 0.5 + bas.z * 0.03, Vector3(ta.distance_to(tb), 0.1, 0.08), bas * Basis(Vector3(0, 0, 1), atan2(top_b - top_a, L)), 0.004)
	for o in ops:
		b.box(oak, A + dir * (o[0] + o[1]) * 0.5 + Vector3(0, o[3] + 0.05, 0) + bas.z * 0.03, Vector3(o[1] - o[0] + 0.2, 0.1, 0.06), bas, 0.004)
	var gaps := []
	for o in ops:
		if o[2] <= y0 + 0.01:
			gaps.append(Vector2(o[0], o[1]))
	var hmax := maxf(top_a, top_b)
	for sg: Vector2 in _segments(0.0, L, gaps):
		cols.append(["box", A + dir * (sg.x + sg.y) * 0.5 + Vector3(0, hmax * 0.5, 0), Vector3(sg.y - sg.x, hmax, 0.12), bas])

# ---------------------------------------------------------------- B07: the small cottage

## B07: small thatched cottage: a rubble plinth, an oak frame with limewashed daub, a steep thick
## thatch, a stone chimney on the west gable, a plank door standing open, shuttered windows, an
## earth floor and a lit hearth inside. One room. Drawn at 6.4 x 4.6 m walls, door 1.1 x 2.0 m,
## eaves about 2.4 m, ridge about 5.6 m; built at SIZE: walls 8.3 x 6 m, door 1.4 x 2.6 m.
static func small_cottage(k := SIZE) -> Node3D:
	var b := HK.MB.new(307)
	var hx := 3.2
	var hz := 2.3
	var fl := 0.06
	var d := {"py": 0.38, "plate": 2.5, "door_top": fl + 2.0}
	var plate: float = d.plate
	var door_x := -1.0
	var door_w := 1.1
	var win := [1.15, 1.75]
	var cols := []
	# Walls: front (+Z, the door), east, back, west (the hearth and chimney).
	_wall(b, Vector2(-hx, hz), Vector2(hx, hz), [
		[door_x - door_w * 0.5 + hx, door_x + door_w * 0.5 + hx, fl, d.door_top, "door"],
		[1.5 - 0.35 + hx, 1.5 + 0.35 + hx, win[0], win[1], "window"]], true, d, cols)
	_wall(b, Vector2(hx, hz), Vector2(hx, -hz), [[hz - 0.35, hz + 0.35, win[0], win[1], "window"]], false, d, cols)
	_wall(b, Vector2(hx, -hz), Vector2(-hx, -hz), [[hx - 0.4 - 0.35, hx - 0.4 + 0.35, win[0], win[1], "window"]], true, d, cols)
	_wall(b, Vector2(-hx, -hz), Vector2(-hx, hz), [], false, d, cols)
	var top := _thatch_roof(b, hx, hz, plate, 45.0, cols)
	var apex := plate + 0.1 + (hz + 0.1) * tan(deg_to_rad(45.0)) - 0.05
	_gable(b, Vector2(hx, hz), Vector2(hx, -hz), plate + 0.1, apex)
	_gable(b, Vector2(-hx, -hz), Vector2(-hx, hz), plate + 0.1, apex)
	_floor_and_door(b, hx, hz, fl, door_x, door_w, cols)
	var fire := _chimney_and_hearth(b, -1.0, hx, plate, top, fl, cols)
	var root := K.asset("B07_small_cottage", b, cols, k)
	HK.fire_fx(root, fire * k, 0.42 * k, 1.8, false)
	return root


# ---------------------------------------------------------------- B08: the medium cottage

## B08: medium cottage: B07's longer, taller sister: three bays, two front windows, the door
## off-centre, the chimney and hearth on the east gable. Drawn 9.2 x 5.4 m walls, eaves 2.6 m;
## built at SIZE (about 12 x 7 m). One long room.
static func medium_cottage(k := SIZE) -> Node3D:
	var b := HK.MB.new(308)
	var hx := 4.6
	var hz := 2.7
	var fl := 0.06
	var d := {"py": 0.4, "plate": 2.6, "door_top": fl + 2.0}
	var plate: float = d.plate
	var door_x := 0.6
	var door_w := 1.1
	var win := [1.15, 1.75]
	var cols := []
	_wall(b, Vector2(-hx, hz), Vector2(hx, hz), [
		[-2.6 - 0.35 + hx, -2.6 + 0.35 + hx, win[0], win[1], "window"],
		[door_x - door_w * 0.5 + hx, door_x + door_w * 0.5 + hx, fl, d.door_top, "door"],
		[2.8 - 0.35 + hx, 2.8 + 0.35 + hx, win[0], win[1], "window"]], true, d, cols)
	_wall(b, Vector2(hx, hz), Vector2(hx, -hz), [], false, d, cols)
	_wall(b, Vector2(hx, -hz), Vector2(-hx, -hz), [
		[hx - 2.0 - 0.35, hx - 2.0 + 0.35, win[0], win[1], "window"],
		[hx + 1.8 - 0.35, hx + 1.8 + 0.35, win[0], win[1], "window"]], true, d, cols)
	_wall(b, Vector2(-hx, -hz), Vector2(-hx, hz), [[hz - 0.35, hz + 0.35, win[0], win[1], "window"]], false, d, cols)
	var top := _thatch_roof(b, hx, hz, plate, 45.0, cols)
	var apex := plate + 0.1 + (hz + 0.1) * tan(deg_to_rad(45.0)) - 0.05
	_gable(b, Vector2(hx, hz), Vector2(hx, -hz), plate + 0.1, apex)
	_gable(b, Vector2(-hx, -hz), Vector2(-hx, hz), plate + 0.1, apex)
	_floor_and_door(b, hx, hz, fl, door_x, door_w, cols)
	var fire := _chimney_and_hearth(b, 1.0, hx, plate, top, fl, cols)
	var root := K.asset("B08_medium_cottage", b, cols, k)
	HK.fire_fx(root, fire * k, 0.42 * k, 1.8, false)
	return root


# ---------------------------------------------------------------- B09: the storage shed

## B09: storage shed: a board-walled store on stone pads with a shingled lean-to roof (high at the
## back), a door standing ajar and an earth floor. Drawn 3.8 x 2.8 m, 2.2 m at the front; built
## at SIZE. Front faces +Z.
static func storage_shed(k := SIZE) -> Node3D:
	var b := HK.MB.new(309)
	var hx := 1.9
	var hz := 1.4
	var yf := 2.2
	var yb := 2.7
	var cols := []
	var door := [hx - 0.55, hx + 0.55, 0.0, 2.0]
	_plank_wall(b, Vector2(-hx, hz), Vector2(hx, hz), 0.0, yf, yf, [door], cols)
	_plank_wall(b, Vector2(hx, hz), Vector2(hx, -hz), 0.0, yf, yb, [], cols)
	_plank_wall(b, Vector2(hx, -hz), Vector2(-hx, -hz), 0.0, yb, yb, [], cols)
	_plank_wall(b, Vector2(-hx, -hz), Vector2(-hx, hz), 0.0, yb, yf, [], cols)
	for x in [-hx, hx]:
		for z in [-hz, hz]:
			b.box(K.rubble(), Vector3(x, 0.02, z), Vector3(0.3, 0.12, 0.3), Basis(), 0.01)
	b.box(K.earth_floor(), Vector3(0, -0.03, 0), Vector3(hx * 2.0 - 0.1, 0.1, hz * 2.0 - 0.1))
	# Lean-to roof: shingles from the back down over the front, oak underneath.
	var ov := 0.4
	var a := Vector3(-hx - 0.3, yb + 0.08 + ov * (yb - yf) / (2.0 * hz), -hz - ov)
	var c := Vector3(hx + 0.3, a.y, -hz - ov)
	var e := Vector3(hx + 0.3, yf + 0.08 - ov * (yb - yf) / (2.0 * hz), hz + ov)
	var f := Vector3(-hx - 0.3, e.y, hz + ov)
	var n := (c - a).cross(f - a).normalized()
	if n.y < 0.0:
		n = -n
	b.quad(K.shingles(), a + n * 0.06, c + n * 0.06, e + n * 0.06, f + n * 0.06, n)
	b.quad(K.oak("weathered"), a, c, e, f, -n)
	b.box(K.oak("weathered"), (e + f) * 0.5 + n * 0.03, Vector3(e.distance_to(f), 0.14, 0.05), Basis(), 0.004)
	cols.append(["box", (a + e) * 0.5 + n * 0.03, Vector3(c.distance_to(a), 0.08, a.distance_to(f)), Basis(Vector3(1, 0, 0), -atan2(a.y - f.y, f.z - a.z))])
	# The door, ajar outward.
	var hinge := Vector3(-0.55, 0.02, hz + 0.04)
	var db := Basis(Vector3.UP, deg_to_rad(-35.0))
	b.box(K.oak("weathered"), hinge + db * Vector3(0.54, 0.99, 0), Vector3(1.06, 1.96, 0.05), db, 0.004)
	for y in [0.35, 1.6]:
		b.box(K.iron(), hinge + db * Vector3(0.45, y, 0.03), Vector3(0.9, 0.06, 0.012), db)
	return K.asset("B09_storage_shed", b, cols, k)


# ---------------------------------------------------------------- B04: the large market shelter

## B04: large market shelter: an open-sided timber hall over the market, three bays of posts on
## stone pads, braces, tie beams and a shingled roof. Stalls and tables stand under it. Drawn
## 8 x 5.2 m, eaves 2.7 m; built at SIZE (about 10.4 x 6.8 m). Long side faces +Z.
static func market_shelter(k := SIZE) -> Node3D:
	var b := HK.MB.new(304)
	var oak := K.oak("weathered")
	var hx := 4.0
	var hz := 2.6
	var eave := 2.7
	var cols := []
	for x in [-hx, 0.0, hx]:
		for z in [-hz, hz]:
			b.box(K.rubble(), Vector3(x, 0.08, z), Vector3(0.42, 0.2, 0.42), Basis(), 0.01)
			b.box(oak, Vector3(x, (0.18 + eave) * 0.5, z), Vector3(0.22, eave - 0.18, 0.22), Basis(), 0.006)
			cols.append(["box", Vector3(x, eave * 0.5, z), Vector3(0.26, eave, 0.26)])
			for dx in [-1.0, 1.0]:
				if absf(x + dx * 0.9) <= hx:
					b.box(oak, Vector3(x + dx * 0.42, eave - 0.42, z), Vector3(0.9, 0.12, 0.14), Basis(Vector3(0, 0, 1), -dx * PI * 0.25), 0.004)
		b.box(oak, Vector3(x, eave + 0.05, 0), Vector3(0.2, 0.22, hz * 2.0 + 0.3), Basis(), 0.006)
		b.box(oak, Vector3(x, eave + 0.95, 0), Vector3(0.18, 1.6, 0.18), Basis(), 0.006)
	for z in [-hz, hz]:
		b.box(oak, Vector3(0, eave + 0.05, z), Vector3(hx * 2.0 + 0.3, 0.22, 0.24), Basis(), 0.006)
	_shingle_roof(b, hx, hz, eave + 0.16, 32.0, cols, 0.6, 0.5)
	return K.asset("B04_large_market_shelter", b, cols, k)


# ---------------------------------------------------------------- B05: the small market stall

## B05: small market stall: a plank counter on a timber frame, a back shelf and a sloping linen
## canvas roof. Market furniture, so real-world size (counter 0.95 m: it must fit the body).
## 2.4 x 1.5 m. The trader stands behind (-Z); customers come to the front (+Z).
static func market_stall(k := 1.0) -> Node3D:
	var b := HK.MB.new(305)
	var oak := K.oak("weathered")
	var hx := 1.2
	var hz := 0.75
	var cols := []
	for x in [-hx, hx]:
		b.box(oak, Vector3(x, 1.05, hz), Vector3(0.1, 2.1, 0.1), Basis(), 0.006)
		b.box(oak, Vector3(x, 1.25, -hz), Vector3(0.1, 2.5, 0.1), Basis(), 0.006)
		b.box(oak, Vector3(x, 2.25, 0), Vector3(0.08, 0.08, hz * 2.0 + 0.1), Basis(Vector3(1, 0, 0), atan2(0.4, hz * 2.0)), 0.004)
	# Counter: a front board wall and a thick top.
	b.box(oak, Vector3(0, 0.47, hz - 0.05), Vector3(hx * 2.0, 0.86, 0.05), Basis(), 0.004)
	b.box(oak, Vector3(0, 0.93, hz - 0.2), Vector3(hx * 2.0 + 0.1, 0.06, 0.5), Basis(), 0.005)
	b.box(oak, Vector3(0, 0.4, hz - 0.3), Vector3(hx * 2.0 - 0.1, 0.04, 0.4), Basis(), 0.004)
	cols.append(["box", Vector3(0, 0.48, hz - 0.2), Vector3(hx * 2.0, 0.96, 0.5)])
	# Back shelf.
	for y in [0.9, 1.4]:
		b.box(oak, Vector3(0, y, -hz + 0.12), Vector3(hx * 2.0 - 0.1, 0.04, 0.26), Basis(), 0.004)
	for x in [-hx, hx]:
		cols.append(["box", Vector3(x, 1.25, 0), Vector3(0.12, 2.5, hz * 2.0)])
	# Canvas roof with a scalloped front edge.
	var nu := 11
	var nv := 5
	var pts := PackedVector3Array()
	var uvs := PackedVector2Array()
	for j in nv:
		var t := float(j) / (nv - 1)
		var z := lerpf(-hz - 0.1, hz + 0.25, t)
		for i in nu:
			var x := lerpf(-hx - 0.15, hx + 0.15, float(i) / (nu - 1))
			var y := lerpf(2.55, 2.12, t) - 0.08 * sin(PI * t) - 0.03 * sin(PI * float(i) / (nu - 1))
			pts.append(Vector3(x, y, z))
			uvs.append(Vector2(x + hx, t * 1.8))
	K.sheet2(b, K.linen(), pts, uvs, nu, nv, Vector3.UP)
	var vp := PackedVector3Array()
	var vu := PackedVector2Array()
	for j in 3:
		for i in nu * 2 - 1:
			var x := lerpf(-hx - 0.15, hx + 0.15, float(i) / (nu * 2 - 2))
			var drop := 0.16 + 0.08 * absf(sin(PI * (x + hx + 0.15) / 0.4))
			var y := 2.12 - drop * float(j) / 2.0
			vp.append(Vector3(x, y, hz + 0.25))
			vu.append(Vector2(x + hx, 1.8 + 2.12 - y))
	K.sheet2(b, K.linen(), vp, vu, nu * 2 - 1, 3, Vector3(0, 0, 1))
	return K.asset("B05_small_market_stall", b, cols, k)
