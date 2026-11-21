class_name AbilityCaster
extends Node
## Runs a player's class abilities: cooldowns, the class resource (Resolve,
## Oil, Tally) and what each ability actually does. All numbers come from the
## AbilityData files; talents adjust them through modifiers.
##
## Abilities run on the caster's own machine. Heals, buffs, taunts and damage
## reach other players and enemies over the network (see Player and Enemy).

signal resource_changed(current: float, maximum: float)
signal ability_used(slot: int)

const AREA_SCENE := preload("res://game/classes/area_effect.gd")
const EMBER_SCRIPT := preload("res://game/classes/ember.gd")

## Resolve fades this much per second out of combat; Oil refills this much per second.
const RESOLVE_FADE := 6.0
const OIL_REGEN := 2.5
const OIL_PER_HIT := 4.0
const RESOLVE_PER_BLOCK := 6.0
const RESOLVE_PER_HIT_TAKEN := 4.0
const TALLY_FADE_DELAY := 8.0
const OUT_OF_COMBAT_TIME := 6.0

var resource := 0.0
var cooldowns := {}  # ability id -> seconds left

var _since_combat := 99.0
var _since_tally := 99.0

@onready var player: Player = get_parent()


func stats() -> CharacterStats:
	return player.stats


func abilities() -> Array[AbilityData]:
	return player.stats.class_data.abilities


func kind() -> ClassData.ResourceKind:
	return player.stats.class_data.resource_kind


func cooldown_left(a: AbilityData) -> float:
	return cooldowns.get(a.id, 0.0)


func refill() -> void:
	resource = stats().resource_max() if kind() == ClassData.ResourceKind.OIL else 0.0
	cooldowns.clear()
	_emit()


func _physics_process(delta: float) -> void:
	if not player.is_multiplayer_authority() or player.stats == null:
		return
	for id in cooldowns.keys():
		cooldowns[id] -= delta
		if cooldowns[id] <= 0.0:
			cooldowns.erase(id)
	_since_combat += delta
	_since_tally += delta
	match kind():
		ClassData.ResourceKind.RESOLVE:
			if _since_combat > OUT_OF_COMBAT_TIME and resource > 0.0:
				_set_resource(resource - RESOLVE_FADE * delta)
		ClassData.ResourceKind.OIL:
			if resource < stats().resource_max():
				_set_resource(resource + OIL_REGEN * (1.0 + stats().intellect() / 100.0) * delta)
		ClassData.ResourceKind.TALLY:
			if resource > 0.0 and _since_tally > TALLY_FADE_DELAY + stats().mod_add("tally_fade_add"):
				_set_resource(0.0)


func _set_resource(v: float) -> void:
	resource = clampf(v, 0.0, stats().resource_max())
	_emit()


func _emit() -> void:
	resource_changed.emit(resource, stats().resource_max())


# --- Hooks from the player ----------------------------------------------------

## You landed a melee hit (normal attacks and strike abilities).
func on_hit_landed(hit: HitInfo, heavy: bool) -> void:
	_since_combat = 0.0
	match kind():
		ClassData.ResourceKind.OIL:
			_set_resource(resource + OIL_PER_HIT)
		ClassData.ResourceKind.TALLY:
			_since_tally = 0.0
			var notches := 2.0 if (heavy or hit.is_crit) else 1.0
			if hit.is_riposte:
				notches = 3.0
			_set_resource(resource + notches)


func on_blocked() -> void:
	_since_combat = 0.0
	if kind() == ClassData.ResourceKind.RESOLVE:
		_set_resource(resource + RESOLVE_PER_BLOCK)


func on_hit_taken() -> void:
	_since_combat = 0.0
	if kind() == ClassData.ResourceKind.RESOLVE:
		_set_resource(resource + RESOLVE_PER_HIT_TAKEN)


# --- Using abilities ------------------------------------------------------------

## Why an ability can't be used right now ("" = it can).
func why_not(a: AbilityData) -> String:
	if not stats().ability_unlocked(a):
		return "Unlocks at level %d" % a.unlock_level
	if cooldown_left(a) > 0.0:
		return "Not ready"
	if a.needs_shield and player.shield == null:
		return "Needs a shield"
	if kind() == ClassData.ResourceKind.TALLY:
		if a.kind == AbilityData.Kind.BEHEAD and resource < 1.0:
			return "Needs a notch"
	elif resource < a.cost:
		return "Not enough %s" % stats().class_data.resource_label
	return ""


func try_use(slot: int) -> bool:
	var list := abilities()
	if slot < 0 or slot >= list.size():
		return false
	var a := list[slot]
	var reason := why_not(a)
	if reason != "":
		CombatFx.word(player.global_position + Vector3.UP * 2.2, reason)
		return false
	if not player.can_start_ability():
		return false
	_pay(a)
	var cd := a.cooldown
	if a.kind == AbilityData.Kind.KINDLE:
		cd *= stats().mod_mult("kindle_cooldown_mult")
	cooldowns[a.id] = cd
	_since_combat = 0.0
	ability_used.emit(slot)
	if a.attack:
		player.start_ability_strike(a)
	else:
		player.start_cast(a)
	return true


var _behead_notches := 0.0

func _pay(a: AbilityData) -> void:
	if kind() == ClassData.ResourceKind.TALLY:
		if a.kind == AbilityData.Kind.BEHEAD:
			_behead_notches = resource
			_set_resource(0.0)
		return
	_set_resource(resource - a.cost)


## Adjust a strike ability's hit before it's sent (damage, status, threat...).
func modify_strike_hit(a: AbilityData, hit: HitInfo, target: Node3D) -> void:
	hit.status = a.status
	hit.status_amount = a.status_amount
	hit.threat_mult *= a.threat_mult
	match a.kind:
		AbilityData.Kind.SHIELD_BASH:
			if stats().mod_add("shield_bash_bleed") > 0.0:
				hit.status = Effects.Status.BLEED
				hit.status_amount = stats().mod_add("shield_bash_bleed")
		AbilityData.Kind.HAMSTRING:
			hit.status_amount *= stats().mod_mult("hamstring_bleed_mult")
			hit.slow = a.value
			hit.slow_time = a.duration
		AbilityData.Kind.BEHEAD:
			var mult := 0.8 + 0.5 * _behead_notches
			var low: bool = target.has_method("health_ratio") and float(target.call(&"health_ratio")) < 0.3
			if low:
				mult *= 2.0 + stats().mod_add("behead_low_health_mult_add")
				var refund := stats().mod_add("behead_refund")
				if refund > 0.0:
					_set_resource(resource + refund)
			hit.damage *= mult
		AbilityData.Kind.CLEAVE:
			if stats().mod_add("cleave_bleed") > 0.0:
				hit.status = Effects.Status.BLEED
				hit.status_amount = stats().mod_add("cleave_bleed")


## Strike abilities that build Tally per enemy hit.
func on_strike_hit(a: AbilityData) -> void:
	if a.kind == AbilityData.Kind.HAMSTRING or a.kind == AbilityData.Kind.CLEAVE:
		_since_tally = 0.0
		_set_resource(resource + 1.0)


## The moment a cast ability takes effect.
func cast_effect(a: AbilityData) -> void:
	var p := player
	var power := a.power * stats().ability_power()
	match a.kind:
		AbilityData.Kind.CHALLENGE:
			var t := p.forward_target(a.ability_range)
			if t:
				_taunt(t, a.duration + stats().mod_add("challenge_duration_add"))
				CombatFx.word(t.global_position + Vector3.UP * 2.6, "Challenged!")
			else:
				CombatFx.word(p.global_position + Vector3.UP * 2.2, "No target")
		AbilityData.Kind.RALLYING_BELLOW:
			var r := a.radius * stats().mod_mult("bellow_radius_mult")
			for e in _enemies_near(p.global_position, r):
				_taunt(e, a.duration)
			for ally in _allies_near(p.global_position, r):
				_buff(ally, &"rallied", 6.0, {"damage_taken": 1.0 - a.value, "label": "Rallied"})
			_visual(&"bellow", p.global_position, r, 0.6)
		AbilityData.Kind.UNBROKEN:
			_buff(p, &"unbroken", a.duration + stats().mod_add("unbroken_duration_add"),
					{"damage_taken": 1.0 - a.value, "min_health": true, "label": "Unbroken"})
			var refill := stats().mod_add("unbroken_stamina_refill")
			if refill > 0.0:
				p.restore_stamina(refill)
		AbilityData.Kind.KINDLE:
			var range_m := a.ability_range * stats().mod_mult("kindle_range_mult")
			var target := p.aim_point(range_m)
			var ember: Node3D = EMBER_SCRIPT.new()
			ember.set(&"caster", self)
			ember.set(&"heal", power * stats().mod_mult("kindle_heal_mult"))
			ember.set(&"damage", a.value * stats().ability_power() * stats().mod_mult("kindle_enemy_damage_mult"))
			ember.set(&"radius", a.radius * stats().mod_mult("kindle_radius_mult"))
			ember.set(&"from", p.global_position + Vector3.UP * 1.6 + p.model.forward() * 0.4)
			ember.set(&"to", target)
			ember.set(&"owned", true)
			CombatFx.world().add_child(ember)
			_net_ember.rpc(ember.get(&"from"), target)
		AbilityData.Kind.VIGIL_LANTERN:
			_area(&"vigil", p.aim_point(a.ability_range), a.radius, a.duration + stats().mod_add("vigil_duration_add"), power)
		AbilityData.Kind.SNUFF:
			_area(&"snuff", p.aim_point(a.ability_range), a.radius, a.duration, stats().mod_add("snuff_heal") * stats().ability_power())
		AbilityData.Kind.FLARE:
			var r2 := a.radius * stats().mod_mult("flare_radius_mult")
			for e in _enemies_near(p.global_position, r2):
				var to := e.global_position - p.global_position
				to.y = 0.0
				if to.length() < 1.0 or p.model.forward().angle_to(to) < deg_to_rad(70.0):
					_strike(e, 0.0, a.value, Effects.Status.NONE, 0.0, 1.0)
			_scale_threat(0.5)
			_visual(&"flare", p.global_position + Vector3.UP * 1.4 + p.model.forward() * 1.0, r2, 0.35)
		AbilityData.Kind.BEACON:
			_area(&"beacon", p.aim_point(a.ability_range), a.radius, a.duration * stats().mod_mult("beacon_delay_mult"), power)
		AbilityData.Kind.PYRE:
			_area(&"pyre", p.global_position, a.radius, a.duration, power * stats().mod_mult("pyre_regen_mult"), a.value)
		AbilityData.Kind.FEINT:
			_scale_threat(1.0 - (a.value + stats().mod_add("feint_threat_drop_add")))
			_buff(p, &"feint", 3.0, {"guaranteed_crit": true, "label": "Feint"})
		AbilityData.Kind.RED_MIST:
			_buff(p, &"red_mist", a.duration + stats().mod_add("red_mist_duration_add"),
					{"stamina_cost": 0.5, "lifesteal": 0.05, "damage_taken": 1.15, "label": "Red Mist"})
		AbilityData.Kind.HOLD_THE_LINE:
			_buff(p, &"hold_line", a.duration, {"block_all": true, "label": "Holding the line"})


## Hold the Line: allies right behind you take less damage (called every frame while holding).
func hold_line_cover(a: AbilityData) -> void:
	var p := player
	var reduction := a.value + stats().mod_add("hold_line_ally_reduction_add")
	for ally in _allies_near(p.global_position, 3.5):
		if ally == p:
			continue
		var to := ally.global_position - p.global_position
		to.y = 0.0
		if p.model.forward().dot(to.normalized()) < -0.3:
			_buff(ally, &"covered", 0.4, {"damage_taken": 1.0 - reduction, "label": "Covered"})


## Shoulder Charge / Lunge: hit enemies you run into.
func dash_hit(a: AbilityData, already: Array[Node]) -> void:
	var p := player
	for e in _enemies_near(p.global_position + p.model.forward() * 0.8, 1.4):
		if e in already:
			continue
		already.append(e)
		match a.kind:
			AbilityData.Kind.SHOULDER_CHARGE:
				_strike(e, a.power, a.value, Effects.Status.NONE, 0.0, a.threat_mult)
			AbilityData.Kind.LUNGE:
				_strike(e, p.weapon_damage() * a.power, p.weapon.poise_damage, Effects.Status.NONE, 0.0, 1.0)


# --- Helpers that reach across the network ----------------------------------------

func _strike(e: Node3D, damage: float, poise: float, status: Effects.Status, status_amount: float, threat_mult: float) -> void:
	var hit := player.make_hit(damage, poise)
	hit.status = status
	hit.status_amount = status_amount
	hit.threat_mult *= threat_mult
	e.call(&"receive_hit", hit)


func _taunt(e: Node3D, duration: float) -> void:
	if e.has_method("taunt"):
		e.call(&"taunt", multiplayer.get_unique_id(), duration)


## Lower (or raise) this player's threat on every enemy.
func _scale_threat(mult: float) -> void:
	for e in get_tree().get_nodes_in_group(&"enemies"):
		e.call(&"scale_threat", multiplayer.get_unique_id(), mult)


## Give a buff/debuff to a player (works for friends on other machines).
func _buff(ally: Player, id: StringName, duration: float, values: Dictionary) -> void:
	ally.apply_effect(id, duration, values)


## Heal a player (works for friends on other machines). Lamplighter heals on
## yourself are weaker (passive).
func heal_player(ally: Player, amount: float) -> void:
	if ally == player:
		amount *= stats().mod_mult("self_heal_mult") + stats().mod_add("self_heal_mult_add")
	ally.heal_from(amount, player.player_name)
	Net.report_heal(ally.get_multiplayer_authority(), amount)


func _area(area_kind: StringName, where: Vector3, radius: float, duration: float, power: float, extra := 0.0) -> void:
	var area: Node3D = AREA_SCENE.new()
	area.set(&"kind", area_kind)
	area.set(&"radius", radius)
	area.set(&"duration", duration)
	area.set(&"power", power)
	area.set(&"extra", extra)
	area.set(&"caster", self)
	area.set(&"owned", true)
	CombatFx.world().add_child(area)
	area.global_position = where
	_net_area.rpc(area_kind, where, radius, duration)


func _visual(visual_kind: StringName, where: Vector3, radius: float, duration: float) -> void:
	CombatFx.burst_visual(visual_kind, where, radius, duration)
	_net_visual.rpc(visual_kind, where, radius, duration)


func _enemies_near(where: Vector3, radius: float) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for n in get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Node3D
		if e and e.call(&"can_be_locked") and e.global_position.distance_to(where) <= radius + 0.4:
			out.append(e)
	return out


func _allies_near(where: Vector3, radius: float) -> Array[Player]:
	var out: Array[Player] = []
	for n in get_tree().get_nodes_in_group(&"player"):
		var a := n as Player
		if a and not a.is_dead() and a.global_position.distance_to(where) <= radius:
			out.append(a)
	return out


func allies_in(where: Vector3, radius: float) -> Array[Player]:
	return _allies_near(where, radius)


func enemies_in(where: Vector3, radius: float) -> Array[Node3D]:
	return _enemies_near(where, radius)


func strike_enemy(e: Node3D, damage: float) -> void:
	_strike(e, damage, 0.0, Effects.Status.NONE, 0.0, 1.0)


# --- What other players see -------------------------------------------------------

@rpc("authority", "call_remote", "unreliable")
func _net_ember(from: Vector3, to: Vector3) -> void:
	var ember: Node3D = EMBER_SCRIPT.new()
	ember.set(&"from", from)
	ember.set(&"to", to)
	ember.set(&"owned", false)
	CombatFx.world().add_child(ember)


@rpc("authority", "call_remote", "reliable")
func _net_area(area_kind: StringName, where: Vector3, radius: float, duration: float) -> void:
	var area: Node3D = AREA_SCENE.new()
	area.set(&"kind", area_kind)
	area.set(&"radius", radius)
	area.set(&"duration", duration)
	area.set(&"owned", false)
	CombatFx.world().add_child(area)
	area.global_position = where


@rpc("authority", "call_remote", "unreliable")
func _net_visual(visual_kind: StringName, where: Vector3, radius: float, duration: float) -> void:
	CombatFx.burst_visual(visual_kind, where, radius, duration)
