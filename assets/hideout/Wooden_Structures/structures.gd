extends RefCounted
## Crude scavenged-timber structures. Modular rules so pieces snap together:
##  - platform: origin at the CENTER of the deck TOP surface; deck is w x d meters, legs hang below.
##  - stairs: origin at bottom-front-center, climbing toward -Z; the top tread ends at y = rise.
##  - railing: origin at the bottom of its first post, runs along +X.
##  - ladder / post: origin at the foot, centered.

const Kit := preload("res://assets/hideout/Materials/kit.gd")


## Deck on log posts with joists and bracing. w along X, d along Z (use multiples of 2 to tile).
## leg = height of the deck above the ground. kind: "plain" or "worn" (rotten, missing boards).
static func platform(w := 4.0, d := 2.0, leg := 1.5, kind := "plain", seed_ := 1) -> Node3D:
	var b := Kit.MB.new(seed_)
	var wood := Kit.wood("aged")
	var plank_w := 0.2
	var n := int(floor(w / (plank_w + 0.012)))
	var pitch := w / n
	for i in n:
		if kind == "worn" and (i == 3 or i == n - 4):
			continue
		var x := -w * 0.5 + pitch * (float(i) + 0.5)
		var m: Material = wood
		var th := 0.05
		var r := b.rng.randf()
		if r < 0.12:
			m = Kit.wood("fresh")
			th = 0.04
		elif r < 0.35:
			m = Kit.wood("grey")
		var yaw := b.rng.randf_range(-0.006, 0.006)
		var len := d + b.rng.randf_range(-0.02, 0.05)
		b.box(m, Vector3(x, -th * 0.5 + b.rng.randf_range(-0.004, 0.004), b.rng.randf_range(-0.02, 0.02)),
			Vector3(pitch - 0.012, th, len), Basis(Vector3.UP, yaw), 0.003)
	# joists (under the deck, along X) resting on two beams (along Z)
	var jz := [-d * 0.5 + 0.15, 0.0, d * 0.5 - 0.15]
	for z in jz:
		b.box(Kit.wood("dark"), Vector3(0, -0.12, z), Vector3(w + 0.06, 0.12, 0.09), Basis(Vector3.BACK, b.rng.randf_range(-0.004, 0.004)), 0.004)
	var bx := w * 0.5 - 0.2
	for sx in [-1, 1]:
		b.box(Kit.wood("dark"), Vector3(sx * bx, -0.26, 0), Vector3(0.14, 0.17, d + 0.1), Basis(), 0.004)
	# round log posts with diagonal bracing
	var pz := d * 0.5 - 0.15
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var foot := -leg
			var jit := Vector3(b.rng.randf_range(-0.02, 0.02), 0, b.rng.randf_range(-0.02, 0.02))
			b.cyl(Kit.wood("grey"), Vector3(sx * bx, foot, sz * pz) + jit, Vector3(sx * bx, -0.18, sz * pz), 0.085, 0.075, 7, 0.06, true, 3)
			# footing stone
			b.blob(Kit.stone("dark"), Vector3(sx * bx, foot + 0.02, sz * pz), Vector3(0.18, 0.1, 0.18), b.rng.randi() % 100, 0.3, 2.0, 4, 8, Basis(), true, 0.4)
		# X-bracing between the two posts on this side (skipped for low platforms)
		if leg > 0.9:
			b.cyl(Kit.wood("grey"), Vector3(sx * bx, -leg + 0.25, -pz), Vector3(sx * bx, -0.45, pz), 0.04, 0.04, 6, 0.1)
			b.cyl(Kit.wood("grey"), Vector3(sx * bx, -leg + 0.25, pz), Vector3(sx * bx, -0.45, -pz), 0.04, 0.04, 6, 0.1)
	if leg > 0.9:
		for sz in [-1, 1]:
			b.cyl(Kit.wood("grey"), Vector3(-bx, -leg * 0.55, sz * pz), Vector3(bx, -leg * 0.55, sz * pz), 0.045, 0.045, 6, 0.1)
	return Kit.asset("Platform_%dx%d" % [roundi(w), roundi(d)], b, "trimesh")


## Open-riser stairs: two stringers and uneven treads. rise = total height gained.
static func stairs(rise := 1.5, width := 1.0, seed_ := 2) -> Node3D:
	var b := Kit.MB.new(seed_)
	var steps := roundi(rise / 0.2)
	var riser := rise / steps
	var run := 0.27
	var length := run * steps
	var dir := Vector3(0, rise, -length)
	var ang := atan2(rise, length)
	for sx in [-1, 1]:
		var x: float = sx * (width * 0.5 - 0.05)
		var a := Vector3(x, -0.04, 0.12)
		var c := Vector3(x, rise - 0.04, -length)
		b.box(Kit.wood("dark"), (a + c) * 0.5 + Vector3(0, -0.1, 0), Vector3((c - a).length() + 0.1, 0.22, 0.07), Kit.basis_x(c - a), 0.004)
	for i in steps:
		var y := riser * (i + 1)
		var z := -run * (i + 0.5) - 0.02
		var m: Material = Kit.wood("fresh") if b.rng.randf() < 0.12 else Kit.wood("aged")
		b.box(m, Vector3(b.rng.randf_range(-0.01, 0.01), y - 0.022, z), Vector3(width + 0.02, 0.045, run + 0.045),
			Basis(Vector3.UP, b.rng.randf_range(-0.012, 0.012)), 0.003)
		# nails
		for sx in [-1, 1]:
			b.box(Kit.iron(), Vector3(sx * (width * 0.5 - 0.05), y + 0.003, z + 0.07), Vector3(0.02, 0.01, 0.02))
	return Kit.asset("Stairs_%.1fm" % rise, b, "trimesh")


## Posts every ~1 m with two crooked log rails. Runs along +X from the origin.
static func railing(length := 2.0, h := 1.0, seed_ := 3) -> Node3D:
	var b := Kit.MB.new(seed_)
	var count := ceili(length / 1.0) + 1
	for i in count:
		var x := length * float(i) / (count - 1)
		var ph := h + b.rng.randf_range(-0.05, 0.08)
		b.box(Kit.wood("dark"), Vector3(x, ph * 0.5, 0), Vector3(0.075, ph, 0.075), Basis(Vector3.BACK, b.rng.randf_range(-0.02, 0.02)), 0.004)
	for ry in [h * 0.92, h * 0.5]:
		var sag := b.rng.randf_range(-0.03, 0.03)
		b.cyl(Kit.wood("grey"), Vector3(-0.04, ry + sag, 0.055), Vector3(length + 0.04, ry - sag, 0.055), 0.032, 0.03, 6, 0.12, true, 4)
	# rope lashings
	for i in count:
		var x := length * float(i) / (count - 1)
		b.cyl(Kit.rope(), Vector3(x, h * 0.92 - 0.03, 0.0), Vector3(x, h * 0.92 + 0.03, 0.0), 0.06, 0.06, 8, 0.05, false)
	return Kit.asset("Railing_%.1fm" % length, b, "convex")


## Round-rail ladder, lashed rungs.
static func ladder(height := 2.4, seed_ := 5) -> Node3D:
	var b := Kit.MB.new(seed_)
	var half := 0.22
	for sx in [-1, 1]:
		b.cyl(Kit.wood("grey"), Vector3(sx * half, 0, 0), Vector3(sx * half + b.rng.randf_range(-0.01, 0.01), height, 0), 0.04, 0.036, 7, 0.08, true, 4)
	var rungs := int(height / 0.3)
	for i in rungs:
		var y := 0.28 + 0.3 * i
		b.cyl(Kit.wood("aged"), Vector3(-half - 0.03, y + b.rng.randf_range(-0.012, 0.012), 0), Vector3(half + 0.03, y + b.rng.randf_range(-0.012, 0.012), 0), 0.024, 0.024, 6, 0.1)
		for sx in [-1, 1]:
			b.cyl(Kit.rope(), Vector3(sx * half, y - 0.022, 0), Vector3(sx * half, y + 0.022, 0), 0.048, 0.048, 8, 0.06, false)
	return Kit.asset("Ladder_%.1fm" % height, b, "convex")


## Round support post (log). Several heights give variety.
static func post(h := 2.4, r := 0.11, seed_ := 6) -> Node3D:
	var b := Kit.MB.new(seed_)
	b.cyl(Kit.wood("grey"), Vector3.ZERO, Vector3(b.rng.randf_range(-0.02, 0.02), h, 0), r * 1.1, r * 0.92, 8, 0.07, true, 6)
	# a couple of old branch stubs
	for i in 2:
		var y := h * b.rng.randf_range(0.25, 0.8)
		var a := b.rng.randf() * TAU
		b.cyl(Kit.wood("grey"), Vector3(0, y, 0), Vector3(cos(a) * r * 1.6, y + 0.04, sin(a) * r * 1.6), r * 0.25, r * 0.15, 5, 0.1, true)
	return Kit.asset("Post_%.1fm" % h, b, "convex")


## Hewn crossbeam with an iron strap. Runs along +X, origin at center.
static func crossbeam(length := 3.0, seed_ := 7) -> Node3D:
	var b := Kit.MB.new(seed_)
	b.box(Kit.wood("dark"), Vector3.ZERO, Vector3(length, 0.2, 0.16), Basis(Vector3.BACK, b.rng.randf_range(-0.01, 0.01)), 0.006)
	for sx in [-1, 1]:
		b.box(Kit.iron(), Vector3(sx * (length * 0.5 - 0.3), 0, 0), Vector3(0.05, 0.215, 0.175))
	return Kit.asset("Crossbeam_%.1fm" % length, b, "convex")
