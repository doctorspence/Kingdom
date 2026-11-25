extends RefCounted
## Small storytelling props, DT01-DT20 (see assets/outpost/MANIFEST.md): things left lying about
## that tell what happened here. DT09/DT11/DT16/DT17 are the handcart, hay, notice and crates
## already built. Real-world size. Origins: centre of the base on y = 0.

const HK := preload("res://assets/hideout/Materials/kit.gd")
const K := preload("res://assets/outpost/materials/outpost_kit.gd")
const MK := preload("res://assets/outpost/market/market.gd")
const CR := preload("res://assets/outpost/carpenter/carpenter.gd")
const WK := preload("res://assets/outpost/white_knights/white_knights.gd")
const BSM := preload("res://assets/outpost/blacksmith/blacksmith.gd")
const CPA := preload("res://assets/outpost/castle_approach/castle_approach.gd")


## DT01: abandoned wooden bucket, tipped on its side.
static func bucket() -> Node3D:
	var b := HK.MB.new(1201)
	b.push(Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5 - 0.15), Vector3(0, 0.15, 0)))
	b.lathe(K.oak("weathered"), PackedVector2Array([Vector2(0.0005, -0.15), Vector2(0.13, -0.15), Vector2(0.15, 0.15), Vector2(0.13, 0.15), Vector2(0.11, -0.13), Vector2(0.0005, -0.13)]), 12)
	for y in [-0.09, 0.09]:
		b.cyl(K.iron(), Vector3(0, y - 0.015, 0), Vector3(0, y + 0.015, 0), 0.145, 0.145, 12, 0.0, false)
	b.pop()
	return K.asset("DT01_abandoned_wooden_bucket", b, [])


## DT02: broken crate: a crate stove in, planks sprung and lying beside it.
static func broken_crate() -> Node3D:
	var b := HK.MB.new(1202)
	var oak := K.oak("weathered")
	b.box(oak, Vector3(0, 0.02, 0), Vector3(0.7, 0.04, 0.55), Basis(), 0.004)
	b.box(oak, Vector3(0, 0.27, -0.26), Vector3(0.7, 0.5, 0.04), Basis(), 0.006)
	b.box(oak, Vector3(-0.33, 0.25, 0), Vector3(0.04, 0.46, 0.55), Basis(Vector3(0, 0, 1), 0.08), 0.006)
	b.box(oak, Vector3(0.36, 0.18, 0.05), Vector3(0.04, 0.32, 0.5), Basis(Vector3(0, 0, 1), -0.4), 0.006)
	for i in 3:
		b.box(oak, Vector3(-0.2 + i * 0.28, 0.02 + i * 0.02, 0.55 + i * 0.05), Vector3(0.7, 0.025, 0.12), Basis(Vector3.UP, 0.4 * (i - 1)), 0.005)
	return K.asset("DT02_broken_crate", b, [["box", Vector3(0, 0.25, -0.05), Vector3(0.75, 0.5, 0.6)]])


## DT03: empty sack, slumped and flat.
static func empty_sack() -> Node3D:
	var b := HK.MB.new(1203)
	MK.sack(b, Vector3.ZERO, 0.9, 1203, true)
	return K.asset("DT03_empty_sack", b, [])


## DT04: wooden spoon.
static func spoon() -> Node3D:
	var b := HK.MB.new(1204)
	b.cyl(K.oak(), Vector3(-0.12, 0.01, 0), Vector3(0.08, 0.012, 0), 0.008, 0.01, 4)
	b.blob(K.oak(), Vector3(0.11, 0.012, 0), Vector3(0.04, 0.012, 0.03), 1204, 0.05, 1.0, 3, 8)
	return K.asset("DT04_wooden_spoon", b, [])


## DT05: clay plate, cracked in two.
static func clay_plate() -> Node3D:
	var b := HK.MB.new(1205)
	for s in [-1.0, 1.0]:
		b.push(Transform3D(Basis(Vector3.UP, 0.1 * s), Vector3(s * 0.02, 0, s * 0.01)))
		var prof := PackedVector2Array([Vector2(0.0005, 0.0), Vector2(0.09, 0.0), Vector2(0.12, 0.025), Vector2(0.11, 0.028), Vector2(0.08, 0.008), Vector2(0.0005, 0.008)])
		b.lathe(K.clay(), prof, 6, true)
		b.pop()
	return K.asset("DT05_clay_plate", b, [])


## DT06: hanging rope: a frayed length hanging from an iron ring. Origin: the ring (hanging).
static func hanging_rope() -> Node3D:
	var b := HK.MB.new(1206)
	K.ring(b, K.iron(), Vector3(0, -0.04, 0), Vector3(0, 0, 1), 0.04, 0.008, 8, 4)
	b.cyl(K.rope(), Vector3(0, -0.08, 0), Vector3(0.03, -1.2, 0.02), 0.014, 0.012, 5)
	b.cyl(K.rope(), Vector3(0.03, -1.2, 0.02), Vector3(0.05, -1.32, 0.04), 0.012, 0.02, 5)
	return K.asset("DT06_hanging_rope", b, [])


## DT07: old iron chain lying in a loose line.
static func old_chain() -> Node3D:
	var b := HK.MB.new(1207)
	for i in 14:
		var p := Vector3(-0.45 + i * 0.065, 0.02, 0.06 * sin(i * 0.6))
		K.ring(b, K.goods("rusted", Color(0.32, 0.2, 0.13), 0.8), p, Vector3.UP if i % 2 == 0 else Vector3(0, 0, 1), 0.035, 0.008, 6, 3)
	return K.asset("DT07_old_iron_chain", b, [])


## DT08: rusted tools: a broken spade, a cracked hammer and a rusted sickle.
static func rusted_tools() -> Node3D:
	var b := HK.MB.new(1208)
	var rust := K.goods("rusted", Color(0.32, 0.2, 0.13), 0.8)
	b.cyl(K.oak("weathered"), Vector3(-0.4, 0.02, -0.1), Vector3(0.1, 0.02, 0.05), 0.016, 0.016, 5)
	b.box(rust, Vector3(0.2, 0.01, 0.08), Vector3(0.22, 0.01, 0.16), Basis(Vector3.UP, 0.3))
	b.cyl(K.oak("weathered"), Vector3(-0.1, 0.015, 0.25), Vector3(0.15, 0.015, 0.3), 0.012, 0.012, 4)
	b.box(rust, Vector3(0.18, 0.02, 0.31), Vector3(0.05, 0.04, 0.12), Basis(Vector3.UP, 0.2))
	for i in 6:
		var a := 0.3 + i * 0.35
		b.box(rust, Vector3(0.1 + cos(a) * 0.15, 0.006, -0.25 + sin(a) * 0.1), Vector3(0.07, 0.006, 0.02), Basis(Vector3.UP, -a))
	return K.asset("DT08_rusted_tools", b, [])


## DT10: broken wagon wheel lying flat, spokes snapped, the iron tyre sprung.
static func broken_wheel() -> Node3D:
	var b := HK.MB.new(1210)
	CR.wheel(b, Vector3(0, 0.05, 0), 0.55, Vector3(0.1, 1, 0.05), 6)
	for i in 3:
		var a := i * 2.0
		b.cyl(K.oak("weathered"), Vector3(cos(a) * 0.8, 0.03, sin(a) * 0.8), Vector3(cos(a) * 0.8 + 0.3, 0.03, sin(a) * 0.8 + 0.1), 0.018, 0.012, 5)
	return K.asset("DT10_broken_wagon_wheel", b, [])


## DT12: scattered firewood: split logs tumbled off a pile.
static func scattered_firewood() -> Node3D:
	var b := HK.MB.new(1212)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1212
	for i in 9:
		var p := Vector3(rng.randf_range(-0.6, 0.6), 0.05, rng.randf_range(-0.5, 0.5))
		var d := Vector3(rng.randf_range(-1, 1), 0.0, rng.randf_range(-1, 1)).normalized() * 0.22
		b.cyl(K.oak("weathered"), p - d, p + d + Vector3(0, 0.03 * (i % 2), 0), 0.05, 0.05, 5, 0.12)
	return K.asset("DT12_scattered_firewood", b, [])


## DT13: fallen signboard: the heraldic signboard's board lying in the mud, one chain still on it.
static func fallen_signboard() -> Node3D:
	var b := HK.MB.new(1213)
	var bas := Basis(Vector3(1, 0, 0), -PI * 0.5 + 0.08)
	var c := Vector3(0, 0.04, 0)
	b.box(K.oak(), c, Vector3(0.74, 0.86, 0.05), bas, 0.004)
	K.face(b, K.emblem_paint(), c + bas * Vector3(-0.31, 0.37, 0.03), c + bas * Vector3(0.31, 0.37, 0.03), c + bas * Vector3(0.31, -0.37, 0.03), c + bas * Vector3(-0.31, -0.37, 0.03), bas * Vector3(0, 0, 1))
	for k in 3:
		K.ring(b, K.iron(), c + Vector3(-0.25 + k * 0.05, 0.03, -0.5 - k * 0.03), Vector3.UP if k % 2 == 0 else Vector3(1, 0, 0), 0.028, 0.006, 6, 3)
	b.blob(K.goods("mud", Color(0.22, 0.17, 0.12), 0.7), Vector3(0.2, 0.0, 0.25), Vector3(0.3, 0.04, 0.2), 1213, 0.3, 2.0, 3, 8, Basis(), true, 0.2)
	return K.asset("DT13_fallen_signboard", b, [])


## DT14: stone piles: rubble and loose stones heaped where a wall came down.
static func stone_piles() -> Node3D:
	var b := HK.MB.new(1214)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1214
	for i in 14:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * 0.6
		var s := rng.randf_range(0.08, 0.2)
		b.blob(K.limestone(), Vector3(cos(a) * d, s * 0.4 + (0.6 - d) * 0.25, sin(a) * d * 0.8), Vector3(s, s * 0.7, s * 0.85), 1214 + i, 0.2, 1.5, 4, 7, Basis(Vector3.UP, a), true)
	return K.asset("DT14_stone_piles", b, [["box", Vector3(0, 0.15, 0), Vector3(1.3, 0.3, 1.0)]])


## DT15: animal tracks and hoofprints: a decal trail 1.2 x 2.4 m pressed into mud.
static func tracks() -> Node3D:
	return K.decal("DT15_animal_tracks_and_hoofprints", "hoofprints", Vector3(1.2, 1.0, 2.4))


## DT18: tattered cloth: a torn White Knights pennant caught on a stake.
static func tattered_cloth() -> Node3D:
	var b := HK.MB.new(1218)
	b.cyl(K.oak("weathered"), Vector3(0, 0, 0), Vector3(0.05, 1.1, 0.02), 0.025, 0.02, 5, 0.08)
	b.push(Transform3D(Basis(Vector3(0, 0, 1), -0.9), Vector3(0.05, 1.05, 0.03)))
	K.banner(b, K.banner_cloth(), 0.3, 0.7, "dagged", 18, 1.5, 6, 6)
	b.pop()
	return K.asset("DT18_tattered_cloth", b, [])


## DT19: old shields: two battered Knights' shields, one face down, leaning on a stone.
static func old_shields() -> Node3D:
	var b := HK.MB.new(1219)
	b.blob(K.limestone(), Vector3(0, 0, -0.25), Vector3(0.3, 0.25, 0.2), 1219, 0.25, 1.5, 4, 7, Basis(), true, 0.4)
	b.push(Transform3D(Basis(Vector3(1, 0, 0), -1.2), Vector3(0, 0.35, -0.1)))
	K.heater(b, 0.62, 0.8, 0.035, 0.03)
	b.pop()
	b.push(Transform3D(Basis(Vector3.UP, 0.8) * Basis(Vector3(1, 0, 0), PI * 0.5), Vector3(0.6, 0.04, 0.3)))
	K.heater(b, 0.62, 0.8, 0.035, 0.03)
	b.pop()
	return K.asset("DT19_old_shields", b, [])


## DT20: abandoned spear: a Knights' spear lying broken in two.
static func abandoned_spear() -> Node3D:
	var b := HK.MB.new(1220)
	CPA._spear(b, Vector3(-0.4, 0.025, 0.0), Vector3(1.1, 0.025, 0.08))
	b.cyl(K.oak(), Vector3(-1.4, 0.025, 0.2), Vector3(-0.55, 0.025, 0.12), 0.021, 0.02, 6)
	return K.asset("DT20_abandoned_spear", b, [])
