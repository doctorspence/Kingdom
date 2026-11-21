extends RefCounted
## Campfires and cooking gear. Origins at ground level, center.

const Kit := preload("res://assets/hideout/Materials/kit.gd")


## kind: "ring" (small stone ring) or "communal" (large). Includes flame, embers, sparks, smoke
## and a flickering light (light = false for a dry prop).
static func campfire(kind := "ring", seed_ := 11, light := true) -> Node3D:
	var b := Kit.MB.new(seed_)
	var big := kind == "communal"
	var ring_r := 0.95 if big else 0.55
	var stones := 17 if big else 10
	var stone_m := Kit.stone("rock")
	for i in stones:
		var a := TAU * float(i) / stones + b.rng.randf_range(-0.08, 0.08)
		var r := ring_r + b.rng.randf_range(-0.05, 0.05)
		var sc := b.rng.randf_range(0.8, 1.25) * (1.35 if big else 1.0)
		b.blob(stone_m, Vector3(cos(a) * r, 0.05 * sc, sin(a) * r), Vector3(0.15, 0.11, 0.12) * sc, b.rng.randi() % 1000, 0.3, 1.8, 4, 7,
			Basis(Vector3.UP, -a + b.rng.randf_range(-0.4, 0.4)), true, 0.5)
		# soot on the inner face: a darker pebble layer
	# ash bed and charcoal
	b.blob(Kit.plain(Color(0.07, 0.065, 0.06), 1.0), Vector3(0, 0.02, 0), Vector3(ring_r * 0.85, 0.05, ring_r * 0.85), 3, 0.2, 2.0, 4, 14, Basis(), false, 0.3)
	# logs leaning in toward the middle, charred at the burning ends
	var logs := 7 if big else 5
	for i in logs:
		var a := TAU * float(i) / logs + b.rng.randf_range(-0.2, 0.2)
		var r_out := ring_r * 0.8
		var len_scale := 1.5 if big else 1.0
		var out_p := Vector3(cos(a) * r_out, 0.07, sin(a) * r_out)
		var in_p := Vector3(cos(a) * 0.08, 0.28 * len_scale, sin(a) * 0.08)
		var mid := out_p.lerp(in_p, 0.45)
		var rr := b.rng.randf_range(0.045, 0.065) * (1.4 if big else 1.0)
		b.cyl(Kit.wood("grey"), out_p, mid, rr, rr * 0.95, 7, 0.08, true, 2)
		b.cyl(Kit.wood("burnt"), mid, in_p, rr * 0.95, rr * 0.8, 7, 0.1, true, 2)
	# glowing coals
	for i in 9:
		var a := b.rng.randf() * TAU
		var r := b.rng.randf_range(0.05, ring_r * 0.6)
		b.blob(Kit.ember(), Vector3(cos(a) * r, 0.07, sin(a) * r), Vector3(0.05, 0.03, 0.045), i, 0.3, 2.0, 3, 6)
	var root := Kit.asset("Campfire_" + kind.capitalize(), b, "convex")
	Kit.fire_fx(root, Vector3(0, 0.25, 0), 1.7 if big else 1.0, (4.5 if big else 3.2) if light else 0.0)
	return root


## Iron-shod timber tripod with a chain and a cooking pot. Stand it over a campfire.
static func tripod_pot(seed_ := 12) -> Node3D:
	var b := Kit.MB.new(seed_)
	var apex := Vector3(0, 1.55, 0)
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.3
		var foot := Vector3(cos(a) * 0.82, 0.0, sin(a) * 0.82)
		b.cyl(Kit.wood("grey"), foot, apex + Vector3(cos(a) * 0.03, 0.12, sin(a) * 0.03), 0.04, 0.032, 6, 0.06, true, 4)
		b.cyl(Kit.iron(), foot, foot + (apex - foot).normalized() * 0.1, 0.044, 0.044, 6, 0.0, true)   # iron shoe
	# rope lashing at the top
	b.cyl(Kit.rope(), apex + Vector3(0, -0.06, 0), apex + Vector3(0, 0.06, 0), 0.078, 0.07, 10, 0.05)
	# chain: alternating links hanging from an iron hook
	var top := apex + Vector3(0, -0.07, 0)
	var links := 9
	var link_len := 0.052
	for i in links:
		var y := top.y - 0.04 - link_len * i
		var rot := Basis(Vector3.UP, PI * 0.5 * (i % 2))
		b.box(Kit.iron(), Vector3(0, y, 0), Vector3(0.026, link_len * 0.95, 0.011), rot)
	var chain_end := top.y - 0.04 - link_len * links
	b.push(Transform3D(Basis(), Vector3(0, chain_end - 0.62, 0)))
	add_pot(b)
	b.pop()
	return Kit.asset("Tripod_Pot", b, "convex")


## Round-bellied iron cooking pot with a rim, lugs, a bail handle and bubbling stew.
## Origin at the base.
static func add_pot(b: Kit.MB) -> void:
	var iron := Kit.iron()
	var prof := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.12, 0.0), Vector2(0.2, 0.035), Vector2(0.255, 0.12), Vector2(0.275, 0.22),
		Vector2(0.255, 0.31), Vector2(0.235, 0.335), Vector2(0.27, 0.345), Vector2(0.27, 0.362), Vector2(0.225, 0.362)])
	b.lathe(iron, prof, 18, true)
	# inside wall down to the stew
	var inner := PackedVector2Array([Vector2(0.225, 0.362), Vector2(0.215, 0.3), Vector2(0.23, 0.2), Vector2(0.2, 0.1), Vector2(0.0, 0.08)])
	b.lathe(iron, inner, 18, true)
	b.disc(Kit.plain(Color(0.2, 0.09, 0.04), 0.35), 0.285, 0.222, 18, true)
	for i in 6:
		var a := b.rng.randf() * TAU
		var r := b.rng.randf_range(0.02, 0.17)
		b.blob(Kit.plain(Color(0.3, 0.2, 0.08), 0.3), Vector3(cos(a) * r, 0.287, sin(a) * r), Vector3(0.03, 0.012, 0.03), i, 0.3, 2.0, 3, 6)
	# lugs and bail
	for sgn in [-1, 1]:
		b.box(iron, Vector3(sgn * 0.27, 0.34, 0), Vector3(0.03, 0.05, 0.05))
	var pts: Array[Vector3] = []
	for i in 9:
		var a := PI * float(i) / 8.0
		pts.append(Vector3(cos(a) * 0.27, 0.34 + sin(a) * 0.3, 0))
	for i in pts.size() - 1:
		b.cyl(iron, pts[i], pts[i + 1], 0.008, 0.008, 5, 0.0, false)


## Rough stool in three varieties: 0 round log seat, 1 three-legged plank seat, 2 split-log bench stub.
static func stool(variant := 0, seed_ := 21) -> Node3D:
	var b := Kit.MB.new(seed_)
	match variant:
		0:
			b.cyl(Kit.wood("grey"), Vector3.ZERO, Vector3(0.0, 0.42, 0.0), 0.19, 0.17, 9, 0.06, true, 3)
		1:
			for i in 3:
				var a := TAU * float(i) / 3.0
				b.cyl(Kit.wood("dark"), Vector3(cos(a) * 0.2, 0, sin(a) * 0.2), Vector3(cos(a) * 0.12, 0.4, sin(a) * 0.12), 0.028, 0.026, 6, 0.08)
			b.cyl(Kit.wood("aged"), Vector3(0, 0.4, 0), Vector3(0, 0.44, 0), 0.2, 0.2, 8, 0.05, true)
		_:
			b.box(Kit.wood("aged"), Vector3(0, 0.4, 0), Vector3(0.55, 0.06, 0.26), Basis(Vector3.UP, 0.1), 0.006)
			for sx in [-1, 1]:
				b.box(Kit.wood("dark"), Vector3(sx * 0.21, 0.185, 0), Vector3(0.07, 0.37, 0.2), Basis(Vector3.BACK, sx * 0.08), 0.004)
	return Kit.asset("Stool_%d" % variant, b, "convex")
