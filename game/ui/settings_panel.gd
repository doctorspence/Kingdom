class_name SettingsPanel
extends PanelContainer
## The settings screen (main menu and Esc menu): Audio, Gameplay, Display and
## Controls tabs. Changes apply at once and are saved.
##
## Controls: click an action, then press the key or mouse button you want
## (Esc cancels). If another action already uses it, the two swap.
## Gamepad controls stay as designed.

signal closed

var _tabs: TabContainer
var _rows := {}  # action -> Button showing its binding
var _listening: StringName = &""
var _message: Label


func _ready() -> void:
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	box.add_child(title)
	_tabs = TabContainer.new()
	_tabs.custom_minimum_size = Vector2(700, 470)
	box.add_child(_tabs)
	_tabs.add_child(_tab("Audio", AudioSettings.new()))
	_tabs.add_child(_gameplay_tab())
	_tabs.add_child(_display_tab())
	_tabs.add_child(_controls_tab())
	_message = Label.new()
	_message.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4))
	box.add_child(_message)
	var close := Button.new()
	close.name = "Close"
	close.text = "Close"
	close.custom_minimum_size = Vector2(0, 42)
	close.pressed.connect(close_panel)
	box.add_child(close)
	Prefs.changed.connect(_refresh_rows)


func open() -> void:
	_stop_listening()
	_refresh_rows()
	_message.text = ""
	visible = true
	(find_child("Close", true, false) as Button).grab_focus()


func close_panel() -> void:
	if not visible:
		return
	_stop_listening()
	visible = false
	Audio.save()
	Prefs.save()
	closed.emit()


func _tab(tab_name: String, content: Control) -> Control:
	var pad := MarginContainer.new()
	pad.name = tab_name
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_top", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_child(content)
	return pad


func _check_box(text: String, on: bool, action: Callable) -> CheckBox:
	var c := CheckBox.new()
	c.text = text
	c.button_pressed = on
	c.toggled.connect(action)
	return c


func _slider_row(text: String, value: float, lo: float, hi: float, step: float, action: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(190, 0)
	row.add_child(label)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(260, 24)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(action)
	s.drag_ended.connect(func(_c: bool) -> void: Prefs.save())
	row.add_child(s)
	return row


func _gameplay_tab() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.add_child(_check_box("Floating damage numbers", CombatFx.show_damage_numbers, func(on: bool) -> void:
		CombatFx.show_damage_numbers = on
		Prefs.save()))
	v.add_child(_check_box("Enemy health bars", CombatFx.show_enemy_health_bars, func(on: bool) -> void:
		CombatFx.show_enemy_health_bars = on
		Prefs.save()))
	var gore_row := HBoxContainer.new()
	gore_row.add_theme_constant_override("separation", 10)
	var gl := Label.new()
	gl.text = "Gore"
	gl.custom_minimum_size = Vector2(190, 0)
	gore_row.add_child(gl)
	var gore := OptionButton.new()
	gore.name = "Gore"
	for t in ["Off", "Low", "High"]:
		gore.add_item(t)
	gore.selected = CombatFx.gore
	gore.item_selected.connect(func(i: int) -> void:
		CombatFx.gore = i
		Prefs.save())
	gore_row.add_child(gore)
	v.add_child(gore_row)
	v.add_child(_slider_row("Camera sensitivity", Prefs.look_sensitivity, 0.3, 3.0, 0.05, func(x: float) -> void: Prefs.look_sensitivity = x))
	v.add_child(_check_box("Invert camera Y", Prefs.invert_y, func(on: bool) -> void:
		Prefs.invert_y = on
		Prefs.save()))
	return _tab("Gameplay", v)


func _display_tab() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.add_child(_check_box("Fullscreen", Prefs.fullscreen, Prefs.set_fullscreen))
	v.add_child(_check_box("Vertical sync", Prefs.vsync, Prefs.set_vsync))
	return _tab("Display", v)


func _controls_tab() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	var hint := Label.new()
	hint.text = "Click an action, then press the key or mouse button you want (Esc cancels). Gamepad controls are fixed."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(660, 340)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(grid)
	for entry in Prefs.REBINDABLE:
		var l := Label.new()
		l.text = entry[1]
		l.custom_minimum_size = Vector2(220, 0)
		grid.add_child(l)
		var b := Button.new()
		b.name = "Bind_%s" % entry[0]
		b.custom_minimum_size = Vector2(240, 32)
		var action: StringName = entry[0]
		b.pressed.connect(func() -> void: _listen(action))
		grid.add_child(b)
		_rows[action] = b
	var reset := Button.new()
	reset.name = "ResetControls"
	reset.text = "Reset controls to default"
	reset.pressed.connect(func() -> void:
		Prefs.reset_controls()
		_message.text = "Controls reset")
	v.add_child(reset)
	return _tab("Controls", v)


func _refresh_rows() -> void:
	for action in _rows:
		var b: Button = _rows[action]
		b.text = "Press a key..." if action == _listening else Prefs.binding_text(action)
		b.modulate = Color(1.0, 0.85, 0.4) if action == _listening else (Color.WHITE if Prefs.is_default(action) else Color(0.7, 0.9, 1.0))


func _listen(action: StringName) -> void:
	_listening = action
	_message.text = "Press the new key or mouse button for \"%s\" (Esc cancels)" % _label_of(action)
	_refresh_rows()


func _stop_listening() -> void:
	_listening = &""
	_refresh_rows()


func _label_of(action: StringName) -> String:
	for entry in Prefs.REBINDABLE:
		if entry[0] == action:
			return entry[1]
	return String(action)


## While waiting for a key, the next key or mouse button is the new binding.
func _input(event: InputEvent) -> void:
	if _listening == &"" or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.physical_keycode == KEY_ESCAPE:
			_message.text = "Cancelled"
			_stop_listening()
			return
		_bind(event)
	elif event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
		_bind(event)


func _bind(event: InputEvent) -> void:
	var action := _listening
	_listening = &""
	var note := Prefs.rebind(action, event)
	_message.text = note if note != "" else "%s: %s" % [_label_of(action), Prefs.event_text(event)]
	_refresh_rows()
