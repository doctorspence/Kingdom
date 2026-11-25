extends RefCounted
## Inn and tavern props, IN03-IN20 (see assets/outpost/MANIFEST.md). IN01/IN02/IN07/IN12 are built
## into the B01 inn. Real-world size: furniture fits the body (seats 0.45 m, tables 0.78 m).
## Origins: centre of the base on y = 0; the front faces +Z.

const HK := preload("res://assets/hideout/Materials/kit.gd")
const K := preload("res://assets/outpost/materials/outpost_kit.gd")
const MK := preload("res://assets/outpost/market/market.gd")
const CR := preload("res://assets/outpost/carpenter/carpenter.gd")


## A plank bench, seat at 0.45 m, length l (also CO17).
static func _bench(b: HK.MB, l: float, m: Material) -> void:
	b.box(m, Vector3(0, 0.44, 0), Vector3(l, 0.06, 0.32), Basis(), 0.005)
	for x in [-l * 0.38, l * 0.38]:
		for s in [-1.0, 1.0]:
			CR._beam(b, m, Vector3(x + 0.04 * s, 0.0, s * 0.13), Vector3(x, 0.41, s * 0.05), 0.06)


## A plank table on two A-frame trestles, top at 0.78 m.
static func _table(b: HK.MB, l: float, d: float, m: Material) -> void:
	b.box(m, Vector3(0, 0.75, 0), Vector3(l, 0.06, d), Basis(), 0.006)
	for x in [-l * 0.36, l * 0.36]:
		for s in [-1.0, 1.0]:
			CR._beam(b, m, Vector3(x, 0.0, s * d * 0.38), Vector3(x, 0.72, s * d * 0.1), 0.07)
	b.box(m, Vector3(0, 0.3, 0), Vector3(l * 0.72, 0.06, 0.06), Basis(), 0.003)


## A turned wooden mug at c.
static func _mug(b: HK.MB, c: Vector3) -> void:
	b.push(Transform3D(Basis(), c))
	b.lathe(K.oak(), PackedVector2Array([Vector2(0.0005, 0.0), Vector2(0.045, 0.0), Vector2(0.05, 0.12), Vector2(0.042, 0.12), Vector2(0.04, 0.012), Vector2(0.0005, 0.012)]), 10)
	b.pop()
	b.box(K.oak(), c + Vector3(0.06, 0.06, 0), Vector3(0.02, 0.07, 0.02), Basis(), 0.0)


## IN03: outdoor bench, 1.8 m, weathered (also CO17).
static func outdoor_bench() -> Node3D:
	var b := HK.MB.new(803)
	_bench(b, 1.8, K.oak("weathered"))
	return K.asset("IN03_outdoor_bench", b, [["box", Vector3(0, 0.24, 0), Vector3(1.8, 0.48, 0.35)]])


## IN04: outdoor table with two benches, weathered, mugs left on it.
static func outdoor_table() -> Node3D:
	var b := HK.MB.new(804)
	_table(b, 1.8, 0.8, K.oak("weathered"))
	for s in [-1.0, 1.0]:
		b.push(Transform3D(Basis(), Vector3(0, 0, s * 0.68)))
		_bench(b, 1.8, K.oak("weathered"))
		b.pop()
	_mug(b, Vector3(-0.4, 0.78, 0.1))
	_mug(b, Vector3(0.3, 0.78, -0.15))
	return K.asset("IN04_outdoor_table", b, [["box", Vector3(0, 0.39, 0), Vector3(1.8, 0.78, 1.7)]])


## IN05: dining table for the taproom, stained oak, 2.2 m.
static func dining_table() -> Node3D:
	var b := HK.MB.new(805)
	_table(b, 2.2, 0.85, K.oak())
	MK.bowl(b, Vector3(-0.5, 0.78, 0.1), 0.1)
	_mug(b, Vector3(0.4, 0.78, -0.1))
	return K.asset("IN05_dining_table", b, [["box", Vector3(0, 0.39, 0), Vector3(2.2, 0.78, 0.85)]])


## IN06: wooden stools: three-legged, two of them.
static func stools() -> Node3D:
	var b := HK.MB.new(806)
	for c in [Vector3(-0.3, 0, 0), Vector3(0.35, 0, 0.15)]:
		b.cyl(K.oak(), c + Vector3(0, 0.42, 0), c + Vector3(0, 0.46, 0), 0.17, 0.17, 10)
		for i in 3:
			var a := TAU * i / 3.0
			b.cyl(K.oak(), c + Vector3(cos(a) * 0.17, 0, sin(a) * 0.17), c + Vector3(cos(a) * 0.09, 0.43, sin(a) * 0.09), 0.02, 0.018, 5)
	return K.asset("IN06_wooden_stools", b, [["box", Vector3(0.02, 0.23, 0.07), Vector3(1.0, 0.46, 0.55)]])


## IN08: ale barrels: three on a timber cradle, one with a tap and a drip bucket.
static func ale_barrels() -> Node3D:
	var b := HK.MB.new(808)
	var oak := K.oak()
	for z in [-0.35, 0.35]:
		b.box(K.oak("weathered"), Vector3(0, 0.1, z), Vector3(1.9, 0.12, 0.12), Basis(), 0.003)
	for i in 3:
		var x := -0.62 + i * 0.62
		b.push(Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), Vector3(x, 0.47, 0)))
		b.lathe(oak, PackedVector2Array([Vector2(0.0005, -0.42), Vector2(0.25, -0.42), Vector2(0.31, 0.0), Vector2(0.25, 0.42), Vector2(0.0005, 0.42)]), 12, true)
		for hy in [-0.3, 0.3]:
			b.cyl(K.iron(), Vector3(0, hy - 0.02, 0), Vector3(0, hy + 0.02, 0), 0.295, 0.295, 12, 0.0, false)
		b.pop()
	b.cyl(K.oak(), Vector3(0, 0.38, 0.42), Vector3(0, 0.38, 0.55), 0.025, 0.02, 6)
	b.lathe(oak, PackedVector2Array([Vector2(0.0005, 0.0), Vector2(0.1, 0.0), Vector2(0.11, 0.14), Vector2(0.1, 0.14), Vector2(0.0005, 0.01)]), 10)
	return K.asset("IN08_ale_barrels", b, [["box", Vector3(0, 0.45, 0), Vector3(1.9, 0.9, 0.85)]])


## IN09: wooden drinking mugs, a few together.
static func mugs() -> Node3D:
	var b := HK.MB.new(809)
	for c in [Vector3(0, 0, 0), Vector3(0.12, 0, 0.05), Vector3(-0.05, 0, 0.13)]:
		_mug(b, c)
	return K.asset("IN09_wooden_mugs", b, [])


## IN10: ceramic tankards: tall clay tankards with handles.
static func tankards() -> Node3D:
	var b := HK.MB.new(810)
	for c in [Vector3(0, 0, 0), Vector3(0.14, 0, 0.04)]:
		b.push(Transform3D(Basis(), c))
		b.lathe(K.clay(), PackedVector2Array([Vector2(0.0005, 0.0), Vector2(0.05, 0.0), Vector2(0.045, 0.17), Vector2(0.038, 0.17), Vector2(0.038, 0.015), Vector2(0.0005, 0.015)]), 10)
		b.pop()
		b.box(K.clay(), c + Vector3(0.06, 0.09, 0), Vector3(0.02, 0.1, 0.02), Basis(), 0.0)
	return K.asset("IN10_ceramic_tankards", b, [])


## IN11: cooking pot: an iron cauldron hung from a tripod.
static func cooking_pot() -> Node3D:
	var b := HK.MB.new(811)
	var top := Vector3(0, 1.4, 0)
	for i in 3:
		var a := TAU * i / 3.0 + 0.3
		b.cyl(K.oak("weathered"), Vector3(cos(a) * 0.7, 0, sin(a) * 0.7), top + Vector3(cos(a) * 0.05, 0.1, sin(a) * 0.05), 0.035, 0.03, 6)
	K.ring(b, K.rope(), top, Vector3.UP, 0.07, 0.015, 8, 4)
	for i in 6:
		K.ring(b, K.iron(), top + Vector3(0, -0.08 - i * 0.07, 0), Vector3(1, 0, 0) if i % 2 else Vector3(0, 0, 1), 0.03, 0.006, 6, 3)
	b.push(Transform3D(Basis(), Vector3(0, 0.38, 0)))
	b.lathe(K.iron(), PackedVector2Array([Vector2(0.0005, 0.0), Vector2(0.14, 0.02), Vector2(0.24, 0.16), Vector2(0.22, 0.32), Vector2(0.2, 0.32), Vector2(0.0005, 0.22)]), 12, true)
	b.pop()
	K.ring(b, K.iron(), Vector3(0, 0.72, 0), Vector3(1, 0, 0), 0.2, 0.008, 10, 3)
	return K.asset("IN11_cooking_pot", b, [["cyl", Vector3(0, 0.55, 0), 0.3, 1.1]])


## IN13: firewood basket: a wicker basket of split logs by the hearth.
static func firewood_basket() -> Node3D:
	var b := HK.MB.new(813)
	MK.basket(b, Vector3.ZERO, 0.3, 0.34)
	for i in 6:
		var a := i * 1.1
		b.cyl(K.oak("weathered"), Vector3(cos(a) * 0.12, 0.2, sin(a) * 0.12 - 0.12), Vector3(cos(a) * 0.12 + 0.04, 0.5, sin(a) * 0.12 + 0.12), 0.045, 0.045, 5)
	return K.asset("IN13_firewood_basket", b, [])


static func _bed(b: HK.MB) -> void:
	var oak := K.oak()
	for x in [-0.95, 0.95]:
		for z in [-0.42, 0.42]:
			b.box(oak, Vector3(x, 0.25 if x < 0.0 else 0.45, z), Vector3(0.08, 0.5 if x < 0.0 else 0.9, 0.08), Basis(), 0.003)
	for z in [-0.42, 0.42]:
		b.box(oak, Vector3(0, 0.28, z), Vector3(1.95, 0.12, 0.05), Basis(), 0.003)
	b.box(oak, Vector3(0.95, 0.65, 0), Vector3(0.05, 0.3, 0.84), Basis(), 0.003)
	b.box(K.straw(), Vector3(0, 0.4, 0), Vector3(1.85, 0.14, 0.8), Basis(), 0.03)


## IN16: bed with a straw mattress: an oak frame with a headboard.
static func bed() -> Node3D:
	var b := HK.MB.new(816)
	_bed(b)
	return K.asset("IN16_bed_straw_mattress", b, [["box", Vector3(0, 0.3, 0), Vector3(2.0, 0.6, 0.9)]])


## IN17: bed made up with linen: the same bed with a sheet, a wool blanket and a bolster.
static func bed_linen() -> Node3D:
	var b := HK.MB.new(817)
	_bed(b)
	b.box(K.linen(), Vector3(-0.05, 0.48, 0), Vector3(1.8, 0.03, 0.84), Basis(), 0.01)
	b.box(K.cloth("blanket_brown", Color(0.55, 0.45, 0.32)), Vector3(-0.3, 0.5, 0), Vector3(1.3, 0.04, 0.88), Basis(), 0.012)
	b.blob(K.linen(), Vector3(0.78, 0.53, 0), Vector3(0.12, 0.06, 0.34), 817, 0.1, 1.5, 4, 8)
	return K.asset("IN17_bed_linen_bedding", b, [["box", Vector3(0, 0.3, 0), Vector3(2.0, 0.6, 0.9)]])


## IN18: wall shelves: two planks on iron brackets with jugs and bowls. Origin: on the wall.
static func wall_shelves() -> Node3D:
	var b := HK.MB.new(818)
	for y in [1.3, 1.7]:
		b.box(K.oak(), Vector3(0, y, 0.13), Vector3(1.2, 0.04, 0.26), Basis(), 0.003)
		for x in [-0.45, 0.45]:
			b.box(K.iron(), Vector3(x, y - 0.08, 0.08), Vector3(0.02, 0.14, 0.14))
	MK.pot(b, Vector3(-0.35, 1.32, 0.13), 0.22, 0.08, true, 8)
	MK.bowl(b, Vector3(0.0, 1.32, 0.13), 0.09)
	MK.bowl(b, Vector3(0.0, 1.35, 0.13), 0.09)
	MK.pot(b, Vector3(0.35, 1.72, 0.13), 0.2, 0.08, false, 8)
	_mug(b, Vector3(-0.2, 1.72, 0.13))
	return K.asset("IN18_wall_shelves", b, [])


## IN19: hanging herbs: bundles drying on a pole on cords. Origin: the pole's centre at 2.2 m.
static func hanging_herbs() -> Node3D:
	var b := HK.MB.new(819)
	b.cyl(K.oak("weathered"), Vector3(-0.7, 2.2, 0), Vector3(0.7, 2.2, 0), 0.025, 0.025, 6)
	var greens := [K.goods("herb_green", Color(0.3, 0.38, 0.2)), K.goods("herb_dry", Color(0.45, 0.4, 0.24)), K.goods("herb_purple", Color(0.38, 0.3, 0.38))]
	for i in 6:
		var x := -0.55 + i * 0.22
		b.cyl(K.rope(), Vector3(x, 2.2, 0), Vector3(x, 2.05, 0), 0.004, 0.004, 3)
		b.blob(greens[i % 3], Vector3(x, 1.94, 0), Vector3(0.06, 0.13, 0.06), 819 + i, 0.4, 3.0, 5, 8)
	return K.asset("IN19_hanging_herbs", b, [])


## IN20: tavern notice board: a board on two posts under a little shingled roof, notices pinned.
static func notice_board() -> Node3D:
	var b := HK.MB.new(820)
	var oak := K.oak("weathered")
	for x in [-0.7, 0.7]:
		b.box(oak, Vector3(x, 1.1, 0), Vector3(0.1, 2.2, 0.1), Basis(), 0.005)
	b.box(oak, Vector3(0, 1.45, 0.02), Vector3(1.3, 0.9, 0.04), Basis(), 0.003)
	b.quad(K.shingles(), Vector3(-0.85, 2.3, -0.2), Vector3(0.85, 2.3, -0.2), Vector3(0.85, 2.15, 0.3), Vector3(-0.85, 2.15, 0.3), Vector3(0, 1, 0.3))
	b.quad(oak, Vector3(-0.85, 2.27, -0.2), Vector3(0.85, 2.27, -0.2), Vector3(0.85, 2.12, 0.3), Vector3(-0.85, 2.12, 0.3), Vector3(0, -1, -0.3))
	var rng := RandomNumberGenerator.new()
	rng.seed = 820
	for i in 5:
		var c := Vector3(-0.45 + (i % 3) * 0.45 + rng.randf_range(-0.05, 0.05), 1.7 - (i / 3) * 0.45, 0.045)
		var tilt := Basis(Vector3(0, 0, 1), rng.randf_range(-0.12, 0.12))
		K.face(b, K.parchment(), c + tilt * Vector3(-0.14, 0.18, 0), c + tilt * Vector3(0.14, 0.18, 0), c + tilt * Vector3(0.14, -0.18, 0), c + tilt * Vector3(-0.14, -0.18, 0), Vector3(0, 0, 1))
		K.knob(b, K.iron(), c + Vector3(0, 0.15, 0.005), 0.01, 5)
	return K.asset("IN20_tavern_notice_board", b, [["box", Vector3(0, 1.1, 0), Vector3(1.5, 2.2, 0.14)]])
