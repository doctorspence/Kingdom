class_name LootTable
extends Resource
## What an enemy (or chest, boss...) can drop. Files live in data/loot/.

## Chance that any items drop at all.
@export_range(0.0, 1.0) var drop_chance := 0.35
## How many items when something drops (random in this range).
@export var item_count := Vector2i(1, 1)
@export var item_level := Vector2i(1, 3)
## Relative chances of Common, Uncommon, Rare, Epic, Legendary.
@export var rarity_weights := PackedFloat32Array([60.0, 28.0, 9.0, 2.5, 0.5])
## At least one item is this rarity or better (bosses: Rare).
@export var guaranteed_min_rarity := 0
## Items it can drop; empty = anything from the general pool.
@export var items: Array[ItemData] = []
## Always drops these too (named uniques).
@export var always: Array[ItemData] = []
@export var coins := Vector2i(3, 10)
@export var souls := Vector2i(5, 12)
## Old-school lines, each with its own chance (used by the Gullet). Roll on top of everything above;
## set drop_chance to 0 to use only these.
@export var entries: Array[LootEntry] = []
