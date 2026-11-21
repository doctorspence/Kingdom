class_name BankPanel
extends PanelContainer
## The bank at a shrine: safe storage that travels with your character and is
## never lost on death. Select an item and it moves between backpack and bank.

var player: Player

var _backpack: GridView
var _bank: GridView
var _info: Label
var _row_button: Button


func _ready() -> void:
	visible = false
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var header := Label.new()
	header.text = "Bank  (safe: never lost when you die)"
	header.add_theme_font_size_override("font_size", 24)
	root.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	root.add_child(row)
	_backpack = GridView.new()
	_backpack.title = "Backpack (Enter / right-click: move to bank)"
	_backpack.activated.connect(_move)
	row.add_child(_backpack)
	_bank = GridView.new()
	_bank.title = "Bank (Enter / right-click: move to backpack)"
	_bank.activated.connect(_move)
	row.add_child(_bank)
	var bottom := HBoxContainer.new()
	root.add_child(bottom)
	_info = Label.new()
	bottom.add_child(_info)
	_row_button = Button.new()
	_row_button.pressed.connect(func() -> void:
		var why := player.inventory.buy_bank_row()
		if why != "":
			CombatFx.word(player.global_position + Vector3.UP * 2.0, why))
	bottom.add_child(_row_button)
	var close_b := Button.new()
	close_b.text = "Close (Esc)"
	close_b.pressed.connect(close)
	bottom.add_child(close_b)


func open(p: Player) -> void:
	player = p
	if not player.inventory.changed.is_connected(refresh):
		player.inventory.changed.connect(refresh)
	visible = true
	refresh()
	_backpack.grab_focus()


func close() -> void:
	visible = false


func refresh() -> void:
	if not visible or player == null:
		return
	var inv := player.inventory
	_backpack.set_grid(inv.backpack)
	_bank.set_grid(inv.bank)
	_info.text = "Gold %d    " % inv.gold
	if inv.bank.height < Inventory.BANK_MAX_ROWS:
		_row_button.text = "Buy another bank row (%d gold)" % inv.next_bank_row_cost()
		_row_button.disabled = false
	else:
		_row_button.text = "Bank is full size"
		_row_button.disabled = true


func _move(it: ItemInstance) -> void:
	var why := player.inventory.move_between(it.uid)
	if why != "":
		CombatFx.word(player.global_position + Vector3.UP * 2.0, why)
	refresh()
