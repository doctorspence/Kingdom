class_name Campfire
extends Node3D
## A campfire: a ring of stones, logs, ash, living flames, rising smoke, a few
## sparks and a flickering warm light. Built entirely in code from textured
## materials; nothing to set up. Drop it anywhere on the ground.

@export var light_energy := 2.6
@export var light_range := 11.0
@export var flame_height := 0.9

const STONE := preload("res://levels/common/materials/rock.tres")
const BARK := preload("res://levels/common/materials/bark.tres")
const ASH := preload("res://levels/common/materials/burned.tres")

var _light: OmniLight3D
var _base := 2.6
var _phase := 0.0


func _ready() -> void:
	_phase = randf() * TAU
	_build_ring()
	_build_logs()
	_build_flames()
	_build_light()
	# A solid footprint so nobody walks through the fire.
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.8
	cyl.height = 0.5
	shape.shape = cyl
	shape.position.y = 0.25
	body.add_child(shape)
	add_child(body)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001 + _phase
	var flicker := 0.85 + 0.15 * sin(t * 9.0) * sin(t * 4.3) + 0.06 * sin(t * 23.0)
	_light.light_energy = _base * flicker


func _build_ring() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(global_position.x * 13.0 + global_position.z * 29.0))
	for i in 9:
		var a := TAU * i / 9.0 + rng.randf_range(-0.15, 0.15)
		var stone := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = rng.randf_range(0.17, 0.27)
		mesh.height = mesh.radius * 1.5
		mesh.radial_segments = 8
		mesh.rings = 4
		mesh.material = STONE
		stone.mesh = mesh
		stone.position = Vector3(cos(a) * 0.72, mesh.height * 0.35, sin(a) * 0.72)
		stone.rotation = Vector3(rng.randf() * 0.5, rng.randf() * TAU, rng.randf() * 0.5)
		add_child(stone)
	var ash := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.62
	disc.bottom_radius = 0.68
	disc.height = 0.05
	disc.material = ASH
	ash.mesh = disc
	ash.position.y = 0.025
	add_child(ash)


func _build_logs() -> void:
	for i in 4:
		var log_mesh := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.07
		cyl.bottom_radius = 0.1
		cyl.height = 1.0
		cyl.radial_segments = 6
		cyl.material = BARK
		log_mesh.mesh = cyl
		var a := TAU * i / 4.0 + 0.4
		log_mesh.position = Vector3(cos(a) * 0.12, 0.22, sin(a) * 0.12)
		log_mesh.rotation = Vector3(0.0, -a, deg_to_rad(70.0))
		add_child(log_mesh)


func _build_flames() -> void:
	var sprite := GradientTexture2D.new()
	sprite.fill = GradientTexture2D.FILL_RADIAL
	sprite.fill_from = Vector2(0.5, 0.5)
	sprite.fill_to = Vector2(0.5, 0.0)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	sprite.gradient = g
	sprite.width = 64
	sprite.height = 64
	add_child(_particles(sprite, 26, 0.9, Color(1.0, 0.75, 0.3, 0.9), Color(0.9, 0.2, 0.03, 0.0), 0.5, 0.2, 1.4, true))
	add_child(_particles(sprite, 8, 3.5, Color(0.2, 0.2, 0.2, 0.28), Color(0.1, 0.1, 0.1, 0.0), 0.9, 0.5, 1.0, false, 0.9))
	add_child(_particles(sprite, 6, 2.2, Color(1.0, 0.8, 0.4, 1.0), Color(1.0, 0.3, 0.05, 0.0), 0.06, 0.02, 3.0, true))


func _particles(texture: Texture2D, amount: int, lifetime: float, from: Color, to: Color, size: float, size_jitter: float, rise: float, glow: bool, lift := 0.3) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 8, 6))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.22
	pm.direction = Vector3.UP
	pm.spread = 14.0
	pm.initial_velocity_min = rise * 0.5
	pm.initial_velocity_max = rise
	pm.gravity = Vector3(0, lift, 0)
	pm.scale_min = maxf(size - size_jitter, 0.02)
	pm.scale_max = size + size_jitter
	var ramp := Gradient.new()
	ramp.set_color(0, from)
	ramp.set_color(1, to)
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = ramp
	pm.color_ramp = ramp_tex
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 1)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = texture
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glow:
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.disable_receive_shadows = true
	quad.material = mat
	p.draw_pass_1 = quad
	p.position.y = 0.25
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


func _build_light() -> void:
	_base = light_energy
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.62, 0.28)
	_light.light_energy = light_energy
	_light.omni_range = light_range
	_light.position.y = 0.8
	_light.shadow_enabled = true
	add_child(_light)
