extends RefCounted
## Furniture, bedding, tent, meat rack, utensils and a personal sleeping area.

const Kit := preload("res://assets/hideout/Materials/kit.gd")
const StorageExtra := preload("res://assets/hideout/Storage_Containers/storage_extra.gd")


## Rough chair in three designs: 0 ladder-back, 1 log-and-slab, 2 stump with a board back and a wool cushion.
## Origin at the floor under the seat, facing +Z.
static func chair(variant := 0, seed_ := 71) -> Node3D:
	var b := Kit.MB.new(seed_)
	var wd := Kit.wood("aged")
	match variant:
		0:
			for sx in [-1, 1]:
				for sz in [-1, 1]:
					var top := 0.46 if sz > 0 else 0.98
					b.box(Kit.wood("dark"), Vector3(sx * 0.19, top * 0.5, sz * 0.19), Vector3(0.045, top, 0.045), Basis(Vector3.BACK, sx * b.rng.randf_range(-0.02, 0.0)), 0.003)
			b.box(wd, Vector3(0, 0.46, 0), Vector3(0.46, 0.04, 0.44), Basis(Vector3.UP, b.rng.randf_range(-0.03, 0.03)), 0.004)
			for y in [0.62, 0.76, 0.9]:
				b.box(wd, Vector3(0, y, -0.19), Vector3(0.4, 0.07, 0.025), Basis(Vector3.BACK, b.rng.randf_range(-0.03, 0.03)), 0.003)
			b.box(Kit.wood("dark"), Vector3(0, 0.25, 0.0), Vector3(0.38, 0.03, 0.03))
		1:
			b.box(Kit.wood("grey"), Vector3(0, 0.5, 0), Vector3(0.58, 0.08, 0.5), Basis(Vector3.UP, 0.04), 0.01)
			for sx in [-1, 1]:
				for sz in [-1, 1]:
					b.cyl(Kit.wood("grey"), Vector3(sx * 0.22, 0, sz * 0.18), Vector3(sx * 0.2, 0.47, sz * 0.17), 0.05, 0.045, 7, 0.08, true, 2)
			b.box(Kit.wood("aged"), Vector3(0, 0.88, -0.24), Vector3(0.56, 0.7, 0.06), Basis(Vector3.RIGHT, -0.12), 0.01)
			for sx in [-1, 1]:
				b.cyl(Kit.wood("dark"), Vector3(sx * 0.31, 0.62, -0.18), Vector3(sx * 0.31, 0.62, 0.22), 0.035, 0.03, 6, 0.08, true, 2)
				b.cyl(Kit.wood("dark"), Vector3(sx * 0.31, 0.5, 0.2), Vector3(sx * 0.31, 0.62, 0.2), 0.03, 0.03, 6)
		_:
			b.cyl(Kit.wood("grey"), Vector3.ZERO, Vector3(0, 0.44, 0), 0.26, 0.24, 10, 0.05, true, 3)
			b.box(Kit.wood("aged"), Vector3(0, 0.8, -0.23), Vector3(0.5, 0.7, 0.04), Basis(Vector3.RIGHT, -0.1), 0.006)
			b.box(Kit.iron(), Vector3(0, 0.56, -0.245), Vector3(0.4, 0.04, 0.015))
			b.blob(Kit.cloth("wool"), Vector3(0, 0.47, 0.0), Vector3(0.26, 0.05, 0.24), 4, 0.15, 2.0, 5, 10, Basis(), false, 0.3)
	return Kit.asset("Chair_%d" % variant, b, "convex")


## kind: "trestle" (planks on A-frame legs, 1.8 m) or "slab" (thick slab on log legs, 1.3 m).
static func table(kind := "trestle", seed_ := 72) -> Node3D:
	var b := Kit.MB.new(seed_)
	var w := 1.8 if kind == "trestle" else 1.3
	var d := 0.85 if kind == "trestle" else 0.75
	var h := 0.78
	if kind == "trestle":
		var n := 4
		for i in n:
			var z := -d * 0.5 + d * (float(i) + 0.5) / n
			b.box(Kit.wood("aged") if b.rng.randf() > 0.3 else Kit.wood("grey"), Vector3(b.rng.randf_range(-0.01, 0.01), h - 0.02, z), Vector3(w, 0.04, d / n - 0.01),
				Basis(Vector3.UP, b.rng.randf_range(-0.01, 0.01)), 0.003)
		for sx in [-1, 1]:
			for sz in [-1, 1]:
				b.box(Kit.wood("dark"), Vector3(sx * (w * 0.5 - 0.25), h * 0.5 - 0.04, sz * 0.2), Vector3(0.07, h - 0.05, 0.07),
					Basis(Vector3.BACK, 0.0).rotated(Vector3.RIGHT, -sz * 0.18), 0.003)
			b.box(Kit.wood("dark"), Vector3(sx * (w * 0.5 - 0.25), h - 0.07, 0), Vector3(0.09, 0.07, d - 0.1))
		b.box(Kit.wood("dark"), Vector3(0, 0.3, 0), Vector3(w - 0.5, 0.05, 0.07), Basis(Vector3.BACK, 0.01), 0.003)
	else:
		b.box(Kit.wood("grey"), Vector3(0, h - 0.045, 0), Vector3(w, 0.09, d), Basis(Vector3.UP, 0.03), 0.012)
		for sx in [-1, 1]:
			for sz in [-1, 1]:
				b.cyl(Kit.wood("grey"), Vector3(sx * (w * 0.5 - 0.12), 0, sz * (d * 0.5 - 0.12)), Vector3(sx * (w * 0.5 - 0.14), h - 0.08, sz * (d * 0.5 - 0.13)), 0.065, 0.06, 7, 0.08, true, 3)
	return Kit.asset("Table_" + kind.capitalize(), b, "convex")


## Tableware: mugs, plates, a ladle, a knife and a heel of bread on a rag. Origin at the base, sits on a table.
static func utensils(seed_ := 73) -> Node3D:
	var b := Kit.MB.new(seed_)
	b.blob(Kit.cloth("grain"), Vector3(0, 0.005, 0), Vector3(0.34, 0.012, 0.24), 2, 0.1, 2.0, 3, 10)
	for p in [Vector3(-0.1, 0.012, -0.02), Vector3(0.12, 0.012, 0.06)]:
		b.lathe(Kit.iron(), PackedVector2Array([Vector2(0.0, p.y), Vector2(0.07, p.y), Vector2(0.105, p.y + 0.018), Vector2(0.1, p.y + 0.02), Vector2(0.065, p.y + 0.008), Vector2(0.0, p.y + 0.008)]).duplicate(), 14)
	for m in [Vector3(0.0, 0.012, 0.14), Vector3(0.22, 0.012, -0.08)]:
		b.push(Transform3D(Basis(), m))
		b.lathe(Kit.wood("dark"), PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.034, 0.0), Vector2(0.04, 0.09), Vector2(0.036, 0.09), Vector2(0.03, 0.01), Vector2(0.0, 0.01)]), 10)
		b.pop()
	b.cyl(Kit.wood("aged"), Vector3(-0.28, 0.02, 0.1), Vector3(-0.05, 0.02, 0.18), 0.008, 0.007, 5)
	b.blob(Kit.iron(), Vector3(-0.3, 0.025, 0.09), Vector3(0.035, 0.015, 0.03), 5, 0.1, 2.0, 3, 8)
	b.box(Kit.iron(), Vector3(0.05, 0.016, -0.14), Vector3(0.14, 0.006, 0.02), Basis(Vector3.UP, 0.3))
	b.box(Kit.wood("dark"), Vector3(0.14, 0.018, -0.17), Vector3(0.07, 0.016, 0.02), Basis(Vector3.UP, 0.3))
	b.blob(Kit.plain(Color(0.42, 0.28, 0.13), 0.85), Vector3(-0.1, 0.045, -0.02), Vector3(0.07, 0.03, 0.05), 3, 0.12, 2.0, 4, 8)
	return Kit.asset("Utensils", b, "none")


## kind: "rolled", "open" (pad, pillow, draped blanket), "straw" (heaped bedding), "blanket" (crumpled on the ground).
static func bedding(kind := "open", seed_ := 74) -> Node3D:
	var b := Kit.MB.new(seed_)
	match kind:
		"rolled":
			b.cyl(Kit.cloth("grain"), Vector3(-0.35, 0.13, 0), Vector3(0.35, 0.13, 0), 0.13, 0.13, 12, 0.04, true, 3)
			b.cyl(Kit.cloth("wool"), Vector3(-0.35, 0.13, 0), Vector3(-0.28, 0.13, 0), 0.134, 0.134, 12, 0.02, true, 1)
			for x in [-0.2, 0.2]:
				b.cyl(Kit.rope(), Vector3(x, 0.13, 0), Vector3(x + 0.03, 0.13, 0), 0.138, 0.138, 12, 0.03, false)
		"straw":
			for i in 14:
				var x := b.rng.randf_range(-0.45, 0.45)
				var z := b.rng.randf_range(-0.9, 0.9)
				b.blob(Kit.cloth("straw"), Vector3(x, 0.05, z), Vector3(0.3, 0.08, 0.35) * b.rng.randf_range(0.7, 1.2), i, 0.35, 2.0, 4, 8, Basis(Vector3.UP, b.rng.randf() * TAU), false, 0.2)
			for i in 40:
				var x := b.rng.randf_range(-0.55, 0.55)
				var z := b.rng.randf_range(-1.0, 1.0)
				var a := b.rng.randf() * TAU
				b.cyl(Kit.cloth("straw"), Vector3(x, 0.07, z), Vector3(x + cos(a) * 0.25, 0.1 + b.rng.randf() * 0.04, z + sin(a) * 0.25), 0.004, 0.003, 3, 0.0, false)
		"blanket":
			_drape(b, Vector3(0, 0.0, 0), 0.9, 1.1, 0.12, 4)
		_:
			b.blob(Kit.cloth("grain"), Vector3(0, 0.04, 0), Vector3(0.45, 0.04, 0.95), 3, 0.08, 2.0, 4, 14, Basis(), false, 0.3)
			b.blob(Kit.cloth("burlap"), Vector3(0, 0.1, -0.7), Vector3(0.24, 0.07, 0.15), 5, 0.15, 2.0, 5, 10)
			_drape(b, Vector3(0, 0.07, 0.25), 0.8, 1.15, 0.07, 6)
	return Kit.asset("Bedding_" + kind.capitalize(), b, "none")


static func _drape(b: Kit.MB, at: Vector3, w: float, l: float, amp: float, seed_: int) -> void:
	var n := FastNoiseLite.new()
	n.seed = seed_
	n.frequency = 1.6
	var res := 14
	var pts := PackedVector3Array()
	for j in res + 1:
		for i in res + 1:
			var u := float(i) / res
			var v := float(j) / res
			var x := (u - 0.5) * w
			var z := (v - 0.5) * l
			var edge := smoothstep(0.0, 0.25, minf(minf(u, 1.0 - u), minf(v, 1.0 - v)))
			pts.append(at + Vector3(x, 0.012 + amp * (0.35 + n.get_noise_2d(x * 2.0, z * 2.0) * 0.65) * (0.25 + 0.75 * edge), z))
	b.grid(Kit.cloth("wool"), pts, res + 1, res + 1, Vector3.UP, 1.0)


## Small A-frame tent: ridge pole on forks, sagging canvas, pegs and guy ropes. Origin at the center of the floor, opening faces +Z.
static func tent(seed_ := 75) -> Node3D:
	var b := Kit.MB.new(seed_)
	var L := 2.4
	var hw := 1.0
	var H := 1.35
	b.cyl(Kit.wood("grey"), Vector3(0, H, -L * 0.5 - 0.3), Vector3(0, H + 0.02, L * 0.5 + 0.3), 0.04, 0.036, 7, 0.06, true, 5)
	for sz in [-1, 1]:
		b.cyl(Kit.wood("grey"), Vector3(0, 0, sz * (L * 0.5 + 0.28)), Vector3(0, H + 0.04, sz * (L * 0.5 + 0.28)), 0.045, 0.04, 6, 0.06, true, 3)
	var res := 10
	for side in [-1, 1]:
		var pts := PackedVector3Array()
		for j in res + 1:
			for i in res + 1:
				var u := float(i) / res
				var v := float(j) / res
				var sag := -0.07 * sin(PI * u) * sin(PI * v * 0.9)
				pts.append(Vector3(side * hw * v, H * (1.0 - v) + 0.02 + sag, (u - 0.5) * L))
		b.grid(Kit.cloth("grain"), pts, res + 1, res + 1, Vector3(side, 0.7, 0))
	# closed back panel
	b.tri(Kit.cloth("grain"), Vector3(-hw, 0.02, -L * 0.5), Vector3(hw, 0.02, -L * 0.5), Vector3(0, H, -L * 0.5), Vector3(0, 0, -1))
	for side in [-1, 1]:
		for z in [-L * 0.5, 0.0, L * 0.5]:
			var peg := Vector3(side * (hw + 0.55), 0.0, z)
			b.cyl(Kit.wood("dark"), peg, peg + Vector3(side * -0.04, 0.2, 0), 0.02, 0.016, 5)
			b.cyl(Kit.rope(), Vector3(side * hw, 0.08, z), peg + Vector3(side * -0.04, 0.16, 0), 0.01, 0.01, 4, 0.1, false, 2)
	return Kit.asset("Tent_Small", b, "convex")


## Forked posts with a pole, hung with cured meat on hooks. Origin at the bottom center.
static func meat_rack(seed_ := 76) -> Node3D:
	var b := Kit.MB.new(seed_)
	var w := 1.6
	for sx in [-1, 1]:
		b.cyl(Kit.wood("grey"), Vector3(sx * w * 0.5, 0, 0), Vector3(sx * w * 0.5, 1.7, 0), 0.05, 0.045, 7, 0.07, true, 4)
		b.cyl(Kit.wood("grey"), Vector3(sx * w * 0.5, 1.5, 0), Vector3(sx * w * 0.5 - 0.1 * sx, 1.78, 0.05), 0.03, 0.025, 6)
	b.cyl(Kit.wood("dark"), Vector3(-w * 0.5 - 0.15, 1.62, 0), Vector3(w * 0.5 + 0.15, 1.62, 0), 0.035, 0.03, 6, 0.06, true, 5)
	for i in 4:
		var x := -0.55 + 0.37 * i + b.rng.randf_range(-0.04, 0.04)
		var drop := 0.28 + b.rng.randf() * 0.15
		b.cyl(Kit.rope(), Vector3(x, 1.62, 0), Vector3(x, 1.62 - drop, 0), 0.01, 0.01, 4, 0.1, false)
		if i == 2:
			# a plucked bird
			b.blob(Kit.plain(Color(0.6, 0.45, 0.35), 0.8), Vector3(x, 1.62 - drop - 0.16, 0), Vector3(0.08, 0.13, 0.07), 7, 0.15, 2.0, 6, 9)
			continue
		b.blob(Kit.plain(Color(0.38, 0.12, 0.09), 0.65), Vector3(x, 1.62 - drop - 0.17, 0), Vector3(0.075, 0.18, 0.065), i, 0.2, 2.0, 6, 9)
		b.blob(Kit.plain(Color(0.78, 0.7, 0.55), 0.7), Vector3(x + 0.02, 1.62 - drop - 0.06, 0.03), Vector3(0.04, 0.05, 0.03), i + 4, 0.2, 2.0, 4, 6)
	return Kit.asset("MeatRack", b, "convex")


## Sagging rope with iron hooks at both ends. Origin at the left hook; runs along +X.
static func hanging_rope(length := 2.0, seed_ := 77) -> Node3D:
	var b := Kit.MB.new(seed_)
	var sag := 0.28
	var segs := 10
	for i in segs:
		var t0 := float(i) / segs
		var t1 := float(i + 1) / segs
		b.cyl(Kit.rope(), Vector3(length * t0, -sag * 4.0 * t0 * (1.0 - t0), 0), Vector3(length * t1, -sag * 4.0 * t1 * (1.0 - t1), 0), 0.014, 0.014, 5, 0.1, false)
	for x in [0.0, length]:
		b.cyl(Kit.iron(), Vector3(x, 0.0, 0.0), Vector3(x, 0.0, 0.07), 0.012, 0.012, 5)
		b.box(Kit.iron(), Vector3(x, 0.0, 0.0), Vector3(0.03, 0.05, 0.015))
	# a rag hung over it
	b.box(Kit.cloth("grain"), Vector3(length * 0.5, -sag + 0.1, 0.0), Vector3(0.28, 0.22, 0.01), Basis(Vector3.BACK, 0.05))
	return Kit.asset("HangingRope_%.0fm" % length, b, "none")


## Personal sleeping corner: bedroll, chest, stool, lamp-free. Built from the other assets as separate nodes.
static func personal_area(seed_ := 78) -> Node3D:
	var root := Node3D.new()
	root.name = "PersonalArea"
	var bed := bedding("open", seed_)
	root.add_child(bed)
	var ch := StorageExtra.chest("closed", seed_)
	ch.position = Vector3(0.0, 0, -1.35)
	root.add_child(ch)
	var st := stool(1, seed_)
	st.position = Vector3(0.85, 0, -0.4)
	root.add_child(st)
	var cl := bedding("rolled", seed_ + 1)
	cl.position = Vector3(-0.95, 0, 0.2)
	cl.rotation_degrees.y = 80
	root.add_child(cl)
	return root


static func stool(variant := 0, seed_ := 21) -> Node3D:
	return (load("res://assets/hideout/Camp_Equipment/camp.gd") as GDScript).stool(variant, seed_)
