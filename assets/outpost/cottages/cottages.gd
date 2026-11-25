extends RefCounted
## Cottage and civilian-life props, CO03-CO18 (see assets/outpost/MANIFEST.md). CO01/CO02 are the
## B07/B08 cottages. Real-world size (doors and shutters are drawn for the 1.3x buildings: 1.43 m).
## Origins: centre of the base on y = 0; the front faces +Z. The wattle fence is also ENV21.

const HK := preload("res://assets/hideout/Materials/kit.gd")
const K := preload("res://assets/outpost/materials/outpost_kit.gd")
const MK := preload("res://assets/outpost/market/market.gd")
const CR := preload("res://assets/outpost/carpenter/carpenter.gd")
const BLD := preload("res://assets/outpost/buildings/buildings.gd")


## A woven wattle hurdle along x: stakes and a wicker panel, length l, height h (also ENV21).
static func wattle(b: HK.MB, l: float, h := 1.0) -> void:
	var n := int(l / 0.4) + 1
	for i in n:
		var x := -l * 0.5 + i * l / (n - 1)
		b.cyl(K.oak("weathered"), Vector3(x, -0.05, 0), Vector3(x, h + 0.08, 0), 0.03, 0.025, 5, 0.1)
	b.box(K.wicker(), Vector3(0, h * 0.5 + 0.03, 0), Vector3(l, h - 0.06, 0.05), Basis(), 0.015)


## CO03: cottage door: an oak plank door with iron straps and a ring, in its frame. Drawn at the
## buildings' size (1.4 x 2.6 m opening).
static func cottage_door() -> Node3D:
	var b := HK.MB.new(903)
	var k: float = BLD.SIZE
	var oak := K.oak("weathered")
	for x in [-0.62 * k, 0.62 * k]:
		b.box(oak, Vector3(x, 1.05 * k, 0), Vector3(0.18 * k, 2.1 * k, 0.18 * k), Basis(), 0.006)
	b.box(oak, Vector3(0, 2.14 * k, 0), Vector3(1.42 * k, 0.16 * k, 0.18 * k), Basis(), 0.006)
	b.box(oak, Vector3(0, 1.0 * k, 0.02), Vector3(1.08 * k, 2.0 * k, 0.06), Basis(), 0.004)
	for y in [0.4, 1.55]:
		b.box(K.iron(), Vector3(-0.1, y * k, 0.06), Vector3(0.9 * k, 0.07, 0.012))
	K.ring(b, K.iron(), Vector3(0.38 * k, 1.0 * k, 0.07), Vector3(0, 0, 1), 0.05, 0.008, 8, 4)
	return K.asset("CO03_cottage_door", b, [["box", Vector3(0, 1.1 * k, 0), Vector3(1.42 * k, 2.2 * k, 0.2)]])


## CO04: wooden shutters: a pair of board shutters, one open on its hinge. Origin: on the wall.
static func shutters() -> Node3D:
	var b := HK.MB.new(904)
	var k: float = BLD.SIZE
	var oak := K.oak("weathered")
	b.box(oak, Vector3(-0.2 * k, 0, 0.03), Vector3(0.38 * k, 0.66 * k, 0.04), Basis(), 0.003)
	var hb := Basis(Vector3.UP, 1.9)
	b.box(oak, Vector3(0.38 * k, 0, 0.03) + hb * Vector3(-0.19 * k, 0, 0), Vector3(0.38 * k, 0.66 * k, 0.04), hb, 0.003)
	for y in [-0.2, 0.2]:
		b.box(K.iron(), Vector3(-0.2 * k, y * k, 0.055), Vector3(0.3 * k, 0.03, 0.01))
	return K.asset("CO04_wooden_shutters", b, [])


## CO05: chimney stack: a free-standing rubble chimney with a stone cap, 5 m (to stand at a gable).
static func chimney() -> Node3D:
	var b := HK.MB.new(905)
	b.box(K.rubble(), Vector3(0, 1.4, 0), Vector3(1.1, 2.8, 1.3), Basis(), 0.012)
	b.box(K.rubble(), Vector3(0, 3.9, 0), Vector3(0.8, 2.2, 0.9), Basis(), 0.01)
	b.box(K.limestone(), Vector3(0, 5.05, 0), Vector3(0.96, 0.12, 1.06), Basis(), 0.008)
	return K.asset("CO05_chimney_stack", b, [["box", Vector3(0, 1.4, 0), Vector3(1.1, 2.8, 1.3)]])


## CO06: vegetable garden: a plank-edged raised bed with rows of cabbages, leeks and beans on poles.
static func vegetable_garden() -> Node3D:
	var b := HK.MB.new(906)
	var oak := K.oak("weathered")
	for s in [-1.0, 1.0]:
		b.box(oak, Vector3(0, 0.1, s * 1.0), Vector3(3.0, 0.2, 0.05), Basis(), 0.003)
		b.box(oak, Vector3(s * 1.5, 0.1, 0), Vector3(0.05, 0.2, 2.0), Basis(), 0.003)
	b.box(K.earth_floor(), Vector3(0, 0.08, 0), Vector3(2.95, 0.16, 1.95), Basis(), 0.0)
	for i in 6:
		var x := -1.2 + i * 0.48
		b.blob(MK.cabbage(), Vector3(x, 0.2, -0.6), Vector3(0.13, 0.1, 0.13), 906 + i, 0.25, 2.0, 4, 8)
		b.cyl(K.goods("leek", Color(0.38, 0.5, 0.28)), Vector3(x, 0.16, 0.0), Vector3(x + 0.02, 0.45, 0.02), 0.025, 0.035, 5)
	for i in 4:
		var x := -1.1 + i * 0.7
		b.cyl(K.oak("weathered"), Vector3(x, 0.1, 0.6), Vector3(x, 1.5, 0.6), 0.015, 0.012, 4)
		b.blob(K.goods("bean", Color(0.28, 0.42, 0.2)), Vector3(x, 0.9, 0.6), Vector3(0.12, 0.45, 0.12), 916 + i, 0.4, 3.0, 5, 8)
	return K.asset("CO06_vegetable_garden", b, [])


## CO07: garden fence: a woven wattle hurdle, 2.4 m (also ENV21).
static func garden_fence() -> Node3D:
	var b := HK.MB.new(907)
	wattle(b, 2.4)
	return K.asset("CO07_garden_fence", b, [["box", Vector3(0, 0.5, 0), Vector3(2.4, 1.0, 0.1)]])


static func _line(b: HK.MB, l: float) -> void:
	for x in [-l * 0.5, l * 0.5]:
		b.cyl(K.oak("weathered"), Vector3(x, 0, 0), Vector3(x, 1.9, 0), 0.04, 0.035, 6, 0.08)
	b.cyl(K.rope(), Vector3(-l * 0.5, 1.82, 0), Vector3(0, 1.72, 0), 0.006, 0.006, 3)
	b.cyl(K.rope(), Vector3(0, 1.72, 0), Vector3(l * 0.5, 1.82, 0), 0.006, 0.006, 3)


## CO08: clothesline: two poles and a sagging rope, 4 m.
static func clothesline() -> Node3D:
	var b := HK.MB.new(908)
	_line(b, 4.0)
	return K.asset("CO08_clothesline", b, [])


## CO09: hanging linen: the clothesline with sheets and shirts pegged out.
static func hanging_linen() -> Node3D:
	var b := HK.MB.new(909)
	_line(b, 4.0)
	var cloths := [K.linen(), K.cloth("weld", Color(0.85, 0.75, 0.38)), K.linen(), K.cloth("woad", Color(0.32, 0.38, 0.55))]
	for i in 4:
		var x := -1.4 + i * 0.95
		var y := 1.82 - 0.1 * (1.0 - absf(x) / 2.0)
		b.push(Transform3D(Basis(), Vector3(x, y, 0.01)))
		K.banner(b, cloths[i], 0.7 if i % 2 == 0 else 0.45, 0.9 if i % 2 == 0 else 0.6, "straight", 909 + i, 2.0, 6, 6)
		b.pop()
	return K.asset("CO09_hanging_linen", b, [])


## CO10: laundry basket: a tall wicker basket of folded and crumpled linen.
static func laundry_basket() -> Node3D:
	var b := HK.MB.new(910)
	MK.basket(b, Vector3.ZERO, 0.3, 0.36)
	MK.heap(b, Vector3.ZERO, 0.3, 0.34, K.linen(), 6, 0.1, 910, Vector3(1.3, 0.6, 1.0))
	return K.asset("CO10_laundry_basket", b, [])


## CO12: animal pen: a wattle pen, 3 x 3 m, with a gap for a hurdle gate.
static func animal_pen() -> Node3D:
	var b := HK.MB.new(912)
	var cols := []
	for side in 4:
		var bas := Basis(Vector3.UP, side * PI * 0.5)
		if side == 0:
			for s in [-1.0, 1.0]:
				b.push(Transform3D(bas, bas * Vector3(s * 0.95, 0, 1.5)))
				wattle(b, 1.1)
				b.pop()
				cols.append(["box", bas * Vector3(s * 0.95, 0.5, 1.5), Vector3(1.1, 1.0, 0.1), bas])
		else:
			b.push(Transform3D(bas, bas * Vector3(0, 0, 1.5)))
			wattle(b, 3.0)
			b.pop()
			cols.append(["box", bas * Vector3(0, 0.5, 1.5), Vector3(3.0, 1.0, 0.1), bas])
	b.box(K.goods("trodden", Color(0.27, 0.21, 0.15), 1.0), Vector3(0, 0.005, 0), Vector3(2.9, 0.01, 2.9))
	return K.asset("CO12_animal_pen", b, cols)


## CO13: chicken coop: a small raised hut on legs with a ramp, a shingled roof and a nest box.
static func chicken_coop() -> Node3D:
	var b := HK.MB.new(913)
	var oak := K.oak("weathered")
	var cols := []
	for x in [-0.6, 0.6]:
		for z in [-0.45, 0.45]:
			b.box(oak, Vector3(x, 0.25, z), Vector3(0.08, 0.5, 0.08), Basis(), 0.003)
	BLD._plank_wall(b, Vector2(-0.65, 0.5), Vector2(0.65, 0.5), 0.5, 1.2, 1.2, [[0.5, 0.8, 0.5, 0.8]], cols)
	BLD._plank_wall(b, Vector2(0.65, 0.5), Vector2(0.65, -0.5), 0.5, 1.2, 1.4, [], cols)
	BLD._plank_wall(b, Vector2(0.65, -0.5), Vector2(-0.65, -0.5), 0.5, 1.4, 1.4, [], cols)
	BLD._plank_wall(b, Vector2(-0.65, -0.5), Vector2(-0.65, 0.5), 0.5, 1.4, 1.2, [], cols)
	b.box(oak, Vector3(0, 0.52, 0), Vector3(1.3, 0.04, 1.0), Basis(), 0.002)
	var a := Vector3(-0.85, 1.48, -0.7)
	var c := Vector3(0.85, 1.48, -0.7)
	var d := Vector3(0.85, 1.25, 0.72)
	var e := Vector3(-0.85, 1.25, 0.72)
	b.quad(K.shingles(), a, c, d, e, Vector3(0, 1, 0.16))
	b.quad(oak, a + Vector3(0, -0.03, 0), c + Vector3(0, -0.03, 0), d + Vector3(0, -0.03, 0), e + Vector3(0, -0.03, 0), Vector3(0, -1, -0.16))
	b.box(oak, Vector3(-0.15, 0.27, 0.9), Vector3(0.22, 0.03, 0.9), Basis(Vector3(1, 0, 0), -0.55), 0.002)
	for i in 4:
		b.box(oak, Vector3(-0.15, 0.1 + i * 0.1, 0.62 + i * 0.12), Vector3(0.2, 0.015, 0.015))
	b.blob(K.straw(), Vector3(0, 0.6, 0), Vector3(0.5, 0.06, 0.4), 913, 0.4, 2.0, 4, 8)
	return K.asset("CO13_chicken_coop", b, [["box", Vector3(0, 0.7, 0), Vector3(1.4, 1.4, 1.1)]])


## CO15: household tools leaning together: a spade, a rake, a pitchfork and a besom broom.
static func household_tools() -> Node3D:
	var b := HK.MB.new(915)
	var top := Vector3(0, 1.45, -0.05)
	var feet := [Vector3(-0.3, 0, 0.25), Vector3(-0.1, 0, 0.3), Vector3(0.12, 0, 0.28), Vector3(0.32, 0, 0.22)]
	for i in 4:
		var f: Vector3 = feet[i]
		var t := top + Vector3((i - 1.5) * 0.04, 0, 0)
		b.cyl(K.oak("weathered"), f + (t - f) * 0.12, t, 0.018, 0.016, 5)
		var dn := (f - t).normalized()
		var side := dn.cross(Vector3(0, 0, 1)).normalized()
		match i:
			0:
				b.box(K.iron(), f + (t - f) * 0.06, Vector3(0.18, 0.24, 0.01), Basis(side, -dn, side.cross(-dn)), 0.0)
			1:
				b.box(K.oak("weathered"), f + (t - f) * 0.12, Vector3(0.4, 0.03, 0.03), Basis(side, -dn, side.cross(-dn)), 0.0)
				for j in 6:
					b.cyl(K.oak(), f + (t - f) * 0.12 + side * (-0.17 + j * 0.068), f + (t - f) * 0.12 + side * (-0.17 + j * 0.068) + dn * 0.08, 0.006, 0.005, 3)
			2:
				for j in 3:
					b.cyl(K.iron(), f + (t - f) * 0.12 + side * (j - 1) * 0.05, f + side * (j - 1) * 0.06 + Vector3(0, 0.02, 0), 0.007, 0.004, 4)
			3:
				b.blob(K.goods("twigs", Color(0.42, 0.33, 0.2), 1.0), f + Vector3(0, 0.22, 0), Vector3(0.1, 0.24, 0.08), 915, 0.3, 3.0, 5, 8)
	return K.asset("CO15_household_tools", b, [])
