class_name ShieldData
extends Resource
## A shield. Files live in data/shields/.

@export var id := &"shield_unnamed"
@export var display_name := "Shield"
@export var visual_scene: PackedScene
## Share of physical damage stopped when blocking (1.0 = all of it).
@export_range(0.0, 1.0) var block_reduction := 1.0
## Stamina lost per point of blocked damage. Lower = sturdier shield.
@export var stamina_per_damage := 0.6
## Parry window after raising the shield (seconds).
@export var parry_window := 0.18
