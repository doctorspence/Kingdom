class_name ProgressionData
extends Resource
## Leveling numbers. The file is data/balance/progression.tres.

@export var max_level := 30
## XP needed to go from level L to L+1 = base × L ^ exponent.
@export var xp_base := 100.0
@export var xp_exponent := 1.6
## One talent point every this many levels.
@export var levels_per_talent_point := 3
## Party members within this distance share kill XP in full (meters).
@export var xp_share_range := 50.0
## Max health = this + Vitality × health_per_vitality.
@export var base_health := 60.0
@export var health_per_vitality := 4.0
## Stamina = base + per level.
@export var base_stamina := 100.0
@export var stamina_per_level := 1.0
## Talent rows open after this many points spent: row 2, row 3.
@export var row2_points := 3
@export var row3_points := 6


func xp_to_next(level: int) -> int:
	return roundi(xp_base * pow(level, xp_exponent))
