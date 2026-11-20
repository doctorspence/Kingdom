extends Control
## Main menu: pick a name, host a game (or play alone), or join a friend.
## Works with mouse, keyboard and gamepad.

var _name_edit: LineEdit
var _address_edit: LineEdit
var _status: Label
var _host_button: Button


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()
	Net.connection_failed.connect(_show_error)
	_host_button.grab_focus()
	# Test shortcuts: "-- --host" or "-- --join=127.0.0.1" on the command line.
	for arg in OS.get_cmdline_user_args():
		if arg == "--host":
			_on_host.call_deferred()
		elif arg.begins_with("--join="):
			_address_edit.text = arg.trim_prefix("--join=")
			_on_join.call_deferred()


func _on_host() -> void:
	Net.player_name = _clean_name()
	var err := Net.host_game()
	if err != OK:
		_show_error("Could not host: port %d is already in use (is another copy hosting?)." % Net.PORT)


func _on_join() -> void:
	var address := _address_edit.text.strip_edges()
	if address == "":
		_show_error("Type the host's address first.")
		return
	Net.player_name = _clean_name()
	_status.text = "Connecting to %s..." % address
	Net.join_game(address)


func _clean_name() -> String:
	var n := _name_edit.text.strip_edges().left(20)
	return n if n != "" else "Wanderer"


func _show_error(text: String) -> void:
	if is_instance_valid(_status):
		_status.text = text
		_status.modulate = Color(1.0, 0.6, 0.5)


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(560, 0)
	box.position = Vector2(-280, -300)
	box.add_theme_constant_override("separation", 14)
	add_child(box)

	var title := Label.new()
	title.text = "KINGDOM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.78, 0.74, 0.64))
	box.add_child(title)

	var sub := Label.new()
	sub.text = "working title"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.5, 0.48, 0.44))
	box.add_child(sub)
	box.add_child(_spacer(20))

	box.add_child(_label("Your name"))
	_name_edit = LineEdit.new()
	_name_edit.text = Net.player_name
	_name_edit.max_length = 20
	box.add_child(_name_edit)
	box.add_child(_spacer(10))

	_host_button = _button("Host game  (or play alone)", _on_host)
	box.add_child(_host_button)
	var ips := Net.local_addresses()
	var hint := _label("Friends on your network join with: %s   (port %d, UDP)" % [
			", ".join(ips) if not ips.is_empty() else "your IP address", Net.PORT])
	hint.add_theme_font_size_override("font_size", 14)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)
	box.add_child(_spacer(10))

	box.add_child(_label("Host's address"))
	_address_edit = LineEdit.new()
	_address_edit.text = Net.join_address
	_address_edit.placeholder_text = "e.g. 192.168.1.20 or a Tailscale/ZeroTier/Radmin address"
	_address_edit.text_submitted.connect(func(_t: String) -> void: _on_join())
	box.add_child(_address_edit)
	box.add_child(_button("Join game", _on_join))
	box.add_child(_spacer(10))
	box.add_child(_button("Quit", func() -> void: get_tree().quit()))

	_status = _label("")
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)


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
