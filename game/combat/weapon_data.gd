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

@export_group("Extra moves (optional; made from the basic attacks when left empty)")
@export var jump_light: AttackData
@export var jump_heavy: AttackData
## Falling attack from a height: lands with a heavy blow around you.
@export var plunge: AttackData
## Light attack right out of a raised guard.
@export var guard_counter: AttackData
@export var running_heavy: AttackData
@export var rolling_heavy: AttackData
## Light attack right after a backstep.
@export var backstep_attack: AttackData

var _variants := {}


## One of the extra moves: the one set in the data file, or one made from the
## basic light and heavy attacks (stronger, longer reach, more stamina).
func move(kind: StringName) -> AttackData:
	var explicit: AttackData = get(kind)
	if explicit:
		return explicit
	if _variants.has(kind):
		return _variants[kind]
	var light: AttackData = light_combo[0] if not light_combo.is_empty() else null
	var made: AttackData
	match kind:
		&"jump_light":
			made = _make(light, 1.15, 1.2, 1.2, 0.2)
		&"jump_heavy":
			made = _make(heavy, 1.3, 1.4, 1.15, 0.2)
		&"plunge":
			made = _make(heavy, 2.2, 2.5, 1.0, 0.9)
			if made:
				made.arc_degrees = 360.0
				made.lunge_distance = 0.0
				made.stamina_cost = 30.0
		&"guard_counter":
			made = _make(heavy, 1.4, 1.8, 0.8, 0.3)
		&"running_heavy":
			made = _make(heavy, 1.35, 1.4, 1.1, 0.3)
			if made:
				made.lunge_distance += 1.2
		&"rolling_heavy":
			made = _make(heavy, 1.25, 1.3, 1.1, 0.2)
			if made:
				made.lunge_distance += 0.6
		&"backstep_attack":
			made = _make(light, 1.2, 1.2, 1.1, 0.4)
			if made:
				made.lunge_distance += 1.0
				made.arc_degrees = minf(made.arc_degrees, 70.0)
	_variants[kind] = made
	return made


func is_heavy(a: AttackData) -> bool:
	if a == heavy:
		return true
	for v in _variants.values():
		if v == a and v != null and a.damage_mult >= 1.0 and kind_is_heavy(a):
			return true
	return false


func kind_is_heavy(a: AttackData) -> bool:
	for k in [&"jump_heavy", &"plunge", &"guard_counter", &"running_heavy", &"rolling_heavy"]:
		if _variants.get(k) == a or get(k) == a:
			return true
	return false


func _make(base: AttackData, damage: float, poise: float, stamina: float, reach_bonus: float) -> AttackData:
	if base == null:
		return null
	var a := base.duplicate() as AttackData
	a.display_name = base.display_name
	a.damage_mult = base.damage_mult * damage
	a.poise_mult = base.poise_mult * poise
	a.stamina_cost = base.stamina_cost * stamina
	a.reach = base.reach + reach_bonus
	return a
