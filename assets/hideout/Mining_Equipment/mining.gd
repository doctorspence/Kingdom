extends RefCounted
## Quarry gear. Origins at ground level, centered.

const Kit := preload("res://assets/hideout/Materials/kit.gd")


## Wooden ore cart on iron wheels (rides on a 0.6 m gauge track). loaded = piled with ore.
## Runs along X, origin under the middle at rail level.
static func mine_cart(loaded := true, seed_ := 31) -> Node3D:
	var b := Kit.MB.new(seed_)
	var iron := Kit.iron()
	var L := 1.15
	var W := 0.78
	var floor_y := 0.3
	var tilt := 0.16
	# chassis beams, axles, wheels
	for sz in [-1, 1]:
		b.box(Kit.wood("dark"), Vector3(0, floor_y - 0.06, sz * 0.3), Vector3(L + 0.1, 0.1, 0.09), Basis(), 0.004)
	for sx in [-1, 1]:
		var x: float = sx * 0.36
		b.cyl(iron, Vector3(x, 0.14, -0.4), Vector3(x, 0.14, 0.4), 0.025, 0.025, 8)
		for sz in [-1, 1]:
			var z: float = sz * 0.31
			# flanged wheel: tread plus flange, with a hub
			b.cyl(iron, Vector3(x, 0.14, z - 0.02), Vector3(x, 0.14, z + 0.02), 0.14, 0.14, 16, 0.0, true)
			b.cyl(iron, Vector3(x, 0.14, z + sz * 0.02), Vector3(x, 0.14, z + sz * 0.035), 0.16, 0.16, 16, 0.0, true)
			b.cyl(iron, Vector3(x, 0.14, z), Vector3(x, 0.14, z + sz * 0.06), 0.045, 0.04, 8, 0.0, true)
	# body: planked floor, sloping sides and ends
	b.box(Kit.wood("aged"), Vector3(0, floor_y, 0), Vector3(L - 0.1, 0.045, W - 0.2), Basis(), 0.003)
	var planks := 3
	var ph := 0.17
	for sz in [-1, 1]:
		for i in planks:
			var y := floor_y + 0.03 + ph * (float(i) + 0.5)
			var out := (y - floor_y) * tan(tilt)
			var m: Material = Kit.wood("grey") if b.rng.randf() < 0.3 else Kit.wood("aged")
			b.box(m, Vector3(b.rng.randf_range(-0.01, 0.01), y, sz * (W * 0.5 - 0.09 + out)), Vector3(L + 0.02, ph - 0.012, 0.03),
				Basis(Vector3.RIGHT, -sz * tilt), 0.003)
	for sx in [-1, 1]:
		for i in planks:
			var y := floor_y + 0.03 + ph * (float(i) + 0.5)
			var out := (y - floor_y) * tan(tilt)
			b.box(Kit.wood("aged"), Vector3(sx * (L * 0.5 - 0.02 + out), y, 0), Vector3(0.03, ph - 0.012, W - 0.12 + out * 1.6),
				Basis(Vector3.BACK, sx * tilt), 0.003)
	# iron straps and rim
	var top_y := floor_y + 0.03 + ph * planks
	for sz in [-1, 1]:
		for i in 4:
			var x := -L * 0.5 + 0.12 + (L - 0.24) * float(i) / 3.0
			var out := (top_y - floor_y) * 0.5 * tan(tilt)
			b.box(iron, Vector3(x, floor_y + (top_y - floor_y) * 0.5 + 0.02, sz * (W * 0.5 - 0.06 + out * 1.9)),
				Vector3(0.045, top_y - floor_y + 0.04, 0.014), Basis(Vector3.RIGHT, -sz * tilt))
		var rim_out := (top_y - floor_y) * tan(tilt)
		b.box(iron, Vector3(0, top_y - 0.01, sz * (W * 0.5 - 0.06 + rim_out)), Vector3(L + 0.04, 0.03, 0.04), Basis(Vector3.RIGHT, -sz * tilt))
	# couplings
	for sx in [-1, 1]:
		b.cyl(iron, Vector3(sx * (L * 0.5 + 0.08), floor_y - 0.04, 0), Vector3(sx * (L * 0.5 + 0.22), floor_y - 0.04, 0), 0.025, 0.02, 6)
		b.cyl(iron, Vector3(sx * (L * 0.5 + 0.22), floor_y - 0.04, 0), Vector3(sx * (L * 0.5 + 0.26), floor_y - 0.04, 0), 0.04, 0.04, 8, 0.0, true)
	if loaded:
		for i in 9:
			var x := b.rng.randf_range(-0.38, 0.38)
			var z := b.rng.randf_range(-0.2, 0.2)
			var s := b.rng.randf_range(0.8, 1.4)
			b.blob(Kit.stone("ore") if b.rng.randf() < 0.55 else Kit.stone("dark"), Vector3(x, top_y - 0.06 + b.rng.randf_range(0.0, 0.1) - absf(x) * 0.12, z),
				Vector3(0.12, 0.09, 0.11) * s, b.rng.randi() % 1000, 0.3, 1.8, 4, 7, Basis(Vector3.UP, b.rng.randf() * TAU), true, 0.7)
	return Kit.asset("MineCart_" + ("Loaded" if loaded else "Empty"), b, "convex")


## 2 m straight track: rails with head/web/foot, uneven sleepers, spikes, gravel ballast.
## The ends line up with the next piece (rails run exactly from x = -1 to +1).
static func track(seed_ := 32) -> Node3D:
	var b := Kit.MB.new(seed_)
	var gauge := 0.6
	var iron := Kit.iron()
	for i in 5:
		var x := -0.8 + 0.4 * i
		b.box(Kit.wood("dark"), Vector3(x + b.rng.randf_range(-0.02, 0.02), 0.04, 0.0), Vector3(0.13, 0.08, 0.95), Basis(Vector3.UP, b.rng.randf_range(-0.04, 0.04)), 0.006)
	for sz in [-1, 1]:
		var z: float = sz * gauge * 0.5
		b.box(iron, Vector3(0, 0.086, z), Vector3(2.0, 0.012, 0.06))                 # foot
		b.box(iron, Vector3(0, 0.1, z), Vector3(2.0, 0.04, 0.016))                   # web
		b.box(iron, Vector3(0, 0.128, z), Vector3(2.0, 0.026, 0.04))                 # head
		for i in 5:
			var x := -0.8 + 0.4 * i
			b.box(iron, Vector3(x, 0.098, z + sz * 0.034), Vector3(0.03, 0.022, 0.02))   # spikes
	# gravel
	for i in 16:
		var x := b.rng.randf_range(-1.0, 1.0)
		var z := b.rng.randf_range(-0.5, 0.5)
		b.blob(Kit.stone("dark"), Vector3(x, 0.01, z), Vector3(0.07, 0.04, 0.06) * b.rng.randf_range(0.7, 1.4), i, 0.3, 2.0, 3, 6, Basis(Vector3.UP, b.rng.randf() * TAU), true, 0.3)
	return Kit.asset("Track_2m", b, "aabb")


## Miner's pickaxe lying on the ground (head up). Origin at the middle of the handle.
static func pickaxe(seed_ := 33) -> Node3D:
	var b := Kit.MB.new(seed_)
	var l := 0.95
	b.cyl(Kit.wood("aged"), Vector3(-l * 0.5, 0.02, 0), Vector3(l * 0.5, 0.02, 0.0), 0.021, 0.018, 6, 0.04, true, 3)
	# curved double-pointed head
	var cx := l * 0.5 - 0.05
	var pts: Array[Vector3] = []
	for i in 9:
		var a := lerpf(-0.9, 0.9, float(i) / 8.0)
		pts.append(Vector3(cx + sin(a) * 0.0, 0.02 + cos(a) * 0.0, 0) + Vector3(-0.07 * (1.0 - cos(a)) * 2.0, 0, sin(a) * 0.23))
	for i in pts.size() - 1:
		var t0 := absf(float(i) / 4.0 - 1.0)
		var t1 := absf(float(i + 1) / 4.0 - 1.0)
		b.cyl(Kit.iron(), pts[i], pts[i + 1], lerpf(0.012, 0.036, 1.0 - t0), lerpf(0.012, 0.036, 1.0 - t1), 6, 0.0, true)
	b.box(Kit.iron(), Vector3(cx, 0.02, 0), Vector3(0.07, 0.065, 0.07))
	return Kit.asset("Pickaxe", b, "none")


## Shovel lying on the ground. Origin at the middle of the handle.
static func shovel(seed_ := 34) -> Node3D:
	var b := Kit.MB.new(seed_)
	b.cyl(Kit.wood("aged"), Vector3(-0.5, 0.02, 0), Vector3(0.35, 0.02, 0), 0.022, 0.02, 6, 0.04, true, 3)
	b.box(Kit.wood("dark"), Vector3(-0.5, 0.02, 0), Vector3(0.05, 0.03, 0.14))                   # T grip
	var iron := Kit.iron()
	var a := Vector3(0.3, 0.012, -0.095)
	b.quad(iron, a, Vector3(0.3, 0.012, 0.095), Vector3(0.62, 0.0, 0.07), Vector3(0.62, 0.0, -0.07), Vector3.UP)
	b.box(iron, Vector3(0.32, 0.03, 0), Vector3(0.1, 0.05, 0.05))
	return Kit.asset("Shovel", b, "none")


## Heap of ore chunks (copper-brown and dark rock).
static func ore_pile(size := 1.0, seed_ := 35) -> Node3D:
	var b := Kit.MB.new(seed_)
	for i in int(14 * size):
		var a := b.rng.randf() * TAU
		var r := b.rng.randf() * 0.45 * size
		var s := b.rng.randf_range(0.7, 1.5) * (1.0 - r / (0.7 * size) * 0.5)
		var m: Material = Kit.stone("ore") if b.rng.randf() < 0.6 else Kit.stone("dark")
		b.blob(m, Vector3(cos(a) * r, 0.07 * s + (0.45 * size - r) * 0.3, sin(a) * r), Vector3(0.13, 0.1, 0.12) * s, b.rng.randi() % 1000,
			0.3, 1.8, 4, 7, Basis(Vector3.UP, b.rng.randf() * TAU), true, 0.5)
	return Kit.asset("OrePile", b, "convex")


## Coil of rope.
static func rope_coil(seed_ := 36) -> Node3D:
	var b := Kit.MB.new(seed_)
	var turns := 5
	var segs := 14
	for t in turns:
		var r := 0.13 + 0.012 * t
		var y := 0.02 + 0.008 * (t % 2)
		for i in segs:
			var a0 := TAU * float(i) / segs
			var a1 := TAU * float(i + 1) / segs
			b.cyl(Kit.rope(), Vector3(cos(a0) * r, y, sin(a0) * r), Vector3(cos(a1) * r, y, sin(a1) * r), 0.016, 0.016, 5, 0.1, false)
	b.cyl(Kit.rope(), Vector3(0.13, 0.03, 0.0), Vector3(0.38, 0.015, 0.1), 0.016, 0.014, 5, 0.1, true, 2)
	return Kit.asset("RopeCoil", b, "none")
