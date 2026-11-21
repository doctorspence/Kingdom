extends RefCounted
## Chains, hooks, signs and a weapon rack.

const Kit := preload("res://assets/hideout/Materials/kit.gd")


## Hanging chain of alternating links. Origin at the top.
static func chain(length := 1.5, seed_ := 101) -> Node3D:
	var b := Kit.MB.new(seed_)
	var link := 0.058
	var n := int(length / link)
	for i in n:
		var y := -link * (float(i) + 0.5)
		b.push(Transform3D(Basis(Vector3.UP, PI * 0.5 * (i % 2)), Vector3(0, y, 0)))
		# an oval link as a ring of four bars
		b.box(Kit.iron(), Vector3(-0.012, 0, 0), Vector3(0.008, link * 0.95, 0.008))
		b.box(Kit.iron(), Vector3(0.012, 0, 0), Vector3(0.008, link * 0.95, 0.008))
		b.box(Kit.iron(), Vector3(0, link * 0.46, 0), Vector3(0.032, 0.008, 0.008))
		b.box(Kit.iron(), Vector3(0, -link * 0.46, 0), Vector3(0.032, 0.008, 0.008))
		b.pop()
	b.cyl(Kit.iron(), Vector3(0, 0.0, 0), Vector3(0, 0.05, 0), 0.02, 0.02, 6)
	return Kit.asset("Chain_%.1fm" % length, b, "none")


## Wall hook: plate with a curved iron hook. kind: "iron" or "rope" (a looped rope hanging on it). Faces +Z, origin at the wall contact.
static func hook(kind := "iron", seed_ := 102) -> Node3D:
	var b := Kit.MB.new(seed_)
	var iron := Kit.iron()
	b.box(iron, Vector3(0, 0, 0.01), Vector3(0.08, 0.14, 0.02))
	b.cyl(iron, Vector3(0, 0.0, 0.02), Vector3(0, 0.0, 0.14), 0.014, 0.012, 6)
	for i in 6:
		var a0 := PI * float(i) / 6.0
		var a1 := PI * float(i + 1) / 6.0
		b.cyl(iron, Vector3(0, 0.0 + sin(a0) * 0.05 * 0.0 + (1.0 - cos(a0)) * 0.03, 0.14 + sin(a0) * 0.035),
			Vector3(0, (1.0 - cos(a1)) * 0.03, 0.14 + sin(a1) * 0.035), 0.012, 0.011, 5)
	if kind == "rope":
		for i in 8:
			var a0 := TAU * float(i) / 8.0
			var a1 := TAU * float(i + 1) / 8.0
			b.cyl(Kit.rope(), Vector3(cos(a0) * 0.07, -0.1 + sin(a0) * 0.1, 0.12), Vector3(cos(a1) * 0.07, -0.1 + sin(a1) * 0.1, 0.12), 0.012, 0.012, 5, 0.1, false)
	return Kit.asset("Hook_" + kind.capitalize(), b, "none")


## Signs. kind: "post" (board on a post with an arrow), "mining" (hanging board with crossed picks).
static func sign_board(kind := "post", seed_ := 103) -> Node3D:
	var b := Kit.MB.new(seed_)
	var iron := Kit.iron()
	var paint := Kit.plain(Color(0.14, 0.11, 0.09), 0.9)
	match kind:
		"mining":
			for sx in [-1, 1]:
				b.cyl(Kit.rope(), Vector3(sx * 0.3, 0.55, 0.0), Vector3(sx * 0.3, 1.05, 0.0), 0.012, 0.012, 5, 0.1, false)
			for i in 3:
				b.box(Kit.wood("grey") if i == 1 else Kit.wood("aged"), Vector3(0, 0.45 + 0.1 * i, 0), Vector3(0.74, 0.095, 0.03), Basis(Vector3.BACK, b.rng.randf_range(-0.01, 0.01)), 0.003)
			# crossed picks, burnt in
			for s in [-1, 1]:
				b.box(paint, Vector3(0, 0.55, 0.018), Vector3(0.46, 0.025, 0.006), Basis(Vector3.BACK, s * 0.7))
				b.box(paint, Vector3(s * 0.15, 0.7, 0.018), Vector3(0.16, 0.03, 0.006), Basis(Vector3.BACK, -s * 0.5))
			b.box(Kit.wood("dark"), Vector3(0, 0.62, -0.03), Vector3(0.1, 0.5, 0.025))
		_:
			b.cyl(Kit.wood("grey"), Vector3.ZERO, Vector3(0, 1.8, 0), 0.05, 0.045, 7, 0.06, true, 4)
			var ang := b.rng.randf_range(-0.06, 0.06)
			b.push(Transform3D(Basis(Vector3.BACK, ang), Vector3(0.25, 1.55, 0.06)))
			b.box(Kit.wood("aged"), Vector3.ZERO, Vector3(0.7, 0.22, 0.03), Basis(), 0.003)
			b.tri(paint, Vector3(0.2, 0.0, 0.017), Vector3(0.05, 0.07, 0.017), Vector3(0.05, -0.07, 0.017), Vector3(0, 0, 1))
			b.box(paint, Vector3(-0.1, 0.0, 0.017), Vector3(0.5, 0.03, 0.006))
			b.pop()
			b.box(iron, Vector3(0.0, 1.55, 0.04), Vector3(0.05, 0.03, 0.01))
	return Kit.asset("Sign_" + kind.capitalize(), b, "convex")


## Wall-mounted weapon rack with a sword, hand axe, spear and short bow: plain, practical sizes. Faces +Z, origin at the bottom center of the back board.
static func weapon_rack(seed_ := 104) -> Node3D:
	var b := Kit.MB.new(seed_)
	var iron := Kit.iron()
	b.box(Kit.wood("dark"), Vector3(0, 1.0, 0), Vector3(1.6, 0.14, 0.05), Basis(), 0.004)
	b.box(Kit.wood("dark"), Vector3(0, 1.6, 0), Vector3(1.6, 0.12, 0.05), Basis(), 0.004)
	for sx in [-1, 1]:
		b.box(Kit.wood("grey"), Vector3(sx * 0.75, 1.3, 0.0), Vector3(0.1, 1.0, 0.05), Basis(), 0.004)
	# pegs
	for x in [-0.55, -0.2, 0.15, 0.5]:
		b.cyl(Kit.wood("aged"), Vector3(x, 1.0, 0.03), Vector3(x, 1.0, 0.15), 0.02, 0.018, 6)
		b.cyl(Kit.wood("aged"), Vector3(x, 1.6, 0.03), Vector3(x, 1.6, 0.15), 0.02, 0.018, 6)
	# arming sword hanging by its guard
	b.push(Transform3D(Basis(), Vector3(-0.55, 0, 0.12)))
	b.box(iron, Vector3(0, 1.22, 0), Vector3(0.05, 0.78, 0.012))
	b.box(iron, Vector3(0, 1.62 - 0.0, 0), Vector3(0.22, 0.025, 0.025))
	b.cyl(Kit.wood("dark"), Vector3(0, 1.64, 0), Vector3(0, 1.76, 0), 0.016, 0.016, 6)
	b.pop()
	# hand axe
	b.push(Transform3D(Basis(), Vector3(-0.2, 0, 0.12)))
	b.cyl(Kit.wood("aged"), Vector3(0, 1.0, 0), Vector3(0, 1.62, 0), 0.02, 0.018, 6, 0.04, true, 2)
	b.box(iron, Vector3(0.07, 1.55, 0), Vector3(0.14, 0.14, 0.03), Basis(Vector3.BACK, 0.0), 0.006)
	b.pop()
	# spear
	b.push(Transform3D(Basis(), Vector3(0.15, 0, 0.12)))
	b.cyl(Kit.wood("aged"), Vector3(0, 0.55, 0), Vector3(0, 2.0, 0), 0.018, 0.016, 6, 0.03, true, 5)
	b.box(iron, Vector3(0, 2.07, 0), Vector3(0.05, 0.16, 0.012), Basis(), 0.002)
	b.pop()
	# short bow with a string
	for i in 6:
		var t0 := float(i) / 6.0
		var t1 := float(i + 1) / 6.0
		var f := func(t: float) -> Vector3:
			return Vector3(0.5 + sin(t * PI) * 0.05, 1.0 + t * 0.62, 0.12)
		b.cyl(Kit.wood("dark"), f.call(t0), f.call(t1), 0.018, 0.016, 5)
	b.cyl(Kit.rope(), Vector3(0.5, 1.0, 0.12), Vector3(0.5, 1.62, 0.12), 0.003, 0.003, 3, 0.0, false)
	return Kit.asset("WeaponRack", b, "convex")
