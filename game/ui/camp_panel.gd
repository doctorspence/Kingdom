class_name CampPanel
extends PanelContainer
## The Camp menu at the hearth: the three upgrades, their levels, what the
## next level costs. Gold is spent from your own purse; the levels belong to
## the world (everyone sees them).
## Works with mouse, keyboard and gamepad (buttons take focus).

signal closed

var player: Player
var camp: Camp

var _gold: Label
var _status: Label
var _rows := {}  # upgrade id -> {"pips": Label, "buy": Button}
var _message: Label


func _ready() -> void:
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var title := Label.new()
	title.text = "Camp Hearth"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	box.add_child(title)
	_status = Label.new()
	_status.add_theme_color_override("font_color", Color(0.75, 0.72, 0.66))
	box.add_child(_status)
	for kind in Camp.UPGRADES:
		box.add_child(_make_row(kind))
	_gold = Label.new()
	_gold.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	box.add_child(_gold)
	_message = Label.new()
	_message.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4))
	box.add_child(_message)
	var close := Button.new()
	close.name = "Close"
	close.text = "Close"
	close.custom_minimum_size = Vector2(0, 40)
	close.pressed.connect(close_panel)
	box.add_child(close)
	WorldState.flag_changed.connect(func(_k: StringName, _v: Variant) -> void: _refresh())


func _make_row(kind: StringName) -> Control:
	var info: Array = Camp.UPGRADES[kind]
	var row := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	row.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	v.add_child(head)
	var name_label := Label.new()
	name_label.text = info[0]
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.custom_minimum_size = Vector2(150, 0)
	head.add_child(name_label)
	var pips := Label.new()
	pips.add_theme_font_size_override("font_size", 20)
	pips.add_theme_color_override("font_color", Color(0.9, 0.75, 0.35))
	head.add_child(pips)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	var buy := Button.new()
	buy.name = "Buy_%s" % kind
	buy.custom_minimum_size = Vector2(230, 36)
	buy.pressed.connect(func() -> void: _buy(kind))
	head.add_child(buy)
	var desc := Label.new()
	desc.text = info[1]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(560, 0)
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.78, 0.75, 0.68))
	v.add_child(desc)
	_rows[kind] = {"pips": pips, "buy": buy}
	return row


func open(p: Player, c: Camp) -> void:
	player = p
	camp = c
	_message.text = ""
	_refresh()
	visible = true
	var first := _rows[Camp.UPGRADES.keys()[0]]["buy"] as Button
	first.grab_focus()


func close_panel() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _refresh() -> void:
	if player == null or camp == null or not visible and not is_inside_tree():
		return
	for kind in _rows:
		var lv := camp.level(kind)
		(_rows[kind]["pips"] as Label).text = "■".repeat(lv) + "□".repeat(Camp.MAX_LEVEL - lv)
		var buy: Button = _rows[kind]["buy"]
		var cost := camp.next_cost(kind)
		if cost < 0:
			buy.text = "Fully improved"
			buy.disabled = true
		else:
			buy.text = "Improve (%d gold)" % cost
			buy.disabled = player.inventory.gold < cost
	_gold.text = "Your gold: %d" % player.inventory.gold
	_status.text = "Raids repelled: %d%s" % [camp.wins(), "      The hearth is COLD" if camp.is_cold() else ""]


func _buy(kind: StringName) -> void:
	var why := camp.upgrade(kind, player)
	_message.text = why if why != "" else "%s improved" % Camp.UPGRADES[kind][0]
	_refresh()
