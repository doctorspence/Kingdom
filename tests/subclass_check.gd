extends Node
## Automated subclass check: the nine subclasses and three factions as data,
## the level 10 rules, the hotbar, passives, saving, syncing to friends, the
## choice screen, and the abilities the first three paths bring.
##   ... --headless --script res://tests/run.gd -- subclass_check

var player: Player
var enemy: Enemy
var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	# --- Data ----------------------------------------------------------------------------
	_check("nine subclasses and three factions", Subclasses.ALL.size() == 9 and Subclasses.FACTIONS.size() == 3)
	var ids := {}
	for s in Subclasses.ALL:
		ids[s.id] = true
	_check("subclass ids are unique", ids.size() == 9)
	for c in Classes.ALL:
		_check("%s has three subclasses" % c.display_name, Subclasses.for_class(c.id).size() == 3)
	var lore_ok := true
	var faction_ok := true
	for s in Subclasses.ALL:
		if s.identity == "" or s.weapon_specialties == "" or s.progression_direction == "" or s.initiation_title == "" or s.initiation_story == "":
			lore_ok = false
		var f := Subclasses.faction(s.faction)
		if not (s.id in f.associated_subclasses):
			faction_ok = false
	_check("every subclass has its lore text", lore_ok)
	_check("every subclass is listed under the faction it is tied to", faction_ok)
	var built_ok := true
	for s in Subclasses.ALL:
		if s.available:
			var lv := s.abilities.map(func(a: AbilityData) -> int: return a.unlock_level)
			if lv != [10, 15, 20]:
				built_ok = false
		elif not s.abilities.is_empty():
			built_ok = false
	_check("built subclasses have abilities at 10, 15, 20; unbuilt ones have none", built_ok)
	_check("exactly Warrior, Guardian and Cleric are available", Subclasses.ALL.filter(func(s: SubclassData) -> bool: return s.available).map(func(s: SubclassData) -> StringName: return s.id) \
			== [&"subclass_warrior", &"subclass_guardian", &"subclass_cleric"])

	# --- The rules (CharacterStats) -----------------------------------------------------
	var stats := CharacterStats.new(Classes.by_id(&"class_headsman"))
	stats.set_level(9)
	_check("level 9: can't choose yet", not stats.can_choose_subclass() and stats.why_not_subclass(Subclasses.by_id(&"subclass_warrior")) != "")
	stats.set_level(10)
	_check("level 10: can choose", stats.can_choose_subclass())
	_check("another class's path is refused", stats.why_not_subclass(Subclasses.by_id(&"subclass_guardian")) == "Belongs to another class")
	_check("an unbuilt path says 'Coming later'", stats.why_not_subclass(Subclasses.by_id(&"subclass_rogue")) == "Coming later")
	_check("a Martial has 3 abilities before choosing", stats.abilities().size() == 3)
	var heavy_before := stats.mod_mult("heavy_damage_mult")
	_check("choosing Warrior works", stats.choose_subclass(Subclasses.by_id(&"subclass_warrior")) == "")
	_check("the hotbar now has the class's 3 then the subclass's 3 (%d)" % stats.abilities().size(),
			stats.abilities().size() == 6 and stats.abilities()[0].id == &"ability_lunge" and stats.abilities()[3].id == &"ability_cleave")
	_check("the subclass passive applies (heavy x%.2f -> x%.2f)" % [heavy_before, stats.mod_mult("heavy_damage_mult")],
			stats.mod_mult("heavy_damage_mult") > heavy_before * 1.09)
	_check("the choice can't be taken twice", stats.choose_subclass(Subclasses.by_id(&"subclass_warrior")) == "You already follow a path")
	stats.clear_subclass()
	_check("clearing it (a future re-pick) gives the three abilities back", stats.subclass == null and stats.abilities().size() == 3 and stats.can_choose_subclass())

	# --- In the arena: saves, friends, the screen, the abilities -----------------------
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(20)
	player = get_tree().get_first_node_in_group(&"player") as Player
	enemy = scene.get_node("Enemies/Marauder") as Enemy
	(scene.get_node("Enemies/Marauder2") as Node3D).global_position = Vector3(60, 0, 60)

	await _setup("class_bulwark", 10)
	_check("a level 10 Vanguard can choose", player.stats.can_choose_subclass())
	_check("choose_subclass on the player: Guardian", player.choose_subclass(&"subclass_guardian") == "")
	_check("the choice is shared with friends (net_subclass = %s)" % player.net_subclass, player.net_subclass == &"subclass_guardian")
	# A friend's copy of this character learns it from net_subclass.
	player.stats.clear_subclass()
	player.net_subclass = &"subclass_guardian"
	player.net_pos = player.global_position
	player._proxy_update(0.016)
	_check("a friend's copy follows net_subclass", player.stats.subclass != null and player.stats.subclass.id == &"subclass_guardian")

	# Saving and loading.
	player._load_character({"class": "class_lamplighter", "level": 12, "xp": 0, "talents": [], "subclass": "subclass_cleric", "inventory": {}})
	_check("loading a save restores the subclass (%s)" % str(player.stats.subclass.id if player.stats.subclass else "none"),
			player.stats.subclass != null and player.stats.subclass.id == &"subclass_cleric" and player.net_subclass == &"subclass_cleric")
	player._load_character({"class": "class_lamplighter", "level": 12, "xp": 0, "talents": [], "subclass": "subclass_warrior", "inventory": {}})
	_check("a save with another class's subclass is ignored", player.stats.subclass == null)
	player._load_character({"class": "class_lamplighter", "level": 3, "xp": 0, "talents": [], "inventory": {}})
	_check("an old save with no subclass still loads", player.stats.subclass == null)

	# The choice screen.
	await _setup("class_headsman", 10)
	var panel := SubclassPanel.new()
	add_child(panel)
	await get_tree().process_frame
	panel.open(player)
	await get_tree().process_frame
	var warrior_btn := panel.find_child("Choose_subclass_warrior", true, false) as Button
	var rogue_btn := panel.find_child("Choose_subclass_rogue", true, false) as Button
	_check("the screen shows all three paths", panel.find_children("Choose_*", "Button", true, false).size() == 3)
	_check("Warrior can be chosen; Rogue says 'Coming later'", warrior_btn != null and not warrior_btn.disabled and rogue_btn != null and rogue_btn.disabled and rogue_btn.text == "Coming later")
	warrior_btn.pressed.emit()
	_check("choosing asks for a confirmation first", panel._confirm.visible and player.stats.subclass == null)
	(panel._confirm.find_child("Confirm", true, false) as Button).pressed.emit()
	_check("confirming takes the path and closes the screen", player.stats.subclass != null and player.stats.subclass.id == &"subclass_warrior" and not panel.visible)
	panel.queue_free()

	# --- The abilities --------------------------------------------------------------------
	await _setup("class_headsman", 20)
	player.choose_subclass(&"subclass_warrior")
	player.caster.refill()
	var ehp := enemy.health
	player.caster.try_use(3)  # Cleave
	await _seconds(1.3)
	_check("Warrior: Cleave hits (%d -> %d) and carves a notch (%d)" % [ehp, enemy.health, player.caster.resource], enemy.health < ehp and player.caster.resource >= 1.0)
	await _setup("class_headsman", 20)
	player.choose_subclass(&"subclass_warrior")
	player.caster.try_use(4)  # Feint
	await _seconds(0.6)
	_check("Warrior: Feint primes a guaranteed crit", player.effects.any("guaranteed_crit"))
	await _setup("class_headsman", 20)
	player.choose_subclass(&"subclass_warrior")
	player.caster.try_use(5)  # Red Mist
	await _seconds(0.7)
	player.health = 50.0
	await _tap("light_attack")
	await _seconds(0.8)
	_check("Warrior: Red Mist heals on hit (hp 50 -> %.1f)" % player.health, player.health > 50.0)

	await _setup("class_bulwark", 20)
	player.choose_subclass(&"subclass_guardian")
	player.caster.resource = 100.0
	player.caster.try_use(3)  # Rallying Bellow
	await _seconds(0.7)
	_check("Guardian: Rallying Bellow taunts and shelters you", enemy._taunt_time > 0.0 and player.effects.has_mod(&"rallied"))
	await _setup("class_bulwark", 20)
	player.choose_subclass(&"subclass_guardian")
	player.caster.resource = 100.0
	player.caster.try_use(4)  # Hold the Line
	await _seconds(0.2)
	enemy.global_position = player.global_position + Vector3(0, 0, 2.0)
	var hp := player.health
	await _force_attack(0)
	await _seconds(1.8)
	_check("Guardian: Hold the Line blocks a blow from behind (hp %d -> %d)" % [hp, player.health], player.health == hp)
	await _setup("class_bulwark", 20)
	player.choose_subclass(&"subclass_guardian")
	player.caster.resource = 100.0
	player.caster.try_use(5)  # Unbroken
	await _seconds(0.5)
	player.health = 3.0
	await _force_attack(2)
	await _seconds(1.8)
	_check("Guardian: Unbroken can't drop below 1 health (hp %.1f)" % player.health, player.health >= 1.0 and not player.is_dead())
	await _setup("class_bulwark", 12)
	player.choose_subclass(&"subclass_guardian")
	_check("Guardian: level 15 ability stays locked at level 12", not player.caster.try_use(4))

	await _setup("class_lamplighter", 20)
	player.choose_subclass(&"subclass_cleric")
	player.effects.add_buildup(Effects.Status.POISON, 60.0)
	player.caster.try_use(3)  # Snuff
	await _seconds(0.5)
	_move_areas_to(player.global_position)
	await _seconds(1.5)
	_check("Cleric: Snuff cures buildup (poison %.0f)" % player.effects.buildup[Effects.Status.POISON], player.effects.buildup[Effects.Status.POISON] < 1.0)
	await _setup("class_lamplighter", 20)
	player.choose_subclass(&"subclass_cleric")
	player.health = 30.0
	player.caster.try_use(4)  # Beacon
	await _seconds(0.4)
	_move_areas_to(player.global_position)
	await _seconds(2.0)
	_check("Cleric: Beacon heals a lot (hp 30 -> %.1f)" % player.health, player.health > 55.0)
	await _setup("class_lamplighter", 20)
	player.choose_subclass(&"subclass_cleric")
	ehp = enemy.health
	player.caster.try_use(5)  # Pyre
	await _seconds(2.5)
	_check("Cleric: Pyre burns enemies inside (%d -> %d) and shelters you" % [ehp, enemy.health], enemy.health < ehp and player.effects.has_mod(&"pyre"))

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _setup(class_id: String, lvl: int) -> void:
	player._set_class(Classes.by_id(StringName(class_id)))
	player._give_starting_gear()
	player.net_subclass = &""
	player.set_level(lvl)
	player.caster.refill()
	player.effects.clear_all()
	player.respawn()
	await _frames(2)
	player.global_position = Vector3(0, 0.05, 0)
	player.model.face_instantly(Vector3.FORWARD)
	player.camera_rig.yaw = 0.0
	player.reset_physics_interpolation()
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
