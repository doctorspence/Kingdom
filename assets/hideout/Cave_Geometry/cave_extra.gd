extends RefCounted
## Tunnels, cave mouths, collapses, pillars and ledges.

const Kit := preload("res://assets/hideout/Materials/kit.gd")


static func _noise(seed_: int, freq: float, octaves := 4) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = seed_
	n.frequency = freq
	n.fractal_octaves = octaves
	return n


## Natural tunnel: rough arched passage along Z with its own floor. Both ends pin to the same
## clean arch (width x height) so tunnel sections chain together. Origin at the floor center of the middle.
static func tunnel(length := 4.0, w := 3.2, h := 2.8, seed_ := 111) -> Node3D:
	var b := Kit.MB.new(seed_)
	var n1 := _noise(seed_, 0.45)
	var n2 := _noise(seed_ + 5, 1.2, 3)
	var nu := 20
	var nv := 14
	var pts := PackedVector3Array()
	for j in nv + 1:
		var v := float(j) / nv
		var z := (v - 0.5) * length
		var mask := smoothstep(0.0, 0.14, minf(v, 1.0 - v))
		for i in nu + 1:
			var phi := PI * float(i) / nu
			var x := -cos(phi) * w * 0.5
			var y := sin(phi) * h
			var d := (n1.get_noise_2d(phi * 1.5, z) * 0.35 + n2.get_noise_2d(phi * 3.0, z * 2.0) * 0.1) * mask
			# push toward / away from the axis
			var dir := Vector2(x, y - h * 0.4).normalized()
			pts.append(Vector3(x + dir.x * d, y + dir.y * d * 0.8, z))
	# rows go left -> right over the top, advancing +Z: the as-built winding faces inward
	b.grid(Kit.stone("rock"), pts, nu + 1, nv + 1, Vector3.ZERO, 0.5)
	# floor
	var fr := 14
	var fpts := PackedVector3Array()
	for j in nv + 1:
		var v := float(j) / nv
		var z := (v - 0.5) * length
		for i in fr + 1:
			var u := float(i) / fr
			var x := (u - 0.5) * w
			var mask := smoothstep(0.0, 0.14, minf(v, 1.0 - v)) * smoothstep(0.0, 0.2, minf(u, 1.0 - u))
			fpts.append(Vector3(x, n1.get_noise_2d(x * 1.2, z) * 0.14 * mask, z))
	b.grid(Kit.dirt(), fpts, fr + 1, nv + 1, Vector3.UP, 0.5)
	return Kit.asset("Tunnel_%dm" % roundi(length), b, "trimesh")


## Cave mouth: a rough rock arch of boulders around a black opening. Faces +Z. Origin at the center of the floor line.
static func cave_opening(w := 3.2, h := 3.0, seed_ := 112, fill_to := 0.0) -> Node3D:
	var b := Kit.MB.new(seed_)
	var mat := Kit.stone("rock")
	var count := 15
	for i in count:
		var t := float(i) / (count - 1)
		var a := PI * t
		var x := -cos(a) * (w * 0.5 + 0.25)
		var y := sin(a) * (h + 0.1)
		var s := b.rng.randf_range(0.5, 0.75)
		b.blob(mat, Vector3(x, y, b.rng.randf_range(-0.1, 0.15)), Vector3(s, s * 0.9, 0.7), b.rng.randi() % 1000, 0.35, 1.3, 8, 12,
			Basis(Vector3.UP, b.rng.randf_range(-0.3, 0.3)), false, 1.0)
	# massive shoulders and lintel rock
	for sx in [-1, 1]:
		b.blob(mat, Vector3(sx * (w * 0.5 + 1.3), 1.4, -0.3), Vector3(1.1, 1.6, 0.9), 7 + sx, 0.4, 1.2, 9, 14, Basis(), false, 0.5)
	b.blob(mat, Vector3(0, h + 0.8, -0.4), Vector3(w * 0.7, 0.9, 0.9), 11, 0.38, 1.2, 9, 14, Basis(), false, 1.0)
	if fill_to > h + 1.4:
		var cy := (h + 1.0 + fill_to) * 0.5
		var ry := (fill_to - h - 1.0) * 0.5 + 0.5
		for x in [-2.2, 0.0, 2.2]:
			b.blob(mat, Vector3(x, cy, -0.4), Vector3(1.5, ry, 0.9), 20 + int(x * 3.0), 0.3, 1.2, 8, 12, Basis(), false, 1.0)
	# dark inside
	b.quad(Kit.plain(Color(0.0, 0.0, 0.0), 1.0), Vector3(-w * 0.5, 0, -0.8), Vector3(w * 0.5, 0, -0.8), Vector3(w * 0.5, h, -0.8), Vector3(-w * 0.5, h, -0.8), Vector3(0, 0, 1))
	return Kit.asset("CaveOpening", b, "none")


## Rock fall that blocks a passage (about tunnel width). Faceted boulders and dust. Origin at the floor center.
static func collapsed_rock(w := 3.2, h := 2.6, seed_ := 113) -> Node3D:
	var b := Kit.MB.new(seed_)
	for i in 22:
		var x := b.rng.randf_range(-w * 0.5, w * 0.5)
		var yb := b.rng.randf() * h * 0.85 * (1.0 - absf(x) / (w * 0.6))
		var s := b.rng.randf_range(0.25, 0.65) * (1.0 + (1.0 - yb / h) * 0.2)
		var m: Material = Kit.stone("rock") if b.rng.randf() < 0.65 else Kit.stone("dark")
		b.blob(m, Vector3(x, yb, b.rng.randf_range(-0.4, 0.4)), Vector3(s, s * 0.8, s * 0.9), b.rng.randi() % 1000, 0.35, 1.6, 5, 8,
			Basis(Vector3.UP, b.rng.randf() * TAU).rotated(Vector3.RIGHT, b.rng.randf_range(-0.4, 0.4)), true, 1.0)
	for i in 14:
		var a := b.rng.randf() * TAU
		var r := b.rng.randf_range(0.6, 1.6)
		b.blob(Kit.stone("dark"), Vector3(cos(a) * r * (w * 0.4), 0.05, 0.6 + sin(a) * 0.5), Vector3(0.09, 0.06, 0.08), i, 0.3, 1.8, 4, 6, Basis(Vector3.UP, a), true, 0.4)
	return Kit.asset("CollapsedRock", b, "convex")


## Floor-to-ceiling rock pillar with flared ends. Origin at the foot.
static func rock_pillar(height := 3.2, radius := 0.55, seed_ := 114) -> Node3D:
	var b := Kit.MB.new(seed_)
	var mat := Kit.stone("rock")
	b.cyl(mat, Vector3(0, 0.0, 0), Vector3(0, height, 0), radius * 0.78, radius * 0.78, 12, 0.14, true, 12)
	for e in [0.0, height]:
		var dir := 1.0 if e == 0.0 else -1.0
		b.blob(mat, Vector3(0, e + dir * 0.2, 0), Vector3(radius * 1.35, 0.35, radius * 1.35), int(e) + 5, 0.3, 1.5, 6, 14, Basis(), false, 1.0)
	return Kit.asset("RockPillar", b, "convex")


## Natural stone ledge shelf against a wall, usable as a stepping ledge. Origin at the back-center of its base.
static func stone_ledge(length := 3.0, seed_ := 115) -> Node3D:
	var b := Kit.MB.new(seed_)
	var mat := Kit.stone("rock")
	var n := int(length / 0.8)
	for i in n:
		var x := -length * 0.5 + length * (float(i) + 0.5) / n
		b.blob(mat, Vector3(x, 0.22, 0.35), Vector3(length / n * 0.85, 0.3, 0.55), b.rng.randi() % 1000, 0.25, 1.4, 7, 12, Basis(Vector3.UP, b.rng.randf_range(-0.2, 0.2)), false, 0.3)
	b.blob(Kit.stone("dark"), Vector3(0, 0.1, 0.9), Vector3(length * 0.3, 0.1, 0.25), 9, 0.25, 1.4, 4, 8, Basis(), true, 0.3)
	return Kit.asset("StoneLedge_%dm" % roundi(length), b, "convex")


## Wet wall tile: darker and glossier. Same footprint/seams as wall_section (facing +Z).
static func wet_wall(w := 4.0, h := 3.6, seed_ := 116) -> Node3D:
	var cave := load("res://assets/hideout/Cave_Geometry/cave.gd") as GDScript
	var node: Node3D = cave.wall_section(w, h, seed_)
	var mi := node.get_node("Mesh") as MeshInstance3D
	for s in mi.mesh.get_surface_count():
		mi.mesh.surface_set_material(s, Kit.stone("wet"))
	node.name = "WetWall_%dm" % roundi(w)
	return node
