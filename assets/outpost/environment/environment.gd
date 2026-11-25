extends RefCounted
## Ground and environment pieces, ENV07-ENV26 (see assets/outpost/MANIFEST.md). Most of the list
## (terrain paint, grass, ferns, brambles, trees, boulders, the brook, mist) is the Tithelands' own
## systems and is used as it is when the outpost is placed. Built here: what the zone lacks.
## Real-world size. Origins: centre of the base on y = 0.

const HK := preload("res://assets/hideout/Materials/kit.gd")
const K := preload("res://assets/outpost/materials/outpost_kit.gd")
const CR := preload("res://assets/outpost/carpenter/carpenter.gd")


## ENV07: mud splash decal, 2 x 2 m, projected down onto whatever it is placed over.
static func mud_splash() -> Node3D:
	return K.decal("ENV07_mud_splash_decal", "mud_splash", Vector3(2.0, 1.0, 2.0))


## A sawn stump with roots at c, radius r.
static func stump(b: HK.MB, c: Vector3, r: float, h: float, seed_: int) -> void:
	b.cyl(K.oak("weathered"), c + Vector3(0, -0.05, 0), c + Vector3(0, h, 0), r * 1.1, r, 9, 0.08)
	b.disc(K.goods("sawn", Color(0.62, 0.48, 0.32), 0.9), c.y + h, r * 0.98, 9, true, c.x, c.z)
	for i in 4:
		var a := TAU * i / 4.0 + seed_
		b.cyl(K.oak("weathered"), c + Vector3(cos(a) * r * 0.7, h * 0.25, sin(a) * r * 0.7), c + Vector3(cos(a) * r * 1.9, -0.05, sin(a) * r * 1.9), r * 0.35, r * 0.15, 5)


## ENV19: tree stumps, one large and one small, sawn flat (the outpost cleared its ground).
static func tree_stumps() -> Node3D:
	var b := HK.MB.new(1019)
	stump(b, Vector3(0, 0, 0), 0.32, 0.45, 1)
	stump(b, Vector3(1.0, 0, 0.5), 0.2, 0.3, 2)
	return K.asset("ENV19_tree_stumps", b, [["cyl", Vector3(0, 0.22, 0), 0.35, 0.45], ["cyl", Vector3(1.0, 0.15, 0.5), 0.22, 0.3]])


## ENV23: stone path pieces: a run of flat limestone stepping stones, 3 m, set in the earth.
static func stone_path() -> Node3D:
	var b := HK.MB.new(1023)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1023
	for i in 7:
		var p := Vector3(rng.randf_range(-0.15, 0.15), 0.0, -1.4 + i * 0.47)
		var sz := Vector3(rng.randf_range(0.45, 0.6), 0.1, rng.randf_range(0.35, 0.45))
		b.blob(K.limestone(), p, sz * 0.5 + Vector3(0, 0.0, 0), 1023 + i, 0.15, 1.2, 3, 8, Basis(Vector3.UP, rng.randf() * PI), true, 0.6)
	return K.asset("ENV23_stone_path_pieces", b, [])


## ENV25: creek rocks: a cluster of rounded wet stones for a stream bed.
static func creek_rocks() -> Node3D:
	var b := HK.MB.new(1025)
	var wet := K.painted("limestone_wet", "limestone", 1.0, {"rough": 0.45, "spec": 0.5, "tint": Color(0.72, 0.72, 0.7)})
	var rng := RandomNumberGenerator.new()
	rng.seed = 1025
	for i in 9:
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.0, 0.9)
		var s := rng.randf_range(0.12, 0.35)
		b.blob(wet, Vector3(cos(a) * d, 0, sin(a) * d * 0.6), Vector3(s, s * 0.6, s * 0.8), 1025 + i, 0.25, 1.5, 5, 9, Basis(Vector3.UP, a), false, 0.4)
	return K.asset("ENV25_creek_rocks", b, [["box", Vector3(0, 0.15, 0), Vector3(1.8, 0.3, 1.1)]])


## ENV26: small footbridge: an oak plank bridge with a single handrail, 4 m over a creek, on
## stone abutments. Walkable (the deck is collision).
static func footbridge() -> Node3D:
	var b := HK.MB.new(1026)
	var oak := K.oak("weathered")
	for x in [-1.9, 1.9]:
		b.box(K.rubble(), Vector3(x, 0.0, 0), Vector3(0.6, 0.5, 1.4), Basis(), 0.01)
	for z in [-0.45, 0.45]:
		b.box(oak, Vector3(0, 0.3, z), Vector3(4.2, 0.18, 0.16), Basis(), 0.005)
	for i in 14:
		var x := -1.95 + i * 0.3
		b.box(oak, Vector3(x, 0.41, 0), Vector3(0.27, 0.05, 1.1), Basis(Vector3.UP, 0.02 * ((i * 7) % 3 - 1)), 0.004)
	for x in [-1.8, 0.0, 1.8]:
		b.box(oak, Vector3(x, 0.85, -0.52), Vector3(0.09, 0.9, 0.09), Basis(), 0.004)
	b.cyl(oak, Vector3(-1.9, 1.25, -0.52), Vector3(1.9, 1.25, -0.52), 0.04, 0.04, 6, 0.05)
	return K.asset("ENV26_small_footbridge", b, [["box", Vector3(0, 0.38, 0), Vector3(4.4, 0.1, 1.1)],
		["box", Vector3(0, 0.85, -0.52), Vector3(4.0, 0.9, 0.1)]])
