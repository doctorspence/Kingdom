extends Node
## Automated settings check: key rebinding (swap on conflict, gamepad kept,
## reset), the save format, and the settings screen (tabs, listening for a key,
## Esc to cancel, gameplay options).
##   ... --headless --path . --script res://tests/run.gd -- prefs_check

var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = true
	return e


func _has_joypad(action: StringName) -> bool:
	return InputMap.action_get_events(action).any(func(e: InputEvent) -> bool: return e is InputEventJoypadButton)


func _run() -> void:
	Prefs.reset_controls()
	_check("defaults: jump is Space, flask is R (%s, %s)" % [Prefs.binding_text(&"jump"), Prefs.binding_text(&"flask")],
			Prefs.binding_text(&"jump") == "Space" and Prefs.binding_text(&"flask") == "R")
	_check("every rebindable action exists", Prefs.REBINDABLE.all(func(e: Array) -> bool: return InputMap.has_action(e[0])))

	# --- Rebinding -----------------------------------------------------------------------
	var note := Prefs.rebind(&"jump", _key(KEY_V))
	_check("jump rebound to V (%s)" % Prefs.binding_text(&"jump"), Prefs.binding_text(&"jump") == "V" and note == "")
	_check("the gamepad button for jump is kept", _has_joypad(&"jump"))
	_check("a changed action is not 'default'", not Prefs.is_default(&"jump") and Prefs.is_default(&"flask"))
	Input.parse_input_event(_key(KEY_V))
	_check("the new key triggers the action in the engine", InputMap.event_is_action(_key(KEY_V), &"jump") and not InputMap.event_is_action(_key(KEY_SPACE), &"jump"))
	note = Prefs.rebind(&"flask", _key(KEY_V))
	_check("a clash swaps the two (flask %s, jump %s; \"%s\")" % [Prefs.binding_text(&"flask"), Prefs.binding_text(&"jump"), note],
			Prefs.binding_text(&"flask") == "V" and Prefs.binding_text(&"jump") == "R" and note.contains("swapped"))
	var mouse_note := Prefs.rebind(&"interact", _mouse(MOUSE_BUTTON_MIDDLE))
	_check("interact can take a mouse button; heavy attack (middle mouse) swaps to E (%s)" % Prefs.binding_text(&"heavy_attack"),
			Prefs.binding_text(&"interact") == "Middle mouse" and Prefs.binding_text(&"heavy_attack") == "E" and mouse_note.contains("swapped"))
	_check("heavy attack keeps its trigger on a gamepad", _has_joypad(&"light_attack") and InputMap.action_get_events(&"heavy_attack").any(func(e: InputEvent) -> bool: return e is InputEventJoypadMotion))
	Prefs.reset_controls()
	_check("reset restores everything", Prefs.binding_text(&"jump") == "Space" and Prefs.binding_text(&"flask") == "R"
			and Prefs.binding_text(&"interact") == "E" and Prefs.binding_text(&"heavy_attack") == "Middle mouse")
	_check("an unknown action can't be rebound", Prefs.rebind(&"debug_help", _key(KEY_V)) != "")

	# --- The save format -----------------------------------------------------------------
	var text := Prefs.encode_all([_key(KEY_Z), _mouse(MOUSE_BUTTON_RIGHT)])
	var back := Prefs.decode_all(text)
	_check("save text round-trips (%s)" % text, text == "key:%d,mouse:%d" % [KEY_Z, MOUSE_BUTTON_RIGHT] and back.size() == 2
			and Prefs.encode_all(back) == text)
	_check("garbage in the save file is ignored", Prefs.decode_all("nonsense,key:x,mouse:").is_empty())

	# --- The screen -------------------------------------------------------------------------
	var panel := SettingsPanel.new()
	add_child(panel)
	await get_tree().process_frame
	panel.open()
	await get_tree().process_frame
	_check("the screen has Audio, Gameplay, Display and Controls tabs", panel._tabs.get_tab_count() == 4)
	_check("a row for every rebindable action", panel._rows.size() == Prefs.REBINDABLE.size())
	(panel._rows[&"jump"] as Button).pressed.emit()
	_check("clicking an action waits for a key", panel._listening == &"jump" and (panel._rows[&"jump"] as Button).text == "Press a key...")
	panel._input(_key(KEY_ESCAPE))
	_check("Esc cancels and changes nothing", panel._listening == &"" and Prefs.binding_text(&"jump") == "Space")
	(panel._rows[&"jump"] as Button).pressed.emit()
	panel._input(_key(KEY_B))
	_check("pressing a key binds it (%s)" % (panel._rows[&"jump"] as Button).text, Prefs.binding_text(&"jump") == "B" and (panel._rows[&"jump"] as Button).text == "B")
	(panel._rows[&"light_attack"] as Button).pressed.emit()
	panel._input(_mouse(MOUSE_BUTTON_RIGHT))
	_check("pressing a mouse button binds it, swapping with block (%s / %s)" % [Prefs.binding_text(&"light_attack"), Prefs.binding_text(&"block")],
			Prefs.binding_text(&"light_attack") == "Right mouse" and Prefs.binding_text(&"block") == "Left mouse")
	(panel.find_child("ResetControls", true, false) as Button).pressed.emit()
	_check("the reset button works", Prefs.binding_text(&"jump") == "Space" and Prefs.binding_text(&"light_attack") == "Left mouse")

	var gore := panel.find_child("Gore", true, false) as OptionButton
	var gore_before := CombatFx.gore
	gore.item_selected.emit(0)
	_check("the gore option changes the gore level", CombatFx.gore == 0)
	gore.item_selected.emit(gore_before)
	var closed := [false]
	panel.closed.connect(func() -> void: closed[0] = true)
	panel.close_panel()
	_check("closing hides it and says so", not panel.visible and closed[0])
	panel.queue_free()

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", label])
	if not ok:
		failures += 1
