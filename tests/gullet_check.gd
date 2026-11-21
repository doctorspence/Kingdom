extends Node
## Automated check of the new Gullet (GULLET_DESIGN.md): items, drop tables,
## food, enemies, barrels, layout, boss. Grows as the dungeon is built.
##   ... --headless --script res://tests/run.gd -- gullet_check

var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	await _items_and_loot()
	await _eating()
	print("PASS: 0 problem(s)" if failures == 0 else "FAIL: %d problem(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)


# --- Step 3: items, food, drop tables --------------------------------------------------------
func _items_and_loot() -> void:
	for id in [&"item_bread", &"item_cooked_meat", &"item_health_potion", &"item_bronze_sword", &"item_iron_sword",
			&"item_steel_sword", &"item_iron_dagger", &"item_steel_pickaxe", &"item_harls_pick", &"item_leather_body",
			&"item_iron_shield", &"item_blackstone_amulet"]:
		_check("item exists: %s" % id, ItemDB.get_item(id) != null)
	var bread := ItemDB.get_item(&"item_bread")
	_check("bread heals 10%, meat 20%, potion 25%", is_equal_approx(bread.use_amount, 0.10)
			and is_equal_approx(ItemDB.get_item(&"item_cooked_meat").use_amount, 0.20)
			and is_equal_approx(ItemDB.get_item(&"item_health_potion").use_amount, 0.25))
	var dagger := ItemDB.get_item(&"item_iron_dagger").weapon
	var sword := ItemDB.get_item(&"item_iron_sword").weapon
	_check("the dagger is faster and shorter than the sword", dagger.light_combo[0].anim_speed > sword.light_combo[0].anim_speed
			and dagger.light_combo[0].reach < sword.light_combo[0].reach)
	_check("steel beats iron beats bronze", ItemDB.get_item(&"item_steel_sword").weapon.damage > sword.damage
			and sword.damage > ItemDB.get_item(&"item_bronze_sword").weapon.damage)

	# Drop tables: rolled many times, the rates should land near the design (GULLET_DESIGN.md section 5).
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var bandit := load("res://data/loot/loot_bandit.tres") as LootTable
	var n := 4000
	var bread_n := 0
	var coins_ok := true
	var dagger_n := 0
	for i in n:
		var r := ItemDB.roll(bandit, rng)
		coins_ok = coins_ok and r.coins >= 5 and r.coins <= 25
		for it in r.items:
			if it.base.id == &"item_bread":
				bread_n += 1
			if it.base.id == &"item_iron_dagger":
				dagger_n += 1
	_check("bandit: coins 5-25 every time, bread about 20%% (%.1f%%), dagger about 5%% (%.1f%%)" % [100.0 * bread_n / n, 100.0 * dagger_n / n],
			coins_ok and absf(bread_n / float(n) - 0.20) < 0.03 and absf(dagger_n / float(n) - 0.05) < 0.02)
	var harl := load("res://data/loot/loot_harl.tres") as LootTable
	var potions_ok := true
	var unique := 0
	var uniq_rarity_ok := true
	var m := 20000
	for i in m:
		var r := ItemDB.roll(harl, rng)
		var got_potion := false
		for it in r.items:
			if it.base.id == &"item_health_potion":
				got_potion = it.count == 2
			if it.base.id == &"item_harls_pick":
				unique += 1
				uniq_rarity_ok = uniq_rarity_ok and it.rarity == ItemInstance.Rarity.EPIC
		potions_ok = potions_ok and got_potion
	_check("Harl: always 2 potions, unique weapon about 1/128 (%d in %d) and always Epic" % [unique, m],
			potions_ok and unique > 80 and unique < 240 and uniq_rarity_ok)
	var chest := ItemDB.roll(load("res://data/loot/loot_gullet_chest.tres"), rng)
	_check("the chest rolls", chest.coins >= 50 and chest.coins <= 150)


func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", label])
	if not ok:
		failures += 1


# --- Eating takes about 1.5 s and heals a share of max health ---------------------------------
func _eating() -> void:
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(30)
	var player := get_tree().get_first_node_in_group(&"player") as Player
	for e in get_tree().get_nodes_in_group(&"enemies"):
		(e as Node3D).global_position = Vector3(80, 0, 80)
	var maxh := player.max_health()
	player.health = maxh * 0.3
	var meat := ItemDB.make_item(ItemDB.get_item(&"item_cooked_meat"), 1, 0)
	player.inventory.add_item(meat)
	var before := player.health
	_check("using food starts eating", player.use_item(meat.uid) == "" and player.state == Player.State.DRINK)
	await _seconds(0.5)
	_check("nothing healed yet after half a second", is_equal_approx(player.health, before))
	await _seconds(1.3)
	_check("cooked meat healed 20%% of max health (%.0f -> %.0f of %.0f)" % [before, player.health, maxh],
			absf(player.health - before - maxh * 0.2) < 1.0 and player.state == Player.State.MOVE)
	_check("the meat is used up", not player.inventory.backpack.items.has(meat.uid))
	scene.queue_free()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await _frames(ceili(s * Engine.physics_ticks_per_second))
