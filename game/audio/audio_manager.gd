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
