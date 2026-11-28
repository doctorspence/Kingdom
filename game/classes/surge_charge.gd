extends Node3D
## The glowing charge between a caster's hands while Arcane Surge is channelled.
## Created by AbilityCaster on EVERY machine that sees the caster (owner and remote
## copies), follows the midpoint of the two hand bones, grows and brightens over the
## channel, and is removed on release (a bright flash) or cancel (a quick fade).

## How long the channel lasts (set from the ability's cast_time; the default
## matches the shipped Arcane Surge for remote copies that don't know it).
var channel_time := 0.333
const FLASH_TIME := 0.18
const CANCEL_TIME := 0.12
## Sits a little beyond the wrists, in front of the palms (metres along the facing).
const FORWARD_OFFSET := 0.09

var _model: CharacterModel
var _skeleton: Skeleton3D
var _hand_l := -1
var _hand_r := -1
var _age := 0.0
var _ending := 0.0  # > 0 while fading out
var _end_time := FLASH_TIME
var _released := false
var _orb: MeshInstance3D
var _mat: StandardMaterial3D
var _light: OmniLight3D
var _motes: CPUParticles3D
var _channel_cue_played := false


func setup(model: CharacterModel) -> void:
	_model = model
	_skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	_hand_l = _skeleton.find_bone("hand_l")
	_hand_r = _skeleton.find_bone("hand_r")
	top_level = true


func _ready() -> void:
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat.albedo_color = Color(0.2, 0.5, 1.0, 0.9)
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 16
	sphere.rings = 8
	_orb = MeshInstance3D.new()
	_orb.mesh = sphere
	_orb.material_override = _mat
	_orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_orb)
	_light = OmniLight3D.new()
	_light.light_color = Color(0.45, 0.7, 1.0)
	_light.light_energy = 0.0
	_light.omni_range = 3.5
	_light.shadow_enabled = false
	add_child(_light)
	# Motes drifting in toward the orb.
	var quad := QuadMesh.new()
	quad.size = Vector2(0.06, 0.06)
	var pmat := StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	pmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	pmat.albedo_color = Color(0.6, 0.85, 1.0, 0.9)
	pmat.albedo_texture = soft_dot()
	quad.material = pmat
	_motes = CPUParticles3D.new()
	_motes.mesh = quad
	_motes.amount = 28
	_motes.lifetime = 0.45
	_motes.local_coords = false
	_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE_SURFACE
	_motes.emission_sphere_radius = 0.45
	_motes.direction = Vector3.ZERO
	_motes.spread = 180.0
	_motes.gravity = Vector3.ZERO
	_motes.initial_velocity_min = 0.0
	_motes.initial_velocity_max = 0.0
	_motes.radial_accel_min = -2.2
	_motes.radial_accel_max = -1.6
	_motes.scale_amount_min = 0.6
	_motes.scale_amount_max = 1.3
	add_child(_motes)
	_follow()
	_update_look(0.0)
	_play(&"surge_gather")


func _process(delta: float) -> void:
	_follow()
	if _ending > 0.0:
		_ending -= delta
		var k := clampf(_ending / _end_time, 0.0, 1.0)
		if _released:
			# Flash: swell and brighten, then fade.
			_orb.scale = Vector3.ONE * lerpf(0.9, 0.3, k)
			_light.light_energy = 6.0 * k
			_mat.albedo_color.a = 0.9 * k
		else:
			_orb.scale = _orb.scale.lerp(Vector3.ONE * 0.02, 1.0 - k)
			_light.light_energy *= k
			_mat.albedo_color.a = 0.9 * k
		if _ending <= 0.0:
			queue_free()
		return
	_age += delta
	_update_look(clampf(_age / channel_time, 0.0, 1.0))
	# The held channel hum only fits a long channel; a quick cast is gather + release.
	if not _channel_cue_played and channel_time >= 0.6 and _age >= 0.3 * channel_time:
		_channel_cue_played = true
		_play(&"surge_channel")


## Grow and brighten with the channel (0 = start, 1 = ready to release).
func _update_look(k: float) -> void:
	var tremble := 1.0 + 0.06 * sin(_age * 40.0) * k
	_orb.scale = Vector3.ONE * lerpf(0.04, 0.3, k * k) * tremble
	_mat.albedo_color.a = lerpf(0.5, 0.95, k)
	_light.light_energy = lerpf(0.1, 3.2, k)
	_motes.emitting = true
	_motes.emission_sphere_radius = lerpf(0.25, 0.5, k)


## The midpoint of the hands, a little in front of them.
func _follow() -> void:
	if _skeleton == null or not is_instance_valid(_skeleton) or _hand_l < 0 or _hand_r < 0:
		return
	var a := _skeleton.global_transform * _skeleton.get_bone_global_pose(_hand_l).origin
	var b := _skeleton.global_transform * _skeleton.get_bone_global_pose(_hand_r).origin
	var fwd := _model.forward() if is_instance_valid(_model) else Vector3.ZERO
	global_position = (a + b) * 0.5 + fwd * FORWARD_OFFSET


func finish(released: bool) -> void:
	if _ending > 0.0:
		return
	_released = released
	_end_time = FLASH_TIME if released else CANCEL_TIME
	_ending = _end_time
	_motes.emitting = false


func _play(cue: StringName) -> void:
	Audio.sfx(cue, global_position)


## A soft round dot (white in the middle, clear at the rim) for particle quads, so the
## motes are glowing points, not squares. Shared by the charge, the wave and the impact.
static var _dot: GradientTexture2D

static func soft_dot() -> GradientTexture2D:
	if _dot == null:
		var grad := Gradient.new()
		grad.set_color(0, Color(1, 1, 1, 1))
		grad.set_color(1, Color(1, 1, 1, 0))
		_dot = GradientTexture2D.new()
		_dot.gradient = grad
		_dot.fill = GradientTexture2D.FILL_RADIAL
		_dot.fill_from = Vector2(0.5, 0.5)
		_dot.fill_to = Vector2(1.0, 0.5)
		_dot.width = 32
		_dot.height = 32
	return _dot
