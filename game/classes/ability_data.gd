class_name AbilityData
extends Resource
## One class ability on the hotbar. What it DOES is chosen by `kind` (the code
## for each kind is in game/classes/ability_caster.gd); all its numbers are here.

enum Kind {
	# Bulwark
	CHALLENGE, SHIELD_BASH, SHOULDER_CHARGE, RALLYING_BELLOW, HOLD_THE_LINE, UNBROKEN,
	# Lamplighter
	KINDLE, VIGIL_LANTERN, SNUFF, FLARE, BEACON, PYRE,
	# Headsman
	HAMSTRING, BEHEAD, LUNGE, CLEAVE, FEINT, RED_MIST,
}

## Permanent ID used by saves and the network. Never change it.
@export var id := &"ability_unnamed"
@export var display_name := "Ability"
@export_multiline var description := ""
@export var kind := Kind.CHALLENGE
## Character level needed to use it.
@export var unlock_level := 1
@export var cooldown := 10.0
## Class resource cost (Resolve, Oil). Tally finishers spend notches instead.
@export var cost := 0.0
## Placeholder icon color until real icons exist.
@export var icon_color := Color(0.6, 0.6, 0.6)
@export var needs_shield := false

@export_group("Melee strike (for strike abilities)")
## The swing, if this ability is a weapon strike (Shield Bash, Hamstring...).
@export var attack: AttackData

@export_group("Casting (for non-strike abilities)")
@export var cast_anim: StringName
## The effect happens this many seconds into the cast.
@export var cast_time := 0.3
## You're busy until this many seconds into the cast.
@export var lock_time := 0.6

@export_group("Numbers")
## Main amount: damage or healing.
@export var power := 0.0
@export var radius := 3.0
## How far it reaches or can be thrown (meters).
@export var ability_range := 20.0
## How long it lasts (seconds).
@export var duration := 5.0
## A second number whose meaning depends on the ability (a percent, a speed...).
@export var value := 0.0
## Status buildup applied to enemies it hits.
@export var status := Effects.Status.NONE
@export var status_amount := 0.0
## Extra threat multiplier for its hits (taunts use their own rules).
@export var threat_mult := 1.0
