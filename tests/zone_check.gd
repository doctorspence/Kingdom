extends Node
## Automated check of the Tithelands: it loads, ladders, the one-way gate,
## wading, shrines, and (as they're added) spawning, travel, map, time, saves.
##   ... --headless --script res://tests/run.gd -- zone_check

var player: Player
var zone: Node
var terrain: ZoneTerrain
var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	zone = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(zone)
	await _frames(30)
	_check("the Tithelands load (%d ms)" % (Time.get_ticks_msec() - t0), Time.get_ticks_msec() - t0 < 15000)
	player = get_tree().get_first_node_in_group(&"player") as Player
	terrain = zone.get_node("Terrain")
	_check("you start at the Crossroads, on the ground", player.global_position.distance_to(Vector3(0, player.global_position.y, 120.4)) < 8.0
			and absf(player.global_position.y - terrain.height_at(player.global_position.x, player.global_position.z)) < 1.0)
	_check("5 shrines (3 on the surface, the camp hearth, one in the Gullet)", get_tree().get_nodes_in_group(&"interactables").filter(func(n: Node) -> bool: return n is Shrine).size() == 5 and get_tree().get_first_node_in_group(&"camp") != null)
	await _seconds(0.5)
	_check("you stand on the ground (no falling through)", player.is_on_floor())

	# --- Watchtower ladder -------------------------------------------------------
	var tower := zone.get_node("Places/Watchtower") as Node3D
	var ladder := tower.get_node("Ladder") as Ladder
	await _go_to(ladder.climb_point(0.0) + ladder.global_transform.basis.z * 0.6)
	player.start_climb(ladder)
	Input.action_press("move_forward")
	await _seconds(7.0)
	Input.action_release("move_forward")
	await _frames(10)
	_check("climb the watchtower ladder to the platform (height %.1f)" % (player.global_position.y - tower.global_position.y),
			player.global_position.y - tower.global_position.y > 9.5 and player.state == Player.State.MOVE)

	# --- One-way gate ----------------------------------------------------------
	var gate := zone.get_node("Places/TowerGate") as ShortcutGate
	var outside := gate.global_position + gate.global_transform.basis.z * 2.0
	await _go_to(outside)
	gate.interact(player)
	await _frames(5)
	_check("the gate won't open from outside", not gate.is_open())
	await _go_to(gate.global_position - gate.global_transform.basis.z * 2.0)
	gate.interact(player)
	await _frames(5)
	_check("the gate opens from inside and stays open", gate.is_open() and WorldState.get_flag(&"opened_watchtower_south"))

	# --- Quarry ladder ------------------------------------------------------------
	var ql := zone.get_node("Places/QuarryLadder") as Ladder
	_check("quarry ladder reaches the rim (%.1f m tall)" % ql.height, ql.height > 3.0)

	# --- Wading -----------------------------------------------------------------------
	var river_spot := Vector3(-28, 0, -5)
	await _go_to(Vector3(river_spot.x, terrain.height_at(river_spot.x, river_spot.z) + 0.2, river_spot.z))
	Input.action_press("move_right")
	await _seconds(1.0)
	var wade_speed := Vector2(player.velocity.x, player.velocity.z).length()
	Input.action_release("move_right")
	_check("wading through the river is slow (%.1f m/s)" % wade_speed, wade_speed < player.tuning.run_speed * 0.7 and wade_speed > 1.0)

	# --- Spawning ------------------------------------------------------------------
	var enemies := zone.get_node("Enemies").get_children()
	_check("enemies spawn around the zone (%d)" % enemies.size(), enemies.size() >= 12)
	var near_start := enemies.filter(func(e: Node3D) -> bool: return Vector2(e.global_position.x, e.global_position.z).distance_to(Vector2(0, 120.4)) < 30.0)
	_check("the Crossroads start is quiet", near_start.is_empty())
	var floating := enemies.filter(func(e: Node3D) -> bool: return e.global_position.y > -20.0 and absf(e.global_position.y - terrain.height_at(e.global_position.x, e.global_position.z)) > 1.5)
	_check("enemies stand on the ground (%d off)" % floating.size(), floating.is_empty())
	var kinds := {}
	for e in enemies:
		kinds[(e as Enemy).data.id] = true
	_check("several kinds appear (%s)" % ", ".join(kinds.keys()), kinds.size() >= 2)
	_check("6-player extras stay empty with 1 player", (zone.get_node("EnemySpawns/HamletEdge") as SpawnPoint).spawned.is_empty()
			and (zone.get_node("EnemySpawns/RaiderCampExtra") as SpawnPoint).spawned.is_empty())
	# Resting rerolls far points, but not one next to a player.
	var hamlet := zone.get_node("EnemySpawns/Hamlet") as SpawnPoint
	var checkpoint := zone.get_node("EnemySpawns/Checkpoint") as SpawnPoint
	await _go_to(hamlet.global_position + Vector3(6, 0, 6))
	var hamlet_before := hamlet.spawned.duplicate()
	var checkpoint_before := checkpoint.spawned.duplicate()
	(zone.get_node("Places/MillShrine") as Shrine).rest(player)
	await _frames(5)
	_check("resting brings far enemies back fresh", checkpoint.spawned.size() == 2 and checkpoint.spawned[0] != checkpoint_before[0])
	_check("...but leaves the ones near you alone", hamlet.spawned == hamlet_before)
	# Named rare: force the roll.
	var camp := zone.get_node("EnemySpawns/HobbCamp") as SpawnPoint
	camp.named_chance = 1.0
	await _go_to(Vector3(0, 0, 120.4))
	(zone.get_node("SpawnDirector") as SpawnDirector).populate(true)
	await _frames(5)
	_check("Hobb the Unhanged can appear at his camp", camp.spawned.size() == 1 and (camp.spawned[0] as Enemy).data.named)

	# --- Exploring: shrines, map fog, fast travel --------------------------------------
	for e in zone.get_node("Enemies").get_children():
		e.remove_from_group(&"enemies")
		e.queue_free()
	var key := player.world_key()
	await _seconds(0.7)
	_check("you find the Crossroads Shrine at the start", player.exploration.found_shrines(key).has("crossroads"))
	_check("the map clears around you, not far away", player.exploration.revealed_at(key, Vector3(0, 0, 120.4), terrain.size)
			and not player.exploration.revealed_at(key, Vector3(-140, 0, -130), terrain.size))
	var quarry := Shrine.by_id(get_tree(), &"quarry")
	var crossroads := Shrine.by_id(get_tree(), &"crossroads")
	_check("you can't travel to a shrine you haven't found", player.travel_to(quarry) != "")
	await _go_to(quarry.global_position + Vector3(4, 0, 4))
	await _seconds(0.7)
	_check("walking up to the Quarry Shrine finds it", player.exploration.found_shrines(key).has("quarry"))
	var why := player.travel_to(crossroads)
	await _frames(5)
	_check("travel back to the Crossroads (%s)" % (why if why != "" else "ok"),
			why == "" and player.global_position.distance_to(crossroads.spawn_transform().origin) < 1.5)
	quarry.rest(player)
	_check("resting remembers your last shrine", player.exploration.last_shrine(key) == "quarry")
	var copy := Exploration.new()
	copy.load_dict(JSON.parse_string(JSON.stringify(player.exploration.to_dict())))
	_check("explored map and shrines survive a save (%.1f%% explored)" % (copy.revealed_fraction(key) * 100.0),
			copy.revealed_fraction(key) > 0.01 and is_equal_approx(copy.revealed_fraction(key), player.exploration.revealed_fraction(key))
			and copy.found_shrines(key) == player.exploration.found_shrines(key) and copy.last_shrine(key) == "quarry")
	var hud := zone.get_node("Hud")
	var map: MapPanel = hud.get(&"_map_panel")
	map.open(player, true)
	await _frames(3)
	_check("the map opens, with every found shrine to travel to", map.visible and map.find_children("*", "Button", true, false).size() == player.found_shrines().size())
	map.close()

	# --- Day, night and rain ------------------------------------------------------------
	var dn := zone.get_node("DayNight") as DayNight
	var sun := zone.get_node("Sun") as DirectionalLight3D
	dn.set_time(0.3)
	await _seconds(1.5)
	var day_sun := sun.light_energy
	_check("daytime: enemies see normally, no lantern (%s)" % dn.clock_text(), Enemy.sight_mult > 0.99 and not player.lantern_lit())
	dn.set_time(dn.day_share() + 0.1)
	await _seconds(1.5)
	_check("night: dark, enemies see half as far, your lantern is lit (%s)" % dn.clock_text(),
			dn.is_night() and sun.light_energy < day_sun * 0.5 and is_equal_approx(Enemy.sight_mult, 0.5) and player.lantern_lit())
	_check("a full day is 48 minutes, a third of it night", is_equal_approx(dn.day_length(), 48.0 * 60.0) and is_equal_approx(1.0 - dn.day_share(), 1.0 / 3.0))
	var t_before := dn.time
	await _seconds(1.0)
	_check("time moves on", dn.time > t_before)
	dn.set_rain(true)
	await _seconds(1.0)
	_check("rain starts falling", DayNight.raining and dn.rain_amount > 0.0 and (dn.get_node("Rain") as GPUParticles3D).emitting)
	var saved_time: Dictionary = JSON.parse_string(JSON.stringify(dn.to_dict()))
	dn.set_time(0.0)
	dn.set_rain(false)
	dn.load_dict(saved_time)
	_check("time and weather can be saved and restored", absf(dn.time - float(saved_time.time)) < 0.001 and DayNight.raining)
	dn.set_rain(false)
	dn.set_time(0.3)

	# --- World save -------------------------------------------------------------------
	var session := zone.get_node("GameSession") as GameSession
	Loot._host_create_pile(1, "Tester", [], 77, 5, player.global_position + Vector3(3, 0, 0))
	dn.set_time(0.42)
	await _frames(3)
	var world: Dictionary = JSON.parse_string(JSON.stringify(session.world_data()))
	_check("the world file is written and read back", SaveSystem.save_world(world.duplicate(true).merged({"name": "zz_check_world"}, true))
			and SaveSystem.load_world("zz_check_world").get("flags", {}).has("opened_watchtower_south"))
	SaveSystem.delete_world("zz_check_world")
	WorldState.reset()
	Loot.clear_piles()
	dn.set_time(0.0)
	session.apply_world(world)
	await _frames(5)
	_check("loading a world reopens its shortcuts", WorldState.get_flag(&"opened_watchtower_south") == true)
	_check("...brings back its time of day", absf(dn.time - 0.42) < 0.01)
	_check("...and its death piles, with their gold", Loot.pile_count() == 1 and int((Loot.piles()[0] as Node).get(&"gold")) == 77)

	# --- The camp in the real zone: raiders start inside the walls, on dry land ----------------
	var hearth_camp := get_tree().get_first_node_in_group(&"camp") as Camp
	var spots_ok := true
	var worst := ""
	if hearth_camp:
		for bearing in range(0, 360, 30):
			hearth_camp.raids.bearing = bearing
			for i in 3:
				var p := hearth_camp.raids._find_spot()
				var half := terrain.size * 0.5 - 8.0
				var wet := terrain.height_at(p.x, p.z) < terrain.water_level() + 0.2
				if absf(p.x) > half or absf(p.z) > half or wet:
					spots_ok = false
					worst = "%.0f, %.0f at bearing %d" % [p.x, p.z, bearing]
	_check("raiders never start outside the walls or in the river (%s)" % worst, hearth_camp != null and spots_ok)

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _go_to(where: Vector3) -> void:
	if where.y == 0.0:
		where.y = terrain.height_at(where.x, where.z) + 0.2
	player.global_position = where
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	await _frames(5)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await _frames(ceili(s * Engine.physics_ticks_per_second))


func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", label])
	if not ok:
		failures += 1
