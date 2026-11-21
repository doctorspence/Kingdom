extends RefCounted
## Lanterns, candles and oil lamps: small warm lights.

const Kit := preload("res://assets/hideout/Materials/kit.gd")


static func _flame_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.8, 0.45)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.55, 0.16)
	m.emission_energy_multiplier = 3.0
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


static func _light(parent: Node3D, pos: Vector3, energy: float, rng_range: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = Color(1.0, 0.6, 0.28)
	l.light_energy = energy
	l.omni_range = rng_range
	l.omni_attenuation = 1.5
	parent.add_child(l)
	l.set_script(Kit.FLICKER)
	l.set("base_energy", energy)


## Iron-framed lantern with horn panes, to hang from a hook. Origin at the hanging ring (top); body hangs below.
static func lantern(light := true, seed_ := 91) -> Node3D:
	var b := Kit.MB.new(seed_)
	var iron := Kit.iron()
	b.cyl(iron, Vector3(0, 0.0, 0), Vector3(0, 0.07, 0), 0.03, 0.03, 8)
	b.lathe(iron, PackedVector2Array([Vector2(0.0, -0.02), Vector2(0.04, -0.02), Vector2(0.09, -0.07), Vector2(0.095, -0.09), Vector2(0.0, -0.09)]), 6)
	for i in 4:
		var a := TAU * float(i) / 4.0 + PI * 0.25
		b.cyl(iron, Vector3(cos(a) * 0.085, -0.09, sin(a) * 0.085), Vector3(cos(a) * 0.085, -0.3, sin(a) * 0.085), 0.008, 0.008, 4)
	b.box(iron, Vector3(0, -0.31, 0), Vector3(0.19, 0.02, 0.19), Basis(Vector3.UP, PI * 0.25))
	# horn panes
	var pane := Kit.plain(Color(0.7, 0.5, 0.25), 0.4)
	for i in 4:
		var a := TAU * float(i) / 4.0
		b.quad(pane, Vector3(cos(a - 0.78) * 0.085, -0.1, sin(a - 0.78) * 0.085), Vector3(cos(a + 0.78) * 0.085, -0.1, sin(a + 0.78) * 0.085),
			Vector3(cos(a + 0.78) * 0.085, -0.29, sin(a + 0.78) * 0.085), Vector3(cos(a - 0.78) * 0.085, -0.29, sin(a - 0.78) * 0.085), Vector3(cos(a), 0, sin(a)))
	b.cyl(Kit.plain(Color(0.75, 0.68, 0.5), 0.8), Vector3(0, -0.3, 0), Vector3(0, -0.2, 0), 0.025, 0.022, 7)
	b.blob(_flame_mat(), Vector3(0, -0.17, 0), Vector3(0.018, 0.04, 0.018), 1, 0.1, 2.0, 4, 6)
	var root := Kit.asset("Lantern", b, "none")
	if light:
		_light(root, Vector3(0, -0.17, 0), 1.4, 7.0)
	return root


## One to three candles on a clay dish or an iron spike holder. count 1..3.
static func candles(count := 3, seed_ := 92) -> Node3D:
	var b := Kit.MB.new(seed_)
	b.lathe(Kit.plain(Color(0.34, 0.2, 0.12), 0.8), PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.09, 0.0), Vector2(0.12, 0.02), Vector2(0.115, 0.025), Vector2(0.0, 0.012)]), 12)
	var wax := Kit.plain(Color(0.82, 0.76, 0.6), 0.55)
	for i in count:
		var a := TAU * float(i) / maxf(count, 1.0) + 0.6
		var r := 0.0 if count == 1 else 0.05
		var h := b.rng.randf_range(0.06, 0.16)
		var p := Vector3(cos(a) * r, 0.015, sin(a) * r)
		b.cyl(wax, p, p + Vector3(0, h, 0), 0.016, 0.014, 8, 0.1, true)
		b.blob(wax, p + Vector3(0.012, 0.01, 0.0), Vector3(0.025, 0.012, 0.02), i, 0.2, 2.0, 3, 6)
		b.blob(_flame_mat(), p + Vector3(0, h + 0.022, 0), Vector3(0.008, 0.02, 0.008), i, 0.1, 2.0, 3, 6)
	var root := Kit.asset("Candles_%d" % count, b, "none")
	_light(root, Vector3(0, 0.22, 0), 0.5 + 0.3 * count, 4.5)
	return root


## Clay oil lamp with a wick. Origin at the base.
static func oil_lamp(seed_ := 93) -> Node3D:
	var b := Kit.MB.new(seed_)
	var clay := Kit.plain(Color(0.4, 0.26, 0.17), 0.75)
	b.lathe(clay, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.05, 0.0), Vector2(0.085, 0.03), Vector2(0.07, 0.065), Vector2(0.04, 0.075), Vector2(0.0, 0.075)]), 12, true)
	b.disc(Kit.plain(Color(0.1, 0.07, 0.03), 0.3), 0.07, 0.04, 10)
	b.cyl(clay, Vector3(0.07, 0.04, 0), Vector3(0.13, 0.06, 0), 0.02, 0.012, 7)
	b.cyl(Kit.cloth("grain"), Vector3(0.125, 0.06, 0), Vector3(0.14, 0.075, 0), 0.006, 0.005, 5)
	b.blob(_flame_mat(), Vector3(0.14, 0.095, 0), Vector3(0.012, 0.028, 0.012), 1, 0.1, 2.0, 3, 6)
	b.cyl(clay, Vector3(-0.06, 0.03, 0), Vector3(-0.115, 0.05, 0), 0.01, 0.01, 6)
	b.cyl(clay, Vector3(-0.115, 0.05, 0), Vector3(-0.06, 0.07, 0), 0.01, 0.01, 6)
	var root := Kit.asset("OilLamp", b, "none")
	_light(root, Vector3(0.14, 0.18, 0), 0.7, 5.0)
	return root
