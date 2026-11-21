class_name ClassData
extends Resource
## A playable class. Files live in data/classes/.

enum ResourceKind { RESOLVE, OIL, TALLY }

## Permanent ID used by saves and the network. Never change it.
@export var id := &"class_unnamed"
@export var display_name := "Class"
## Short role line for the character creator ("Tank", "Healer"...).
@export var role := ""
@export_multiline var description := ""

@export_group("Gear")
@export var weapon: WeaponData
@export var shield: ShieldData
## Gear a new character starts with (equipped).
@export var starting_items: Array[ItemData] = []

@export_group("Resource")
@export var resource_kind := ResourceKind.RESOLVE
@export var resource_label := "Resolve"
@export var resource_max := 100.0
@export var resource_color := Color(0.7, 0.7, 0.75)

@export_group("Stats at level 1, and gained per level")
@export var strength := 10.0
@export var strength_per_level := 1.0
@export var agility := 10.0
@export var agility_per_level := 1.0
@export var intellect := 10.0
@export var intellect_per_level := 1.0
@export var vitality := 10.0
@export var vitality_per_level := 1.0
@export var armor := 10.0
@export var armor_per_level := 1.0

@export_group("Passive")
@export var passive_name := ""
@export_multiline var passive_description := ""
## Passives are modifiers too (same names as talents), always on.
@export var passive_mods := {}

@export_group("Kit")
## The 6 hotbar abilities, in slot order.
@export var abilities: Array[AbilityData] = []
@export var talents: Array[TalentData] = []
