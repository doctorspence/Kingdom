class_name InventoryPanel
extends PanelContainer
## Inventory + character (I / View button): your equipment slots, the backpack
## grid, item details compared with what you're wearing, gold, souls, weight.

var player: Player

var _slot_buttons := {}  # slot key -> Button
var _grid: GridView
var _info: RichTextLabel
var _summary: Label
var _use_button: Button
var _drop_button: Button
var _selected: ItemInstance
var _selected_slot := ""


func _ready() -> void:
	visible = false
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var header := Label.new()
	header.text = "Inventory"
	header.add_theme_font_size_override("font_size", 24)
	root.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	root.add_child(row)

	var slots := VBoxContainer.new()
	slots.add_theme_constant_override("separation", 3)
	row.add_child(slots)
	for s in Inventory.SLOTS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(250, 30)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.pressed.connect(_on_slot_pressed.bind(s))
		b.focus_entered.connect(_on_slot_pressed.bind(s))
		slots.add_child(b)
		_slot_buttons[s] = b

	var middle := VBoxContainer.new()
	row.add_child(middle)
	_grid = GridView.new()
	_grid.title = "Backpack"
	_grid.selected.connect(_on_grid_selected)
	_grid.activated.connect(func(_it: ItemInstance) -> void: _on_use())
	middle.add_child(_grid)
	var actions := HBoxContainer.new()
	middle.add_child(actions)
	_use_button = _button("Equip / Use", _on_use)
	actions.add_child(_use_button)
	_drop_button = _button("Drop", _on_drop)
	actions.add_child(_drop_button)
	actions.add_child(_button("Swap weapon set", func() -> void:
		player.inventory.swap_weapon_set()))
	actions.add_child(_button("Close (I)", close))
	_summary = Label.new()
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.custom_minimum_size = Vector2(460, 0)
	middle.add_child(_summary)

	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.custom_minimum_size = Vector2(330, 520)
	_info.fit_content = false
	row.add_child(_info)


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(action)
	return b


func open(p: Player) -> void:
	player = p
	if not player.inventory.changed.is_connected(refresh):
		player.inventory.changed.connect(refresh)
	visible = true
	refresh()
	_grid.grab_focus()


func close() -> void:
	visible = false


func refresh() -> void:
	if not visible or player == null:
		return
	var inv := player.inventory
	for s in _slot_buttons:
		var b: Button = _slot_buttons[s]
		var it: ItemInstance = inv.equipped.get(s)
		var active: bool = not (s.begins_with("main") or s.begins_with("off")) or s.right(1) == str(inv.active_set)
		b.text = "%s: %s" % [Inventory.SLOT_LABELS[s], it.display_name() if it else "—"]
		b.modulate = (it.color() if it else Color(0.7, 0.7, 0.7)) * (Color(1, 1, 1) if active else Color(0.6, 0.6, 0.6))
	_grid.set_grid(inv.backpack)
	var s := player.stats
	var load_names := ["light", "medium", "heavy", "OVERLOADED"]
	_summary.text = "Gold %d    Souls %d\nWeight %.1f  (%d%% — %s rolls)    Armor %d\nStr %d  Agi %d  Int %d  Vit %d    Weapon set %d" % [
			inv.gold, inv.souls, inv.equipped_weight(), roundi(player.equip_load * 100.0), load_names[player.load_tier()],
			roundi(s.armor()), roundi(s.strength()), roundi(s.agility()), roundi(s.intellect()), roundi(s.vitality()), inv.active_set]
	_show(_selected)


func _on_grid_selected(it: ItemInstance) -> void:
	_selected = it
	_selected_slot = ""
	_show(it)


func _on_slot_pressed(slot: String) -> void:
	_selected_slot = slot
	_selected = player.inventory.equipped.get(slot)
	_show(_selected)


func _show(it: ItemInstance) -> void:
	_use_button.text = "Unequip" if _selected_slot != "" else ("Use" if it and it.base.use_effect != &"" else "Equip")
	_drop_button.disabled = _selected_slot != "" or it == null
	if it == null:
		_info.text = "[color=#888]Select an item.[/color]"
		return
	var text := _describe(it)
	# Compare with what's worn in the same slot.
	if _selected_slot == "":
		var options := player.inventory.slots_for(it)
		if not options.is_empty():
			var worn: ItemInstance = player.inventory.equipped.get(options[0])
			if worn:
				text += "\n\n[color=#999]Currently equipped:[/color]\n" + _describe(worn)
	_info.text = text


func _describe(it: ItemInstance) -> String:
	var lines := it.describe()
	var out := "[color=#%s][b]%s[/b][/color]" % [it.color().to_html(false), lines[0]]
	for i in range(1, lines.size()):
		out += "\n" + lines[i]
	return out


func _on_use() -> void:
	if _selected_slot != "":
		var why := player.inventory.unequip(_selected_slot)
		if why != "":
			CombatFx.word(player.global_position + Vector3.UP * 2.0, why)
		_selected = null
		_selected_slot = ""
		refresh()
		return
	if _selected == null:
		return
	var why2 := ""
	if _selected.base.use_effect != &"":
		why2 = player.use_item(_selected.uid)
	else:
		why2 = player.inventory.equip(_selected.uid)
		if why2 == "":
			Audio.sfx(&"equip")
	if why2 != "":
		CombatFx.word(player.global_position + Vector3.UP * 2.0, why2)
	_selected = _grid.current()
	refresh()


func _on_drop() -> void:
	if _selected and _selected_slot == "":
		player.drop_item(_selected.uid)
		_selected = null
		refresh()
