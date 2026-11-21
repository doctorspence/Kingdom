extends RefCounted
## Buckets, baskets, chests and mining supply boxes.

const Kit := preload("res://assets/hideout/Materials/kit.gd")


## Staved wooden bucket with iron bands and a bail handle. kind: "water" or "empty".
static func bucket(kind := "water", seed_ := 61) -> Node3D:
	var b := Kit.MB.new(seed_)
	var h := 0.32
	var rb := 0.19
	var rt := 0.22
	var sides := 14
	for i in sides:
		var a0 := TAU * float(i) / sides
		var a1 := TAU * (float(i) + 0.95) / sides
		var m: Material = Kit.wood("grey") if b.rng.randf() < 0.3 else Kit.wood("aged")
		var uvo := Vector2(b.rng.randf() * 3.0, b.rng.randf() * 3.0)
		var tl := 1.0 - b.rng.randf() * 0.03
		var am := (a0 + a1) * 0.5
		var rad := Vector3(cos(am), 0, sin(am))
		for s in 2:
			var inset := 0.0 if s == 0 else 0.018
			var p00 := Vector3(cos(a0) * (rb - inset), 0, sin(a0) * (rb - inset))
			var p01 := Vector3(cos(a1) * (rb - inset), 0, sin(a1) * (rb - inset))
			var p11 := Vector3(cos(a1) * (rt - inset), h * tl, sin(a1) * (rt - inset))
			var p10 := Vector3(cos(a0) * (rt - inset), h * tl, sin(a0) * (rt - inset))
			b.quad(m, p00, p01, p11, p10, rad if s == 0 else -rad, uvo)
		b.quad(m, Vector3(cos(a0) * rt, h * tl, sin(a0) * rt), Vector3(cos(a1) * rt, h * tl, sin(a1) * rt),
			Vector3(cos(a1) * (rt - 0.018), h * tl, sin(a1) * (rt - 0.018)), Vector3(cos(a0) * (rt - 0.018), h * tl, sin(a0) * (rt - 0.018)), Vector3.UP, uvo)
	b.disc(Kit.wood("dark"), 0.03, rb - 0.018, sides, true)
	if kind == "water":
		b.disc(Kit.water(), h * 0.78, lerpf(rb, rt, 0.78) - 0.018, sides, true)
	for t in [0.18, 0.8]:
		var r := lerpf(rb, rt, t) + 0.004
		b.lathe(Kit.iron(), PackedVector2Array([Vector2(r, h * t - 0.016), Vector2(r + 0.01, h * t - 0.016), Vector2(r + 0.01, h * t + 0.016), Vector2(r, h * t + 0.016)]), sides + 4)
	# bail handle, hanging to one side
	var pts: Array[Vector3] = []
	for i in 9:
		var a := PI * float(i) / 8.0
		pts.append(Vector3(cos(a) * rt, h * 0.95 + sin(a) * 0.17, 0.0))
	b.push(Transform3D(Basis(Vector3.UP, 0.4), Vector3.ZERO))
	for i in pts.size() - 1:
		b.cyl(Kit.iron(), pts[i], pts[i + 1], 0.008, 0.008, 5, 0.0, false)
	b.pop()
	return Kit.asset("Bucket_" + kind.capitalize(), b, "convex")


## Woven supply basket. kind: "turnips", "bread", "empty".
static func basket(kind := "turnips", seed_ := 62) -> Node3D:
	var b := Kit.MB.new(seed_)
	var straw := Kit.cloth("straw")
	var prof := PackedVector2Array()
	var rows := 14
	for i in rows + 1:
		var t := float(i) / rows
		var r := lerpf(0.17, 0.27, t) + (0.008 if i % 2 == 0 else -0.004)
		prof.append(Vector2(r, 0.02 + 0.3 * t))
	b.lathe(straw, prof, 16, false)
	var inner := PackedVector2Array()
	for i in rows + 1:
		var t := float(rows - i) / rows
		inner.append(Vector2(lerpf(0.15, 0.25, t), 0.02 + 0.3 * t + 0.0))
	b.lathe(Kit.cloth("grain"), PackedVector2Array([Vector2(0.255, 0.32), Vector2(0.28, 0.325), Vector2(0.28, 0.34), Vector2(0.25, 0.335)]), 16, false)
	b.disc(straw, 0.02, 0.17, 14, false)
	match kind:
		"turnips":
			for i in 6:
				var a := b.rng.randf() * TAU
				var r := b.rng.randf() * 0.13
				b.blob(Kit.plain(Color(0.62, 0.5, 0.5), 0.8), Vector3(cos(a) * r, 0.3 + b.rng.randf() * 0.04, sin(a) * r), Vector3(0.07, 0.065, 0.07), i, 0.15, 2.0, 5, 8)
				b.blob(Kit.plain(Color(0.2, 0.28, 0.12), 0.9), Vector3(cos(a) * r, 0.37, sin(a) * r), Vector3(0.03, 0.04, 0.03), i + 9, 0.3, 2.0, 3, 6)
		"bread":
			for i in 4:
				var a := b.rng.randf() * TAU
				var r := b.rng.randf() * 0.12
				b.blob(Kit.plain(Color(0.45, 0.3, 0.14), 0.8), Vector3(cos(a) * r, 0.31, sin(a) * r), Vector3(0.11, 0.045, 0.06), i, 0.12, 2.0, 5, 8, Basis(Vector3.UP, a))
	# arched handle
	for i in 8:
		var a0 := PI * float(i) / 8.0
		var a1 := PI * float(i + 1) / 8.0
		b.cyl(straw, Vector3(cos(a0) * 0.26, 0.33 + sin(a0) * 0.22, 0), Vector3(cos(a1) * 0.26, 0.33 + sin(a1) * 0.22, 0), 0.016, 0.016, 5, 0.1, false)
	return Kit.asset("Basket_" + kind.capitalize(), b, "convex")


## Iron-bound wooden chest with a domed lid. kind: "closed", "open" (lid back), "broken" (lid ajar, splintered).
static func chest(kind := "closed", seed_ := 63) -> Node3D:
	var b := Kit.MB.new(seed_)
	var w := 0.9
	var d := 0.5
	var h := 0.42
	var iron := Kit.iron()
	var wood := Kit.wood("dark")
	# body: planked sides
	var rows := 3
	for i in rows:
		var y := 0.02 + (h - 0.02) * (float(i) + 0.5) / rows
		var sh := (h - 0.02) / rows - 0.01
		for sz in [-1, 1]:
			b.box(wood if b.rng.randf() > 0.3 else Kit.wood("grey"), Vector3(0, y, sz * (d * 0.5 - 0.0125)), Vector3(w, sh, 0.025), Basis(), 0.002)
		for sx in [-1, 1]:
			b.box(wood, Vector3(sx * (w * 0.5 - 0.0125), y, 0), Vector3(0.025, sh, d - 0.05), Basis(), 0.002)
	b.box(Kit.wood("aged"), Vector3(0, 0.03, 0), Vector3(w - 0.05, 0.03, d - 0.05))
	for sx in [-1, 1]:
		b.box(Kit.wood("dark"), Vector3(sx * (w * 0.5 - 0.035), 0.01, 0), Vector3(0.08, 0.04, d + 0.04))
	# iron straps and corner plates
	for x in [-0.28, 0.28]:
		b.box(iron, Vector3(x, h * 0.5 + 0.01, d * 0.5 + 0.004), Vector3(0.06, h, 0.01))
		b.box(iron, Vector3(x, h * 0.5 + 0.01, -d * 0.5 - 0.004), Vector3(0.06, h, 0.01))
	# domed lid hinged at the back edge
	var hinge := Vector3(0, h, -d * 0.5)
	var ang := 0.0
	if kind == "open":
		ang = -1.9
	elif kind == "broken":
		ang = -0.5
	b.push(Transform3D(Basis(Vector3.RIGHT, ang), hinge))
	var arc := 8
	var r_dome := 0.13
	for i in arc:
		var a0 := PI * float(i) / arc
		var a1 := PI * float(i + 1) / arc
		var y0 := sin(a0) * r_dome
		var y1 := sin(a1) * r_dome
		var zz0 := d * 0.5 - cos(a0) * d * 0.5
		var zz1 := d * 0.5 - cos(a1) * d * 0.5
		var nrm := Vector3(0, zz1 - zz0, -(y1 - y0))
		b.quad(wood, Vector3(-w * 0.5 - 0.02, y0, zz0), Vector3(w * 0.5 + 0.02, y0, zz0), Vector3(w * 0.5 + 0.02, y1, zz1), Vector3(-w * 0.5 - 0.02, y1, zz1), nrm)
		# lid straps
		for x in [-0.28, 0.28]:
			b.quad(iron, Vector3(x - 0.03, y0 + 0.006, zz0), Vector3(x + 0.03, y0 + 0.006, zz0), Vector3(x + 0.03, y1 + 0.006, zz1), Vector3(x - 0.03, y1 + 0.006, zz1), nrm)
	b.box(iron, Vector3(0, 0.0, d - 0.01), Vector3(0.09, 0.1, 0.02))     # lock plate
	b.pop()
	if kind == "open":
		b.blob(Kit.cloth("wool"), Vector3(0.0, h - 0.02, 0.0), Vector3(0.32, 0.08, 0.18), 3, 0.25, 2.0, 5, 10, Basis(), false, 0.3)
	# side handles
	for sx in [-1, 1]:
		b.cyl(iron, Vector3(sx * (w * 0.5 + 0.02), h * 0.65, -0.06), Vector3(sx * (w * 0.5 + 0.02), h * 0.65, 0.06), 0.008, 0.008, 5, 0.0, false)
	return Kit.asset("Chest_" + kind.capitalize(), b, "convex")


## Heavy mining supply box: braced planks, iron corners, rope handles. kind: "tools" (handles poking out) or "powder_free" (empty rope-lashed).
static func mining_box(kind := "tools", seed_ := 64) -> Node3D:
	var b := Kit.MB.new(seed_)
	var w := 0.95
	var d := 0.5
	var h := 0.45
	for i in 3:
		var y := 0.06 + (h - 0.06) * (float(i) + 0.5) / 3.0
		for sz in [-1, 1]:
			b.box(Kit.wood("grey") if i == 1 else Kit.wood("aged"), Vector3(0, y, sz * (d * 0.5 - 0.015)), Vector3(w, (h - 0.06) / 3.0 - 0.01, 0.03), Basis(), 0.002)
		for sx in [-1, 1]:
			b.box(Kit.wood("aged"), Vector3(sx * (w * 0.5 - 0.015), y, 0), Vector3(0.03, (h - 0.06) / 3.0 - 0.01, d - 0.06), Basis(), 0.002)
	b.box(Kit.wood("dark"), Vector3(0, 0.04, 0), Vector3(w - 0.04, 0.04, d - 0.04))
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			b.box(Kit.iron(), Vector3(sx * (w * 0.5 - 0.04), h * 0.5, sz * (d * 0.5 + 0.004)), Vector3(0.07, h, 0.012))
			b.box(Kit.iron(), Vector3(sx * (w * 0.5 + 0.004), h * 0.5, sz * (d * 0.5 - 0.04)), Vector3(0.012, h, 0.07))
	for sx in [-1, 1]:
		b.cyl(Kit.rope(), Vector3(sx * (w * 0.5 + 0.02), h * 0.8, -0.08), Vector3(sx * (w * 0.5 + 0.06), h * 0.8, 0.0), 0.014, 0.014, 5, 0.1, false)
		b.cyl(Kit.rope(), Vector3(sx * (w * 0.5 + 0.06), h * 0.8, 0.0), Vector3(sx * (w * 0.5 + 0.02), h * 0.8, 0.08), 0.014, 0.014, 5, 0.1, false)
	if kind == "tools":
		for i in 3:
			var x := -0.3 + 0.3 * i
			b.cyl(Kit.wood("aged"), Vector3(x, h * 0.6, 0.0), Vector3(x + b.rng.randf_range(-0.05, 0.05), h + 0.55 + b.rng.randf() * 0.2, b.rng.randf_range(-0.08, 0.08)), 0.02, 0.018, 6, 0.04, true, 2)
		b.box(Kit.iron(), Vector3(0.28, h + 0.5, 0.02), Vector3(0.2, 0.05, 0.04), Basis(Vector3.BACK, 0.3))
	return Kit.asset("MiningBox_" + kind.capitalize(), b, "convex")
