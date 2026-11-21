extends Node
## Automated class check: every ability of all three classes, plus XP,
## leveling, talents, status effects and threat.
##   ... --headless --script res://tests/run.gd -- class_check

var player: Player
var enemy: Enemy
var enemy2: Enemy
var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(20)
	player = get_tree().get_first_node_in_group(&"player") as Player
	enemy = scene.get_node("Enemies/Marauder") as Enemy
	enemy2 = scene.get_node("Enemies/Marauder2") as Enemy
	enemy2.global_position = Vector3(60, 0, 60)


	# --- XP and levels -------------------------------------------------------
	await _setup("class_bulwark", 1)
	enemy.health = 1.0
	await _tap("light_attack")
	await _seconds(1.0)
	_check("killing a Marauder gives XP and a level (level %d, xp %d)" % [player.stats.level, player.stats.xp],
			player.stats.level == 2 and player.stats.xp == 120 - 100)
	player.set_level(10)
	_check("level 10: more health than level 1 (%d)" % player.max_health(), player.max_health() > 130.0)

	# --- Unlocks: abilities at levels 2, 4 and 6, three per class -------------------
	for cid in ["class_headsman", "class_bulwark", "class_lamplighter"]:
		var cd := Classes.by_id(StringName(cid))
		var levels: Array = []
		for a in cd.abilities:
			levels.append(a.unlock_level)
		_check("%s has exactly three abilities, unlocking at 2, 4, 6 (%s)" % [cd.display_name, str(levels)],
				levels == [2, 4, 6])
	await _setup("class_lamplighter", 1)
	_check("Locked abilities refuse (Arcane Bolt at level 1)", not player.caster.try_use(0))
	player.set_level(2)
	_check("Level 2 unlocks the first ability", player.caster.why_not(player.stats.class_data.abilities[0]) == "")
	_check("Level 2 does not unlock the second", player.caster.why_not(player.stats.class_data.abilities[1]) != "")
	player.set_level(10)
	_check("Level 10 still has all three (no abilities lost)", player.stats.class_data.abilities.size() == 3
			and player.stats.ability_unlocked(player.stats.class_data.abilities[2]))

	# --- Martial -------------------------------------------------------------------
	await _setup("class_headsman", 20)
	_check("Martial has a two-handed greatsword", player.weapon.two_handed and player.shield == null)
	enemy.global_position = Vector3(3.0, 0, -6.0)  # ahead and off to the side
	var ehp := enemy.health
	var start := player.global_position
	player.caster.try_use(0)  # Lunge
	await _seconds(0.1)
	var inv := player.is_invulnerable()
	await _seconds(0.9)
	_check("Lunge closes on the target and hits it (moved %.1f m, hp %d -> %d)" % [start.distance_to(player.global_position), ehp, enemy.health],
			start.distance_to(player.global_position) > 3.0 and enemy.health < ehp)
	_check("Lunge: invulnerable at the start", inv)
	await _setup("class_headsman", 20)
	enemy2.global_position = Vector3(-1.6, 0, 1.6)  # behind you
	enemy2.reset_physics_interpolation()
	ehp = enemy.health
	var e2hp := enemy2.health
	player.caster.try_use(1)  # Whirlwind
	await _seconds(1.4)
	_check("Whirlwind hits enemies in front AND behind (%d -> %d, %d -> %d)" % [ehp, enemy.health, e2hp, enemy2.health],
			enemy.health < ehp and enemy2.health < e2hp)
	_park_enemy2()
	await _setup("class_headsman", 20)
	player.caster.try_use(2)  # Battle Fury
	await _seconds(0.7)
	_check("Battle Fury: more damage and faster attacks (x%.2f dmg, x%.2f speed)" % [player.effects.product("damage_dealt"), player.effects.product("attack_speed")],
			player.effects.product("damage_dealt") > 1.2 and player.effects.product("attack_speed") > 1.2)
	_check("Battle Fury has a cooldown", player.caster.cooldown_left(player.stats.class_data.abilities[2]) > 30.0)

	# --- Vanguard --------------------------------------------------------------------
	await _setup("class_bulwark", 20)
	_check("Vanguard has a shield and sword", player.shield != null and player.weapon.id == &"weapon_rusty_sword")
	player.caster.try_use(0)  # Shield Bash
	await _wait_state(Enemy.State.STAGGER, 1.2)
	_check("Shield Bash staggers the Marauder (%s)" % Enemy.State.keys()[enemy.state], enemy.state == Enemy.State.STAGGER)
	await _setup("class_bulwark", 20)
	enemy.global_position = Vector3(0, 0, -6.0)
	enemy2.global_position = Vector3(0, 0, -9.0)
	enemy2.reset_physics_interpolation()
	ehp = enemy.health
	e2hp = enemy2.health
	player.caster.try_use(1)  # Shield Throw
	await _seconds(0.5)
	_check("Shield Throw: the shield is away (no blocking)", player.effects.any("shield_away"))
	await _seconds(1.5)
	_check("Shield Throw hits both enemies in its path (%d -> %d, %d -> %d)" % [ehp, enemy.health, e2hp, enemy2.health],
			enemy.health < ehp and enemy2.health < e2hp)
	await _seconds(2.0)
	_check("Shield Throw: the shield comes back", not player.effects.any("shield_away"))
	_park_enemy2()
	await _setup("class_bulwark", 20)
	player.effects.clear_all()
	player.caster.try_use(2)  # Iron Resolve
	await _seconds(0.6)
	_check("Iron Resolve: less damage and poise taken (x%.2f, x%.2f)" % [player.effects.damage_taken_mult(), player.effects.product("poise_taken")],
			player.effects.damage_taken_mult() < 0.65 and player.effects.product("poise_taken") < 0.5)
	await _setup("class_bulwark", 1)
	_check("Shield Bash is locked at level 1", not player.caster.try_use(0))

	# --- Mystic ----------------------------------------------------------------------
	await _setup("class_lamplighter", 20)
	_check("Mystic starts full of Oil (%d)" % player.caster.resource, player.caster.resource >= 99.0)
	enemy.global_position = Vector3(0, 0, -8.0)
	ehp = enemy.health
	player.caster.try_use(0)  # Arcane Bolt
	await _seconds(1.2)
	_check("Arcane Bolt damages the enemy (%d -> %d) and costs Oil (%d)" % [ehp, enemy.health, player.caster.resource],
			enemy.health < ehp and player.caster.resource < 95.0)
	await _setup("class_lamplighter", 20)
	player.health = 30.0
	player.caster.try_use(1)  # Mend (nobody else is here, so it heals you)
	await _seconds(0.8)
	_check("Mend heals you with no friend in front (hp 30 -> %.1f)" % player.health, player.health > 70.0)
	await _setup("class_lamplighter", 20)
	player.caster.try_use(2)  # Hex
	await _seconds(0.8)
	_check("Hex curses the enemy (less damage dealt, more taken)",
			enemy.effects.has_mod(&"hex") and enemy.effects.product("damage_dealt") < 0.8 and enemy.effects.damage_taken_mult() > 1.15)
	await _setup("class_lamplighter", 20)
	player.caster.resource = 0.0
	_check("Mystic abilities need Oil", not player.caster.try_use(1))

	# --- Talents and threat ----------------------------------------------------------
	await _setup("class_lamplighter", 9)
	var reservoir: TalentData = player.stats.class_data.talents[0]
	var keen: TalentData = player.stats.class_data.talents[1]
	var steady: TalentData = player.stats.class_data.talents[4]
	_check("Row 2 talent locked with 0 points spent", not player.stats.can_pick(steady))
	player.stats.pick(reservoir)
	player.stats.pick(keen)
	_check("Keen Mind: Arcane Bolt x1.25", absf(player.stats.mod_mult("arcane_bolt_damage_mult") - 1.25) < 0.01)
	_check("Talent points: 3 at level 9, 1 left", player.stats.talent_points_total() == 3 and player.stats.talent_points_free() == 1)
	await _setup("class_bulwark", 5)
	await _tap("light_attack")
	await _seconds(0.8)
	var bulwark_threat: float = enemy.threat.get(1, 0.0)
	await _setup("class_headsman", 5)
	await _tap("light_attack")
	await _seconds(0.8)
	var headsman_threat: float = enemy.threat.get(1, 0.0)
	_check("Vanguard makes far more threat per hit (%.0f vs %.0f)" % [bulwark_threat, headsman_threat], bulwark_threat > headsman_threat * 1.5)

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


## Put the second Marauder back out of the way, fresh.
func _park_enemy2() -> void:
	enemy2.reset_from_rest()
	enemy2.global_position = Vector3(60, 0, 60)
	enemy2.reset_physics_interpolation()


## Fresh player of a class and level facing a fresh, passive Marauder 2 m away.
func _setup(class_id: String, lvl: int) -> void:
	player._set_class(Classes.by_id(StringName(class_id)))
	player._give_starting_gear()
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
