extends RefCounted
## Natural cave pieces. Floor/wall/ceiling sections are 4 m tiles whose edges are pinned to
## the tile plane, so neighboring tiles meet without gaps (vary the seed per tile).

const Kit := preload("res://assets/hideout/Materials/kit.gd")


static func _noise(seed_: int, freq: float, octaves := 4) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = seed_
	n.frequency = freq
	n.fractal_octaves = octaves
	return n


static func _edge_mask(u: float, v: float, band := 0.1) -> float:
	return smoothstep(0.0, band, minf(minf(u, 1.0 - u), minf(v, 1.0 - v)))


## Walkable cave floor tile: swells, hollows, loose gravel. Origin at the center, y = 0 at the edges.
static func floor_section(size := 4.0, seed_ := 1, res := 22, amp := 0.7) -> Node3D:
	var b := Kit.MB.new(seed_)
	var n1 := _noise(seed_, 0.3)
	var n2 := _noise(seed_ + 50, 1.3, 3)
	var pts := PackedVector3Array()
	for j in res + 1:
		for i in res + 1:
			var u := float(i) / res
			var v := float(j) / res
			var x := (u - 0.5) * size
			var z := (v - 0.5) * size
			var h := (n1.get_noise_2d(x, z) * 0.3 + n2.get_noise_2d(x, z) * 0.07) * amp
			pts.append(Vector3(x, h * _edge_mask(u, v), z))
	b.grid(Kit.dirt(), pts, res + 1, res + 1, Vector3.UP, 0.5)
	# scattered stones and gravel sitting on it
	for i in 9:
		var x := b.rng.randf_range(-size * 0.42, size * 0.42)
		var z := b.rng.randf_range(-size * 0.42, size * 0.42)
		var s := b.rng.randf_range(0.5, 1.6)
		var u := x / size + 0.5
		var v := z / size + 0.5
		var gy := (n1.get_noise_2d(x, z) * 0.3 + n2.get_noise_2d(x, z) * 0.07) * amp * _edge_mask(u, v)
		b.blob(Kit.stone("dark"), Vector3(x, gy + 0.02, z), Vector3(0.12, 0.08, 0.1) * s, b.rng.randi() % 1000, 0.3, 1.8, 4, 7,
			Basis(Vector3.UP, b.rng.randf() * TAU), true, 0.4)
	return Kit.asset("CaveFloor_%dm" % roundi(size), b, "trimesh")


## Rough rock wall tile facing +Z with strata ledges and hollows. Origin bottom-center.
static func wall_section(w := 4.0, h := 3.6, seed_ := 2, res := 24) -> Node3D:
	var b := Kit.MB.new(seed_)
	var n1 := _noise(seed_, 0.35)
	var n2 := _noise(seed_ + 9, 1.1, 3)
	var pts := PackedVector3Array()
	for j in res + 1:
		for i in res + 1:
			var u := float(i) / res
			var v := float(j) / res
			var x := (u - 0.5) * w
			var y := v * h
			var strata := sin(y * 4.2 + n1.get_noise_2d(x, y) * 2.0) * 0.06
			var d := (n1.get_noise_2d(x * 1.2, y * 1.2) * 0.55 + n2.get_noise_2d(x, y) * 0.16 + strata)
			pts.append(Vector3(x, y, d * _edge_mask(u, v, 0.08)))
	b.grid(Kit.stone("rock"), pts, res + 1, res + 1, Vector3(0, 0, 1), 0.5)
	return Kit.asset("CaveWall_%dm" % roundi(w), b, "trimesh")


## Rock outcrop. size: "large" (3 m), "medium" (1.6 m), "small" (0.6 m rubble).
static func rock_formation(size := "large", seed_ := 3) -> Node3D:
	var b := Kit.MB.new(seed_)
	var s := 1.0
	var parts := 5
	match size:
		"medium":
			s = 0.5
			parts = 4
		"small":
			s = 0.18
			parts = 3
	var mat := Kit.stone("rock")
	for i in parts:
		var a := b.rng.randf() * TAU
		var r := b.rng.randf_range(0.0, 1.0) * 1.0 * s * (0.0 if i == 0 else 1.0)
		var rad := Vector3(b.rng.randf_range(1.1, 1.8), b.rng.randf_range(1.0, 2.1), b.rng.randf_range(1.0, 1.6)) * s * (1.0 if i == 0 else 0.6)
		b.blob(mat, Vector3(cos(a) * r, rad.y * 0.45, sin(a) * r), rad, b.rng.randi() % 1000, 0.42, 1.3, 10, 16,
			Basis(Vector3.UP, b.rng.randf() * TAU), false, 0.5)
	for i in 4 + int(parts):
		var a := b.rng.randf() * TAU
		var r := (1.2 + b.rng.randf() * 1.3) * s
		var q := b.rng.randf_range(0.8, 1.6) * maxf(s, 0.25) * 0.14
		b.blob(Kit.stone("dark"), Vector3(cos(a) * r, q * 0.4, sin(a) * r), Vector3(q * 1.2, q * 0.8, q), b.rng.randi() % 1000, 0.3, 1.8, 4, 8,
			Basis(Vector3.UP, b.rng.randf() * TAU), true, 0.4)
	return Kit.asset("Rock_" + size.capitalize(), b, "convex")


## Cluster of stalagmites (rising) or stalactites (hanging, origin at the ceiling).
static func stalagmites(count := 5, hanging := false, seed_ := 4) -> Node3D:
	var b := Kit.MB.new(seed_)
	var mat := Kit.stone("wet")
	var dir := -1.0 if hanging else 1.0
	for i in count:
		var a := b.rng.randf() * TAU
		var r := b.rng.randf() * 0.5 if i > 0 else 0.0
		var h := b.rng.randf_range(0.5, 1.5) if i > 0 else b.rng.randf_range(1.3, 1.8)
		var base := b.rng.randf_range(0.1, 0.24) * (1.3 if i == 0 else 1.0)
		var lean := Vector3(b.rng.randf_range(-0.08, 0.08), 0, b.rng.randf_range(-0.08, 0.08))
		var p0 := Vector3(cos(a) * r, 0, sin(a) * r)
		b.cyl(mat, p0 + Vector3(0, -0.03 * dir, 0), p0 + lean + Vector3(0, h * dir, 0), base, 0.012, 9, 0.12, true, 6)
		b.blob(mat, p0, Vector3(base * 1.5, 0.05, base * 1.5), b.rng.randi() % 100, 0.3, 2.0, 3, 9)
	return Kit.asset("Stalag%s_%d" % ["tites" if hanging else "mites", count], b, "convex")


## Shallow underground pool ringed with wet stones. Origin at the center, water surface just below 0.
static func water_pool(radius := 1.1, seed_ := 5) -> Node3D:
	var b := Kit.MB.new(seed_)
	b.disc(Kit.water(), 0.17, radius, 20, true)
	var stones := 14
	for i in stones:
		var a := TAU * float(i) / stones + b.rng.randf_range(-0.1, 0.1)
		var r := radius * b.rng.randf_range(0.95, 1.12)
		var s := b.rng.randf_range(0.7, 1.4) * radius * 0.28
		b.blob(Kit.stone("wet"), Vector3(cos(a) * r, 0.01, sin(a) * r), Vector3(s, s * 0.6, s * 0.8), b.rng.randi() % 1000, 0.3, 1.8, 5, 8,
			Basis(Vector3.UP, -a), true, 0.35)
	return Kit.asset("WaterPool", b, "none")


## Ceiling tile: rough relief, hang it at the cave height (origin at the tile center, facing down).
static func ceiling_section(size := 4.0, seed_ := 7, res := 22) -> Node3D:
	var b := Kit.MB.new(seed_)
	var n1 := _noise(seed_, 0.28)
	var n2 := _noise(seed_ + 50, 1.0, 3)
	var pts := PackedVector3Array()
	for j in res + 1:
		for i in res + 1:
			var u := float(i) / res
			var v := float(j) / res
			var x := (u - 0.5) * size
			var z := (v - 0.5) * size
			var h := n1.get_noise_2d(x, z) * 0.9 + n2.get_noise_2d(x, z) * 0.2
			pts.append(Vector3(x, -absf(h) * _edge_mask(u, v), z))
	b.grid(Kit.stone("rock"), pts, res + 1, res + 1, Vector3.DOWN, 0.5)
	return Kit.asset("CaveCeiling_%dm" % roundi(size), b, "trimesh")
