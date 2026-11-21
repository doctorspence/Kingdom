class_name Classes
extends RefCounted
## The list of playable classes and character looks.

const ALL: Array[ClassData] = [
	preload("res://data/classes/class_bulwark.tres"),
	preload("res://data/classes/class_lamplighter.tres"),
	preload("res://data/classes/class_headsman.tres"),
]

## Body color presets for the character creator (placeholder "skin" tints
## until real character models and outfits exist).
const LOOK_COLORS: Array[Color] = [
	Color(0.42, 0.4, 0.37),
	Color(0.55, 0.45, 0.36),
	Color(0.36, 0.27, 0.2),
	Color(0.24, 0.2, 0.17),
	Color(0.3, 0.33, 0.38),
]
const BODY_NAMES := ["Broad", "Slender"]


static func by_id(id: StringName) -> ClassData:
	for c in ALL:
		if c.id == id:
			return c
	return ALL[0]
