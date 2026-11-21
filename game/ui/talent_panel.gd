class_name TalentPanel
extends PanelContainer
## The talent tree (T / D-pad left): 3 rows of 4. Row 2 opens after 3 points
## spent, row 3 after 6. Free reset while standing at a shrine.
## Works with mouse, keyboard and gamepad (buttons take focus).

var player: Player

var _grid: GridContainer
var _info: Label
var _points: Label
var _reset: Button


func _ready() -> void:
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	_points = Label.new()
	_points.add_theme_font_size_override("font_size", 22)
	box.add_child(_points)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(_grid)
	_info = Label.new()
	_info.custom_minimum_size = Vector2(760, 70)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_info)
	var row := HBoxContainer.new()
	box.add_child(row)
	_reset = Button.new()
	_reset.text = "Reset talents (only at a shrine)"
	_reset.pressed.connect(_on_reset)
	row.add_child(_reset)
	var close := Button.new()
	close.text = "Close (T)"
	close.pressed.connect(toggle)
	row.add_child(close)


func toggle() -> void:
	visible = not visible
	if visible:
		_rebuild()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if _grid.get_child_count() > 0:
			(_grid.get_child(0) as Button).grab_focus()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _rebuild() -> void:
	for c in _grid.get_children():
		c.queue_free()
	var s := player.stats
	_points.text = "%s talents    Level %d    Points left: %d / %d" % [
			s.class_data.display_name, s.level, s.talent_points_free(), s.talent_points_total()]
	_reset.disabled = not _at_shrine()
	for row in [1, 2, 3]:
		for t in s.class_data.talents:
			if t.row != row:
				continue
			var b := Button.new()
			b.custom_minimum_size = Vector2(180, 56)
			var picked := t.id in s.talents
			b.text = ("[x] " if picked else "") + t.display_name
			b.disabled = not picked and not s.can_pick(t)
			if not s.row_open(row):
				b.text = t.display_name + " (locked)"
			b.focus_entered.connect(_show_info.bind(t))
			b.mouse_entered.connect(_show_info.bind(t))
			b.pressed.connect(_on_pick.bind(t))
			_grid.add_child(b)


func _show_info(t: TalentData) -> void:
	var need := ""
	if t.row == 2:
		need = "  (row 2: spend 3 points first)"
	elif t.row == 3:
		need = "  (row 3: spend 6 points first)"
	_info.text = "%s%s\n%s" % [t.display_name, need, t.description]


func _on_pick(t: TalentData) -> void:
	if player.stats.pick(t):
		_rebuild()


func _on_reset() -> void:
	if _at_shrine():
		player.stats.reset_talents()
		_rebuild()


func _at_shrine() -> bool:
	var thing := player.nearest_interactable()
	return thing is Shrine
