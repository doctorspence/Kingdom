class_name FactionData
extends Resource
## One of the three powers of the land. Lore only: a faction never restricts
## which class or subclass you can play. Files live in data/factions/.

## Permanent ID. Never change it.
@export var id := &"faction_unnamed"
@export var display_name := "Faction"
@export var tagline := ""
@export_multiline var description := ""
## What they claim to be, and what they really are (cryptic, in-world).
@export_multiline var claim := ""
@export_multiline var truth := ""
@export var look := ""
## Subclass ids the faction is associated with (display only).
@export var associated_subclasses: Array[StringName] = []
## Color for the preview screen.
@export var color := Color(0.7, 0.7, 0.7)
