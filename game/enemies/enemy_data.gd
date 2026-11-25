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
## What it drops when it dies (items, coins, souls).
@export var loot_table: LootTable
## Balance: how much it takes (hits and deflects) before it is thrown off balance.
## It starts refilling `poise_regen_delay` seconds after the last blow.
@export var poise := 40.0
@export var poise_regen_delay := 3.0
## (Unused since the 2026-11-22 balance pass: a broken balance opens a riposte instead.)
@export var stagger_time := 1.0
## How long it stays open to a riposte after its balance breaks (seconds).
@export var riposte_window := 1.5
## Knocked down this long after a riposte (if it survives).
@export var riposted_time := 1.8

@export_group("Balance and tempo")
## Once its balance (poise) starts refilling, this share of the full bar comes back per second.
## Hurt enemies refill slower (at 0 health about a third of this).
@export var balance_regen := 0.25
## Recoils this long when you deflect the last blow of its attack (your opening to strike back).
@export var deflect_recoil_time := 0.55
## Raises its guard after this many of your hits in a row (0 = never guards).
@export var guard_after_hits := 2
## Holds its guard this long, or until it has blocked two blows, then strikes back.
@export var guard_time := 0.9
## Chance that it strikes back straight out of its guard (otherwise it just lowers it).
@export_range(0.0, 1.0) var counter_chance := 0.65
## Chance to follow an attack straight up with another (a string of blows to deflect in rhythm).
@export_range(0.0, 1.0) var combo_chance := 0.0
## Chance that a swing with a wind-up is held a beat longer (a delayed swing that punishes guessing) ...
@export_range(0.0, 1.0) var delay_chance := 0.0
## ... and how slowly the held wind-up plays (0.5 = it takes twice as long).
@export_range(0.2, 1.0) var delay_hold := 0.5
## Reads a turtle: after you *block* (not deflect) this many of its blows in a row,
## its next attack is far more likely to be a red (unblockable) one. 0 = never.
@export var read_guard_after := 2
## How much likelier its red attacks become then (x weight).
@export var read_guard_mult := 6.0

@export_group("Movement")
@export var walk_speed := 1.4
@export var run_speed := 3.6
## How fast it turns (degrees per second).
@export var turn_speed := 300.0

@export_group("Senses")
## Sees you this far (meters) inside a cone this wide (degrees), if nothing blocks the view.
@export var sight_range := 22.0
@export var sight_angle := 120.0
## Hears you this close (doubled while you sprint or fight).
@export var hearing_range := 6.0
## How quickly it notices you: multiplies how fast its awareness meter fills
## (lookouts and hounds are keen, sleepy ones lower). See STEALTH_PLAN.md.
@export var perception := 1.0

@export_group("Special behavior")
## Blows a horn / howls when it spots you: everyone of its kind nearby joins in.
@export var caller := false
@export var call_range := 35.0
@export var call_anim := &"ual2/Idle_Rail_Call"
@export var call_time := 1.4
## Chance to block your blows from the front with a shield (when not attacking).
@export_range(0.0, 1.0) var block_chance := 0.0
## Gets faster and hits harder when an ally dies nearby (White Knights).
@export var martyr_fury := false
## A named enemy (rare): name shown over its health bar.
@export var named := false

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
## How it passes the time on its post before a fight (ENEMY_LIFE_PLAN.md):
## "loose" (bandits: chatting, drinking, slouching), "disciplined" (Knights:
## upright, arms folded, few words) or "none" (always in fighting stance).
@export_enum("loose", "disciplined", "none") var calm_style := "loose"

@export_group("Look")
@export var body_tint := Color(0.2, 0.07, 0.06)
@export var scale := 1.12
@export var weapon_scene: PackedScene
## Something in the left hand (a shield).
@export var offhand_scene: PackedScene
## Height of the lock-on point and the health bar (meters, before scaling).
@export var lock_height := 1.35
@export var bar_height := 2.25

@export_group("Boss")
## A boss: huge poise (a break = stance break, kneeling open to a critical),
## switches target only at the start of attacks, has a bar at the screen bottom.
@export var boss := false
## Phase 2 starts below this share of health (0 = no second phase).
@export_range(0.0, 1.0) var phase2_at := 0.0
## Used instead of `attacks` in phase 2.
@export var phase2_attacks: Array[AttackData] = []
@export var phase2_speed_mult := 1.25
## Enemy scene it calls in phase 2 (`adds_count` plus one per extra player in the arena).
@export var adds_scene: PackedScene
@export var adds_count := 2
## Kneels this long after its poise breaks.
@export var stance_time := 3.0
## Balance (poise) lost when you deflect one of its blows (every enemy, not only bosses).
@export var parry_poise_damage := 22.0
## Extra health per extra player in the arena (bosses: 0.8).
@export var boss_health_per_player := 0.8
## Flag set the first time it dies (opens shortcuts for good).
@export var kill_flag := &""

@export_group("Ranged and camps (Gullet)")
## Archers: tries to stay between this distance and `attack_range` from you, backing off when you
## close in (0 = a normal melee enemy). Archers don't count toward the 2-attackers rule.
@export var keep_distance := 0.0
## A shout also pulls in every enemy with the same family name (bandits, archers and captains).
@export var call_family := &""
## Hidden until a player passes within this many meters (the nook ambush); 0 = normal senses.
@export var ambush_range := 0.0

@export_group("Boss extras (Harl)")
## Text shown when phase 2 begins, and the body tint after it.
@export var phase2_text := "Ablaze!"
@export var phase2_tint := Color(1.0, 0.55, 0.25)
## The next attack after a "grip" attack hits this much harder.
@export var grip_damage_mult := 1.5
