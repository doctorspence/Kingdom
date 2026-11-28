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
## Status buildup this hit adds (bleed, poison, frost).
var status := Effects.Status.NONE
var status_amount := 0.0
## Threat multiplier (the Bulwark makes 2.5×).
var threat_mult := 1.0
## Slow the target (0.3 = 30% slower) for slow_time seconds.
var slow := 0.0
var slow_time := 0.0
## Attacker's level (for the armor formula).
var attacker_level := 1
## Extra damage if the target is Hexed (0.15 = +15%). Applied by the host (Hex lives there).
var hexed_bonus := 0.0


## Packed into a Dictionary to send over the network.
func to_dict() -> Dictionary:
	return {"d": damage, "p": poise_damage, "c": is_crit, "r": is_riposte, "o": origin,
			"hs": hit_stop, "s": status, "sa": status_amount, "t": threat_mult,
			"sl": slow, "st": slow_time, "l": attacker_level, "hx": hexed_bonus}


static func from_dict(d: Dictionary) -> HitInfo:
	var h := HitInfo.new()
	h.damage = d.get("d", 0.0)
	h.poise_damage = d.get("p", 0.0)
	h.is_crit = d.get("c", false)
	h.is_riposte = d.get("r", false)
	h.origin = d.get("o", Vector3.ZERO)
	h.hit_stop = d.get("hs", 0.05)
	h.status = d.get("s", Effects.Status.NONE)
	h.status_amount = d.get("sa", 0.0)
	h.threat_mult = d.get("t", 1.0)
	h.slow = d.get("sl", 0.0)
	h.slow_time = d.get("st", 0.0)
	h.attacker_level = d.get("l", 1)
	h.hexed_bonus = d.get("hx", 0.0)
	return h


## Armor reduction (DESIGN.md 5.12): armor ÷ (armor + 60 + 15 × attacker level), max 75%.
static func armor_reduction(armor: float, attacker_level: int) -> float:
	return clampf(armor / (armor + 60.0 + 15.0 * attacker_level), 0.0, 0.75)
