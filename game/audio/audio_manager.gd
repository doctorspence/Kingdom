extends Node
## Autoload "Audio": the volume groups (buses) and their saved settings.
##
## Master
##  ├─ Music      zone and boss music
##  ├─ Effects    combat, footsteps, abilities, enemies
##  ├─ Ambience   wind, rain, cave air, birds
##  └─ Interface  menus, loot and shrine sounds
##
## Volumes are 0..1 sliders (0 = silent), saved in settings.cfg under [audio].
## Other scripts pick a group by name when they play a sound.

const GROUPS: Array[StringName] = [&"Master", &"Music", &"Effects", &"Ambience", &"Interface"]
const DEFAULTS := {&"Master": 0.8, &"Music": 0.6, &"Effects": 0.9, &"Ambience": 0.7, &"Interface": 0.8}

signal volume_changed(group: StringName, value: float)

var volumes := DEFAULTS.duplicate()


func _init() -> void:
	# The buses must exist before anything plays, so make them straight away.
	for g in GROUPS:
		if g != &"Master" and AudioServer.get_bus_index(g) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, g)
			AudioServer.set_bus_send(i, &"Master")


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(Net.SETTINGS_PATH) == OK:
		for g in GROUPS:
			volumes[g] = clampf(float(cfg.get_value("audio", String(g), DEFAULTS[g])), 0.0, 1.0)
	for g in GROUPS:
		_apply(g)
	# Every button in every menu clicks.
	get_tree().node_added.connect(func(n: Node) -> void:
		if n is BaseButton:
			(n as BaseButton).pressed.connect(func() -> void: sfx(&"ui_click")))


# --- Playing sound effects ---------------------------------------------------------

## Same cue again within this many seconds is skipped (stops a pile-up of one sound).
const MIN_REPEAT := 0.045
## Most one-shot sounds playing at once.
const MAX_VOICES := 28
## Sounds farther than this from the listener are not played.
const HEARING_RANGE := 45.0

var _cache := {}
var _last_played := {}
var _last_file := {}
var _voices := 0
## Counts what was played (the automated checks read this).
var played_count := 0


## Play a sound cue (see SfxLibrary). With `where` it comes from that spot in the
## world and gets quieter with distance; without it, it plays flat (menus).
## `db` adjusts the volume for this one play. Returns true if it played.
func sfx(cue: StringName, where := Vector3.INF, db := 0.0) -> bool:
	var data := SfxLibrary.cue(cue)
	if data.is_empty():
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(cue, -9.0)) < MIN_REPEAT or _voices >= MAX_VOICES:
		return false
	var files: Array = data["files"]
	if files.is_empty():
		return false
	var path: String = files[randi() % files.size()]
	if files.size() > 1 and path == _last_file.get(cue, ""):
		path = files[randi() % files.size()]
	var stream := _load(path)
	if stream == null:
		return false
	var pitch: Vector2 = data["pitch"]
	var volume: float = float(data["db"]) + db
	var scene := get_tree().current_scene
	var player: Node
	if where != Vector3.INF and scene is Node3D:
		var cam := get_viewport().get_camera_3d()
		if cam and cam.global_position.distance_to(where) > HEARING_RANGE:
			return false
		var p3 := AudioStreamPlayer3D.new()
		p3.stream = stream
		p3.bus = data["bus"]
		p3.volume_db = volume
		p3.pitch_scale = randf_range(pitch.x, pitch.y)
		p3.max_distance = HEARING_RANGE
		p3.unit_size = 7.0
		scene.add_child(p3)
		p3.global_position = where
		player = p3
	else:
		var p2 := AudioStreamPlayer.new()
		p2.stream = stream
		p2.bus = data["bus"]
		p2.volume_db = volume
		p2.pitch_scale = randf_range(pitch.x, pitch.y)
		add_child(p2)
		player = p2
	_last_played[cue] = now
	_last_file[cue] = path
	_voices += 1
	played_count += 1
	var released := [false]
	var release := func() -> void:
		if not released[0]:
			released[0] = true
			_voices -= 1
	player.finished.connect(func() -> void:
		release.call()
		player.queue_free())
	player.tree_exited.connect(release)  # the scene changed under it
	player.call(&"play")
	for layer in data.get("layers", []):
		sfx(layer, where, db)
	return true


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


func get_volume(group: StringName) -> float:
	return volumes.get(group, 1.0)


func set_volume(group: StringName, value: float) -> void:
	if not group in GROUPS:
		return
	volumes[group] = clampf(value, 0.0, 1.0)
	_apply(group)
	volume_changed.emit(group, volumes[group])


## Write the volumes to settings.cfg (call when a slider is let go).
func save() -> void:
	if not Net.save_settings_enabled:
		return
	var cfg := ConfigFile.new()
	cfg.load(Net.SETTINGS_PATH)
	for g in GROUPS:
		cfg.set_value("audio", String(g), volumes[g])
	cfg.save(Net.SETTINGS_PATH)


func _apply(group: StringName) -> void:
	var i := AudioServer.get_bus_index(group)
	if i == -1:
		return
	var v: float = volumes[group]
	AudioServer.set_bus_mute(i, v <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))
