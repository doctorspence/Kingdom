extends RefCounted
## More crude timber pieces: doors/gates, scaffold, bridge, barricade, hanging platform, shelves.

const Kit := preload("res://assets/hideout/Materials/kit.gd")


## Plank door in a rough timber frame. kind: "door" (1 m), "gate" (double leaf, 2.4 m), "broken".
## Origin at the bottom center of the opening; the door sits at z = 0.
static func door(kind := "door", seed_ := 51) -> Node3D:
	var b := Kit.MB.new(seed_)
	var w := 2.4 if kind == "gate" else 1.0
	var h := 2.4 if kind == "gate" else 2.0
	var iron := Kit.iron()
	for sx in [-1, 1]:
		b.box(Kit.wood("dark"), Vector3(sx * (w * 0.5 + 0.08), h * 0.5 + 0.1, 0), Vector3(0.16, h + 0.2, 0.2), Basis(), 0.005)
	b.box(Kit.wood("dark"), Vector3(0, h + 0.14, 0), Vector3(w + 0.5, 0.2, 0.22), Basis(Vector3.BACK, b.rng.randf_range(-0.01, 0.01)), 0.005)
	var leaves := 2 if kind == "gate" else 1
	var lw := w / leaves
	for l in leaves:
		var cx := -w * 0.5 + lw * (float(l) + 0.5)
		var n := roundi(lw / 0.17)
		var pw := lw / n
		for i in n:
			var x := cx - lw * 0.5 + pw * (float(i) + 0.5)
			var ph := h - 0.06 - b.rng.randf() * 0.04
			if kind == "broken" and i in [1, 2]:
				ph = h * b.rng.randf_range(0.45, 0.7)
			b.box(Kit.wood("grey") if b.rng.randf() < 0.3 else Kit.wood("aged"), Vector3(x, 0.03 + ph * 0.5, 0), Vector3(pw - 0.012, ph, 0.05), Basis(), 0.003)
		for by in [h * 0.22, h * 0.78]:
			b.box(Kit.wood("dark"), Vector3(cx, by, 0.05), Vector3(lw - 0.04, 0.13, 0.035), Basis(), 0.003)
		var ang := atan2(h * 0.56, lw - 0.1)
		b.box(Kit.wood("dark"), Vector3(cx, h * 0.5, 0.085), Vector3(sqrt(pow(lw - 0.1, 2.0) + pow(h * 0.56, 2.0)), 0.1, 0.03), Basis(Vector3.BACK, ang), 0.002)
		var side := -1.0 if l == 0 else 1.0
		for by in [h * 0.22, h * 0.78]:
			b.box(iron, Vector3(cx + side * (lw * 0.5 - 0.17), by, 0.075), Vector3(0.3, 0.05, 0.015))
	if kind == "gate":
		b.box(Kit.wood("dark"), Vector3(0, h * 0.5, 0.115), Vector3(w + 0.2, 0.11, 0.05), Basis(), 0.003)
	else:
		b.cyl(iron, Vector3(w * 0.5 - 0.15, h * 0.48, 0.08), Vector3(w * 0.5 - 0.15, h * 0.48, 0.1), 0.05, 0.05, 10)
	return Kit.asset("Door_" + kind.capitalize(), b, "convex")


## Lashed log scaffold with a plank deck. Origin at the center of the ground footprint.
static func scaffold(w := 2.0, d := 1.6, h := 3.2, deck_y := 1.6, seed_ := 52) -> Node3D:
	var b := Kit.MB.new(seed_)
	var px := w * 0.5
	var pz := d * 0.5
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			b.cyl(Kit.wood("grey"), Vector3(sx * px, 0, sz * pz), Vector3(sx * px + b.rng.randf_range(-0.03, 0.03), h, sz * pz), 0.07, 0.06, 7, 0.06, true, 4)
	for y in [0.7, deck_y, h - 0.2]:
		for sz in [-1, 1]:
			b.cyl(Kit.wood("dark"), Vector3(-px - 0.15, y, sz * pz + 0.07), Vector3(px + 0.15, y + b.rng.randf_range(-0.03, 0.03), sz * pz + 0.07), 0.045, 0.04, 6, 0.08, true, 3)
		for sx in [-1, 1]:
			b.cyl(Kit.wood("dark"), Vector3(sx * px + 0.07, y, -pz - 0.15), Vector3(sx * px + 0.07, y, pz + 0.15), 0.045, 0.04, 6, 0.08, true, 3)
		for sx in [-1, 1]:
			for sz in [-1, 1]:
				b.cyl(Kit.rope(), Vector3(sx * px, y - 0.03, sz * pz), Vector3(sx * px, y + 0.03, sz * pz), 0.085, 0.085, 8, 0.06, false)
	for sz in [-1, 1]:
		b.cyl(Kit.wood("grey"), Vector3(-px, 0.7, sz * pz + 0.1), Vector3(px, h - 0.2, sz * pz + 0.1), 0.035, 0.035, 6, 0.1)
	var n := roundi((d + 0.3) / 0.2)
	for i in n:
		var z := -d * 0.5 - 0.15 + (d + 0.3) * (float(i) + 0.5) / n
		if i == 2:
			continue
		b.box(Kit.wood("aged") if b.rng.randf() > 0.25 else Kit.wood("grey"), Vector3(0, deck_y + 0.06, z), Vector3(w + 0.3, 0.04, (d + 0.3) / n - 0.012),
			Basis(Vector3.UP, b.rng.randf_range(-0.01, 0.01)), 0.003)
	return Kit.asset("Scaffold", b, "trimesh")


## Small plank bridge with log stringers and rope rails. Runs along +X; origin at the start center on the deck.
static func bridge(length := 3.0, width := 1.2, seed_ := 53) -> Node3D:
	var b := Kit.MB.new(seed_)
	for sz in [-1, 1]:
		b.cyl(Kit.wood("grey"), Vector3(-0.15, -0.2, sz * (width * 0.5 - 0.1)), Vector3(length + 0.15, -0.2, sz * (width * 0.5 - 0.1)), 0.11, 0.1, 8, 0.05, true, 5)
	var n := int(length / 0.2)
	for i in n:
		var x := length * (float(i) + 0.5) / n
		if i == 6:
			continue
		var m: Material = Kit.wood("fresh") if b.rng.randf() < 0.1 else (Kit.wood("grey") if b.rng.randf() < 0.3 else Kit.wood("aged"))
		b.box(m, Vector3(x, -0.03, b.rng.randf_range(-0.02, 0.02)), Vector3(length / n - 0.015, 0.05, width + b.rng.randf_range(-0.05, 0.08)),
			Basis(Vector3.UP, b.rng.randf_range(-0.01, 0.01)), 0.003)
	for sz in [-1, 1]:
		var zz: float = sz * (width * 0.5 + 0.02)
		for i in 3:
			var x := length * float(i) / 2.0
			b.cyl(Kit.wood("dark"), Vector3(x, -0.1, zz), Vector3(x, 0.95, zz), 0.045, 0.04, 6, 0.06)
		var sag := b.rng.randf_range(0.04, 0.09)
		b.cyl(Kit.rope(), Vector3(0, 0.9, zz), Vector3(length * 0.5, 0.9 - sag, zz), 0.022, 0.022, 6, 0.1, false, 3)
		b.cyl(Kit.rope(), Vector3(length * 0.5, 0.9 - sag, zz), Vector3(length, 0.9, zz), 0.022, 0.022, 6, 0.1, false, 3)
	return Kit.asset("Bridge_%dm" % roundi(length), b, "trimesh")


## Barricade: sharpened stakes, a lashed crossbar and nailed boards. Origin at ground, center.
static func barricade(w := 2.4, seed_ := 54) -> Node3D:
	var b := Kit.MB.new(seed_)
	var n := 3
	for i in n:
		var x := -w * 0.5 + w * float(i) / (n - 1)
		for sgn in [-1, 1]:
			b.cyl(Kit.wood("grey"), Vector3(x, 0, sgn * 0.45 + b.rng.randf_range(-0.04, 0.04)), Vector3(x + b.rng.randf_range(-0.08, 0.08), 1.25, -sgn * 0.05),
				0.07, 0.012, 7, 0.08, true, 4)
	b.cyl(Kit.wood("dark"), Vector3(-w * 0.5 - 0.15, 0.75, 0), Vector3(w * 0.5 + 0.15, 0.82, 0), 0.06, 0.055, 7, 0.07, true, 4)
	for i in 3:
		var y := 0.25 + 0.3 * i
		b.box(Kit.wood("aged") if i != 1 else Kit.wood("grey"), Vector3(b.rng.randf_range(-0.2, 0.2), y, 0.12 + 0.02 * i),
			Vector3(w * b.rng.randf_range(0.5, 0.85), 0.16, 0.035), Basis(Vector3.BACK, b.rng.randf_range(-0.08, 0.08)).rotated(Vector3.UP, b.rng.randf_range(-0.04, 0.04)), 0.004)
	return Kit.asset("Barricade", b, "convex")


## Platform slung from a beam on four ropes. Origin at the center of the deck top.
static func hanging_platform(w := 1.6, d := 1.4, hang := 2.0, seed_ := 55) -> Node3D:
	var b := Kit.MB.new(seed_)
	var n := roundi(w / 0.2)
	for i in n:
		var x := -w * 0.5 + w * (float(i) + 0.5) / n
		b.box(Kit.wood("aged") if b.rng.randf() > 0.3 else Kit.wood("grey"), Vector3(x, -0.025, 0), Vector3(w / n - 0.012, 0.05, d), Basis(Vector3.UP, b.rng.randf_range(-0.01, 0.01)), 0.003)
	for sz in [-1, 1]:
		b.box(Kit.wood("dark"), Vector3(0, -0.12, sz * (d * 0.5 - 0.15)), Vector3(w + 0.1, 0.1, 0.1), Basis(), 0.004)
	b.cyl(Kit.wood("grey"), Vector3(-w * 0.5 - 0.3, hang, 0), Vector3(w * 0.5 + 0.3, hang, 0), 0.09, 0.08, 8, 0.05, true, 4)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var top := Vector3(sx * (w * 0.5 - 0.1), hang, 0)
			var bot := Vector3(sx * (w * 0.5 - 0.1), -0.1, sz * (d * 0.5 - 0.15))
			b.cyl(Kit.rope(), bot, top, 0.022, 0.022, 6, 0.12, false, 4)
			b.cyl(Kit.rope(), bot + Vector3(0, 0.02, 0), bot + Vector3(0, 0.14, 0), 0.04, 0.04, 8, 0.06, false)
	return Kit.asset("HangingPlatform", b, "trimesh")


## Open shelving unit with jars, sacks and boxes. Origin at the bottom center of the unit.
static func shelf(w := 1.3, h := 1.9, tiers := 4, seed_ := 56) -> Node3D:
	var b := Kit.MB.new(seed_)
	var d := 0.4
	for sx in [-1, 1]:
		b.box(Kit.wood("dark"), Vector3(sx * (w * 0.5 - 0.04), h * 0.5, 0), Vector3(0.08, h, d), Basis(Vector3.BACK, b.rng.randf_range(-0.01, 0.01)), 0.004)
	for i in tiers:
		var y := 0.15 + (h - 0.25) * float(i) / (tiers - 1)
		b.box(Kit.wood("aged") if b.rng.randf() > 0.3 else Kit.wood("grey"), Vector3(0, y, 0), Vector3(w, 0.04, d + 0.02), Basis(Vector3.BACK, b.rng.randf_range(-0.012, 0.012)), 0.003)
		if i == 0:
			continue
		var k := b.rng.randi_range(1, 3)
		for j in k:
			var x := -w * 0.5 + 0.2 + (w - 0.4) * (float(j) + b.rng.randf() * 0.5) / k
			match b.rng.randi() % 3:
				0:
					b.cyl(Kit.plain(Color(0.35, 0.25, 0.17), 0.8), Vector3(x, y + 0.02, 0), Vector3(x, y + 0.2, 0), 0.06, 0.055, 9, 0.03)
					b.cyl(Kit.wood("dark"), Vector3(x, y + 0.2, 0), Vector3(x, y + 0.23, 0), 0.04, 0.04, 8)
				1:
					b.blob(Kit.cloth("grain"), Vector3(x, y + 0.12, 0), Vector3(0.12, 0.1, 0.09), b.rng.randi() % 100, 0.18, 2.0, 5, 9, Basis(), false, 0.5)
				_:
					b.box(Kit.wood("dark"), Vector3(x, y + 0.05, 0.0), Vector3(0.2, 0.1, 0.14), Basis(Vector3.UP, b.rng.randf_range(-0.5, 0.5)), 0.003)
	var ang := atan2(h - 0.3, w - 0.2)
	b.box(Kit.wood("dark"), Vector3(0, h * 0.5, -d * 0.5 - 0.012), Vector3(sqrt(pow(w - 0.2, 2.0) + pow(h - 0.3, 2.0)), 0.07, 0.02), Basis(Vector3.BACK, ang), 0.002)
	return Kit.asset("Shelf_%dTier" % tiers, b, "convex")
