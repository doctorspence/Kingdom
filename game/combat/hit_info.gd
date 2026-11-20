class_name HitInfo
extends RefCounted
## Everything about one hit, passed from the attacker to whoever gets hit.
## The one being hit decides what happened and returns a Result.

enum Result { IGNORED, HIT, BLOCKED, PARRIED, DODGED, KILLED }

var attacker: Node3D
var attack: AttackData
var damage := 0.0
var poise_damage := 0.0
var is_crit := false
var is_riposte := false
## Where the blow came from (for blocking direction and blood spray).
var origin := Vector3.ZERO
var parryable := true
var unblockable := false
var hit_stop := 0.05
