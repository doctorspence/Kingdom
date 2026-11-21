extends Control
## Main menu: make your character (name, class, body, color), then host a game
## (or play alone) or join a friend. Works with mouse, keyboard and gamepad.

var _name_edit: LineEdit
var _address_edit: LineEdit
var _status: Label
var _host_button: Button
var _class_info: Label
var _class_buttons: Array[Button] = []
var _body_buttons: Array[Button] = []
var _color_buttons: Array[Button] = []

var _class_id := &"class_bulwark"
var _body := 0
var _color := 0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_class_id = Net.character.get("class", _class_id)
	_body = Net.character.get("body", 0)
	_color = Net.character.get("color", 0)
	_build()
	_refresh()
	Net.connection_failed.connect(_show_error)
	_host_button.grab_focus()
	# Test shortcuts: "-- --host" or "-- --join=127.0.0.1" (optionally
	# "--class=class_headsman") on the command line.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--class="):
			_class_id = StringName(arg.trim_prefix("--class="))
	for arg in OS.get_cmdline_user_args():
		if arg == "--host":
			_on_host.call_deferred()
		elif arg.begins_with("--join="):
			_address_edit.text = arg.trim_prefix("--join=")
			_on_join.call_deferred()


func _save_choice() -> void:
	Net.player_name = _clean_name()
	Net.character = {"class": _class_id, "body": _body, "color": _color}


func _on_host() -> void:
	_save_choice()
	var err := Net.host_game()
	if err != OK:
		_show_error("Could not host: port %d is already in use (is another copy hosting?)." % Net.PORT)


func _on_join() -> void:
	var address := _address_edit.text.strip_edges()
	if address == "":
		_show_error("Type the host's address first.")
		return
	_save_choice()
	_status.text = "Connecting to %s..." % address
	Net.join_game(address)


func _clean_name() -> String:
	var n := _name_edit.text.strip_edges().left(20)
	return n if n != "" else "Wanderer"


func _show_error(text: String) -> void:
	if is_instance_valid(_status):
		_status.text = text
		_status.modulate = Color(1.0, 0.6, 0.5)


func _refresh() -> void:
	for b in _class_buttons:
		b.button_pressed = b.get_meta("id") == _class_id
	for i in _body_buttons.size():
		_body_buttons[i].button_pressed = i == _body
	for i in _color_buttons.size():
		_color_buttons[i].text = "[x]" if i == _color else ""
	var c := Classes.by_id(_class_id)
	var first_abilities := PackedStringArray()
	for a in c.abilities:
		first_abilities.append("%s (lvl %d)" % [a.display_name, a.unlock_level])
	_class_info.text = "%s — %s\n\n%s\n\nResource: %s\nPassive: %s. %s\n\nAbilities: %s" % [
			c.display_name, c.role, c.description, c.resource_label, c.passive_name,
			c.passive_description, ", ".join(first_abilities)]


# --- Building the screen ------------------------------------------------------

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var columns := HBoxContainer.new()
	columns.set_anchors_preset(Control.PRESET_CENTER)
	columns.position = Vector2(-560, -330)
	columns.add_theme_constant_override("separation", 60)
	add_child(columns)

	# Left: your character.
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(560, 0)
	left.add_theme_constant_override("separation", 10)
	columns.add_child(left)

	var title := Label.new()
	title.text = "KINGDOM"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.78, 0.74, 0.64))
	left.add_child(title)

	left.add_child(_label("Your name"))
	_name_edit = LineEdit.new()
	_name_edit.text = Net.player_name
	_name_edit.max_length = 20
	left.add_child(_name_edit)

	left.add_child(_label("Class"))
	var class_row := HBoxContainer.new()
	class_row.add_theme_constant_override("separation", 8)
	left.add_child(class_row)
	for c in Classes.ALL:
		var b := Button.new()
		b.text = "%s\n%s" % [c.display_name, c.role]
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(180, 56)
		b.set_meta("id", c.id)
		b.pressed.connect(func() -> void:
			_class_id = c.id
			_refresh())
		class_row.add_child(b)
		_class_buttons.append(b)

	_class_info = _label("")
	_class_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_class_info.custom_minimum_size = Vector2(560, 230)
	_class_info.add_theme_font_size_override("font_size", 15)
	left.add_child(_class_info)

	left.add_child(_label("Body"))
	var body_row := HBoxContainer.new()
	left.add_child(body_row)
	for i in Classes.BODY_NAMES.size():
		var b := Button.new()
		b.text = Classes.BODY_NAMES[i]
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(120, 36)
		b.pressed.connect(func() -> void:
			_body = i
			_refresh())
		body_row.add_child(b)
		_body_buttons.append(b)

	left.add_child(_label("Color"))
	var color_row := HBoxContainer.new()
	color_row.add_theme_constant_override("separation", 6)
	left.add_child(color_row)
	for i in Classes.LOOK_COLORS.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(48, 36)
		var style := StyleBoxFlat.new()
		style.bg_color = Classes.LOOK_COLORS[i]
		b.add_theme_stylebox_override("normal", style)
		b.add_theme_stylebox_override("hover", style)
		b.add_theme_stylebox_override("pressed", style)
		b.pressed.connect(func() -> void:
			_color = i
			_refresh())
		color_row.add_child(b)
		_color_buttons.append(b)

	# Right: play.
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(460, 0)
	right.add_theme_constant_override("separation", 14)
	columns.add_child(right)
	right.add_child(_spacer(90))

	_host_button = _button("Host game  (or play alone)", _on_host)
	right.add_child(_host_button)
	var ips := Net.local_addresses()
	var hint := _label("Friends on your network join with: %s   (port %d, UDP)" % [
			", ".join(ips) if not ips.is_empty() else "your IP address", Net.PORT])
	hint.add_theme_font_size_override("font_size", 14)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(hint)
	right.add_child(_spacer(10))

	right.add_child(_label("Host's address"))
	_address_edit = LineEdit.new()
	_address_edit.text = Net.join_address
	_address_edit.placeholder_text = "e.g. 192.168.1.20 or a Tailscale/ZeroTier/Radmin address"
	_address_edit.text_submitted.connect(func(_t: String) -> void: _on_join())
	right.add_child(_address_edit)
	right.add_child(_button("Join game", _on_join))
	right.add_child(_spacer(10))
	right.add_child(_button("Quit", func() -> void: get_tree().quit()))

	_status = _label("")
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_status)


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(action)
	return b


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.75, 0.72, 0.66))
	return l


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
