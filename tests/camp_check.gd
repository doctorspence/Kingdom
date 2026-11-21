extends Node
## Automated camp check: claiming, the cold hearth, upgrades and their looks,
## the Camp menu, and night raids (size, march, camp strength, winning, being
## overrun, dawn, the dusk trigger, rewards).
##   ... --headless --script res://tests/run.gd -- camp_check

var player: Player
var camp: Camp
var failures := 0
var _messages: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	WorldState.reset()
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(20)
	player = get_tree().get_first_node_in_group(&"player") as Player
	for n in get_tree().get_nodes_in_group(&"enemies"):
		(n as Node3D).global_position = Vector3(300, 0, 300)  # out of the way
		(n as Enemy).queue_free()
	await _frames(5)

	# A camp is a shrine with the camp script, a little away from the arena's middle.
	var shrine: Node3D = (load("res://game/world/shrine.tscn") as PackedScene).instantiate()
	shrine.set_script(load("res://game/world/camp.gd"))
	shrine.set(&"shrine_name", "Camp Hearth")
	shrine.set(&"shrine_id", &"camp")
	scene.add_child(shrine)
	shrine.global_position = Vector3(0, 0, -30)
	camp = shrine as Camp
	await _frames(5)
	camp.raids.message.connect(func(t: String) -> void: _messages.append(t))
	camp.raids.enemies_root = scene.get_node("Enemies")
	DayNight.night = 0.0
	camp.raids._was_night = false

	# --- Claiming -----------------------------------------------------------------------
	_check("a new camp is cold and unclaimed", not camp.is_claimed() and not camp.is_active())
	_check("it offers to be claimed (%s)" % camp.get_interact_text(), camp.get_interact_text().begins_with("Claim"))
	_check("you can't rest at an unclaimed camp", camp.rest(player) == "The hearth is cold")
	player.inventory.gold = 20
	_check("claiming without gold is refused", camp.claim(player).begins_with("Not enough gold") and not camp.is_claimed())
	player.inventory.gold = 130
	_check("claiming costs 100 gold", camp.claim(player) == "" and player.inventory.gold == 30 and camp.is_claimed() and camp.is_active())
	await _frames(3)
	_check("a claimed camp shows a banner (%d decor pieces)" % camp._decor.get_child_count(), camp._decor.get_child_count() >= 2)
	_check("it can be rested at again", camp.get_interact_text().begins_with("Use the Camp Hearth"))

	# --- Upgrades ---------------------------------------------------------------------------
	player.inventory.gold = 5000
	var bodies0 := _count(camp._decor, "StaticBody3D")
	_check("palisade level 1 costs 150", camp.next_cost(&"palisade") == 150 and camp.upgrade(&"palisade", player) == "" and player.inventory.gold == 4850)
	await _frames(3)
	var posts1 := _count(camp._decor, "StaticBody3D")
	camp.upgrade(&"palisade", player)
	await _frames(3)
	var posts2 := _count(camp._decor, "StaticBody3D")
	camp.upgrade(&"palisade", player)
	await _frames(3)
	var posts3 := _count(camp._decor, "StaticBody3D")
	_check("the palisade grows with each level (%d -> %d -> %d -> %d solid posts)" % [bodies0, posts1, posts2, posts3], posts1 > bodies0 and posts2 > posts1 and posts3 > posts2)
	_check("a fourth level is refused", camp.upgrade(&"palisade", player) == "Already at the highest level")
	_check("the three levels cost 150 + 400 + 900", player.inventory.gold == 5000 - 150 - 400 - 900)
	camp.upgrade(&"watch", player)
	await _frames(3)
	var lights1 := _count(camp._decor, "OmniLight3D")
	camp.upgrade(&"watch", player)
	camp.upgrade(&"watch", player)
	await _frames(3)
	var lights3 := _count(camp._decor, "OmniLight3D")
	_check("watchfires: 3 torches at level 1, 9 at level 3 (%d, %d)" % [lights1, lights3], lights1 == 3 and lights3 == 9)
	camp.upgrade(&"stores", player)
	camp.upgrade(&"stores", player)
	camp.upgrade(&"stores", player)
	_check("all upgrades at level 3 (total %d)" % camp.total_level(), camp.total_level() == 9)
	player.inventory.gold = 10
	WorldState.set_flag(Camp.FLAG_COLD, true)
	_check("a cold hearth refuses upgrades", camp.upgrade(&"stores", player) == "The hearth is cold")
	_check("a cold hearth offers to be relit", camp.get_interact_text().begins_with("Relight"))
	player.inventory.gold = 80
	_check("relighting costs 50", camp.relight(player) == "" and player.inventory.gold == 30 and camp.is_active())
	_check("upgrades survive going cold", camp.total_level() == 9)

	# --- The Camp menu ------------------------------------------------------------------------
	WorldState.set_flag(&"camp_palisade", 0)
	player.inventory.gold = 150
	var panel := CampPanel.new()
	add_child(panel)
	await get_tree().process_frame
	panel.open(player, camp)
	await get_tree().process_frame
	var buy_palisade := panel.find_child("Buy_palisade", true, false) as Button
	var buy_watch := panel.find_child("Buy_watch", true, false) as Button
	_check("the menu lists the three upgrades", panel.find_children("Buy_*", "Button", true, false).size() == 3)
	_check("what you can afford is enabled, the rest is not", not buy_palisade.disabled and buy_watch.disabled == (camp.level(&"watch") >= 3 or player.inventory.gold < camp.next_cost(&"watch")))
	buy_palisade.pressed.emit()
	await _frames(2)
	_check("buying from the menu works (palisade %d, gold %d)" % [camp.level(&"palisade"), player.inventory.gold], camp.level(&"palisade") == 1 and player.inventory.gold == 0)
	panel.queue_free()
	WorldState.set_flag(&"camp_palisade", 3)

	# --- Raids ----------------------------------------------------------------------------------
	var raids := camp.raids
	player.global_position = camp.global_position + Vector3(0, 0.1, 6)
	_check("raid size with 1 player and a full camp: 3 + 9/3 = 6 (%d)" % raids.raid_size(), raids.raid_size() == 6)
	raids.start_raid(4)
	await _frames(5)
	_check("a raid starts with 4 raiders and says so (%d, \"%s\")" % [raids.raiders.size(), _messages.back() if not _messages.is_empty() else ""],
			raids.active and raids.raiders.size() == 4 and not _messages.is_empty() and _messages.back().begins_with("Raiders approach"))
	_check("with Watchfires the message names the direction", _messages.back().contains("They come from the"))
	var far_enough := true
	var in_group := true
	for e in raids.raiders:
		var d := e.global_position.distance_to(camp.global_position)
		if d < 60.0 or d > 100.0:
			far_enough = false
		if not e.is_in_group(&"raiders") or e.is_in_group(&"respawn_on_rest"):
			in_group = false
	_check("raiders appear 70-90 m out", far_enough)
	_check("raiders are marked and resting won't undo them", in_group)
	_check("they march to the camp (patrol points at the hearth)", raids.raiders[0].patrol_points.size() == 2
			and raids.raiders[0].patrol_points[0].distance_to(camp.global_position) < 5.0)
	_check("Watchfires level 3 shortens their sight", is_equal_approx(raids.raiders[0].sight_scale, 0.6))
	_check("camp strength starts at 100", is_equal_approx(raids.strength, 100.0))

	# Raiders at the hearth drain the camp.
	raids.raiders[0].global_position = camp.global_position + Vector3(3, 0, 0)
	raids.raiders[1].global_position = camp.global_position + Vector3(-3, 0, 0)
	for e in raids.raiders:
		e.set_physics_process(false)  # hold them still for the measurement
	await _seconds(3.0)
	var drained := 100.0 - raids.strength
	var expected := 2.0 * CampRaids.DRAIN_PER_RAIDER * 0.25 * 3.0
	_check("two raiders at the hearth drain the camp (%.1f, expected about %.1f with a full palisade)" % [drained, expected], absf(drained - expected) < expected * 0.4 + 0.5)

	# Winning.
	var wins_before := camp.wins()
	for e in raids.raiders.duplicate():
		e._die()
	await _frames(3)
	var drops_before := Loot.drop_count()
	await _frames(3)
	_check("killing every raider wins the raid (%s)" % str(raids.active), not raids.active and camp.wins() == wins_before + 1)
	_check("the win refills the camp and says so", is_equal_approx(raids.strength, 100.0) and _messages.back().begins_with("The raid is repelled"))
	var before := Loot.drop_count()
	raids._give_reward()
	await _frames(3)
	_check("the raid chest drops items at Stores level 3 (%d new)" % (Loot.drop_count() - before), Loot.drop_count() - before >= 4)
	_check("the first raid is recorded", bool(WorldState.get_flag(Camp.FLAG_FIRST_RAID, false)))

	# Being overrun.
	raids.start_raid(3)
	await _frames(3)
	raids.strength = 0.4
	for e in raids.raiders:
		e.global_position = camp.global_position + Vector3(2, 0, 2)
		e.set_physics_process(false)
	await _seconds(1.0)
	_check("a camp at 0 strength is overrun: raiders leave, hearth cold (%s / %s)" % [str(raids.active), str(camp.is_cold())],
			not raids.active and camp.is_cold() and raids.raiders.is_empty() and _messages.back().begins_with("The camp is overrun"))
	_check("no resting at a cold hearth", camp.rest(player) == "The hearth is cold")
	player.inventory.gold = 50
	camp.relight(player)
	_check("relighted for 50 gold", camp.is_active())

	# Dawn.
	raids.start_raid(3)
	await _frames(3)
	var wins_now := camp.wins()
	raids._was_night = true
	DayNight.night = 0.0
	await _frames(3)
	_check("dawn sends surviving raiders away, with no reward", not raids.active and camp.wins() == wins_now and _messages.back().begins_with("Dawn comes"))
	await _frames(3)

	# The dusk trigger.
	WorldState.set_flag(Camp.FLAG_FIRST_RAID, false)
	raids._was_night = false
	DayNight.night = 1.0
	await _frames(4)
	_check("at dusk the first raid always comes (%s)" % str(raids.active), raids.active and raids.raiders.size() == 6)
	raids.end_raid(&"fled")
	raids._was_night = true
	await _frames(2)
	player.global_position = camp.global_position + Vector3(0, 0.1, 400)
	raids._was_night = false
	DayNight.night = 0.0
	await _frames(2)
	raids._was_night = false
	DayNight.night = 1.0
	await _frames(4)
	_check("no raid when no player is within 120 m of the camp", not raids.active)
	player.global_position = camp.global_position + Vector3(0, 0.1, 6)
	camp.raids.end_raid(&"fled")
	WorldState.set_flag(Camp.FLAG_COLD, true)
	raids._was_night = false
	DayNight.night = 0.0
	await _frames(2)
	DayNight.night = 1.0
	await _frames(3)
	_check("no raid on a cold camp", not raids.active)
	DayNight.night = 0.0

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _count(root: Node, type_name: String) -> int:
	return root.find_children("*", type_name, true, false).size()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await _frames(ceili(s * Engine.physics_ticks_per_second))


func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", label])
	if not ok:
		failures += 1
