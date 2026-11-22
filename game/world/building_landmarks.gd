extends RefCounted
## The Tithelands' landmark buildings, built from the building kit (game/world/building_kit.gd):
## the stone tithe barn, the water mill and the round watchtower. Each keeps the footprint,
## doorways and walkable floors of the old blockout so gameplay is unchanged.

const BK := preload("res://game/world/building_kit.gd")
const Kit := preload("res://assets/hideout/Materials/kit.gd")
const SPIN := preload("res://game/world/spin.gd")


# ---------------------------------------------------------------- shared pieces

## Six faces of an eight-corner block (corner index bits: 1 = x/angle, 2 = y, 4 = z/radius).
static func block8(c: BK.Ctx, mat: Material, cs: Array[Vector3]) -> void:
	var cen := Vector3.ZERO
	for p in cs:
		cen += p
	cen /= 8.0
	for axis: int in [1, 2, 4]:
		var others: Array[int] = []
		for b: int in [1, 2, 4]:
			if b != axis:
				others.append(b)
		for s in 2:
			var base := axis if s == 1 else 0
			var idx := [base, base | others[0], base | others[0] | others[1], base | others[1]]
			var fc := (cs[idx[0]] + cs[idx[1]] + cs[idx[2]] + cs[idx[3]]) * 0.25
			c.mb.quad(mat, cs[idx[0]], cs[idx[1]], cs[idx[2]], cs[idx[3]], fc - cen)


## Ring-segment block between angles a0..a1, radii r0..r1, heights y0..y1 (p = (cos a, y, sin a) * r).
static func seg(c: BK.Ctx, mat: Material, a0: float, a1: float, r0: float, r1: float, y0: float, y1: float, jit := 0.0) -> void:
	var cs: Array[Vector3] = []
	for i in 8:
		var a := a1 if (i & 1) else a0
		var y := y1 if (i & 2) else y0
		var r := r1 if (i & 4) else r0
		var p := Vector3(cos(a) * r, y, sin(a) * r)
		if jit > 0.0:
			p += Vector3(c.rng.randf_range(-jit, jit), c.rng.randf_range(-jit, jit), c.rng.randf_range(-jit, jit))
		cs.append(p)
	block8(c, mat, cs)


## Free angle spans in [A0, A0 + TAU) for a course, minus holes Vector4(a0, a1, y0, y1).
const A0 := -PI * 0.75


static func _free_angles(ya: float, yb: float, holes: Array, jag: float, rng: RandomNumberGenerator) -> Array:
	var spans: Array = [Vector2(A0, A0 + TAU)]
	for h: Vector4 in holes:
		if h.z >= yb - 0.01 or h.w <= ya + 0.01:
			continue
		var j0 := 0.0
		var j1 := 0.0
		if jag > 0.0 and h.y - h.x > 0.3 and h.z > 3.0:
			j0 = rng.randf_range(-jag, jag)
			j1 = rng.randf_range(-jag, jag)
		var next: Array = []
		for s: Vector2 in spans:
			var x0 := h.x + j0
			var x1 := h.y + j1
			if x1 <= s.x or x0 >= s.y:
				next.append(s)
				continue
			if x0 > s.x + 0.02:
				next.append(Vector2(s.x, x0))
			if x1 < s.y - 0.02:
				next.append(Vector2(x1, s.y))
		spans = next
	return spans


## Round wall of dressed blocks. batter: extra outer radius per meter below batter_top.
static func ring_wall(c: BK.Ctx, r0: float, r1: float, y0: float, y1: float, holes: Array = [], jag := 0.0,
		batter := 0.0, batter_top := 0.0, course := Vector2(0.27, 0.36), cols := true) -> void:
	var y := y0
	var row := 0
	while y < y1 - 0.03:
		var h := c.rng.randf_range(course.x, course.y)
		for hl: Vector4 in holes:
			for e: float in [hl.z, hl.w]:
				if e > y + 0.08 and e < y + h:
					h = e - y
		if y1 - (y + h) < 0.1:
			h = y1 - y
		var ro := r1 + maxf(0.0, batter_top - (y + h * 0.5)) * batter
		for sp: Vector2 in _free_angles(y, y + h, holes, jag, c.rng):
			# mortar core in pieces that follow the curve
			var n := int(ceil((sp.y - sp.x) / 0.35))
			for k in n:
				var a := sp.x + (sp.y - sp.x) * k / n
				var b := sp.x + (sp.y - sp.x) * (k + 1) / n
				seg(c, c.m.mortar, a, b, r0 + 0.05, ro - 0.05, y, y + h)
			var a := sp.x
			var first := true
			while a < sp.y - 0.01:
				var ln := c.rng.randf_range(0.42, 0.78)
				if first and row % 2 == 1:
					ln *= 0.55
				var da := minf(ln / ro, sp.y - a)
				if sp.y - (a + da) < 0.22 / ro:
					da = sp.y - a
				var out := c.rng.randf_range(-0.01, 0.03)
				seg(c, c.stone(), a + 0.006, a + da - 0.006, r0 - 0.01, ro + out, y + 0.012, y + h - 0.012, 0.018)
				a += da
				first = false
		y += h
		row += 1
	if not cols:
		return
	var ys: Array[float] = [y0, y1]
	for hl: Vector4 in holes:
		for e: float in [hl.z, hl.w]:
			if e > y0 and e < y1:
				ys.append(e)
	ys.sort()
	for i in ys.size() - 1:
		if ys[i + 1] - ys[i] < 0.05:
			continue
		for sp: Vector2 in _free_angles(ys[i], ys[i + 1], holes, 0.0, c.rng):
			var n := int(ceil((sp.y - sp.x) / 0.4))
			for k in n:
				var a := sp.x + (sp.y - sp.x) * (k + 0.5) / n
				var w := (sp.y - sp.x) / n * (r0 + r1) * 0.5 + 0.08
				c.col(Vector3(cos(a), 0, sin(a)) * (r0 + r1) * 0.5 + Vector3(0, (ys[i] + ys[i + 1]) * 0.5, 0),
					Vector3(r1 - r0, ys[i + 1] - ys[i], w), Basis(Vector3.UP, -a))


## Plank door leaf in the current frame: hinge at the origin, leaf along +x, w by hh, studded.
static func door_leaf(c: BK.Ctx, w: float, hh: float, studs := false) -> void:
	var n := maxi(3, roundi(w / 0.26))
	for i in n:
		var pw := w / n
		c.mb.box(c.m.planks, Vector3(pw * (i + 0.5), hh * 0.5 + c.rng.randf_range(-0.01, 0.01), 0), Vector3(pw - 0.012, hh, 0.08), Basis(), 0.006)
	for yy: float in [0.35, hh * 0.5, hh - 0.4]:
		c.mb.box(c.m.planks, Vector3(w * 0.5, yy, -0.07), Vector3(w - 0.1, 0.18, 0.06))
		c.mb.box(c.m.iron, Vector3(w * 0.42, yy, 0.05), Vector3(w * 0.84, 0.07, 0.015))
		if studs:
			var k := 0.15
			while k < w - 0.1:
				c.mb.box(c.m.iron, Vector3(k, yy + 0.16, 0.05), Vector3(0.05, 0.05, 0.03))
				k += 0.3
	BK.beam(c, c.m.planks, Vector3(0.1, 0.45, -0.07), Vector3(w - 0.1, hh * 0.5 - 0.1, -0.07), 0.05, 0.16, 0.0)
	BK.beam(c, c.m.planks, Vector3(0.1, hh * 0.5 + 0.1, -0.07), Vector3(w - 0.1, hh - 0.5, -0.07), 0.05, 0.16, 0.0)


## Stone-slate roof, ridge along x: boarded under, overlapping slates laid from the eave up, ridge tiles.
static func slate_roof(c: BK.Ctx, hx: float, hz: float, plate_y: float, pitch_deg: float, over := 0.45) -> float:
	var p := deg_to_rad(pitch_deg)
	var yr := plate_y + hz * tan(p)
	var S := (hz + over) / cos(p)
	var X := Vector3.RIGHT
	for sgn: float in [1.0, -1.0]:
		var down := Vector3(0, -sin(p), sgn * cos(p))
		var n := Vector3(0, cos(p), sgn * sin(p))
		var bas := Basis(X, n, X.cross(n))
		var R := Vector3(0, yr, 0)
		c.mb.box(c.m.planks_grey, R + down * (S * 0.5) + n * 0.06, Vector3(hx * 2.0, 0.12, S), bas)
		c.col(R + down * (S * 0.5) + n * 0.15, Vector3(hx * 2.0, 0.3, S), bas)
		var s := S
		var row := 0
		while s > 0.2:
			var ex := lerpf(0.2, 0.3, s / S)
			var x := -hx + (0.0 if row % 2 == 0 else -0.2)
			while x < hx - 0.02:
				var w := minf(c.rng.randf_range(0.26, 0.46), hx - x)
				var x0 := maxf(x, -hx)
				var lift := c.rng.randf_range(0.03, 0.05)
				var top := 0.125
				var sl := c.rng.randf_range(-0.03, 0.04)
				var ll := Vector3(x0 + 0.006, 0, 0) + R + down * (s + sl) + n * (top + lift)
				var lr := Vector3(x + w - 0.006, 0, 0) + R + down * (s + sl + c.rng.randf_range(-0.02, 0.02)) + n * (top + lift + c.rng.randf_range(-0.01, 0.01))
				var ul := Vector3(x0 + 0.006, 0, 0) + R + down * (s - 0.5) + n * (top + 0.005)
				var ur := Vector3(x + w - 0.006, 0, 0) + R + down * (s - 0.5) + n * (top + 0.005)
				var mat: Material = c.m.slate if c.rng.randf() < 0.75 else c.m.slate_b
				c.mb.quad(mat, ll, lr, ur, ul, n)
				c.mb.quad(mat, ll, lr, lr - n * 0.03, ll - n * 0.03, down)
				x += w
			s -= ex
			row += 1
	var ry := yr + 0.2 / cos(p)
	var x := -hx
	while x < hx - 0.05:
		var l := minf(0.42, hx - x)
		c.mb.cyl(c.m.slate, Vector3(x + 0.01, ry, 0), Vector3(x + l - 0.01, ry, 0), 0.2, 0.19, 8, 0.03)
		x += l
	return ry + 0.2


## Stone gable wall a→b (centerline) with a triangle rising under the roof line and coping on top.
static func stone_gable(c: BK.Ctx, a: Vector2, b: Vector2, y0: float, plate: float, th: float, hz: float, pitch_deg: float, holes: Array = []) -> void:
	BK.rubble(c, a, b, y0, plate, th, holes)
	var tp := tan(deg_to_rad(pitch_deg))
	var L := BK._push_wall(c, a, b)
	var y := plate
	while true:
		var h := c.rng.randf_range(0.2, 0.3)
		var half := hz - (y + h - plate) / tp
		if half < 0.2:
			break
		var u := L * 0.5 - half
		var u1 := L * 0.5 + half
		c.mb.box(c.m.mortar, Vector3(L * 0.5, y + h * 0.5, 0), Vector3(half * 2.0, h, th * 0.84))
		while u < u1 - 0.04:
			var ln := minf(c.rng.randf_range(0.3, 0.7), u1 - u)
			if u1 - (u + ln) < 0.15:
				ln = u1 - u
			c.mb.box(c.stone(), Vector3(u + ln * 0.5, y + h * 0.5, c.rng.randf_range(-0.01, 0.015)), Vector3(ln - 0.03, h - 0.028, th + c.rng.randf_range(-0.02, 0.04)), Basis(), 0.02)
			u += ln
		y += h
	# coping along both rakes, kneelers at the feet, a finial at the apex
	var apex := Vector3(L * 0.5, plate + hz * tp + 0.05, 0)
	for e: float in [0.0, L]:
		var foot := Vector3(e, plate + (hz - L * 0.5) * tp + 0.05, 0)
		BK.beam(c, c.m.stone_q, foot, apex, th + 0.14, 0.7, 0.01)
		c.mb.box(c.m.stone_q, foot + Vector3(0.25 if e == 0.0 else -0.25, -0.25, 0), Vector3(0.7, 0.5, th + 0.16), Basis(), 0.02)
	c.mb.box(c.m.stone_q, apex + Vector3(0, 0.45, 0), Vector3(0.4, 0.5, 0.4), Basis(), 0.02)
	c.mb.pop()


# ---------------------------------------------------------------- tithe barn

## Long stone barn: buttressed walls with slits, stone gables with coping, slate roof, oak trusses,
## great double doors (one standing open) on the +z gable. Walls 9 x 15 m.
static func tithe_barn(mats: Dictionary, seed_: int) -> Node3D:
	var c := BK.Ctx.new(seed_, mats)
	var hx := 7.5  # along world z (the barn's length), built with the ridge along local x
	var hz := 4.5
	var th := 0.7
	var plate := 4.4
	var pitch := 47.0
	c.mb.push(Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3.ZERO))  # local x -> +z
	var L := hz * 2.0 + th
	var door := Vector4(L * 0.5 - 2.0, L * 0.5 + 2.0, 0.0, 4.4)
	# long walls with slits and buttresses
	for sgn: float in [1.0, -1.0]:
		var a := Vector2(-hx + th * 0.5, hz) if sgn > 0 else Vector2(hx - th * 0.5, -hz)
		var b := Vector2(hx - th * 0.5, hz) if sgn > 0 else Vector2(-hx + th * 0.5, -hz)
		var Lw := a.distance_to(b)
		var slits: Array = []
		for k in 4:
			var u := Lw * (k + 0.5) / 4.0
			slits.append(Vector4(u - 0.1, u + 0.1, 1.7, 3.2))
		BK.rubble(c, a, b, -0.5, plate, th, slits, false)
		BK._push_wall(c, a, b)
		for s: Vector4 in slits:
			c.mb.box(mats.dark, Vector3((s.x + s.y) * 0.5, (s.z + s.w) * 0.5, -0.05), Vector3(0.22, s.w - s.z + 0.02, 0.06))
		for k in 3:
			_buttress(c, Lw * (k + 1) / 4.0, -0.5, 3.4, th * 0.5)
		c.mb.pop()
	stone_gable(c, Vector2(hx, hz + th * 0.5), Vector2(hx, -hz - th * 0.5), -0.5, plate, th, hz, pitch, [door])
	stone_gable(c, Vector2(-hx, -hz - th * 0.5), Vector2(-hx, hz + th * 0.5), -0.5, plate, th, hz, pitch, [Vector4(L * 0.5 - 0.12, L * 0.5 + 0.12, 5.0, 6.4)])
	# great doors
	BK._push_wall(c, Vector2(hx, hz + th * 0.5), Vector2(hx, -hz - th * 0.5))
	c.mb.box(mats.oak, Vector3(L * 0.5, 4.2, 0.05), Vector3(4.0, 0.4, th - 0.1), Basis(), 0.015)
	for e: float in [door.x + 0.13, door.y - 0.13]:
		c.mb.box(mats.oak, Vector3(e, 2.0, 0.1), Vector3(0.26, 4.0, 0.34), Basis(), 0.012)
	var lw := (4.0 - 0.52) * 0.5
	c.mb.push(Transform3D(Basis(), Vector3(door.x + 0.26, 0.02, 0.1)))
	door_leaf(c, lw, 3.95, true)
	c.col(Vector3(lw * 0.5, 2.0, 0), Vector3(lw, 4.0, 0.12))
	c.mb.pop()
	c.mb.push(Transform3D(Basis(Vector3.UP, PI + deg_to_rad(105)), Vector3(door.y - 0.26, 0.02, 0.2)))
	door_leaf(c, lw, 3.95, true)
	c.col(Vector3(lw * 0.5, 2.0, 0), Vector3(lw, 4.0, 0.12))
	c.mb.pop()
	c.mb.pop()
	# floor, trusses, roof
	c.mb.box(mats.mortar, Vector3(0, -0.05, 0), Vector3(hx * 2.0 - th, 0.2, hz * 2.0 - th))
	var tp := tan(deg_to_rad(pitch))
	var x := -hx + 2.5
	while x < hx - 1.5:
		var zi := hz - th * 0.5
		BK.beam(c, mats.oak, Vector3(x, plate - 0.15, -zi), Vector3(x, plate - 0.15, zi), 0.3, 0.36)
		var top := Vector3(x, plate + hz * tp - 0.25, 0)
		BK.beam(c, mats.oak, Vector3(x, plate, 0), top, 0.28, 0.26)
		for s: float in [-1.0, 1.0]:
			BK.beam(c, mats.oak, Vector3(x, plate + 0.05, s * (zi - 0.1)), top + Vector3(0, -0.05, s * 0.1), 0.26, 0.3)
			BK.beam(c, mats.oak, Vector3(x, plate + 0.2, s * 0.2), Vector3(x, plate + hz * tp * 0.5, s * hz * 0.5), 0.2, 0.18)
		x += 3.0
	slate_roof(c, hx, hz, plate + 0.05, pitch)
	# mounting stones and a trough by the door
	c.mb.box(mats.stone_q, Vector3(hx + 1.3, 0.15, -hz + 0.6), Vector3(1.0, 0.5, 0.7), Basis(Vector3.UP, 0.1), 0.04)
	c.mb.box(mats.stone_q, Vector3(hx + 1.0, 0.35, -hz + 0.55), Vector3(0.6, 0.45, 0.6), Basis(Vector3.UP, 0.05), 0.04)
	c.mb.pop()
	return BK.finish(c, "Building")


## Stepped buttress against a wall (in the wall's frame: x along it, z out from face `face`).
static func _buttress(c: BK.Ctx, u: float, y0: float, y1: float, face: float) -> void:
	var y := y0
	var w := 0.85
	while y < y1:
		var h := minf(c.rng.randf_range(0.26, 0.36), y1 - y)
		var d := 0.95 if y < y1 * 0.55 else 0.6
		c.mb.box(c.m.mortar, Vector3(u, y + h * 0.5, face + d * 0.5 - 0.02), Vector3(w - 0.06, h, d - 0.06))
		var split := c.rng.randf_range(0.35, 0.6)
		for part in 2:
			var w0 := -w * 0.5 if part == 0 else -w * 0.5 + w * split
			var w1 := -w * 0.5 + w * split if part == 0 else w * 0.5
			c.mb.box(c.m.stone_q if part == 0 else c.stone(), Vector3(u + (w0 + w1) * 0.5, y + h * 0.5, face + d * 0.5), Vector3(w1 - w0 - 0.03, h - 0.025, d + c.rng.randf_range(-0.02, 0.03)), Basis(), 0.02)
		y += h
	# sloped weathering on the steps
	c.mb.box(c.m.stone_q, Vector3(u, y1 * 0.55 + 0.05, face + 0.78), Vector3(w + 0.04, 0.16, 0.5), Basis(Vector3.RIGHT, 0.55), 0.015)
	c.mb.box(c.m.stone_q, Vector3(u, y1 + 0.1, face + 0.3), Vector3(w + 0.04, 0.16, 0.7), Basis(Vector3.RIGHT, 0.6), 0.015)
	c.col(Vector3(u, (y0 + y1) * 0.5, face + 0.45), Vector3(w, y1 - y0, 0.9))


# ---------------------------------------------------------------- mill

## Water mill: stone ground floor, framed upper floor with a loft door and hoist beam, thatch,
## a turning wheel on +x in a stone wheel pit. Walls 7 x 7 m, door on +z.
static func mill(mats: Dictionary, seed_: int) -> Node3D:
	var c := BK.Ctx.new(seed_, mats)
	var hx := 3.5
	var hz := 3.5
	var th := 0.6
	var stone_top := 3.0
	var plate := 5.9
	var pitch := 50.0
	var daub: Material = mats.daub_grey
	c.mb.push(Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3.ZERO))  # local x -> +z (front gable)
	var L := hz * 2.0 + th
	# ground floor in stone: door in the front gable, window at the back, axle through the -z side
	BK.rubble(c, Vector2(hx, hz + th * 0.5), Vector2(hx, -hz - th * 0.5), -0.6, stone_top, th, [Vector4(L * 0.5 - 0.8, L * 0.5 + 0.8, 0.1, 2.75)])
	BK.rubble(c, Vector2(hx - th * 0.5, -hz), Vector2(-hx + th * 0.5, -hz), -0.6, stone_top, th, [Vector4(hx - th * 0.5 - 0.3, hx - th * 0.5 + 0.3, 2.3, 2.9)], false)
	BK.rubble(c, Vector2(-hx, -hz - th * 0.5), Vector2(-hx, hz + th * 0.5), -0.6, stone_top, th, [Vector4(L * 0.5 - 0.4, L * 0.5 + 0.4, 1.3, 2.0)])
	BK.rubble(c, Vector2(-hx + th * 0.5, hz), Vector2(hx - th * 0.5, hz), -0.6, stone_top, th, [], false)
	BK._push_wall(c, Vector2(hx, hz + th * 0.5), Vector2(hx, -hz - th * 0.5))
	c.mb.box(mats.oak, Vector3(L * 0.5, 2.62, 0.05), Vector3(1.6, 0.26, th + 0.04), Basis(), 0.012)
	c.mb.push(Transform3D(Basis(Vector3.UP, deg_to_rad(-70)), Vector3(L * 0.5 - 0.78, 0.12, -0.15)))
	door_leaf(c, 1.55, 2.45)
	c.mb.pop()
	c.mb.pop()
	BK._push_wall(c, Vector2(-hx, -hz - th * 0.5), Vector2(-hx, hz + th * 0.5))
	c.mb.box(mats.dark, Vector3(L * 0.5, 1.65, -0.05), Vector3(0.82, 0.72, 0.06))
	c.mb.box(mats.stone_q, Vector3(L * 0.5, 1.22, 0.05), Vector3(1.1, 0.14, th + 0.12), Basis(), 0.015)
	c.mb.pop()
	c.mb.box(mats.planks, Vector3(0, 0.0, 0), Vector3(hx * 2.0 - th, 0.2, hz * 2.0 - th))
	c.col(Vector3(0, -0.3, 0), Vector3(hx * 2.0 - th, 0.6, hz * 2.0 - th))
	# floor joists showing between stone and frame, then the timber upper floor
	BK.frame_wall(c, Vector2(-hx, hz), Vector2(hx, hz), stone_top, plate, [Vector4(hx - 0.45, hx + 0.45, stone_top + 0.8, stone_top + 1.45)], daub)
	BK.frame_wall(c, Vector2(hx, hz), Vector2(hx, -hz), stone_top, plate, [Vector4(hz - 0.65, hz + 0.65, stone_top + 0.75, stone_top + 2.25)], daub, false, {})
	BK.frame_wall(c, Vector2(hx, -hz), Vector2(-hx, -hz), stone_top, plate, [], daub)
	BK.frame_wall(c, Vector2(-hx, -hz), Vector2(-hx, hz), stone_top, plate, [Vector4(hz - 0.4, hz + 0.4, stone_top + 0.85, stone_top + 1.5)], daub, false)
	BK.gable(c, hx, hz, plate, pitch, daub)
	BK.gable(c, -hx, hz, plate, pitch, daub)
	var top := BK.thatch_roof(c, hx + 0.02, hz, plate, pitch, mats.thatch_old, 0.45, 0.65, 0.5)
	# hoist beam out of the front gable with a pulley, rope and hook
	var hy := plate + hz * tan(deg_to_rad(pitch)) * 0.62
	BK.beam(c, mats.oak, Vector3(hx - 1.0, hy, 0), Vector3(hx + 1.55, hy, 0), 0.24, 0.26)
	BK.beam(c, mats.oak, Vector3(hx + 0.1, hy - 1.2, 0), Vector3(hx + 1.0, hy - 0.1, 0), 0.16, 0.16)
	c.mb.cyl(mats.oak_grey, Vector3(hx + 1.3, hy - 0.3, -0.06), Vector3(hx + 1.3, hy - 0.3, 0.06), 0.16, 0.16, 10)
	c.mb.cyl(mats.iron, Vector3(hx + 1.3, hy - 0.13, 0), Vector3(hx + 1.3, hy - 0.3, 0), 0.03, 0.03, 4)
	c.mb.cyl(mats.rope, Vector3(hx + 1.46, hy - 0.3, 0), Vector3(hx + 1.46, 2.6, 0), 0.02, 0.02, 4, 0.0, false)
	c.mb.cyl(mats.iron, Vector3(hx + 1.46, 2.6, 0), Vector3(hx + 1.46, 2.35, 0.05), 0.025, 0.02, 4)
	c.mb.pop()
	# wheel pit along the +x wall (scene axes from here)
	var pit_x := hx + th * 0.5
	c.mb.box(mats.water, Vector3(pit_x + 0.95, 0.05, 0), Vector3(1.9, 0.02, 6.4))
	c.mb.box(mats.dark, Vector3(pit_x + 0.95, -0.5, 0), Vector3(1.9, 0.1, 6.4))
	BK.rubble(c, Vector2(pit_x + 2.0, 3.3), Vector2(pit_x + 2.0, -3.3), -0.9, 0.55, 0.45)
	BK.rubble(c, Vector2(pit_x, 3.2), Vector2(pit_x + 2.25, 3.2), -0.9, 0.3, 0.4, [], false)
	BK.rubble(c, Vector2(pit_x + 2.25, -3.2), Vector2(pit_x, -3.2), -0.9, 0.3, 0.4, [], false)
	c.mb.cyl(mats.oak, Vector3(hx - 0.3, 2.6, 0), Vector3(pit_x + 1.6, 2.6, 0), 0.2, 0.2, 10, 0.02, true)
	for xx: float in [pit_x + 0.08, pit_x + 1.5]:
		c.mb.cyl(mats.iron, Vector3(xx, 2.6, 0), Vector3(xx + 0.12, 2.6, 0), 0.23, 0.23, 10)
	# bearing post at the far end of the axle
	c.mb.box(mats.oak, Vector3(pit_x + 1.75, 1.3, 0), Vector3(0.3, 3.2, 0.36), Basis(), 0.015)
	c.col(Vector3(pit_x + 1.0, 0.0, 0), Vector3(2.4, 0.6, 6.8))
	c.col(Vector3(pit_x + 0.95, 2.8, 0), Vector3(0.8, 5.4, 5.4))
	var root := BK.finish(c, "Building")
	var wc := BK.Ctx.new(seed_ + 1, mats)
	_wheel(wc, 2.7, 0.7)
	var wheel := MeshInstance3D.new()
	wheel.name = "Wheel"
	wheel.mesh = wc.mb.build()
	wheel.position = Vector3(pit_x + 0.95, 2.6, 0)
	wheel.set_script(SPIN)
	wheel.set("speed", -0.35)
	root.add_child(wheel)
	return root


## Water wheel turning about local x: two rims, crossed spokes, hub, paddles.
static func _wheel(c: BK.Ctx, r: float, w: float) -> void:
	var segs := 18
	for side: float in [-1.0, 1.0]:
		var x := side * (w * 0.5 - 0.05)
		for i in segs:
			var a0 := TAU * i / segs
			var a1 := TAU * (i + 1) / segs
			var cs: Array[Vector3] = []
			for k in 8:
				var a := a1 if (k & 1) else a0
				var yy := (r if (k & 2) else r - 0.24)
				var xx := x + (0.05 if (k & 4) else -0.05)
				cs.append(Vector3(xx, cos(a) * yy, sin(a) * yy))
			block8(c, c.m.oak, cs)
		for i in 4:
			var a := TAU * i / 8.0 + (0.0 if side < 0 else PI / 8.0)
			c.mb.box(c.m.oak, Vector3(x, 0, 0), Vector3(0.12, (r - 0.1) * 2.0, 0.16), Basis(Vector3.RIGHT, a), 0.01)
	c.mb.cyl(c.m.oak, Vector3(-w * 0.5 - 0.1, 0, 0), Vector3(w * 0.5 + 0.1, 0, 0), 0.38, 0.38, 10, 0.03)
	for xx: float in [-w * 0.5 - 0.02, w * 0.5 - 0.06]:
		c.mb.cyl(c.m.iron, Vector3(xx, 0, 0), Vector3(xx + 0.08, 0, 0), 0.41, 0.41, 10)
	var n := 20
	for i in n:
		var a := TAU * i / n
		var mid := r - 0.12
		c.mb.box(c.m.planks_grey, Vector3(0, cos(a) * mid, sin(a) * mid), Vector3(w - 0.12, 0.42, 0.05), Basis(Vector3.RIGHT, a), 0.01)


# ---------------------------------------------------------------- watchtower

## Round tower of dressed stone (r 3.2, walls to 12 m) with a battered base, doors north and south,
## arrow slits, a breach high on +x, a plank floor at 10 m with a ladder hole, corbels, parapet and
## merlons. The ladder itself is a separate node in levels/tithelands/props/watchtower.tscn.
static func watchtower(mats: Dictionary, seed_: int) -> Node3D:
	var c := BK.Ctx.new(seed_, mats)
	var r0 := 2.7
	var r1 := 3.2
	var dw := 0.82 / r1  # half door width in radians
	var holes := [
		Vector4(-PI * 0.5 - dw, -PI * 0.5 + dw, -1.0, 2.85),
		Vector4(PI * 0.5 - dw, PI * 0.5 + dw, -1.0, 2.85),
		Vector4(-0.36, 0.36, 8.2, 13.0),  # breach
		Vector4(PI * 0.5 - 0.03, PI * 0.5 + 0.03, 5.5, 6.6),
		Vector4(-PI * 0.5 - 0.03, -PI * 0.5 + 0.03, 7.3, 8.4),
		Vector4(PI - 0.03, PI + 0.03, 4.9, 6.0),
		Vector4(PI * 0.75 - 0.03, PI * 0.75 + 0.03, 9.0, 9.9),
	]
	ring_wall(c, r0, r1, -0.8, 11.84, holes, 0.12, 0.35, 1.3)
	# lintels over the doors, dark backing in the slits
	for a: float in [-PI * 0.5, PI * 0.5]:
		seg(c, mats.stone_q, a - dw - 0.05, a + dw + 0.05, r0 - 0.02, r1 + 0.05, 2.4, 2.85, 0.015)
		for s: float in [-1.0, 1.0]:
			var p := Vector3(cos(a + s * dw * 0.92), 0, sin(a + s * dw * 0.92)) * (r1 - 0.12)
			c.mb.box(mats.oak, p + Vector3(0, 1.2, 0), Vector3(0.22, 2.4, 0.22), Basis(Vector3.UP, -a), 0.012)
	for h: Vector4 in holes.slice(3):
		var a := (h.x + h.y) * 0.5
		c.mb.box(mats.dark, Vector3(cos(a), 0, sin(a)) * (r0 + 0.25) + Vector3(0, (h.z + h.w) * 0.5, 0), Vector3(0.05, h.w - h.z, 0.24), Basis(Vector3.UP, -a), 0.0)
	# corbels, parapet and merlons
	var nc := 26
	for i in nc:
		var a := TAU * i / nc
		if absf(wrapf(a, -PI, PI)) < 0.5:
			continue
		seg(c, mats.stone_q, a - 0.07, a + 0.07, r1 - 0.02, r1 + 0.16, 11.4, 11.62, 0.012)
		seg(c, mats.stone_q, a - 0.06, a + 0.06, r1 - 0.02, r1 + 0.3, 11.62, 11.84, 0.012)
	var par := [Vector4(-0.6, 0.6, 0.0, 20.0)]
	ring_wall(c, r0 + 0.25, r1 + 0.28, 11.84, 12.6, par, 0.15)
	for i in 10:
		var a := TAU * i / 10.0
		if absf(wrapf(a, -PI, PI)) < 0.75:
			continue
		var hw := 0.5 / (r1 + 0.1)
		var mh := 1.0 if c.rng.randf() < 0.8 else c.rng.randf_range(0.4, 0.7)
		var y := 12.6
		while y < 12.6 + mh - 0.05:
			var h := minf(c.rng.randf_range(0.28, 0.38), 12.6 + mh - y)
			seg(c, c.stone(), a - hw, a + hw, r0 + 0.28, r1 + 0.27, y, y + h - 0.02, 0.015)
			y += h
		seg(c, mats.stone_q, a - hw - 0.02, a + hw + 0.02, r0 + 0.24, r1 + 0.32, y, y + 0.14, 0.01)
		c.col(Vector3(cos(a), 0, sin(a)) * (r1 + 0.05) + Vector3(0, 12.6 + mh * 0.5, 0), Vector3(0.5, mh, 1.0), Basis(Vector3.UP, -a))
	# plank floor at 10 m with joists and the ladder hole at (0, -1.5)
	var fy := 10.025
	var z := -r0 + 0.1
	while z < r0 - 0.05:
		var hw := sqrt(maxf(r0 * r0 - z * z, 0.0)) + 0.05
		var spans: Array = [Vector2(-hw, hw)]
		if z > -2.1 and z < -0.9:
			spans = [Vector2(-hw, -0.6), Vector2(0.6, hw)]
		for sp: Vector2 in spans:
			if sp.y - sp.x > 0.1:
				c.mb.box(mats.planks_grey, Vector3((sp.x + sp.y) * 0.5, fy - 0.03, z + 0.11), Vector3(sp.y - sp.x, 0.06, 0.205), Basis(), 0.006)
		z += 0.22
	for x: float in [-1.9, -0.7, 0.7, 1.9]:
		var hl := sqrt(r0 * r0 - x * x) + 0.1
		c.mb.box(mats.oak, Vector3(x, fy - 0.17, 0), Vector3(0.18, 0.22, hl * 2.0), Basis(), 0.01)
	for b: Array in [[Vector3(0, 0, 0.9), Vector3(5.6, 0.25, 3.6)], [Vector3(-1.65, 0, -1.8), Vector3(2.1, 0.25, 1.8)],
			[Vector3(1.65, 0, -1.8), Vector3(2.1, 0.25, 1.8)], [Vector3(0, 0, -2.45), Vector3(1.3, 0.25, 0.7)]]:
		c.col(b[0] + Vector3(0, fy - 0.125, 0), b[1])
	# railing round the ladder hatch (getting on and off the ladder teleports, so it only stops falls)
	var hx0 := -0.68
	var hx1 := 0.68
	var hz0 := -2.18
	var hz1 := -0.82
	for p: Vector2 in [Vector2(hx0, hz0), Vector2(hx1, hz0), Vector2(hx0, hz1), Vector2(hx1, hz1)]:
		c.mb.box(mats.oak_grey, Vector3(p.x, fy + 0.5, p.y), Vector3(0.1, 1.0, 0.1), Basis(), 0.01)
	var sides := [[Vector3(hx0, 0, hz0), Vector3(hx1, 0, hz0)], [Vector3(hx0, 0, hz1), Vector3(hx1, 0, hz1)],
		[Vector3(hx0, 0, hz0), Vector3(hx0, 0, hz1)], [Vector3(hx1, 0, hz0), Vector3(hx1, 0, hz1)]]
	for sd: Array in sides:
		for ry: float in [0.5, 0.95]:
			BK.beam(c, mats.oak_grey, sd[0] + Vector3(0, fy + ry, 0), sd[1] + Vector3(0, fy + ry, 0), 0.06, 0.08, 0.01)
		var mid: Vector3 = (sd[0] + sd[1]) * 0.5
		var size := Vector3(absf(sd[1].x - sd[0].x) + 0.1, 1.0, absf(sd[1].z - sd[0].z) + 0.1)
		c.col(mid + Vector3(0, fy + 0.5, 0), size)
	# ground: earth floor inside, fallen blocks under the breach
	c.mb.box(mats.ash, Vector3(0, -0.06, 0), Vector3(r0 * 1.9, 0.12, r0 * 1.9))
	for i in 12:
		var a := c.rng.randf_range(-0.7, 0.7)
		var d := c.rng.randf_range(r1 + 0.4, r1 + 3.5)
		var p := Vector3(cos(a) * d, c.rng.randf_range(-0.12, 0.05), sin(a) * d)
		var sz := Vector3(c.rng.randf_range(0.35, 0.6), c.rng.randf_range(0.25, 0.35), c.rng.randf_range(0.3, 0.45))
		var rot := Basis(Vector3.UP, c.rng.randf() * TAU) * Basis(Vector3.FORWARD, c.rng.randf_range(-0.35, 0.35))
		c.mb.box(c.stone(), p + Vector3(0, sz.y * 0.4, 0), sz, rot, 0.03)
	return BK.finish(c, "Building")


## The mill weir: a stone crest across the river with an oak capping beam and posts on the
## pond side, a stone apron sloping down under the sheeting water, boulders and foam at the
## foot. Local x runs downstream, z across; y = 0 is the water level below the drop, the crest
## top is at +0.78. Visual only (you still wade across).
static func weir(mats: Dictionary, seed_: int) -> Node3D:
	var c := BK.Ctx.new(seed_, mats)
	var r := c.rng
	var half := 8.0
	# crest wall: courses of squared stones, bedded into both banks
	var y := -0.75
	var row := 0
	while y < 0.74:
		var h := r.randf_range(0.22, 0.3)
		var z := -half
		while z < half:
			var l := r.randf_range(0.55, 0.95)
			l = minf(l, half - z)
			c.mb.box(c.stone(), Vector3(-0.05 + r.randf_range(-0.03, 0.03), y + h * 0.5, z + l * 0.5 + (0.0 if row % 2 == 0 else 0.0)), Vector3(0.9, h, l - 0.025), Basis(), 0.018)
			z += l
		y += h
		row += 1
	# capping beam and the posts holding it on the pond side
	c.mb.box(mats.oak, Vector3(-0.05, 0.86, 0), Vector3(0.5, 0.16, half * 2.0), Basis(), 0.012)
	var zp := -half + 0.6
	while zp < half:
		c.mb.box(mats.oak, Vector3(-0.62, 0.45, zp), Vector3(0.2, 1.7, 0.2), Basis(), 0.012)
		c.mb.box(mats.iron, Vector3(-0.52, 0.8, zp), Vector3(0.05, 0.3, 0.22))
		zp += 1.9
	# stone apron: a ramp from the crest down to the stream bed below, under the water
	var ang := atan2(-0.5, 2.85)
	var xr := 0.45
	while xr < 3.3:
		var yy := lerpf(0.3, -0.2, (xr - 0.45) / 2.85)
		var zz := -5.6
		while zz < 5.6:
			var l := r.randf_range(0.5, 0.9)
			l = minf(l, 5.6 - zz)
			c.mb.box(c.stone(), Vector3(xr + 0.2, yy - 0.1, zz + l * 0.5), Vector3(0.42, 0.28, l - 0.03), Basis(Vector3(0, 0, 1), ang), 0.02)
			zz += l
		xr += 0.4
	# boulders below the drop
	for i in 7:
		var rr := r.randf_range(0.25, 0.5)
		c.mb.blob(c.stone(), Vector3(r.randf_range(3.2, 4.6), -0.05, r.randf_range(-5.0, 5.0)), Vector3(rr * 1.2, rr * 0.8, rr), 3, 0.25)
	var root := BK.finish(c, "Weir")
	root.add_child(_foam(Vector3(3.9, 0.04, 0.0), Vector2(3.4, 12.0)))
	root.add_child(_foam(Vector3(0.75, 0.52, 0.0), Vector2(0.9, 11.4), 0.55))
	return root


static func _foam(at: Vector3, size: Vector2, strength := 1.0) -> MeshInstance3D:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float strength = 1.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y);
}
void fragment() {
	vec2 p = UV * vec2(5.0, 22.0);
	float n = vn(p + vec2(-TIME * 1.1, 0.0)) * 0.6 + vn(p * 2.3 + vec2(-TIME * 1.7, 3.0)) * 0.4;
	float edge = smoothstep(0.0, 0.2, UV.x) * (1.0 - smoothstep(0.35, 1.0, UV.x)) * smoothstep(0.0, 0.06, UV.y) * (1.0 - smoothstep(0.94, 1.0, UV.y));
	ALBEDO = vec3(0.86, 0.9, 0.92);
	ALPHA = smoothstep(0.5, 0.8, n) * edge * 0.75 * strength;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("strength", strength)
	var pm := PlaneMesh.new()
	pm.size = size
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, pm.get_mesh_arrays())
	am.surface_set_material(0, m)
	var mi := MeshInstance3D.new()
	mi.name = "Foam"
	mi.mesh = am
	mi.position = at
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# ---------------------------------------------------------------- ruined chapel

## Wall a→b with a broken top: profile = [Vector2(u_end, top_y), ...] from the start. Holes are in the
## whole wall's frame (Vector4 u0, u1, y0, y1); each piece gets the part that falls inside it.
static func ruin_wall(c: BK.Ctx, a: Vector2, b: Vector2, y0: float, profile: Array, th: float, holes: Array = []) -> void:
	var dir := (b - a).normalized()
	var u0 := 0.0
	for k in profile.size():
		var p: Vector2 = profile[k]
		var u1 := p.x
		var hs: Array = []
		for h: Vector4 in holes:
			if h.y <= u0 + 0.02 or h.x >= u1 - 0.02:
				continue
			hs.append(Vector4(maxf(h.x, u0) - u0, minf(h.y, u1) - u0, h.z, h.w))
		BK.rubble(c, a + dir * u0, a + dir * u1, y0, p.y, th, hs, k == 0 or k == profile.size() - 1)
		u0 = u1


static func _top_at(profile: Array, u: float) -> float:
	for p: Vector2 in profile:
		if u <= p.x:
			return p.y
	return (profile[profile.size() - 1] as Vector2).y


## Pointed (equilateral) arch opening as stepped holes: width w from u_c, springing at ys, sill y0.
static func arch_holes(u_c: float, w: float, y0: float, ys: float, step := 0.2) -> Array:
	var out: Array = [Vector4(u_c - w * 0.5, u_c + w * 0.5, y0, ys)]
	var apex := w * sqrt(3.0) * 0.5
	var dy := 0.0
	while dy < apex - 0.05:
		var top := minf(dy + step, apex)
		var half := (sqrt(maxf(w * w - top * top, 0.0)) - w * 0.5)
		if half < 0.06:
			break
		out.append(Vector4(u_c - half, u_c + half, ys + dy, ys + top))
		dy = top
	return out


## Dressed stones round the arch on the outer face of wall a→b, plus a sill and jamb stones.
static func arch_ring(c: BK.Ctx, a: Vector2, b: Vector2, th: float, u_c: float, w: float, y0: float, ys: float, top_y: float) -> void:
	var apex := ys + w * sqrt(3.0) * 0.5
	if top_y < apex + 0.15:
		return
	BK._push_wall(c, a, b)
	var n := 7
	for side: float in [1.0, -1.0]:
		var cen := Vector2(u_c + side * w * 0.5, ys)
		for i in n:
			var f := (float(i) + 0.5) / n
			var phi := lerpf(PI, PI * 2.0 / 3.0, f) if side > 0.0 else lerpf(0.0, PI / 3.0, f)
			var rad := w + 0.15
			var pos := cen + Vector2(cos(phi), sin(phi)) * rad
			c.mb.box(c.m.stone_q, Vector3(pos.x, pos.y, th * 0.5 + 0.01), Vector3(0.3, 0.37, 0.12), Basis(Vector3(0, 0, 1), phi), 0.01)
	for sx: float in [-1.0, 1.0]:  # jamb stones
		var yy := y0 + 0.2
		while yy < ys - 0.1:
			c.mb.box(c.m.stone_q, Vector3(u_c + sx * (w * 0.5 + 0.16), yy, th * 0.5 + 0.01), Vector3(0.3, 0.34, 0.12), Basis(), 0.01)
			yy += 0.4
	c.mb.box(c.m.stone_q, Vector3(u_c, y0 - 0.04, th * 0.5 + 0.02), Vector3(w + 0.5, 0.1, 0.3), Basis(), 0.01)
	c.mb.pop()


static func _grave(c: BK.Ctx, at: Vector3, yaw: float, h: float) -> void:
	var r := c.rng
	c.mb.push(Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, r.randf_range(-0.12, 0.12)) * Basis(Vector3(0, 0, 1), r.randf_range(-0.1, 0.1)), at))
	c.mb.box(c.stone(), Vector3(0, h * 0.5 - 0.1, 0), Vector3(0.62, h + 0.1, 0.14), Basis(), 0.03)
	c.mb.box(c.stone(), Vector3(0, h - 0.05, 0), Vector3(0.5, 0.16, 0.12), Basis(), 0.04)
	c.mb.pop()
	c.col(at + Vector3(0, h * 0.5, 0), Vector3(0.62, h, 0.3), Basis(Vector3.UP, yaw))


## Ruined chapel on the south ridge: a stone nave and chancel with pointed lancet windows, the west
## gable and bell-cote still standing, the north wall mostly down, roof beams fallen, flagged floor,
## altar, rubble, a stone cross and leaning gravestones. Nave along x, west door at x = -5.
## Origin at the nave's centre; the whole footprint spans x -5.5 .. 9.3 (z +-3.4).
static func chapel(mats: Dictionary, seed_: int) -> Node3D:
	var c := BK.Ctx.new(seed_, mats)
	var r := c.rng
	var hx := 5.0
	var hz := 2.95
	var th := 0.75
	var y0 := -0.55
	# --- nave south wall: three lancets
	var south_p: Array = [Vector2(1.0, 6.3), Vector2(2.6, 6.0), Vector2(3.4, 4.9), Vector2(4.6, 5.8), Vector2(6.0, 6.1), Vector2(7.1, 3.6), Vector2(8.4, 5.2), Vector2(9.2, 6.0), Vector2(10.0, 6.3)]
	var south_h: Array = []
	var wins_s := [2.1, 5.0, 7.9]
	for u: float in wins_s:
		south_h.append_array(arch_holes(u, 0.9, 1.7, 3.6))
	var sa := Vector2(-hx, hz)
	var sb := Vector2(hx, hz)
	ruin_wall(c, sa, sb, y0, south_p, th, south_h)
	for u: float in wins_s:
		arch_ring(c, sa, sb, th, u, 0.9, 1.7, 3.6, _top_at(south_p, u))
	# --- nave north wall: low, one window stump
	var north_p: Array = [Vector2(1.4, 2.2), Vector2(3.0, 1.4), Vector2(4.2, 3.8), Vector2(5.3, 2.6), Vector2(6.6, 4.6), Vector2(7.8, 1.8), Vector2(10.0, 3.2)]
	ruin_wall(c, Vector2(hx, -hz), Vector2(-hx, -hz), y0, north_p, th, arch_holes(5.0, 0.9, 1.7, 3.6))
	# --- west gable: door and a window above, stepped gable rising to the bell-cote
	var wl := hz * 2.0
	var west_p: Array = []
	var uu := 0.0
	while uu < wl - 0.01:
		uu = minf(uu + 0.6, wl)
		var mid := uu - 0.3
		west_p.append(Vector2(uu, 5.9 + (wl * 0.5 - absf(mid - wl * 0.5)) * 0.62))
	var west_h: Array = []
	west_h.append_array(arch_holes(wl * 0.5, 1.5, -0.55, 2.2))
	west_h.append_array(arch_holes(wl * 0.5, 0.8, 4.3, 5.2))
	var wa := Vector2(-hx, -hz)
	var wb := Vector2(-hx, hz)
	ruin_wall(c, wa, wb, y0, west_p, th, west_h)
	arch_ring(c, wa, wb, th, wl * 0.5, 1.5, 0.0, 2.2, _top_at(west_p, wl * 0.5))
	arch_ring(c, wa, wb, th, wl * 0.5, 0.8, 4.3, 5.2, _top_at(west_p, wl * 0.5))
	# bell-cote on the apex: two piers, a pointed top and a bell
	var apex_y := 5.9 + hz * 0.62
	c.mb.push(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-hx, apex_y - 0.4, 0)))
	for sx: float in [-0.42, 0.42]:
		c.mb.box(c.m.stone_q, Vector3(sx, 0.7, 0), Vector3(0.36, 1.4, 0.55), Basis(), 0.015)
	for i in 5:
		var f := float(i) / 4.0
		c.mb.box(c.m.stone_q, Vector3(0, 1.45 + (1.0 - absf(f - 0.5) * 2.0) * 0.28, 0), Vector3(0.9 - absf(f - 0.5) * 1.3, 0.2, 0.55), Basis(), 0.015)
	c.mb.cyl(mats.iron, Vector3(0, 1.2, 0), Vector3(0, 0.62, 0), 0.1, 0.3, 10, 0.01)
	c.mb.cyl(mats.iron, Vector3(-0.42, 1.28, 0), Vector3(0.42, 1.28, 0), 0.03, 0.03, 6)
	c.mb.pop()
	c.col(Vector3(-hx, apex_y + 0.3, 0), Vector3(0.6, 1.4, 1.3))
	# --- nave east wall with the chancel arch
	var east_p: Array = [Vector2(1.3, 6.3), Vector2(2.0, 5.7), Vector2(3.9, 6.6), Vector2(4.6, 6.0), Vector2(5.9, 5.5)]
	var ea := Vector2(hx, hz)
	var eb := Vector2(hx, -hz)
	ruin_wall(c, ea, eb, y0, east_p, th, arch_holes(hz, 2.2, -0.55, 3.3))
	arch_ring(c, ea, eb, th, hz, 2.2, 0.0, 3.3, 6.0)
	# --- chancel
	var chx := 8.8
	var chz := 2.15
	var cth := 0.7
	ruin_wall(c, Vector2(hx, chz), Vector2(chx, chz), y0, [Vector2(1.0, 4.5), Vector2(2.0, 3.4), Vector2(3.8, 4.2)], cth, arch_holes(2.4, 0.6, 1.8, 3.2))
	var ce_p: Array = [Vector2(1.0, 4.2), Vector2(1.7, 5.0), Vector2(2.6, 5.8), Vector2(3.3, 5.0), Vector2(4.3, 4.0)]
	ruin_wall(c, Vector2(chx, chz), Vector2(chx, -chz), y0, ce_p, cth, arch_holes(chz, 1.1, 1.6, 3.8))
	arch_ring(c, Vector2(chx, chz), Vector2(chx, -chz), cth, chz, 1.1, 1.6, 3.8, 5.8)
	ruin_wall(c, Vector2(chx, -chz), Vector2(hx, -chz), y0, [Vector2(1.5, 3.0), Vector2(2.4, 1.2), Vector2(3.8, 2.4)], cth)
	# --- flagged floor: nave and chancel, some stones missing or heaved
	for fx in range(-4, 5):
		for fz in range(-2, 3):
			if r.randf() < 0.22:
				continue
			c.mb.box(c.m.stone_b, Vector3(fx * 0.95 + r.randf_range(-0.04, 0.04), 0.03 + r.randf_range(0.0, 0.05), fz * 0.95 + r.randf_range(-0.04, 0.04)), Vector3(0.9, 0.12, 0.9), Basis(Vector3.UP, r.randf_range(-0.05, 0.05)), 0.02)
	for fx in range(0, 4):
		for fz in range(-1, 2):
			if r.randf() < 0.2:
				continue
			c.mb.box(c.m.stone_b, Vector3(5.85 + fx * 0.95, 0.06, fz * 0.95), Vector3(0.9, 0.14, 0.9), Basis(Vector3.UP, r.randf_range(-0.05, 0.05)), 0.02)
	# altar block with a cracked top slab
	c.mb.box(c.m.stone_q, Vector3(8.0, 0.45, 0), Vector3(0.9, 0.9, 1.7), Basis(), 0.02)
	c.mb.box(c.m.stone_q, Vector3(8.0, 0.97, 0.35), Vector3(1.05, 0.14, 1.0), Basis(Vector3.UP, 0.04), 0.02)
	c.mb.box(c.m.stone_q, Vector3(8.05, 0.99, -0.5), Vector3(1.0, 0.1, 0.62), Basis(Vector3(0, 0, 1), 0.22), 0.02)
	c.col(Vector3(8.0, 0.5, 0), Vector3(0.9, 1.0, 1.7))
	# --- fallen roof timbers and rubble
	for i in 6:
		var p0 := Vector3(r.randf_range(-3.8, 4.0), r.randf_range(0.2, 1.2), r.randf_range(-2.0, 2.0))
		var d := Vector3(r.randf_range(-1.0, 1.0), 0.0, r.randf_range(-1.0, 1.0)).normalized()
		var p1 := p0 + d * r.randf_range(2.2, 4.2) + Vector3(0, r.randf_range(-0.7, 0.2), 0)
		p1.y = maxf(p1.y, 0.25)
		BK.beam(c, mats.oak_grey if i % 2 == 0 else mats.charred, p0, p1, 0.26, 0.3, 0.02)
		c.col((p0 + p1) * 0.5, Vector3(p0.distance_to(p1), 0.3, 0.3), Kit.basis_x(p1 - p0))
	for i in 16:
		var side := 1.0 if r.randf() < 0.5 else -1.0
		var px := r.randf_range(-4.6, 9.0)
		var inside := r.randf() < 0.45
		var pz := side * (r.randf_range(0.8, 2.0) if inside else r.randf_range(3.5, 4.6))
		var rr := r.randf_range(0.28, 0.75)
		c.mb.blob(c.stone(), Vector3(px, rr * 0.25, pz), Vector3(rr * 1.4, rr * 0.7, rr), r.randi() % 997, 0.3, 1.5, 6, 10, Basis(Vector3.UP, r.randf() * TAU), true, 0.7)
		c.col(Vector3(px, rr * 0.25, pz), Vector3(rr * 1.6, rr * 1.0, rr * 1.4))
	# --- west cross, graves
	c.mb.box(c.m.stone_q, Vector3(-8.2, 0.12, 1.4), Vector3(1.0, 0.25, 1.0), Basis(), 0.02)
	c.mb.box(c.m.stone_q, Vector3(-8.2, 0.37, 1.4), Vector3(0.7, 0.25, 0.7), Basis(), 0.02)
	c.mb.box(c.m.stone_q, Vector3(-8.2, 1.4, 1.4), Vector3(0.3, 2.0, 0.3), Basis(Vector3(0, 0, 1), 0.03), 0.015)
	c.mb.box(c.m.stone_q, Vector3(-8.2, 2.05, 1.4), Vector3(0.28, 0.3, 1.0), Basis(), 0.015)
	c.col(Vector3(-8.2, 1.1, 1.4), Vector3(0.9, 2.2, 0.9))
	for i in 11:
		var gx := -4.0 + i * 1.15 + r.randf_range(-0.2, 0.2)
		_grave(c, Vector3(gx, 0.0, hz + 2.1 + r.randf_range(0.0, 2.4)), PI + r.randf_range(-0.25, 0.25), r.randf_range(0.55, 1.1))
	for i in 4:
		_grave(c, Vector3(-6.5 - i * 0.2, 0.0, -hz - 1.4 - i * 1.2), r.randf_range(-0.3, 0.3), r.randf_range(0.5, 0.9))
	return BK.finish(c, "Chapel")


# ---------------------------------------------------------------- old barrow

## Grassed burial mound (radius 7.6, 3 m high) ringed with kerbstones, a crescent facade of upright
## stones with a sealed trilithon portal on +z, a ring of leaning standing stones and a flat altar slab.
## Origin at the mound's centre on the ground. The dome has its own collision, so it can be climbed.
static func barrow(mats: Dictionary, seed_: int) -> Node3D:
	var c := BK.Ctx.new(seed_, mats)
	var r := c.rng
	var R := 7.6
	var H := 3.0
	var prof := PackedVector2Array()
	for i in 13:
		var f := float(i) / 12.0
		prof.append(Vector2(R * (1.0 - f) + 0.01, -0.3 + (H + 0.3) * (0.5 + 0.5 * cos(PI * (1.0 - f)))))
	prof[prof.size() - 1] = Vector2(0.01, H)
	c.mb.lathe(mats.turf, prof, 28, true)
	# kerbstones round the foot (the forecourt side stays open)
	for i in 26:
		var a := TAU * float(i) / 26.0 + r.randf_range(-0.04, 0.04)
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 1.0:
			continue
		var rr := r.randf_range(0.55, 0.85)
		var kp := Vector3(cos(a) * (R - 0.1), rr * 0.2, sin(a) * (R - 0.1))
		c.mb.blob(mats.stone_a if i % 2 == 0 else mats.stone_c, kp, Vector3(rr * 1.2, rr * 0.8, rr), r.randi() % 997, 0.22, 1.4, 6, 10, Basis(Vector3.UP, -a), true, 0.65)
		c.col(kp + Vector3(0, 0.1, 0), Vector3(rr * 1.3, rr * 1.0, rr * 1.3), Basis(Vector3.UP, -a))
	# facade: upright slabs in a crescent, the portal in the middle
	var fr := 5.7
	for k: int in [-2, -1, 1, 2]:
		var a := PI * 0.5 + k * 0.42
		_menhir(c, Vector3(cos(a) * fr, 0.0, sin(a) * fr), r.randf_range(2.0, 2.9), r.randf_range(0.9, 1.3), -a + PI * 0.5)
	for sx: float in [-1.0, 1.0]:
		_menhir(c, Vector3(sx * 1.1, 0.0, fr), 2.3, 0.7, 0.0)
	c.mb.box(mats.stone_c, Vector3(0, 2.55, fr), Vector3(3.0, 0.6, 0.9), Basis(Vector3(0, 0, 1), 0.015), 0.03)
	c.col(Vector3(0, 2.55, fr), Vector3(3.0, 0.6, 0.9))
	c.mb.box(mats.stone_b, Vector3(0.05, 1.0, fr + 0.05), Vector3(1.6, 2.1, 0.55), Basis(Vector3(1, 0, 0), -0.05), 0.04)
	c.mb.box(mats.dark, Vector3(0, 1.0, fr - 0.45), Vector3(1.5, 2.0, 0.2))
	c.col(Vector3(0, 1.0, fr), Vector3(1.6, 2.1, 0.6))
	# standing stones in a wide ring, one fallen
	for i in 9:
		var a := TAU * float(i) / 9.0 + r.randf_range(-0.08, 0.08)
		var rad := r.randf_range(11.2, 12.4)
		var pos := Vector3(cos(a) * rad, 0.0, sin(a) * rad)
		if i == 4:
			c.mb.blob(mats.stone_b, pos + Vector3(0, 0.45, 0), Vector3(1.7, 0.55, 0.6), 91, 0.12, 1.2, 7, 12, Basis(Vector3.UP, -a + 0.4), true)
			c.col(pos + Vector3(0, 0.5, 0), Vector3(3.2, 1.0, 1.1), Basis(Vector3.UP, -a + 0.4))
		else:
			_menhir(c, pos, r.randf_range(1.9, 3.3), r.randf_range(0.8, 1.2), -a + PI * 0.5)
	# altar slab in the forecourt
	c.mb.box(mats.stone_q, Vector3(0.9, 0.35, 8.6), Vector3(0.5, 0.7, 0.9), Basis(), 0.03)
	c.mb.box(mats.stone_q, Vector3(-0.9, 0.35, 8.6), Vector3(0.5, 0.7, 0.9), Basis(), 0.03)
	c.mb.box(mats.stone_b, Vector3(0, 0.82, 8.6), Vector3(2.9, 0.22, 1.3), Basis(Vector3.UP, 0.05), 0.03)
	c.col(Vector3(0, 0.5, 8.6), Vector3(2.9, 1.0, 1.3))
	var root := BK.finish(c, "Barrow")
	# the mound's own collision: a trimesh of the dome so the slope can be walked
	var dome := BK.Ctx.new(1, mats)
	dome.mb.lathe(mats.turf, prof, 28, true)
	var cs := CollisionShape3D.new()
	cs.name = "Dome"
	cs.shape = dome.mb.build().create_trimesh_shape()
	root.get_node("Collision").add_child(cs)
	return root


## One upright standing stone: a faceted block leaning a little, with its collision.
static func _menhir(c: BK.Ctx, at: Vector3, h: float, w: float, yaw: float) -> void:
	var r := c.rng
	var lean := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, r.randf_range(-0.07, 0.07)) * Basis(Vector3(0, 0, 1), r.randf_range(-0.07, 0.07))
	c.mb.blob(c.stone(), at + Vector3(0, h * 0.45, 0), Vector3(w * 0.55, h * 0.55, w * 0.3), r.randi() % 997, 0.16, 1.3, 7, 10, lean, true)
	c.col(at + Vector3(0, h * 0.45, 0), Vector3(w * 0.9, h * 0.9, w * 0.55), Basis(Vector3.UP, yaw))
