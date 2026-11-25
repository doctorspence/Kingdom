extends Node
## Defines every control in the game (keyboard + mouse and gamepad).
##
## This runs once when the game starts (it is an "autoload"). Keeping the
## controls in code makes them easy to read in one place. A rebinding menu
## comes later and will save your changes on top of these defaults.

const STICK_DEADZONE := 0.2
const TRIGGER_DEADZONE := 0.3


func _ready() -> void:
	# Movement and camera
	_add("move_forward", [_key(KEY_W), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_add("move_back", [_key(KEY_S), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_add("move_left", [_key(KEY_A), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_add("move_right", [_key(KEY_D), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_add("look_left", [_axis(JOY_AXIS_RIGHT_X, -1.0)])
	_add("look_right", [_axis(JOY_AXIS_RIGHT_X, 1.0)])
	_add("look_up", [_axis(JOY_AXIS_RIGHT_Y, -1.0)])
	_add("look_down", [_axis(JOY_AXIS_RIGHT_Y, 1.0)])
	_add("walk", [])  # no key by default (rebindable); gamepad: just tilt the stick gently
	_add("crouch", [_key(KEY_CTRL), _key(KEY_C), _button(JOY_BUTTON_LEFT_STICK)])  # toggle
	# Shift / gamepad B: tap = roll, hold = sprint (handled in the player script)
	_add("dodge_sprint", [_key(KEY_SHIFT), _button(JOY_BUTTON_B)])
	_add("jump", [_key(KEY_SPACE), _button(JOY_BUTTON_A)])

	# Targeting
	_add("lock_on", [_key(KEY_Q), _button(JOY_BUTTON_RIGHT_STICK)])
	_add("target_next", [_mouse(MOUSE_BUTTON_WHEEL_DOWN)])
	_add("target_prev", [_mouse(MOUSE_BUTTON_WHEEL_UP)])

	# Combat (used from Phase 3 on)
	_add("light_attack", [_mouse(MOUSE_BUTTON_LEFT), _button(JOY_BUTTON_RIGHT_SHOULDER)])
	_add("heavy_attack", [_mouse(MOUSE_BUTTON_MIDDLE), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)], TRIGGER_DEADZONE)
	_add("block", [_mouse(MOUSE_BUTTON_RIGHT), _button(JOY_BUTTON_LEFT_SHOULDER)])
	_add("flask", [_key(KEY_R), _button(JOY_BUTTON_X)])
	_add("interact", [_key(KEY_E), _button(JOY_BUTTON_Y)])
	_add("ability_modifier", [_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)], TRIGGER_DEADZONE)
	for i in range(1, 7):
		_add("ability_%d" % i, [_key((KEY_0 + i) as Key)])
	_add("swap_weapons", [_key(KEY_X), _button(JOY_BUTTON_DPAD_RIGHT)])

	# Menus
	_add("inventory", [_key(KEY_I), _key(KEY_TAB), _button(JOY_BUTTON_BACK)])
	_add("map", [_key(KEY_M), _button(JOY_BUTTON_DPAD_UP)])
	_add("chat", [_key(KEY_ENTER)])
	_add("menu", [_key(KEY_ESCAPE), _button(JOY_BUTTON_START)])
	# Inside the menu book (inventory, map, talents...): the player can't act there,
	# so these reuse keys and buttons that mean something else in the world.
	_add("menu_tab_prev", [_key(KEY_Q), _button(JOY_BUTTON_LEFT_SHOULDER)])
	_add("menu_tab_next", [_key(KEY_E), _button(JOY_BUTTON_RIGHT_SHOULDER)])
	_add("menu_filter_prev", [_key(KEY_BRACKETLEFT), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)], TRIGGER_DEADZONE)
	_add("menu_filter_next", [_key(KEY_BRACKETRIGHT), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)], TRIGGER_DEADZONE)
	_add("inv_compare", [_key(KEY_C), _button(JOY_BUTTON_X)])
	_add("inv_drop", [_key(KEY_DELETE), _button(JOY_BUTTON_Y)])
	_add("inv_junk", [_key(KEY_J), _button(JOY_BUTTON_LEFT_STICK)])
	_add("inv_sort", [_key(KEY_Z), _button(JOY_BUTTON_RIGHT_STICK)])
	_add("inv_rotate", [_key(KEY_R)])

	# Test helpers (only for development)
	_add("debug_help", [_key(KEY_F1)])
	_add("debug_info", [_key(KEY_F2)])
	# Cheat keys only exist in editor/debug builds; an exported build keeps the
	# actions (so is_action_pressed stays valid) but gives them no keys.
	var dev := OS.is_debug_build()
	_add("debug_equip_load", [_key(KEY_F3)] if dev else [])
	_add("debug_reset", [_key(KEY_F4)] if dev else [])
	_add("debug_time", [_key(KEY_F5)] if dev else [])
	_add("debug_rain", [_key(KEY_F6)] if dev else [])
	_add("debug_raid", [_key(KEY_F7)] if dev else [])
	_add("toggle_health_bars", [_key(KEY_H)])
	_add("toggle_damage_numbers", [_key(KEY_N)])
	_add("talents", [_key(KEY_T), _button(JOY_BUTTON_DPAD_LEFT)])
	_add("debug_level_up", [_key(KEY_PAGEUP)] if dev else [])
	_add("debug_level_reset", [_key(KEY_PAGEDOWN)] if dev else [])


func _add(action: StringName, events: Array, deadzone := STICK_DEADZONE) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)
	for e: InputEvent in events:
		InputMap.action_add_event(action, e)


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


func _mouse(index: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = index
	return e


func _button(index: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = index
	return e


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e
