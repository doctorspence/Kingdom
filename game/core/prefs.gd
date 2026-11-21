extends Node
## Autoload "Prefs": your settings that are not volume (volume is Audio's).
##
##   Gameplay   damage numbers, enemy health bars, gore level
##   Camera     mouse sensitivity, invert Y
##   Display    fullscreen, vsync
##   Controls   keyboard and mouse bindings (gamepad stays as designed)
##
## Everything is saved in settings.cfg and applied at start-up. The default
## controls stay in InputSetup; this only layers your changes on top.

## The actions you can rebind, in menu order: [action, label].
const REBINDABLE := [
	["move_forward", "Move forward"], ["move_back", "Move back"], ["move_left", "Move left"], ["move_right", "Move right"],
	["jump", "Jump"], ["dodge_sprint", "Roll / sprint"], ["walk", "Walk (hold)"],
	["light_attack", "Light attack"], ["heavy_attack", "Heavy attack"], ["block", "Block / parry"],
	["lock_on", "Lock on"], ["target_next", "Next target"], ["target_prev", "Previous target"],
	["flask", "Drink flask"], ["interact", "Interact"], ["swap_weapons", "Swap weapons"],
	["ability_1", "Ability 1"], ["ability_2", "Ability 2"], ["ability_3", "Ability 3"],
	["ability_4", "Ability 4"], ["ability_5", "Ability 5"], ["ability_6", "Ability 6"],
	["inventory", "Inventory"], ["map", "Map"], ["talents", "Talents"], ["chat", "Chat"],
]

signal changed

## Camera: multiplies the mouse and stick look speed.
var look_sensitivity := 1.0
var invert_y := false
var fullscreen := false
var vsync := true

## action -> its default keyboard/mouse events (captured once at start).
var _defaults := {}


func _ready() -> void:
	for entry in REBINDABLE:
		_defaults[entry[0]] = _kbm_events(entry[0])
	_load()
	_apply_display()


# --- Saving ----------------------------------------------------------------------------

func save() -> void:
	if not Net.save_settings_enabled:
		return
	var cfg := ConfigFile.new()
	cfg.load(Net.SETTINGS_PATH)
	cfg.set_value("gameplay", "damage_numbers", CombatFx.show_damage_numbers)
	cfg.set_value("gameplay", "enemy_health_bars", CombatFx.show_enemy_health_bars)
	cfg.set_value("gameplay", "gore", CombatFx.gore)
	cfg.set_value("camera", "look_sensitivity", look_sensitivity)
	cfg.set_value("camera", "invert_y", invert_y)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "vsync", vsync)
	if cfg.has_section("controls"):
		cfg.erase_section("controls")
	for entry in REBINDABLE:
		var changed_from_default := encode_all(_kbm_events(entry[0])) != encode_all(_defaults[entry[0]])
		if changed_from_default:
			cfg.set_value("controls", entry[0], encode_all(_kbm_events(entry[0])))
	cfg.save(Net.SETTINGS_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(Net.SETTINGS_PATH) != OK:
		return
	CombatFx.show_damage_numbers = bool(cfg.get_value("gameplay", "damage_numbers", true))
	CombatFx.show_enemy_health_bars = bool(cfg.get_value("gameplay", "enemy_health_bars", true))
	CombatFx.gore = clampi(int(cfg.get_value("gameplay", "gore", 2)), 0, 2)
	look_sensitivity = clampf(float(cfg.get_value("camera", "look_sensitivity", 1.0)), 0.3, 3.0)
	invert_y = bool(cfg.get_value("camera", "invert_y", false))
	fullscreen = bool(cfg.get_value("display", "fullscreen", false))
	vsync = bool(cfg.get_value("display", "vsync", true))
	if cfg.has_section("controls"):
		for key in cfg.get_section_keys("controls"):
			if _defaults.has(key):
				_set_events(key, decode_all(String(cfg.get_value("controls", key, ""))))


# --- Display ---------------------------------------------------------------------------

func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_display()
	save()


func set_vsync(on: bool) -> void:
	vsync = on
	_apply_display()
	save()


func _apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)


# --- Controls --------------------------------------------------------------------------

## The keyboard and mouse events on an action (gamepad ones are left alone).
func _kbm_events(action: StringName) -> Array:
	var out := []
	for e in InputMap.action_get_events(action):
		if e is InputEventKey or e is InputEventMouseButton:
			out.append(e)
	return out


func _set_events(action: StringName, events: Array) -> void:
	for e in _kbm_events(action):
		InputMap.action_erase_event(action, e)
	for e in events:
		InputMap.action_add_event(action, e)


## What the action is bound to right now, for display ("W", "Left mouse"...).
func binding_text(action: StringName) -> String:
	var events := _kbm_events(action)
	if events.is_empty():
		return "(none)"
	return event_text(events[0])


static func event_text(e: InputEvent) -> String:
	if e is InputEventKey:
		var code: Key = e.physical_keycode if e.physical_keycode != KEY_NONE else e.keycode
		if DisplayServer.get_name() == "headless":
			return OS.get_keycode_string(code)  # (the display server can't translate keys here)
		return OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(code))
	if e is InputEventMouseButton:
		match e.button_index:
			MOUSE_BUTTON_LEFT:
				return "Left mouse"
			MOUSE_BUTTON_RIGHT:
				return "Right mouse"
			MOUSE_BUTTON_MIDDLE:
				return "Middle mouse"
			MOUSE_BUTTON_WHEEL_UP:
				return "Wheel up"
			MOUSE_BUTTON_WHEEL_DOWN:
				return "Wheel down"
			_:
				return "Mouse %d" % e.button_index
	return "?"


## Bind a key or mouse button to an action. If another action already uses it,
## the two swap, so nothing is ever left silently unbound. Returns a message
## ("" if nothing needed saying).
func rebind(action: StringName, event: InputEvent) -> String:
	if not _defaults.has(action):
		return "Can't rebind that"
	var new_code := encode(event)
	if new_code == "":
		return "Can't use that"
	var message := ""
	var old := _kbm_events(action)
	for entry in REBINDABLE:
		var other: StringName = entry[0]
		if other == action:
			continue
		for e in _kbm_events(other):
			if encode(e) == new_code:
				_set_events(other, old)  # the other action takes this one's old binding
				message = "%s swapped with %s" % [event_text(event), entry[1]]
	_set_events(action, [event])
	save()
	changed.emit()
	return message


func reset_controls() -> void:
	for entry in REBINDABLE:
		_set_events(entry[0], _defaults[entry[0]])
	save()
	changed.emit()


func is_default(action: StringName) -> bool:
	return encode_all(_kbm_events(action)) == encode_all(_defaults.get(action, []))


# --- Turning events into text and back (for the save file) -------------------------------

## "key:87" or "mouse:1", or "" if it is neither.
static func encode(e: InputEvent) -> String:
	if e is InputEventKey:
		var code: int = e.physical_keycode if e.physical_keycode != KEY_NONE else e.keycode
		return "key:%d" % code
	if e is InputEventMouseButton:
		return "mouse:%d" % e.button_index
	return ""


static func encode_all(events: Array) -> String:
	var parts := PackedStringArray()
	for e in events:
		parts.append(encode(e))
	return ",".join(parts)


static func decode(text: String) -> InputEvent:
	var bits := text.split(":")
	if bits.size() != 2 or not bits[1].is_valid_int():
		return null
	if bits[0] == "key":
		var k := InputEventKey.new()
		k.physical_keycode = int(bits[1]) as Key
		return k
	if bits[0] == "mouse":
		var m := InputEventMouseButton.new()
		m.button_index = int(bits[1]) as MouseButton
		return m
	return null


static func decode_all(text: String) -> Array:
	var out := []
	for part in text.split(","):
		var e := decode(part)
		if e:
			out.append(e)
	return out
