class_name Hud
extends CanvasLayer
## On-screen display: your bars and flasks, party frames, chat, lock-on marker,
## enemy health bars, prompts, the Esc menu and test helpers.
##   F1 = controls   F2 = debug info   F3 = equip load   F4 = reset

const HELP_TEXT := """CONTROLS (F1 to hide)
Move: WASD / left stick (tilt gently to walk)
Walk: hold Ctrl
Look: mouse / right stick
Roll: tap Shift / tap B
Sprint: hold Shift / hold B
Jump: Space / A
Lock on: Q / click right stick
Switch target: mouse wheel / flick right stick
Light attack: left mouse / RB  (press again to combo)
Heavy attack: middle mouse / RT  (hold to charge)
Block: hold right mouse / LB  (raise it just as a hit lands = parry)
Riposte: light attack on a reeling enemy after a parry
Drink flask: R / X        Interact / rest: E / Y
Revive a downed friend: hold E / Y next to them (costs a flask)
Chat: Enter        Menu (leave game): Esc

TEST KEYS
F2: debug info (invincibility shows as a blue tint)
F3: change equip load (light / medium / heavy / overloaded)
F4: reset to start, full health
H: enemy health bars on/off    N: damage numbers on/off"""

const CHAT_LINES := 8
const CHAT_FADE_TIME := 12.0

var player: Player

var _health_bar: ResourceBar
var _stamina_bar: ResourceBar
var _flask_label: Label
var _prompt_label: Label
var _marker: Control
var _debug_label: Label
var _help_label: Label
var _hint_label: Label
var _death_label: Label
var _down_label: Label
var _death_fade := 0.0
var _party_box: VBoxContainer
var _chat_log: Label
var _chat_edit: LineEdit
var _chat_lines: Array[String] = []
var _chat_timer := 0.0
var _menu: PanelContainer


func _ready() -> void:
	_build()
	Net.chat_received.connect(_on_chat)
	while player == null:
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group(&"local_player") as Player
	player.health_changed.connect(_health_bar.set_values)
	player.stamina_changed.connect(_stamina_bar.set_values)
	player.flasks_changed.connect(_on_flasks_changed)
	player.died.connect(_on_died)
	player.respawned.connect(_on_respawned)
	_health_bar.set_values(player.health, player.tuning.max_health)
	_stamina_bar.set_values(player.stamina, player.tuning.max_stamina)
	_on_flasks_changed(player.flasks, player.tuning.flask_count)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("chat") and not Net.typing:
		_open_chat()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu") and not Net.typing:
		_menu.visible = not _menu.visible
		if _menu.visible:
			(_menu.find_child("Resume", true, false) as Button).grab_focus()
	elif event.is_action_pressed("debug_help"):
		_help_label.visible = not _help_label.visible
		_hint_label.visible = false
	elif event.is_action_pressed("debug_info"):
		_debug_label.visible = not _debug_label.visible
		if player:
			player.show_debug = _debug_label.visible
	elif event.is_action_pressed("toggle_health_bars"):
		CombatFx.show_enemy_health_bars = not CombatFx.show_enemy_health_bars
	elif event.is_action_pressed("toggle_damage_numbers"):
		CombatFx.show_damage_numbers = not CombatFx.show_damage_numbers


func _process(delta: float) -> void:
	_marker.queue_redraw()
	if _death_label.visible:
		_death_fade = minf(1.0, _death_fade + delta * 0.8)
		_death_label.modulate.a = _death_fade
	_chat_timer -= delta
	_chat_log.modulate.a = 1.0 if Net.typing else clampf(_chat_timer / 2.0, 0.0, 1.0)
	if player != null and (not is_instance_valid(player) or not player.is_inside_tree()):
		player = null  # our character was removed (leaving the game)
	if player == null:
		return
	if _debug_label.visible:
		_debug_label.text = _debug_text()
	_update_prompt()
	_update_party()
	_down_label.visible = player.is_downed()
	if player.is_downed():
		_down_label.text = "You're down! Bleeding out: %d\nA friend can hold Interact next to you to revive you." % ceili(player.bleed_time_left())


func _update_prompt() -> void:
	var text := ""
	var reviving := player.revive_target()
	if reviving:
		text = "Reviving %s...  %d%%" % [reviving.player_name, roundi(player.revive_progress() * 100.0)]
	elif player.state == Player.State.MOVE:
		var downed := player._nearest_downed_friend()
		if downed:
			text = "[Hold E]  Revive %s  (costs a flask)" % downed.player_name if player.flasks > 0 \
					else "No flasks left to revive %s" % downed.player_name
		else:
			var thing := player.nearest_interactable()
			if thing:
				text = "[E]  %s" % thing.call(&"get_interact_text")
	_prompt_label.visible = text != ""
	_prompt_label.text = text


## Small frames for everyone else in the party: name, health, down/dead.
func _update_party() -> void:
	var others: Array[Player] = []
	for n in get_tree().get_nodes_in_group(&"player"):
		var p := n as Player
		if p and p != player:
			others.append(p)
	while _party_box.get_child_count() < others.size():
		_party_box.add_child(_make_party_frame())
	for i in _party_box.get_child_count():
		var frame := _party_box.get_child(i) as Control
		frame.visible = i < others.size()
		if not frame.visible:
			continue
		var p := others[i]
		var label := frame.get_child(0) as Label
		var bar := frame.get_child(1) as ResourceBar
		var status := ""
		if p.is_downed():
			status = "  DOWN %ds" % ceili(p.bleed_time_left())
		elif p.is_dead():
			status = "  dead"
		label.text = p.player_name + status
		label.modulate = Color(1.0, 0.55, 0.45) if p.is_out_of_fight() else Color(1, 1, 1)
		bar.set_values(p.health, p.tuning.max_health)


func _make_party_frame() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.add_child(_make_label(16))
	var bar := ResourceBar.new()
	bar.pixels_per_point = 1.6
	bar.custom_minimum_size = Vector2(160, 8)
	bar.fill_color = Color(0.58, 0.07, 0.06)
	box.add_child(bar)
	return box


func _on_flasks_changed(current: int, maximum: int) -> void:
	_flask_label.text = "Flasks  %d / %d" % [current, maximum]
	_flask_label.modulate = Color(1, 1, 1) if current > 0 else Color(0.6, 0.4, 0.4)


func _debug_text() -> String:
	var p := player
	var tier_names := ["light", "medium", "heavy", "OVERLOADED"]
	var speed := Vector2(p.velocity.x, p.velocity.z).length()
	var lines := PackedStringArray([
		"State: %s%s" % [p.state_name(), "  (sprinting)" if p.is_sprinting else ("  (walking)" if p.is_walking else "")],
		"Speed: %.1f m/s" % speed,
		"Health: %d / %d    Stamina: %d / %d" % [p.health, p.tuning.max_health, p.stamina, p.tuning.max_stamina],
		"Equip load: %d%% (%s)   [F3 to change]" % [roundi(p.equip_load * 100.0), tier_names[p.load_tier()]],
		"Invincible: %s    Blocking: %s%s" % ["YES" if p.is_invulnerable() else "no", "yes" if p.is_blocking else "no", "  (PARRY WINDOW)" if p.is_parrying() else ""],
		"Last fall: %.1f m" % p.last_fall_height,
		"Lock target: %s" % (p.targeting.target.name if p.targeting.has_target() else "none"),
		"Network: %s, %d player(s), ping n/a" % [["offline", "hosting", "joined"][Net.mode], get_tree().get_nodes_in_group(&"player").size()],
		"FPS: %d" % Engine.get_frames_per_second(),
	])
	return "\n".join(lines)


func _on_died() -> void:
	_death_fade = 0.0
	_death_label.modulate.a = 0.0
	_death_label.visible = true


func _on_respawned() -> void:
	_death_label.visible = false


# --- Chat ---------------------------------------------------------------------

func _open_chat() -> void:
	Net.typing = true
	_chat_edit.visible = true
	_chat_edit.text = ""
	_chat_edit.grab_focus()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_chat() -> void:
	Net.typing = false
	_chat_edit.release_focus()
	_chat_edit.visible = false
	_chat_timer = CHAT_FADE_TIME
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_chat_submitted(text: String) -> void:
	Net.send_chat(text)
	_close_chat()


func _on_chat_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_chat()
		_chat_edit.accept_event()


func _on_chat(sender: String, text: String, is_system: bool) -> void:
	_chat_lines.append(("* " + text) if is_system else "%s: %s" % [sender, text])
	while _chat_lines.size() > CHAT_LINES:
		_chat_lines.pop_front()
	_chat_log.text = "\n".join(_chat_lines)
	_chat_timer = CHAT_FADE_TIME


# --- Marker and enemy bars ----------------------------------------------------

func _draw_marker() -> void:
	if player == null or not is_instance_valid(player) or not player.is_inside_tree():
		return
	var cam := player.camera_rig.camera
	# Enemy health bars (once hurt or targeted).
	if CombatFx.show_enemy_health_bars:
		for n in get_tree().get_nodes_in_group(&"enemies"):
			var e := n as Node3D
			if e == null:
				continue
			var targeted := player.targeting.target == e
			if not (e.call(&"wants_health_bar") or (targeted and e.call(&"can_be_locked"))):
				continue
			var at: Vector3 = e.call(&"bar_point")
			if cam.is_position_behind(at) or cam.global_position.distance_to(at) > 30.0:
				continue
			var p := cam.unproject_position(at)
			var w := 90.0
			var ratio: float = e.call(&"health_ratio")
			var r := Rect2(p - Vector2(w * 0.5, 0), Vector2(w, 7))
			_marker.draw_rect(r.grow(1.0), Color(0, 0, 0, 0.8))
			_marker.draw_rect(Rect2(r.position, Vector2(w * ratio, 7)), Color(0.62, 0.08, 0.06))
	if not player.targeting.has_target():
		return
	var point := player.targeting.target_point()
	if cam.is_position_behind(point):
		return
	var pos := cam.unproject_position(point)
	_marker.draw_circle(pos, 7.0, Color(0, 0, 0, 0.6))
	_marker.draw_circle(pos, 4.5, Color(0.95, 0.9, 0.8, 0.95))


# --- Building the screen ------------------------------------------------------

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_marker = Control.new()
	_marker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marker.draw.connect(_draw_marker)
	root.add_child(_marker)

	var bars := VBoxContainer.new()
	bars.position = Vector2(40, 36)
	bars.add_theme_constant_override("separation", 6)
	root.add_child(bars)

	_health_bar = ResourceBar.new()
	_health_bar.custom_minimum_size = Vector2(300, 14)
	_health_bar.fill_color = Color(0.58, 0.07, 0.06)
	bars.add_child(_health_bar)

	_stamina_bar = ResourceBar.new()
	_stamina_bar.custom_minimum_size = Vector2(300, 9)
	_stamina_bar.fill_color = Color(0.3, 0.52, 0.2)
	_stamina_bar.chip_color = Color(0.75, 0.7, 0.35)
	bars.add_child(_stamina_bar)

	_flask_label = _make_label(18)
	bars.add_child(_flask_label)

	_party_box = VBoxContainer.new()
	_party_box.position = Vector2(40, 150)
	_party_box.add_theme_constant_override("separation", 8)
	root.add_child(_party_box)

	_chat_log = _make_label(17)
	_place(_chat_log, Control.PRESET_BOTTOM_LEFT, Rect2(40, -330, 640, 220))
	_chat_log.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_chat_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_chat_log)

	_chat_edit = LineEdit.new()
	_place(_chat_edit, Control.PRESET_BOTTOM_LEFT, Rect2(40, -100, 640, 36))
	_chat_edit.placeholder_text = "Say something (Enter to send, Esc to cancel)"
	_chat_edit.max_length = 200
	_chat_edit.visible = false
	_chat_edit.text_submitted.connect(_on_chat_submitted)
	_chat_edit.gui_input.connect(_on_chat_input)
	root.add_child(_chat_edit)

	_prompt_label = _make_label(24)
	_place(_prompt_label, Control.PRESET_CENTER_BOTTOM, Rect2(-400, -140, 800, 40))
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.visible = false
	root.add_child(_prompt_label)

	_down_label = _make_label(30)
	_down_label.add_theme_color_override("font_color", Color(0.9, 0.35, 0.3))
	_place(_down_label, Control.PRESET_CENTER, Rect2(-500, 80, 1000, 100))
	_down_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_down_label.visible = false
	root.add_child(_down_label)

	_debug_label = _make_label(18)
	_place(_debug_label, Control.PRESET_BOTTOM_RIGHT, Rect2(-640, -280, 600, 240))
	_debug_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_debug_label.visible = false
	root.add_child(_debug_label)

	_help_label = _make_label(18)
	_help_label.text = HELP_TEXT
	_place(_help_label, Control.PRESET_TOP_RIGHT, Rect2(-720, 36, 680, 640))
	_help_label.visible = false
	root.add_child(_help_label)

	_hint_label = _make_label(18)
	_hint_label.text = "F1: controls"
	_place(_hint_label, Control.PRESET_TOP_RIGHT, Rect2(-240, 36, 200, 30))
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_hint_label)

	_death_label = _make_label(64)
	_death_label.text = "Your light goes out"
	_death_label.add_theme_color_override("font_color", Color(0.6, 0.08, 0.06))
	_place(_death_label, Control.PRESET_CENTER, Rect2(-500, -60, 1000, 120))
	_death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_death_label.visible = false
	root.add_child(_death_label)

	_menu = PanelContainer.new()
	_place(_menu, Control.PRESET_CENTER, Rect2(-180, -90, 360, 180))
	_menu.visible = false
	var menu_box := VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 12)
	_menu.add_child(menu_box)
	var resume := Button.new()
	resume.name = "Resume"
	resume.text = "Resume"
	resume.custom_minimum_size = Vector2(0, 44)
	resume.pressed.connect(func() -> void:
		_menu.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED)
	menu_box.add_child(resume)
	var leave := Button.new()
	leave.text = "Leave game" if Net.mode != Net.Mode.HOST else "Close game (everyone leaves)"
	leave.custom_minimum_size = Vector2(0, 44)
	leave.pressed.connect(func() -> void: Net.leave())
	menu_box.add_child(leave)
	root.add_child(_menu)


## Pin a control to a screen corner (or the center), offset by `rect`.
func _place(c: Control, preset: Control.LayoutPreset, rect: Rect2) -> void:
	c.set_anchors_preset(preset)
	c.offset_left = rect.position.x
	c.offset_top = rect.position.y
	c.offset_right = rect.position.x + rect.size.x
	c.offset_bottom = rect.position.y + rect.size.y


func _make_label(font_size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color(0.9, 0.87, 0.8))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
