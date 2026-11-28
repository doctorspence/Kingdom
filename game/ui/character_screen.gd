class_name CharacterScreen
extends Control
## The menu "book": a tab bar on top (Character, Inventory, Map, Talents, Quests,
## System) over a torch-lit stone backdrop. The Inventory page shows the
## backpack grid (left), your character on a pedestal with the gear slots around
## it (middle) and your stats (right), all at once.
##
## This file only shows things and passes your clicks on: the rules for what fits
## and what can be worn live in Inventory and ItemGrid.
##
## Mouse: drag items; right-click or the wheel turns a carried item, right-click
##   (or double-click) equips or uses. Hover shows the item card.
## Keyboard / gamepad: arrows / D-pad move; Enter / A equips; hold Enter / A to
##   pick an item up, then A puts it down, R / Y turns it, Esc / B cancels.
##   I or Tab / View opens and closes it; Q E / LB RB change tab, [ ] / LT RT change filter, C / X compare,
##   Del / Y drop, J / L3 mark junk, Z / R3 sort, X (key) swaps weapon sets.

signal page_requested(page: String)
signal close_requested

const PAGES := ["character", "inventory", "map", "talents", "quests", "system"]
const PAGE_TITLES := ["Character", "Inventory", "Map", "Talents", "Quests", "System"]
## Pages drawn here (the others are panels the HUD lays over the backdrop).
const OWN_PAGES := ["character", "inventory", "quests"]

const STAGE := Vector2(1920, 1080)
const LEFT := Rect2(48, 92, 900, 790)
const FOOTER := Rect2(98, 898, 800, 56)
const CENTER := Rect2(976, 92, 600, 862)
const RIGHT := Rect2(1594, 92, 288, 862)
const PREVIEW := Rect2(990, 106, 572, 834)  # the 3D view fills the middle frame; the slots sit over it
const GRID_POS := Vector2(98, 290)
const GRID_AREA := Vector2(800, 486)
const SLOT := 84.0
const SLOT_TOP := 170.0
const SLOT_STEP := 124.0
const LEFT_SLOTS := ["head", "shoulders", "chest", "hands", "legs", "feet"]
const RIGHT_SLOTS := ["neck", "ring1", "main", "off", "cloak"]
const SLOT_NAMES := {"head": "Helmet", "shoulders": "Shoulders", "chest": "Chest armor", "hands": "Gloves",
		"legs": "Legs", "feet": "Boots", "neck": "Necklace", "ring1": "Ring", "main": "Main hand",
		"off": "Off hand", "cloak": "Utility (cloak)"}
## A faint picture in each empty slot.
const EMPTY_ICONS := {"head": &"item_kettle_helm", "shoulders": &"item_leather_pauldrons", "chest": &"item_platebody",
		"hands": &"item_mail_gauntlets", "legs": &"item_plate_legs", "feet": &"item_leather_boots",
		"neck": &"item_bone_amulet", "ring1": &"item_iron_ring", "main": &"item_bronze_sword",
		"off": &"item_kite_shield", "cloak": &"item_tattered_cloak"}
## Filter tabs: [title, category (-1 = all, -2 = junk), icon item].
const FILTERS := [
	["All Items", -1, &""],
	["Weapons", ItemData.Category.WEAPON, &"item_bronze_sword"],
	["Off Hand", ItemData.Category.OFF_HAND, &"item_kite_shield"],
	["Armor", ItemData.Category.ARMOR, &"item_chainmail_body"],
	["Jewelry", ItemData.Category.JEWELRY, &"item_iron_ring"],
	["Consumables", ItemData.Category.CONSUMABLE, &"item_health_potion"],
	["Junk", -2, &""],
]
const HOLD_TO_MOVE := 0.4

var player: Player
var page := "inventory"

var _stage: Control
var _grid: Control
var _preview: CharacterPreview
var _set_toggle: Control
var _overlay: Control
var _slots := {}  # slot name (LEFT_SLOTS / RIGHT_SLOTS) -> Control
var _filter := 0
var _cell := 80.0
var _cursor := Vector2i.ZERO
var _sel_slot := ""  # a slot name when a slot (not the grid) is selected
var _hover_uid := ""
var _hover_slot := ""
var _mouse := Vector2.ZERO  # stage coordinates
var _compare := false
# Carrying an item (drag and drop, or "hold A" on a gamepad). The item stays
# where it is until it's put down, so cancelling can't lose anything.
var _carry: ItemInstance
var _carry_from := ""  # "grid" or a real slot key ("head", "main1"...)
var _carry_rot := false
var _carry_grab := Vector2.ZERO
var _carry_pad := false
var _press_uid := ""
var _press_slot := ""
var _press_pos := Vector2.ZERO
var _accept_held := -1.0
var _msg := ""
var _msg_time := 0.0
var _pad := false
## The last thing you used was the keyboard (so the selection shows its card, not just the mouse hover).
var _nav_keys := false
var _ps_pad := false
var _hits := []  # [Rect2, Callable] clickable areas drawn on the stage
var _time := 0.0
var _glow: GradientTexture2D
var _vignette: GradientTexture2D
var _stone: Texture2D = preload("res://assets/textures_painted/stonewall/color.png")


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_glow = _radial([Color(1.0, 0.6, 0.25, 0.55), Color(1.0, 0.45, 0.15, 0.0)])
	_vignette = _radial([Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.82)], 0.42)

	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_CENTER)
	_stage.offset_left = -STAGE.x * 0.5
	_stage.offset_top = -STAGE.y * 0.5
	_stage.offset_right = STAGE.x * 0.5
	_stage.offset_bottom = STAGE.y * 0.5
	_stage.mouse_filter = Control.MOUSE_FILTER_PASS
	_stage.draw.connect(_draw_stage)
	_stage.gui_input.connect(_on_stage_input)
	add_child(_stage)

	_grid = Control.new()
	_grid.position = GRID_POS
	_grid.size = GRID_AREA
	_grid.focus_mode = Control.FOCUS_ALL
	_grid.draw.connect(_draw_grid)
	_grid.gui_input.connect(_on_grid_input)
	_grid.focus_entered.connect(func() -> void:
		_sel_slot = ""
		_redraw())
	_grid.focus_exited.connect(_redraw)
	_grid.mouse_exited.connect(func() -> void:
		_hover_uid = ""
		_redraw())
	_stage.add_child(_grid)

	_preview = CharacterPreview.new()
	_preview.position = PREVIEW.position
	_preview.size = PREVIEW.size
	_stage.add_child(_preview)

	for i in LEFT_SLOTS.size():
		_add_slot(LEFT_SLOTS[i], Vector2(CENTER.position.x + 26, SLOT_TOP + i * SLOT_STEP))
	for i in RIGHT_SLOTS.size():
		_add_slot(RIGHT_SLOTS[i], Vector2(CENTER.end.x - 26 - SLOT, SLOT_TOP + i * SLOT_STEP))
	_set_toggle = Control.new()
	_set_toggle.position = Vector2(CENTER.end.x - 26 - SLOT, SLOT_TOP + 5 * SLOT_STEP)
	_set_toggle.size = Vector2(SLOT, SLOT)
	_set_toggle.focus_mode = Control.FOCUS_ALL
	_set_toggle.tooltip_text = ""
	_set_toggle.draw.connect(_draw_set_toggle)
	_set_toggle.focus_entered.connect(_redraw)
	_set_toggle.focus_exited.connect(_redraw)
	_set_toggle.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or e.is_action_pressed("ui_accept"):
			_swap_sets()
			_set_toggle.accept_event())
	_stage.add_child(_set_toggle)

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	_stage.add_child(_overlay)


func _add_slot(slot_name: String, pos: Vector2) -> void:
	var c := Control.new()
	c.position = pos
	c.size = Vector2(SLOT, SLOT)
	c.focus_mode = Control.FOCUS_ALL
	c.draw.connect(_draw_slot.bind(slot_name, c))
	c.gui_input.connect(_on_slot_input.bind(slot_name, c))
	c.focus_entered.connect(func() -> void:
		_sel_slot = slot_name
		_redraw())
	c.focus_exited.connect(_redraw)
	c.mouse_entered.connect(func() -> void:
		_hover_slot = slot_name
		_redraw())
	c.mouse_exited.connect(func() -> void:
		if _hover_slot == slot_name:
			_hover_slot = ""
		_redraw())
	_stage.add_child(c)
	_slots[slot_name] = c


static func _radial(colors: Array, start := 0.0) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, colors[0])
	g.set_color(1, colors[1])
	g.set_offset(0, start)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	return t


# --- Opening, pages ------------------------------------------------------------

func open(p: Player, which := "inventory") -> void:
	player = p
	if not player.inventory.changed.is_connected(_on_changed):
		player.inventory.changed.connect(_on_changed)
	visible = true
	set_page(which)


func close() -> void:
	_cancel_carry()
	visible = false


func set_page(which: String) -> void:
	page = which
	var own := page in OWN_PAGES
	_grid.visible = page == "inventory"
	_preview.visible = own
	_set_toggle.visible = own
	for s in _slots:
		_slots[s].visible = own
	_cancel_carry()
	_layout_grid()
	if own and player:
		_preview.show_player(player)
	if page == "inventory":
		_grid.grab_focus()
	elif own:
		_slots["head"].grab_focus()
	_redraw()


func _on_changed() -> void:
	if not visible:
		return
	_layout_grid()
	if player:
		_preview.show_player(player)
	_redraw()


## Cell size so the backpack fills its area (the bank grows, the backpack may too).
func _layout_grid() -> void:
	if player == null:
		return
	var g := _backpack()
	_cell = floorf(minf(GRID_AREA.x / g.width, GRID_AREA.y / g.height))
	_grid.size = Vector2(g.width, g.height) * _cell
	_cursor = _cursor.clamp(Vector2i.ZERO, Vector2i(g.width - 1, g.height - 1))


func _redraw() -> void:
	_stage.queue_redraw()
	_grid.queue_redraw()
	_overlay.queue_redraw()
	_set_toggle.queue_redraw()
	for s in _slots:
		_slots[s].queue_redraw()


func _say(text: String) -> void:
	_msg = text
	_msg_time = 3.0
	_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	if _msg_time > 0.0:
		_msg_time -= delta
		if _msg_time <= 0.0:
			_redraw()
	if _accept_held >= 0.0:
		_accept_held += delta
		if _accept_held >= HOLD_TO_MOVE:
			_accept_held = -1.0
			var it := _backpack().item_at(_cursor) if _grid.has_focus() else null
			if it and _carry == null:
				_start_carry(it, "grid", true)
	queue_redraw()  # torch flicker on the backdrop
	if _grid.has_focus() or _accept_held >= 0.0:
		_grid.queue_redraw()  # the pulsing cursor
	if _carry:
		for s in _slots:
			_slots[s].queue_redraw()


# --- Helpers -------------------------------------------------------------------

func _inv() -> Inventory:
	return player.inventory


func _backpack() -> ItemGrid:
	return player.inventory.backpack


## "main" / "off" are the active weapon set's hands.
func _real_slot(slot_name: String) -> String:
	if slot_name == "main" or slot_name == "off":
		return "%s%d" % [slot_name, _inv().active_set]
	return slot_name


func _slot_item(slot_name: String) -> ItemInstance:
	return _inv().equipped.get(_real_slot(slot_name))


func _selected() -> ItemInstance:
	if _sel_slot != "":
		return _slot_item(_sel_slot)
	return _backpack().item_at(_cursor)


func _matches_filter(it: ItemInstance) -> bool:
	var f: int = FILTERS[_filter][1]
	if f == -1:
		return true
	if f == -2:
		return it.junk
	return it.base.category() == f


func _cell_rect(cell: Vector2i, size: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * _cell, Vector2(size) * _cell)


func _equipped_like(it: ItemInstance) -> ItemInstance:
	var options := _inv().slots_for(it)
	if options.is_empty():
		return null
	var worn: ItemInstance = _inv().equipped.get(options[0])
	return worn if worn != it else null


func _pad_label(action: String) -> String:
	if not _pad:
		return {"equip": "Enter", "compare": "C", "drop": "Del", "sort": "Z", "junk": "J", "rotate": "R",
				"cancel": "Esc", "tab_prev": "Q", "tab_next": "E", "filter_prev": "[", "filter_next": "]"}[action]
	if _ps_pad:
		return {"equip": "✕", "compare": "□", "drop": "△", "sort": "R3", "junk": "L3", "rotate": "△",
				"cancel": "○", "tab_prev": "L1", "tab_next": "R1", "filter_prev": "L2", "filter_next": "R2"}[action]
	return {"equip": "A", "compare": "X", "drop": "Y", "sort": "R3", "junk": "L3", "rotate": "Y",
			"cancel": "B", "tab_prev": "LB", "tab_next": "RB", "filter_prev": "LT", "filter_next": "RT"}[action]


# --- Actions -------------------------------------------------------------------

func _equip_or_use() -> void:
	if _sel_slot != "":
		var it0 := _slot_item(_sel_slot)
		if it0 == null:
			return
		var why0 := _inv().unequip(_real_slot(_sel_slot))
		if why0 != "":
			_say(why0)
		else:
			Audio.sfx(&"equip")
		return
	var it := _backpack().item_at(_cursor)
	if it == null:
		return
	var why := ""
	if it.base.use_effect != &"":
		why = player.use_item(it.uid)
	elif it.base.is_equipment():
		var options := _inv().slots_for(it)
		why = _inv().equip(it.uid, options[0] if not options.is_empty() else "")
		if why == "":
			Audio.sfx(&"equip")
	else:
		why = "Can't be equipped"
	if why != "":
		_say(why)


func _drop_selected() -> void:
	if _sel_slot != "":
		_say("Take it off first")
		return
	var it := _backpack().item_at(_cursor)
	if it:
		player.drop_item(it.uid)
		_say("Dropped %s" % it.display_name())


func _toggle_junk() -> void:
	var it := _backpack().item_at(_cursor) if _sel_slot == "" else null
	if it == null:
		_say("Only backpack items can be junk")
		return
	_inv().toggle_junk(it.uid)
	Audio.sfx(&"ui_click")


func _sort() -> void:
	var why := _inv().sort_backpack()
	if why != "":
		_say(why)
	else:
		Audio.sfx(&"ui_click")
		_cursor = Vector2i.ZERO


func _swap_sets() -> void:
	_inv().swap_weapon_set()
	Audio.sfx(&"equip")
	_say("Weapon set %s" % ("I" if _inv().active_set == 1 else "II"))


func _cycle_filter(step: int) -> void:
	_filter = wrapi(_filter + step, 0, FILTERS.size())
	Audio.sfx(&"ui_click")
	_redraw()


func _cycle_page(step: int) -> void:
	var i := PAGES.find(page)
	page_requested.emit(PAGES[wrapi(i + step, 0, PAGES.size())])


# --- Carrying (drag and drop) ------------------------------------------------------

func _start_carry(it: ItemInstance, from: String, by_pad: bool) -> void:
	_carry = it
	_carry_from = from
	_carry_rot = _backpack().is_rotated(it.uid) if from == "grid" else false
	_carry_pad = by_pad
	if from == "grid":
		var p: Vector2i = _backpack().positions[it.uid]
		_carry_grab = (_press_pos - GRID_POS) - Vector2(p) * _cell
		if by_pad:
			_cursor = p
	else:
		var fp := ItemGrid.footprint(it, false)
		_carry_grab = Vector2(fp) * _cell * 0.5
	Audio.sfx(&"ui_click")
	_redraw()


func _cancel_carry() -> void:
	_carry = null
	_carry_from = ""
	_carry_pad = false
	_press_uid = ""
	_press_slot = ""
	_redraw()


func _rotate_carry() -> void:
	if _carry == null:
		return
	var s := _carry.base.grid_size
	if s.x == s.y:
		_say("That doesn't need turning")
		return
	_carry_rot = not _carry_rot
	# keep the grab point inside the turned shape
	_carry_grab = Vector2(_carry_grab.y, _carry_grab.x)
	_clamp_carry()
	Audio.sfx(&"ui_click")
	_redraw()


## Keep a gamepad-carried item whole inside the grid.
func _clamp_carry() -> void:
	if _carry and _carry_pad:
		var fp := ItemGrid.footprint(_carry, _carry_rot)
		var g := _backpack()
		_cursor = _cursor.clamp(Vector2i.ZERO, Vector2i(maxi(g.width - fp.x, 0), maxi(g.height - fp.y, 0)))


## Where the carried item would land on the grid (top-left cell).
func _carry_target() -> Vector2i:
	if _carry_pad:
		return _cursor
	var top_left := _mouse - GRID_POS - _carry_grab
	return Vector2i(roundi(top_left.x / _cell), roundi(top_left.y / _cell))


func _over_grid(stage_pos: Vector2) -> bool:
	var g := _backpack()
	return Rect2(GRID_POS, Vector2(g.width, g.height) * _cell).grow(_cell * 0.5).has_point(stage_pos)


func _slot_at(stage_pos: Vector2) -> String:
	for s in _slots:
		if (_slots[s] as Control).get_rect().grow(6).has_point(stage_pos):
			return s
	return ""


## Put the carried item down at the cursor (pad) or under the mouse.
func _put_down(target_slot := "") -> void:
	if _carry == null:
		return
	var it := _carry
	var from := _carry_from
	var why := ""
	if target_slot == "" and not _carry_pad:
		target_slot = _slot_at(_mouse)
	if target_slot != "":
		var real := _real_slot(target_slot)
		if from == "grid":
			if not (real in _inv().slots_for(it)):
				why = "That doesn't go there" if it.base.is_equipment() else "That can't be worn"
			else:
				why = _inv().equip(it.uid, real)
				if why == "":
					Audio.sfx(&"equip")
		elif from != real:
			why = "That doesn't go there"
	elif _carry_pad or _over_grid(_mouse):
		var at := _carry_target()
		if from == "grid":
			var under_cell := _cursor if _carry_pad else Vector2i(((_mouse - GRID_POS) / _cell).floor())
			var under := _backpack().item_at(under_cell)
			if under and under != it and under.base == it.base and it.base.stack_max > 1:
				why = _inv().move_in_backpack(it.uid, _backpack().positions[under.uid])
			else:
				why = _inv().move_in_backpack(it.uid, at, _carry_rot)
		else:
			why = _inv().unequip_to(from, at, _carry_rot)
			if why == "":
				Audio.sfx(&"equip")
		if why == "":
			_cursor = at
			_sel_slot = ""
	else:
		_cancel_carry()
		return
	if why != "":
		_say(why)
		if not _carry_pad:
			_cancel_carry()
		return
	Audio.sfx(&"ui_click")
	_cancel_carry()


# --- Input ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not visible or player == null:
		return
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		if not _pad:
			_pad = true
			var jn := Input.get_joy_name(event.device).to_lower()
			_ps_pad = jn.contains("ps") or jn.contains("dualsense") or jn.contains("dualshock") or jn.contains("sony")
			_redraw()
	elif (event is InputEventKey or event is InputEventMouseButton) and _pad:
		_pad = false
		_redraw()
	if event is InputEventKey and event.pressed and not _nav_keys:
		_nav_keys = true
		_redraw()
	if event is InputEventMouseMotion:
		_mouse = _stage.get_global_transform().affine_inverse() * event.global_position
		if _nav_keys and event.relative.length() > 3.0:
			_nav_keys = false
			_redraw()
		if _carry and not _carry_pad:
			_redraw()
	if event.is_action_pressed("menu_tab_prev"):
		_cycle_page(-1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("menu_tab_next"):
		_cycle_page(1)
		get_viewport().set_input_as_handled()
		return
	# I / Tab / View: close from the Inventory page, jump to it from any other page.
	# (Caught here, before Tab would move the focus between buttons.)
	if event.is_action_pressed("inventory") and not Net.typing:
		if page == "inventory":
			close_requested.emit()
		else:
			page_requested.emit("inventory")
		get_viewport().set_input_as_handled()
		return
	if not (page in OWN_PAGES):
		return
	var handled := true
	if event.is_action_pressed("ui_cancel") and _carry:
		_cancel_carry()
	elif event.is_action_pressed("ui_cancel") and event is InputEventJoypadButton:
		close_requested.emit()
	elif page != "inventory":
		handled = false
	elif event.is_action_pressed("menu_filter_prev"):
		_cycle_filter(-1)
	elif event.is_action_pressed("menu_filter_next"):
		_cycle_filter(1)
	elif event.is_action_pressed("inv_rotate") and _carry:
		_rotate_carry()
	elif event.is_action_pressed("inv_drop"):
		if _carry:
			_rotate_carry()
		else:
			_drop_selected()
	elif _carry:
		handled = false
	elif event.is_action_pressed("inv_compare"):
		_compare = not _compare
		Audio.sfx(&"ui_click")
		_redraw()
	elif event.is_action_pressed("inv_junk"):
		_toggle_junk()
	elif event.is_action_pressed("inv_sort"):
		_sort()
	elif event.is_action_pressed("swap_weapons") and event is InputEventKey:
		_swap_sets()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()


func _on_stage_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for h in _hits:
			if (h[0] as Rect2).has_point(event.position):
				(h[1] as Callable).call()
				_stage.accept_event()
				return
		if _carry and not _carry_pad:
			_cancel_carry()


func _on_grid_input(event: InputEvent) -> void:
	var g := _backpack()
	if event is InputEventMouseMotion:
		var cell := Vector2i((event.position / _cell).floor())
		var it := g.item_at(cell)
		var uid := it.uid if it else ""
		if uid != _hover_uid:
			_hover_uid = uid
			_redraw()
		if _press_uid != "" and _carry == null and (GRID_POS + event.position).distance_to(_press_pos) > 8.0:
			var pressed: ItemInstance = g.items.get(_press_uid)
			if pressed:
				_start_carry(pressed, "grid", false)
		return
	if event is InputEventMouseButton:
		var cell2 := Vector2i((event.position / _cell).floor())
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _carry:
					_put_down()
				else:
					_cursor = cell2.clamp(Vector2i.ZERO, Vector2i(g.width - 1, g.height - 1))
					_sel_slot = ""
					_grid.grab_focus()
					var it2 := g.item_at(_cursor)
					_press_uid = it2.uid if it2 else ""
					_press_pos = GRID_POS + event.position
					if event.double_click and it2:
						_press_uid = ""
						_equip_or_use()
			else:
				_press_uid = ""
				if _carry and not _carry_pad:
					_put_down()
			_redraw()
			_grid.accept_event()
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			if _carry:
				_rotate_carry()
			else:
				_cursor = cell2.clamp(Vector2i.ZERO, Vector2i(g.width - 1, g.height - 1))
				_sel_slot = ""
				_equip_or_use()
			_grid.accept_event()
		elif event.pressed and _carry and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			_rotate_carry()
			_grid.accept_event()
		return
	# keyboard / gamepad
	if event.is_action_pressed("ui_accept"):
		if _carry:
			_put_down()
		else:
			_accept_held = 0.0
		_grid.accept_event()
		return
	if event.is_action_released("ui_accept"):
		if _accept_held >= 0.0:
			_accept_held = -1.0
			_equip_or_use()
		_grid.accept_event()
		return
	var move := Vector2i.ZERO
	if event.is_action_pressed("ui_left", true):
		move = Vector2i.LEFT
	elif event.is_action_pressed("ui_right", true):
		move = Vector2i.RIGHT
	elif event.is_action_pressed("ui_up", true):
		move = Vector2i.UP
	elif event.is_action_pressed("ui_down", true):
		move = Vector2i.DOWN
	if move == Vector2i.ZERO:
		return
	_accept_held = -1.0
	var next := _cursor + move
	# Skip over the rest of a big item, so one press leaves it.
	var here := g.item_at(_cursor)
	if here and not _carry:
		var p: Vector2i = g.positions[here.uid]
		var s := g.size_of(here.uid)
		if move.x > 0:
			next.x = p.x + s.x
		elif move.x < 0:
			next.x = p.x - 1
		elif move.y > 0:
			next.y = p.y + s.y
		elif move.y < 0:
			next.y = p.y - 1
	# a carried item has to stay whole inside the grid
	var fp := ItemGrid.footprint(_carry, _carry_rot) if _carry and _carry_pad else Vector2i.ONE
	if next.x < 0 or next.y < 0 or next.x + fp.x > g.width or next.y + fp.y > g.height:
		return  # let focus move on to the slots
	_cursor = next
	_sel_slot = ""
	_redraw()
	_grid.accept_event()


func _on_slot_input(event: InputEvent, slot_name: String, c: Control) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if _carry:
				_put_down(slot_name)
			else:
				_sel_slot = slot_name
				c.grab_focus()
				_press_slot = slot_name if _slot_item(slot_name) else ""
				_press_pos = c.position + event.position
				if event.double_click and _slot_item(slot_name):
					_press_slot = ""
					_equip_or_use()
			_redraw()
			c.accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_press_slot = ""
			if _carry and not _carry_pad:
				_put_down()
			c.accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if _carry:
				_rotate_carry()
			else:
				_sel_slot = slot_name
				_equip_or_use()
			c.accept_event()
		return
	if event is InputEventMouseMotion and _press_slot != "" and _carry == null:
		if (c.position + event.position).distance_to(_press_pos) > 8.0:
			var it := _slot_item(_press_slot)
			if it:
				_start_carry(it, _real_slot(_press_slot), false)
		return
	if event.is_action_pressed("ui_accept"):
		if _carry:
			_put_down(slot_name)
		else:
			_sel_slot = slot_name
			_equip_or_use()
		c.accept_event()


# --- Drawing: backdrop -----------------------------------------------------------------

func _draw() -> void:
	var r := get_rect()
	draw_rect(Rect2(Vector2.ZERO, r.size), Color(0.03, 0.028, 0.025))
	# dark stone wall
	var tile := 512.0
	var y := 0.0
	while y < r.size.y:
		var x := 0.0
		while x < r.size.x:
			draw_texture_rect(_stone, Rect2(x, y, tile, tile), false, Color(0.16, 0.14, 0.12))
			x += tile
		y += tile
	# two torches high on the wall, flickering
	var cx := r.size.x * 0.5
	for side in [-1.0, 1.0]:
		var p := Vector2(cx + side * minf(r.size.x * 0.5 - 60.0, 1010.0), r.size.y * 0.2)
		var f := 1.0 + sin(_time * 8.0 + side) * 0.06 + sin(_time * 21.0 + side * 3.0) * 0.04
		var gs := 900.0 * f
		draw_texture_rect(_glow, Rect2(p - Vector2(gs, gs) * 0.5, Vector2(gs, gs)), false, Color(1, 1, 1, 0.8))
		_draw_flame(p, f)
	draw_texture_rect(_vignette, Rect2(Vector2(-r.size.x * 0.15, -r.size.y * 0.2), r.size * Vector2(1.3, 1.4)), false)
	# the tab bar band runs the full width of any screen
	var bar_y := _stage.position.y
	draw_rect(Rect2(0, bar_y, r.size.x, 64), Color(0.02, 0.018, 0.016, 0.92))
	draw_rect(Rect2(0, bar_y + 62, r.size.x, 2), Color(0, 0, 0, 0.8))
	UiStyle.rule(self, Vector2(60, bar_y + 64), Vector2(r.size.x - 60, bar_y + 64), UiStyle.GOLD, 1.5)


func _draw_flame(p: Vector2, f: float) -> void:
	# sconce
	draw_colored_polygon(PackedVector2Array([p + Vector2(-16, 18), p + Vector2(16, 18), p + Vector2(8, 34), p + Vector2(-8, 34)]), Color(0.16, 0.12, 0.08))
	draw_rect(Rect2(p + Vector2(-4, 34), Vector2(8, 40)), Color(0.12, 0.09, 0.06))
	for layer in [[26.0, Color(1.0, 0.45, 0.1, 0.55)], [18.0, Color(1.0, 0.68, 0.25, 0.85)], [10.0, Color(1.0, 0.92, 0.65, 0.95)]]:
		var w: float = layer[0] * 0.55
		var h: float = layer[0] * 1.7 * f
		var sway := sin(_time * 6.0 + layer[0]) * 3.0
		draw_colored_polygon(PackedVector2Array([p + Vector2(-w, 16), p + Vector2(w, 16), p + Vector2(w * 0.5, 16 - h * 0.5), p + Vector2(sway, 16 - h), p + Vector2(-w * 0.5, 16 - h * 0.5)]), layer[1])


# --- Drawing: the stage -------------------------------------------------------------------

func _draw_stage() -> void:
	_hits.clear()
	_draw_tabs()
	if not (page in OWN_PAGES) or player == null:
		return
	UiStyle.frame(_stage, LEFT)
	match page:
		"inventory":
			_draw_inventory_frame()
		"character":
			_draw_character_sheet()
		"quests":
			_draw_quests()
	UiStyle.frame(_stage, CENTER)
	# a dark recess behind the 3D view
	_stage.draw_rect(PREVIEW.grow(3), Color(0, 0, 0, 0.8))
	UiStyle.frame(_stage, RIGHT, false, UiStyle.PANEL)
	_draw_stats()


func _draw_tabs() -> void:
	var w := STAGE.x
	var gap := 190.0
	var x0 := w * 0.5 - gap * (PAGES.size() - 1) * 0.5
	for i in PAGES.size():
		var cx := x0 + gap * i
		var title: String = PAGE_TITLES[i]
		var on: bool = PAGES[i] == page
		var tw := UiStyle.text_width(title, 30)
		if on:
			var gs := Vector2(tw + 120, 70)
			_stage.draw_texture_rect(_glow, Rect2(Vector2(cx, 62) - gs * 0.5, gs), false, Color(1, 0.85, 0.5, 0.55))
			UiStyle.rule(_stage, Vector2(cx - tw * 0.5 - 26, 62), Vector2(cx + tw * 0.5 + 26, 62), UiStyle.GOLD_BRIGHT, 3.0)
			UiStyle.diamond(_stage, Vector2(cx, 63), 5, UiStyle.GOLD_BRIGHT)
		UiStyle.text(_stage, Vector2(cx - tw * 0.5, 42), title, 30, UiStyle.IVORY if on else UiStyle.IVORY_DIM)
		_hits.append([Rect2(cx - gap * 0.5, 0, gap, 64), func() -> void:
			if PAGES[i] != page:
				Audio.sfx(&"ui_click")
				page_requested.emit(PAGES[i])])
	var lb := _pad_label("tab_prev")
	var rb := _pad_label("tab_next")
	UiStyle.badge(_stage, Vector2(x0 - gap * 0.5 - 70, 18), lb, 17)
	UiStyle.badge(_stage, Vector2(x0 + gap * (PAGES.size() - 1) + gap * 0.5 + 30, 18), rb, 17)


func _draw_inventory_frame() -> void:
	# filter tabs
	var tw := 78.0
	var gap := 12.0
	var total := FILTERS.size() * tw + (FILTERS.size() - 1) * gap
	var x := LEFT.get_center().x - total * 0.5
	var ty := 120.0
	var lt := _pad_label("filter_prev")
	if lt != "":
		UiStyle.badge(_stage, Vector2(x - 62, ty + 20), lt, 16)
	UiStyle.badge(_stage, Vector2(x + total + 16, ty + 20), _pad_label("filter_next"), 16)
	for i in FILTERS.size():
		var r := Rect2(x + i * (tw + gap), ty, tw, 66)
		var on := i == _filter
		if on:
			_stage.draw_rect(r.grow(2), Color(0, 0, 0, 0.7))
			_stage.draw_rect(r, Color(0.62, 0.52, 0.38))
			_stage.draw_rect(r.grow(-3), Color(0.78, 0.68, 0.52))
			_stage.draw_rect(r, UiStyle.GOLD_BRIGHT, false, 2.0)
		var icon_id: StringName = FILTERS[i][2]
		var item := ItemDB.get_item(icon_id) if icon_id != &"" else null
		var col := Color(1, 1, 1) if on else Color(0.85, 0.8, 0.72, 0.85)
		if item and item.icon:
			UiStyle.item_icon(_stage, item.icon, r.grow(-8), col)
		else:
			var label := "All" if FILTERS[i][1] == -1 else "Junk"
			UiStyle.text(_stage, Vector2(r.position.x, r.get_center().y + 9), label, 24,
					Color(0.15, 0.1, 0.05) if on else UiStyle.IVORY_DIM, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		if i < FILTERS.size() - 1:
			UiStyle.diamond(_stage, Vector2(r.end.x + gap * 0.5, r.get_center().y), 3, Color(UiStyle.GOLD, 0.6))
		_hits.append([r, _set_filter.bind(i)])
	UiStyle.rule(_stage, Vector2(LEFT.position.x + 40, 204), Vector2(LEFT.end.x - 40, 204), UiStyle.GOLD, 1.5)
	# title, load, souls, coins
	UiStyle.text(_stage, Vector2(LEFT.position.x + 48, 256), FILTERS[_filter][0], 36)
	var inv := _inv()
	var cap := Inventory.load_capacity(player.stats.strength())
	var tier := player.load_tier()
	var load_col: Color = [UiStyle.IVORY, UiStyle.IVORY, Color(1.0, 0.78, 0.45), UiStyle.BAD][tier]
	UiStyle.weight_icon(_stage, Vector2(480, 242), 1.15)
	UiStyle.text(_stage, Vector2(500, 254), "%.1f / %.0f" % [inv.equipped_weight(), cap], 26, load_col)
	var coins_txt := _thousands(inv.coins)
	var cw := UiStyle.text_width(coins_txt, 26)
	UiStyle.text(_stage, Vector2(LEFT.end.x - 80 - cw, 254), coins_txt, 26)
	UiStyle.coin_icon(_stage, Vector2(LEFT.end.x - 60, 240), 1.0)
	var souls_txt := _thousands(inv.souls)
	var sw := UiStyle.text_width(souls_txt, 26)
	var sx := LEFT.end.x - 80 - cw - 50 - sw
	UiStyle.soul_icon(_stage, Vector2(sx - 22, 244), 1.0)
	UiStyle.text(_stage, Vector2(sx, 254), souls_txt, 26, Color(0.8, 0.88, 1.0))
	UiStyle.rule(_stage, Vector2(LEFT.position.x + 40, 276), Vector2(LEFT.end.x - 40, 276), UiStyle.GOLD, 1.5)
	# a line under the grid: messages, or what you're doing
	var line_y := GRID_POS.y + _grid.size.y + 42
	if _msg_time > 0.0:
		UiStyle.text(_stage, Vector2(LEFT.position.x, line_y), _msg, 22, Color(1.0, 0.8, 0.55), HORIZONTAL_ALIGNMENT_CENTER, LEFT.size.x)
	else:
		var hint := ""
		if _carry:
			hint = ("%s place   ·   %s turn   ·   %s cancel" % [_pad_label("equip"), _pad_label("rotate"), _pad_label("cancel")]) if _carry_pad \
					else "Release to place   ·   right-click or wheel to turn   ·   drop it on a slot to wear it"
		else:
			hint = ("Hold %s to move an item" % _pad_label("equip")) if _pad else "Drag items to move them   ·   double- or right-click to equip   ·   drag the figure to turn it"
		UiStyle.text(_stage, Vector2(LEFT.position.x, line_y), hint, 19, UiStyle.MUTED, HORIZONTAL_ALIGNMENT_CENTER, LEFT.size.x)
	_draw_footer()


func _set_filter(i: int) -> void:
	_filter = i
	Audio.sfx(&"ui_click")
	_redraw()


func _draw_footer() -> void:
	UiStyle.frame(_stage, FOOTER, false, Color(0.06, 0.054, 0.048, 0.96))
	var sel := _selected()
	var actions := []
	if _carry:
		actions = [["equip", "Place", func() -> void: _put_down()], ["rotate", "Turn", _rotate_carry], ["cancel", "Cancel", _cancel_carry]]
	else:
		var equip_word := "Equip"
		if _sel_slot != "":
			equip_word = "Unequip"
		elif sel and sel.base.use_effect != &"":
			equip_word = "Use"
		actions = [["equip", equip_word, _equip_or_use],
				["compare", "Compare" if not _compare else "Compare: on", func() -> void:
					_compare = not _compare
					_redraw()],
				["drop", "Drop", _drop_selected],
				["sort", "Sort", _sort],
				["junk", "Unmark Junk" if sel and sel.junk else "Mark Junk", _toggle_junk]]
	var widths := []
	var total := 0.0
	for a in actions:
		var w := 34.0 + 8.0 + UiStyle.text_width(a[1], 21)
		widths.append(w)
		total += w
	var spacing := 34.0
	total += spacing * (actions.size() - 1)
	var x := FOOTER.get_center().x - total * 0.5
	for i in actions.size():
		var a: Array = actions[i]
		var label := _pad_label(a[0])
		var round := _pad and label.length() <= 1
		var bw := UiStyle.badge(_stage, Vector2(x, FOOTER.position.y + 14), label, 15, round)
		var dim: bool = not _carry and sel == null and a[0] in ["equip", "drop", "junk"]
		UiStyle.text(_stage, Vector2(x + bw + 8, FOOTER.position.y + 36), a[1], 21, UiStyle.MUTED if dim else UiStyle.IVORY)
		_hits.append([Rect2(x, FOOTER.position.y, widths[i], FOOTER.size.y), a[2]])
		x += maxf(widths[i], bw + 8 + UiStyle.text_width(a[1], 21)) + spacing


func _draw_character_sheet() -> void:
	var s := player.stats
	var x0 := LEFT.position.x + 60
	# Level and class lead; the name sits under them, labelled, so a default
	# name like "Player 1" can't be read as a level.
	var title := "Level %d %s" % [s.level, s.class_data.display_name]
	UiStyle.text(_stage, Vector2(x0, 160), title, 40)
	var line := "Known as %s" % (player.player_name if player.player_name != "" else "no one")
	if s.subclass:
		line += "  ·  " + s.subclass.display_name
	UiStyle.text(_stage, Vector2(x0, 200), line, 24, UiStyle.GOLD)
	UiStyle.rule(_stage, Vector2(LEFT.position.x + 40, 228), Vector2(LEFT.end.x - 40, 228))
	var load_names := ["Light (quick rolls)", "Medium", "Heavy (slow rolls)", "Overloaded"]
	var w := player.weapon
	var rows := [
		["Experience", "%d / %d to level %d" % [s.xp, s.xp_to_next(), s.level + 1]],
		["Talent points", "%d free of %d" % [s.talent_points_free(), s.talent_points_total()]],
		["Weapon damage", "%d" % roundi(player.weapon_damage())],
		["Critical chance", "%.1f%%" % (s.crit_chance(w) * 100.0)],
		["Ability power", "%d%%" % roundi(s.ability_power() * 100.0)],
		["Balance (poise)", "%d" % roundi(player.max_poise())],
		["Armor", "%d" % roundi(s.armor())],
		["Equip load", "%.1f / %.0f   %s" % [_inv().equipped_weight(), Inventory.load_capacity(s.strength()), load_names[player.load_tier()]]],
		["Weapon set", "I" if _inv().active_set == 1 else "II"],
		["Coins", _thousands(_inv().coins)],
		["Souls", _thousands(_inv().souls)],
	]
	var y := 280.0
	for r in rows:
		UiStyle.text(_stage, Vector2(x0, y), r[0], 24, UiStyle.IVORY_DIM)
		UiStyle.text(_stage, Vector2(x0, y), r[1], 24, UiStyle.IVORY, HORIZONTAL_ALIGNMENT_RIGHT, LEFT.size.x - 120)
		y += 50.0
	UiStyle.text(_stage, Vector2(LEFT.position.x, LEFT.end.y - 40), "Your soul is bound to the old shrines.", 20, UiStyle.MUTED, HORIZONTAL_ALIGNMENT_CENTER, LEFT.size.x)


func _draw_quests() -> void:
	UiStyle.text(_stage, Vector2(LEFT.position.x + 60, 160), "Quests", 40)
	UiStyle.rule(_stage, Vector2(LEFT.position.x + 40, 190), Vector2(LEFT.end.x - 40, 190))
	UiStyle.text(_stage, Vector2(LEFT.position.x, LEFT.get_center().y), "No one has asked anything of you yet.", 26,
			UiStyle.IVORY_DIM, HORIZONTAL_ALIGNMENT_CENTER, LEFT.size.x)


func _draw_stats() -> void:
	var s := player.stats
	var r := RIGHT
	var cx := r.get_center().x
	UiStyle.text(_stage, Vector2(r.position.x, 150), "Level %d" % s.level, 32, UiStyle.IVORY, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var cls := s.class_data.display_name + ("  ·  " + s.subclass.display_name if s.subclass else "")
	UiStyle.text(_stage, Vector2(r.position.x, 178), cls, 19, UiStyle.GOLD, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	# experience bar
	var bar := Rect2(r.position.x + 34, 194, r.size.x - 68, 12)
	var frac := clampf(float(s.xp) / maxf(s.xp_to_next(), 1.0), 0.0, 1.0)
	_stage.draw_rect(bar.grow(2), Color(0, 0, 0, 0.8))
	_stage.draw_rect(bar, Color(0.14, 0.12, 0.1))
	_stage.draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), Color(0.85, 0.66, 0.32))
	_stage.draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, 4)), Color(1, 0.9, 0.6, 0.6))
	_stage.draw_rect(bar.grow(1), UiStyle.GOLD, false, 1.0)
	UiStyle.diamond(_stage, Vector2(bar.position.x - 6, bar.get_center().y), 6, UiStyle.GOLD)
	UiStyle.diamond(_stage, Vector2(bar.end.x + 6, bar.get_center().y), 6, UiStyle.GOLD)
	var w := player.weapon
	var groups := [
		[["strength", "Strength", "%d" % roundi(s.strength())],
		 ["agility", "Agility", "%d" % roundi(s.agility())],
		 ["intellect", "Intellect", "%d" % roundi(s.intellect())],
		 ["vitality", "Vitality", "%d" % roundi(s.vitality())]],
		[["attack", "Attack", "%d" % roundi(player.weapon_damage())],
		 ["defense", "Defense", "%d" % roundi(s.armor())],
		 ["power", "Ability Power", "%d%%" % roundi(s.ability_power() * 100.0)],
		 ["crit", "Critical", "%.1f%%" % (s.crit_chance(w) * 100.0)]],
		[["health", "Health", "%d / %d" % [roundi(player.health), roundi(player.max_health())]],
		 ["stamina", "Stamina", "%d / %d" % [roundi(player.stamina), roundi(player.max_stamina())]],
		 ["resource", s.class_data.resource_label, "%d / %d" % [roundi(player.caster.resource), roundi(s.resource_max())]]],
	]
	var y := 236.0
	for gi in groups.size():
		UiStyle.rule(_stage, Vector2(r.position.x + 24, y), Vector2(r.end.x - 24, y))
		y += 22.0
		for row in groups[gi]:
			var col := s.class_data.resource_color if row[0] == "resource" else UiStyle.GOLD
			UiStyle.glyph(_stage, row[0], Vector2(r.position.x + 40, y + 16), col)
			UiStyle.text(_stage, Vector2(r.position.x + 62, y + 24), row[1], 22)
			UiStyle.text(_stage, Vector2(r.position.x, y + 24), row[2], 22, UiStyle.IVORY, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 30)
			y += 44.0
		y += 12.0
	UiStyle.rule(_stage, Vector2(r.position.x + 24, y), Vector2(r.end.x - 24, y))


static func _thousands(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.right(3) + out
		s = s.left(s.length() - 3)
	return ("-" if n < 0 else "") + s + out


# --- Drawing: grid, slots -------------------------------------------------------------------

func _draw_grid() -> void:
	if player == null:
		return
	var g := _backpack()
	var c := _grid
	c.draw_rect(Rect2(Vector2.ZERO, Vector2(g.width, g.height) * _cell).grow(4), Color(0, 0, 0, 0.75))
	for y in g.height:
		for x in g.width:
			UiStyle.well(c, _cell_rect(Vector2i(x, y), Vector2i.ONE).grow(-1.5))
	# where a carried item would land
	if _carry and (_carry_pad or _over_grid(_mouse)) and _slot_at(_mouse) == "" :
		var at := _carry_target()
		var fp := ItemGrid.footprint(_carry, _carry_rot)
		var ok := false
		if _carry_from == "grid":
			var under := g.item_at(_cursor if _carry_pad else Vector2i(((_mouse - GRID_POS) / _cell).floor()))
			ok = g.can_place(_carry, at, _carry.uid, _carry_rot) or (under and under != _carry and under.base == _carry.base and _carry.base.stack_max > 1)
		else:
			ok = g.can_place(_carry, at, "", _carry_rot)
		var pr := _cell_rect(at, fp).intersection(Rect2(Vector2.ZERO, Vector2(g.width, g.height) * _cell))
		c.draw_rect(pr.grow(-2), Color(0.4, 0.9, 0.35, 0.22) if ok else Color(0.95, 0.3, 0.2, 0.25))
		c.draw_rect(pr.grow(-2), Color(0.5, 1.0, 0.45, 0.8) if ok else Color(1.0, 0.4, 0.3, 0.8), false, 2.0)
	for uid in g.items:
		var it: ItemInstance = g.items[uid]
		var r := _cell_rect(g.positions[uid], g.size_of(uid)).grow(-3)
		var faded := (_carry == it) or not _matches_filter(it)
		_draw_item(c, it, r, 0.3 if faded else 1.0)
		if uid == _hover_uid and _carry == null:
			c.draw_rect(r.grow(1), Color(UiStyle.GOLD_BRIGHT, 0.7), false, 2.0)
	if _carry and _carry_pad:
		var fp2 := ItemGrid.footprint(_carry, _carry_rot)
		_draw_item(c, _carry, _cell_rect(_cursor, fp2).grow(-3), 0.85)
	if c.has_focus() and _carry == null:
		var it2 := g.item_at(_cursor)
		var cr := _cell_rect(_cursor, Vector2i.ONE)
		if it2:
			cr = _cell_rect(g.positions[it2.uid], g.size_of(it2.uid))
		var pulse := 0.75 + 0.25 * sin(_time * 5.0)
		c.draw_rect(cr.grow(-1), Color(UiStyle.GOLD_BRIGHT, pulse), false, 3.0)
		c.draw_rect(cr.grow(2), Color(UiStyle.GOLD_BRIGHT, 0.25 * pulse), false, 3.0)
	if _accept_held > 0.05:
		var cr2 := _cell_rect(_cursor, Vector2i.ONE)
		c.draw_arc(cr2.get_center(), _cell * 0.3, -PI * 0.5, -PI * 0.5 + TAU * _accept_held / HOLD_TO_MOVE, 24, UiStyle.GOLD_BRIGHT, 4.0)


## One item: rarity-tinted well, icon, rarity border, stack count, junk mark.
func _draw_item(c: CanvasItem, it: ItemInstance, r: Rect2, alpha := 1.0) -> void:
	var rc := it.color()
	var bg := Color(0.1, 0.09, 0.08).lerp(rc, 0.0 if it.rarity == ItemInstance.Rarity.COMMON else 0.22)
	bg = bg.darkened(0.35)
	c.draw_rect(r, Color(bg, 0.92 * alpha))
	# a soft lighter middle
	c.draw_rect(r.grow(-r.size.x * 0.18), Color(1, 1, 1, 0.025 * alpha))
	var icon_rect := r.grow(-4)
	if it.base.icon:
		UiStyle.item_icon(c, it.base.icon, icon_rect, Color(1, 1, 1, alpha))
	else:
		c.draw_rect(icon_rect.grow(-6), Color(it.base.icon_color, 0.6 * alpha))
		UiStyle.text(c, Vector2(r.position.x, r.get_center().y + 6), it.display_name().get_slice(" ", 0), 15,
				Color(UiStyle.IVORY, alpha), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var border := Color(rc, 0.95 * alpha) if it.rarity > ItemInstance.Rarity.COMMON else Color(0.55, 0.5, 0.42, 0.8 * alpha)
	c.draw_rect(r, border, false, 2.0)
	if it.rarity >= ItemInstance.Rarity.RARE:
		c.draw_rect(r.grow(-3), Color(rc, 0.25 * alpha), false, 2.0)
	if it.count > 1:
		var n := str(it.count)
		UiStyle.text(c, Vector2(r.end.x - 6 - UiStyle.text_width(n, 22, UiStyle.serif_bold()), r.end.y - 6), n, 22,
				Color(UiStyle.IVORY, alpha), HORIZONTAL_ALIGNMENT_LEFT, -1, UiStyle.serif_bold())
	if it.junk:
		var jp := r.position + Vector2(4, 4)
		c.draw_rect(Rect2(jp, Vector2(36, 18)), Color(0.35, 0.08, 0.05, 0.9 * alpha))
		UiStyle.text(c, jp + Vector2(0, 14), "junk", 14, Color(1, 0.75, 0.65, alpha), HORIZONTAL_ALIGNMENT_CENTER, 36)


func _draw_slot(slot_name: String, c: Control) -> void:
	if player == null:
		return
	var r := Rect2(Vector2.ZERO, c.size)
	var valid := _carry != null and _carry_from == "grid" and _real_slot(slot_name) in _inv().slots_for(_carry)
	var lit := c.has_focus() or _hover_slot == slot_name or valid
	UiStyle.slot(c, r, lit)
	var it := _slot_item(slot_name)
	if it and _carry != it:
		_draw_item(c, it, r.grow(-4))
	elif it:
		_draw_item(c, it, r.grow(-4), 0.3)
	else:
		var ghost := ItemDB.get_item(EMPTY_ICONS.get(slot_name, &""))
		if ghost and ghost.icon:
			UiStyle.item_icon(c, ghost.icon, r.grow(-10), Color(0.55, 0.48, 0.38, 0.28))
		else:
			UiStyle.text(c, Vector2(0, r.get_center().y + 6), SLOT_NAMES[slot_name], 13, UiStyle.MUTED, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	if valid:
		var pulse := 0.5 + 0.5 * sin(_time * 6.0)
		c.draw_rect(r.grow(2), Color(0.5, 1.0, 0.45, 0.4 + 0.4 * pulse), false, 3.0)
	if slot_name == "off":
		var main := _slot_item("main")
		if main and main.base.weapon and main.base.weapon.two_handed and it == null:
			UiStyle.text(c, Vector2(0, r.end.y - 8), "two-handed", 13, UiStyle.MUTED, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func _draw_set_toggle() -> void:
	if player == null:
		return
	var c := _set_toggle
	var r := Rect2(Vector2.ZERO, c.size)
	UiStyle.slot(c, r, c.has_focus())
	UiStyle.text(c, Vector2(0, 26), "Weapon set", 14, UiStyle.IVORY_DIM, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	for i in 2:
		var on := _inv().active_set == i + 1
		var pr := Rect2(8 + i * 36, 36, 32, 28)
		c.draw_rect(pr, Color(0.6, 0.48, 0.3) if on else Color(0.12, 0.1, 0.09))
		c.draw_rect(pr, UiStyle.GOLD_BRIGHT if on else UiStyle.CELL_EDGE, false, 1.5)
		UiStyle.text(c, Vector2(pr.position.x, pr.position.y + 21), "I" if i == 0 else "II", 18,
				Color(0.12, 0.08, 0.04) if on else UiStyle.IVORY_DIM, HORIZONTAL_ALIGNMENT_CENTER, pr.size.x)
	if not _pad:
		UiStyle.text(c, Vector2(0, r.end.y - 4), "X", 13, UiStyle.MUTED, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


# --- Drawing: item card and carried item ----------------------------------------------------------

func _draw_overlay() -> void:
	if player == null or not (page in OWN_PAGES):
		return
	if _carry and not _carry_pad:
		var fp := ItemGrid.footprint(_carry, _carry_rot)
		var r := Rect2(_mouse - _carry_grab, Vector2(fp) * _cell).grow(-3)
		_overlay.draw_rect(r.grow(6), Color(0, 0, 0, 0.35))
		_draw_item(_overlay, _carry, r, 0.92)
		return
	if _carry:
		return
	# Which item to describe: the one under the mouse, else the selection.
	var it: ItemInstance = null
	var anchor := Rect2()
	var g := _backpack()
	if _hover_uid != "" and g.items.has(_hover_uid):
		it = g.items[_hover_uid]
		anchor = Rect2(GRID_POS + Vector2(g.positions[_hover_uid]) * _cell, Vector2(g.size_of(_hover_uid)) * _cell)
	elif _hover_slot != "":
		it = _slot_item(_hover_slot)
		anchor = (_slots[_hover_slot] as Control).get_rect()
		if it == null:
			_slot_label(_hover_slot)
	elif _sel_slot != "" and (_slots[_sel_slot] as Control).has_focus() and (_pad or _nav_keys):
		it = _slot_item(_sel_slot)
		anchor = (_slots[_sel_slot] as Control).get_rect()
		if it == null:
			_slot_label(_sel_slot)
	elif _grid.has_focus() and _grid.visible and (_pad or _nav_keys):
		it = g.item_at(_cursor)
		if it:
			anchor = Rect2(GRID_POS + Vector2(g.positions[it.uid]) * _cell, Vector2(g.size_of(it.uid)) * _cell)
	if it == null:
		return
	var worn := _equipped_like(it) if _sel_slot == "" or _hover_uid != "" else null
	var card := _card_lines(it, worn)
	var size := _card_size(card)
	var pos := Vector2(anchor.end.x + 14, anchor.position.y)
	if pos.x + size.x > STAGE.x - 20:
		pos.x = anchor.position.x - 14 - size.x
	pos.y = clampf(pos.y, 80, STAGE.y - size.y - 20)
	_draw_card(card, Rect2(pos, size))
	if _compare and worn:
		var wc := _card_lines(worn, null, "Equipped")
		var ws := _card_size(wc)
		var wp := Vector2(pos.x + size.x + 10, pos.y)
		if wp.x + ws.x > STAGE.x - 20:
			wp.x = pos.x - ws.x - 10
		_draw_card(wc, Rect2(wp, ws))


func _slot_label(slot_name: String) -> void:
	var r := (_slots[slot_name] as Control).get_rect()
	var text_s: String = SLOT_NAMES[slot_name] + " (empty)"
	var w := UiStyle.text_width(text_s, 20) + 28
	var at := Vector2(r.end.x + 10, r.position.y + 22) if r.position.x < CENTER.get_center().x else Vector2(r.position.x - 10 - w, r.position.y + 22)
	var box := Rect2(at, Vector2(w, 40))
	_overlay.draw_rect(box, Color(0.05, 0.045, 0.04, 0.95))
	_overlay.draw_rect(box, Color(UiStyle.GOLD, 0.8), false, 1.5)
	UiStyle.text(_overlay, at + Vector2(14, 27), text_s, 20, UiStyle.IVORY_DIM)


## The card's lines: [text, size, color, kind] (kind "rule" draws a divider).
func _card_lines(it: ItemInstance, worn: ItemInstance, heading := "") -> Array:
	var L := []
	var rc := it.color()
	if heading != "":
		L.append([heading.to_upper(), 15, UiStyle.MUTED, ""])
	L.append([it.display_name(), 28, rc, "title"])
	var kind := ItemData.slot_name(it.base.slot)
	if it.base.shield:
		kind = "Shield"
	L.append(["%s  ·  %s" % [ItemInstance.RARITY_NAMES[it.rarity], kind], 19, Color(rc, 0.85), ""])
	L.append(["", 0, Color.WHITE, "rule"])
	var w := it.base.weapon
	if w:
		var dmg := roundi(w.damage * it.scale())
		var delta := ""
		if worn and worn.base.weapon:
			delta = _delta(dmg - roundi(worn.base.weapon.damage * worn.scale()))
		L.append(["Damage  %d%s" % [dmg, delta], 24, UiStyle.IVORY, "big"])
		L.append(["Attack speed  %s%s" % [it.attack_speed(), "   ·   Two-handed" if w.two_handed else ""], 19, UiStyle.IVORY_DIM, ""])
	if it.base.shield:
		var sh := it.base.shield
		L.append(["Blocks  %d%%" % roundi(sh.block_reduction * 100.0), 24, UiStyle.IVORY, "big"])
		L.append(["Stability  %s" % ("high" if sh.stamina_per_damage < 0.5 else ("low" if sh.stamina_per_damage > 0.7 else "medium")), 19, UiStyle.IVORY_DIM, ""])
	if it.armor() > 0.0:
		var a := roundi(it.armor())
		var d2 := _delta(a - roundi(worn.armor())) if worn else ""
		L.append(["Defense  %d%s" % [a, d2], 24 if w == null and it.base.shield == null else 19, UiStyle.IVORY, "big" if w == null else ""])
	var bonus_names := {"strength": "Strength", "agility": "Agility", "intellect": "Intellect", "vitality": "Vitality"}
	for k in it.base.stats:
		L.append([_stat_text(k, float(it.base.stats[k]) * it.scale(), bonus_names), 19, UiStyle.GOOD, ""])
	for k in it.bonuses:
		if k == "armor":
			L.append(["+%d defense" % roundi(float(it.bonuses[k])), 19, UiStyle.GOOD, ""])
		else:
			L.append([_stat_text(k, float(it.bonuses[k]), bonus_names), 19, UiStyle.GOOD, ""])
	if it.base.legendary_text != "":
		L.append([it.base.legendary_text, 19, ItemInstance.RARITY_COLORS[4], "wrap"])
	if it.base.use_effect != &"":
		var use_txt: String = {"cure_poison": "Use: cures poison", "cure_frost": "Use: cures frost",
				"heal": "Use: heals %d" % roundi(it.base.use_amount),
				"heal_percent": "Use: heals %d%% of your health" % roundi(it.base.use_amount * 100.0)}.get(String(it.base.use_effect), "Use")
		L.append([use_txt, 19, UiStyle.GOOD, ""])
	L.append(["", 0, Color.WHITE, "rule"])
	var lvl_ok := player.stats.level >= it.base.required_level
	L.append(["Requires level %d" % it.base.required_level, 18, UiStyle.IVORY_DIM if lvl_ok else UiStyle.BAD, ""])
	L.append(["Weight %.1f      Value %s coins%s" % [it.base.weight * it.count, _thousands(it.sell_value()), "   ×%d" % it.count if it.count > 1 else ""], 18, UiStyle.IVORY_DIM, ""])
	if it.junk:
		L.append(["Marked as junk", 17, Color(1, 0.65, 0.55), ""])
	if it.base.flavor != "":
		L.append(["\"%s\"" % it.base.flavor, 17, UiStyle.MUTED, "wrap"])
	if worn and not _compare and heading == "":
		L.append(["%s compare with what you wear" % _pad_label("compare"), 15, UiStyle.MUTED, ""])
	return L


func _stat_text(k: String, v: float, names: Dictionary) -> String:
	if names.has(k):
		return "+%d %s" % [roundi(v), names[k]]
	return ItemInstance._stat_line(k, v)


static func _delta(d: int) -> String:
	if d == 0:
		return ""
	return "   (%s%d)" % ["+" if d > 0 else "", d]


const CARD_W := 380.0


func _card_size(lines: Array) -> Vector2:
	var h := 24.0
	for l in lines:
		h += _line_height(l)
	return Vector2(CARD_W, h + 10)


func _line_height(l: Array) -> float:
	if l[3] == "rule":
		return 14.0
	if l[3] == "wrap":
		var n := ceili(UiStyle.text_width(l[0], l[1]) / (CARD_W - 44.0))
		return (l[1] + 8.0) * maxi(n, 1)
	return l[1] + 10.0


func _draw_card(lines: Array, r: Rect2) -> void:
	var c := _overlay
	c.draw_rect(r.grow(8), Color(0, 0, 0, 0.35))
	c.draw_rect(r, Color(0.055, 0.05, 0.045, 0.97))
	c.draw_rect(r, UiStyle.GOLD_DARK, false, 3.0)
	c.draw_rect(r.grow(-1), UiStyle.GOLD, false, 1.2)
	for corner in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
		UiStyle.diamond(c, corner, 5, UiStyle.GOLD)
	var y := r.position.y + 16
	for l in lines:
		var h := _line_height(l)
		if l[3] == "rule":
			UiStyle.rule(c, Vector2(r.position.x + 18, y + 7), Vector2(r.end.x - 18, y + 7), UiStyle.GOLD, 1.0)
		elif l[3] == "wrap":
			c.draw_multiline_string(UiStyle.serif(), Vector2(r.position.x + 22, y + l[1]), l[0], HORIZONTAL_ALIGNMENT_LEFT,
					r.size.x - 44, l[1], -1, l[2])
		else:
			var font := UiStyle.serif_bold() if l[3] == "title" else UiStyle.serif()
			UiStyle.text(c, Vector2(r.position.x + 22, y + l[1]), l[0], l[1], l[2], HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 44, font)
		y += h
