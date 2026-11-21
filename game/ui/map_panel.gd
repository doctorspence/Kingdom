class_name MapPanel
extends PanelContainer
## The map (M): the zone seen from above, hidden under fog until you've been
## there. Shows the shrines you found, your party, and you (DESIGN.md 11.4).
## At a shrine it doubles as the fast-travel screen: click a found shrine.

signal travel_chosen(shrine: Shrine)

const MAP_PX := 600.0

var player: Player
## True when opened from a shrine's "Travel" button.
var travel_mode := false

var _title: Label
var _hint: Label
var _canvas: Control
var _ground: TextureRect
var _fog: TextureRect
var _terrain_tex: ImageTexture
var _terrain_for: ZoneTerrain
var _travel_buttons: VBoxContainer
var _refresh_timer := 0.0
var _say_time := 0.0


func _ready() -> void:
	visible = false
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	add_child(root)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	root.add_child(_title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	root.add_child(row)
	_canvas = Control.new()
	_canvas.custom_minimum_size = Vector2(MAP_PX, MAP_PX)
	_canvas.clip_contents = true
	_canvas.gui_input.connect(_on_canvas_input)
	row.add_child(_canvas)
	_ground = TextureRect.new()
	_ground.size = Vector2(MAP_PX, MAP_PX)
	_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_canvas.add_child(_ground)
	# Fog: a black layer that is see-through where you've explored.
	_fog = TextureRect.new()
	_fog.size = Vector2(MAP_PX, MAP_PX)
	_fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fog.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = "shader_type canvas_item;\nvoid fragment() { float seen = texture(TEXTURE, UV).r; COLOR = vec4(0.03, 0.03, 0.035, 1.0 - smoothstep(0.25, 0.75, seen)); }"
	_fog.material = mat
	_canvas.add_child(_fog)
	var markers := Control.new()
	markers.size = Vector2(MAP_PX, MAP_PX)
	markers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	markers.draw.connect(_draw_markers.bind(markers))
	_canvas.add_child(markers)
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(220, 0)
	side.add_theme_constant_override("separation", 8)
	row.add_child(side)
	var legend := Label.new()
	legend.text = "◆ shrine you found\n▲ you\n● party\n\nThe fog lifts as you explore."
	side.add_child(legend)
	_travel_buttons = VBoxContainer.new()
	_travel_buttons.add_theme_constant_override("separation", 6)
	side.add_child(_travel_buttons)
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.modulate = Color(1, 1, 1, 0.7)
	root.add_child(_hint)


func open(p: Player, for_travel := false) -> void:
	player = p
	travel_mode = for_travel
	var z := p.zone()
	if z == null:
		return
	if _terrain_for != z:
		_terrain_for = z
		_terrain_tex = ImageTexture.create_from_image(z.map_image(256))
		_ground.texture = _terrain_tex
	_refresh()
	_build_travel_list()
	visible = true
	if travel_mode and _travel_buttons.get_child_count() > 1:
		(_travel_buttons.get_child(1) as Button).grab_focus()


func close() -> void:
	visible = false


func _refresh() -> void:
	var z := player.zone()
	var key := player.world_key()
	_fog.texture = ImageTexture.create_from_image(player.exploration.fog_image(key))
	_title.text = "%s   —   %d%% explored" % [z.zone_name, roundi(player.exploration.revealed_fraction(key) * 100.0)]
	if _say_time <= 0.0:
		_hint.text = "Click a shrine (or pick one on the right) to travel there.   Esc: close" if travel_mode \
				else "M / Esc: close.   Travel between shrines you've found by resting at one."
	_canvas.get_child(2).queue_redraw()


func _build_travel_list() -> void:
	for c in _travel_buttons.get_children():
		c.queue_free()
	if not travel_mode:
		return
	var header := Label.new()
	header.text = "Travel to:"
	_travel_buttons.add_child(header)
	for s in player.found_shrines():
		var b := Button.new()
		b.text = s.shrine_name
		b.pressed.connect(func() -> void: travel_chosen.emit(s))
		_travel_buttons.add_child(b)


## Show a short message under the map (instead of the big banner, which the map covers).
func say(text: String) -> void:
	_hint.text = text
	_say_time = 3.0


func _process(delta: float) -> void:
	if not visible or player == null or not is_instance_valid(player):
		return
	_say_time -= delta
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 0.5
		_refresh()


## World position -> pixel on the map.
func _to_map(pos: Vector3) -> Vector2:
	var size := _terrain_for.size
	return Vector2((pos.x / size + 0.5) * MAP_PX, (pos.z / size + 0.5) * MAP_PX)


func _draw_markers(c: Control) -> void:
	if player == null or not is_instance_valid(player) or _terrain_for == null:
		return
	var font: Font = ThemeDB.fallback_font
	for s in player.found_shrines():
		var p := _to_map(s.global_position)
		var diamond := PackedVector2Array([p + Vector2(0, -8), p + Vector2(7, 0), p + Vector2(0, 8), p + Vector2(-7, 0)])
		c.draw_colored_polygon(diamond, Color(0.95, 0.72, 0.3))
		c.draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color(0, 0, 0, 0.8), 1.5)
		c.draw_string(font, p + Vector2(10, 5), s.shrine_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.95, 0.88, 0.7))
	for n in get_tree().get_nodes_in_group(&"player"):
		var other := n as Player
		if other == null or other == player:
			continue
		var p := _to_map(other.global_position)
		c.draw_circle(p, 5.0, Color(0.45, 0.75, 1.0))
		c.draw_string(font, p + Vector2(8, 4), other.player_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.75, 0.88, 1.0))
	# You: an arrow pointing where you face.
	var me := _to_map(player.global_position)
	var f := player.model.forward()
	var dir := Vector2(f.x, f.z).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	var side := Vector2(-dir.y, dir.x)
	var arrow := PackedVector2Array([me + dir * 11.0, me - dir * 7.0 + side * 7.0, me - dir * 3.0, me - dir * 7.0 - side * 7.0])
	c.draw_colored_polygon(arrow, Color(1, 1, 1))
	c.draw_polyline(arrow + PackedVector2Array([arrow[0]]), Color(0, 0, 0), 1.5)


func _on_canvas_input(event: InputEvent) -> void:
	# Click a shrine on the map to travel there.
	if not travel_mode or not (event is InputEventMouseButton) or not event.pressed:
		return
	var local: Vector2 = event.position
	for s in player.found_shrines():
		if _to_map(s.global_position).distance_to(local) < 14.0:
			travel_chosen.emit(s)
			_canvas.accept_event()
			return
