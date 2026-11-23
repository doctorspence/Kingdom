class_name DayNight
extends Node
## The zone's clock and weather (DESIGN.md 11.4): a day lasts about 48 real
## minutes (32 of day, 16 of night). Nights are cold, blue and very dark, and
## enemies see only half as far. Rain comes and goes.
##
## The host runs the clock and the weather and tells everyone else; joiners
## keep their own clock ticking between updates.

## How dark it is right now, 0 (day) to 1 (deep night). Read by players (lantern) and enemies.
static var night := 0.0
static var raining := false
## 0 on the surface, 1 deep underground (the Gullet): no sun, no rain, a dark warm gloom.
static var cave := 0.0
## Below this height the camera counts as underground.
const CAVE_BELOW := -15.0

@export var environment: WorldEnvironment
@export var sun: DirectionalLight3D
@export var day_minutes := 32.0
@export var night_minutes := 16.0
## Where the day starts when a new world begins (0 = dawn, 0.5 ≈ mid-afternoon).
@export_range(0.0, 1.0) var start_time := 0.15
## Rain: how often the weather may change (minutes, random in this range) and the chance of rain.
@export var weather_minutes := Vector2(4.0, 9.0)
@export_range(0.0, 1.0) var rain_chance := 0.35

## 0..1 through a full day; daylight is the first day_minutes of it.
var time := 0.0
## How heavy the rain is right now (fades in and out).
var rain_amount := 0.0

var _env: Environment
var _sky: ProceduralSkyMaterial
var _day := {}
var _sync_timer := 0.0
var _weather_timer := 0.0
var _rain: GPUParticles3D
var _stars: MeshInstance3D
var _star_mat: ShaderMaterial
var _glow: Material
## How soaked the ground is: rises quickly in rain, dries slowly after.
var wet_ground := 0.0
## 0 in the open .. 1 deep in the woods (eased as the camera moves).
var canopy := 0.0
var mood := Vector3.ZERO  ## (deep woods, quarry, chapel and barrow), eased as the camera moves
var _mood_target := Vector3.ZERO
var _canopy_timer := 0.0
var _land: Object
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group(&"day_night")
	_rng.randomize()
	time = start_time
	if environment:
		# Our own copy, so the shared look file isn't changed.
		_env = environment.environment.duplicate(true)
		environment.environment = _env
		_sky = _env.sky.sky_material as ProceduralSkyMaterial if _env.sky else null
		_env.adjustment_color_correction = palette_grade()
		_day = {
			"ambient": _env.ambient_light_energy,
			"exposure": _env.tonemap_exposure,
			"fog_color": _env.fog_light_color,
			"fog_energy": _env.fog_light_energy,
			"fog_density": _env.fog_density,
			"vol_albedo": _env.volumetric_fog_albedo,
			"vol_density": _env.volumetric_fog_density,
			"sky_top": _sky.sky_top_color if _sky else Color.BLACK,
			"sky_horizon": _sky.sky_horizon_color if _sky else Color.BLACK,
			"sun_energy": sun.light_energy if sun else 1.0,
			"sun_color": sun.light_color if sun else Color.WHITE,
		}
	_build_rain()
	_build_stars()
	_weather_timer = _rng.randf_range(weather_minutes.x, weather_minutes.y) * 60.0
	multiplayer.peer_connected.connect(_on_peer_connected)
	var zone_audio := ZoneAudio.new()  # the zone's ambience and music
	zone_audio.name = "ZoneAudio"
	zone_audio.day_night = self
	add_child(zone_audio)
	_apply()


func _exit_tree() -> void:
	night = 0.0
	raining = false
	Enemy.sight_mult = 1.0


func day_length() -> float:
	return (day_minutes + night_minutes) * 60.0


## Daylight lasts this share of the full day.
func day_share() -> float:
	return day_minutes / (day_minutes + night_minutes)


func is_night() -> bool:
	return time >= day_share()


## Hours on a 24-hour clock, for the debug screen (dawn = 6:00, dusk = 20:00).
func clock_text() -> String:
	var hours: float
	if time < day_share():
		hours = 6.0 + time / day_share() * 14.0
	else:
		hours = fmod(20.0 + (time - day_share()) / (1.0 - day_share()) * 10.0, 24.0)
	return "%02d:%02d" % [int(hours), int(fmod(hours, 1.0) * 60.0)]


func _process(delta: float) -> void:
	time = fmod(time + delta / day_length(), 1.0)
	var target_rain := 1.0 if raining else 0.0
	rain_amount = move_toward(rain_amount, target_rain, delta / 20.0)
	if multiplayer.is_server():
		_weather_timer -= delta
		if _weather_timer <= 0.0:
			_weather_timer = _rng.randf_range(weather_minutes.x, weather_minutes.y) * 60.0
			set_rain(_rng.randf() < rain_chance)
		_sync_timer -= delta
		if _sync_timer <= 0.0 and multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0:
			_sync_timer = 10.0
			_net_sync.rpc(time, raining)
	var cam := get_viewport().get_camera_3d()
	# Underground = deep below the ground (the Gullet) or inside the quarry descent, where the light fades in with every stride.
	var cave_target := 0.0
	if cam:
		cave_target = 1.0 if cam.global_position.y < CAVE_BELOW else QuarryDescent.depth_cave(cam.global_position)
	cave = move_toward(cave, cave_target, delta * 1.0)
	# Under the trees: how thick the woods are where the camera is (land script woodland map).
	_canopy_timer -= delta
	if _canopy_timer <= 0.0 and cam:
		_canopy_timer = 0.25
		_mood_target = _mood_at(cam.global_position)
	mood = mood.move_toward(_mood_target, delta * 0.6)
	canopy = mood.x
	_apply()


## Host: start or stop the rain.
func set_rain(on: bool) -> void:
	raining = on
	if multiplayer.is_server() and multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0:
		_net_sync.rpc(time, raining)


## Host (or tests): jump the clock.
func set_time(t: float) -> void:
	time = fposmod(t, 1.0)
	if multiplayer.is_server() and multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0:
		_net_sync.rpc(time, raining)
	_apply()


func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		_net_sync.rpc_id(id, time, raining)


@rpc("authority", "call_remote", "unreliable_ordered")
func _net_sync(t: float, rain: bool) -> void:
	time = t
	raining = rain


## How far into night (0..1), easing through dusk and dawn.
func _night_amount() -> float:
	var ds := day_share()
	var fade := 0.05  # dusk / dawn length, as a share of the day
	if time < ds:
		# Day: dawn fades in at the start, dusk fades out at the end.
		return maxf(1.0 - smoothstep(0.0, fade, time), smoothstep(ds - fade, ds, time))
	return 1.0


func _apply() -> void:
	night = _night_amount()
	Enemy.sight_mult = lerpf(1.0, 0.5, night)
	var wet := rain_amount
	# Golden hour: the low sun at dawn and dusk warms the light, sky and haze.
	var ds := day_share()
	var gold := 0.0
	if time < ds:
		var arc_d := time / ds
		gold = (1.0 - smoothstep(0.02, 0.24, minf(arc_d, 1.0 - arc_d))) * (1.0 - night) * (1.0 - 0.7 * wet)
	wet_ground = move_toward(wet_ground, 1.0 if raining else 0.0, get_process_delta_time() / (25.0 if raining else 150.0))
	RenderingServer.global_shader_parameter_set(&"wetness", wet_ground * (1.0 - cave))
	if _glow == null and ResourceLoader.exists("res://assets/buildings/materials/glow.tres"):
		_glow = load("res://assets/buildings/materials/glow.tres")
	if _glow:
		# Lit windows: the only warm light in the dark, a little in heavy rain too.
		(_glow as StandardMaterial3D).emission_energy_multiplier = maxf(smoothstep(0.2, 0.9, night), 0.3 * wet + 0.5 * gold) * 2.4 * (1.0 - cave)
	if sun:
		# The sun crosses the sky during the day; at night a dim blue moon stands in.
		var arc := clampf(time / ds, 0.0, 1.0) if time < ds else (time - ds) / (1.0 - ds)
		sun.rotation_degrees = Vector3(-lerpf(15.0, 165.0, arc), 35.0, 0.0)
		sun.light_energy = lerpf(_day.get("sun_energy", 0.9), 0.6, night) * lerpf(1.0, 0.6, wet)
		sun.light_color = (_day.get("sun_color", Color.WHITE) as Color).lerp(Color(1.0, 0.6, 0.32), gold * 0.8).lerp(Color(0.5, 0.6, 0.9), night)
		sun.shadow_enabled = night < 0.95
	if _env:
		_env.ambient_light_energy = lerpf(_day.ambient, 0.95, night) * lerpf(1.0, 0.8, wet)
		# At night the light comes from a cold moonlit color, not the black sky.
		_env.ambient_light_color = Color(0.32, 0.38, 0.55)
		_env.ambient_light_sky_contribution = lerpf(1.0, 0.0, night)
		_env.fog_light_color = (_day.fog_color as Color).lerp(Color(0.82, 0.55, 0.42), gold * 0.42).lerp(Color(0.16, 0.19, 0.27), night).darkened(0.2 * wet)
		_env.fog_light_energy = lerpf(_day.fog_energy, 0.9, night)
		_env.fog_density = _day.fog_density * lerpf(1.0, 1.8, wet) * lerpf(1.0, 1.3, night)
		_env.volumetric_fog_albedo = (_day.vol_albedo as Color).lerp(Color(0.2, 0.23, 0.3), night)
		_env.volumetric_fog_density = _day.vol_density * lerpf(1.0, 1.6, wet)
		# Deep woodland: the light under the canopy is a lifted green, never black
		# (brief: shadows lean to #354536), with a little more haze for light shafts.
		var cw := canopy * (1.0 - night)
		# Eyes adjust under the trees: exposure rises gently with the canopy (readable, still dim).
		_env.tonemap_exposure = float(_day.exposure) * (1.0 + 0.45 * cw)
		if cw > 0.0:
			_env.ambient_light_color = _env.ambient_light_color.lerp(Color(0.45, 0.53, 0.42), cw)
			_env.ambient_light_sky_contribution = lerpf(_env.ambient_light_sky_contribution, 0.35, cw)
			_env.ambient_light_energy *= 1.0 + 0.85 * cw
			_env.volumetric_fog_density *= 1.0 + 0.5 * cw
			_env.volumetric_fog_albedo = _env.volumetric_fog_albedo.lerp(Color(0.62, 0.7, 0.6), 0.5 * cw)
		# The quarry: pale stone throws light back, dust hangs in the air.
		var qw := mood.y * (1.0 - night)
		if qw > 0.0:
			_env.ambient_light_color = _env.ambient_light_color.lerp(Color(0.66, 0.65, 0.6), 0.45 * qw)
			_env.ambient_light_energy *= 1.0 + 0.2 * qw
			_env.volumetric_fog_albedo = _env.volumetric_fog_albedo.lerp(Color(0.8, 0.77, 0.7), 0.6 * qw)
			_env.volumetric_fog_density *= 1.0 + 0.4 * qw
		# The chapel and the barrow: colder, quieter light and a mist close to the ground.
		var ow := mood.z
		if ow > 0.0:
			_env.ambient_light_color = _env.ambient_light_color.lerp(Color(0.42, 0.47, 0.56), 0.5 * ow)
			_env.ambient_light_energy *= 1.0 - 0.12 * ow
			_env.fog_light_color = _env.fog_light_color.lerp(Color(0.5, 0.56, 0.62), 0.4 * ow)
			_env.volumetric_fog_density *= 1.0 + 0.7 * ow
		if _sky:
			_sky.sky_top_color = (_day.sky_top as Color).lerp(Color(0.4, 0.42, 0.58), gold * 0.5).lerp(Color(0.05, 0.06, 0.1), night).darkened(0.25 * wet)
			_sky.sky_horizon_color = (_day.sky_horizon as Color).lerp(Color(0.95, 0.58, 0.38), gold * 0.8).lerp(Color(0.13, 0.15, 0.21), night).darkened(0.25 * wet)
			_sky.ground_horizon_color = _sky.sky_horizon_color
	if cave > 0.0:
		if sun:
			sun.light_energy *= 1.0 - cave
			sun.shadow_enabled = sun.shadow_enabled and cave < 0.5
		if _env:
			_env.ambient_light_energy = lerpf(_env.ambient_light_energy, 0.85, cave)
			_env.ambient_light_color = _env.ambient_light_color.lerp(Color(0.42, 0.32, 0.24), cave)
			_env.ambient_light_sky_contribution = lerpf(_env.ambient_light_sky_contribution, 0.0, cave)
			_env.fog_light_color = _env.fog_light_color.lerp(Color(0.08, 0.07, 0.06), cave)
			_env.fog_light_energy = lerpf(_env.fog_light_energy, 0.3, cave)
			_env.volumetric_fog_albedo = _env.volumetric_fog_albedo.lerp(Color(0.25, 0.2, 0.15), cave)
	if _stars:
		var cam_s := get_viewport().get_camera_3d()
		if cam_s:
			_stars.global_position = cam_s.global_position
		var vis := smoothstep(0.35, 0.95, night) * (1.0 - cave) * (1.0 - wet)
		_stars.visible = vis > 0.01
		_star_mat.set_shader_parameter("amount", vis)
		if sun:
			_star_mat.set_shader_parameter("moon_dir", sun.global_transform.basis.z)
	if _rain:
		_rain.amount_ratio = wet * (1.0 - cave)
		_rain.emitting = wet * (1.0 - cave) > 0.01
		var cam := get_viewport().get_camera_3d()
		if cam:
			_rain.global_position = cam.global_position + Vector3.UP * 8.0



## A dome of stars and a moon that follow the camera, faded in with the night.
func _build_stars() -> void:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, fog_disabled, blend_add;
uniform float amount = 0.0;
uniform vec3 moon_dir = vec3(0.0, 1.0, 0.0);
varying vec3 dir;
float hash(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
void vertex() { dir = VERTEX; }
void fragment() {
	vec3 d = normalize(dir);
	vec3 p = d * 110.0;
	vec3 g = floor(p);
	vec3 f = fract(p) - 0.5;
	float r = hash(g);
	float star = step(0.985, r) * smoothstep(0.22, 0.0, length(f)) * (0.55 + 0.45 * sin(TIME * (1.0 + r * 3.0) + r * 40.0));
	star *= 0.6 + 1.6 * hash(g + 7.0);
	float horizon = smoothstep(0.04, 0.4, d.y);
	float md = dot(d, normalize(moon_dir));
	float moon = smoothstep(0.9990, 0.9995, md) + 0.25 * smoothstep(0.985, 0.9995, md);
	vec3 col = vec3(0.75, 0.82, 1.0) * star * horizon + vec3(0.85, 0.9, 1.0) * moon * 1.4;
	ALBEDO = col * amount;
	ALPHA = 1.0;
}
"""
	_star_mat = ShaderMaterial.new()
	_star_mat.shader = sh
	var sphere := SphereMesh.new()
	sphere.radius = 480.0  # inside the camera far plane (600)
	sphere.height = 960.0
	sphere.radial_segments = 48
	sphere.rings = 24
	sphere.material = _star_mat
	_stars = MeshInstance3D.new()
	_stars.name = "Stars"
	_stars.mesh = sphere
	_stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_stars.extra_cull_margin = 16384.0
	add_child(_stars)


## Streaks of rain falling around the camera.
func _build_rain() -> void:
	_rain = GPUParticles3D.new()
	_rain.name = "Rain"
	_rain.amount = 6000
	_rain.lifetime = 1.2
	_rain.emitting = false
	_rain.visibility_aabb = AABB(Vector3(-25, -20, -25), Vector3(50, 30, 50))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(24, 1, 24)
	pm.direction = Vector3(0.1, -1, 0.05)
	pm.spread = 3.0
	pm.initial_velocity_min = 16.0
	pm.initial_velocity_max = 20.0
	pm.gravity = Vector3(0, -9.8, 0)
	_rain.process_material = pm
	var streak := QuadMesh.new()
	streak.size = Vector2(0.01, 0.55)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.72, 0.77, 0.85, 0.22)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.billboard_keep_scale = true
	streak.material = mat
	_rain.draw_pass_1 = streak
	add_child(_rain)


func to_dict() -> Dictionary:
	return {"time": time, "raining": raining}


func load_dict(d: Dictionary) -> void:
	time = fposmod(float(d.get("time", start_time)), 1.0)
	raining = bool(d.get("raining", false))
	rain_amount = 1.0 if raining else 0.0
	_apply()


func _mood_at(p: Vector3) -> Vector3:
	if _land == null:
		var t := get_tree().get_first_node_in_group(&"zone_terrain")
		if t == null or t.get("land") == null:
			return Vector3.ZERO
		_land = t.get("land")
	if not _land.has_method("mood"):
		return Vector3.ZERO
	# Average a few points around the camera, so one gap in the trees doesn't flicker.
	var s := Vector3.ZERO
	for o: Vector2 in [Vector2.ZERO, Vector2(8, 0), Vector2(-8, 0), Vector2(0, 8), Vector2(0, -8)]:
		s += _land.call("mood", p.x + o.x, p.z + o.y)
	return s / 5.0


static var _grade: ImageTexture3D

## The Greenwood colour grade (brief section 9), as a 17x17x17 lookup table:
## shadows never go pure black but lean to deep woodland green (#354536),
## yellow-greens are calmed (no neon foliage), the few strong colours (flowers,
## berries, banners, fire) keep their saturation, highlights warm a touch.
static func palette_grade() -> ImageTexture3D:
	if _grade:
		return _grade
	var n := 17
	var layers: Array[Image] = []
	for b in n:
		var img := Image.create(n, n, false, Image.FORMAT_RGB8)
		for g in n:
			for r in n:
				var c := Color(r / float(n - 1), g / float(n - 1), b / float(n - 1))
				var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
				# Lift the deepest shadows toward a dark woodland green instead of black.
				var lift := pow(1.0 - lum, 4.0)
				c = Color(c.r + 0.018 * lift, c.g + 0.03 * lift, c.b + 0.022 * lift)
				# Calm the yellow-greens; keep reds, purples and blues where they are.
				var h := c.h
				var s := c.s
				if h > 0.12 and h < 0.32:
					var k := smoothstep(0.12, 0.17, h) * (1.0 - smoothstep(0.27, 0.32, h))
					s *= 1.0 - 0.18 * k
					h += 0.012 * k
				elif h > 0.7 or h < 0.06:
					s = minf(s * 1.08, 1.0)
				c = Color.from_hsv(h, s, c.v)
				# Warm, soft highlights.
				var hi := smoothstep(0.62, 1.0, lum)
				c = Color(c.r + 0.012 * hi, c.g + 0.004 * hi, c.b - 0.01 * hi)
				img.set_pixel(r, g, Color(clampf(c.r, 0.0, 1.0), clampf(c.g, 0.0, 1.0), clampf(c.b, 0.0, 1.0)))
		layers.append(img)
	_grade = ImageTexture3D.new()
	_grade.create(Image.FORMAT_RGB8, n, n, n, false, layers)
	return _grade
