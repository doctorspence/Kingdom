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
		_day = {
			"ambient": _env.ambient_light_energy,
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
	cave = move_toward(cave, 1.0 if cam and cam.global_position.y < CAVE_BELOW else 0.0, delta * 1.5)
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
	if sun:
		# The sun crosses the sky during the day; at night a dim blue moon stands in.
		var ds := day_share()
		var arc := clampf(time / ds, 0.0, 1.0) if time < ds else (time - ds) / (1.0 - ds)
		sun.rotation_degrees = Vector3(-lerpf(15.0, 165.0, arc), 35.0, 0.0)
		sun.light_energy = lerpf(_day.get("sun_energy", 0.9), 0.3, night) * lerpf(1.0, 0.6, wet)
		sun.light_color = (_day.get("sun_color", Color.WHITE) as Color).lerp(Color(0.5, 0.6, 0.9), night)
		sun.shadow_enabled = night < 0.95
	if _env:
		_env.ambient_light_energy = lerpf(_day.ambient, 0.35, night) * lerpf(1.0, 0.8, wet)
		# At night the light comes from a cold moonlit color, not the black sky.
		_env.ambient_light_color = Color(0.32, 0.38, 0.55)
		_env.ambient_light_sky_contribution = lerpf(1.0, 0.0, night)
		_env.fog_light_color = (_day.fog_color as Color).lerp(Color(0.16, 0.19, 0.27), night).darkened(0.2 * wet)
		_env.fog_light_energy = lerpf(_day.fog_energy, 0.7, night)
		_env.fog_density = _day.fog_density * lerpf(1.0, 1.8, wet) * lerpf(1.0, 1.3, night)
		_env.volumetric_fog_albedo = (_day.vol_albedo as Color).lerp(Color(0.2, 0.23, 0.3), night)
		_env.volumetric_fog_density = _day.vol_density * lerpf(1.0, 1.6, wet)
		if _sky:
			_sky.sky_top_color = (_day.sky_top as Color).lerp(Color(0.05, 0.06, 0.1), night).darkened(0.25 * wet)
			_sky.sky_horizon_color = (_day.sky_horizon as Color).lerp(Color(0.13, 0.15, 0.21), night).darkened(0.25 * wet)
			_sky.ground_horizon_color = _sky.sky_horizon_color
	if cave > 0.0:
		if sun:
			sun.light_energy *= 1.0 - cave
			sun.shadow_enabled = sun.shadow_enabled and cave < 0.5
		if _env:
			_env.ambient_light_energy = lerpf(_env.ambient_light_energy, 0.5, cave)
			_env.ambient_light_color = _env.ambient_light_color.lerp(Color(0.42, 0.32, 0.24), cave)
			_env.ambient_light_sky_contribution = lerpf(_env.ambient_light_sky_contribution, 0.0, cave)
			_env.fog_light_color = _env.fog_light_color.lerp(Color(0.08, 0.07, 0.06), cave)
			_env.fog_light_energy = lerpf(_env.fog_light_energy, 0.3, cave)
			_env.volumetric_fog_albedo = _env.volumetric_fog_albedo.lerp(Color(0.25, 0.2, 0.15), cave)
	if _rain:
		_rain.amount_ratio = wet * (1.0 - cave)
		_rain.emitting = wet * (1.0 - cave) > 0.01
		var cam := get_viewport().get_camera_3d()
		if cam:
			_rain.global_position = cam.global_position + Vector3.UP * 8.0


## Streaks of rain falling around the camera.
func _build_rain() -> void:
	_rain = GPUParticles3D.new()
	_rain.name = "Rain"
	_rain.amount = 3000
	_rain.lifetime = 1.2
	_rain.emitting = false
	_rain.visibility_aabb = AABB(Vector3(-25, -20, -25), Vector3(50, 30, 50))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(22, 1, 22)
	pm.direction = Vector3(0.1, -1, 0.05)
	pm.spread = 3.0
	pm.initial_velocity_min = 16.0
	pm.initial_velocity_max = 20.0
	pm.gravity = Vector3(0, -9.8, 0)
	_rain.process_material = pm
	var streak := QuadMesh.new()
	streak.size = Vector2(0.015, 0.5)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.7, 0.75, 0.82, 0.35)
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
