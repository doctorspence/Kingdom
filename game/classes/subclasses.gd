class_name Subclasses
extends RefCounted
## The list of subclasses and factions, and the level where you choose.

## Character level where the subclass is chosen.
const CHOOSE_LEVEL := 10

const ALL: Array[SubclassData] = [
	preload("res://data/subclasses/subclass_warrior.tres"),
	preload("res://data/subclasses/subclass_rogue.tres"),
	preload("res://data/subclasses/subclass_ranger.tres"),
	preload("res://data/subclasses/subclass_guardian.tres"),
	preload("res://data/subclasses/subclass_paladin.tres"),
	preload("res://data/subclasses/subclass_warden.tres"),
	preload("res://data/subclasses/subclass_cleric.tres"),
	preload("res://data/subclasses/subclass_mage.tres"),
	preload("res://data/subclasses/subclass_warlock.tres"),
]

const FACTIONS: Array[FactionData] = [
	preload("res://data/factions/faction_white_knights.tres"),
	preload("res://data/factions/faction_dark_ages.tres"),
	preload("res://data/factions/faction_outcasts.tres"),
]


## null if there is none by that id (an empty id means "no subclass").
static func by_id(id: StringName) -> SubclassData:
	for s in ALL:
		if s.id == id:
			return s
	return null


## The three subclasses of one primary class, in order.
static func for_class(class_id: StringName) -> Array[SubclassData]:
	var out: Array[SubclassData] = []
	for s in ALL:
		if s.primary_class == class_id:
			out.append(s)
	return out


static func faction(id: StringName) -> FactionData:
	for f in FACTIONS:
		if f.id == id:
			return f
	return FACTIONS[2]
