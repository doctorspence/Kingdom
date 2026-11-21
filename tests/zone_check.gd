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
	_check("you start at the Crossroads, on the ground", player.global_position.distance_to(Vector3(0, player.global_position.y, 172)) < 8.0
			and absf(player.global_position.y - terrain.height_at(player.global_position.x, player.global_position.z)) < 1.0)
	_check("3 shrines", get_tree().get_nodes_in_group(&"interactables").filter(func(n: Node) -> bool: return n is Shrine).size() == 3)
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
	_check("quarry ladder reaches the rim (%.1f m tall)" % ql.height, ql.height > 6.0)

	# --- Wading -----------------------------------------------------------------------
	var river_spot := Vector3(-40, 0, -7)
	await _go_to(Vector3(river_spot.x, terrain.height_at(river_spot.x, river_spot.z) + 0.2, river_spot.z))
	Input.action_press("move_right")
	await _seconds(1.0)
	var wade_speed := Vector2(player.velocity.x, player.velocity.z).length()
	Input.action_release("move_right")
	_check("wading through the river is slow (%.1f m/s)" % wade_speed, wade_speed < 3.0 and wade_speed > 1.0)

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
