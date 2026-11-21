class_name CharacterStats
extends RefCounted
## A character's class, level, XP, stats and talents, and the "modifiers"
## that talents and the class passive add (see TalentData).

signal leveled_up(new_level: int)
signal changed

const PROGRESSION: ProgressionData = preload("res://data/balance/progression.tres")

var class_data: ClassData
var level := 1
var xp := 0
## Talent ids picked.
var talents: Array[StringName] = []
## Equipped gear adds stats, armor and legendary effects (set by the player).
var gear: Inventory


func _init(c: ClassData) -> void:
	class_data = c


# --- Stats --------------------------------------------------------------------

func strength() -> float:
	return class_data.strength + class_data.strength_per_level * (level - 1) + _gear("strength")


func agility() -> float:
	return class_data.agility + class_data.agility_per_level * (level - 1) + _gear("agility")


func intellect() -> float:
	return class_data.intellect + class_data.intellect_per_level * (level - 1) + _gear("intellect")


func vitality() -> float:
	return class_data.vitality + class_data.vitality_per_level * (level - 1) + _gear("vitality")


func armor() -> float:
	return class_data.armor + class_data.armor_per_level * (level - 1) + mod_add("armor_add") + (gear.armor_total() if gear else 0.0)


func max_health() -> float:
	return PROGRESSION.base_health + vitality() * PROGRESSION.health_per_vitality


func max_stamina() -> float:
	return PROGRESSION.base_stamina + PROGRESSION.stamina_per_level * (level - 1)


func resource_max() -> float:
	var extra := mod_add("oil_max_add") if class_data.resource_kind == ClassData.ResourceKind.OIL else 0.0
	if class_data.resource_kind == ClassData.ResourceKind.TALLY:
		extra = mod_add("tally_max_add")
	return class_data.resource_max + extra


## Weapon damage bonus from stats: Σ(stat × weapon scaling) ÷ 100.
func damage_bonus(weapon: WeaponData) -> float:
	return (strength() * weapon.scaling_strength + agility() * weapon.scaling_agility
			+ intellect() * weapon.scaling_intellect) / 100.0


func crit_chance(weapon: WeaponData) -> float:
	return weapon.crit_chance + agility() * 0.0005 + mod_add("crit_chance_add") + _gear("crit_chance")


## Healing and ability power scale with Intellect.
func ability_power() -> float:
	return 1.0 + intellect() / 100.0


# --- Modifiers (talents + passive) ----------------------------------------------

## Multiply: names ending in _mult (default 1).
func mod_mult(key: String) -> float:
	var v := float(class_data.passive_mods.get(key, 1.0))
	for t in _picked():
		if t.mods.has(key):
			v *= float(t.mods[key])
	return v


## Add: everything else (default 0).
func mod_add(key: String) -> float:
	var v := float(class_data.passive_mods.get(key, 0.0))
	for t in _picked():
		if t.mods.has(key):
			v += float(t.mods[key])
	return v


func _picked() -> Array[TalentData]:
	var out: Array[TalentData] = []
	for t in class_data.talents:
		if t.id in talents:
			out.append(t)
	return out


# --- XP and levels --------------------------------------------------------------

func xp_to_next() -> int:
	return PROGRESSION.xp_to_next(level)


func add_xp(amount: int) -> void:
	if level >= PROGRESSION.max_level:
		return
	xp += amount
	while level < PROGRESSION.max_level and xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		leveled_up.emit(level)
	changed.emit()


func set_level(new_level: int) -> void:
	level = clampi(new_level, 1, PROGRESSION.max_level)
	xp = 0
	while talents.size() > talent_points_total():
		talents.pop_back()
	changed.emit()


# --- Talents ------------------------------------------------------------------

func talent_points_total() -> int:
	return level / PROGRESSION.levels_per_talent_point


func talent_points_free() -> int:
	return talent_points_total() - talents.size()


func row_open(row: int) -> bool:
	match row:
		2:
			return talents.size() >= PROGRESSION.row2_points
		3:
			return talents.size() >= PROGRESSION.row3_points
	return true


func can_pick(t: TalentData) -> bool:
	return not (t.id in talents) and talent_points_free() > 0 and row_open(t.row)


func pick(t: TalentData) -> bool:
	if not can_pick(t):
		return false
	talents.append(t.id)
	changed.emit()
	return true


func reset_talents() -> void:
	talents.clear()
	changed.emit()


func ability_unlocked(a: AbilityData) -> bool:
	return level >= a.unlock_level


## A stat from worn gear (base stats + bonus rolls).
func _gear(stat_name: String) -> float:
	return gear.stat_total(stat_name) if gear else 0.0
