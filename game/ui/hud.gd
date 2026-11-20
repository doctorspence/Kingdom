class_name Hud
extends CanvasLayer
## On-screen display: health and stamina bars, lock-on marker, and test helpers.
##   F1 = show controls   F2 = debug info   F3 = equip load   F4 = reset

const HELP_TEXT := """CONTROLS (F1 to hide)
Move: WASD / left stick (tilt gently to walk)
Walk: hold Ctrl
Look: mouse / right stick
Sprint: hold Shift / hold B
Roll: Space / tap B
Jump: F / A
Lock on: Q / click right stick
Switch target: mouse wheel / flick right stick
Free the mouse: Esc (click to grab it again)

TEST KEYS
F2: debug info (invincibility shows as a blue tint)
F3: change equip load (light / medium / heavy / overloaded)
F4: reset to start, full health"""

var player: Player

var _health_bar: ResourceBar
var _stamina_bar: ResourceBar
var _marker: Control
var _debug_label: Label
var _help_label: Label
var _hint_label: Label
var _death_label: Label
var _death_fade := 0.0


func _ready() -> void:
	_build()
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group(&"player") as Player
	if player:
		player.health_changed.connect(_health_bar.set_values)
		player.stamina_changed.connect(_stamina_bar.set_values)
		player.died.connect(_on_died)
		player.respawned.connect(_on_respawned)
		_health_bar.set_values(player.health, player.tuning.max_health)
		_stamina_bar.set_values(player.stamina, player.tuning.max_stamina)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_help"):
		_help_label.visible = not _help_label.visible
		_hint_label.visible = false
	elif event.is_action_pressed("debug_info"):
		_debug_label.visible = not _debug_label.visible
		if player:
			player.show_debug = _debug_label.visible


func _process(delta: float) -> void:
	_marker.queue_redraw()
	if _death_label.visible:
		_death_fade = minf(1.0, _death_fade + delta * 0.8)
		_death_label.modulate.a = _death_fade
	if _debug_label.visible and player:
		_debug_label.text = _debug_text()


func _debug_text() -> String:
	var p := player
	var tier_names := ["light", "medium", "heavy", "OVERLOADED"]
	var speed := Vector2(p.velocity.x, p.velocity.z).length()
	var lines := PackedStringArray([
		"State: %s%s" % [p.state_name(), "  (sprinting)" if p.is_sprinting else ("  (walking)" if p.is_walking else "")],
		"Speed: %.1f m/s" % speed,
		"Health: %d / %d    Stamina: %d / %d" % [p.health, p.tuning.max_health, p.stamina, p.tuning.max_stamina],
		"Equip load: %d%% (%s)   [F3 to change]" % [roundi(p.equip_load * 100.0), tier_names[p.load_tier()]],
		"Invincible: %s" % ("YES" if p.is_invulnerable() else "no"),
		"Last fall: %.1f m" % p.last_fall_height,
		"Lock target: %s" % (p.targeting.target.name if p.targeting.has_target() else "none"),
		"FPS: %d" % Engine.get_frames_per_second(),
	])
	return "\n".join(lines)


func _on_died() -> void:
	_death_fade = 0.0
	_death_label.modulate.a = 0.0
	_death_label.visible = true


func _on_respawned() -> void:
	_death_label.visible = false


func _draw_marker() -> void:
	if player == null or not player.targeting.has_target():
		return
	var cam := player.camera_rig.camera
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

	_debug_label = _make_label(18)
	_place(_debug_label, Control.PRESET_BOTTOM_LEFT, Rect2(40, -260, 700, 220))
	_debug_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_debug_label.visible = false
	root.add_child(_debug_label)

	_help_label = _make_label(18)
	_help_label.text = HELP_TEXT
	_place(_help_label, Control.PRESET_TOP_RIGHT, Rect2(-600, 36, 560, 420))
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
