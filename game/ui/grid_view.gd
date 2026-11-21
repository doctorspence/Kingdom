class_name GridView
extends Control
## Draws an ItemGrid (backpack or bank). Mouse: left-click selects, right-click
## does the main action. Keyboard/gamepad: arrows / D-pad move the cursor,
## Enter / A selects, the panel's buttons act on the selection.

signal selected(item: ItemInstance)
signal activated(item: ItemInstance)

const CELL := 46.0

var grid: ItemGrid
var cursor := Vector2i.ZERO
var title := ""


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_grid(g: ItemGrid) -> void:
	grid = g
	custom_minimum_size = Vector2(g.width * CELL, g.height * CELL + 22)
	queue_redraw()


func current() -> ItemInstance:
	return grid.item_at(cursor) if grid else null


func _gui_input(event: InputEvent) -> void:
	if grid == null:
		return
	if event is InputEventMouseButton and event.pressed:
		var cell := Vector2i(floori(event.position.x / CELL), floori((event.position.y - 22) / CELL))
		if cell.x >= 0 and cell.y >= 0 and cell.x < grid.width and cell.y < grid.height:
			cursor = cell
			grab_focus()
			selected.emit(current())
			if event.button_index == MOUSE_BUTTON_RIGHT or event.double_click:
				if current():
					activated.emit(current())
			queue_redraw()
			accept_event()
		return
	var move := Vector2i.ZERO
	if event.is_action_pressed("ui_left"):
		move = Vector2i.LEFT
	elif event.is_action_pressed("ui_right"):
		move = Vector2i.RIGHT
	elif event.is_action_pressed("ui_up"):
		move = Vector2i.UP
	elif event.is_action_pressed("ui_down"):
		move = Vector2i.DOWN
	elif event.is_action_pressed("ui_accept"):
		if current():
			activated.emit(current())
		accept_event()
		return
	if move != Vector2i.ZERO:
		var next := cursor + move
		if next.x < 0 or next.x >= grid.width or next.y < 0 or next.y >= grid.height:
			return  # let focus leave the grid (to buttons next to it)
		cursor = next
		selected.emit(current())
		queue_redraw()
		accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT:
		queue_redraw()


func _draw() -> void:
	if grid == null:
		return
	var font := get_theme_default_font()
	draw_string(font, Vector2(0, 16), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.85, 0.82, 0.75))
	var top := Vector2(0, 22)
	for y in grid.height:
		for x in grid.width:
			var r := Rect2(top + Vector2(x, y) * CELL, Vector2(CELL, CELL))
			draw_rect(r.grow(-1), Color(0.1, 0.1, 0.11, 0.9))
	for uid in grid.items:
		var it: ItemInstance = grid.items[uid]
		var p: Vector2i = grid.positions[uid]
		var r := Rect2(top + Vector2(p) * CELL, Vector2(it.base.grid_size) * CELL).grow(-3)
		draw_rect(r, it.base.icon_color.darkened(0.3))
		draw_rect(r, it.color(), false, 2.0)
		var short := it.display_name().get_slice(" ", it.display_name().get_slice_count(" ") - 1).left(7)
		draw_string(font, r.position + Vector2(4, 16), short, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 6, 12, Color(1, 1, 1, 0.95))
		if it.count > 1:
			draw_string(font, r.position + Vector2(4, r.size.y - 4), "x%d" % it.count, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 0.8))
	if has_focus():
		var c := Rect2(top + Vector2(cursor) * CELL, Vector2(CELL, CELL))
		var it := current()
		if it:
			c = Rect2(top + Vector2(grid.positions[it.uid]) * CELL, Vector2(it.base.grid_size) * CELL)
		draw_rect(c, Color(1.0, 0.9, 0.5), false, 3.0)
