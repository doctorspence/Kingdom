extends Node3D
## Arcane Surge's wave: a wide, flat wave of blue light that sweeps forward from the
## caster and passes THROUGH enemies (it does not stop on the first one).
##
## Only the caster's copy ("owned") hits anything; copies on other machines are
## visual only. Hit rules (ARCANE_SURGE_PLAN.md, decision 6):
##  - each physics frame, enemies whose position along the wave axis lies inside the
##    stretch swept this frame and whose sideways offset is within half the width (plus a
##    margin) are candidates, nearest first;
##  - each needs a clear line of sight from the cast point (no solid wall between);
##  - at most `max_targets` enemies per cast, each once; the first is the PRIMARY hit
##    (`primary_damage`), the rest SECONDARY (`secondary_damage`);
##  - the wave stops at `travel` (range, or the first wall) and fades out.
## Only enemies are hit: players and everything else are ignored.
##
## Look and sound: _build_visual() (the crescent), _on_enemy_hit() (impact
## burst / sound), _play_release_cue() (release sound), and _fade() (end of life).

const CHARGE := preload("res://game/classes/surge_charge.gd")
const SPEED := 24.0
## How far in front of the cast point (chest) the wave starts.
const START_OFFSET := 0.8
## Extra sideways reach beyond half the width (enemy body radius).
const LATERAL_MARGIN := 0.4
## Extra reach along the axis each frame, so a fast frame never skips an enemy.
const AXIS_MARGIN := 0.3
const POISE_PRIMARY := 14.0
const POISE_SECONDARY := 8.0
const FADE_TIME := 0.15

# Set by AbilityCaster before the wave enters the tree.
var caster: AbilityCaster
var owned := false
## Cast point (the caster's chest). Distances below are measured from here.
var origin := Vector3.ZERO
var direction := Vector3.FORWARD  # flat, normalised
var travel := 12.0
## Width where the wave starts; it grows by `spread` metres per metre travelled.
var width := 3.0
var spread := 0.0
var primary_damage := 0.0
var secondary_damage := 0.0
var max_targets := 3
var hexed_bonus := 0.0

## Enemies already hit by this wave (once each).
var hit_nodes: Array[Node3D] = []

var _s := 0.0  # where the front of the wave is, along the axis from `origin`
var _swept := -0.5  # how far along the axis enemies have already been checked
var _fading := 0.0
var _visual: Node3D


func _ready() -> void:
	direction.y = 0.0
	direction = direction.normalized() if direction.length() > 0.01 else Vector3.FORWARD
	_s = minf(START_OFFSET, travel)
	_place()
	_build_visual()
	# Plays on every machine that sees the wave (after it has been placed).
	_play_release_cue.call_deferred()


func _physics_process(delta: float) -> void:
	if _fading > 0.0:
		_fading -= delta
		if _shader_mat:
			_shader_mat.set_shader_parameter(&"fade", clampf(_fading / FADE_TIME, 0.0, 1.0))
		if _fading <= 0.0:
			queue_free()
		return
	var next := minf(_s + SPEED * delta, travel)
	if not owned or is_instance_valid(caster):  # copies on other machines only play the impact looks
		_sweep(_swept, next + AXIS_MARGIN)
	_swept = next
	_s = next
	_place()
	if _s >= travel:
		_fade()


## The wave's full width `s` metres from the cast point.
func width_at(s: float) -> float:
	return width + spread * maxf(s, 0.0)


func _place() -> void:
	var pos := origin + direction * _s
	global_transform = Transform3D(Basis.looking_at(direction, Vector3.UP), pos)
	# Spread: the look is built at the starting width and stretched sideways.
	var k := width_at(_s) / width if width > 0.0 else 1.0
	if _visual:
		_visual.scale.x = k
	if _trail:
		_trail.emission_box_extents.x = width_at(_s) * 0.45


## Check the enemies between two distances along the axis. The owner hurts them; copies
## on other machines only show the impact.
func _sweep(from_s: float, to_s: float) -> void:
	if hit_nodes.size() >= max_targets:
		return
	var found: Array = []  # [distance along the axis, enemy]
	for n in get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Node3D
		if e == null or e in hit_nodes or not e.call(&"can_be_locked"):
			continue
		var rel := e.global_position - origin
		rel.y = 0.0
		var along := rel.dot(direction)
		if along < from_s or along > to_s or along > travel + AXIS_MARGIN:
			continue
		var side := (rel - direction * along).length()
		if side > width_at(along) * 0.5 + LATERAL_MARGIN:
			continue
		if not _clear_line(Vector3(e.call(&"get_lock_point"))):
			continue
		found.append([along, e])
	found.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	for entry in found:
		if hit_nodes.size() >= max_targets:
			break
		var e: Node3D = entry[1]
		var primary := hit_nodes.is_empty()
		hit_nodes.append(e)
		if owned:
			caster.strike(e, primary_damage if primary else secondary_damage,
					POISE_PRIMARY if primary else POISE_SECONDARY, 1.0, hexed_bonus)
		_on_enemy_hit(e, primary)


## No solid wall (world layer) between the cast point and the enemy's chest.
func _clear_line(to: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(origin, to, 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


# --- Look and sound (hook points) ---------------------------------------------------

const SHADER_CODE := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform float fade = 1.0;
void fragment() {
	float u = UV.x * 2.0 - 1.0;
	float v = UV.y;
	float edge = pow(clamp(1.0 - abs(u), 0.0, 1.0), 0.6);
	float vert = pow(clamp(sin(3.14159 * v), 0.0, 1.0), 0.8);
	// moving streaks and a slow shimmer through the body
	float streak = 0.75 + 0.25 * sin(u * 14.0 - TIME * 7.0 + v * 5.0);
	float shimmer = 0.92 + 0.08 * sin(TIME * 23.0 + u * 9.0);
	// thin bright leading band at chest height, brightest in the middle of the wave
	float band = exp(-pow((v - 0.5) / 0.09, 2.0)) * pow(edge, 1.2);
	vec3 body = vec3(0.10, 0.28, 1.0);
	vec3 bright = vec3(0.7, 1.0, 1.0);
	ALBEDO = body * 1.3 + bright * band * 2.4;
	ALPHA = clamp((edge * vert * streak * shimmer * 0.95 + band * 0.6) * fade, 0.0, 1.0);
}
"""

## Height of the wave and how far its middle bulges ahead of its ends (metres).
const VISUAL_HEIGHT := 1.7
const BULGE := 1.3
const COLUMNS := 20
const ROWS := 6

var _shader_mat: ShaderMaterial
var _trail: CPUParticles3D


## An enemy was struck (owner and visual copies): blue flash, sparks and a sound.
func _on_enemy_hit(e: Node3D, _primary: bool) -> void:
	var at := Vector3(e.call(&"get_lock_point"))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(0.4, 0.75, 1.0, 0.9)
	var ring := TorusMesh.new()  # a flat shock ring, not a ball
	ring.inner_radius = 0.42
	ring.outer_radius = 0.5
	ring.rings = 24
	ring.ring_segments = 6
	var flash := MeshInstance3D.new()
	flash.mesh = ring
	flash.material_override = mat
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var light := OmniLight3D.new()
	light.light_color = Color(0.5, 0.75, 1.0)
	light.light_energy = 2.0
	light.omni_range = 4.0
	flash.add_child(light)
	var sparks := CPUParticles3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.1, 0.1)
	var pmat := StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	pmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	pmat.albedo_color = Color(0.65, 0.9, 1.0, 1.0)
	pmat.albedo_texture = CHARGE.soft_dot()
	quad.material = pmat
	sparks.mesh = quad
	sparks.amount = 22
	sparks.lifetime = 0.45
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.direction = direction
	sparks.spread = 70.0
	sparks.initial_velocity_min = 2.5
	sparks.initial_velocity_max = 6.0
	sparks.gravity = Vector3(0, -3.0, 0)
	sparks.emitting = true
	flash.add_child(sparks)
	CombatFx.world().add_child(flash)
	flash.global_position = at
	flash.scale = Vector3(0.4, 1.0, 0.4)
	var tw := flash.create_tween()
	tw.set_parallel(true)
	tw.tween_property(flash, "scale", Vector3(2.8, 1.0, 2.8), 0.2)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.2)
	tw.tween_property(light, "light_energy", 0.0, 0.3)
	tw.chain().tween_callback(flash.queue_free).set_delay(0.3)
	Audio.sfx(&"surge_impact", at)


## The release sound (all machines).
func _play_release_cue() -> void:
	Audio.sfx(&"surge_release", global_position)


## The wave reached its end: fade out and free.
func _fade() -> void:
	_fading = FADE_TIME
	if _trail:
		_trail.emitting = false


## A wide crescent of light (bulging forward, bright core, deep blue edges that fade
## toward the ends, top and bottom), drifting motes behind it and a glow.
func _build_visual() -> void:
	var shader := Shader.new()
	shader.code = SHADER_CODE
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = shader
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for r in ROWS + 1:
		var v := float(r) / ROWS
		for c in COLUMNS + 1:
			var u := float(c) / COLUMNS * 2.0 - 1.0
			# The wave is a vertical sheet in the x-y plane, its middle pushed forward (-z).
			# The height tapers toward both ends so the silhouette is a blade, not a rectangle.
			var taper := pow(clampf(1.0 - pow(absf(u), 1.7), 0.0, 1.0), 0.8)
			verts.append(Vector3(u * width * 0.5, -0.35 + (v - 0.5) * VISUAL_HEIGHT * taper, -BULGE * (1.0 - u * u)))
			uvs.append(Vector2(float(c) / COLUMNS, v))
	for r in ROWS:
		for c in COLUMNS:
			var i := r * (COLUMNS + 1) + c
			indices.append_array([i, i + 1, i + COLUMNS + 1, i + 1, i + COLUMNS + 2, i + COLUMNS + 1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.custom_aabb = AABB(Vector3(-width, -1.5, -BULGE - 0.5), Vector3(width * 2.0, 3.0, BULGE + 1.0))
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _shader_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_visual = mi
	var light := OmniLight3D.new()
	light.light_color = Color(0.4, 0.65, 1.0)
	light.light_energy = 1.2
	light.omni_range = 4.0
	light.position = Vector3(0.0, -0.3, -0.6)
	add_child(light)
	# Motes shed behind the wave, left standing in the air.
	var quad := QuadMesh.new()
	quad.size = Vector2(0.09, 0.09)
	var pmat := StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	pmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	pmat.albedo_color = Color(0.5, 0.8, 1.0, 0.9)
	pmat.albedo_texture = CHARGE.soft_dot()
	quad.material = pmat
	_trail = CPUParticles3D.new()
	_trail.mesh = quad
	_trail.amount = 60
	_trail.lifetime = 0.5
	_trail.local_coords = false
	_trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_trail.emission_box_extents = Vector3(width * 0.45, 0.6, 0.15)
	_trail.direction = Vector3(0, 1, 0.5)
	_trail.spread = 40.0
	_trail.initial_velocity_min = 0.2
	_trail.initial_velocity_max = 0.9
	_trail.gravity = Vector3.ZERO
	_trail.position = Vector3(0.0, -0.5, 0.3)
	add_child(_trail)
	_place()  # apply the spread to the freshly built look
