extends Node3D
## Local mist: soft ellipsoid fog volumes from the land script's `mist_spots`
## ([x, z, radius, height, density]) lying low in the hollows, along the brook,
## at the barrow and the churchyard, over the river by the mill pond, and pale
## dust in the quarry. Thicker at night and in rain (from DayNight), thinner by
## day. Uses the environment's volumetric fog, so it costs little. (The global
## height fog is set in tithelands_env.tres and faded underground by DayNight.)
##
## The banks drift: each creeps around its own spot and slowly thickens and
## thins, so shapes come and go in it. The motion follows DayNight's clock, so
## everyone in a shared world sees the same mist.

## How far a bank wanders from its spot (share of its radius, at most DRIFT_MAX metres).
const DRIFT := 0.4
const DRIFT_MAX := 9.0
## Sideways wander, as a share of the drift along the wind.
const SWAY := 0.4
const WIND := Vector2(0.8, 0.6)
## Seconds, roughly, for a bank to drift out and back, and to thicken and thin.
const DRIFT_SECONDS := 80.0
const SWELL_SECONDS := 45.0
## How much thicker and thinner a bank gets (share of its density).
const SWELL := 0.35
## At night the banks turn a dark blue-teal, so the moonlit fog reads as mist in the dark, not milk.
const NIGHT_ALBEDO := Color(0.3, 0.4, 0.48)

@export var terrain: SculptedTerrain

var _banks: Array[Dictionary] = []
var _day_night: DayNight


func _ready() -> void:
	_build.call_deferred()


func _build() -> void:
	if terrain == null:
		return
	terrain.height_at(0, 0)
	var land: Object = terrain.land
	if land == null or land.get("mist_spots") == null:
		return
	for s: Array in land.get("mist_spots"):
		var r: float = s[2]
		var h: float = s[3]
		var fv := FogVolume.new()
		fv.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
		fv.size = Vector3(r * 2.0, h * 2.0, r * 2.0)
		var fm := FogMaterial.new()
		fm.albedo = Color(0.82, 0.84, 0.8) if s[0] > -140.0 or s[1] > -80.0 else Color(0.85, 0.82, 0.74)
		fm.edge_fade = 0.6
		fm.height_falloff = 0.4  # thickest near the ground
		fv.material = fm
		add_child(fv)
		var i := _banks.size()
		_banks.append({
			"volume": fv,
			"material": fm,
			"home": Vector2(s[0], s[1]),
			"lift": h * 0.15,
			"reach": minf(r * DRIFT, DRIFT_MAX),
			"density": float(s[4]),
			"albedo": fm.albedo,
			# Banks start at different points and move at slightly different speeds.
			"drift_phase": fposmod(i * 2.399, TAU),
			"swell_phase": fposmod(i * 4.113, TAU),
			"pace": (i % 3 - 1) * 0.2,
		})
	_move_banks()


func _process(_delta: float) -> void:
	if not _banks.is_empty():
		_move_banks()


func _move_banks() -> void:
	if _day_night == null:
		_day_night = get_tree().get_first_node_in_group(&"day_night") as DayNight
	# Where we are in the day (0..1) and how long a day is, in seconds.
	var day := _day_night.time if _day_night else 0.0
	var day_seconds := _day_night.day_length() if _day_night else 2880.0
	var night: float = DayNight.night
	var rain := _day_night.rain_amount if _day_night else 0.0
	var thickness := lerpf(1.1, 1.25, night) * lerpf(1.0, 1.4, rain)
	for bank in _banks:
		var pace: float = 1.0 + bank.pace
		# Whole numbers of cycles per day, so nothing jumps when the day starts over.
		var drift: float = TAU * day * roundf(day_seconds / DRIFT_SECONDS * pace) + bank.drift_phase
		var swell: float = TAU * day * roundf(day_seconds / SWELL_SECONDS * pace) + bank.swell_phase
		var offset: Vector2 = (WIND * sin(drift) + WIND.orthogonal() * sin(drift * 2.0 + bank.swell_phase) * SWAY) * bank.reach
		var at: Vector2 = bank.home + offset
		var volume: FogVolume = bank.volume
		volume.position = Vector3(at.x, terrain.height_at(at.x, at.y) + bank.lift, at.y) - global_position
		(bank.material as FogMaterial).density = bank.density * thickness * (1.0 + SWELL * sin(swell))
		(bank.material as FogMaterial).albedo = (bank.albedo as Color).lerp(NIGHT_ALBEDO, night)
