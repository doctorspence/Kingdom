extends Node
## Combat effects for everyone to use: blood spurts and splatters, sparks,
## floating damage numbers and attack warning glints.
## Runs at start-up (autoload named "CombatFx").

## HURT: damage a player takes (red, so it never reads as damage you dealt).
## New kinds go at the end (WORD keeps its number).
enum NumberKind { NORMAL, CRIT, HEAL, WORD, HURT }

const MAX_DECALS := 60
## Blood splatters fade out after this long (seconds).
const DECAL_LIFETIME := 180.0

## Settings (toggled in-game for now; a settings menu comes later).
var show_damage_numbers := true
var show_enemy_health_bars := true
## Gore level: 0 = off, 1 = low, 2 = high.
var gore := 2

var _blood_texture: ImageTexture
var _decals: Array[Decal] = []
var _blood_mesh: SphereMesh
var _spark_mesh: SphereMesh


func _ready() -> void:
	_blood_texture = _make_splat_texture()
	_blood_mesh = SphereMesh.new()
	_blood_mesh.radius = 0.03
	_blood_mesh.height = 0.06
	_blood_mesh.radial_segments = 6
	_blood_mesh.rings = 3
	var blood_mat := StandardMaterial3D.new()
	blood_mat.albedo_color = Color(0.32, 0.01, 0.01)
	blood_mat.roughness = 0.3
	_blood_mesh.material = blood_mat
	_spark_mesh = SphereMesh.new()
	_spark_mesh.radius = 0.02
	_spark_mesh.height = 0.04
	_spark_mesh.radial_segments = 4
	_spark_mesh.rings = 2
	var spark_mat := StandardMaterial3D.new()
	spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat.albedo_color = Color(1.0, 0.8, 0.4)
	spark_mat.emission_enabled = true
	spark_mat.emission = Color(1.0, 0.7, 0.3)
	spark_mat.emission_energy_multiplier = 6.0
	_spark_mesh.material = spark_mat


# --- Numbers ------------------------------------------------------------------

func damage_number(where: Vector3, amount: float, kind := NumberKind.NORMAL) -> void:
	if not show_damage_numbers:
		return
	var text := str(roundi(amount))
	match kind:
		NumberKind.CRIT:
			_float_text(where, text, Color(1.0, 0.85, 0.2), 64)
		NumberKind.HEAL:
			_float_text(where, "+" + text, Color(0.4, 0.95, 0.4), 48)
		NumberKind.HURT:
			_float_text(where, "-" + text, Color(1.0, 0.35, 0.3), 44)
		_:
			_float_text(where, text, Color(0.95, 0.95, 0.92), 48)


## Gray words like "Blocked", "Deflect!", "Off balance!", "Steady".
func word(where: Vector3, text: String, color := Color(0.75, 0.75, 0.72)) -> void:
	if show_damage_numbers:
		_float_text(where, text, color, 44)


func _float_text(where: Vector3, text: String, color: Color, size: int) -> void:
	var label := Label3D.new()
	label.text = text
	label.modulate = color
	label.font_size = size
	label.outline_size = 10
	label.outline_modulate = Color(0, 0, 0, 0.85)
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 10
	_world().add_child(label)
	label.global_position = where + Vector3(randf_range(-0.25, 0.25), 0.0, randf_range(-0.25, 0.25))
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y + 0.9, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.6)
	tween.chain().tween_callback(label.queue_free)


# --- Blood --------------------------------------------------------------------

## A spurt of blood droplets at `where`, flying roughly along `direction`.
func blood(where: Vector3, direction: Vector3, amount := 1.0) -> void:
	Audio.sfx(&"hit_crit" if amount > 1.2 else &"hit_flesh", where)
	if gore == 0:
		return
	var count := int((18 if gore == 2 else 8) * amount)
	_burst(where, direction, count, _blood_mesh, 2.0, 4.5, 0.7, Vector3(0, -9.8, 0))
	# A splatter on the ground below.
	var space := _world().get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(where, where + Vector3.DOWN * 4.0, 1)
	var hit := space.intersect_ray(query)
	if hit:
		var spot: Vector3 = hit.position + Vector3(direction.x, 0, direction.z).normalized() * randf_range(0.2, 0.8)
		_splat(spot, randf_range(0.6, 1.2) * amount)


func _splat(where: Vector3, size: float) -> void:
	var decal := Decal.new()
	decal.texture_albedo = _blood_texture
	decal.size = Vector3(size, 1.0, size)
	decal.modulate = Color(1, 1, 1, 0.9)
	decal.cull_mask = 1
	_world().add_child(decal)
	decal.global_position = where
	decal.rotation.y = randf() * TAU
	_decals.append(decal)
	if _decals.size() > MAX_DECALS:
		var old: Decal = _decals.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	var tween := decal.create_tween()
	tween.tween_interval(DECAL_LIFETIME)
	tween.tween_property(decal, "modulate:a", 0.0, 10.0)
	tween.tween_callback(func() -> void:
		_decals.erase(decal)
		decal.queue_free())


# --- Sparks and glints --------------------------------------------------------

## Metal sparks for blocks and parries.
func sparks(where: Vector3, direction: Vector3, big := false, pitch := 1.0) -> void:
	Audio.sfx(&"clang_parry" if big else &"clang_block", where, 0.0, pitch)
	_burst(where, direction, 26 if big else 12, _spark_mesh, 3.0, 7.0, 0.35, Vector3(0, -6, 0))
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.75, 0.4)
	light.light_energy = 4.0 if big else 2.0
	light.omni_range = 4.0
	_world().add_child(light)
	light.global_position = where
	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.25)
	tween.tween_callback(light.queue_free)


## A brief star of light: white = parryable attack coming, red = unblockable.
func glint(where: Vector3, color: Color, parent: Node3D = null, strength := 1.0) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.09
	mesh.height = 0.18
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 12.0
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if parent:
		parent.add_child(mi)
	else:
		_world().add_child(mi)
		mi.global_position = where
	mi.scale = Vector3.ONE * 0.1
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 3.0 * strength
	light.omni_range = 3.0
	mi.add_child(light)
	var tween := mi.create_tween()
	tween.tween_property(mi, "scale", Vector3.ONE * 1.6 * strength, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mi, "scale", Vector3.ONE * 0.01, 0.3)
	tween.tween_callback(mi.queue_free)


# --- Helpers ------------------------------------------------------------------

func _burst(where: Vector3, direction: Vector3, count: int, mesh: Mesh, v_min: float, v_max: float,
		lifetime: float, gravity: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.one_shot = true
	p.amount = maxi(count, 1)
	p.lifetime = lifetime
	p.explosiveness = 0.95
	p.draw_pass_1 = mesh
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	var dir := direction.normalized() if direction.length() > 0.01 else Vector3.UP
	pm.direction = (dir + Vector3.UP * 0.4).normalized()
	pm.spread = 35.0
	pm.initial_velocity_min = v_min
	pm.initial_velocity_max = v_max
	pm.gravity = gravity
	pm.scale_min = 0.6
	pm.scale_max = 1.6
	p.process_material = pm
	_world().add_child(p)
	p.global_position = where
	p.emitting = true
	get_tree().create_timer(lifetime + 0.5).timeout.connect(p.queue_free)


## Short flashy visuals for abilities (everyone sees these):
##   bellow (shockwave ring), flare (blinding flash), ember_burst, beacon_column
func burst_visual(kind: StringName, where: Vector3, radius: float, duration: float) -> void:
	var color := Color(1.0, 0.85, 0.6)
	var mi := MeshInstance3D.new()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var start_scale := Vector3.ONE * 0.2
	var end_scale := Vector3.ONE
	match kind:
		&"bellow":
			var torus := TorusMesh.new()
			torus.inner_radius = radius * 0.92
			torus.outer_radius = radius
			mi.mesh = torus
			color = Color(0.85, 0.82, 0.75)
			where += Vector3.UP * 0.8
		&"beacon_column":
			var cyl := CylinderMesh.new()
			cyl.top_radius = radius
			cyl.bottom_radius = radius
			cyl.height = 14.0
			mi.mesh = cyl
			color = Color(1.0, 0.95, 0.75)
			where += Vector3.UP * 7.0
			start_scale = Vector3(1, 1, 1)
		_:
			var sphere := SphereMesh.new()
			sphere.radius = radius if kind == &"ember_burst" else 1.2
			sphere.height = sphere.radius * 2.0
			mi.mesh = sphere
			color = Color(1.0, 0.65, 0.3) if kind == &"ember_burst" else Color(1.0, 1.0, 0.95)
	mat.albedo_color = Color(color.r, color.g, color.b, 0.5)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 4.0
	mi.material_override = mat
	world().add_child(mi)
	mi.global_position = where
	mi.scale = start_scale
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 8.0 if kind == &"flare" else 3.0
	light.omni_range = radius + 4.0
	mi.add_child(light)
	var tween := mi.create_tween()
	tween.set_parallel(true)
	tween.tween_property(mi, "scale", end_scale, duration * 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, duration).set_delay(duration * 0.2)
	tween.tween_property(light, "light_energy", 0.0, duration)
	tween.chain().tween_callback(mi.queue_free)


func world() -> Node3D:
	return _world()


func _world() -> Node3D:
	var scene := get_tree().current_scene
	return scene as Node3D if scene is Node3D else get_tree().root.get_child(get_tree().root.get_child_count() - 1) as Node3D


## Draw a blood splat picture once, at start-up (no image file needed).
func _make_splat_texture() -> ImageTexture:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.06
	var center := Vector2(size, size) * 0.5
	var droplets: Array[Vector3] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 10:
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.3, 0.46) * size
		droplets.append(Vector3(center.x + cos(a) * d, center.y + sin(a) * d, rng.randf_range(2.0, 5.0)))
	for y in size:
		for x in size:
			var p := Vector2(x, y)
			var r := p.distance_to(center) / (size * 0.5)
			var edge := 0.55 + noise.get_noise_2d(x, y) * 0.35
			var alpha := clampf((edge - r) * 6.0, 0.0, 1.0)
			for dr in droplets:
				if p.distance_to(Vector2(dr.x, dr.y)) < dr.z:
					alpha = 1.0
			var shade := 0.22 + noise.get_noise_2d(x * 3.0, y * 3.0) * 0.06
			img.set_pixel(x, y, Color(shade, 0.01, 0.01, alpha * 0.92))
	return ImageTexture.create_from_image(img)
