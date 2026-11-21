class_name LootBalance
extends Resource
## Random bonus rolls. The file is data/balance/loot.tres.
## Each bonus rolls between min and max, times (1 + per_ilvl × (item level − 1)).

## stat name -> Vector2(min, max) at item level 1.
@export var bonus_ranges := {
	"strength": Vector2(1, 3),
	"agility": Vector2(1, 3),
	"intellect": Vector2(1, 3),
	"vitality": Vector2(1, 3),
	"armor": Vector2(2, 6),
	"crit_chance": Vector2(0.01, 0.03),
	"poise": Vector2(3, 8),
	"stamina_regen": Vector2(0.03, 0.08),
	"move_speed": Vector2(0.02, 0.04),
	"bleed_on_hit": Vector2(6, 12),
	"poison_on_hit": Vector2(6, 12),
	"frost_on_hit": Vector2(6, 12),
	"status_resist": Vector2(0.05, 0.12),
}
## Which bonuses never scale with item level (percentages).
@export var flat_bonuses := PackedStringArray(["crit_chance", "stamina_regen", "move_speed", "status_resist"])
@export var per_ilvl := 0.15
## Weapons only get these on-hit bonuses; jewelry/armor never do.
@export var weapon_only := PackedStringArray(["bleed_on_hit", "poison_on_hit", "frost_on_hit"])
## The general pool picks a slot first: chances for weapon / shield / armor / jewelry.
@export var category_weights := PackedFloat32Array([25.0, 10.0, 55.0, 10.0])
