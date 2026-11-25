extends RefCounted
## Lighting and effects, FX01-FX13 (see assets/outpost/MANIFEST.md). FX02 is the CP05 brazier,
## FX03 the CP17 lantern; FX06/FX07/FX08/FX11 (forge fire, smoke, torch flame, sparks) are the
## hideout kit's fire_fx() used by the torch holder, brazier, forge and hearths; FX10 (ground fog)
## is the zone's Mist node. Real-world size. Origins: centre of the base on y = 0 (the wall
## lantern: on the wall, facing +Z).

const HK := preload("res://assets/hideout/Materials/kit.gd")
const K := preload("res://assets/outpost/materials/outpost_kit.gd")
const CPA := preload("res://assets/outpost/castle_approach/castle_approach.gd")


## FX01: standing wooden torch: a pitch-wrapped torch on a tall stake, burning.
static func standing_torch() -> Node3D:
	var b := HK.MB.new(1101)
	b.cyl(K.oak("weathered"), Vector3(0, 0, 0), Vector3(0, 1.7, 0), 0.04, 0.035, 6, 0.06)
	b.cyl(K.iron(), Vector3(0, 1.62, 0), Vector3(0, 1.7, 0), 0.05, 0.05, 6)
	b.cyl(K.goods("pitch", Color(0.12, 0.09, 0.07), 0.6), Vector3(0, 1.7, 0), Vector3(0, 1.9, 0), 0.055, 0.045, 6)
	var root := K.asset("FX01_standing_wooden_torch", b, [["cyl", Vector3(0, 0.85, 0), 0.06, 1.7]])
	HK.fire_fx(root, Vector3(0, 1.93, 0), 0.4, 2.0, false)
	return root


## FX04: wall-mounted lantern: an iron bracket arm with the CP17 lantern hanging from it.
static func wall_lantern() -> Node3D:
	var b := HK.MB.new(1104)
	b.box(K.iron(), Vector3(0, 0, 0.012), Vector3(0.1, 0.25, 0.024))
	b.box(K.iron(), Vector3(0, 0.08, 0.22), Vector3(0.03, 0.03, 0.42))
	b.cyl(K.iron(), Vector3(0, -0.08, 0.02), Vector3(0, 0.07, 0.3), 0.01, 0.01, 4)
	var root := K.asset("FX04_wall_mounted_lantern", b, [])
	var lantern := CPA.iron_lantern()
	lantern.name = "Lantern"
	lantern.position = Vector3(0, 0.06, 0.4)
	root.add_child(lantern)
	return root


## FX05: candle cluster: a few tallow candles of different heights on a plate, lit.
static func candles() -> Node3D:
	var b := HK.MB.new(1105)
	b.cyl(K.iron(), Vector3(0, 0, 0), Vector3(0, 0.015, 0), 0.14, 0.14, 12)
	var wax := K.goods("tallow", Color(0.86, 0.8, 0.66), 0.6)
	var hot := K.lantern_glow()
	for c in [Vector3(-0.05, 0, 0.02), Vector3(0.05, 0, -0.03), Vector3(0.0, 0, 0.07), Vector3(0.08, 0, 0.06)]:
		var h: float = 0.08 + absf(c.x + c.z) * 0.8
		b.cyl(wax, c + Vector3(0, 0.015, 0), c + Vector3(0, 0.015 + h, 0), 0.02, 0.018, 6)
		b.blob(hot, c + Vector3(0, 0.04 + h, 0), Vector3(0.008, 0.02, 0.008), 1, 0.0, 1.0, 3, 5)
	var root := K.asset("FX05_candle_cluster", b, [])
	K.flicker_light(root, Vector3(0, 0.25, 0), 0.7, 4.0)
	return root


## FX09: campfire: a ring of stones, crossed logs, embers and a fire.
static func campfire() -> Node3D:
	var b := HK.MB.new(1109)
	for i in 9:
		var a := TAU * i / 9.0
		b.blob(K.limestone(), Vector3(cos(a) * 0.55, 0.0, sin(a) * 0.55), Vector3(0.13, 0.1, 0.11), 1109 + i, 0.25, 1.5, 4, 7, Basis(Vector3.UP, a), false, 0.4)
	for i in 4:
		var a := TAU * i / 4.0 + 0.3
		b.cyl(K.oak("weathered"), Vector3(cos(a) * 0.45, 0.04, sin(a) * 0.45), Vector3(cos(a) * 0.05, 0.25, sin(a) * 0.05), 0.05, 0.045, 6)
	for i in 7:
		b.blob(HK.ember(), Vector3(cos(i * 0.9) * 0.15, 0.03, sin(i * 0.9) * 0.15), Vector3(0.08, 0.03, 0.07), 1120 + i, 0.3, 2.0, 3, 6)
	var root := K.asset("FX09_campfire", b, [])
	HK.fire_fx(root, Vector3(0, 0.2, 0), 1.0, 3.2, true)
	return root


static func _soft_ring() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.7, 0.85, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t


static func _particles(root: Node3D, nm: String, area: Vector3, amount: int, life: float, pm: ParticleProcessMaterial, mat: StandardMaterial3D, quad: Vector2) -> void:
	var p := GPUParticles3D.new()
	p.name = nm
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.process_material = pm
	p.visibility_aabb = AABB(-area * 0.5 - Vector3(0, 0.5, 0), area + Vector3(0, 1.0, 0))
	var qm := QuadMesh.new()
	qm.size = quad
	qm.material = mat
	p.draw_pass_1 = qm
	root.add_child(p)


## FX12: rain splash: tiny splashes jumping off a 4 x 4 m patch (puddles, roofs' drip lines).
## Turn it on with the weather (visible = raining).
static func rain_splash() -> Node3D:
	var root := Node3D.new()
	root.name = "FX12_rain_splash"
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(2.0, 0.01, 2.0)
	pm.direction = Vector3.UP
	pm.spread = 25.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.2
	pm.gravity = Vector3(0, -9.8, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.albedo_color = Color(0.75, 0.8, 0.85, 0.45)
	_particles(root, "Splashes", Vector3(4, 0.5, 4), 120, 0.25, pm, mat, Vector2(0.02, 0.05))
	return root


## FX13: water ripples: rings spreading on still water (a trough, a puddle, the creek's pools),
## 3 x 3 m. Place it just above the water surface.
static func water_ripples() -> Node3D:
	var root := Node3D.new()
	root.name = "FX13_water_ripples"
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(1.5, 0.0, 1.5)
	pm.gravity = Vector3.ZERO
	pm.scale_curve = HK._curve([Vector2(0, 0.1), Vector2(1, 1.0)])
	pm.color_ramp = HK._ramp([Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0)], [0.0, 1.0])
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _soft_ring()
	mat.albedo_color = Color(0.8, 0.85, 0.9, 1)
	_particles(root, "Rings", Vector3(3, 0.2, 3), 14, 1.6, pm, mat, Vector2(0.5, 0.5))
	var p := root.get_node("Rings") as GPUParticles3D
	(p.draw_pass_1 as QuadMesh).orientation = PlaneMesh.FACE_Y
	return root
