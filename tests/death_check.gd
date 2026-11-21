extends Node
## Automated death check (DESIGN.md 10): keep 3 most valuable items, the pile,
## recovering it, dying twice, fall deaths, the pile timer, boss rooms.
##   ... --headless --script res://tests/run.gd -- death_check

var player: Player
var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(20)
	player = get_tree().get_first_node_in_group(&"player") as Player
	for e in get_tree().get_nodes_in_group(&"enemies"):
		(e as Node3D).global_position = Vector3(80, 0, 80)  # out of the way
	var inv := player.inventory

	# --- Keep 3, drop the rest ---------------------------------------------------
	await _go_to(Vector3(5, 0.05, 5))
	inv.add_item(ItemDB.make_item(ItemDB.get_item(&"item_kettle_helm"), 6, ItemInstance.Rarity.EPIC))
	inv.add_item(ItemDB.make_item(ItemDB.get_item(&"item_iron_ring"), 1, 0))
	inv.add_item(ItemDB.make_item(ItemDB.get_item(&"item_antidote"), 1, 0))
	inv.coins = 100
	inv.souls = 50
	var everything: Array[ItemInstance] = []
	for s in inv.equipped:
		everything.append(inv.equipped[s])
	for uid in inv.backpack.items:
		everything.append(inv.backpack.items[uid])
	everything.sort_custom(func(a: ItemInstance, b: ItemInstance) -> bool: return a.sell_value() > b.sell_value())
	var best3: Array = everything.slice(0, 3).map(func(i: ItemInstance) -> String: return i.uid)
	var total := everything.size()
	var sword_kept := everything.slice(0, 3).any(func(i: ItemInstance) -> bool: return i.base.id == &"item_rusty_sword")
	var death_spot := player.global_position
	player.take_damage(9999.0, true)
	await _frames(5)
	var kept: Array = []
	for s in inv.equipped:
		kept.append(inv.equipped[s].uid)
	for uid in inv.backpack.items:
		kept.append(uid)
	kept.sort()
	best3.sort()
	_check("you keep exactly your 3 most valuable items", kept == best3)
	_check("coins and souls all dropped", inv.coins == 0 and inv.souls == 0)
	_check("one pile, where you died", Loot.pile_count() == 1 and (Loot.piles()[0] as Node3D).global_position.distance_to(death_spot) < 0.5)
	_check("kept equipped items stay equipped (sword kept: %s)" % str(sword_kept), not sword_kept or inv.equipped.has("main1"))

	# --- Recover it ------------------------------------------------------------------
	await _seconds(3.3)  # respawn at the shrine
	await _go_to(death_spot + Vector3(0.8, 0, 0))
	(Loot.piles()[0] as Node).call(&"interact", player)
	await _frames(5)
	var count := inv.equipped.size() + inv.backpack.items.size()
	_check("recovering gives everything back (%d / %d items, %d coins)" % [count, total, inv.coins], count == total and inv.coins == 100 and inv.souls == 50)
	_check("the pile is gone after recovery", Loot.pile_count() == 0)

	# --- Die twice: the first pile is lost --------------------------------------------
	await _go_to(Vector3(-5, 0.05, 5))
	player.take_damage(9999.0, true)
	await _seconds(3.3)
	await _go_to(Vector3(-5, 0.05, -5))
	inv.coins = 30  # something new to lose
	var coins_second := inv.coins
	player.take_damage(9999.0, true)
	await _frames(5)
	var pile: Node3D = Loot.piles()[0] if Loot.pile_count() > 0 else null
	_check("dying again destroys the first pile (piles: %d)" % Loot.pile_count(),
			Loot.pile_count() == 1 and pile.global_position.z < 0.0)
	_check("second pile holds only what you had then (%d coins)" % coins_second, int(pile.get(&"coins")) == coins_second)
	await _seconds(3.3)
	(Loot.piles()[0] as Node).call(&"interact", player)  # tidy up
	await _frames(3)

	# --- Falling to your death: pile at the last safe ground ----------------------------
	await _go_to(Vector3(8, 0.05, -8))
	await _frames(10)
	var safe := player.global_position
	player.global_position = Vector3(8, 25, -8)
	player.reset_physics_interpolation()
	await _seconds(2.5)
	var fall_pile: Node3D = Loot.piles()[0] if Loot.pile_count() > 0 else null
	_check("fall death: pile at the last safe ground", fall_pile != null and fall_pile.global_position.distance_to(safe) < 1.0)
	await _seconds(1.5)
	if fall_pile:
		fall_pile.call(&"interact", player)
	await _frames(3)

	# --- Boss room: pile at the door -------------------------------------------------------
	var room := BossRoom.new()
	room.size = Vector3(20, 10, 20)
	var door := Marker3D.new()
	door.name = "Door"
	door.position = Vector3(0, 0, 14)
	room.add_child(door)
	scene.add_child(room)
	room.global_position = Vector3(-20, 0, -20)
	while player.is_dead():
		await get_tree().physics_frame
	await _go_to(Vector3(-20, 0.05, -20))
	player.take_damage(9999.0, true)
	await _frames(5)
	var boss_pile: Node3D = Loot.piles()[0] if Loot.pile_count() > 0 else null
	_check("death in a boss room: pile at the boss door", boss_pile != null and boss_pile.global_position.distance_to(door.global_position) < 0.5)
	await _seconds(3.3)
	room.queue_free()
	if boss_pile:
		boss_pile.call(&"interact", player)
	await _frames(3)

	# --- The pile doesn't last forever --------------------------------------------------------
	Loot.pile_minutes = 0.01  # 0.6 s
	await _go_to(Vector3(3, 0.05, -3))
	player.take_damage(9999.0, true)
	await _frames(5)
	var had := Loot.pile_count()
	await _seconds(1.5)
	_check("piles crumble when their time runs out (%d -> %d)" % [had, Loot.pile_count()], had == 1 and Loot.pile_count() == 0)
	Loot.pile_minutes = 60.0

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _go_to(where: Vector3) -> void:
	player.global_position = where
	player.reset_physics_interpolation()
	await _frames(3)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await _frames(ceili(s * Engine.physics_ticks_per_second))


func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", label])
	if not ok:
		failures += 1
