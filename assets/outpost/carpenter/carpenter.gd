extends RefCounted
## Carpenter props, CR02-CR16 (see assets/outpost/MANIFEST.md). CR01 is the B06 workshop. Real-world
## size. Origins: centre of the base on y = 0; the front faces +Z. The wheel and cart helpers are
## shared with the stable (manure cart) and the story props (handcart).

const HK := preload("res://assets/hideout/Materials/kit.gd")
const K := preload("res://assets/outpost/materials/outpost_kit.gd")


static func _beam(b: HK.MB, m: Material, a: Vector3, c: Vector3, t: float, t2 := -1.0) -> void:
	b.box(m, (a + c) * 0.5, Vector3(a.distance_to(c), t, t if t2 < 0.0 else t2), HK.basis_x(c - a), 0.003)


## A spoked cart wheel standing in the plane facing axis, centred at c: iron tyre, felloes,
## spokes, hub.
static func wheel(b: HK.MB, c: Vector3, r: float, axis: Vector3, spokes := 10) -> void:
	var ax := axis.normalized()
	var u := HK.basis_y(ax).x
	var v := ax.cross(u)
	var oak := K.oak("weathered")
	var segs := 16
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		var p0 := c + (u * cos(a0) + v * sin(a0)) * r
		var p1 := c + (u * cos(a1) + v * sin(a1)) * r
		var mid := (p0 + p1) * 0.5
		var tang := (p1 - p0).normalized()
		b.box(oak, mid - (mid - c).normalized() * 0.035, Vector3(p0.distance_to(p1) + 0.01, 0.07, 0.07), Basis(tang, (mid - c).normalized(), ax))
		b.box(K.iron(), mid + (mid - c).normalized() * 0.006, Vector3(p0.distance_to(p1) + 0.012, 0.014, 0.075), Basis(tang, (mid - c).normalized(), ax))
	for i in spokes:
		var a := TAU * i / spokes
		var d := u * cos(a) + v * sin(a)
		b.cyl(oak, c + d * 0.08, c + d * (r - 0.06), 0.018, 0.014, 5)
	b.cyl(oak, c - ax * 0.1, c + ax * 0.1, 0.085, 0.085, 10)
	b.cyl(K.iron(), c - ax * 0.12, c + ax * 0.12, 0.03, 0.03, 6)


## A two-wheeled cart body: a plank bed with low sides, two shafts to the front (+Z), resting on
## its shafts' feet. width w, length l, wheel radius r. Returns the bed's floor height.
static func cart(b: HK.MB, w: float, l: float, r: float, sides := 0.3) -> float:
	var oak := K.oak("weathered")
	var bed := r + 0.05
	b.cyl(oak, Vector3(-w * 0.5 - 0.15, r, 0), Vector3(w * 0.5 + 0.15, r, 0), 0.05, 0.05, 6)
	for s in [-1.0, 1.0]:
		wheel(b, Vector3(s * (w * 0.5 + 0.12), r, 0), r, Vector3(1, 0, 0))
	b.box(oak, Vector3(0, bed, 0), Vector3(w, 0.05, l), Basis(), 0.003)
	for s in [-1.0, 1.0]:
		b.box(oak, Vector3(s * w * 0.5, bed + sides * 0.5, 0), Vector3(0.04, sides, l), Basis(), 0.003)
		b.box(oak, Vector3(s * w * 0.32, bed - 0.04, l * 0.5 + 0.7), Vector3(0.07, 0.07, 1.6), Basis(Vector3(1, 0, 0), -0.32), 0.003)
	b.box(oak, Vector3(0, bed + sides * 0.5, -l * 0.5), Vector3(w, sides, 0.04), Basis(), 0.003)
	b.box(oak, Vector3(0, bed + sides * 0.5, l * 0.5), Vector3(w, sides, 0.04), Basis(), 0.003)
	return bed + 0.025


## CR02: workbench (= the bench in B06, also a loose piece): heavy oak top on splayed legs,
## a few tools on it.
static func workbench() -> Node3D:
	var b := HK.MB.new(602)
	var oak := K.oak()
	b.box(oak, Vector3(0, 0.82, 0), Vector3(2.0, 0.09, 0.65), Basis(), 0.006)
	for x in [-0.85, 0.85]:
		for z in [-0.25, 0.25]:
			b.box(oak, Vector3(x, 0.39, z), Vector3(0.09, 0.78, 0.09), Basis(), 0.004)
	b.box(oak, Vector3(0, 0.2, 0), Vector3(1.8, 0.04, 0.55), Basis(), 0.003)
	_mallet(b, Vector3(-0.6, 0.865, 0.05), 0.4)
	_saw(b, Vector3(0.3, 0.87, -0.1), 0.2)
	return K.asset("CR02_workbench", b, [["box", Vector3(0, 0.43, 0), Vector3(2.0, 0.86, 0.65)]])


## CR03: sawhorse: a beam on two pairs of splayed legs.
static func sawhorse() -> Node3D:
	var b := HK.MB.new(603)
	var oak := K.oak("weathered")
	b.box(oak, Vector3(0, 0.66, 0), Vector3(1.1, 0.1, 0.1), Basis(), 0.004)
	for x in [-0.42, 0.42]:
		for s in [-1.0, 1.0]:
			_beam(b, oak, Vector3(x + 0.05 * s, 0, s * 0.3), Vector3(x, 0.64, 0), 0.06)
	return K.asset("CR03_sawhorse", b, [["box", Vector3(0, 0.33, 0), Vector3(1.1, 0.7, 0.6)]])


static func _saw(b: HK.MB, c: Vector3, yaw: float) -> void:
	var bas := Basis(Vector3.UP, yaw)
	b.box(K.iron(), c + bas * Vector3(0.12, 0.003, 0), Vector3(0.55, 0.004, 0.12), bas)
	b.box(K.oak(), c + bas * Vector3(-0.2, 0.012, 0.0), Vector3(0.14, 0.024, 0.1), bas, 0.003)


static func _mallet(b: HK.MB, c: Vector3, yaw: float) -> void:
	var bas := Basis(Vector3.UP, yaw)
	b.cyl(K.oak(), c + bas * Vector3(-0.15, 0.0, 0), c + bas * Vector3(0.1, 0.0, 0), 0.015, 0.015, 5)
	b.cyl(K.oak("weathered"), c + bas * Vector3(0.12, 0.0, -0.08), c + bas * Vector3(0.12, 0.0, 0.08), 0.05, 0.05, 8)


## CR04: hand saw lying flat.
static func hand_saw() -> Node3D:
	var b := HK.MB.new(604)
	_saw(b, Vector3.ZERO, 0.0)
	return K.asset("CR04_hand_saw", b, [])


## CR05: wooden mallet lying on its side.
static func mallet() -> Node3D:
	var b := HK.MB.new(605)
	_mallet(b, Vector3(0, 0.05, 0), 0.0)
	return K.asset("CR05_wooden_mallet", b, [])


## CR06: chisels and carving tools in an open leather roll.
static func chisels() -> Node3D:
	var b := HK.MB.new(606)
	b.box(K.leather(), Vector3(0, 0.005, 0), Vector3(0.5, 0.01, 0.3), Basis(), 0.002)
	for i in 6:
		var x := -0.2 + i * 0.08
		b.cyl(K.oak(), Vector3(x, 0.02, 0.12), Vector3(x, 0.02, 0.0), 0.012, 0.012, 5)
		b.box(K.iron(), Vector3(x, 0.018, -0.07), Vector3(0.01 + 0.004 * (i % 3), 0.006, 0.14))
	return K.asset("CR06_chisels_and_carving_tools", b, [])


## CR07: timber plank piles: planks stacked in layers on spacers, 3 m long.
static func plank_pile() -> Node3D:
	var b := HK.MB.new(607)
	var oak := K.oak("weathered")
	for x in [-1.2, 0.0, 1.2]:
		b.box(oak, Vector3(x, 0.05, 0), Vector3(0.1, 0.1, 0.9), Basis(), 0.004)
	for layer in 4:
		var y := 0.12 + layer * 0.075
		for i in 3:
			b.box(oak, Vector3(0.02 * (layer % 2), y, -0.27 + i * 0.27), Vector3(3.0, 0.045, 0.24), Basis(Vector3.UP, 0.01 * (i - 1)), 0.004)
		if layer < 3:
			for x in [-1.2, 0.0, 1.2]:
				b.box(oak, Vector3(x, y + 0.035, 0), Vector3(0.04, 0.03, 0.85), Basis(), 0.0)
	return K.asset("CR07_timber_plank_pile", b, [["box", Vector3(0, 0.2, 0), Vector3(3.0, 0.4, 0.9)]])


## CR08: cut logs: trunks stacked in a pyramid, 2.4 m long.
static func cut_logs() -> Node3D:
	var b := HK.MB.new(608)
	var rows := [3, 2, 1]
	for r in rows.size():
		for i in rows[r]:
			var z: float = (i - (rows[r] - 1) * 0.5) * 0.4
			var y := 0.19 + r * 0.33
			b.cyl(K.oak("weathered"), Vector3(-1.2, y, z), Vector3(1.2, y, z), 0.19, 0.17, 9, 0.05)
	return K.asset("CR08_cut_logs", b, [["box", Vector3(0, 0.5, 0), Vector3(2.4, 1.0, 1.2)]])


## CR10: wood shavings: pale curls scattered on the floor.
static func shavings() -> Node3D:
	var b := HK.MB.new(610)
	var pale := K.goods("shaving", Color(0.78, 0.62, 0.42), 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 610
	for i in 40:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * 0.6
		b.blob(pale, Vector3(cos(a) * d, 0.01, sin(a) * d * 0.7), Vector3(0.04, 0.012, 0.02), i, 0.4, 2.0, 3, 5, Basis(Vector3.UP, rng.randf() * TAU))
	return K.asset("CR10_wood_shavings", b, [])


## CR11: wooden cart: a two-wheeled hand cart with plank sides and shafts.
static func wooden_cart() -> Node3D:
	var b := HK.MB.new(611)
	cart(b, 1.2, 1.8, 0.55)
	return K.asset("CR11_wooden_cart", b, [["box", Vector3(0, 0.55, 0), Vector3(1.6, 1.1, 1.9)]])


## CR12: cart wheels: two spare wheels leaning against each other.
static func cart_wheels() -> Node3D:
	var b := HK.MB.new(612)
	wheel(b, Vector3(-0.08, 0.53, 0), 0.55, Vector3(1, 0, 0.35))
	wheel(b, Vector3(0.12, 0.53, 0.05), 0.55, Vector3(1, 0, -0.3))
	return K.asset("CR12_cart_wheels", b, [["box", Vector3(0, 0.55, 0), Vector3(0.6, 1.1, 1.2)]])


## CR13: wagon axle: an oak axle beam with iron-bound ends, on a block.
static func wagon_axle() -> Node3D:
	var b := HK.MB.new(613)
	b.box(K.oak("weathered"), Vector3(0, 0.12, 0), Vector3(0.3, 0.24, 0.3), Basis(), 0.006)
	b.box(K.oak(), Vector3(0, 0.3, 0), Vector3(1.6, 0.12, 0.12), Basis(), 0.004)
	for s in [-1.0, 1.0]:
		b.cyl(K.iron(), Vector3(s * 0.8, 0.3, 0), Vector3(s * 0.98, 0.3, 0), 0.04, 0.03, 6)
	return K.asset("CR13_wagon_axle", b, [])


## CR15: wooden pegs: a small crate of turned pegs.
static func pegs() -> Node3D:
	var b := HK.MB.new(615)
	b.box(K.oak("weathered"), Vector3(0, 0.08, 0), Vector3(0.4, 0.16, 0.3), Basis(), 0.003)
	b.box(K.goods("dark", Color(0.06, 0.04, 0.03)), Vector3(0, 0.161, 0), Vector3(0.36, 0.002, 0.26))
	var rng := RandomNumberGenerator.new()
	rng.seed = 615
	for i in 18:
		var p := Vector3(rng.randf_range(-0.16, 0.16), 0.17, rng.randf_range(-0.11, 0.11))
		var d := Vector3(rng.randf_range(-1, 1), 0.3, rng.randf_range(-1, 1)).normalized() * 0.12
		b.cyl(K.oak(), p - d * 0.5, p + d * 0.5, 0.012, 0.009, 4)
	return K.asset("CR15_wooden_pegs", b, [])


## CR16: timber frame section: a jointed wall frame (posts, rails, a brace) on two trestles.
static func frame_section() -> Node3D:
	var b := HK.MB.new(616)
	var oak := K.oak("weathered")
	for x in [-1.0, 1.0]:
		b.box(oak, Vector3(x, 0.3, 0), Vector3(0.1, 0.6, 0.7), Basis(), 0.004)
	var y := 0.65
	for z in [-0.9, 0.9]:
		b.box(K.oak(), Vector3(0, y, z), Vector3(2.4, 0.16, 0.16), Basis(), 0.004)
	for x in [-1.1, 0.0, 1.1]:
		b.box(K.oak(), Vector3(x, y, 0), Vector3(0.16, 0.16, 1.8), Basis(), 0.004)
	_beam(b, K.oak(), Vector3(-1.0, y, -0.8), Vector3(-0.1, y, 0.8), 0.12)
	return K.asset("CR16_timber_frame_section", b, [["box", Vector3(0, 0.37, 0), Vector3(2.4, 0.75, 2.0)]])
