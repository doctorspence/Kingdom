extends RefCounted
## Blacksmith props, BS05-BS21 (see assets/outpost/MANIFEST.md). BS01, BS02 and BS20 are built into
## the B02 forge; BS03/BS04 (the anvil on its stump) is in buildings.gd. Real-world size.
## Origins: centre of the base on y = 0; the front faces +Z.

const HK := preload("res://assets/hideout/Materials/kit.gd")
const K := preload("res://assets/outpost/materials/outpost_kit.gd")
const MK := preload("res://assets/outpost/market/market.gd")


## A hammer lying or hanging: handle from a to b, an iron head across b.
static func _hammer(b: HK.MB, a: Vector3, tip: Vector3, head := 0.13) -> void:
	b.cyl(K.oak(), a, tip, 0.014, 0.016, 5)
	var d := (tip - a).normalized()
	var side := d.cross(Vector3.UP)
	if side.length() < 0.1:
		side = d.cross(Vector3.RIGHT)
	b.box(K.iron(), tip, Vector3(head, 0.045, 0.045), HK.basis_x(side.normalized()))


## Tongs: two long iron arms crossing at a rivet near the jaws.
static func _tongs(b: HK.MB, a: Vector3, tip: Vector3) -> void:
	var d := (tip - a)
	var side := d.normalized().cross(Vector3.UP).normalized() * 0.03
	var pivot := a + d * 0.72
	b.cyl(K.iron(), a + side, pivot, 0.007, 0.007, 4)
	b.cyl(K.iron(), a - side, pivot, 0.007, 0.007, 4)
	b.cyl(K.iron(), pivot, tip - side * 0.6, 0.008, 0.006, 4)
	b.cyl(K.iron(), pivot, tip + side * 0.6, 0.008, 0.006, 4)


## A horseshoe lying flat (or tilted by bas) at c: a U of short iron bars.
static func _horseshoe(b: HK.MB, c: Vector3, bas := Basis()) -> void:
	var pts := []
	for i in 8:
		var a := PI * (0.15 + 1.7 * float(i) / 7.0)
		pts.append(c + bas * Vector3(cos(a) * 0.06, 0.008, sin(a) * 0.065))
	for i in 7:
		b.box(K.iron(), (pts[i] + pts[i + 1]) * 0.5, Vector3(pts[i].distance_to(pts[i + 1]) + 0.004, 0.012, 0.022), bas * HK.basis_x(bas.inverse() * (pts[i + 1] - pts[i])))


## A rough sword blade blank: a tapering iron bar with a tang.
static func _blank(b: HK.MB, c: Vector3, yaw: float, l := 0.85) -> void:
	var bas := Basis(Vector3.UP, yaw)
	b.box(K.iron(), c + bas * Vector3(0, 0.006, 0), Vector3(l, 0.01, 0.05), bas)
	b.box(K.iron(), c + bas * Vector3(-l * 0.5 - 0.07, 0.006, 0), Vector3(0.14, 0.012, 0.018), bas)


## A stack of firewood: split logs in rows between two posts, w long.
static func woodstack(b: HK.MB, w: float, rows: int, seed_: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	for x in [-w * 0.5 - 0.06, w * 0.5 + 0.06]:
		b.box(K.oak("weathered"), Vector3(x, rows * 0.06 + 0.1, 0), Vector3(0.07, rows * 0.12 + 0.2, 0.07), Basis(), 0.004)
	for r in rows:
		var n := int(w / 0.13)
		for i in n:
			var x := -w * 0.5 + (i + 0.5) * w / n + (0.03 if r % 2 else 0.0)
			var rad := rng.randf_range(0.05, 0.065)
			b.cyl(K.oak("weathered"), Vector3(x, 0.06 + r * 0.115, -0.25), Vector3(x + rng.randf_range(-0.02, 0.02), 0.06 + r * 0.115, 0.25), rad, rad, 5, 0.12)


## BS05: bellows: two oak boards hinged at a nozzle with a leather bag between, on a stand.
static func bellows() -> Node3D:
	var b := HK.MB.new(505)
	var oak := K.oak()
	b.box(oak, Vector3(0, 0.3, 0), Vector3(0.6, 0.6, 0.4), Basis(), 0.006)
	b.box(oak, Vector3(0, 0.63, 0), Vector3(0.8, 0.05, 0.5), Basis(Vector3(0, 0, 1), 0.1), 0.003)
	b.blob(K.leather(), Vector3(0, 0.7, 0), Vector3(0.4, 0.09, 0.24), 5, 0.15, 1.5, 4, 8)
	b.box(oak, Vector3(0, 0.79, 0), Vector3(0.8, 0.05, 0.5), Basis(Vector3(0, 0, 1), -0.08), 0.003)
	b.cyl(K.iron(), Vector3(0.4, 0.71, 0), Vector3(0.62, 0.69, 0), 0.03, 0.015, 6)
	b.cyl(oak, Vector3(-0.38, 0.8, 0), Vector3(-0.62, 1.0, 0), 0.02, 0.02, 5)
	return K.asset("BS05_bellows", b, [["box", Vector3(0, 0.42, 0), Vector3(0.8, 0.84, 0.5)]])


## BS06: hammers: three smith's hammers lying together.
static func hammers() -> Node3D:
	var b := HK.MB.new(506)
	_hammer(b, Vector3(-0.15, 0.02, 0.15), Vector3(0.15, 0.025, -0.05), 0.13)
	_hammer(b, Vector3(-0.2, 0.02, 0.0), Vector3(0.18, 0.025, 0.12), 0.16)
	_hammer(b, Vector3(-0.1, 0.02, -0.18), Vector3(0.22, 0.025, -0.2), 0.1)
	return K.asset("BS06_hammers", b, [])


## BS07: tongs: two pairs lying crossed.
static func tongs() -> Node3D:
	var b := HK.MB.new(507)
	_tongs(b, Vector3(-0.3, 0.01, 0.05), Vector3(0.3, 0.01, -0.05))
	_tongs(b, Vector3(-0.25, 0.02, -0.15), Vector3(0.28, 0.02, 0.18))
	return K.asset("BS07_tongs", b, [])


## BS08: smith's workbench: a heavy oak bench with a vice, hammers, tongs and a file.
static func workbench() -> Node3D:
	var b := HK.MB.new(508)
	var oak := K.oak()
	b.box(oak, Vector3(0, 0.82, 0), Vector3(1.8, 0.1, 0.7), Basis(), 0.006)
	for x in [-0.8, 0.8]:
		for z in [-0.28, 0.28]:
			b.box(oak, Vector3(x, 0.39, z), Vector3(0.1, 0.78, 0.1), Basis(), 0.004)
	b.box(oak, Vector3(0, 0.18, 0), Vector3(1.6, 0.04, 0.6), Basis(), 0.004)
	b.box(K.iron(), Vector3(0.65, 0.95, 0.3), Vector3(0.18, 0.16, 0.12))
	b.cyl(K.iron(), Vector3(0.65, 0.95, 0.38), Vector3(0.65, 0.95, 0.5), 0.012, 0.012, 5)
	_hammer(b, Vector3(-0.5, 0.89, 0.1), Vector3(-0.2, 0.9, 0.18))
	_tongs(b, Vector3(-0.1, 0.875, -0.15), Vector3(0.4, 0.875, -0.1))
	b.box(K.iron(), Vector3(0.2, 0.88, 0.15), Vector3(0.3, 0.012, 0.025), Basis(Vector3.UP, 0.4))
	return K.asset("BS08_workbench", b, [["box", Vector3(0, 0.44, 0), Vector3(1.8, 0.88, 0.7)]])


## BS09: tool rack: an oak board on legs with pegs; hammers, tongs and a file hang from it.
static func tool_rack() -> Node3D:
	var b := HK.MB.new(509)
	var oak := K.oak("weathered")
	for x in [-0.6, 0.6]:
		b.box(oak, Vector3(x, 0.8, 0), Vector3(0.08, 1.6, 0.08), Basis(), 0.004)
	b.box(oak, Vector3(0, 1.25, 0), Vector3(1.3, 0.5, 0.04), Basis(), 0.004)
	for i in 6:
		var x := -0.5 + i * 0.2
		b.cyl(oak, Vector3(x, 1.4, 0.02), Vector3(x, 1.42, 0.12), 0.012, 0.012, 4)
		if i % 3 == 0:
			_hammer(b, Vector3(x, 1.38, 0.08), Vector3(x, 1.0, 0.08), 0.12)
		elif i % 3 == 1:
			_tongs(b, Vector3(x, 1.4, 0.08), Vector3(x, 0.85, 0.08))
		else:
			b.box(K.iron(), Vector3(x, 1.2, 0.07), Vector3(0.025, 0.36, 0.01))
	return K.asset("BS09_tool_rack", b, [["box", Vector3(0, 0.8, 0), Vector3(1.3, 1.6, 0.15)]])


## BS10: metal ingots: bars of iron stacked crosswise.
static func ingots() -> Node3D:
	var b := HK.MB.new(510)
	for r in 3:
		for i in 3 - r:
			var o := (i - (2 - r) * 0.5) * 0.09
			var bas := Basis(Vector3.UP, PI * 0.5 * (r % 2))
			b.box(K.iron(), bas * Vector3(o, 0.025 + r * 0.05, 0), Vector3(0.07, 0.045, 0.3), bas, 0.004)
	return K.asset("BS10_metal_ingots", b, [])


## BS11: coal basket: a wicker basket heaped with coal.
static func coal_basket() -> Node3D:
	var b := HK.MB.new(511)
	MK.basket(b, Vector3.ZERO, 0.28, 0.3)
	MK.heap(b, Vector3.ZERO, 0.28, 0.29, MK.coal(), 16, 0.05, 511)
	return K.asset("BS11_coal_basket", b, [])


## BS12: coal pile: a heap of coal against the forge, lumps on top.
static func coal_pile() -> Node3D:
	var b := HK.MB.new(512)
	b.blob(MK.coal(), Vector3(0, 0.0, 0), Vector3(0.6, 0.35, 0.45), 512, 0.3, 2.0, 6, 12, Basis(), true, 0.0)
	for i in 10:
		var a := i * 2.3
		b.blob(MK.coal(), Vector3(cos(a) * (0.3 + 0.03 * i), 0.18 - 0.012 * i, sin(a) * 0.25), Vector3(0.06, 0.04, 0.05), 520 + i, 0.3, 2.0, 3, 6)
	return K.asset("BS12_coal_pile", b, [["box", Vector3(0, 0.15, 0), Vector3(1.1, 0.3, 0.8)]])


## BS13: firewood stack: split logs stacked between two posts, 1.4 m long.
static func firewood_stack() -> Node3D:
	var b := HK.MB.new(513)
	woodstack(b, 1.4, 6, 513)
	return K.asset("BS13_firewood_stack", b, [["box", Vector3(0, 0.38, 0), Vector3(1.6, 0.76, 0.55)]])


## An open tub of water (quench barrel, bucket): staves as a lathe, iron hoops, dark water.
static func _tub(b: HK.MB, c: Vector3, h: float, r: float, hoops: Array) -> void:
	b.push(Transform3D(Basis(), c))
	b.lathe(K.oak(), PackedVector2Array([Vector2(0.0005, 0.0), Vector2(r * 0.92, 0.0), Vector2(r, h), Vector2(r - 0.02, h), Vector2(r * 0.9 - 0.02, 0.03), Vector2(0.0005, 0.03)]), 14)
	for t: float in hoops:
		var rr := lerpf(r * 0.92, r, t) + 0.006
		b.cyl(K.iron(), Vector3(0, t * h - 0.018, 0), Vector3(0, t * h + 0.018, 0), rr, rr, 14, 0.0, false)
	b.disc(HK.water(), h * 0.85, r * 0.96 - 0.02, 14)
	b.pop()


## BS14: quenching barrel: a half barrel of dark water, iron-hooped.
static func quench_barrel() -> Node3D:
	var b := HK.MB.new(514)
	_tub(b, Vector3.ZERO, 0.62, 0.34, [0.15, 0.85])
	return K.asset("BS14_quenching_barrel", b, [["cyl", Vector3(0, 0.31, 0), 0.36, 0.62]])


## BS15: water bucket: an oak bucket with iron bands and a rope handle.
static func water_bucket() -> Node3D:
	var b := HK.MB.new(515)
	_tub(b, Vector3.ZERO, 0.3, 0.15, [0.2, 0.8])
	for i in 6:
		var a0 := PI * float(i) / 6.0
		var a1 := PI * float(i + 1) / 6.0
		b.cyl(K.rope(), Vector3(cos(a0) * 0.15, 0.3 + sin(a0) * 0.12, 0), Vector3(cos(a1) * 0.15, 0.3 + sin(a1) * 0.12, 0), 0.008, 0.008, 4)
	return K.asset("BS15_water_bucket", b, [])


## BS16: horseshoes: a handful lying in a heap (also ST19).
static func horseshoes() -> Node3D:
	var b := HK.MB.new(516)
	for i in 6:
		var a := i * 1.9
		_horseshoe(b, Vector3(cos(a) * 0.1 * (i % 3), 0.012 * i, sin(a) * 0.08), Basis(Vector3.UP, a) * Basis(Vector3(1, 0, 0), 0.08 * (i % 2)))
	return K.asset("BS16_horseshoes", b, [])


## BS17: sword blade blanks: rough-forged blades laid side by side.
static func blade_blanks() -> Node3D:
	var b := HK.MB.new(517)
	for i in 4:
		_blank(b, Vector3(0, i * 0.012, -0.12 + i * 0.08), 0.03 * (i - 1.5), 0.8 + 0.05 * (i % 2))
	return K.asset("BS17_sword_blade_blanks", b, [])


## BS18: iron tools: a heap of finished tools: hammer, tongs, chisels, a file, a horseshoe.
static func iron_tools() -> Node3D:
	var b := HK.MB.new(518)
	_hammer(b, Vector3(-0.2, 0.02, 0.1), Vector3(0.1, 0.025, -0.05), 0.12)
	_tongs(b, Vector3(-0.25, 0.04, -0.12), Vector3(0.22, 0.04, -0.02))
	for i in 3:
		b.box(K.iron(), Vector3(0.12 + i * 0.05, 0.06, 0.12), Vector3(0.02, 0.016, 0.2), Basis(Vector3.UP, 0.2 * i), 0.0)
	_horseshoe(b, Vector3(0.25, 0.01, -0.15))
	return K.asset("BS18_iron_tools", b, [])


## BS19: weapon rack: a timber rack with finished swords and an axe, for the smith's customers.
static func weapon_rack() -> Node3D:
	var b := HK.MB.new(519)
	var oak := K.oak("weathered")
	for x in [-0.7, 0.7]:
		b.box(oak, Vector3(x, 0.7, 0), Vector3(0.08, 1.4, 0.08), Basis(), 0.004)
		b.box(oak, Vector3(x, 0.04, 0), Vector3(0.1, 0.08, 0.5), Basis(), 0.004)
	b.box(oak, Vector3(0, 1.2, 0), Vector3(1.5, 0.07, 0.1), Basis(), 0.004)
	b.box(oak, Vector3(0, 0.25, 0.1), Vector3(1.4, 0.06, 0.12), Basis(), 0.004)
	for i in 4:
		var x := -0.5 + i * 0.3
		var foot := Vector3(x, 0.28, 0.1)
		var bas := Basis(Vector3(1, 0, 0), -0.12)
		b.box(K.iron(), foot + bas * Vector3(0, 0.45, 0), Vector3(0.045, 0.85, 0.008), bas)
		b.box(K.iron(), foot + bas * Vector3(0, 0.88, 0), Vector3(0.18, 0.025, 0.03), bas)
		b.cyl(K.leather(), foot + bas * Vector3(0, 0.9, 0), foot + bas * Vector3(0, 1.08, 0), 0.016, 0.016, 5)
		K.knob(b, K.iron(), foot + bas * Vector3(0, 1.1, 0), 0.025, 6)
	b.cyl(K.oak(), Vector3(0.62, 0.05, 0.12), Vector3(0.6, 1.15, 0.02), 0.018, 0.018, 5)
	b.box(K.iron(), Vector3(0.6, 1.08, 0.08), Vector3(0.02, 0.18, 0.16), Basis(), 0.0)
	return K.asset("BS19_weapon_rack", b, [["box", Vector3(0, 0.7, 0.03), Vector3(1.5, 1.4, 0.35)]])


## BS21: ash pile: grey ash and cinders raked out of the forge.
static func ash_pile() -> Node3D:
	var b := HK.MB.new(521)
	b.blob(K.goods("ash", Color(0.42, 0.4, 0.38), 1.0), Vector3.ZERO, Vector3(0.45, 0.16, 0.35), 521, 0.3, 2.0, 5, 10, Basis(), true, 0.0)
	for i in 6:
		b.blob(MK.coal(), Vector3(cos(i * 2.1) * 0.2, 0.08, sin(i * 2.1) * 0.16), Vector3(0.04, 0.03, 0.035), 530 + i, 0.3, 2.0, 3, 6)
	return K.asset("BS21_ash_pile", b, [])
