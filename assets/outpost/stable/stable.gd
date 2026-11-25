extends RefCounted
## Stable and horse props, ST03-ST25 (see assets/outpost/MANIFEST.md). ST01/ST02 are the B03 stable.
## Real-world size (horses and grooms). Origins: centre of the base on y = 0; the front faces +Z.
## The fence, gate and hay pieces are shared with the cottages and the open country (ENV20-ENV22).

const HK := preload("res://assets/hideout/Materials/kit.gd")
const K := preload("res://assets/outpost/materials/outpost_kit.gd")
const MK := preload("res://assets/outpost/market/market.gd")
const CR := preload("res://assets/outpost/carpenter/carpenter.gd")


static func manure() -> Material: return K.goods("manure", Color(0.24, 0.17, 0.1), 0.9)
static func grain() -> Material: return K.goods("grain", Color(0.7, 0.58, 0.36), 1.0)


## A post-and-rail fence section along x, length l: two posts and three rails (also ENV20).
static func rail_fence(b: HK.MB, l: float, h := 1.3) -> void:
	var oak := K.oak("weathered")
	for x in [-l * 0.5, l * 0.5]:
		b.box(oak, Vector3(x, h * 0.5, 0), Vector3(0.13, h, 0.13), Basis(Vector3.UP, 0.2), 0.008)
	for i in 3:
		var y := 0.35 + i * (h - 0.45) / 2.0
		b.cyl(oak, Vector3(-l * 0.5 - 0.08, y, 0.06), Vector3(l * 0.5 + 0.08, y + 0.03 * (i - 1), 0.06), 0.045, 0.04, 6, 0.08)


## ST03: stable doors: a split ("half") door in its frame, the top leaf open.
static func stable_doors() -> Node3D:
	var b := HK.MB.new(703)
	var oak := K.oak("weathered")
	for x in [-0.65, 0.65]:
		b.box(oak, Vector3(x, 1.2, 0), Vector3(0.14, 2.4, 0.14), Basis(), 0.005)
	b.box(oak, Vector3(0, 2.35, 0), Vector3(1.44, 0.14, 0.14), Basis(), 0.005)
	b.box(oak, Vector3(0, 0.62, 0.0), Vector3(1.16, 1.1, 0.05), Basis(), 0.004)
	b.box(oak, Vector3(0, 0.62, 0.035), Vector3(1.0, 0.08, 0.03), Basis(Vector3(0, 0, 1), 0.85), 0.0)
	var hinge := Vector3(-0.58, 1.24, 0.03)
	var hb := Basis(Vector3.UP, -1.6)
	b.box(oak, hinge + hb * Vector3(0.58, 0.5, 0), Vector3(1.16, 1.0, 0.05), hb, 0.004)
	for y in [0.3, 0.95]:
		b.box(K.iron(), Vector3(-0.3, y, 0.03), Vector3(0.6, 0.05, 0.01))
	return K.asset("ST03_stable_doors", b, [["box", Vector3(0, 0.62, 0), Vector3(1.44, 1.24, 0.14)]])


## ST04: rectangular hay bales, stacked three and one.
static func hay_bales() -> Node3D:
	var b := HK.MB.new(704)
	var bales := [Vector3(-0.32, 0.22, 0), Vector3(0.32, 0.22, 0.04), Vector3(0, 0.66, 0.02), Vector3(0.95, 0.22, 0.5)]
	for i in bales.size():
		b.box(K.straw(), bales[i], Vector3(0.6, 0.44, 0.95), Basis(Vector3.UP, 0.08 * (i - 1.5)), 0.03)
		for dz in [-0.25, 0.25]:
			K.ring(b, K.rope(), bales[i] + Vector3(0, 0, dz), Vector3(0, 0, 1), 0.36, 0.006, 4, 3)
	return K.asset("ST04_rectangular_hay_bales", b, [["box", Vector3(0.2, 0.44, 0.2), Vector3(1.6, 0.88, 1.4)]])


## ST05: loose hay piles.
static func hay_piles() -> Node3D:
	var b := HK.MB.new(705)
	b.blob(K.straw(), Vector3(0, 0, 0), Vector3(0.7, 0.4, 0.55), 705, 0.35, 2.0, 6, 12, Basis(), false, 0.0)
	b.blob(K.straw(), Vector3(0.7, 0, 0.3), Vector3(0.4, 0.22, 0.35), 706, 0.35, 2.0, 5, 10, Basis(), false, 0.0)
	return K.asset("ST05_loose_hay_piles", b, [])


## ST06: hay rack: a slatted rack on a wall bracket, full of hay. Origin: on the wall, facing +Z.
static func hay_rack() -> Node3D:
	var b := HK.MB.new(706)
	var oak := K.oak("weathered")
	b.box(oak, Vector3(0, 1.6, 0.05), Vector3(1.6, 0.08, 0.1), Basis(), 0.003)
	b.box(oak, Vector3(0, 1.0, 0.35), Vector3(1.6, 0.06, 0.06), Basis(), 0.003)
	for i in 12:
		var x := -0.72 + i * 0.13
		b.box(oak, Vector3(x, 1.3, 0.2), Vector3(0.03, 0.66, 0.03), Basis(Vector3(1, 0, 0), 0.45), 0.0)
	b.blob(K.straw(), Vector3(0, 1.35, 0.2), Vector3(0.75, 0.3, 0.16), 707, 0.4, 2.2, 5, 10)
	return K.asset("ST06_hay_rack", b, [])


## ST07: wooden feeding trough on short legs, grain in the bottom (also CO14).
static func feed_trough() -> Node3D:
	var b := HK.MB.new(707)
	var oak := K.oak("weathered")
	b.box(oak, Vector3(0, 0.35, 0), Vector3(1.6, 0.05, 0.4), Basis(), 0.003)
	for s in [-1.0, 1.0]:
		b.box(oak, Vector3(0, 0.5, s * 0.2), Vector3(1.6, 0.3, 0.04), Basis(Vector3(1, 0, 0), s * 0.2), 0.003)
		b.box(oak, Vector3(s * 0.8, 0.5, 0), Vector3(0.04, 0.3, 0.46), Basis(), 0.003)
		for z in [-0.15, 0.15]:
			b.box(oak, Vector3(s * 0.65, 0.17, z), Vector3(0.07, 0.35, 0.07), Basis(), 0.003)
	b.box(grain(), Vector3(0, 0.4, 0), Vector3(1.5, 0.06, 0.36), Basis(), 0.01)
	return K.asset("ST07_wooden_feeding_trough", b, [["box", Vector3(0, 0.35, 0), Vector3(1.6, 0.7, 0.5)]])


## ST08: water trough: a hollowed limestone trough full of water.
static func water_trough() -> Node3D:
	var b := HK.MB.new(708)
	var s := K.limestone()
	b.box(s, Vector3(0, 0.08, 0), Vector3(1.8, 0.16, 0.7), Basis(), 0.01)
	for z in [-0.3, 0.3]:
		b.box(s, Vector3(0, 0.36, z), Vector3(1.8, 0.4, 0.1), Basis(), 0.01)
	for x in [-0.85, 0.85]:
		b.box(s, Vector3(x, 0.36, 0), Vector3(0.1, 0.4, 0.7), Basis(), 0.01)
	b.box(HK.water(), Vector3(0, 0.46, 0), Vector3(1.6, 0.01, 0.5))
	return K.asset("ST08_water_trough", b, [["box", Vector3(0, 0.28, 0), Vector3(1.8, 0.56, 0.7)]])


## ST11: feed baskets: two wicker baskets of grain.
static func feed_baskets() -> Node3D:
	var b := HK.MB.new(711)
	for c in [Vector3(-0.2, 0, 0), Vector3(0.25, 0, 0.12)]:
		MK.basket(b, c, 0.22, 0.28)
		b.disc(grain(), 0.24, 0.2, 12, true, c.x, c.z)
	return K.asset("ST11_feed_baskets", b, [])


## ST12: hitching post: two posts and a rail with iron tie rings.
static func hitching_post() -> Node3D:
	var b := HK.MB.new(712)
	var oak := K.oak("weathered")
	for x in [-1.1, 1.1]:
		b.box(oak, Vector3(x, 0.55, 0), Vector3(0.16, 1.1, 0.16), Basis(), 0.008)
	b.cyl(oak, Vector3(-1.25, 1.0, 0), Vector3(1.25, 1.0, 0), 0.06, 0.06, 7, 0.06)
	for x in [-0.6, 0.0, 0.6]:
		K.ring(b, K.iron(), Vector3(x, 0.92, 0.06), Vector3(0, 0, 1), 0.05, 0.008, 8, 4)
	return K.asset("ST12_hitching_post", b, [["box", Vector3(0, 0.55, 0), Vector3(2.4, 1.1, 0.2)]])


## ST13: horse fence section, 3 m post-and-rail (also ENV20).
static func fence_section() -> Node3D:
	var b := HK.MB.new(713)
	rail_fence(b, 3.0)
	return K.asset("ST13_horse_fence_section", b, [["box", Vector3(0, 0.65, 0.03), Vector3(3.0, 1.3, 0.16)]])


## ST14: stable gate: a framed, braced gate hung on a post, 3 m (also ENV22).
static func stable_gate() -> Node3D:
	var b := HK.MB.new(714)
	var oak := K.oak("weathered")
	b.box(oak, Vector3(-1.55, 0.75, 0), Vector3(0.16, 1.5, 0.16), Basis(), 0.008)
	b.box(oak, Vector3(1.55, 0.7, 0), Vector3(0.14, 1.4, 0.14), Basis(), 0.008)
	for y in [0.3, 0.75, 1.2]:
		b.box(oak, Vector3(0, y, 0.08), Vector3(2.9, 0.09, 0.05), Basis(), 0.003)
	for x in [-1.38, 1.38]:
		b.box(oak, Vector3(x, 0.75, 0.08), Vector3(0.09, 1.0, 0.05), Basis(), 0.003)
	CR._beam(b, oak, Vector3(-1.3, 0.3, 0.11), Vector3(1.3, 1.2, 0.11), 0.07, 0.04)
	for y in [0.3, 1.2]:
		b.box(K.iron(), Vector3(-1.42, y, 0.09), Vector3(0.22, 0.04, 0.06))
	return K.asset("ST14_stable_gate", b, [["box", Vector3(0, 0.7, 0.05), Vector3(3.2, 1.4, 0.18)]])


## The saddle shape: seat, pommel, cantle, skirts, girth and stirrups, sitting on a rail at top.
static func _saddle(b: HK.MB, top: Vector3) -> void:
	var lth := K.leather()
	b.blob(lth, top + Vector3(0, 0.03, 0), Vector3(0.22, 0.06, 0.26), 15, 0.08, 1.2, 4, 10)
	b.blob(lth, top + Vector3(0, 0.08, 0.2), Vector3(0.1, 0.07, 0.06), 16, 0.1, 1.2, 4, 8)
	b.blob(lth, top + Vector3(0, 0.1, -0.22), Vector3(0.16, 0.08, 0.05), 17, 0.1, 1.2, 4, 8)
	for s in [-1.0, 1.0]:
		b.box(lth, top + Vector3(s * 0.2, -0.17, 0.0), Vector3(0.02, 0.34, 0.42), Basis(Vector3(0, 0, 1), s * 0.3), 0.004)
		b.cyl(lth, top + Vector3(s * 0.2, -0.05, 0.08), top + Vector3(s * 0.24, -0.5, 0.08), 0.008, 0.008, 3)
		K.ring(b, K.iron(), top + Vector3(s * 0.24, -0.55, 0.08), Vector3(1, 0, 0), 0.06, 0.008, 8, 3)
	b.box(K.cloth("woad", Color(0.32, 0.38, 0.55)), top + Vector3(0, -0.04, 0), Vector3(0.5, 0.02, 0.62), Basis(), 0.004)


## ST15: saddle rack: a timber A-frame stand with a saddle on it.
static func saddle_rack() -> Node3D:
	var b := HK.MB.new(715)
	var oak := K.oak("weathered")
	for z in [-0.4, 0.4]:
		CR._beam(b, oak, Vector3(-0.35, 0, z), Vector3(0, 0.95, z), 0.07)
		CR._beam(b, oak, Vector3(0.35, 0, z), Vector3(0, 0.95, z), 0.07)
	b.box(oak, Vector3(0, 0.97, 0), Vector3(0.1, 0.08, 0.95), Basis(), 0.003)
	_saddle(b, Vector3(0, 1.05, 0))
	return K.asset("ST15_saddle_rack", b, [["box", Vector3(0, 0.6, 0), Vector3(0.8, 1.2, 0.95)]])


## ST16: a saddle on its own, set down on its front edge on the ground.
static func saddle() -> Node3D:
	var b := HK.MB.new(716)
	b.push(Transform3D(Basis(Vector3(1, 0, 0), 1.2), Vector3(0, 0.3, 0)))
	_saddle(b, Vector3.ZERO)
	b.pop()
	return K.asset("ST16_saddle", b, [])


## ST17: horse blankets: two woollen blankets folded over a rail.
static func horse_blankets() -> Node3D:
	var b := HK.MB.new(717)
	MK.rail(b, 1.6, 1.3)
	for i in 2:
		var m := K.cloth("blanket_red", Color(0.6, 0.22, 0.2)) if i == 0 else K.cloth("blanket_brown", Color(0.55, 0.45, 0.32))
		for s in [-1.0, 1.0]:
			b.push(Transform3D(Basis(Vector3(1, 0, 0), s * 0.25), Vector3(-0.38 + i * 0.76, 1.27, s * 0.03)))
			K.banner(b, m, 0.62, 0.75, "straight", i * 2 + int(s > 0), 2.0, 6, 6)
			b.pop()
	return K.asset("ST17_horse_blankets", b, MK._rail_cols(1.6, 1.3))


## ST18: bridles and reins hanging from wall pegs. Origin: on the wall, facing +Z.
static func bridles() -> Node3D:
	var b := HK.MB.new(718)
	b.box(K.oak("weathered"), Vector3(0, 1.6, 0.02), Vector3(0.9, 0.12, 0.04), Basis(), 0.003)
	for i in 3:
		var x := -0.3 + i * 0.3
		b.cyl(K.oak(), Vector3(x, 1.6, 0.04), Vector3(x, 1.62, 0.14), 0.014, 0.014, 4)
		K.ring(b, K.leather(), Vector3(x, 1.42, 0.12), Vector3(0, 0, 1), 0.14, 0.01, 10, 3)
		K.ring(b, K.leather(), Vector3(x, 1.2, 0.12), Vector3(0, 0, 1), 0.28, 0.008, 12, 3)
		b.box(K.iron(), Vector3(x, 1.27, 0.13), Vector3(0.12, 0.012, 0.012))
	return K.asset("ST18_bridles_and_reins", b, [])


## ST20: farrier's tool box: an open tote with nippers, a rasp, a hammer and nails.
static func farrier_tools() -> Node3D:
	var b := HK.MB.new(720)
	var oak := K.oak("weathered")
	b.box(oak, Vector3(0, 0.02, 0), Vector3(0.6, 0.04, 0.3), Basis(), 0.002)
	for s in [-1.0, 1.0]:
		b.box(oak, Vector3(0, 0.09, s * 0.15), Vector3(0.6, 0.14, 0.02), Basis(), 0.002)
		b.box(oak, Vector3(s * 0.3, 0.17, 0), Vector3(0.02, 0.3, 0.32), Basis(), 0.002)
	b.cyl(oak, Vector3(-0.3, 0.3, 0), Vector3(0.3, 0.3, 0), 0.016, 0.016, 5)
	b.box(K.iron(), Vector3(-0.1, 0.12, 0.05), Vector3(0.35, 0.02, 0.04), Basis(Vector3(0, 0, 1), 0.3))
	b.cyl(K.oak(), Vector3(0.1, 0.06, -0.06), Vector3(0.12, 0.25, -0.02), 0.012, 0.012, 4)
	b.box(K.iron(), Vector3(0.12, 0.26, -0.02), Vector3(0.12, 0.03, 0.03))
	return K.asset("ST20_farrier_tool_box", b, [])


## ST21: manure pile with straw in it.
static func manure_pile() -> Node3D:
	var b := HK.MB.new(721)
	b.blob(manure(), Vector3.ZERO, Vector3(0.8, 0.45, 0.6), 721, 0.35, 2.0, 6, 12, Basis(), false, 0.0)
	b.blob(K.straw(), Vector3(0.3, 0.05, 0.2), Vector3(0.4, 0.15, 0.3), 722, 0.4, 2.0, 4, 8, Basis(), false, 0.0)
	return K.asset("ST21_manure_pile", b, [["box", Vector3(0, 0.2, 0), Vector3(1.5, 0.4, 1.1)]])


## ST22: manure cart: the two-wheeled cart loaded with muck and straw.
static func manure_cart() -> Node3D:
	var b := HK.MB.new(722)
	var y := CR.cart(b, 1.0, 1.5, 0.45, 0.32)
	b.blob(manure(), Vector3(0, y, 0), Vector3(0.45, 0.32, 0.68), 723, 0.3, 2.0, 5, 10, Basis(), false, 0.0)
	b.blob(K.straw(), Vector3(0.1, y + 0.2, 0.2), Vector3(0.3, 0.1, 0.3), 724, 0.4, 2.0, 4, 8)
	return K.asset("ST22_manure_cart", b, [["box", Vector3(0, 0.45, 0), Vector3(1.4, 0.95, 1.6)]])


## ST23: wheelbarrow: a plank tray on one wheel, two handles and legs.
static func wheelbarrow() -> Node3D:
	var b := HK.MB.new(723)
	var oak := K.oak("weathered")
	CR.wheel(b, Vector3(0, 0.22, 0.65), 0.22, Vector3(1, 0, 0), 8)
	for s in [-1.0, 1.0]:
		CR._beam(b, oak, Vector3(s * 0.08, 0.24, 0.66), Vector3(s * 0.3, 0.55, -0.75), 0.05)
		b.box(oak, Vector3(s * 0.24, 0.2, -0.3), Vector3(0.05, 0.4, 0.05), Basis(), 0.002)
	b.box(oak, Vector3(0, 0.42, 0.0), Vector3(0.5, 0.04, 0.7), Basis(Vector3(1, 0, 0), -0.12), 0.002)
	for s in [-1.0, 1.0]:
		b.box(oak, Vector3(s * 0.27, 0.53, 0.0), Vector3(0.03, 0.24, 0.72), Basis(), 0.002)
	b.box(oak, Vector3(0, 0.55, 0.35), Vector3(0.52, 0.26, 0.03), Basis(Vector3(1, 0, 0), 0.3), 0.002)
	return K.asset("ST23_wheelbarrow", b, [["box", Vector3(0, 0.35, 0), Vector3(0.6, 0.7, 1.5)]])


## ST25: grooming equipment: a bucket with brushes and a curry comb beside it.
static func grooming() -> Node3D:
	var b := HK.MB.new(725)
	b.push(Transform3D(Basis(), Vector3.ZERO))
	b.lathe(K.oak(), PackedVector2Array([Vector2(0.0005, 0.0), Vector2(0.13, 0.0), Vector2(0.15, 0.28), Vector2(0.13, 0.28), Vector2(0.11, 0.02), Vector2(0.0005, 0.02)]), 12)
	b.pop()
	for i in 2:
		var p := Vector3(-0.03 + i * 0.07, 0.3, 0.0)
		b.box(K.oak(), p, Vector3(0.06, 0.03, 0.16), Basis(Vector3(1, 0, 0), 0.4), 0.002)
		b.box(K.goods("bristle", Color(0.2, 0.15, 0.1)), p + Vector3(0, -0.02, 0), Vector3(0.05, 0.025, 0.15), Basis(Vector3(1, 0, 0), 0.4))
	b.box(K.iron(), Vector3(0.28, 0.02, 0.05), Vector3(0.12, 0.04, 0.1), Basis(), 0.002)
	b.box(K.leather(), Vector3(0.28, 0.05, 0.05), Vector3(0.1, 0.02, 0.06), Basis(), 0.002)
	return K.asset("ST25_grooming_equipment", b, [])
