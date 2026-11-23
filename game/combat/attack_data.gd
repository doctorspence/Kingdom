class_name AttackData
extends Resource
## One attack (a swing, a thrust, a slam), for players and enemies alike.
##
## All times are in "animation seconds": seconds into the animation clip at
## normal speed. If the animation plays faster or slower, everything stays in
## sync with what you see.

@export var display_name := "Attack"

@export_group("Animation")
@export var anim: StringName
## Optional follow-through animation played after `anim` ends.
@export var recovery_anim: StringName
@export var anim_speed := 1.0
## Before this point the wind-up plays at `windup_speed_mult` (for slow,
## telegraphed or delayed attacks). Also where a heavy attack holds its charge.
@export var windup_until := 0.0
@export var windup_speed_mult := 1.0

@export_group("Timing (animation seconds)")
## The weapon can hit between these two times.
@export var hit_start := 0.2
@export var hit_end := 0.3
## From here the next combo attack can start.
@export var chain_time := 0.4
## From here you can roll or block out of the attack.
@export var cancel_time := 0.45
## The attack is over; normal movement returns.
@export var end_time := 0.8
## Enemies keep turning toward you until this time, then commit.
@export var track_until := 0.0
## More hit moments in the same attack (combos): (start, end) pairs.
@export var extra_hits := PackedVector2Array()
## Enemies flash their warning (white glint or red glow) at this time.
@export var telegraph_time := 0.0

@export_group("Damage")
@export var damage_mult := 1.0
@export var poise_mult := 1.0
## Flat damage for enemy attacks (players use their weapon's damage instead).
@export var base_damage := 0.0
@export var base_poise_damage := 0.0
@export var stamina_cost := 14.0
## Enemy attacks: status buildup on a hit (Marauder axes bleed, hound bites).
@export var status := Effects.Status.NONE
@export var status_amount := 0.0
## Freeze on impact (seconds): 0.05 light, 0.09 heavy, 0.15 critical.
@export var hit_stop := 0.05

@export_group("Reach")
@export var reach := 2.2
@export_range(10.0, 360.0) var arc_degrees := 120.0
## Step forward during the swing (meters), between these animation times.
@export var lunge_distance := 0.5
@export var lunge_start := 0.0
@export var lunge_end := 0.3

@export_group("Ranged (bows)")
## If above 0, this attack shoots an arrow at hit_start instead of swinging.
@export var projectile_speed := 0.0
@export var projectile_range := 40.0

@export_group("Rules")
## A timed block can parry it (white glint on enemies).
@export var parryable := true
## Can't be blocked or parried at all; dodge it (red glow on enemies).
@export var unblockable := false
## Enemy only: how likely it is to pick this attack (relative weight).
@export var weight := 1.0
## Enemy only: only used when the target is within this distance.
@export var max_use_distance := 3.0

@export_group("Special")
## Slows the target (0.3 = 30% slower) for slow_time seconds (wax spit).
@export_range(0.0, 0.9) var slow := 0.0
@export var slow_time := 3.0
## Leaves burning ground (radius meters) this far ahead of the boss at the hit moment.
@export var fire_radius := 0.0
@export var fire_ahead := 2.5
@export var fire_time := 8.0

@export_group("Boss moves")
## Enemy only: not used closer than this (a cone fired from a distance).
@export var min_use_distance := 0.0
## Enemy only: this move deals no damage but charges the next attack (Corrupted Grip). A broken stance cancels it.
@export var grip := false

@export_group("Stone Eruption (Harl)")
## Enemy only: at the telegraph moment a ring of black stone is marked under every player in the
## arena (radius > 0), and spikes burst up through it `burst_delay` seconds later.
@export var burst_radius := 0.0
@export var burst_delay := 1.3
@export var burst_damage := 38.0
## Marks per player: after the first, each new ring is placed `burst_gap` seconds later under
## wherever that player has run to, so standing still, or running in a straight line, gets punished.
@export var burst_waves := 1
@export var burst_gap := 0.75
