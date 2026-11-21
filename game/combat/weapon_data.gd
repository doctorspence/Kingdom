class_name WeaponData
extends Resource
## A weapon type and its moveset. Files live in data/weapons/.

## Permanent ID used by saves and the network. Never change it.
@export var id := &"weapon_unnamed"
@export var display_name := "Weapon"
@export var visual_scene: PackedScene
@export var damage := 20.0
@export var poise_damage := 12.0
@export_range(0.0, 1.0) var crit_chance := 0.05
@export var crit_multiplier := 1.5
## Share of damage stopped when you block with this weapon (no shield).
@export_range(0.0, 1.0) var block_reduction := 0.6
## Damage bonus per stat point = scaling ÷ 100 (DESIGN.md 5.12).
@export var scaling_strength := 0.5
@export var scaling_agility := 0.5
@export var scaling_intellect := 0.0
## Two-handed weapons can't be used with a shield.
@export var two_handed := false
## Status buildup on every hit (axes: bleed).
@export var status := Effects.Status.NONE
@export var status_amount := 0.0
## Ignores this share of the target's armor (maces).
@export_range(0.0, 1.0) var armor_pierce := 0.0

@export_group("Moveset")
## Light attack combo, in order. The last one loops back to the first.
@export var light_combo: Array[AttackData] = []
@export var heavy: AttackData
## Extra damage for a fully charged heavy attack.
@export var heavy_charge_bonus := 0.5
## Seconds of holding to fully charge.
@export var heavy_charge_time := 0.6
@export var running_attack: AttackData
@export var rolling_attack: AttackData
@export var riposte: AttackData
