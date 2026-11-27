class_name AbilityCaster
extends Node
## Runs a player's class abilities: cooldowns, the class resource (Resolve,
## Oil (shown to players as "Mana"), Tally) and what each ability actually does. All numbers come from the
## AbilityData files; talents adjust them through modifiers.
##
## Abilities run on the caster's own machine. Heals, buffs, taunts and damage
## reach other players and enemies over the network (see Player and Enemy).

signal resource_changed(current: float, maximum: float)
signal ability_used(slot: int)

const AREA_SCENE := preload("res://game/classes/area_effect.gd")
const EMBER_SCRIPT := preload("res://game/classes/ember.gd")
const SHIELD_THROW_SCRIPT := preload("res://game/classes/shield_throw.gd")
const BOLT_SCRIPT := preload("res://game/classes/arcane_bolt.gd")

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
	return player.stats.abilities()


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
				_set_resource(resource + OIL_REGEN * stats().mod_mult("oil_regen_mult") * (1.0 + stats().intellect() / 100.0) * delta)
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
	# Talents shorten one ability's cooldown with "<name>_cooldown_mult"
	# (the name is the ability id without "ability_").
	var cd := a.cooldown * stats().mod_mult(String(a.id).trim_prefix("ability_") + "_cooldown_mult")
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
		AbilityData.Kind.WHIRLWIND:
			hit.damage *= stats().mod_mult("whirlwind_damage_mult")
			if stats().mod_add("whirlwind_bleed") > 0.0:
				hit.status = Effects.Status.BLEED
				hit.status_amount = stats().mod_add("whirlwind_bleed")
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
		AbilityData.Kind.BATTLE_FURY:
			_buff(p, &"battle_fury", a.duration + stats().mod_add("battle_fury_duration_add"),
					{"damage_dealt": 1.0 + a.value + stats().mod_add("battle_fury_damage_add"),
					"attack_speed": 1.0 + a.power, "label": "Battle Fury"})
			_visual(&"bellow", p.global_position, 2.0, 0.4, &"fury")
		AbilityData.Kind.IRON_RESOLVE:
			_buff(p, &"iron_resolve", a.duration + stats().mod_add("iron_resolve_duration_add"),
					{"damage_taken": 1.0 - clampf(a.value + stats().mod_add("iron_resolve_reduction_add"), 0.0, 0.8),
					"poise_taken": 1.0 - a.power, "label": "Iron Resolve"})
			_visual(&"bellow", p.global_position, 2.0, 0.4, &"resolve")
		AbilityData.Kind.SHIELD_THROW:
			_throw_shield(a)
		AbilityData.Kind.ARCANE_BOLT:
			_cast_bolt(a)
		AbilityData.Kind.MEND:
			_mend(a)
		AbilityData.Kind.HEX:
			var victim := p.forward_target(a.ability_range)
			if victim and victim.has_method("apply_effect"):
				victim.call(&"apply_effect", &"hex", a.duration + stats().mod_add("hex_duration_add"),
						{"damage_dealt": 1.0 - a.power, "damage_taken": 1.0 + a.value + stats().mod_add("hex_vuln_add"), "label": "Hexed"})
				CombatFx.word(victim.global_position + Vector3.UP * 2.6, "Hexed!")
				CombatFx.burst_visual(&"flare", victim.global_position + Vector3.UP * 1.3, 1.2, 0.35)
				Audio.sfx(&"hex", victim.global_position + Vector3.UP * 1.3)
			else:
				CombatFx.word(p.global_position + Vector3.UP * 2.2, "No target")


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
				var bleed := stats().mod_add("lunge_bleed")
				_strike(e, p.weapon_damage() * a.power, p.weapon.poise_damage,
						Effects.Status.BLEED if bleed > 0.0 else Effects.Status.NONE, bleed, 1.0)


# --- Helpers that reach across the network ----------------------------------------

func _strike(e: Node3D, damage: float, poise: float, status: Effects.Status, status_amount: float, threat_mult: float, positional := false) -> void:
	var hit := player.make_hit(damage, poise)
	hit.status = status
	hit.status_amount = status_amount
	hit.threat_mult *= threat_mult
	if positional:
		# Thrown and fired abilities get the sneak attack and from-behind bonuses too.
		var sneak := player.is_sneak_target(e)
		hit.damage *= player.position_bonus(e, hit, sneak)
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


func _visual(visual_kind: StringName, where: Vector3, radius: float, duration: float, cue := &"") -> void:
	CombatFx.burst_visual(visual_kind, where, radius, duration)
	if cue != &"":
		Audio.sfx(cue, where)
	_net_visual.rpc(visual_kind, where, radius, duration, cue)


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


## A direct hit from a thrown or fired ability.
func strike(e: Node3D, damage: float, poise: float, threat_mult: float) -> void:
	_strike(e, damage, poise, Effects.Status.NONE, 0.0, threat_mult, true)


# --- Primary class abilities ---------------------------------------------------------

## Shield Throw: the shield flies at your target (or straight ahead) and returns.
func _throw_shield(a: AbilityData) -> void:
	var p := player
	var t := p.forward_target(a.ability_range)
	var dir := p.model.forward()
	if t:
		dir = t.global_position - p.global_position
		dir.y = 0.0
		dir = dir.normalized()
		p.model.face_instantly(dir)
	var dist := a.ability_range * stats().mod_mult("shield_throw_range_mult")
	var from := p.global_position + Vector3.UP * 1.2 + dir * 0.6
	var disc: Node3D = SHIELD_THROW_SCRIPT.new()
	disc.set(&"caster", self)
	disc.set(&"follow", p)
	disc.set(&"owned", true)
	disc.set(&"direction", dir)
	disc.set(&"max_distance", dist)
	disc.set(&"damage", p.weapon_damage() * a.power * stats().mod_mult("shield_throw_damage_mult"))
	disc.set(&"poise", a.value)
	disc.set(&"threat_mult", a.threat_mult)
	CombatFx.world().add_child(disc)
	disc.global_position = from
	# While it's away your shield doesn't block (see Player.receive_hit).
	_buff(p, &"shield_away", dist / 26.0 + dist / 30.0 + 0.4, {"shield_away": true})
	_net_shield_throw.rpc(from, dir, dist)


## The shield came home.
func shield_returned() -> void:
	player.effects.remove_mod(&"shield_away")


## Arcane Bolt: homes on your target, else flies straight and hits the first enemy.
func _cast_bolt(a: AbilityData) -> void:
	var p := player
	var from := p.global_position + Vector3.UP * 1.5 + p.model.forward() * 0.5
	var t := p.forward_target(a.ability_range)
	var bolt: Node3D = BOLT_SCRIPT.new()
	bolt.set(&"caster", self)
	bolt.set(&"owned", true)
	bolt.set(&"target", t)
	var dir := p.model.forward()
	var aim := Vector3.ZERO
	if t:
		aim = t.call(&"get_lock_point")
		dir = (aim - from).normalized()
		p.model.face_instantly(dir)
	bolt.set(&"direction", dir)
	bolt.set(&"max_range", a.ability_range + 4.0)
	bolt.set(&"damage", a.power * stats().ability_power() * stats().mod_mult("arcane_bolt_damage_mult"))
	CombatFx.world().add_child(bolt)
	bolt.global_position = from
	_net_bolt.rpc(from, dir, aim, a.ability_range + 4.0)


## Mend: heals the friend in front of you, or yourself if nobody is.
func _mend(a: AbilityData) -> void:
	var p := player
	var amount := a.power * stats().ability_power() * stats().mod_mult("mend_heal_mult")
	var best: Player
	var best_angle := 40.0
	for ally in _allies_near(p.global_position, a.ability_range):
		if ally == p or ally.state == Player.State.DOWNED:
			continue
		var to := ally.global_position - p.global_position
		to.y = 0.0
		var angle := rad_to_deg(p.model.forward().angle_to(to))
		if angle < best_angle:
			best_angle = angle
			best = ally
	if best:
		heal_player(best, amount)
		_visual(&"ember_burst", best.global_position + Vector3.UP * 0.2, 1.2, 0.5, &"mend")
	else:
		p.heal_from(amount, p.player_name)  # no self-heal penalty for Mend
		_visual(&"ember_burst", p.global_position + Vector3.UP * 0.2, 1.2, 0.5, &"mend")


# --- What other players see -------------------------------------------------------

@rpc("authority", "call_remote", "unreliable")
func _net_ember(from: Vector3, to: Vector3) -> void:
	var ember: Node3D = EMBER_SCRIPT.new()
	ember.set(&"from", from)
	ember.set(&"to", to)
	ember.set(&"owned", false)
	CombatFx.world().add_child(ember)


@rpc("authority", "call_remote", "reliable")
func _net_shield_throw(from: Vector3, dir: Vector3, dist: float) -> void:
	var disc: Node3D = SHIELD_THROW_SCRIPT.new()
	disc.set(&"follow", player)
	disc.set(&"owned", false)
	disc.set(&"direction", dir)
	disc.set(&"max_distance", dist)
	CombatFx.world().add_child(disc)
	disc.global_position = from


@rpc("authority", "call_remote", "unreliable")
func _net_bolt(from: Vector3, dir: Vector3, aim_at: Vector3, max_range: float) -> void:
	var bolt: Node3D = BOLT_SCRIPT.new()
	bolt.set(&"owned", false)
	bolt.set(&"direction", dir)
	bolt.set(&"aim_at", aim_at)
	bolt.set(&"max_range", max_range)
	CombatFx.world().add_child(bolt)
	bolt.global_position = from


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
func _net_visual(visual_kind: StringName, where: Vector3, radius: float, duration: float, cue := &"") -> void:
	CombatFx.burst_visual(visual_kind, where, radius, duration)
	if cue != &"":
		Audio.sfx(cue, where)
