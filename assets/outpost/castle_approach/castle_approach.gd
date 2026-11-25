extends RefCounted
## Castle approach and military checkpoint, CP01-CP20 (see assets/outpost/MANIFEST.md).
## CP01, CP02 and CP19 are the White Knights banner, pennant and shield (WK01, WK03, WK05).
## Everything here says "the Knights control this road": stained oak, charcoal iron, the cross
## stencilled on their stores, red-and-ivory on the barrier.
##
## Origins: standing things on y = 0 at the centre of the base (the road barrier: at its pivot
## post); the lantern at its hanging ring.

const HK := preload("res://assets/hideout/Materials/kit.gd")
const K := preload("res://assets/outpost/materials/outpost_kit.gd")
const BLD := preload("res://assets/outpost/buildings/buildings.gd")

## Where a WK03 pennant goes on the CP03 banner pole.
const POLE_PENNANT := Vector3(0, 4.47, 0)


# ---------------------------------------------------------------- shared parts

static func _beam(b: HK.MB, m: Material, a: Vector3, c: Vector3, t: float, t2 := -1.0) -> void:
	b.box(m, (a + c) * 0.5, Vector3(a.distance_to(c), t, t if t2 < 0.0 else t2), HK.basis_x(c - a), 0.004)


static func _foot_stones(b: HK.MB, r: float, seed_: int) -> void:
	for i in 3:
		var a := TAU * i / 3.0 + 0.7 + seed_
		b.blob(K.limestone(), Vector3(cos(a) * r, 0.03, sin(a) * r), Vector3(0.1, 0.06, 0.08), seed_ * 7 + i, 0.3, 1.5, 4, 6, Basis(), true, 0.5)


## A spear (shaft, leaf-shaped iron head, butt cap) from foot to the tip of the head.
static func _spear(b: HK.MB, foot: Vector3, tip: Vector3) -> void:
	var dir := (tip - foot).normalized()
	var head := tip - dir * 0.3
	b.cyl(K.iron(), foot, foot + dir * 0.06, 0.024, 0.022, 6)
	b.cyl(K.oak(), foot + dir * 0.05, head, 0.021, 0.019, 6)
	b.push(Transform3D(HK.basis_y(dir), head))
	b.lathe(K.iron(), PackedVector2Array([Vector2(0.018, 0.0), Vector2(0.045, 0.1), Vector2(0.03, 0.2), Vector2(0.0005, 0.3)]), 4)
	b.pop()


## A barrel made of flat staves (chunky facets) with iron hoops and a lid; the cross
## stencilled on its front (+Z). Sits on y = 0 at c.
static func _barrel(b: HK.MB, c: Vector3, h: float, r_end: float, r_mid: float, yaw: float, stencil := true) -> void:
	var staves := 14
	var rings := 6
	var rad := func(t: float) -> float: return r_end + (r_mid - r_end) * (1.0 - pow(2.0 * t - 1.0, 2.0))
	b.push(Transform3D(Basis(Vector3.UP, yaw), c))
	for s in staves:
		var a0 := TAU * s / staves
		var a1 := TAU * (s + 1) / staves
		var am := (a0 + a1) * 0.5
		for i in rings:
			var t0 := float(i) / rings
			var t1 := float(i + 1) / rings
			var r0: float = rad.call(t0)
			var r1: float = rad.call(t1)
			var p00 := Vector3(cos(a0) * r0, t0 * h, sin(a0) * r0)
			var p01 := Vector3(cos(a1) * r0, t0 * h, sin(a1) * r0)
			var p10 := Vector3(cos(a0) * r1, t1 * h, sin(a0) * r1)
			var p11 := Vector3(cos(a1) * r1, t1 * h, sin(a1) * r1)
			var out := Vector3(cos(am), 0, sin(am))
			var w := (a1 - a0) * r0
			b.tri(K.oak(), p00, p01, p11, out, Vector2(t0 * h, 0), Vector2(t0 * h, w), Vector2(t1 * h, w))
			b.tri(K.oak(), p00, p11, p10, out, Vector2(t0 * h, 0), Vector2(t1 * h, w), Vector2(t1 * h, 0))
	for t in [0.07, 0.24, 0.76, 0.93]:
		var y: float = t * h
		var r: float = rad.call(t) + 0.008
		b.cyl(K.iron(), Vector3(0, y - 0.022, 0), Vector3(0, y + 0.022, 0), r, r, staves, 0.0, false)
	b.disc(K.oak(), h - 0.025, r_end - 0.01, staves)
	b.disc(K.oak(), 0.0, r_end, staves, false)
	b.cyl(K.oak(), Vector3(0, h - 0.03, 0), Vector3(0, h + 0.005, 0), r_end + 0.002, r_end + 0.002, staves, 0.0, false)
	if stencil:
		# A curved patch on the front, just off the staves.
		var nu := 5
		var nv := 4
		var hs := 0.34 * h
		var span := 0.36 / r_mid
		var pts := PackedVector3Array()
		var uvs := PackedVector2Array()
		for j in nv:
			for i in nu:
				var t := 0.5 + (0.5 - float(j) / (nv - 1)) * hs / h
				var a := PI * 0.5 + (float(i) / (nu - 1) - 0.5) * span
				var r: float = rad.call(t) + 0.006
				pts.append(Vector3(cos(a) * r, t * h, sin(a) * r))
				uvs.append(Vector2(1.0 - float(i) / (nu - 1), float(j) / (nv - 1)))
		K.sheet(b, K.stencil(), pts, uvs, nu, nv, Vector3(0, 0, 1))
	b.pop()


## A plank crate with frame boards and a diagonal brace on each side, the cross stencilled
## on the front and both ends. Sits on y = 0 at c.
static func _crate(b: HK.MB, c: Vector3, size: Vector3, yaw: float, stencil := true) -> void:
	var oak := K.oak()
	var dark := K.oak("weathered")
	var hs := size * 0.5
	var t := 0.035
	b.push(Transform3D(Basis(Vector3.UP, yaw), c))
	b.box(oak, Vector3(0, hs.y, 0), size, Basis(), 0.004)
	# Frame boards round the four sides and a brace across each.
	for side in 4:
		var bas := Basis(Vector3.UP, side * PI * 0.5)
		var w: float = size.x if side % 2 == 0 else size.z
		var d: float = hs.z if side % 2 == 0 else hs.x
		var fz := d + t * 0.5
		for y in [t, size.y - t]:
			b.box(dark, bas * Vector3(0, y, fz), Vector3(w, t * 2.0, t), bas, 0.003)
		for x in [-w * 0.5 + t, w * 0.5 - t]:
			b.box(dark, bas * Vector3(x, hs.y, fz), Vector3(t * 2.0, size.y, t), bas, 0.003)
		var painted := stencil and side != 2
		if not painted:
			var a := bas * Vector3(-w * 0.5 + t * 2.0, t * 2.0, fz)
			var e := bas * Vector3(w * 0.5 - t * 2.0, size.y - t * 2.0, fz)
			b.box(dark, (a + e) * 0.5, Vector3(a.distance_to(e), t * 2.0, t), bas * Basis(Vector3(0, 0, 1), atan2(size.y - t * 4.0, w - t * 4.0)), 0.003)
		else:
			var sz := minf(size.y, w) * 0.62
			var off := 0.004
			var p0 := bas * Vector3(-sz * 0.5, hs.y + sz * 0.5, d + off)
			var p1 := bas * Vector3(sz * 0.5, hs.y + sz * 0.5, d + off)
			var p2 := bas * Vector3(sz * 0.5, hs.y - sz * 0.5, d + off)
			var p3 := bas * Vector3(-sz * 0.5, hs.y - sz * 0.5, d + off)
			K.face(b, K.stencil(), p0, p1, p2, p3, bas * Vector3(0, 0, 1))
	for x in [-hs.x + t, 0.0, hs.x - t]:
		b.box(dark, Vector3(x, size.y + t * 0.5, 0), Vector3(t * 2.0, t, size.z + t * 2.0), Basis(), 0.003)
	b.pop()


# ---------------------------------------------------------------- CP03-CP05: poles and fire

## CP03: banner pole, 4.7 m: an oak pole with an iron foot, a gold finial and two iron rings
## for a WK03 pennant (at POLE_PENNANT). Stands on its own.
static func banner_pole() -> Node3D:
	var b := HK.MB.new(203)
	var top := 4.6
	b.cyl(K.iron(), Vector3.ZERO, Vector3(0, 0.3, 0), 0.06, 0.052, 8)
	b.cyl(K.oak(), Vector3(0, 0.28, 0), Vector3(0, top, 0), 0.05, 0.04, 8, 0.02, true, 3)
	K.knob(b, K.gold(), Vector3(0, top + 0.04, 0), 0.06)
	b.push(Transform3D(Basis(), Vector3(0, top + 0.08, 0)))
	b.lathe(K.gold(), PackedVector2Array([Vector2(0.02, 0.0), Vector2(0.04, 0.07), Vector2(0.0005, 0.26)]), 4)
	b.pop()
	_foot_stones(b, 0.16, 3)
	return K.asset("CP03_banner_pole", b, [["cyl", Vector3(0, top * 0.5, 0), 0.08, top]])


## CP04: stone torch holder: a limestone pillar with the cross carved on its face, an iron
## cup and prongs on top, a burning torch. 1.75 m. Lights the road at the checkpoint.
static func stone_torch_holder() -> Node3D:
	var b := HK.MB.new(204)
	var s := K.limestone()
	b.box(s, Vector3(0, 0.1, 0), Vector3(0.52, 0.2, 0.52), Basis(), 0.012)
	b.box(s, Vector3(0, 0.75, 0), Vector3(0.34, 1.1, 0.34), Basis(), 0.01)
	b.box(s, Vector3(0, 1.36, 0), Vector3(0.46, 0.12, 0.46), Basis(), 0.008)
	K.extrude(b, K.red_stone(), s, K.cross_poly(0.1, Vector2(0, 0.95)), 0.17, 0.018, Rect2(-0.1, 0.85, 0.2, 0.2))
	b.push(Transform3D(Basis(), Vector3(0, 1.42, 0)))
	b.lathe(K.iron(), PackedVector2Array([Vector2(0.04, 0.0), Vector2(0.09, 0.03), Vector2(0.15, 0.14), Vector2(0.135, 0.15), Vector2(0.0005, 0.05)]), 10)
	for i in 4:
		var a := TAU * i / 4.0 + PI * 0.25
		b.cyl(K.iron(), Vector3(cos(a) * 0.13, 0.12, sin(a) * 0.13), Vector3(cos(a) * 0.17, 0.32, sin(a) * 0.17), 0.012, 0.008, 5)
	b.cyl(K.oak("weathered"), Vector3(0, 0.04, 0), Vector3(0, 0.3, 0), 0.045, 0.05, 7)
	b.blob(HK.ember(), Vector3(0, 0.3, 0), Vector3(0.07, 0.05, 0.07), 4, 0.3, 2.0, 3, 6)
	b.pop()
	var root := K.asset("CP04_stone_torch_holder", b, [["box", Vector3(0, 0.75, 0), Vector3(0.5, 1.5, 0.5)]])
	HK.fire_fx(root, Vector3(0, 1.78, 0), 0.5, 2.4, false)
	return root


## CP05: standing iron brazier: three legs, a deep bowl and an iron cage, full of coals and
## fire. 1.3 m. The main warm light at the checkpoint (casts shadows).
static func iron_brazier() -> Node3D:
	var b := HK.MB.new(205)
	var ir := K.iron()
	for i in 3:
		var a := TAU * i / 3.0 + 0.4
		b.cyl(ir, Vector3(cos(a) * 0.36, 0, sin(a) * 0.36), Vector3(cos(a) * 0.2, 0.78, sin(a) * 0.2), 0.026, 0.03, 6)
		K.knob(b, ir, Vector3(cos(a) * 0.36, 0.02, sin(a) * 0.36), 0.04, 6)
	K.ring(b, ir, Vector3(0, 0.32, 0), Vector3.UP, 0.28, 0.014, 12)
	b.push(Transform3D(Basis(), Vector3(0, 0.72, 0)))
	b.lathe(ir, PackedVector2Array([Vector2(0.0005, 0.0), Vector2(0.16, 0.0), Vector2(0.3, 0.1), Vector2(0.37, 0.26), Vector2(0.385, 0.3), Vector2(0.36, 0.3), Vector2(0.0005, 0.08)]), 14)
	for i in 10:
		var a := TAU * i / 10.0
		b.cyl(ir, Vector3(cos(a) * 0.37, 0.28, sin(a) * 0.37), Vector3(cos(a) * 0.43, 0.6, sin(a) * 0.43), 0.012, 0.012, 5)
	K.ring(b, ir, Vector3(0, 0.6, 0), Vector3.UP, 0.43, 0.016, 14)
	for i in 12:
		var a := b.rng.randf() * TAU
		var r := b.rng.randf() * 0.26
		b.blob(HK.ember() if i % 3 else HK.plain(Color(0.06, 0.05, 0.05), 0.6), Vector3(cos(a) * r, 0.24 + b.rng.randf() * 0.06, sin(a) * r),
			Vector3(0.07, 0.05, 0.06), i, 0.3, 2.0, 3, 6)
	b.pop()
	var root := K.asset("CP05_standing_iron_brazier", b, [["cyl", Vector3(0, 0.66, 0), 0.42, 1.32]])
	HK.fire_fx(root, Vector3(0, 1.08, 0), 0.9, 3.4, true)
	return root


# ---------------------------------------------------------------- CP06-CP07: closing the road

## CP06: wooden road barrier: a red-and-ivory boom on a pivot post with a stone counterweight,
## resting in a forked post. The origin is the pivot post's foot; the boom runs 5.4 m along +X,
## so two face to face close a 12 m road.
static func road_barrier() -> Node3D:
	var b := HK.MB.new(206)
	var oak := K.oak()
	var y := 1.08
	b.box(K.limestone(), Vector3(0, 0.12, 0), Vector3(0.56, 0.24, 0.56), Basis(), 0.012)
	b.box(oak, Vector3(0, 0.7, 0), Vector3(0.24, 0.98, 0.24), Basis(), 0.008)
	for s in [-1.0, 1.0]:
		b.box(oak, Vector3(0, y + 0.1, s * 0.13), Vector3(0.2, 0.42, 0.06), Basis(), 0.004)
	b.cyl(K.iron(), Vector3(0, y, -0.2), Vector3(0, y, 0.2), 0.025, 0.025, 6)
	K.knob(b, K.gold(), Vector3(0, y + 0.34, 0.13), 0.035, 6)
	K.knob(b, K.gold(), Vector3(0, y + 0.34, -0.13), 0.035, 6)
	# The boom: painted bands (the stripes texture runs along it), an iron tip.
	b.box(K.stripes(), Vector3(2.2, y, 0), Vector3(6.4, 0.14, 0.14), Basis(), 0.004)
	b.box(K.iron(), Vector3(5.42, y, 0), Vector3(0.05, 0.17, 0.17))
	# Counterweight: a limestone block strapped under the short end.
	b.box(K.limestone(), Vector3(-0.72, y - 0.2, 0), Vector3(0.38, 0.32, 0.3), Basis(), 0.012)
	for x in [-0.82, -0.62]:
		b.box(K.iron(), Vector3(x, y - 0.12, 0), Vector3(0.04, 0.5, 0.33))
	# The forked rest post.
	var fx := 5.1
	b.box(oak, Vector3(fx, 0.45, 0), Vector3(0.16, 0.9, 0.16), Basis(), 0.006)
	for s in [-1.0, 1.0]:
		_beam(b, oak, Vector3(fx, 0.85, 0), Vector3(fx, y + 0.06, s * 0.15), 0.07)
	b.box(K.limestone(), Vector3(fx, 0.06, 0), Vector3(0.34, 0.12, 0.34), Basis(), 0.01)
	return K.asset("CP06_wooden_road_barrier", b, [
		["box", Vector3(0, 0.6, 0), Vector3(0.56, 1.2, 0.56)],
		["box", Vector3(2.2, y, 0), Vector3(6.4, 0.18, 0.18)],
		["box", Vector3(fx, 0.55, 0), Vector3(0.34, 1.1, 0.34)]])


## CP07: movable timber barricade: a log with crossed sharpened stakes (a "cheval de frise"),
## 3 m long, 1.25 m high. Blocks a lane or a gap; two men can drag it.
static func timber_barricade() -> Node3D:
	var b := HK.MB.new(207)
	var log_m := K.oak("weathered")
	b.cyl(log_m, Vector3(-1.5, 0.6, 0), Vector3(1.5, 0.6, 0), 0.12, 0.11, 9, 0.05, true, 3)
	for i in 5:
		var x := lerpf(-1.25, 1.25, i / 4.0)
		for s in [-1.0, 1.0]:
			var a := Vector3(x, 0.0, -s * 0.72)
			var tip := Vector3(x + 0.04 * s, 1.25, s * 0.72)
			var dir := (tip - a).normalized()
			var p := tip - dir * 0.28
			b.cyl(K.oak(), a, p, 0.05, 0.048, 6, 0.04)
			b.cyl(K.oak(), p, tip, 0.048, 0.004, 6)
		K.ring(b, K.rope(), Vector3(x, 0.6, 0), Vector3(1, 0, 0), 0.14, 0.016, 8)
	return K.asset("CP07_movable_timber_barricade", b, [["box", Vector3(0, 0.62, 0), Vector3(3.0, 1.24, 1.4)]])


# ---------------------------------------------------------------- CP08: the guard shelter

## CP08: guard inspection shelter: an open-fronted timber booth on stone footings, plank floor,
## waist-high plank walls on three sides, a shingled hip roof with a pennant on top, a shield on
## the front post and a seat inside. A building, so built at the buildings' SIZE (x1.3): about
## 3.4 x 2.9 m, eaves at 3.6 m. Front faces +Z.
static func guard_shelter() -> Node3D:
	var b := HK.MB.new(208)
	var oak := K.oak()
	var hx := 1.3
	var hz := 1.1
	var eave := 2.75
	for x in [-hx, hx]:
		for z in [-hz, hz]:
			b.box(K.limestone(), Vector3(x, 0.09, z), Vector3(0.32, 0.22, 0.32), Basis(), 0.01)
			b.box(oak, Vector3(x, (0.2 + eave) * 0.5, z), Vector3(0.16, eave - 0.2, 0.16), Basis(), 0.006)
	# Plank floor almost at ground level, so the player walks straight in (no step-up in the game).
	b.box(oak, Vector3(0, 0.03, 0), Vector3(hx * 2.0 - 0.1, 0.06, hz * 2.0 - 0.1), Basis(), 0.004)
	for z in [-hz, hz]:
		b.box(oak, Vector3(0, eave, z), Vector3(hx * 2.0 + 0.2, 0.16, 0.16), Basis(), 0.006)
	for x in [-hx, hx]:
		b.box(oak, Vector3(x, eave, 0), Vector3(0.16, 0.16, hz * 2.0), Basis(), 0.006)
	# Half walls: back and both sides (vertical boards on a rail).
	var wall := K.oak("weathered")
	b.box(wall, Vector3(0, 0.6, -hz), Vector3(hx * 2.0, 1.1, 0.05), Basis(), 0.004)
	for x in [-hx, hx]:
		b.box(wall, Vector3(x, 0.6, 0), Vector3(0.05, 1.1, hz * 2.0), Basis(), 0.004)
		b.box(oak, Vector3(x, 1.18, 0), Vector3(0.1, 0.06, hz * 2.0 + 0.1), Basis(), 0.004)
	b.box(oak, Vector3(0, 1.18, -hz), Vector3(hx * 2.0 + 0.1, 0.06, 0.1), Basis(), 0.004)
	# A seat along the back.
	# (Drawn low: the shelter is scaled x1.3, which puts the seat at a normal 0.47 m.)
	b.box(oak, Vector3(0, 0.36, -hz + 0.25), Vector3(hx * 1.7, 0.05, 0.3), Basis(), 0.004)
	for x in [-hx * 0.7, hx * 0.7]:
		b.box(oak, Vector3(x, 0.18, -hz + 0.25), Vector3(0.06, 0.33, 0.24), Basis(), 0.004)
	# The roof: four shingled slopes to an apex, oak underneath, hip boards and a fascia.
	var ov := 0.45
	var ey := eave + 0.02
	var corners := [Vector3(-hx - ov, ey - 0.12, hz + ov), Vector3(hx + ov, ey - 0.12, hz + ov), Vector3(hx + ov, ey - 0.12, -hz - ov), Vector3(-hx - ov, ey - 0.12, -hz - ov)]
	var apex := Vector3(0, eave + 1.05, 0)
	for i in 4:
		var e0: Vector3 = corners[i]
		var e1: Vector3 = corners[(i + 1) % 4]
		var mid := (e0 + e1) * 0.5
		var out := (mid - Vector3(0, mid.y, 0)).normalized() + Vector3(0, 1.4, 0)
		var edge := e0.distance_to(e1)
		var slope := Vector2(Vector2(mid.x, mid.z).length(), apex.y - mid.y).length()
		b.tri(K.shingles(), e0, e1, apex, out, Vector2(0, slope), Vector2(edge, slope), Vector2(edge * 0.5, 0))
		var dn := Vector3(0, -0.06, 0)
		b.tri(oak, e0 + dn, e1 + dn, apex + dn, -out, Vector2(0, slope), Vector2(edge, slope), Vector2(edge * 0.5, 0))
		_beam(b, oak, e0 + Vector3(0, -0.04, 0), e1 + Vector3(0, -0.04, 0), 0.1, 0.05)
		_beam(b, oak, e0 + Vector3(0, 0.03, 0), apex + Vector3(0, 0.03, 0), 0.09)
	K.knob(b, K.gold(), apex + Vector3(0, 0.07, 0), 0.07)
	# A pennant pole on the apex.
	var pole_top := apex + Vector3(0, 1.1, 0)
	b.cyl(oak, apex, pole_top, 0.035, 0.028, 6)
	K.knob(b, K.gold(), pole_top + Vector3(0, 0.03, 0), 0.04, 6)
	b.push(Transform3D(Basis(Vector3.UP, 0.5), pole_top + Vector3(0.0, -0.06, 0)))
	K.pennant(b, K.pennant_cloth(), 0.9, 0.36, 5)
	b.pop()
	# The Knights' shield on the front-left post.
	b.push(Transform3D(Basis(), Vector3(-hx, 1.75, hz + 0.08)))
	K.heater(b, 0.42, 0.54, 0.03, 0.025)
	b.pop()
	var cols := [["box", Vector3(0, 0.03, 0), Vector3(hx * 2.0 - 0.1, 0.06, hz * 2.0 - 0.1)],
		["box", Vector3(0, 0.6, -hz), Vector3(hx * 2.0, 1.2, 0.08)],
		["box", Vector3(-hx, 0.6, 0), Vector3(0.08, 1.2, hz * 2.0)],
		["box", Vector3(hx, 0.6, 0), Vector3(0.08, 1.2, hz * 2.0)]]
	for x in [-hx, hx]:
		cols.append(["box", Vector3(x, eave * 0.5, hz), Vector3(0.18, eave, 0.18)])
	return K.asset("CP08_guard_inspection_shelter", b, cols, BLD.SIZE)


# ---------------------------------------------------------------- CP09-CP13: furniture

## A trestle table: top at height y, legs in A-frames at the ends.
static func _trestle(b: HK.MB, length: float, depth: float, y: float) -> void:
	var oak := K.oak()
	b.box(oak, Vector3(0, y - 0.04, 0), Vector3(length, 0.08, depth), Basis(), 0.006)
	for x in [-length * 0.37, length * 0.37]:
		for s in [-1.0, 1.0]:
			_beam(b, oak, Vector3(x, 0.0, s * depth * 0.42), Vector3(x, y - 0.08, s * depth * 0.12), 0.07)
		b.box(oak, Vector3(x, 0.03, 0), Vector3(0.08, 0.06, depth * 0.95), Basis(), 0.004)
		b.box(oak, Vector3(x, y - 0.12, 0), Vector3(0.08, 0.07, depth * 0.85), Basis(), 0.004)
	b.box(oak, Vector3(0, y * 0.4, 0), Vector3(length * 0.74, 0.07, 0.07), Basis(), 0.004)


## CP09: toll and inspection table: a trestle table with an open ledger, an inkwell and quill,
## a coin box, stacks of coins, a sealed notice, and an emblem cloth hung on the front.
## 1.9 x 0.85 m, top at 0.82 m. The clerk stands behind (-Z); travellers come to the front (+Z).
static func toll_table() -> Node3D:
	var b := HK.MB.new(209)
	var y := 0.82
	_trestle(b, 1.9, 0.85, y)
	# The front cloth.
	b.push(Transform3D(Basis(), Vector3(0, y, 0.43)))
	K.banner(b, K.banner_cloth(), 0.8, 0.55, "point", 9, 2.0, 9, 6)
	b.pop()
	# Ledger: a leather cover and two open pages, slightly raised in the middle.
	var lc := Vector3(-0.25, y + 0.015, -0.05)
	b.box(K.leather(), lc, Vector3(0.62, 0.03, 0.44), Basis(Vector3.UP, 0.08))
	for s in [-1.0, 1.0]:
		var bas := Basis(Vector3.UP, 0.08) * Basis(Vector3(0, 0, 1), -s * 0.06)
		var c := lc + Basis(Vector3.UP, 0.08) * Vector3(s * 0.15, 0.03, 0)
		var a0 := c + bas * Vector3(-0.14, 0, -0.2)
		var a1 := c + bas * Vector3(0.14, 0, -0.2)
		var a2 := c + bas * Vector3(0.14, 0, 0.2)
		var a3 := c + bas * Vector3(-0.14, 0, 0.2)
		K.face(b, K.parchment(), a0, a1, a2, a3, Vector3.UP)
	# Inkwell and quill.
	b.push(Transform3D(Basis(), Vector3(0.18, y, -0.18)))
	b.lathe(K.iron(), PackedVector2Array([Vector2(0.0005, 0.0), Vector2(0.04, 0.0), Vector2(0.045, 0.03), Vector2(0.025, 0.06), Vector2(0.0005, 0.06)]), 8)
	b.pop()
	b.cyl(HK.plain(Color(0.78, 0.74, 0.66), 1.0), Vector3(0.18, y + 0.05, -0.18), Vector3(0.24, y + 0.26, -0.1), 0.005, 0.012, 4)
	# Coin box and coins.
	var cb := Vector3(0.52, y, -0.12)
	b.box(K.oak(), cb + Vector3(0, 0.08, 0), Vector3(0.34, 0.16, 0.24), Basis(Vector3.UP, -0.2), 0.004)
	b.box(K.iron(), cb + Vector3(0, 0.08, 0), Vector3(0.36, 0.04, 0.26), Basis(Vector3.UP, -0.2))
	b.box(K.oak(), cb + Vector3(0, 0.17, 0), Vector3(0.36, 0.03, 0.26), Basis(Vector3.UP, -0.2), 0.003)
	for i in 4:
		var p := Vector3(0.18 + i * 0.07, y, 0.12 + (i % 2) * 0.06)
		var n := 2 + (i * 3) % 5
		b.cyl(K.gold(), p, p + Vector3(0, 0.006 * n, 0), 0.016, 0.016, 8)
	# A sealed notice lying on the table.
	var nc := Vector3(-0.6, y + 0.003, 0.18)
	var nb := Basis(Vector3.UP, -0.3)
	K.face(b, K.parchment(), nc + nb * Vector3(-0.12, 0, -0.16), nc + nb * Vector3(0.12, 0, -0.16), nc + nb * Vector3(0.12, 0, 0.16), nc + nb * Vector3(-0.12, 0, 0.16), Vector3.UP)
	return K.asset("CP09_toll_inspection_table", b, [["box", Vector3(0, y * 0.5, 0), Vector3(1.9, y, 0.85)]])


## CP10: guard bench: a heavy plank on splayed legs, 1.8 m.
static func guard_bench() -> Node3D:
	var b := HK.MB.new(210)
	var oak := K.oak()
	b.box(oak, Vector3(0, 0.44, 0), Vector3(1.8, 0.07, 0.36), Basis(), 0.006)
	for x in [-0.66, 0.66]:
		for s in [-1.0, 1.0]:
			_beam(b, oak, Vector3(x + s * 0.06, 0.0, s * 0.16), Vector3(x, 0.41, s * 0.06), 0.06)
	b.box(oak, Vector3(0, 0.18, 0), Vector3(1.3, 0.06, 0.06), Basis(), 0.004)
	return K.asset("CP10_guard_bench", b, [["box", Vector3(0, 0.24, 0), Vector3(1.8, 0.48, 0.38)]])


## CP11: spear rack: a timber frame holding five spears upright (one slot empty), 1.8 m wide.
static func spear_rack() -> Node3D:
	var b := HK.MB.new(211)
	var oak := K.oak()
	b.box(oak, Vector3(0, 0.04, 0), Vector3(1.8, 0.08, 0.5), Basis(), 0.006)
	for x in [-0.86, 0.86]:
		b.box(oak, Vector3(x, 0.7, -0.1), Vector3(0.1, 1.3, 0.1), Basis(), 0.006)
		_beam(b, oak, Vector3(x, 0.08, 0.2), Vector3(x, 0.7, -0.08), 0.07)
	b.box(oak, Vector3(0, 1.3, -0.1), Vector3(1.86, 0.09, 0.12), Basis(), 0.006)
	b.box(oak, Vector3(0, 0.3, 0.02), Vector3(1.76, 0.08, 0.14), Basis(), 0.006)
	for i in 6:
		if i == 4:
			continue
		var x := lerpf(-0.7, 0.7, i / 5.0)
		_spear(b, Vector3(x, 0.08, 0.06), Vector3(x + 0.02, 2.75, -0.16))
	return K.asset("CP11_spear_rack", b, [["box", Vector3(0, 0.65, -0.02), Vector3(1.86, 1.3, 0.5)]])


## CP12: weapon storage chest: iron-bound oak with the emblem painted on the front, a lock
## plate and side handles. 1.2 x 0.6 x 0.65 m.
static func weapon_chest() -> Node3D:
	var b := HK.MB.new(212)
	var oak := K.oak()
	var ir := K.iron()
	for x in [-0.52, 0.52]:
		for z in [-0.24, 0.24]:
			b.box(oak, Vector3(x, 0.03, z), Vector3(0.12, 0.06, 0.12), Basis(), 0.004)
	b.box(oak, Vector3(0, 0.32, 0), Vector3(1.2, 0.52, 0.6), Basis(), 0.006)
	b.box(oak, Vector3(0, 0.63, 0), Vector3(1.24, 0.1, 0.64), Basis(), 0.006)
	for x in [-0.42, 0.42]:
		b.box(ir, Vector3(x, 0.34, 0), Vector3(0.06, 0.66, 0.64))
	for y in [0.1, 0.55]:
		b.box(ir, Vector3(0, y, 0), Vector3(1.22, 0.04, 0.62))
	# Painted emblem on the front, between the bands.
	var c := Vector3(0, 0.34, 0.302)
	K.face(b, K.emblem_paint(), c + Vector3(-0.2, 0.18, 0), c + Vector3(0.2, 0.18, 0), c + Vector3(0.2, -0.18, 0), c + Vector3(-0.2, -0.18, 0), Vector3(0, 0, 1))
	# Lock and hasp under the lid, handles on the ends.
	b.box(ir, Vector3(0, 0.52, 0.31), Vector3(0.12, 0.1, 0.02))
	K.ring(b, ir, Vector3(0, 0.46, 0.325), Vector3(0, 0, 1), 0.025, 0.007, 6)
	for x in [-0.61, 0.61]:
		K.ring(b, ir, Vector3(x, 0.42, 0), Vector3(1, 0, 0), 0.06, 0.01, 8)
	return K.asset("CP12_weapon_storage_chest", b, [["box", Vector3(0, 0.34, 0), Vector3(1.24, 0.68, 0.64)]])


## CP13: wooden shield display: two posts and rails with three Knights' shields, under a
## small shingled pent roof. 2.4 m wide, 2.2 m tall. Front faces +Z.
static func shield_display() -> Node3D:
	var b := HK.MB.new(213)
	var oak := K.oak()
	for x in [-1.1, 1.1]:
		b.box(K.limestone(), Vector3(x, 0.07, 0), Vector3(0.26, 0.14, 0.26), Basis(), 0.008)
		b.box(oak, Vector3(x, 1.05, 0), Vector3(0.13, 2.0, 0.13), Basis(), 0.006)
	for y in [0.85, 1.75]:
		b.box(oak, Vector3(0, y, 0.0), Vector3(2.36, 0.1, 0.08), Basis(), 0.006)
	# Pent roof.
	var y0 := 2.05
	var a := Vector3(-1.35, y0 + 0.25, -0.25)
	var c := Vector3(1.35, y0 + 0.25, -0.25)
	var d := Vector3(1.35, y0 - 0.05, 0.45)
	var e := Vector3(-1.35, y0 - 0.05, 0.45)
	var n := Vector3(0, 1, 0.43)
	b.quad(K.shingles(), a, c, d, e, n)
	b.quad(oak, a + Vector3(0, -0.04, 0), c + Vector3(0, -0.04, 0), d + Vector3(0, -0.04, 0), e + Vector3(0, -0.04, 0), -n)
	b.box(oak, Vector3(0, y0 + 0.1, 0), Vector3(2.5, 0.1, 0.1), Basis(), 0.004)
	for x in [-1.1, 1.1]:
		_beam(b, oak, Vector3(x, y0 + 0.1, 0), Vector3(x, y0 + 0.2, -0.22), 0.06)
	# Three shields on pegs.
	for i in 3:
		var x := (i - 1) * 0.72
		b.cyl(oak, Vector3(x, 1.68, 0.03), Vector3(x, 1.68, 0.1), 0.02, 0.02, 5)
		b.push(Transform3D(Basis(Vector3(0, 0, 1), (i - 1) * 0.05), Vector3(x, 1.3, 0.05)))
		K.heater(b, 0.56, 0.72, 0.035, 0.03)
		b.pop()
	return K.asset("CP13_wooden_shield_display", b, [["box", Vector3(0, 1.05, 0.02), Vector3(2.4, 2.1, 0.24)]])


# ---------------------------------------------------------------- CP14-CP16: stores

## CP14: supply barrels: three oak barrels with iron hoops, two stencilled with the cross.
static func supply_barrels() -> Node3D:
	var b := HK.MB.new(214)
	_barrel(b, Vector3(-0.34, 0, -0.12), 0.92, 0.3, 0.37, 0.3)
	_barrel(b, Vector3(0.38, 0, -0.18), 0.92, 0.3, 0.37, -0.5, false)
	_barrel(b, Vector3(0.02, 0, 0.5), 0.7, 0.24, 0.29, 0.1)
	return K.asset("CP14_supply_barrels", b, [
		["cyl", Vector3(-0.34, 0.46, -0.12), 0.37, 0.92],
		["cyl", Vector3(0.38, 0.46, -0.18), 0.37, 0.92],
		["cyl", Vector3(0.02, 0.35, 0.5), 0.29, 0.7]])


## CP15: supply crates: two large crates and a small one on top, stencilled with the cross.
static func supply_crates() -> Node3D:
	var b := HK.MB.new(215)
	_crate(b, Vector3(-0.44, 0, 0), Vector3(0.8, 0.62, 0.62), 0.05)
	_crate(b, Vector3(0.45, 0, 0.06), Vector3(0.8, 0.62, 0.62), -0.12)
	_crate(b, Vector3(-0.1, 0.665, 0.02), Vector3(0.56, 0.42, 0.44), 0.3)
	return K.asset("CP15_supply_crates", b, [
		["box", Vector3(-0.44, 0.33, 0), Vector3(0.86, 0.66, 0.68), Basis(Vector3.UP, 0.05)],
		["box", Vector3(0.45, 0.33, 0.06), Vector3(0.86, 0.66, 0.68), Basis(Vector3.UP, -0.12)],
		["box", Vector3(-0.1, 0.9, 0.02), Vector3(0.6, 0.46, 0.48), Basis(Vector3.UP, 0.3)]])


## CP16: rope and chain bundles: two coils of rope and a heap of iron chain with a loose end.
## About 1.2 x 0.9 m on the ground. No collision.
static func rope_chain_bundles() -> Node3D:
	var b := HK.MB.new(216)
	for k in 5:
		K.ring(b, K.rope(), Vector3(-0.35, 0.025 + k * 0.038, -0.1), Vector3.UP, 0.24 - k * 0.012, 0.022, 12, 4)
	b.push(Transform3D(Basis(Vector3(1, 0, 0), -1.1), Vector3(0.1, 0.18, -0.32)))
	for k in 4:
		K.ring(b, K.rope(), Vector3(0, k * 0.036, 0), Vector3.UP, 0.16, 0.02, 10, 4)
	b.pop()
	# Chain: links laid in a loose spiral heap, alternating flat and upright, then a tail.
	var pts: Array[Vector3] = []
	for i in 22:
		var a := i * 0.75
		var r := 0.05 + i * 0.008
		pts.append(Vector3(0.32 + cos(a) * r, 0.02 + (22 - i) * 0.004, 0.25 + sin(a) * r))
	for i in 8:
		pts.append(pts[21] + Vector3(0.07 * (i + 1), 0.0, 0.025 * (i + 1)) - Vector3(0, pts[21].y - 0.018, 0))
	for i in pts.size():
		var nxt: Vector3 = pts[mini(i + 1, pts.size() - 1)]
		var prv: Vector3 = pts[maxi(i - 1, 0)]
		var dir := (nxt - prv).normalized()
		var side := dir.cross(Vector3.UP).normalized()
		var axis := Vector3.UP if i % 2 == 0 else side
		K.ring(b, K.iron(), pts[i], axis, 0.032, 0.008, 6, 3)
	return K.asset("CP16_rope_and_chain_bundles", b, [])


# ---------------------------------------------------------------- CP17-CP18, CP20

## CP17: iron lantern: a four-sided iron frame with warm horn panes, a candle and a soft
## flickering light. 0.5 m. Hangs from its ring (origin): hooks, brackets, shelter eaves.
static func iron_lantern() -> Node3D:
	var b := HK.MB.new(217)
	var ir := K.iron()
	K.ring(b, ir, Vector3(0, -0.035, 0), Vector3(0, 0, 1), 0.03, 0.007, 8)
	b.push(Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3(0, -0.22, 0)))
	b.lathe(ir, PackedVector2Array([Vector2(0.15, 0.0), Vector2(0.15, 0.02), Vector2(0.0005, 0.15)]), 4)
	b.pop()
	var hw := 0.095
	for i in 4:
		var a := TAU * i / 4.0 + PI * 0.25
		var p := Vector3(cos(a), 0, sin(a)) * hw * sqrt(2.0)
		b.cyl(ir, p + Vector3(0, -0.5, 0), p + Vector3(0, -0.22, 0), 0.009, 0.009, 4)
	for i in 4:
		var bas := Basis(Vector3.UP, i * PI * 0.5)
		K.face(b, K.lantern_glow(), bas * Vector3(-hw, -0.23, hw), bas * Vector3(hw, -0.23, hw), bas * Vector3(hw, -0.49, hw), bas * Vector3(-hw, -0.49, hw), bas * Vector3(0, 0, 1))
		b.box(ir, bas * Vector3(0, -0.36, hw + 0.003), Vector3(0.012, 0.26, 0.008), bas)
	b.box(ir, Vector3(0, -0.515, 0), Vector3(0.24, 0.03, 0.24))
	b.cyl(HK.plain(Color(0.85, 0.8, 0.68), 0.7), Vector3(0, -0.5, 0), Vector3(0, -0.4, 0), 0.02, 0.02, 6)
	var root := K.asset("CP17_iron_lantern", b, [])
	K.flicker_light(root, Vector3(0, -0.36, 0), 1.3, 7.0)
	return root


## CP18: warning sign: a Knights' board on a post, the cross over three lines of ivory
## lettering on dark planks, a red rag tied below. 2.3 m. Front faces +Z.
static func warning_sign() -> Node3D:
	var b := HK.MB.new(218)
	var oak := K.oak()
	b.box(oak, Vector3(0, 1.1, 0), Vector3(0.14, 2.2, 0.14), Basis(), 0.01)
	var c := Vector3(0, 1.62, 0.1)
	var bas := Basis(Vector3(0, 0, 1), 0.04)
	b.box(oak, c, Vector3(0.82, 1.0, 0.05), bas, 0.004)
	K.face(b, K.warning_board(), c + bas * Vector3(-0.4, 0.49, 0.027), c + bas * Vector3(0.4, 0.49, 0.027),
		c + bas * Vector3(0.4, -0.49, 0.027), c + bas * Vector3(-0.4, -0.49, 0.027), Vector3(0, 0, 1))
	for y in [0.35, -0.35]:
		K.knob(b, K.iron(), c + bas * Vector3(0, y, 0.03), 0.014, 6)
	# A red rag knotted round the post.
	K.ring(b, HK.plain(K.Painter.RED.darkened(0.3), 1.0), Vector3(0, 0.95, 0), Vector3.UP, 0.08, 0.02, 8)
	b.push(Transform3D(Basis(Vector3(0, 0, 1), 0.25), Vector3(0.06, 0.95, 0.06)))
	K.banner(b, HK.plain(K.Painter.RED.darkened(0.3), 1.0), 0.07, 0.32, "point", 3, 1.0, 3, 5)
	b.pop()
	_foot_stones(b, 0.17, 18)
	return K.asset("CP18_warning_sign", b, [["box", Vector3(0, 1.1, 0.04), Vector3(0.84, 2.2, 0.22)]])


## CP20: stone boundary marker: a weathered standing stone with the cross carved and painted on
## its face, leaning a little. 1.1 m. Marks where the Knights' land begins.
static func boundary_marker() -> Node3D:
	var b := HK.MB.new(220)
	var s := K.limestone()
	var outline := PackedVector2Array()
	outline.append(Vector2(-0.27, -0.12))
	outline.append(Vector2(0.27, -0.12))
	outline.append(Vector2(0.23, 0.88))
	for i in range(1, 8):
		var a := PI * float(i) / 8.0
		outline.append(Vector2(cos(a) * 0.23, 0.88 + sin(a) * 0.2))
	outline.append(Vector2(-0.23, 0.88))
	b.push(Transform3D(Basis(Vector3(1, 0, 0), -0.06) * Basis(Vector3(0, 0, 1), 0.04), Vector3(0, 0, -0.14)))
	K.extrude(b, s, s, outline, 0.0, 0.28, Rect2(-0.27, -0.12, 0.54, 1.2), true)
	K.extrude(b, K.red_stone(), s, K.cross_poly(0.15, Vector2(0, 0.66)), 0.28, 0.025, Rect2(-0.15, 0.51, 0.3, 0.3))
	b.pop()
	_foot_stones(b, 0.3, 20)
	return K.asset("CP20_stone_boundary_marker", b, [["box", Vector3(0, 0.5, 0), Vector3(0.56, 1.1, 0.34)]])
