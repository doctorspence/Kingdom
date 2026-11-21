class_name ShopPanel
extends PanelContainer
## Trading with a merchant: Buy, Sell (gold merchants only) and Buy back.

var player: Player
var vendor: Vendor

var _title: Label
var _wallet: Label
var _list: VBoxContainer
var _info: RichTextLabel
var _action: Button
var _tabs: Array[Button] = []
var _mode := "buy"
var _selected: ItemInstance


func _ready() -> void:
	visible = false
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 24)
	root.add_child(_title)
	_wallet = Label.new()
	root.add_child(_wallet)
	var tabs := HBoxContainer.new()
	root.add_child(tabs)
	for m in ["buy", "sell", "buyback"]:
		var b := Button.new()
		b.text = {"buy": "Buy", "sell": "Sell", "buyback": "Buy back"}[m]
		b.toggle_mode = true
		b.pressed.connect(func() -> void:
			_mode = m
			_selected = null
			refresh())
		tabs.add_child(b)
		_tabs.append(b)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	root.add_child(row)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 420)
	row.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var right := VBoxContainer.new()
	row.add_child(right)
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.custom_minimum_size = Vector2(340, 360)
	right.add_child(_info)
	_action = Button.new()
	_action.custom_minimum_size = Vector2(0, 40)
	_action.pressed.connect(_on_action)
	right.add_child(_action)
	var close_b := Button.new()
	close_b.text = "Close (Esc)"
	close_b.pressed.connect(close)
	right.add_child(close_b)


func open(p: Player, v: Vendor) -> void:
	player = p
	vendor = v
	_mode = "buy"
	_selected = null
	if not player.inventory.changed.is_connected(refresh):
		player.inventory.changed.connect(refresh)
	visible = true
	refresh()
	_tabs[0].grab_focus()


func close() -> void:
	visible = false


func refresh() -> void:
	if not visible or vendor == null:
		return
	_tabs[1].disabled = not vendor.data.buys_items
	_tabs[2].disabled = not vendor.data.buys_items
	for i in 3:
		_tabs[i].button_pressed = ["buy", "sell", "buyback"][i] == _mode
	_title.text = "%s — \"%s\"" % [vendor.data.display_name, vendor.data.greeting]
	_wallet.text = "You have %d gold and %d souls." % [player.inventory.gold, player.inventory.souls]
	for c in _list.get_children():
		c.queue_free()
	var items: Array[ItemInstance] = []
	match _mode:
		"buy":
			items = vendor.offers()
		"sell":
			for uid in player.inventory.backpack.items:
				items.append(player.inventory.backpack.items[uid])
		"buyback":
			items = player.inventory.buyback.duplicate()
	for it in items:
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%s   —   %d %s" % [it.display_name(), _price(it), _currency()]
		b.modulate = it.color()
		b.pressed.connect(_select.bind(it))
		b.focus_entered.connect(_select.bind(it))
		_list.add_child(b)
	if items.is_empty():
		var l := Label.new()
		l.text = "Nothing here."
		_list.add_child(l)
	_action.text = {"buy": "Buy", "sell": "Sell", "buyback": "Buy back"}[_mode]
	_action.disabled = _selected == null
	_show()


func _price(it: ItemInstance) -> int:
	return vendor.price_of(it) if _mode == "buy" else it.sell_value()


func _currency() -> String:
	return vendor.currency_name() if _mode == "buy" else "gold"


func _select(it: ItemInstance) -> void:
	_selected = it
	_action.disabled = false
	_show()


func _show() -> void:
	if _selected == null:
		_info.text = "[color=#888]Select an item.[/color]"
		return
	var lines := _selected.describe()
	var text := "[color=#%s][b]%s[/b][/color]" % [_selected.color().to_html(false), lines[0]]
	for i in range(1, lines.size()):
		text += "\n" + lines[i]
	text += "\n\n[b]Price: %d %s[/b]" % [_price(_selected), _currency()]
	_info.text = text


func _on_action() -> void:
	if _selected == null:
		return
	var why := ""
	match _mode:
		"buy":
			why = vendor.buy(player, _selected)
		"sell":
			player.inventory.sell(_selected.uid)
		"buyback":
			why = player.inventory.buy_back(_selected.uid)
	if why != "":
		CombatFx.word(player.global_position + Vector3.UP * 2.0, why)
	_selected = null
	refresh()
