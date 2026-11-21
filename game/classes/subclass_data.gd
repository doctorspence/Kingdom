class_name SubclassData
extends Resource
## A subclass: chosen at level 10 within one primary class. It adds its own
## abilities (levels 10, 15, 20 for now) and a passive on top of the class, and
## never removes anything. Files live in data/subclasses/.
##
## Everything players read before choosing (identity, weapons, direction, the
## initiation story, the faction tie) lives here as text, so lore is data.

## Permanent ID used by saves and the network. Never change it.
@export var id := &"subclass_unnamed"
@export var display_name := "Subclass"
## The primary class it belongs to (a ClassData id, e.g. class_headsman).
@export var primary_class := &"class_headsman"
@export var tagline := ""
@export_multiline var identity := ""
## Weapons this path favors (display text; any class can still use any weapon).
@export var weapon_specialties := ""
@export_multiline var progression_direction := ""

@export_group("Kit")
## Abilities this subclass adds, in hotbar order (unlock levels 10, 15, 20).
## They go on the hotbar after the class's own three.
@export var abilities: Array[AbilityData] = []
@export var passive_name := ""
@export_multiline var passive_description := ""
## Passives are modifiers too (same names as talents), always on.
@export var passive_mods := {}
## What is not built yet (shown in the preview as "coming later").
@export_multiline var planned_abilities := ""
## False until the abilities exist: the choice stays locked ("Coming later")
## so nobody locks in a path with nothing on it.
@export var available := false

@export_group("Lore")
## A FactionData id. Display only: it never restricts or grants anything.
@export var faction := &"faction_outcasts"
@export var initiation_title := ""
@export_multiline var initiation_story := ""
## True once the quest system exists and this path needs its trial. Until then
## the shrine choice stands in for the trial.
@export var requires_trial := false
