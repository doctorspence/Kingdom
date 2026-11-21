class_name ItemData
extends Resource
## A base item (the fixed part). Files live in data/items/. What you actually
## find in the world is an ItemInstance: this base plus item level, rarity and
## random bonus rolls.

enum Slot { NONE, HEAD, SHOULDERS, CHEST, HANDS, LEGS, FEET, CLOAK, NECK, RING, MAIN_HAND, OFF_HAND, TWO_HAND, CONSUMABLE }

## Permanent ID used by saves and the network. Never change it.
@export var id := &"item_unnamed"
@export var display_name := "Item"
@export_multiline var flavor := ""
@export var slot := Slot.NONE
## Size on the inventory grid (columns × rows).
@export var grid_size := Vector2i(1, 1)
## Equip load (kg-ish).
@export var weight := 1.0
## Sell price at item level 1 (buy price is 4×). Rarity and item level raise it.
@export var value := 10
## Placeholder icon color until real icons exist.
@export var icon_color := Color(0.5, 0.5, 0.5)
## Lowest rarity this base can drop as (unique items set this to Legendary).
@export var min_rarity := 0

@export_group("Base stats (at item level 1; grow 10% per level)")
@export var armor := 0.0
## Fixed stats, e.g. {"strength": 2, "poise": 5}.
@export var stats := {}

@export_group("Weapons and shields")
@export var weapon: WeaponData
@export var shield: ShieldData

@export_group("Consumables")
@export var stack_max := 1
## What using it does: "cure_poison", "cure_frost", "heal".
@export var use_effect := &""
@export var use_amount := 0.0

@export_group("Unique / legendary")
## Set for named uniques: their special effect, as modifiers (same names as talents).
@export var legendary_mods := {}
@export_multiline var legendary_text := ""


func is_equipment() -> bool:
	return slot != Slot.NONE and slot != Slot.CONSUMABLE


func is_weapon() -> bool:
	return weapon != null


static func slot_name(s: Slot) -> String:
	return ["—", "Head", "Shoulders", "Chest", "Hands", "Legs", "Feet", "Cloak", "Neck", "Ring",
			"Main hand", "Off hand", "Two-handed", "Consumable"][s]
