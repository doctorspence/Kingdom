extends RefCounted
## The list of equipment this pack makes. tools/build_equipment.gd turns each entry into a model
## scene, an item definition (data/items/...), an inventory icon and (for weapons) a WeaponData.
##
## Fields: id (the project's item_<name> convention; existing ids are reused, not duplicated),
## name, cat (folder), kind (weapon / shield / armor), slot (ItemData.Slot), tier, build (model
## builder name), grid, weight, value, level (required level), template (WeaponData whose moveset
## it copies), dmg (damage multiplier on the template, or absolute damage), armor, stats, flavor.

const W := preload("res://assets/equipment/eq_weapons.gd")
const A := preload("res://assets/equipment/eq_armor.gd")

const MAIN := 10
const OFF := 11
const TWO := 12
const HEAD := 1
const CHEST := 3
const LEGS := 5

const TIER_LEVEL := {"bronze": 1, "iron": 5, "steel": 10}
const TIER_VALUE := {"bronze": 1.0, "iron": 2.2, "steel": 5.0}
const TIER_WEIGHT := {"bronze": 1.0, "iron": 1.05, "steel": 0.95}
const TIER_NAME := {"bronze": "Bronze", "iron": "Iron", "steel": "Steel"}
const TIER_DMG := {"bronze": 0.86, "iron": 1.0, "steel": 1.18}


static func entries() -> Array:
	var out: Array = []
	for t in W.TIERS:
		var tn: String = TIER_NAME[t]
		var lv: int = TIER_LEVEL[t]
		out.append({"id": "item_%s_dagger" % t, "name": "%s Dagger" % tn, "cat": "Daggers", "folder": "Weapons", "kind": "weapon", "slot": MAIN, "tier": t,
				"build": "dagger", "grid": Vector2i(1, 2), "weight": 1.2, "value": 14 * TIER_VALUE[t], "level": lv, "template": "weapon_iron_dagger", "base_dmg": 14.0,
				"flavor": "Short, quick, and always within reach."})
		out.append({"id": "item_%s_sword" % t, "name": "%s Sword" % tn, "cat": "Swords", "folder": "Weapons", "kind": "weapon", "slot": MAIN, "tier": t,
				"build": "sword", "grid": Vector2i(1, 3), "weight": 3.6, "value": 18 * TIER_VALUE[t], "level": lv, "template": "weapon_iron_sword", "base_dmg": 28.0,
				"flavor": "An arming sword: plain, balanced, honest."})
		out.append({"id": "item_%s_2h_sword" % t, "name": "%s 2H Sword" % tn, "cat": "TwoHandedSwords", "folder": "Weapons", "kind": "weapon", "slot": TWO, "tier": t,
				"build": "sword2h", "grid": Vector2i(1, 4), "weight": 6.5, "value": 30 * TIER_VALUE[t], "level": lv + 1, "template": "weapon_executioner_greatsword", "base_dmg": 30.0,
				"flavor": "Needs both hands and a good deal of room."})
		out.append({"id": "item_%s_mace" % t, "name": "%s Mace" % tn, "cat": "Maces", "folder": "Weapons", "kind": "weapon", "slot": MAIN, "tier": t,
				"build": "mace", "grid": Vector2i(1, 3), "weight": 4.8, "value": 20 * TIER_VALUE[t], "level": lv, "template": "weapon_flanged_mace", "base_dmg": 25.0,
				"flavor": "Armor splits better than it parries."})
		out.append({"id": "item_%s_shield" % t, "name": "%s Shield" % tn, "cat": "Shields", "folder": "Weapons", "kind": "shield", "slot": OFF, "tier": t,
				"build": "shield", "grid": Vector2i(2, 3), "weight": 6.0, "value": 24 * TIER_VALUE[t], "level": lv, "template": "shield_iron",
				"flavor": "A heater shield, wood-cored and edged in metal."})
		out.append({"id": "item_%s_bow" % t, "name": "%s Bow" % tn, "cat": "Bows", "folder": "Weapons", "kind": "weapon", "slot": TWO, "tier": t,
				"build": "bow", "grid": Vector2i(2, 3), "weight": 2.6, "value": 22 * TIER_VALUE[t], "level": lv, "template": "weapon_hunting_bow", "base_dmg": 16.0,
				"flavor": "A plain wooden longbow, fitted in metal."})
	out.append({"id": "item_wooden_staff", "name": "Wooden Staff", "cat": "Staves", "folder": "Weapons", "kind": "weapon", "slot": TWO, "tier": "wood",
			"build": "staff", "grid": Vector2i(1, 4), "weight": 3.0, "value": 12, "level": 1, "template": "weapon_lantern_staff", "base_dmg": 13.0,
			"flavor": "A walking staff that has learned a second trade."})
	out.append({"id": "item_mystic_staff", "name": "Mystic Staff", "cat": "Staves", "folder": "Weapons", "kind": "weapon", "slot": TWO, "tier": "wood",
			"build": "mystic_staff", "grid": Vector2i(1, 4), "weight": 3.2, "value": 70, "level": 4, "template": "weapon_lantern_staff", "base_dmg": 15.0, "int_scaling": 0.6,
			"flavor": "The stone is small. It does not feel small."})
	return out


static func armor_entries() -> Array:
	return A.catalog()


static func build_model(e: Dictionary) -> Node3D:
	var t: String = e.tier
	match e.build:
		"dagger": return W.sword_like("dagger", t)
		"sword": return W.sword_like("sword", t)
		"sword2h": return W.sword_like("sword2h", t)
		"mace": return W.mace(t)
		"shield": return W.shield(t)
		"bow": return W.bow(t)
		"staff": return W.staff()
		"mystic_staff": return W.mystic_staff()
		_: return A.build(e.build)
	return null
