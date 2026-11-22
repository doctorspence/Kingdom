extends Node3D
## Local mist: soft ellipsoid fog volumes from the land script's `mist_spots`
## ([x, z, radius, height, density]) lying low in the hollows, along the brook,
## at the barrow and the churchyard, over the river by the mill pond, and pale
## dust in the quarry. Thicker at night and in rain (from DayNight), thinner by
## day. Uses the environment's volumetric fog, so it costs little; no global
## height fog (that would bury the Gullet's rooms).

@export var terrain: SculptedTerrain

var _volumes: Array = []  # [FogMaterial, base density]
var _day_night: Node
var _timer := 0.0


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
		var x: float = s[0]
		var z: float = s[1]
		var r: float = s[2]
		var h: float = s[3]
		var fv := FogVolume.new()
		fv.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
		fv.size = Vector3(r * 2.0, h * 2.0, r * 2.0)
		fv.position = Vector3(x, terrain.height_at(x, z) + h * 0.15, z) - global_position
		var fm := FogMaterial.new()
		fm.density = float(s[4])
		fm.albedo = Color(0.82, 0.84, 0.8) if x > -140.0 or z > -80.0 else Color(0.85, 0.82, 0.74)
		fm.edge_fade = 0.6
		fm.height_falloff = 0.4  # thickest near the ground
		fv.material = fm
		add_child(fv)
		_volumes.append([fm, float(s[4])])


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0 or _volumes.is_empty():
		return
	_timer = 1.0
	if _day_night == null:
		_day_night = get_tree().get_first_node_in_group(&"day_night")
	var night: float = _day_night.get("night") if _day_night else 0.0
	var rain: float = _day_night.get("rain_amount") if _day_night else 0.0
	var k := lerpf(0.75, 1.5, night) * lerpf(1.0, 1.4, rain)
	for v: Array in _volumes:
		(v[0] as FogMaterial).density = float(v[1]) * k
