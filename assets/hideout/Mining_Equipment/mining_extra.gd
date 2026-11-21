extends RefCounted
## Wheelbarrow, hammer, winch, pulley gantry, timber support frames, broken tools and rubble.

const Kit := preload("res://assets/hideout/Materials/kit.gd")


## Wooden wheelbarrow, wheel at the front (+Z). loaded = heaped with ore.
static func wheelbarrow(loaded := false, seed_ := 81) -> Node3D:
	var b := Kit.MB.new(seed_)
	var iron := Kit.iron()
	# tray
	b.box(Kit.wood("aged"), Vector3(0, 0.44, 0.1), Vector3(0.5, 0.035, 0.62), Basis(), 0.003)
	for sx in [-1, 1]:
		for i in 2:
			b.box(Kit.wood("aged") if i == 0 else Kit.wood("grey"), Vector3(sx * (0.27 + 0.03 * i), 0.5 + 0.1 * i, 0.1), Vector3(0.03, 0.1, 0.66),
				Basis(Vector3.BACK, sx * 0.3), 0.003)
	for i in 2:
		b.box(Kit.wood("aged"), Vector3(0, 0.5 + 0.1 * i, 0.46 + 0.04 * i), Vector3(0.52 + 0.06 * i, 0.1, 0.03), Basis(Vector3.RIGHT, 0.4), 0.003)
	b.box(Kit.wood("grey"), Vector3(0, 0.52, -0.2), Vector3(0.5, 0.2, 0.03), Basis(), 0.003)
	# handles, legs
	for sx in [-1, 1]:
		b.cyl(Kit.wood("dark"), Vector3(sx * 0.22, 0.4, 0.5), Vector3(sx * 0.26, 0.66, -0.95), 0.025, 0.03, 6, 0.05, true, 3)
		b.cyl(Kit.wood("dark"), Vector3(sx * 0.25, 0.55, -0.45), Vector3(sx * 0.27, 0.0, -0.58), 0.025, 0.022, 6, 0.05)
	# wheel (axis along X)
	b.cyl(Kit.wood("aged"), Vector3(-0.025, 0.2, 0.62), Vector3(0.025, 0.2, 0.62), 0.2, 0.2, 14, 0.02)
	b.push(Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, 0.2, 0.62)))
	b.lathe(iron, PackedVector2Array([Vector2(0.2, -0.035), Vector2(0.214, -0.035), Vector2(0.214, 0.035), Vector2(0.2, 0.035)]), 18)
	b.pop()
	b.cyl(Kit.wood("dark"), Vector3(-0.06, 0.2, 0.62), Vector3(0.06, 0.2, 0.62), 0.04, 0.04, 8)
	for sx in [-1, 1]:
		b.cyl(iron, Vector3(sx * 0.07, 0.2, 0.62), Vector3(sx * 0.13, 0.2, 0.62), 0.016, 0.016, 6)
		b.cyl(iron, Vector3(sx * 0.13, 0.2, 0.62), Vector3(sx * 0.26, 0.2, 0.55), 0.012, 0.012, 5)
	if loaded:
		for i in 7:
			b.blob(Kit.stone("ore") if i % 2 else Kit.stone("dark"), Vector3(b.rng.randf_range(-0.15, 0.15), 0.5 + b.rng.randf() * 0.07, b.rng.randf_range(-0.05, 0.3)),
				Vector3(0.09, 0.07, 0.08) * b.rng.randf_range(0.8, 1.3), b.rng.randi() % 100, 0.3, 1.8, 4, 7, Basis(Vector3.UP, b.rng.randf() * TAU), true, 0.6)
	return Kit.asset("Wheelbarrow_" + ("Loaded" if loaded else "Empty"), b, "convex")


## Sledge/mining hammer lying on the ground. Origin at the handle middle.
static func hammer(seed_ := 82) -> Node3D:
	var b := Kit.MB.new(seed_)
	b.cyl(Kit.wood("aged"), Vector3(-0.4, 0.025, 0), Vector3(0.38, 0.03, 0), 0.024, 0.02, 6, 0.04, true, 3)
	b.box(Kit.iron(), Vector3(0.36, 0.05, 0), Vector3(0.1, 0.1, 0.1), Basis(Vector3.BACK, 0.0), 0.004)
	b.box(Kit.iron(), Vector3(0.36, 0.05, 0), Vector3(0.22, 0.085, 0.085), Basis(), 0.004)
	return Kit.asset("MiningHammer", b, "none")


## Hand winch over a shaft: A-frame, wooden drum with rope, crank and a hanging bucket. Origin at the center of the base.
static func winch(seed_ := 83) -> Node3D:
	var b := Kit.MB.new(seed_)
	var iron := Kit.iron()
	for sz in [-1, 1]:
		b.cyl(Kit.wood("dark"), Vector3(-0.35, 0.05, sz * 0.6), Vector3(0.35, 0.05, sz * 0.6), 0.07, 0.07, 6, 0.04, true, 2)
		b.cyl(Kit.wood("grey"), Vector3(-0.3, 0.05, sz * 0.6), Vector3(-0.08, 1.55, sz * 0.38), 0.065, 0.055, 7, 0.05, true, 4)
		b.cyl(Kit.wood("grey"), Vector3(0.3, 0.05, sz * 0.6), Vector3(0.08, 1.55, sz * 0.38), 0.065, 0.055, 7, 0.05, true, 4)
	b.cyl(Kit.wood("dark"), Vector3(-0.5, 1.45, 0.38), Vector3(0.5, 1.45, 0.38), 0.0, 0.0, 3)
	var ay := 1.38
	# drum along Z
	b.cyl(Kit.wood("aged"), Vector3(0, ay, -0.35), Vector3(0, ay, 0.35), 0.12, 0.12, 10, 0.02, true, 1)
	for z in [-0.3, -0.22, -0.14, -0.06, 0.02, 0.1, 0.18, 0.26]:
		b.cyl(Kit.rope(), Vector3(0, ay, z), Vector3(0, ay, z + 0.06), 0.135, 0.135, 10, 0.03, false)
	b.cyl(iron, Vector3(0, ay, -0.6), Vector3(0, ay, 0.6), 0.018, 0.018, 6)
	b.cyl(iron, Vector3(0, ay, 0.6), Vector3(0.22, ay + 0.2, 0.6), 0.016, 0.016, 5)
	b.cyl(Kit.wood("dark"), Vector3(0.22, ay + 0.2, 0.55), Vector3(0.22, ay + 0.2, 0.7), 0.025, 0.025, 6)
	# rope down to a bucket
	b.cyl(Kit.rope(), Vector3(0.0, ay - 0.13, 0.3), Vector3(0.0, 0.55, 0.3), 0.017, 0.017, 6, 0.1, false, 4)
	b.cyl(Kit.wood("aged"), Vector3(0, 0.1, 0.3), Vector3(0, 0.46, 0.3), 0.15, 0.19, 10, 0.03, true, 2)
	b.lathe(iron, PackedVector2Array([Vector2(0.178, 0.34), Vector2(0.188, 0.34), Vector2(0.188, 0.4), Vector2(0.178, 0.4)]), 12)
	return Kit.asset("Winch", b, "convex")


## Pulley gantry: post, arm with a sheave wheel at the tip, hanging rope, hook and block. Origin at the foot.
static func pulley(seed_ := 84) -> Node3D:
	var b := Kit.MB.new(seed_)
	var iron := Kit.iron()
	b.cyl(Kit.wood("grey"), Vector3.ZERO, Vector3(0, 2.5, 0), 0.1, 0.085, 8, 0.05, true, 5)
	b.cyl(Kit.wood("dark"), Vector3(0, 2.3, 0), Vector3(1.25, 2.5, 0), 0.06, 0.05, 7, 0.05, true, 4)
	b.cyl(Kit.wood("dark"), Vector3(0, 1.7, 0), Vector3(0.7, 2.35, 0), 0.04, 0.04, 6, 0.05)
	# sheave
	b.cyl(iron, Vector3(1.25, 2.42, -0.04), Vector3(1.25, 2.42, 0.04), 0.1, 0.1, 14)
	for sz in [-1, 1]:
		b.box(iron, Vector3(1.25, 2.4, sz * 0.065), Vector3(0.05, 0.3, 0.012))
	b.cyl(iron, Vector3(1.25, 2.42, -0.07), Vector3(1.25, 2.42, 0.07), 0.015, 0.015, 6)
	# rope over the wheel and down both sides
	b.cyl(Kit.rope(), Vector3(1.15, 2.42, 0), Vector3(1.15, 0.9, 0), 0.016, 0.016, 5, 0.1, false, 4)
	b.cyl(Kit.rope(), Vector3(1.35, 2.42, 0), Vector3(1.35, 0.4, 0.0), 0.016, 0.016, 5, 0.1, false, 3)
	# hook block
	b.box(Kit.wood("dark"), Vector3(1.15, 0.85, 0), Vector3(0.1, 0.14, 0.07), Basis(), 0.003)
	b.cyl(iron, Vector3(1.15, 0.78, 0), Vector3(1.15, 0.6, 0), 0.015, 0.015, 5)
	b.box(iron, Vector3(1.15, 0.56, 0), Vector3(0.05, 0.07, 0.02))
	# rope tail coiled at the base
	for i in 3:
		b.cyl(Kit.rope(), Vector3(1.35 + 0.1 * i, 0.15, 0.0), Vector3(1.4 + 0.12 * i, 0.03, 0.15), 0.016, 0.016, 5, 0.1, false)
	return Kit.asset("PulleyGantry", b, "convex")


## Mine entrance timber set: two hewn posts, cap beam and corner braces. kind: "intact" or "broken" (a post kicked out, cap cracked).
## Origin at the bottom center; the opening is walkable (trimesh collision).
static func support_frame(w := 2.4, h := 2.4, kind := "intact", seed_ := 85) -> Node3D:
	var b := Kit.MB.new(seed_)
	var lean := 0.0
	for sx in [-1, 1]:
		var tilt := 0.0
		var ph := h
		if kind == "broken" and sx == 1:
			tilt = 0.25
			ph = h * 0.92
		b.box(Kit.wood("dark"), Vector3(sx * (w * 0.5 + 0.1) + sin(tilt) * ph * 0.5, ph * 0.5, 0), Vector3(0.24, ph, 0.26), Basis(Vector3.BACK, -tilt), 0.008)
		b.box(Kit.stone("dark"), Vector3(sx * (w * 0.5 + 0.1), 0.0, 0), Vector3(0.38, 0.1, 0.4), Basis(), 0.01)
	b.box(Kit.wood("grey"), Vector3(0, h + 0.12, 0), Vector3(w + 0.8, 0.26, 0.3), Basis(Vector3.BACK, -0.015 if kind == "broken" else 0.004), 0.008)
	for sx in [-1, 1]:
		var a := Vector3(sx * (w * 0.5 - 0.02), h - 0.55, 0.22)
		var c := Vector3(sx * (w * 0.5 - 0.65), h - 0.02, 0.22)
		b.box(Kit.wood("aged"), (a + c) * 0.5, Vector3((c - a).length(), 0.12, 0.1), Kit.basis_x(c - a), 0.004)
		b.box(Kit.iron(), Vector3(sx * (w * 0.5 + 0.1), h * 0.75, 0.14), Vector3(0.27, 0.05, 0.02))
	if kind == "broken":
		b.box(Kit.wood("grey"), Vector3(0.7, 0.03, 0.55), Vector3(0.9, 0.12, 0.2), Basis(Vector3.UP, 0.5), 0.01)
		for i in 5:
			b.blob(Kit.stone("dark"), Vector3(w * 0.5 - 0.3 + b.rng.randf_range(-0.4, 0.5), 0.07, b.rng.randf_range(-0.4, 0.5)), Vector3(0.14, 0.1, 0.12) * b.rng.randf_range(0.6, 1.4),
				i, 0.3, 1.8, 4, 7, Basis(Vector3.UP, b.rng.randf() * TAU), true, 0.4)
	return Kit.asset("SupportFrame_" + kind.capitalize(), b, "trimesh")


## Snapped pickaxe, bent shovel and cracked hammer head dumped together.
static func broken_tools(seed_ := 86) -> Node3D:
	var b := Kit.MB.new(seed_)
	var iron := Kit.iron()
	b.cyl(Kit.wood("aged"), Vector3(-0.4, 0.02, 0.1), Vector3(0.05, 0.02, 0.0), 0.02, 0.016, 6, 0.04, true, 2)
	b.cyl(Kit.wood("grey"), Vector3(0.1, 0.03, 0.12), Vector3(0.32, 0.03, 0.2), 0.016, 0.012, 5, 0.1)
	b.box(iron, Vector3(0.38, 0.04, 0.22), Vector3(0.2, 0.05, 0.05), Basis(Vector3.UP, 0.3), 0.004)
	b.cyl(Kit.wood("aged"), Vector3(-0.3, 0.02, -0.25), Vector3(0.2, 0.025, -0.3), 0.021, 0.018, 6, 0.04)
	b.box(iron, Vector3(0.32, 0.015, -0.35), Vector3(0.22, 0.01, 0.17), Basis(Vector3.UP, -0.2).rotated(Vector3.RIGHT, 0.12), 0.01)
	b.box(iron, Vector3(0.22, 0.02, -0.3), Vector3(0.1, 0.05, 0.05))
	b.box(iron, Vector3(-0.1, 0.06, 0.4), Vector3(0.12, 0.09, 0.09), Basis(Vector3.UP, 0.5), 0.012)
	b.box(iron, Vector3(0.0, 0.05, 0.46), Vector3(0.1, 0.08, 0.08), Basis(Vector3.UP, 1.0), 0.012)
	return Kit.asset("BrokenTools", b, "none")


## Pile of stone rubble. radius ~ footprint.
static func rubble(radius := 1.0, seed_ := 87) -> Node3D:
	var b := Kit.MB.new(seed_)
	var n := int(10 + 16 * radius)
	for i in n:
		var a := b.rng.randf() * TAU
		var r := sqrt(b.rng.randf()) * radius
		var s := b.rng.randf_range(0.5, 1.5) * (1.1 - r / (radius * 1.2) * 0.6) * 0.2 * minf(radius, 1.4) + 0.03
		var m: Material = Kit.stone("rock") if b.rng.randf() < 0.6 else Kit.stone("dark")
		b.blob(m, Vector3(cos(a) * r, s * 0.35 + (radius - r) * 0.18, sin(a) * r), Vector3(s * 1.2, s * 0.8, s), b.rng.randi() % 1000, 0.3, 1.8, 4, 7,
			Basis(Vector3.UP, b.rng.randf() * TAU), true, 0.4)
	return Kit.asset("Rubble_%.1fm" % radius, b, "convex")
