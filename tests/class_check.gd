extends Node
## Automated class check: every ability of all three classes, plus XP,
## leveling, talents, status effects and threat.
##   ... --headless --script res://tests/run.gd -- class_check

var player: Player
var enemy: Enemy
var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(20)
	player = get_tree().get_first_node_in_group(&"player") as Player
	enemy = scene.get_node("Enemies/Marauder") as Enemy
	(scene.get_node("Enemies/Marauder2") as Node3D).global_position = Vector3(60, 0, 60)

	# --- XP and levels -------------------------------------------------------
	await _setup("class_bulwark", 1)
	enemy.health = 1.0
	player.caster.try_use(0)  # Challenge (nothing else needed)
	await _seconds(0.6)
	await _tap("light_attack")
	await _seconds(1.0)
	_check("killing a Marauder gives XP and a level (level %d, xp %d)" % [player.stats.level, player.stats.xp],
			player.stats.level == 2 and player.stats.xp == 120 - 100)
	player.set_level(10)
	_check("level 10: more health than level 1 (%d)" % player.max_health(), player.max_health() > 130.0)

	# --- Bulwark ---------------------------------------------------------------
	await _setup("class_bulwark", 20)
	_check("Bulwark has a shield and sword", player.shield != null and player.weapon.id == &"weapon_rusty_sword")
	player.caster.try_use(0)  # Challenge
	await _seconds(0.6)
	_check("Challenge taunts (forced target %s)" % str(enemy._taunt_time > 0.0), enemy._taunt_time > 0.0 and enemy.target == player)
	await _setup_keep()
	player.caster.resource = 100.0
	player.caster.try_use(1)  # Shield Bash
	await _wait_state(Enemy.State.STAGGER, 1.2)
	_check("Shield Bash staggers the Marauder (%s)" % Enemy.State.keys()[enemy.state], enemy.state == Enemy.State.STAGGER)
	await _setup("class_bulwark", 20)
	enemy.global_position = player.global_position + Vector3(0, 0, -4.0)
	player.caster.resource = 100.0
	player.caster.try_use(2)  # Shoulder Charge
	await _wait_state(Enemy.State.STAGGER, 1.0)
	_check("Shoulder Charge staggers on impact", enemy.state == Enemy.State.STAGGER)
	await _setup("class_bulwark", 20)
	player.caster.resource = 100.0
	player.caster.try_use(3)  # Rallying Bellow
	await _seconds(0.6)
	_check("Rallying Bellow: taunts and buffs you", enemy._taunt_time > 0.0 and player.effects.has_mod(&"rallied"))
	await _setup("class_bulwark", 20)
	player.caster.resource = 100.0
	player.caster.try_use(4)  # Hold the Line
	await _seconds(0.2)
	enemy.global_position = player.global_position + Vector3(0, 0, 2.0)  # behind
	var hp := player.health
	await _force_attack(0)
	await _seconds(1.8)
	_check("Hold the Line blocks a blow from behind (hp %d -> %d)" % [hp, player.health], player.health == hp)
	await _setup("class_bulwark", 20)
	player.caster.resource = 100.0
	player.caster.try_use(5)  # Unbroken
	await _seconds(0.5)
	player.health = 3.0
	await _force_attack(2)
	await _seconds(1.8)
	_check("Unbroken: can't drop below 1 health (hp %.1f)" % player.health, player.health >= 1.0 and not player.is_dead())

	# --- Lamplighter -------------------------------------------------------------
	await _setup("class_lamplighter", 20)
	_check("Lamplighter starts full of Oil (%d)" % player.caster.resource, player.caster.resource >= 99.0)
	player.health = 50.0
	player.caster.try_use(0)  # Kindle
	await _seconds(0.45)
	_aim_embers_at(player.global_position)
	await _seconds(2.0)
	_check("Kindle heals (self heals at 50%%): hp 50 -> %.1f" % player.health, player.health > 55.0 and player.health < 70.0)
	await _setup("class_lamplighter", 20)
	player.health = 40.0
	player.caster.try_use(1)  # Vigil Lantern
	await _seconds(0.5)
	_move_areas_to(player.global_position)
	await _seconds(3.2)
	_check("Vigil Lantern heals over time (hp 40 -> %.1f)" % player.health, player.health > 45.0)
	await _setup("class_lamplighter", 20)
	player.effects.add_buildup(Effects.Status.POISON, 60.0)
	player.caster.try_use(2)  # Snuff
	await _seconds(0.5)
	_move_areas_to(player.global_position)
	await _seconds(1.5)
	_check("Snuff cures buildup (poison %.0f)" % player.effects.buildup[Effects.Status.POISON], player.effects.buildup[Effects.Status.POISON] < 1.0)
	await _setup("class_lamplighter", 20)
	enemy.add_threat(1, 100.0)
	player.caster.try_use(3)  # Flare
	await _seconds(0.5)
	_check("Flare halves your threat (%.0f)" % enemy.threat.get(1, 0.0), absf(enemy.threat.get(1, 0.0) - 50.0) < 5.0)
	await _setup("class_lamplighter", 20)
	player.health = 30.0
	player.caster.try_use(4)  # Beacon
	await _seconds(0.4)
	_move_areas_to(player.global_position)
	await _seconds(2.0)
	_check("Beacon: big delayed heal (hp 30 -> %.1f)" % player.health, player.health > 55.0)
	await _setup("class_lamplighter", 20)
	var ehp := enemy.health
	player.caster.try_use(5)  # Pyre (centered on you; the enemy is 2 m away)
	await _seconds(2.5)
	_check("Pyre burns enemies inside (%d -> %d) and shelters you" % [ehp, enemy.health],
			enemy.health < ehp and player.effects.has_mod(&"pyre"))

	# --- Headsman ------------------------------------------------------------------
	await _setup("class_headsman", 20)
	_check("Headsman has a two-handed greatsword", player.weapon.two_handed and player.shield == null)
	player.caster.try_use(0)  # Hamstring
	await _seconds(0.9)
	_check("Hamstring: bleed buildup, slow, notches (bleed %.0f, tally %d)" % [enemy.effects.buildup[Effects.Status.BLEED], player.caster.resource],
			enemy.effects.buildup[Effects.Status.BLEED] > 30.0 and enemy.effects.has_mod(&"slow") and player.caster.resource >= 2.0)
	await _setup("class_headsman", 20)
	player.caster._set_resource(5.0)
	ehp = enemy.health
	player.caster.try_use(1)  # Behead (5 notches)
	await _seconds(1.2)
	var big := ehp - enemy.health
	await _setup("class_headsman", 20)
	player.caster._set_resource(1.0)
	ehp = enemy.health
	player.caster.try_use(1)  # Behead (1 notch)
	await _seconds(1.2)
	var small := ehp - enemy.health
	_check("Behead: more notches hit harder (%.0f vs %.0f), notches spent" % [big, small], big > small * 1.5 and player.caster.resource <= 1.0)
	await _setup("class_headsman", 20)
	enemy.global_position = Vector3(40, 0, 40)
	var start := player.global_position
	player.caster.try_use(2)  # Lunge
	await _seconds(0.1)
	var inv := player.is_invulnerable()
	await _seconds(0.8)
	_check("Lunge dashes ~7 m, invincible at start (%.1f m)" % start.distance_to(player.global_position), start.distance_to(player.global_position) > 5.5 and inv)
	await _setup("class_headsman", 20)
	player.caster.try_use(3)  # Cleave
	await _seconds(1.3)
	_check("Cleave hits and carves a notch (tally %d)" % player.caster.resource, player.caster.resource >= 2.0)
	await _setup("class_headsman", 20)
	player.caster.try_use(4)  # Feint
	await _seconds(0.6)
	_check("Feint primes a guaranteed crit", player.effects.any("guaranteed_crit"))
	await _setup("class_headsman", 20)
	player.caster.try_use(5)  # Red Mist
	await _seconds(0.7)
	player.health = 50.0
	await _tap("light_attack")
	await _seconds(0.8)
	_check("Red Mist: hits heal you (hp 50 -> %.1f)" % player.health, player.health > 50.0)

	# --- Talents, locks, threat ---------------------------------------------------
	await _setup("class_lamplighter", 1)
	_check("Locked abilities refuse (Pyre at level 1)", not player.caster.try_use(5))
	player.set_level(9)
	var wick: TalentData = player.stats.class_data.talents[0]
	var bright: TalentData = player.stats.class_data.talents[1]
	var tallow: TalentData = player.stats.class_data.talents[4]
	_check("Row 2 talent locked with 0 points spent", not player.stats.can_pick(tallow))
	player.stats.pick(wick)
	player.stats.pick(bright)
	_check("Long Wick: Kindle range x1.5", absf(player.stats.mod_mult("kindle_range_mult") - 1.5) < 0.01)
	_check("Talent points: 3 at level 9, 1 left", player.stats.talent_points_total() == 3 and player.stats.talent_points_free() == 1)
	await _setup("class_bulwark", 5)
	await _tap("light_attack")
	await _seconds(0.8)
	var bulwark_threat: float = enemy.threat.get(1, 0.0)
	await _setup("class_headsman", 5)
	await _tap("light_attack")
	await _seconds(0.8)
	var headsman_threat: float = enemy.threat.get(1, 0.0)
	_check("Bulwark makes far more threat per hit (%.0f vs %.0f)" % [bulwark_threat, headsman_threat], bulwark_threat > headsman_threat * 1.5)

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


## Fresh player of a class and level facing a fresh, passive Marauder 2 m away.
func _setup(class_id: String, lvl: int) -> void:
	player._set_class(Classes.by_id(StringName(class_id)))
	player.set_level(lvl)
	player.caster.refill()
	player.effects.clear_all()
	await _setup_keep()


func _setup_keep() -> void:
	player.respawn()
	await _frames(2)
	player.global_position = Vector3(0, 0.05, 0)
	player.model.face_instantly(Vector3.FORWARD)
	player.camera_rig.yaw = 0.0
	player.reset_physics_interpolation()
	if player.stats.class_data.resource_kind == ClassData.ResourceKind.OIL:
		player.caster.resource = player.stats.resource_max()
	enemy.reset_from_rest()
	enemy.global_position = Vector3(0, 0, -2.0)
	enemy.model.face_instantly(Vector3.BACK)
	enemy.reset_physics_interpolation()
	enemy.target = player
	enemy._set_state(Enemy.State.CHASE)
	enemy._cooldown = 999.0
	await _frames(10)


func _force_attack(index: int) -> void:
	enemy.model.face_instantly(player.global_position - enemy.global_position)
	enemy.target = player
	enemy.start_attack(index)
	await get_tree().physics_frame


func _wait_state(s: Enemy.State, seconds: float) -> void:
	for i in ceili(seconds * 60.0):
		if enemy.state == s:
			return
		await get_tree().physics_frame


func _aim_embers_at(where: Vector3) -> void:
	for n in CombatFx.world().get_children():
		if n.get_script() == load("res://game/classes/ember.gd"):
			n.set(&"to", where)


func _move_areas_to(where: Vector3) -> void:
	for n in CombatFx.world().get_children():
		if n.get_script() == load("res://game/classes/area_effect.gd"):
			(n as Node3D).global_position = where


func _tap(action: StringName) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().physics_frame
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await _frames(ceili(s * Engine.physics_ticks_per_second))


func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", label])
	if not ok:
		failures += 1
