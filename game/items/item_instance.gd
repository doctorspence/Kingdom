class_name ItemInstance
extends RefCounted
## One real item: a base (ItemData) + item level + rarity + random bonus rolls.
## Turns into a plain Dictionary for saving and for sending over the network.

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const RARITY_COLORS := [
	Color(0.92, 0.92, 0.9),
	Color(0.35, 0.85, 0.3),
	Color(0.3, 0.55, 1.0),
	Color(0.7, 0.35, 0.95),
	Color(1.0, 0.55, 0.1),
]
## Bonus rolls per rarity (DESIGN.md 9.1).
const BONUS_COUNT := [0, 0, 1, 2, 2]
## Base stats grow this much per item level above 1.
const PER_ILVL := 0.1

var uid := ""
var base: ItemData
var ilvl := 1
var rarity := Rarity.COMMON
## Rolled bonuses: stat name -> amount.
var bonuses := {}
var count := 1
## Marked as junk by its owner (sorted last, sold in one go at a merchant).
var junk := false


static func make(item: ItemData, item_level: int, item_rarity: int) -> ItemInstance:
	var it := ItemInstance.new()
	it.uid = new_uid()
	it.base = item
	it.ilvl = maxi(item_level, 1)
	it.rarity = maxi(item_rarity, item.min_rarity) as Rarity
	return it


static func new_uid() -> String:
	return "%x%x" % [Time.get_ticks_usec() & 0xFFFFFFF, randi()]


func display_name() -> String:
	return base.display_name


func color() -> Color:
	return RARITY_COLORS[rarity]


## Base armor and stats scale with item level.
func scale() -> float:
	return 1.0 + PER_ILVL * (ilvl - 1)


func armor() -> float:
	return base.armor * scale() + float(bonuses.get("armor", 0.0))


## A stat from the base + bonus rolls (e.g. "strength", "crit_chance").
func stat(name: String) -> float:
	return float(base.stats.get(name, 0.0)) * scale() + float(bonuses.get(name, 0.0))


## Sell price; buying costs 4×.
func sell_value() -> int:
	return maxi(1, roundi(base.value * scale() * [1.0, 1.6, 3.0, 6.0, 12.0][rarity] * count))


func weight() -> float:
	return base.weight


## Swing speed of a weapon, from how fast its light attacks play: "Fast", "Average" or "Slow" ("" if not a weapon).
func attack_speed() -> String:
	if base.weapon == null or base.weapon.light_combo.is_empty():
		return ""
	var total := 0.0
	for a in base.weapon.light_combo:
		total += a.anim_speed / maxf(a.end_time, 0.1)
	var pace := total / base.weapon.light_combo.size()
	return "Fast" if pace >= 1.3 else ("Average" if pace >= 0.95 else "Slow")


func to_dict() -> Dictionary:
	var d := {"uid": uid, "id": String(base.id), "ilvl": ilvl, "rarity": rarity, "bonuses": bonuses, "count": count}
	if junk:
		d["junk"] = true
	return d


static func from_dict(d: Dictionary) -> ItemInstance:
	var item := ItemDB.get_item(StringName(d.get("id", "")))
	if item == null:
		return null
	var it := ItemInstance.new()
	it.base = item
	it.uid = d.get("uid", new_uid())
	it.ilvl = int(d.get("ilvl", 1))
	it.rarity = int(d.get("rarity", 0)) as Rarity
	it.bonuses = d.get("bonuses", {})
	it.count = int(d.get("count", 1))
	it.junk = bool(d.get("junk", false))
	return it


## Tooltip lines (name and rarity first).
func describe() -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append("%s" % display_name())
	lines.append("%s  ·  %s  ·  item level %d" % [RARITY_NAMES[rarity], ItemData.slot_name(base.slot), ilvl])
	if base.required_level > 1 or base.tier != &"":
		lines.append("%s%s" % [String(base.tier).capitalize() + ("  ·  " if base.tier != &"" else ""), "Level %d" % base.required_level])
	if base.weapon:
		var w := base.weapon
		lines.append("Damage %d   Poise %d%s" % [roundi(w.damage * scale()), roundi(w.poise_damage),
				"   Two-handed" if w.two_handed else ""])
		var sc := PackedStringArray()
		if w.scaling_strength > 0.0:
			sc.append("Str %s" % _grade(w.scaling_strength))
		if w.scaling_agility > 0.0:
			sc.append("Agi %s" % _grade(w.scaling_agility))
		if w.scaling_intellect > 0.0:
			sc.append("Int %s" % _grade(w.scaling_intellect))
		lines.append("Scales with: " + ", ".join(sc))
	if base.shield:
		lines.append("Blocks %d%%   Stability %s   Parry window %.2f s" % [roundi(base.shield.block_reduction * 100.0),
				"high" if base.shield.stamina_per_damage < 0.5 else ("low" if base.shield.stamina_per_damage > 0.7 else "medium"),
				base.shield.parry_window])
	if armor() > 0.0:
		lines.append("Armor %d" % roundi(armor()))
	for k in base.stats:
		lines.append(_stat_line(k, float(base.stats[k]) * scale()))
	for k in bonuses:
		if k != "armor":
			lines.append(_stat_line(k, float(bonuses[k])) + "  (bonus)")
		elif float(bonuses[k]) > 0.0:
			lines.append("+%d armor  (bonus)" % roundi(float(bonuses[k])))
	if base.legendary_text != "":
		lines.append(base.legendary_text)
	if base.use_effect != &"":
		lines.append("Use: " + {"cure_poison": "cures poison", "cure_frost": "cures frost", "heal": "heals %d" % roundi(base.use_amount), "heal_percent": "heals %d%% of your health" % roundi(base.use_amount * 100.0)}.get(String(base.use_effect), String(base.use_effect)))
	if count > 1:
		lines.append("x%d" % count)
	lines.append("Weight %.1f   Sells for %d coins" % [base.weight, sell_value()])
	if base.flavor != "":
		lines.append("\"%s\"" % base.flavor)
	return lines


static func _grade(v: float) -> String:
	return "A" if v >= 0.8 else ("B" if v >= 0.6 else ("C" if v >= 0.4 else "D"))


static func _stat_line(k: String, v: float) -> String:
	var names := {"strength": "Strength", "agility": "Agility", "intellect": "Intellect", "vitality": "Vitality",
			"crit_chance": "% crit chance", "poise": "poise", "stamina_regen": "% stamina regen",
			"move_speed": "% move speed", "bleed_on_hit": "bleed buildup on hit", "poison_on_hit": "poison buildup on hit",
			"frost_on_hit": "frost buildup on hit", "status_resist": "% status resistance"}
	var label: String = names.get(k, k)
	if label.begins_with("%"):
		return "+%.1f%s" % [v * 100.0, label]
	return "+%d %s" % [roundi(v), label]
