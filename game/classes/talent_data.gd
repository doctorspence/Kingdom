class_name TalentData
extends Resource
## One talent. Talents don't run code of their own: each one adds "modifiers"
## (named numbers) that the abilities and stats read, e.g. kindle_range_mult.

@export var id := &"talent_unnamed"
@export var display_name := "Talent"
@export_multiline var description := ""
## Row 1, 2 or 3. Row 2 opens after 3 points spent in the tree, row 3 after 6.
@export_range(1, 3) var row := 1
## Modifier name -> amount. Names ending in "_mult" multiply, others add.
@export var mods := {}
