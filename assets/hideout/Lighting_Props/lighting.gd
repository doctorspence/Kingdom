extends RefCounted
## Torches and braziers: the hideout's main light sources. Each carries its own flame and light.

const Kit := preload("res://assets/hideout/Materials/kit.gd")


## Wall torch, mounted on +Z-facing walls: origin at the wall contact point of the bracket.
## design: "bracket" (iron arm + wrapped head) or "cresset" (iron basket with pitch).
static func wall_torch(design := "bracket", light := true, seed_ := 41) -> Node3D:
	var b := Kit.MB.new(seed_)
	var iron := Kit.iron()
	b.box(iron, Vector3(0, 0, 0.012), Vector3(0.12, 0.2, 0.025))             # wall plate
	for s in [-1, 1]:
		b.box(iron, Vector3(0.0, s * 0.07, 0.028), Vector3(0.1, 0.02, 0.012)) # tie bars
	var flame_pos := Vector3(0, 0.55, 0.26)
	match design:
		"bracket":
			b.cyl(iron, Vector3(0, 0, 0.03), Vector3(0, 0.0, 0.24), 0.017, 0.017, 6, 0.0, true)
			b.cyl(iron, Vector3(0, -0.02, 0.24), Vector3(0, 0.36, 0.26), 0.02, 0.02, 6, 0.0, true)
			b.cyl(Kit.wood("burnt"), Vector3(0, 0.34, 0.26), Vector3(0, 0.5, 0.26), 0.04, 0.052, 8, 0.1, true, 2)
			b.cyl(Kit.rope(), Vector3(0, 0.44, 0.26), Vector3(0, 0.5, 0.26), 0.06, 0.06, 8, 0.12, true, 1)
			for i in 3:
				var y := 0.39 + 0.03 * i
				b.cyl(iron, Vector3(0, y, 0.26), Vector3(0, y + 0.012, 0.26), 0.045, 0.045, 8, 0.0, false)
		"cresset":
			b.cyl(iron, Vector3(0, 0, 0.03), Vector3(0, 0.0, 0.22), 0.017, 0.017, 6)
			b.cyl(iron, Vector3(0, -0.02, 0.22), Vector3(0, 0.3, 0.24), 0.02, 0.02, 6)
			var prof := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.06, 0.0), Vector2(0.11, 0.09), Vector2(0.125, 0.15), Vector2(0.11, 0.15), Vector2(0.0, 0.03)])
			b.push(Transform3D(Basis(), Vector3(0, 0.3, 0.26)))
			b.lathe(iron, prof, 8, false)
			for i in 8:
				var a := TAU * float(i) / 8.0
				b.cyl(iron, Vector3(cos(a) * 0.062, 0.0, sin(a) * 0.062), Vector3(cos(a) * 0.125, 0.16, sin(a) * 0.125), 0.008, 0.008, 4)
			b.blob(Kit.plain(Color(0.05, 0.04, 0.035), 0.4), Vector3(0, 0.13, 0), Vector3(0.1, 0.035, 0.1), 3, 0.2, 2.0, 3, 8)
			b.pop()
			flame_pos = Vector3(0, 0.5, 0.26)
	var root := Kit.asset("Torch_" + design.capitalize(), b, "none")
	Kit.fire_fx(root, flame_pos, 0.4, 2.2 if light else 0.0, false)
	return root


## Free-standing wooden torch stand with an iron dish. Origin at the foot.
static func torch_stand(seed_ := 42) -> Node3D:
	var b := Kit.MB.new(seed_)
	var iron := Kit.iron()
	for i in 3:
		var a := TAU * float(i) / 3.0
		b.cyl(Kit.wood("dark"), Vector3(cos(a) * 0.28, 0, sin(a) * 0.28), Vector3(0, 0.55, 0), 0.03, 0.025, 6, 0.05)
	b.cyl(Kit.wood("grey"), Vector3(0, 0, 0), Vector3(0.0, 1.5, 0.0), 0.04, 0.034, 7, 0.06, true, 4)
	var prof := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.05, 0.0), Vector2(0.14, 0.06), Vector2(0.16, 0.08), Vector2(0.0, 0.05)])
	b.push(Transform3D(Basis(), Vector3(0, 1.5, 0)))
	b.lathe(iron, prof, 10, false)
	b.blob(Kit.plain(Color(0.05, 0.04, 0.035), 0.4), Vector3(0, 0.07, 0), Vector3(0.13, 0.04, 0.13), 3, 0.2, 2.0, 3, 8)
	b.pop()
	var root := Kit.asset("TorchStand", b, "convex")
	Kit.fire_fx(root, Vector3(0, 1.72, 0), 0.55, 3.0, true)
	return root


## Iron brazier: bowl on three legs heaped with glowing coals.
static func brazier(seed_ := 43) -> Node3D:
	var b := Kit.MB.new(seed_)
	var iron := Kit.iron()
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.5
		b.cyl(iron, Vector3(cos(a) * 0.3, 0, sin(a) * 0.3), Vector3(cos(a) * 0.15, 0.55, sin(a) * 0.15), 0.022, 0.026, 6)
	var prof := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.14, 0.0), Vector2(0.25, 0.07), Vector2(0.33, 0.2), Vector2(0.35, 0.24), Vector2(0.325, 0.24), Vector2(0.0, 0.05)])
	b.push(Transform3D(Basis(), Vector3(0, 0.52, 0)))
	b.lathe(iron, prof, 14, true)
	for i in 10:
		var a := b.rng.randf() * TAU
		var r := b.rng.randf() * 0.22
		b.blob(Kit.ember() if i % 3 else Kit.plain(Color(0.06, 0.05, 0.05), 0.6), Vector3(cos(a) * r, 0.2 + b.rng.randf() * 0.04, sin(a) * r),
			Vector3(0.06, 0.045, 0.05), i, 0.3, 2.0, 3, 6)
	b.pop()
	var root := Kit.asset("Brazier", b, "convex")
	Kit.fire_fx(root, Vector3(0, 0.82, 0), 0.8, 3.6, true)
	return root
