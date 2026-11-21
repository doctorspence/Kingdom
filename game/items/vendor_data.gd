class_name VendorData
extends Resource
## A merchant's stock. Files live in data/vendors/.

enum Currency { COINS, SOULS }

@export var display_name := "Merchant"
@export_multiline var greeting := ""
@export var currency := Currency.COINS
## Always for sale (consumables never run out).
@export var always: Array[ItemData] = []
## How many random gear pieces are on offer (rerolled when you rest).
@export var gear_count := 4
@export var gear_item_level := Vector2i(1, 3)
## Relative chances of Common, Uncommon, Rare, Epic, Legendary for the gear.
@export var gear_rarity_weights := PackedFloat32Array([50.0, 40.0, 10.0, 0.0, 0.0])
## Price = item's sell value × this.
@export var price_mult := 4.0
## Only merchants who deal in coins buy your things.
@export var buys_items := true
