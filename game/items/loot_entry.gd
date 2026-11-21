class_name LootEntry
extends Resource
## One line of an "old-school" drop table: an item, its own chance, and how many.
## Put these in a LootTable's `entries`; each one rolls on its own.

@export var item: ItemData
## Chance per kill, 0 to 1 (1/128 = 0.0078125).
@export_range(0.0, 1.0) var chance := 0.1
## How many come out when it drops (stackable items arrive as one stack).
@export var count := Vector2i(1, 1)
## Fixed rarity (0 Common, 1 Uncommon, 2 Rare, 3 Epic, 4 Legendary). -1 = the item's own minimum.
@export_range(-1, 4) var rarity := -1
