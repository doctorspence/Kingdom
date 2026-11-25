class_name PlayerTuning
extends Resource
## Every movement and stamina number for the player, in one data file.
##
## The values live in data/balance/player_tuning.tres. Open that file in
## Godot and change the numbers in the Inspector; no code needed.

enum LoadTier { LIGHT, MEDIUM, HEAVY, OVERLOADED }

@export_group("Health")
@export var max_health := 100.0

@export_group("Speeds (meters per second)")
@export var walk_speed := 1.5
@export var run_speed := 5.8
@export var sprint_speed := 8.0
## Movement speed while locked on to a target (strafing), going forward.
@export var lock_on_speed := 5.0
## Combat stance (locked on or guarding): backing away is this share of forward speed ...
@export_range(0.3, 1.0) var stance_back_mult := 0.7
## ... and side-stepping is a slow, careful step at this speed (m/s), feet stepping
## out and in while you keep your fighting stance.
@export var stance_side_speed := 1.3
## Below this stick tilt (0–1) you walk instead of run.
@export_range(0.1, 0.9) var walk_stick_threshold := 0.55
## Crouched (toggle): slow and quiet. A gently tilted stick is a little slower still.
@export var crouch_speed := 2.2
@export_range(0.3, 1.0) var crouch_gentle_mult := 0.7

@export_group("Stealth")
## Multiplies an enemy's sight range while you are crouched and moving ...
@export var crouch_seen_mult := 0.45
## ... and crouched and still.
@export var crouch_still_seen_mult := 0.35
## Multiplies an enemy's hearing range: crouched and moving, walking, standing still,
## and loud (sprinting, attacking, rolling).
@export var crouch_heard_mult := 0.35
@export var walk_heard_mult := 0.6
@export var still_heard_mult := 0.3
@export var loud_heard_mult := 2.0
## Sneak attack (first blow on an enemy that hasn't noticed you): balance damage
## multiplier, and the most a named rare can take from the damage bonus.
@export var sneak_poise_mult := 2.0
@export var sneak_named_cap := 1.5
## Hits from behind (more than this many degrees off its facing) always do this
## much more damage, in or out of a fight. A sneak attack uses the larger: no stacking.
@export var flank_angle := 120.0
@export var flank_damage_mult := 1.5

@export_group("Weight and turning")
## How fast you reach your target speed (m/s per second).
@export var acceleration := 16.0
## How fast you stop when you let go (m/s per second).
@export var deceleration := 20.0
## How fast your body turns while walking/running (degrees per second).
@export var turn_speed := 360.0
## How quickly the body swings round to face where you push (higher = snappier).
@export var turn_sharpness := 9.0
## How fast your movement swings to a new direction while walking/running (degrees per second).
## You keep your speed through the turn instead of slowing to a stop.
@export var direction_change_speed := 360.0
## How fast you turn while sprinting. Low = wide, heavy turns.
@export var sprint_turn_speed := 620.0
## How much you can steer in the air (0 = none, 1 = full).
@export_range(0.0, 1.0) var air_control := 0.2
@export var gravity := 22.0

@export_group("Jump")
@export var jump_height := 1.1
## Invincible for this long right after jumping (seconds).
@export var jump_iframes := 0.12
@export var jump_stamina := 12.0
## Grace period to still jump after walking off a ledge (seconds).
@export var coyote_time := 0.12

@export_group("Dodge roll")
@export var roll_stamina := 18.0
## Light, medium, heavy load: how long a roll lasts (seconds).
@export var roll_duration := PackedFloat32Array([0.45, 0.52, 0.68])
## Light, medium, heavy load: how far a roll goes (meters).
@export var roll_distance := PackedFloat32Array([4.8, 4.2, 3.1])
## Light, medium, heavy load: invincible time at the start of a roll (seconds).
@export var roll_iframes := PackedFloat32Array([0.28, 0.24, 0.19])
## Gear weight ÷ capacity at or below which you count as light / medium / heavy.
@export var load_light_max := 0.30
@export var load_medium_max := 0.70
@export var load_heavy_max := 1.00

@export_group("Stamina")
@export var max_stamina := 100.0
@export var stamina_regen := 35.0
## Pause after spending stamina before it refills (seconds).
@export var stamina_regen_delay := 0.6
@export var sprint_stamina_per_second := 9.0
## After running dry while sprinting, you must recover this much before sprinting again.
@export var sprint_restart_stamina := 20.0

@export_group("Fall damage")
## Falls shorter than this do no damage (meters).
@export var safe_fall_height := 5.0
## Falls this long or longer kill you (meters).
@export var lethal_fall_height := 15.0
## Above this height you land hard and stumble briefly (meters).
@export var hard_landing_height := 3.0
@export var hard_landing_time := 0.35

@export_group("Combat")
## How fast your attacks play (1 = original speed). Raises wind-ups, swings, recovery and lunges together.
@export_range(0.7, 1.6) var attack_speed := 1.2
## Hits you can take before you stagger (refills after a pause).
@export var poise := 30.0
@export var poise_regen_delay := 3.0
@export var stagger_time := 0.45
## Stunned after your stamina runs out while blocking (seconds).
@export var guard_break_time := 1.2
@export var block_move_speed := 2.6
## Stamina refills at this fraction of normal speed while blocking.
@export_range(0.0, 1.0) var block_regen_mult := 0.5
## Blocks work against blows from this wide in front of you (degrees).
@export var block_arc := 120.0
## A light attack this soon after a roll becomes a rolling attack (seconds).
@export var rolling_attack_window := 0.35
## How close you must be to a stunned enemy to riposte (meters).
@export var riposte_range := 2.4
## Pushed back this hard (m/s) by a blow you block (not by a deflect).
@export var block_pushback := 3.0

@export_group("Timing and rhythm")
## Deflect window when you raise a weapon (no shield) to guard (seconds). Shields have their own.
@export var deflect_window_weapon := 0.15
## Press guard again this soon after the last press and the deflect window shrinks (no mashing).
@export var deflect_spam_time := 0.45
## Each rushed press multiplies the window by this (0.5 = half, then a quarter...).
@export_range(0.1, 1.0) var deflect_spam_mult := 0.5
## Stamina you get back from a clean deflect.
@export var deflect_stamina_gain := 8.0
## Steady: tap guard within this long after an attack's recovery point (seconds) ...
@export var tempo_window := 0.25
## ... and get back this share of the stamina that attack cost.
@export_range(0.0, 1.0) var tempo_refund := 0.6
## Light attacks: guard can cut the follow-through short this long after the blade passes (animation seconds).
@export var guard_cancel_after_hit := 0.04
## A blow that reaches you in the first this-many seconds of a roll is a perfect dodge.
@export var perfect_dodge_time := 0.15
## After a perfect dodge your next blow within this long hits harder and shakes their balance more.
@export var evade_bonus_time := 0.9
@export var evade_damage_mult := 1.3
@export var evade_balance_mult := 2.0
## Step-in: perfect-dodge *toward* a red (unblockable) attack and the attacker loses this
## share of its full balance ...
@export_range(0.0, 1.0) var step_in_balance := 0.45
## ... and recoils this long (seconds; bosses don't recoil).
@export var step_in_recoil := 0.7
## Attack out of a roll from this far through it (0-1; earlier after a perfect dodge).
@export_range(0.0, 1.0) var roll_attack_from := 0.6
## Guard out of a roll from this far through it (0-1).
@export_range(0.0, 1.0) var roll_guard_from := 0.7
## Deflects in a row (each within this long of the last) ring higher and higher.
@export var deflect_chain_time := 1.2
## Pitch step per deflect in a row (0.06 = 6% higher each time, up to 5 steps).
@export var deflect_chain_pitch := 0.06
## Flinch: a clean hit during your light attack's wind-up knocks you out of it for
## this long (seconds). Heavy swings power through. Swing into their blade and you lose.
@export var flinch_time := 0.3
## Heavy attacks: their wind-up (the raise before the blow) plays at this speed
## (0.5 = takes twice as long, about 0.5 s with a sword). Charging holds at the top as before.
@export_range(0.2, 1.0) var heavy_windup_scale := 0.5
## Attack reach: a melee swing aimed at someone just out of reach closes up to this much
## extra distance during its wind-up (meters), so blows connect instead of falling short ...
@export var reach_assist := 1.2
## ... moving no faster than this while doing it (m/s).
@export var reach_assist_speed := 7.0

@export_group("Flasks")
@export var flask_count := 4
## Share of max health one flask heals.
@export_range(0.0, 1.0) var flask_heal := 0.4
@export var drink_time := 1.2
## The heal lands this many seconds into drinking.
@export var drink_heal_at := 0.75
@export var drink_move_speed := 1.5

@export_group("Downed and revive (co-op)")
## Bleed-out time for your 1st, 2nd, 3rd+ time going down (resets when you rest).
@export var downed_bleed_times := PackedFloat32Array([20.0, 12.0, 6.0])
@export var downed_crawl_speed := 0.6
## How long a friend holds Interact to revive you (seconds). Costs them one flask.
@export var revive_time := 3.0
## Share of max health you get back when revived.
@export_range(0.05, 1.0) var revive_health := 0.3
@export var revive_range := 2.0

@export_group("Input feel")
## A button pressed slightly early (during a roll) still counts (seconds).
@export var input_buffer_time := 0.2
## Gamepad B held longer than this is a sprint, not a roll (seconds).
@export var dodge_hold_time := 0.25


func load_tier(load_ratio: float) -> LoadTier:
	if load_ratio <= load_light_max:
		return LoadTier.LIGHT
	if load_ratio <= load_medium_max:
		return LoadTier.MEDIUM
	if load_ratio <= load_heavy_max:
		return LoadTier.HEAVY
	return LoadTier.OVERLOADED


## Damage from a fall of `height` meters, as a share of max health (0 to 1).
func fall_damage_fraction(height: float) -> float:
	if height <= safe_fall_height:
		return 0.0
	var t := clampf((height - safe_fall_height) / (lethal_fall_height - safe_fall_height), 0.0, 1.0)
	return pow(t, 1.5) if t < 1.0 else 1.0
