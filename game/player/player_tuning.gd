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
@export var walk_speed := 2.0
@export var run_speed := 4.5
@export var sprint_speed := 6.5
## Movement speed while locked on to a target (strafing).
@export var lock_on_speed := 3.2
## Below this stick tilt (0–1) you walk instead of run.
@export_range(0.1, 0.9) var walk_stick_threshold := 0.55

@export_group("Weight and turning")
## How fast you reach your target speed (m/s per second).
@export var acceleration := 30.0
## How fast you stop when you let go (m/s per second).
@export var deceleration := 35.0
## How fast your body turns while walking/running (degrees per second).
@export var turn_speed := 1080.0
## How fast your movement swings to a new direction while walking/running (degrees per second).
## You keep your speed through the turn instead of slowing to a stop.
@export var direction_change_speed := 1080.0
## How fast you turn while sprinting. Low = wide, heavy turns.
@export var sprint_turn_speed := 400.0
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
@export var roll_duration := PackedFloat32Array([0.55, 0.65, 0.85])
## Light, medium, heavy load: how far a roll goes (meters).
@export var roll_distance := PackedFloat32Array([4.0, 3.5, 2.5])
## Light, medium, heavy load: invincible time at the start of a roll (seconds).
@export var roll_iframes := PackedFloat32Array([0.33, 0.28, 0.22])
## Gear weight ÷ capacity at or below which you count as light / medium / heavy.
@export var load_light_max := 0.30
@export var load_medium_max := 0.70
@export var load_heavy_max := 1.00

@export_group("Stamina")
@export var max_stamina := 100.0
@export var stamina_regen := 35.0
## Pause after spending stamina before it refills (seconds).
@export var stamina_regen_delay := 0.6
@export var sprint_stamina_per_second := 10.0
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
