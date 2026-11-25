extends RefCounted
## White Knights faction assets, WK01-WK12 (see assets/outpost/MANIFEST.md).
## One emblem on everything: an ivory field with a dark red cross pattee (painter.gd).
## The Knights' things are dark stained oak, tarnished gold and charcoal iron: cared for and
## costly, against the weathered civilian village around them.
##
## Origins follow the hideout kit:
##   standing props: centre of the base on y = 0;
##   hanging things (banners, pennants): the top attachment point;
##   wall-mounted things (shield, plaque, seal, insignia, fittings): on the wall, facing +Z.

const HK := preload("res://assets/hideout/Materials/kit.gd")
const K := preload("res://assets/outpost/materials/outpost_kit.gd")


# ---------------------------------------------------------------- shared parts

## A hanging bar: oak rod with gold knob ends and iron bands that hold the cloth.
static func _bar(b: HK.MB, half: float, y: float, r: float, z := 0.0, bands := 4) -> void:
	b.cyl(K.oak(), Vector3(-half, y, z), Vector3(half, y, z), r, r, 8)
	K.knob(b, K.gold(), Vector3(-half - r * 0.5, y, z), r * 1.7)
	K.knob(b, K.gold(), Vector3(half + r * 0.5, y, z), r * 1.7)
	for i in bands:
		var x := lerpf(-half * 0.85, half * 0.85, (i + 0.5) / bands)
		b.cyl(K.iron(), Vector3(x - 0.02, y, z), Vector3(x + 0.02, y, z), r * 1.3, r * 1.3, 8)


## Two ropes from the hanging point (origin) to the bar, and the iron ring they meet at.
static func _hang_ropes(b: HK.MB, half: float, y: float) -> void:
	b.cyl(K.rope(), Vector3(0, -0.04, 0), Vector3(-half * 0.8, y + 0.03, 0), 0.012, 0.012, 5, 0.0, false)
	b.cyl(K.rope(), Vector3(0, -0.04, 0), Vector3(half * 0.8, y + 0.03, 0), 0.012, 0.012, 5, 0.0, false)
	K.ring(b, K.iron(), Vector3(0, -0.02, 0), Vector3(0, 0, 1), 0.035, 0.008, 8)


## A few small stones round the foot of a post.
static func _foot_stones(b: HK.MB, r: float, seed_: int) -> void:
	for i in 3:
		var a := TAU * i / 3.0 + 0.4 + seed_
		b.blob(K.limestone(), Vector3(cos(a) * r, 0.03, sin(a) * r), Vector3(0.1, 0.06, 0.08), seed_ * 7 + i, 0.3, 1.5, 4, 6, Basis(), true, 0.5)


## A straight timber between two points (braces, arms).
static func _beam(b: HK.MB, m: Material, a: Vector3, c: Vector3, t: float) -> void:
	b.box(m, (a + c) * 0.5, Vector3(a.distance_to(c), t, t), HK.basis_x(c - a), 0.004)


# ---------------------------------------------------------------- WK01-WK04: cloth

## WK01: large ivory banner with the red cross, 1.8 x 4 m, tongued hem, on a gold-tipped bar.
## Hangs from its rope ring (origin); about 4.6 m from ring to hem. For walls and gatehouses.
static func large_banner() -> Node3D:
	var b := HK.MB.new(101)
	var y := -0.55
	_bar(b, 1.05, y, 0.045, 0.0, 5)
	_hang_ropes(b, 1.05, y)
	b.push(Transform3D(Basis(), Vector3(0, y, 0)))
	K.banner(b, K.banner_cloth(), 1.8, 4.0, "dagged", 1)
	b.pop()
	return K.asset("WK01_large_white_knights_banner", b, [])


## WK02: narrow hanging banner, 0.85 x 3 m, pointed hem. Hangs from its rope ring (origin);
## about 3.35 m from ring to point. Fits the WK12 banner stand.
static func narrow_banner() -> Node3D:
	var b := HK.MB.new(102)
	var y := -0.35
	_bar(b, 0.5, y, 0.035, 0.0, 3)
	_hang_ropes(b, 0.5, y)
	b.push(Transform3D(Basis(), Vector3(0, y, 0)))
	K.banner(b, K.banner_cloth(), 0.85, 3.0, "point", 2)
	b.pop()
	return K.asset("WK02_narrow_hanging_banner", b, [])


## WK03: small triangular pennant, 1.4 m long, 0.55 m at the hoist. The origin is on the
## pole's axis at the top ring; it flies along +X. For poles, tents and the checkpoint.
static func small_pennant() -> Node3D:
	var b := HK.MB.new(103)
	for y in [-0.02, -0.53]:
		K.ring(b, K.iron(), Vector3(0, y, 0), Vector3.UP, 0.05, 0.008, 8)
	b.cyl(K.rope(), Vector3(0.05, 0.0, 0), Vector3(0.05, -0.56, 0), 0.01, 0.01, 5)
	b.push(Transform3D(Basis(), Vector3(0.055, 0, 0)))
	K.pennant(b, K.pennant_cloth(), 1.4, 0.55, 2)
	b.pop()
	return K.asset("WK03_small_triangular_pennant", b, [])


## WK04: mounted standard: a 5.6 m oak pole planted in the ground (iron foot, gold spear-point
## finial), a crossbar and a swallow-tailed banner. Stands on its own.
static func mounted_standard() -> Node3D:
	var b := HK.MB.new(104)
	var top := 5.6
	b.cyl(K.iron(), Vector3(0, 0, 0), Vector3(0, 0.3, 0), 0.058, 0.05, 8)
	b.cyl(K.oak(), Vector3(0, 0.28, 0), Vector3(0, top, 0), 0.055, 0.045, 8, 0.02, true, 3)
	K.knob(b, K.gold(), Vector3(0, top + 0.05, 0), 0.07)
	b.push(Transform3D(Basis(), Vector3(0, top + 0.1, 0)))
	b.lathe(K.gold(), PackedVector2Array([Vector2(0.025, 0.0), Vector2(0.055, 0.1), Vector2(0.035, 0.24), Vector2(0.0005, 0.44)]), 4)
	b.pop()
	var y := 4.95
	var z := 0.08
	b.box(K.iron(), Vector3(0, y, 0.03), Vector3(0.13, 0.12, 0.15))
	_bar(b, 0.58, y, 0.035, z, 3)
	b.cyl(K.rope(), Vector3(0, top - 0.05, 0.03), Vector3(-0.5, y + 0.03, z), 0.01, 0.01, 4, 0.0, false)
	b.cyl(K.rope(), Vector3(0, top - 0.05, 0.03), Vector3(0.5, y + 0.03, z), 0.01, 0.01, 4, 0.0, false)
	b.push(Transform3D(Basis(), Vector3(0, y, z)))
	K.banner(b, K.banner_cloth(), 1.05, 2.2, "swallow", 4, 2.0)
	b.pop()
	_foot_stones(b, 0.17, 4)
	return K.asset("WK04_mounted_standard", b, [["cyl", Vector3(0, top * 0.5, 0), 0.09, top]])


# ---------------------------------------------------------------- WK05-WK07: painted wood

## WK05: wooden heater shield, 0.62 x 0.8 m: the emblem painted on oak, iron rim.
## Wall-mounted: back at z = 0, centred on the shield.
static func wooden_shield() -> Node3D:
	var b := HK.MB.new(105)
	K.heater(b, 0.62, 0.8)
	return K.asset("WK05_wooden_shield_red_cross", b, [["box", Vector3(0, 0, 0.035), Vector3(0.62, 0.8, 0.07)]])


## WK06: heraldic signboard: an oak post with an arm and a painted board hung on chains
## (emblem both sides). 2.8 m tall. Marks Knights' property: checkpoint, stores, toll.
static func signboard() -> Node3D:
	var b := HK.MB.new(106)
	var oak := K.oak()
	b.box(oak, Vector3(0, 1.35, 0), Vector3(0.15, 2.7, 0.15), Basis(), 0.01)
	b.box(oak, Vector3(0, 2.72, 0), Vector3(0.2, 0.06, 0.2), Basis(), 0.004)
	K.knob(b, K.gold(), Vector3(0, 2.79, 0), 0.05)
	b.box(oak, Vector3(0.52, 2.5, 0), Vector3(1.04, 0.1, 0.1), Basis(), 0.006)
	_beam(b, oak, Vector3(0.07, 2.0, 0), Vector3(0.52, 2.46, 0), 0.07)
	for x in [0.3, 0.8]:
		for k in 3:
			K.ring(b, K.iron(), Vector3(x, 2.41 - k * 0.055, 0), Vector3(0, 0, 1) if k % 2 == 0 else Vector3(1, 0, 0), 0.028, 0.006, 6)
	var c := Vector3(0.55, 1.82, 0)
	b.box(oak, c, Vector3(0.74, 0.86, 0.05), Basis(), 0.004)
	for s in [1.0, -1.0]:
		var z: float = s * 0.03
		K.face(b, K.emblem_paint(), c + Vector3(-0.31 * s, 0.37, z), c + Vector3(0.31 * s, 0.37, z),
			c + Vector3(0.31 * s, -0.37, z), c + Vector3(-0.31 * s, -0.37, z), Vector3(0, 0, s))
		for e in [[Vector3(0, 0.4, 0), Vector3(0.74, 0.06, 0.03)], [Vector3(0, -0.4, 0), Vector3(0.74, 0.06, 0.03)],
				[Vector3(0.34, 0, 0), Vector3(0.06, 0.86, 0.03)], [Vector3(-0.34, 0, 0), Vector3(0.06, 0.86, 0.03)]]:
			b.box(oak, c + e[0] + Vector3(0, 0, s * 0.03), e[1], Basis(), 0.003)
	_foot_stones(b, 0.2, 6)
	return K.asset("WK06_heraldic_signboard", b, [
		["box", Vector3(0, 1.4, 0), Vector3(0.16, 2.8, 0.16)],
		["box", c, Vector3(0.76, 0.88, 0.1)]])


## WK07: coat-of-arms plaque: a gabled oak board in a tarnished gold frame with a carved
## shield in relief and gold rosette nails. 0.95 x 1.15 m. Wall-mounted: back at z = 0,
## bottom centre at the origin. Over doors: guard shelter, toll house, inn (Knights' licence).
static func plaque() -> Node3D:
	var b := HK.MB.new(107)
	var w := 0.95
	var h := 1.15
	var poly := PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(w * 0.5, 0), Vector2(w * 0.5, h - 0.22), Vector2(0, h), Vector2(-w * 0.5, h - 0.22)])
	K.extrude(b, K.oak(), K.oak(), poly, 0.0, 0.05, Rect2(-w * 0.5, 0, w, h))
	for i in poly.size():
		var a := poly[i]
		var c := poly[(i + 1) % poly.size()]
		var inward := (Vector2(0, h * 0.45) - (a + c) * 0.5).normalized() * 0.02
		_beam(b, K.gold(), Vector3(a.x + inward.x, a.y + inward.y, 0.06), Vector3(c.x + inward.x, c.y + inward.y, 0.06), 0.035)
	b.push(Transform3D(Basis(), Vector3(0, 0.5, 0.05)))
	K.heater(b, 0.54, 0.7, 0.03, 0.035)
	b.pop()
	for p in [Vector2(-0.36, 0.1), Vector2(0.36, 0.1), Vector2(-0.36, 0.86), Vector2(0.36, 0.86)]:
		K.knob(b, K.gold(), Vector3(p.x, p.y, 0.06), 0.028, 8)
	return K.asset("WK07_coat_of_arms_plaque", b, [["box", Vector3(0, h * 0.5, 0.06), Vector3(w, h, 0.12)]])


# ---------------------------------------------------------------- WK08: the awning

## WK08: red-and-ivory market awning: striped linen on four oak posts, sloping to the front
## (2.75 m back, 2.3 m front), a scalloped valance and guy ropes. 3.2 x 2.2 m under cover.
## Same asset as MK03. Front faces +Z.
static func market_awning() -> Node3D:
	var b := HK.MB.new(108)
	var oak := K.oak()
	var hw := 1.6
	var zf := 1.1
	var zb := -1.1
	var hf := 2.3
	var hb := 2.75
	for x in [-hw, hw]:
		b.cyl(oak, Vector3(x, 0, zf), Vector3(x, hf + 0.04, zf), 0.06, 0.05, 7, 0.03)
		b.cyl(oak, Vector3(x, 0, zb), Vector3(x, hb + 0.04, zb), 0.06, 0.05, 7, 0.03)
		b.cyl(oak, Vector3(x, hf, zf), Vector3(x, hb, zb), 0.038, 0.038, 6)
	b.cyl(oak, Vector3(-hw - 0.12, hf, zf), Vector3(hw + 0.12, hf, zf), 0.045, 0.045, 7)
	b.cyl(oak, Vector3(-hw - 0.12, hb, zb), Vector3(hw + 0.12, hb, zb), 0.045, 0.045, 7)
	# The canvas: from the back rail to 0.15 m past the front rail, sagging between them.
	var x0 := -hw - 0.15
	var x1 := hw + 0.15
	var nu := 17
	var nv := 8
	var pts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var slope := Vector2(zf + 0.15 - zb, hf - hb).length()
	var front_y := 0.0
	for j in nv:
		var t := float(j) / (nv - 1)
		var z := lerpf(zb, zf + 0.15, t)
		var tt := (z - zb) / (zf - zb)
		for i in nu:
			var x := lerpf(x0, x1, float(i) / (nu - 1))
			var y := lerpf(hb, hf, tt) + 0.06 - 0.1 * sin(PI * clampf(tt, 0.0, 1.0)) - 0.025 * absf(sin(PI * (x - x0) / 0.8))
			pts.append(Vector3(x, y, z))
			uvs.append(Vector2(x - x0, t * slope))
			if j == nv - 1 and i == 0:
				front_y = y
	K.sheet2(b, K.stripes(), pts, uvs, nu, nv, Vector3.UP)
	# The valance: a scalloped drop along the front edge, one scallop per stripe.
	var vpts := PackedVector3Array()
	var vuvs := PackedVector2Array()
	var vn := 4
	for j in vn:
		for i in nu * 2 - 1:
			var x := lerpf(x0, x1, float(i) / (nu * 2 - 2))
			var top := pts[(nv - 1) * nu + i / 2].y if i % 2 == 0 else (pts[(nv - 1) * nu + i / 2].y + pts[(nv - 1) * nu + i / 2 + 1].y) * 0.5
			var drop := 0.2 + 0.1 * absf(sin(PI * (x - x0) / 0.5))
			var y: float = top - drop * float(j) / (vn - 1)
			vpts.append(Vector3(x, y, zf + 0.15 + 0.01 * float(j) / (vn - 1)))
			vuvs.append(Vector2(x - x0, slope + (top - y)))
	K.sheet2(b, K.stripes(), vpts, vuvs, nu * 2 - 1, vn, Vector3(0, 0, 1))
	# Guy ropes and pegs at the front corners.
	for s in [-1.0, 1.0]:
		var peg := Vector3(s * (hw + 0.35), 0.0, zf + 1.0)
		b.cyl(K.rope(), Vector3(s * hw, hf - 0.05, zf), peg + Vector3(0, 0.18, 0), 0.01, 0.01, 4, 0.0, false)
		b.box(oak, peg + Vector3(0, 0.1, 0), Vector3(0.05, 0.22, 0.05), Basis(Vector3(s, 0, 0).cross(Vector3.UP).normalized(), -0.3), 0.004)
	var cols := []
	for x in [-hw, hw]:
		cols.append(["cyl", Vector3(x, hf * 0.5, zf), 0.08, hf])
		cols.append(["cyl", Vector3(x, hb * 0.5, zb), 0.08, hb])
	return K.asset("WK08_red_ivory_market_awning", b, cols)


# ---------------------------------------------------------------- WK09-WK11: small fittings

## WK09: a Knights' notice: parchment nailed to a wall or board, a red wax seal stamped
## with the cross, ribbon tails. 0.34 x 0.46 m. Origin: top centre, on the wall.
static func notice_seal() -> Node3D:
	var b := HK.MB.new(109)
	var w := 0.34
	var h := 0.46
	var nu := 5
	var nv := 6
	var pts := PackedVector3Array()
	var uvs := PackedVector2Array()
	for j in nv:
		for i in nu:
			var xn := float(i) / (nu - 1)
			var yn := float(j) / (nv - 1)
			var curl := 0.03 * pow(yn, 3.0) * (0.4 + 0.6 * absf(2.0 * xn - 1.0)) + 0.006 * absf(2.0 * xn - 1.0)
			pts.append(Vector3((xn - 0.5) * w, -yn * h, 0.004 + curl))
			uvs.append(Vector2(xn, yn))
	K.sheet2(b, K.parchment(), pts, uvs, nu, nv, Vector3(0, 0, 1))
	b.cyl(K.iron(), Vector3(0, -0.03, 0), Vector3(0, -0.03, 0.02), 0.005, 0.005, 5)
	K.knob(b, K.iron(), Vector3(0, -0.03, 0.02), 0.011, 6)
	var sc := Vector3(0, -0.385, 0.012)
	var ribbon := HK.plain(K.Painter.RED.darkened(0.25), 1.0)
	for s in [-1.0, 1.0]:
		var a := sc + Vector3(s * 0.008, -0.01, 0.002)
		var c := sc + Vector3(s * 0.05, -0.11, 0.004)
		var side := Vector3(0.011, 0.003 * s, 0)
		b.quad(ribbon, a - side, a + side, c + side, c - side, Vector3(0, 0, 1))
	b.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), sc))
	b.lathe(K.wax(), PackedVector2Array([Vector2(0.0005, 0.0), Vector2(0.04, 0.0), Vector2(0.043, 0.004), Vector2(0.037, 0.009), Vector2(0.0005, 0.009)]), 14)
	b.pop()
	K.extrude(b, K.wax(), K.wax(), K.cross_poly(0.024, Vector2(sc.x, sc.y)), sc.z + 0.009, 0.003, Rect2(-0.024, sc.y - 0.024, 0.048, 0.048))
	return K.asset("WK09_faction_notice_seal", b, [])


## WK10: stone insignia: a limestone block with a raised panel and the cross carved in relief,
## painted red (worn). 0.9 x 0.9 x 0.3 m. For the gatehouse, walls, plinths and the toll house.
## Wall-mounted: back at z = 0, bottom centre at the origin.
static func stone_insignia() -> Node3D:
	var b := HK.MB.new(110)
	var s := K.limestone()
	b.box(s, Vector3(0, 0.45, 0.12), Vector3(0.9, 0.9, 0.24), Basis(), 0.012)
	b.box(s, Vector3(0, 0.45, 0.25), Vector3(0.78, 0.78, 0.04), Basis(), 0.006)
	K.extrude(b, K.red_stone(), K.limestone(), K.cross_poly(0.31, Vector2(0, 0.45)), 0.27, 0.06, Rect2(-0.31, 0.14, 0.62, 0.62))
	return K.asset("WK10_stone_insignia", b, [["box", Vector3(0, 0.45, 0.165), Vector3(0.9, 0.9, 0.33)]])


## WK11: banner ropes and fittings: an iron wall bracket with a pulley block, a rope down to
## a hook (a banner's ring hangs here, about 1.3 m below the arm) and back to a cleat with a
## coil of spare rope. The arm reaches 1 m from the wall. Origin: the wall plate, facing +Z.
static func banner_fittings() -> Node3D:
	var b := HK.MB.new(111)
	var ir := K.iron()
	b.box(ir, Vector3(0, 0, 0.012), Vector3(0.14, 0.34, 0.024), Basis(), 0.002)
	for y in [0.12, -0.12]:
		K.knob(b, ir, Vector3(0, y, 0.026), 0.014, 6)
	b.box(ir, Vector3(0, 0.1, 0.52), Vector3(0.04, 0.04, 1.0))
	_beam(b, ir, Vector3(0, -0.14, 0.03), Vector3(0, 0.085, 0.62), 0.03)
	var tip := Vector3(0, 0.08, 0.96)
	K.ring(b, ir, tip + Vector3(0, -0.04, 0), Vector3(1, 0, 0), 0.03, 0.007, 8)
	b.box(K.oak(), tip + Vector3(0, -0.14, 0), Vector3(0.06, 0.12, 0.09), Basis(), 0.004)
	b.cyl(ir, tip + Vector3(-0.04, -0.14, 0), tip + Vector3(0.04, -0.14, 0), 0.012, 0.012, 6)
	var r := K.rope()
	var hook := tip + Vector3(0, -1.3, 0.03)
	b.cyl(r, tip + Vector3(0, -0.19, 0.03), hook + Vector3(0, 0.07, 0), 0.011, 0.011, 5)
	K.ring(b, ir, hook + Vector3(0, 0.035, 0), Vector3(1, 0, 0), 0.03, 0.007, 8)
	b.cyl(ir, hook, hook + Vector3(0, -0.06, 0.03), 0.007, 0.007, 5)
	var cleat := Vector3(0, -1.3, 0.0)
	b.cyl(r, tip + Vector3(0, -0.19, -0.03), cleat + Vector3(0, 0.05, 0.07), 0.011, 0.011, 5)
	b.box(K.oak(), cleat + Vector3(0, 0, 0.025), Vector3(0.06, 0.24, 0.05), Basis(), 0.003)
	b.box(K.oak(), cleat + Vector3(0, 0, 0.065), Vector3(0.045, 0.32, 0.035), Basis(), 0.003)
	for k in 3:
		K.ring(b, r, cleat + Vector3(0, -0.17 - k * 0.012, 0.075), Vector3(0, 0, 1), 0.12 - k * 0.012, 0.011, 10)
	return K.asset("WK11_banner_ropes_and_fittings", b, [])


# ---------------------------------------------------------------- WK12: the stand

## WK12: banner stand: a 4.1 m oak upright on a cross foot, a crossbar with gold ends and a
## front hook at 3.82 m that a WK02 narrow banner hangs from (its hem then clears the ground
## by about half a meter). Front faces +Z. Stands on its own.
const STAND_HOOK := Vector3(0, 3.82, 0.12)


static func banner_stand() -> Node3D:
	var b := HK.MB.new(112)
	var oak := K.oak()
	var top := 4.1
	b.box(oak, Vector3(0, (top + 0.12) * 0.5, 0), Vector3(0.12, top - 0.12, 0.12), Basis(), 0.006)
	b.box(oak, Vector3(0, 0.06, 0), Vector3(1.3, 0.12, 0.14), Basis(), 0.008)
	b.box(oak, Vector3(0, 0.065, 0), Vector3(0.14, 0.12, 1.3), Basis(), 0.008)
	# Braces to the sides and the back only, so a hanging banner clears them at the front.
	for d in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, -1)]:
		_beam(b, oak, d * 0.5 + Vector3(0, 0.13, 0), d * 0.06 + Vector3(0, 0.8, 0), 0.07)
	b.cyl(oak, Vector3(-0.66, 3.8, 0), Vector3(0.66, 3.8, 0), 0.04, 0.04, 8)
	K.knob(b, K.gold(), Vector3(-0.69, 3.8, 0), 0.055)
	K.knob(b, K.gold(), Vector3(0.69, 3.8, 0), 0.055)
	b.box(K.iron(), Vector3(0, 3.8, 0.0), Vector3(0.16, 0.1, 0.16))
	b.cyl(K.iron(), Vector3(0, 3.8, 0.07), STAND_HOOK + Vector3(0, 0.0, 0.0), 0.01, 0.01, 5)
	b.cyl(K.iron(), STAND_HOOK, STAND_HOOK + Vector3(0, 0.05, 0.02), 0.01, 0.01, 5)
	b.box(oak, Vector3(0, top + 0.02, 0), Vector3(0.17, 0.05, 0.17), Basis(), 0.003)
	K.knob(b, K.gold(), Vector3(0, top + 0.1, 0), 0.065)
	return K.asset("WK12_banner_stand", b, [
		["box", Vector3(0, top * 0.5, 0), Vector3(0.14, top, 0.14)],
		["box", Vector3(0, 0.07, 0), Vector3(1.3, 0.14, 1.3)]])
