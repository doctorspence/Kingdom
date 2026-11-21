extends RefCounted
## Barrels, crates and sacks. Origins sit at the center of the base (resting on y = 0).

const Kit := preload("res://assets/hideout/Materials/kit.gd")


# ---------------------------------------------------------------- barrels

## kind: "small", "large", "water" (open, full), "grain" (open, heaped), "broken"
static func barrel(kind := "large", seed_ := 1) -> Node3D:
	var b := Kit.MB.new(seed_)
	add_barrel(b, kind)
	return Kit.asset("Barrel_" + kind.capitalize(), b, "convex")


## Three barrels: two upright, one lying across the tops.
static func barrel_stack(seed_ := 4) -> Node3D:
	var b := Kit.MB.new(seed_)
	b.push(Transform3D(Basis(), Vector3(-0.44, 0, 0)))
	add_barrel(b, "large")
	b.pop()
	b.push(Transform3D(Basis(), Vector3(0.44, 0, 0.02)))
	add_barrel(b, "large")
	b.pop()
	b.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5).rotated(Vector3.UP, 0.05), Vector3(0, 1.29, -0.31)))
	add_barrel(b, "small")
	b.pop()
	return Kit.asset("Barrel_Stack", b, "trimesh")


static func add_barrel(b: Kit.MB, kind: String) -> void:
	var h := 1.0
	var re := 0.32
	var rb := 0.4
	var sides := 18
	match kind:
		"small":
			h = 0.64
			re = 0.2
			rb = 0.25
			sides = 14
		"large":
			h = 1.05
			re = 0.33
			rb = 0.42
			sides = 20
		"water", "grain":
			h = 0.92
			re = 0.3
			rb = 0.38
			sides = 18
		"broken":
			h = 0.95
			re = 0.31
			rb = 0.39
			sides = 18
	var thick := 0.024
	var rad := func(t: float) -> float:
		return re + (rb - re) * (1.0 - pow(2.0 * t - 1.0, 2.0))
	var woods := [Kit.wood("aged"), Kit.wood("aged"), Kit.wood("grey"), Kit.wood("dark")]
	var broken := [3, 4, 5, 6] if kind == "broken" else []
	var rows := 6
	for i in sides:
		var a0 := TAU * float(i) / sides
		var a1 := TAU * (float(i) + 0.94) / sides
		var tb := b.rng.randf() * 0.012
		var tl := 1.0 - b.rng.randf() * 0.016
		var tr := tl
		if i in broken:
			tl = b.rng.randf_range(0.3, 0.7)
			tr = b.rng.randf_range(0.3, 0.7)
		var wm: Material = woods[b.rng.randi() % woods.size()]
		var rj := 1.0 + b.rng.randf_range(-0.012, 0.012)
		var am := (a0 + a1) * 0.5
		var radial := Vector3(cos(am), 0, sin(am))
		var uvo := Vector2(b.rng.randf() * 3.0, b.rng.randf() * 3.0)
		for k in rows:
			var t0l := lerpf(tb, tl, float(k) / rows)
			var t1l := lerpf(tb, tl, float(k + 1) / rows)
			var t0r := lerpf(tb, tr, float(k) / rows)
			var t1r := lerpf(tb, tr, float(k + 1) / rows)
			var p00 := _bp(rad, a0, t0l, h, rj, 0.0)
			var p01 := _bp(rad, a1, t0r, h, rj, 0.0)
			var p11 := _bp(rad, a1, t1r, h, rj, 0.0)
			var p10 := _bp(rad, a0, t1l, h, rj, 0.0)
			b.quad(wm, p00, p01, p11, p10, radial, uvo)
			var q00 := _bp(rad, a0, t0l, h, rj, thick)
			var q01 := _bp(rad, a1, t0r, h, rj, thick)
			var q11 := _bp(rad, a1, t1r, h, rj, thick)
			var q10 := _bp(rad, a0, t1l, h, rj, thick)
			b.quad(wm, q00, q01, q11, q10, -radial, uvo)
		# top rim of the stave
		b.quad(wm, _bp(rad, a0, tl, h, rj, 0.0), _bp(rad, a1, tr, h, rj, 0.0),
			_bp(rad, a1, tr, h, rj, thick), _bp(rad, a0, tl, h, rj, thick), Vector3.UP, uvo)
	# floor and head
	b.disc(Kit.wood("dark"), 0.05, re - thick, sides, true)
	match kind:
		"small", "large":
			b.disc(Kit.wood("grey"), h - 0.08, rad.call(1.0 - 0.08 / h) - thick, sides, true)
			# a stave-width plank line and a bung
			b.box(Kit.wood("dark"), Vector3(0.0, h - 0.068, 0.0), Vector3(0.012, 0.004, (re - thick) * 1.8))
			b.cyl(Kit.wood("dark"), Vector3(0.12, h - 0.082, 0.1), Vector3(0.12, h - 0.062, 0.1), 0.03, 0.03, 8, 0.0, true)
		"water":
			b.disc(Kit.water(), h * 0.82, rad.call(0.82) - thick, sides, true)
		"grain":
			b.blob(Kit.cloth("straw"), Vector3(0, h * 0.8, 0), Vector3(re * 0.9, 0.16, re * 0.9), 5, 0.2, 2.5, 6, 14, Basis(), false, 0.3)
		"broken":
			# the head has fallen in
			b.box(Kit.wood("grey"), Vector3(0.04, 0.2, 0.0), Vector3(0.5, 0.025, 0.14), Basis(Vector3.BACK, 0.45).rotated(Vector3.UP, 0.4))
			b.box(Kit.wood("grey"), Vector3(-0.08, 0.14, 0.1), Vector3(0.42, 0.025, 0.13), Basis(Vector3.BACK, -0.3).rotated(Vector3.UP, -0.2))
	# iron hoops (a loose one on the broken barrel)
	var hoops := [0.1, 0.27, 0.73, 0.9]
	for ti in hoops.size():
		var t: float = hoops[ti]
		var y := t * h
		var r: float = rad.call(t) + 0.004
		if kind == "broken" and ti == 3:
			# slipped down and tilted
			b.push(Transform3D(Basis(Vector3.RIGHT, 0.09).rotated(Vector3.BACK, 0.07), Vector3(0.0, 0.14, 0.0)))
			_hoop(b, 0.0, r + 0.03, sides + 4)
			b.pop()
			continue
		if kind == "broken" and ti == 2:
			continue
		_hoop(b, y, r, sides + 4)


static func _bp(rad: Callable, ang: float, t: float, h: float, rj: float, inset: float) -> Vector3:
	var r: float = rad.call(t) * rj - inset
	return Vector3(cos(ang) * r, t * h, sin(ang) * r)


static func _hoop(b: Kit.MB, y: float, r: float, sides: int) -> void:
	var hh := 0.034
	var th := 0.012
	var prof := PackedVector2Array([Vector2(r, y - hh), Vector2(r + th, y - hh), Vector2(r + th, y + hh), Vector2(r, y + hh)])
	b.lathe(Kit.iron(), prof, sides, false)
	# a rivet row
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.4
		b.box(Kit.iron(), Vector3(cos(a) * (r + th), y, sin(a) * (r + th)), Vector3(0.016, 0.016, 0.016), Basis(Vector3.UP, -a))


# ---------------------------------------------------------------- crates

## kind: "small", "large", "open" (supplies), "broken"
static func crate(kind := "small", seed_ := 1) -> Node3D:
	var b := Kit.MB.new(seed_)
	add_crate(b, kind)
	return Kit.asset("Crate_" + kind.capitalize(), b, "convex")


static func add_crate(b: Kit.MB, kind: String) -> void:
	var sx := 0.58
	var sy := 0.46
	var sz := 0.46
	var post := 0.05
	var slat_h := 0.14
	match kind:
		"large":
			sx = 1.05
			sy = 0.88
			sz = 0.86
			post = 0.08
			slat_h = 0.17
		"open":
			sx = 0.8
			sy = 0.52
			sz = 0.6
			post = 0.06
		"broken":
			sx = 0.78
			sy = 0.62
			sz = 0.6
			post = 0.06
	var t := 0.024
	var lift := 0.045
	var wood_a := Kit.wood("aged")
	var iron := Kit.iron()
	var n := roundi((sy - lift) / slat_h)
	var sh := (sy - lift) / n
	var skip_front := [2, 3] if kind == "broken" else []
	# runners and floor
	for sgn in [-1, 1]:
		b.box(Kit.wood("dark"), Vector3(0, lift * 0.5, sgn * (sz * 0.5 - 0.06)), Vector3(sx, lift, 0.09), Basis(), 0.003)
	b.box(wood_a, Vector3(0, lift + 0.012, 0), Vector3(sx - 2.0 * t, 0.024, sz - 2.0 * t))
	# slatted walls
	for i in n:
		var y := lift + sh * (float(i) + 0.5)
		for sgn in [-1, 1]:
			var rz := Basis(Vector3.BACK, b.rng.randf_range(-0.012, 0.012))
			if not (sgn == 1 and i in skip_front):
				b.box(wood_a if b.rng.randf() > 0.2 else Kit.wood("grey"), Vector3(0, y, sgn * (sz * 0.5 - t * 0.5)),
					Vector3(sx + b.rng.randf_range(-0.01, 0.01), sh - 0.014, t), rz, 0.0025)
				for e in [-1, 1]:
					b.box(iron, Vector3(e * (sx * 0.5 - 0.035), y, sgn * (sz * 0.5 + 0.004)), Vector3(0.018, 0.018, 0.01))
			var rx := Basis(Vector3.BACK, b.rng.randf_range(-0.012, 0.012))
			b.box(wood_a if b.rng.randf() > 0.2 else Kit.wood("grey"), Vector3(sgn * (sx * 0.5 - t * 0.5), y, 0),
				Vector3(t, sh - 0.014, sz - 2.0 * t - 0.01), rx, 0.0025)
	# corner posts (a little proud of the walls)
	for sx_s in [-1, 1]:
		for sz_s in [-1, 1]:
			var ph := sy
			if kind == "broken" and sx_s == 1 and sz_s == 1:
				ph = sy * 0.72
			b.box(Kit.wood("dark"), Vector3(sx_s * (sx * 0.5 - post * 0.5 + 0.008), ph * 0.5, sz_s * (sz * 0.5 - post * 0.5 + 0.008)),
				Vector3(post, ph, post), Basis(), 0.003)
	# diagonal brace on the front and one side
	var ang := atan2(sy - lift - 0.1, sx - post * 2.0)
	var blen := sqrt(pow(sx - post * 2.0, 2.0) + pow(sy - lift - 0.1, 2.0))
	if not (kind == "broken"):
		b.box(Kit.wood("dark"), Vector3(0, lift + (sy - lift) * 0.5, sz * 0.5 + 0.012), Vector3(blen, 0.07, 0.02), Basis(Vector3.BACK, ang), 0.002)
	else:
		# snapped brace hanging off one nail
		b.box(Kit.wood("dark"), Vector3(-0.2, 0.3, sz * 0.5 + 0.03), Vector3(0.5, 0.07, 0.02), Basis(Vector3.BACK, 1.15).rotated(Vector3.RIGHT, -0.12), 0.002)
	# lid / contents
	match kind:
		"small", "large":
			var planks := roundi(sz / 0.16)
			var pw := sz / planks
			for i in planks:
				var z := -sz * 0.5 + pw * (float(i) + 0.5)
				b.box(Kit.wood("grey") if b.rng.randf() < 0.25 else wood_a, Vector3(b.rng.randf_range(-0.01, 0.01), sy + 0.014, z),
					Vector3(sx + 0.03, 0.028, pw - 0.012), Basis(Vector3.UP, b.rng.randf_range(-0.02, 0.02)), 0.0025)
			for sgn in [-1, 1]:
				b.box(Kit.wood("dark"), Vector3(sgn * (sx * 0.5 - 0.09), sy + 0.045, 0), Vector3(0.06, 0.03, sz - 0.04))
		"open":
			b.blob(Kit.cloth("straw"), Vector3(0, sy - 0.1, 0), Vector3(sx * 0.5 - 0.02, 0.16, sz * 0.5 - 0.02), 3, 0.18, 2.5, 6, 14, Basis(), false, 0.1)
			add_sack_into(b, Vector3(-0.16, sy - 0.02, 0.0), 0.5, 1)
			add_sack_into(b, Vector3(0.2, sy - 0.05, 0.05), 0.4, 2)
			b.blob(Kit.plain(Color(0.38, 0.22, 0.1), 0.7), Vector3(0.12, sy + 0.1, -0.12), Vector3(0.1, 0.045, 0.045), 7, 0.1, 2.0, 5, 8)
			# a lid plank leaning on the rim
			b.box(wood_a, Vector3(0.1, sy + 0.18, sz * 0.5 + 0.05), Vector3(sx - 0.1, 0.026, 0.15), Basis(Vector3.RIGHT, -0.9), 0.002)
		"broken":
			# lid planks collapsed inwards
			b.box(wood_a, Vector3(-0.1, sy - 0.15, -0.1), Vector3(sx * 0.7, 0.026, 0.14), Basis(Vector3.BACK, 0.35).rotated(Vector3.UP, 0.2), 0.003)
			b.box(Kit.wood("grey"), Vector3(0.12, sy - 0.1, 0.08), Vector3(sx * 0.6, 0.026, 0.14), Basis(Vector3.BACK, -0.5).rotated(Vector3.UP, -0.15), 0.003)
			b.box(wood_a, Vector3(0.0, sy + 0.01, -sz * 0.5 + 0.07), Vector3(sx + 0.03, 0.028, 0.14), Basis(Vector3.RIGHT, 0.0), 0.003)
			# loose plank and splinters on the ground
			b.box(Kit.wood("grey"), Vector3(0.3, 0.014, sz * 0.5 + 0.3), Vector3(0.55, 0.026, 0.15), Basis(Vector3.UP, 0.5), 0.003)
			b.box(Kit.wood("dark"), Vector3(-0.35, 0.012, sz * 0.5 + 0.2), Vector3(0.3, 0.024, 0.12), Basis(Vector3.UP, -0.8), 0.003)


# ---------------------------------------------------------------- sacks

## kind: "grain" (upright, tied), "slumped" (lying over)
static func sack(kind := "grain", seed_ := 1) -> Node3D:
	var b := Kit.MB.new(seed_)
	add_sack_into(b, Vector3.ZERO, 1.0, seed_, kind == "slumped")
	return Kit.asset("Sack_" + kind.capitalize(), b, "convex")


static func add_sack_into(b: Kit.MB, pos: Vector3, s: float, seed_: int, slumped := false) -> void:
	var mat := Kit.cloth("burlap") if seed_ % 2 == 1 else Kit.cloth("grain")
	if slumped:
		b.blob(mat, pos + Vector3(0, 0.12 * s, 0), Vector3(0.36, 0.17, 0.2) * s, seed_, 0.16, 1.6, 8, 14,
			Basis(Vector3.UP, 0.4), false, 0.55)
		b.blob(mat, pos + Vector3(-0.31 * s, 0.1 * s, 0.1 * s), Vector3(0.1, 0.07, 0.07) * s, seed_ + 3, 0.2, 2.0, 5, 8)
		return
	b.blob(mat, pos + Vector3(0, 0.27 * s, 0), Vector3(0.21, 0.28, 0.17) * s, seed_, 0.14, 1.8, 9, 14, Basis(), false, 0.92)
	# gathered, tied neck and a floppy top
	b.blob(mat, pos + Vector3(0.0, 0.6 * s, 0.0), Vector3(0.09, 0.08, 0.08) * s, seed_ + 1, 0.25, 2.5, 5, 10)
	b.cyl(Kit.rope(), pos + Vector3(0, 0.545 * s, 0), pos + Vector3(0, 0.575 * s, 0), 0.062 * s, 0.062 * s, 10, 0.05, false)
	b.blob(mat, pos + Vector3(0.05 * s, 0.67 * s, 0.01 * s), Vector3(0.1, 0.045, 0.06) * s, seed_ + 2, 0.3, 2.5, 4, 8, Basis(Vector3.BACK, -0.5))
