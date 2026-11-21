class_name EnemyData
extends Resource
## One kind of enemy. Files live in data/enemies/.

## Permanent ID used by saves and the network. Never change it.
@export var id := &"enemy_unnamed"
@export var display_name := "Enemy"
@export var max_health := 150.0
## Its level (for the armor formula) and its armor.
@export var level := 3
@export var armor := 20.0
## XP each nearby player gets for the kill.
@export var xp := 60
## Hits it can take before staggering (refills after a pause).
@export var poise := 40.0
@export var poise_regen_delay := 3.0
@export var stagger_time := 1.0
## How long it stays open to a riposte after being parried (seconds).
@export var riposte_window := 1.5
## Knocked down this long after a riposte (if it survives).
@export var riposted_time := 1.8

@export_group("Movement")
@export var walk_speed := 1.4
@export var run_speed := 3.6
## How fast it turns (degrees per second).
@export var turn_speed := 300.0

@export_group("Behavior")
## Notices you from this far away (meters), if it can see you.
@export var aggro_range := 14.0
## Gives up and walks home past this distance from where it started.
@export var leash_range := 30.0
## Starts attacking within this distance.
@export var attack_range := 2.8
## Pause between attacks (seconds, random in this range).
@export var attack_cooldown_min := 0.6
@export var attack_cooldown_max := 1.6
@export var attacks: Array[AttackData] = []

@export_group("Look")
@export var body_tint := Color(0.2, 0.07, 0.06)
@export var scale := 1.12
@export var weapon_scene: PackedScene
