extends RefCounted
## Market props, MK01-MK24 (see assets/outpost/MANIFEST.md). Real-world size: goods and
## furniture fit the body. Origins: centre of the base on y = 0; the front faces +Z.
## The small-goods helpers here (baskets, pots, sacks, bowls) are shared with the other props.

const HK := preload("res://assets/hideout/Materials/kit.gd")
const K := preload("res://assets/outpost/materials/outpost_kit.gd")
const CP := preload("res://assets/outpost/castle_approach/castle_approach.gd")


# ---------------------------------------------------------------- shared small goods

static func apple() -> Material: return K.goods("apple", Color(0.52, 0.12, 0.08), 0.6)
static func green_apple() -> Material: return K.goods("green_apple", Color(0.45, 0.5, 0.16), 0.6)
static func turnip() -> Material: return K.goods("turnip", Color(0.78, 0.72, 0.62))
static func cabbage() -> Material: return K.goods("cabbage", Color(0.33, 0.47, 0.22))
static func bread() -> Material: return K.goods("bread", Color(0.6, 0.4, 0.19))
static func fish() -> Material: return K.goods("fish", Color(0.5, 0.53, 0.55), 0.4)
static func meat() -> Material: return K.goods("meat", Color(0.48, 0.16, 0.13), 0.6)
static func fat() -> Material: return K.goods("fat", Color(0.82, 0.72, 0.6), 0.6)
static func coal() -> Material: return K.goods("coal", Color(0.06, 0.055, 0.05), 0.7)
static func burlap() -> Material: return K.cloth("burlap", Color(0.72, 0.6, 0.42))


## A wicker basket at c: tapering sides, a rim, a floor; open at the top.
static func basket(b: HK.MB, c: Vector3, r: float, h: float) -> void:
	b.push(Transform3D(Basis(), c))
	b.lathe(K.wicker(), PackedVector2Array([Vector2(0.0005, 0.0), Vector2(r * 0.75, 0.0), Vector2(r, h)]), 14)
	b.lathe(K.wicker(), PackedVector2Array([Vector2(r - 0.015, h), Vector2(r * 0.75 - 0.015, 0.02), Vector2(0.0005, 0.02)]), 14)
	b.pop()
	K.ring(b, K.wicker(), c + Vector3(0, h, 0), Vector3.UP, r - 0.005, 0.014, 14, 5)


## A heap of small round goods filling a basket of radius r up to height y.
static func heap(b: HK.MB, c: Vector3, r: float, y: float, m: Material, n: int, size: float, seed_: int, stretch := Vector3.ONE) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	for i in n:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * r * 0.78
		var p := c + Vector3(cos(a) * d, y + rng.randf() * size * 0.8 - (d / r) * size * 0.6, sin(a) * d)
		b.blob(m, p, stretch * size * rng.randf_range(0.85, 1.15), seed_ + i, 0.12, 1.5, 4, 7, Basis(Vector3.UP, rng.randf() * TAU))


## A clay pot (or jug) at c: foot, belly, shoulder, neck and lip, dark inside the mouth.
static func pot(b: HK.MB, c: Vector3, h: float, r: float, handle := false, sides := 12) -> void:
	var prof := PackedVector2Array([Vector2(0.0005, 0.0), Vector2(r * 0.55, 0.0), Vector2(r, h * 0.4), Vector2(r * 0.8, h * 0.78),
		Vector2(r * 0.42, h * 0.9), Vector2(r * 0.5, h), Vector2(r * 0.4, h)])
	b.push(Transform3D(Basis(), c))
	b.lathe(K.clay(), prof, sides, true)
	b.disc(K.goods("dark", Color(0.06, 0.04, 0.03)), h * 0.96, r * 0.4, sides)
	b.pop()
	if handle:
		var pts := []
		for i in 6:
			var t := float(i) / 5.0
			pts.append(c + Vector3(r * 0.45 + sin(t * PI) * r * 0.55, h * (0.88 - t * 0.45), 0))
		for i in 5:
			b.cyl(K.clay(), pts[i], pts[i + 1], r * 0.09, r * 0.09, 5)


## A burlap sack at c, tied at the neck. s: overall size (1 = a full grain sack ~0.7 m).
static func sack(b: HK.MB, c: Vector3, s: float, seed_: int, slumped := false) -> void:
	var rad := Vector3(0.26, 0.3 if not slumped else 0.18, 0.22) * s
	b.blob(burlap(), c + Vector3(0, rad.y * 0.9, 0), rad, seed_, 0.18, 1.6, 6, 10, Basis(Vector3.UP, seed_ * 0.7), false, 0.85)
	if not slumped:
		b.cyl(burlap(), c + Vector3(0, rad.y * 1.65, 0), c + Vector3(0, rad.y * 2.0, 0), 0.06 * s, 0.09 * s, 6)
		K.ring(b, K.rope(), c + Vector3(0, rad.y * 1.72, 0), Vector3.UP, 0.065 * s, 0.01, 8, 4)


## A turned wooden bowl at c.
static func bowl(b: HK.MB, c: Vector3, r: float) -> void:
	b.push(Transform3D(Basis(), c))
	b.lathe(K.oak("weathered"), PackedVector2Array([Vector2(0.0005, 0.0), Vector2(r * 0.5, 0.0), Vector2(r, r * 0.55), Vector2(r * 0.9, r * 0.55), Vector2(r * 0.45, r * 0.12), Vector2(0.0005, r * 0.12)]), 12, true)
	b.pop()


## A rail on two posts (meat hooks, cloth bolts, leather goods), 2.1 m high, width w.
static func rail(b: HK.MB, w: float, h := 2.1) -> void:
	var oak := K.oak("weathered")
	for x in [-w * 0.5, w * 0.5]:
		b.box(oak, Vector3(x, h * 0.5, 0), Vector3(0.1, h, 0.1), Basis(), 0.005)
		b.box(oak, Vector3(x, 0.04, 0), Vector3(0.12, 0.08, 0.6), Basis(), 0.004)
	b.box(oak, Vector3(0, h - 0.05, 0), Vector3(w + 0.16, 0.09, 0.09), Basis(), 0.004)


static func _hook(b: HK.MB, top: Vector3) -> Vector3:
	b.cyl(K.iron(), top, top + Vector3(0, -0.16, 0), 0.008, 0.008, 4)
	b.cyl(K.iron(), top + Vector3(0, -0.16, 0), top + Vector3(0, -0.12, 0.05), 0.008, 0.008, 4)
	return top + Vector3(0, -0.16, 0)


static func _rail_cols(w: float, h := 2.1) -> Array:
	return [["box", Vector3(-w * 0.5, h * 0.5, 0), Vector3(0.12, h, 0.12)], ["box", Vector3(w * 0.5, h * 0.5, 0), Vector3(0.12, h, 0.12)]]


# ---------------------------------------------------------------- MK02-MK05: stalls and fittings

## MK02: plain canvas awning (the WK08 awning in undyed linen).
static func canvas_awning() -> Node3D:
	return preload("res://assets/outpost/white_knights/white_knights.gd").market_awning(K.linen())


## MK04: merchant table, a trestle table 1.8 m long, top at 0.8 m.
static func merchant_table() -> Node3D:
	var b := HK.MB.new(404)
	CP._trestle(b, 1.8, 0.8, 0.8)
	return K.asset("MK04_merchant_table", b, [["box", Vector3(0, 0.4, 0), Vector3(1.8, 0.8, 0.8)]])


static func _shelves(b: HK.MB) -> void:
	var oak := K.oak("weathered")
	for x in [-0.78, 0.78]:
		b.box(oak, Vector3(x, 0.75, -0.25), Vector3(0.07, 1.5, 0.07), Basis(), 0.004)
		b.box(oak, Vector3(x, 0.35, 0.2), Vector3(0.07, 0.7, 0.07), Basis(), 0.004)
	for i in 3:
		var y := 0.38 + i * 0.45
		var z := 0.15 - i * 0.18
		b.box(oak, Vector3(0, y, z), Vector3(1.6, 0.04, 0.3), Basis(), 0.004)


## MK05: display shelves: three stepped boards, 1.6 m wide, 1.5 m high.
static func display_shelves() -> Node3D:
	var b := HK.MB.new(405)
	_shelves(b)
	return K.asset("MK05_display_shelves", b, [["box", Vector3(0, 0.75, -0.02), Vector3(1.65, 1.5, 0.6)]])


# ---------------------------------------------------------------- MK06-MK12: food

## MK06: fruit basket: red and green apples heaped in wicker.
static func fruit_basket() -> Node3D:
	var b := HK.MB.new(406)
	basket(b, Vector3.ZERO, 0.26, 0.24)
	heap(b, Vector3.ZERO, 0.26, 0.24, apple(), 12, 0.045, 61)
	heap(b, Vector3.ZERO, 0.26, 0.25, green_apple(), 6, 0.045, 62)
	return K.asset("MK06_fruit_basket", b, [])


## MK07: vegetable basket: turnips and a couple of cabbages.
static func vegetable_basket() -> Node3D:
	var b := HK.MB.new(407)
	basket(b, Vector3.ZERO, 0.3, 0.26)
	heap(b, Vector3.ZERO, 0.3, 0.25, turnip(), 9, 0.06, 71, Vector3(1, 0.9, 1))
	heap(b, Vector3.ZERO, 0.22, 0.3, cabbage(), 3, 0.1, 72)
	return K.asset("MK07_vegetable_basket", b, [])


## MK08: grain sacks: three tied burlap sacks and one slumped open.
static func grain_sacks() -> Node3D:
	var b := HK.MB.new(408)
	sack(b, Vector3(-0.3, 0, 0), 1.0, 81)
	sack(b, Vector3(0.28, 0, -0.08), 0.95, 82)
	sack(b, Vector3(0.0, 0, 0.42), 0.9, 83, true)
	return K.asset("MK08_grain_sacks", b, [["box", Vector3(0, 0.3, 0.1), Vector3(1.1, 0.6, 0.9)]])


## MK09: bread basket: a wide shallow basket of loaves.
static func bread_basket() -> Node3D:
	var b := HK.MB.new(409)
	basket(b, Vector3.ZERO, 0.34, 0.14)
	heap(b, Vector3.ZERO, 0.34, 0.15, bread(), 6, 0.07, 91, Vector3(1.5, 0.7, 0.9))
	return K.asset("MK09_bread_basket", b, [])


## MK10: meat hooks: a rail on two posts with six iron hooks.
static func meat_hooks() -> Node3D:
	var b := HK.MB.new(410)
	rail(b, 1.6)
	for i in 6:
		_hook(b, Vector3(-0.65 + i * 0.26, 2.0, 0))
	return K.asset("MK10_meat_hooks", b, _rail_cols(1.6))


## MK11: hanging meat: the hook rail with hams and sides of meat hanging.
static func hanging_meat() -> Node3D:
	var b := HK.MB.new(411)
	rail(b, 1.6)
	for i in 5:
		var tip := _hook(b, Vector3(-0.6 + i * 0.3, 2.0, 0))
		var big := i % 2 == 0
		var size := Vector3(0.11, 0.24, 0.08) if big else Vector3(0.09, 0.17, 0.07)
		b.blob(meat(), tip + Vector3(0, -size.y, 0), size, 110 + i, 0.2, 1.5, 6, 9)
		b.blob(fat(), tip + Vector3(0, -size.y * 0.5, 0.02), size * Vector3(0.9, 0.4, 0.9), 120 + i, 0.2, 1.5, 4, 8)
	return K.asset("MK11_hanging_meat", b, _rail_cols(1.6))


## MK12: fish basket: a long basket of grey fish.
static func fish_basket() -> Node3D:
	var b := HK.MB.new(412)
	basket(b, Vector3.ZERO, 0.3, 0.2)
	heap(b, Vector3.ZERO, 0.3, 0.2, fish(), 9, 0.05, 121, Vector3(3.2, 0.7, 1.0))
	return K.asset("MK12_fish_basket", b, [])


# ---------------------------------------------------------------- MK13-MK18: wares

## MK13: pottery display: the stepped shelves full of pots and jugs.
static func pottery_display() -> Node3D:
	var b := HK.MB.new(413)
	_shelves(b)
	for i in 3:
		var y := 0.4 + i * 0.45
		var z := 0.15 - i * 0.18
		for j in 4:
			var x := -0.6 + j * 0.4
			if (i + j) % 2 == 0:
				pot(b, Vector3(x, y, z), 0.26 - i * 0.03, 0.1, false, 8)
			else:
				pot(b, Vector3(x, y, z), 0.22, 0.08, true, 8)
	return K.asset("MK13_pottery_display", b, [["box", Vector3(0, 0.75, -0.02), Vector3(1.65, 1.5, 0.6)]])


## MK14: clay pots: a big storage pot and two smaller ones.
static func clay_pots() -> Node3D:
	var b := HK.MB.new(414)
	pot(b, Vector3(0, 0, 0), 0.62, 0.24)
	pot(b, Vector3(0.36, 0, 0.14), 0.36, 0.14)
	pot(b, Vector3(-0.3, 0, 0.22), 0.3, 0.12)
	return K.asset("MK14_clay_pots", b, [["cyl", Vector3(0, 0.31, 0), 0.25, 0.62]])


## MK15: ceramic jugs: two handled jugs.
static func ceramic_jugs() -> Node3D:
	var b := HK.MB.new(415)
	pot(b, Vector3(-0.1, 0, 0), 0.34, 0.11, true)
	pot(b, Vector3(0.14, 0, 0.08), 0.27, 0.09, true)
	return K.asset("MK15_ceramic_jugs", b, [])


## MK16: wooden bowls: a stack of three and one on its own with a spoon.
static func wooden_bowls() -> Node3D:
	var b := HK.MB.new(416)
	for i in 3:
		bowl(b, Vector3(0, i * 0.035, 0), 0.12)
	bowl(b, Vector3(0.26, 0, 0.05), 0.11)
	b.cyl(K.oak("weathered"), Vector3(0.18, 0.07, 0.05), Vector3(0.42, 0.02, 0.1), 0.008, 0.01, 4)
	return K.asset("MK16_wooden_bowls", b, [])


## MK17: weighing scales: a beam balance on a post, two pans on cords.
static func weighing_scales() -> Node3D:
	var b := HK.MB.new(417)
	var oak := K.oak()
	b.box(oak, Vector3(0, 0.02, 0), Vector3(0.36, 0.04, 0.2), Basis(), 0.003)
	b.cyl(oak, Vector3(0, 0.04, 0), Vector3(0, 0.5, 0), 0.02, 0.016, 6)
	b.box(K.iron(), Vector3(0, 0.5, 0), Vector3(0.5, 0.02, 0.02))
	K.knob(b, K.gold(), Vector3(0, 0.53, 0), 0.02, 6)
	for x in [-0.24, 0.24]:
		for dz in [-0.05, 0.05]:
			b.cyl(K.rope(), Vector3(x, 0.5, 0), Vector3(x + dz * 0.5, 0.3, dz), 0.003, 0.003, 3, 0.0, false)
		b.push(Transform3D(Basis(), Vector3(x, 0.28, 0)))
		b.lathe(K.gold(), PackedVector2Array([Vector2(0.0005, 0.0), Vector2(0.06, 0.0), Vector2(0.085, 0.025), Vector2(0.08, 0.026), Vector2(0.0005, 0.004)]), 10)
		b.pop()
	return K.asset("MK17_weighing_scales", b, [])


## MK18: iron weights: five stepped cylinders.
static func iron_weights() -> Node3D:
	var b := HK.MB.new(418)
	var x := 0.0
	for i in 5:
		var r := 0.045 - i * 0.007
		b.cyl(K.iron(), Vector3(x, 0, 0), Vector3(x, r * 1.4, 0), r, r * 0.92, 8)
		K.knob(b, K.iron(), Vector3(x, r * 1.4 + 0.006, 0), 0.008, 5)
		x += r * 2.0 + 0.015
	return K.asset("MK18_iron_weights", b, [])


# ---------------------------------------------------------------- MK19-MK23: cloth, leather, money

static func _dyes() -> Array:
	return [K.cloth("red", Color(0.68, 0.24, 0.22)), K.cloth("woad", Color(0.32, 0.38, 0.55)),
		K.cloth("weld", Color(0.85, 0.75, 0.38)), K.cloth("moss", Color(0.45, 0.52, 0.32)), K.linen()]


## MK19: hanging cloth bolts: lengths of dyed cloth draped over a rail.
static func hanging_cloth() -> Node3D:
	var b := HK.MB.new(419)
	rail(b, 1.8)
	var dyes := _dyes()
	for i in 5:
		b.push(Transform3D(Basis(), Vector3(-0.68 + i * 0.34, 2.06, 0.05)))
		K.banner(b, dyes[i], 0.3, 1.1 + (i % 3) * 0.2, "straight", i, 2.0, 5, 6)
		b.pop()
	return K.asset("MK19_hanging_cloth_bolts", b, _rail_cols(1.8))


## MK20: folded fabric: three stacks of folded dyed cloth.
static func folded_fabric() -> Node3D:
	var b := HK.MB.new(420)
	var dyes := _dyes()
	for s in 3:
		for i in 4:
			var m: Material = dyes[(s * 2 + i) % dyes.size()]
			b.box(m, Vector3(-0.32 + s * 0.32, 0.03 + i * 0.06, 0), Vector3(0.28, 0.055, 0.22), Basis(Vector3.UP, 0.06 * (i % 3) - 0.05), 0.006)
	return K.asset("MK20_folded_fabric", b, [])


## MK21: leather goods display: a rail with belts, pouches and a pair of boots.
static func leather_goods() -> Node3D:
	var b := HK.MB.new(421)
	rail(b, 1.4, 1.8)
	for i in 4:
		var top := Vector3(-0.5 + i * 0.33, 1.75, 0.0)
		if i % 2 == 0:
			b.box(K.leather(), top + Vector3(0, -0.45, 0.04), Vector3(0.05, 0.9, 0.01))
			b.box(K.iron(), top + Vector3(0, -0.88, 0.05), Vector3(0.06, 0.05, 0.012))
		else:
			b.cyl(K.leather(), top, top + Vector3(0, -0.12, 0.04), 0.006, 0.006, 3)
			b.blob(K.leather(), top + Vector3(0, -0.22, 0.04), Vector3(0.09, 0.1, 0.05), 210 + i, 0.15, 1.5, 4, 8)
	for x in [-0.12, 0.12]:
		b.box(K.leather(), Vector3(x, 0.15, 0.25), Vector3(0.1, 0.3, 0.12), Basis(), 0.01)
		b.box(K.leather(), Vector3(x, 0.04, 0.32), Vector3(0.1, 0.08, 0.26), Basis(), 0.01)
	return K.asset("MK21_leather_goods_display", b, _rail_cols(1.4, 1.8))


## MK22: merchant coin chest: a small iron-bound chest, lid open, coins inside.
static func coin_chest() -> Node3D:
	var b := HK.MB.new(422)
	b.box(K.oak(), Vector3(0, 0.12, 0), Vector3(0.46, 0.24, 0.3), Basis(), 0.004)
	for x in [-0.17, 0.17]:
		b.box(K.iron(), Vector3(x, 0.12, 0), Vector3(0.04, 0.25, 0.31))
	b.box(K.goods("dark", Color(0.06, 0.04, 0.03)), Vector3(0, 0.236, 0), Vector3(0.4, 0.01, 0.24))
	heap(b, Vector3(0, 0.0, 0), 0.18, 0.22, K.gold(), 16, 0.022, 221, Vector3(1, 0.35, 1))
	var hinge := Vector3(0, 0.24, -0.15)
	var lb := Basis(Vector3(1, 0, 0), -1.9)
	b.box(K.oak(), hinge + lb * Vector3(0, 0.0, 0.15), Vector3(0.47, 0.05, 0.3), lb, 0.003)
	return K.asset("MK22_merchant_coin_chest", b, [["box", Vector3(0, 0.12, 0), Vector3(0.46, 0.24, 0.3)]])


## MK23: wooden price sign: a board on a stake with a pinned price list.
static func price_sign() -> Node3D:
	var b := HK.MB.new(423)
	b.box(K.oak("weathered"), Vector3(0, 0.55, 0), Vector3(0.05, 1.1, 0.05), Basis(), 0.004)
	var c := Vector3(0, 1.0, 0.03)
	b.box(K.oak("weathered"), c, Vector3(0.42, 0.34, 0.03), Basis(Vector3(0, 0, 1), 0.04), 0.003)
	K.face(b, K.parchment(), c + Vector3(-0.15, 0.13, 0.017), c + Vector3(0.15, 0.13, 0.017), c + Vector3(0.15, -0.13, 0.017), c + Vector3(-0.15, -0.13, 0.017), Vector3(0, 0, 1))
	return K.asset("MK23_wooden_price_sign", b, [])
