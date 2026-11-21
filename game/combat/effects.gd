class_name Effects
extends RefCounted
## Status buildup (bleed, poison, frost) and timed buffs/debuffs for one
## character (player or enemy). Owned by that character; it asks Effects for
## multipliers ("how much extra damage do I take right now?").

enum Status { NONE, BLEED, POISON, FROST }

## Buildup needed to trigger a status.
const THRESHOLD := 100.0
## Meters start draining this long after the last buildup, at this rate per second.
const DRAIN_DELAY := 2.0
const DRAIN_RATE := 12.0
## DESIGN.md 5.10
const BLEED_BURST := 0.15
const POISON_PER_SECOND := 0.015
const POISON_TIME := 20.0
const FROST_BURST := 0.10
const FROST_TIME := 15.0

## Buildup meters, 0..THRESHOLD.
var buildup := {Status.BLEED: 0.0, Status.POISON: 0.0, Status.FROST: 0.0}
var poison_left := 0.0
var frost_left := 0.0
## id -> {"time": seconds left, plus any of: damage_taken, damage_dealt, move,
##        stamina_regen, stamina_cost, lifesteal, min_health, block_all}
var mods := {}

var _since_buildup := 99.0


## Add buildup. Returns the status that triggered (or NONE).
func add_buildup(status: Status, amount: float) -> Status:
	if status == Status.NONE or amount <= 0.0:
		return Status.NONE
	_since_buildup = 0.0
	buildup[status] = buildup[status] + amount
	if buildup[status] >= THRESHOLD:
		buildup[status] = 0.0
		match status:
			Status.POISON:
				poison_left = POISON_TIME
			Status.FROST:
				frost_left = FROST_TIME
		return status
	return Status.NONE


## Cure poison, frost and all buildup (Snuff, resting).
func cleanse() -> void:
	for k in buildup:
		buildup[k] = 0.0
	poison_left = 0.0
	frost_left = 0.0


func add_mod(id: StringName, duration: float, values: Dictionary) -> void:
	var entry := values.duplicate()
	entry["time"] = duration
	mods[id] = entry


func has_mod(id: StringName) -> bool:
	return mods.has(id)


func remove_mod(id: StringName) -> void:
	mods.erase(id)


func clear_all() -> void:
	cleanse()
	mods.clear()


## Advance time. Returns damage over time to apply this frame (as a share of max health).
func tick(delta: float) -> float:
	_since_buildup += delta
	if _since_buildup > DRAIN_DELAY:
		for k in buildup:
			buildup[k] = maxf(0.0, buildup[k] - DRAIN_RATE * delta)
	var dot := 0.0
	if poison_left > 0.0:
		poison_left -= delta
		dot += POISON_PER_SECOND * delta
	frost_left = maxf(0.0, frost_left - delta)
	for id in mods.keys():
		mods[id]["time"] -= delta
		if mods[id]["time"] <= 0.0:
			mods.erase(id)
	return dot


## Multiply together one named value across all active mods (default 1).
func product(key: String) -> float:
	var v := 1.0
	for id in mods:
		if mods[id].has(key):
			v *= float(mods[id][key])
	return v


## Add together one named value across all active mods (default 0).
func total(key: String) -> float:
	var v := 0.0
	for id in mods:
		if mods[id].has(key):
			v += float(mods[id][key])
	return v


func any(key: String) -> bool:
	for id in mods:
		if mods[id].get(key, false):
			return true
	return false


func damage_taken_mult() -> float:
	return product("damage_taken") * (1.15 if frost_left > 0.0 else 1.0)


func move_mult() -> float:
	return product("move") * (0.8 if frost_left > 0.0 else 1.0)


func stamina_regen_mult() -> float:
	return product("stamina_regen") * (0.6 if frost_left > 0.0 else 1.0)


## For the HUD: active things worth showing, as short names.
func active_names() -> PackedStringArray:
	var out := PackedStringArray()
	if poison_left > 0.0:
		out.append("Poisoned %ds" % ceili(poison_left))
	if frost_left > 0.0:
		out.append("Frostbitten %ds" % ceili(frost_left))
	for id in mods:
		if mods[id].has("label"):
			out.append("%s %ds" % [mods[id]["label"], ceili(mods[id]["time"])])
	return out
