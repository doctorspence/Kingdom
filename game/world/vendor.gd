class_name Vendor
extends Node3D
## A merchant standing in the world. Interact to trade. Each player sees their
## own stock (the gear on offer is rerolled whenever you rest at a shrine).

@export var data: VendorData
@export var body_tint := Color(0.35, 0.3, 0.25)

## Current offer: Array of ItemInstance (consumables are refilled each time).
var stock: Array[ItemInstance] = []


func _ready() -> void:
	add_to_group(&"interactables")
	add_to_group(&"vendors")
	var model := CharacterModel.new()
	model.body_tint = body_tint
	model.add_child((load("res://assets/characters/mannequin/UAL1_Standard.glb") as PackedScene).instantiate())
	add_child(model)
	model.play(&"Idle_Talking", 0.0)
	var label := Label3D.new()
	label.text = data.display_name
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.004
	label.font_size = 44
	label.outline_size = 8
	label.position.y = 2.2
	label.modulate = Color(0.95, 0.85, 0.6) if data.currency == VendorData.Currency.GOLD else Color(0.7, 0.8, 1.0)
	add_child(label)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	body.add_child(shape)
	add_child(body)
	restock()


## New gear on offer (called on start and when you rest).
func restock() -> void:
	stock.clear()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var table := LootTable.new()
	table.drop_chance = 1.0
	table.item_count = Vector2i(data.gear_count, data.gear_count)
	table.item_level = data.gear_item_level
	table.rarity_weights = data.gear_rarity_weights
	table.gold = Vector2i.ZERO
	table.souls = Vector2i.ZERO
	if data.gear_count > 0:
		for it: ItemInstance in ItemDB.roll(table, rng).items:
			stock.append(it)


func price_of(item: ItemInstance) -> int:
	return maxi(1, roundi(item.sell_value() * data.price_mult / maxi(item.count, 1)))


func currency_name() -> String:
	return "gold" if data.currency == VendorData.Currency.GOLD else "souls"


## Buy an item for the player. Returns "" or the reason it failed.
func buy(player: Player, item: ItemInstance) -> String:
	var price := price_of(item)
	var inv := player.inventory
	var wallet := inv.gold if data.currency == VendorData.Currency.GOLD else inv.souls
	if wallet < price:
		return "Not enough %s" % currency_name()
	var bought := item
	if item.base in data.always:
		bought = ItemDB.make_item(item.base, 1, 0)  # consumables: a fresh one each time
	if not inv.backpack.has_room_for(bought):
		return "Your backpack is full"
	if data.currency == VendorData.Currency.GOLD:
		inv.gold -= price
	else:
		inv.souls -= price
	inv.add_item(bought)
	if bought == item:
		stock.erase(item)
	return ""


## Everything for sale right now: the always-in-stock items, then the gear.
func offers() -> Array[ItemInstance]:
	var out: Array[ItemInstance] = []
	for base in data.always:
		out.append(ItemInstance.make(base, 1, 0))
	out.append_array(stock)
	return out


func get_interact_text() -> String:
	return "Trade with %s" % data.display_name


func interact(player: Node3D) -> void:
	player.call(&"open_menu", &"shop", self)
