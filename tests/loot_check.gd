extends Node
## Automated loot check: items, rolls, inventory, equipment, drops, merchants,
## bank, saving, legendary effect, bows and consumables.
##   ... --headless --script res://tests/run.gd -- loot_check

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
	var inv := player.inventory

	# --- Items and rolls ---------------------------------------------------------
	_check("item database loaded (%d items)" % ItemDB.all_items().size(), ItemDB.all_items().size() >= 30)
	var ring := ItemDB.get_item(&"item_iron_ring")
	var rare := ItemDB.make_item(ring, 5, ItemInstance.Rarity.RARE)
	var epic := ItemDB.make_item(ring, 5, ItemInstance.Rarity.EPIC)
	_check("Rare rolls 1 bonus, Epic 2 (%d, %d)" % [rare.bonuses.size(), epic.bonuses.size()], rare.bonuses.size() == 1 and epic.bonuses.size() == 2)
	var table: LootTable = load("res://data/loot/loot_marauder.tres")
	var items := 0
	var coinss := 0
	for i in 200:
		var r := ItemDB.roll(table)
		items += r.items.size()
		coinss += r.coins
	_check("Marauder loot: ~half drop something (%d items / 200 kills, %d coins)" % [items, coinss], items > 60 and items < 260 and coinss > 1000)

	# --- Starting gear and equipping ----------------------------------------------
	_check("Bulwark starts with sword, shield, hauberk", player.weapon.id == &"weapon_rusty_sword" and player.shield != null
			and inv.equipped.has("chest"))
	var armor_before := player.stats.armor()
	var helm := ItemDB.make_item(ItemDB.get_item(&"item_kettle_helm"), 3, 0)
	inv.add_item(helm)
	_check("equip a helm: armor goes up", inv.equip(helm.uid) == "" and player.stats.armor() > armor_before)
	var gs := ItemDB.make_item(ItemDB.get_item(&"item_executioners_greatsword"), 1, 0)
	inv.add_item(gs)
	var why := inv.equip(gs.uid, "main1")
	await _frames(2)
	_check("two-handed greatsword: shield goes back to the backpack (%s)" % why,
			why == "" and player.weapon.two_handed and player.shield == null and not inv.equipped.has("off1"))
	var axe := ItemDB.make_item(ItemDB.get_item(&"item_woodcutters_axe"), 1, 0)
	inv.add_item(axe)
	inv.equip(axe.uid, "main2")
	inv.swap_weapon_set()
	await _frames(2)
	_check("weapon set 2: the axe (bleeds)", player.weapon.id == &"weapon_woodcutters_axe" and player.weapon.status == Effects.Status.BLEED)
	inv.swap_weapon_set()
	await _frames(2)
	_check("heavier gear = heavier load (%.0f%%)" % (player.equip_load * 100.0), player.equip_load > 0.2)

	# --- Backpack grid ---------------------------------------------------------------
	var tiny := ItemGrid.new(2, 2)
	var big := ItemDB.make_item(ItemDB.get_item(&"item_rusty_hauberk"), 1, 0)  # 2x3
	_check("grid: a 2x3 chest doesn't fit a 2x2 grid", not tiny.add(big))
	var g := ItemGrid.new(4, 2)
	var ring1 := ItemDB.make_item(ring, 1, 0)
	_check("grid: in a 4x2 grid the 2x3 chest lies on its side (3x2), and a ring still fits",
			g.add(big) and g.is_rotated(big.uid) and g.size_of(big.uid) == Vector2i(3, 2) and g.add(ring1))
	_check("grid: no overlaps, nothing outside", not g.can_place(ring1, Vector2i(0, 0), ring1.uid) and not g.can_place(ring1, Vector2i(4, 0)))
	g.remove(ring1.uid)
	_check("grid: turn it upright where it doesn't fit (blocked), back on its side where it does",
			not g.move(big.uid, Vector2i(0, 0), false) and g.move(big.uid, Vector2i(1, 0), true))
	var potion := ItemDB.make_item(ItemDB.get_item(&"item_antidote"), 1, 0)
	var potion2 := ItemDB.make_item(ItemDB.get_item(&"item_antidote"), 1, 0)
	g.add(potion)
	g.add(potion2)
	_check("consumables stack (x%d)" % potion.count, potion.count == 2 and g.items.size() == 2)
	var sorted_ok := g.sort()
	_check("sort: everything still fits, nothing overlaps", sorted_ok and g.items.size() == 2 and g.can_place(potion, g.positions[potion.uid], potion.uid))
	var saved_grid := ItemGrid.new()
	saved_grid.load_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	_check("grid save keeps turned items turned", saved_grid.is_rotated(big.uid) == g.is_rotated(big.uid))
	# One ring slot: an old save with two rings keeps one on and packs the other.
	var old := Inventory.new()
	var r_a := ItemDB.make_item(ring, 1, 0)
	var r_b := ItemDB.make_item(ring, 1, 0)
	old.load_dict({"equipped": {"ring1": r_a.to_dict(), "ring2": r_b.to_dict()}})
	_check("one ring slot: an old second ring goes to the backpack", old.equipped.has("ring1")
			and not old.equipped.has("ring2") and old.backpack.items.has(r_b.uid))
	r_a.junk = true
	_check("junk mark is saved", ItemInstance.from_dict(JSON.parse_string(JSON.stringify(r_a.to_dict()))).junk)

	# --- Drops, pickup, coins and souls ---------------------------------------------------
	var rich: LootTable = table.duplicate()
	rich.drop_chance = 1.0
	rich.item_count = Vector2i(2, 2)
	enemy.data = enemy.data.duplicate()
	enemy.data.loot_table = rich
	var coins_before := inv.coins
	var souls_before := inv.souls
	enemy.global_position = player.global_position + Vector3(0, 0, -2)
	enemy.health = 1.0
	enemy._cooldown = 99.0
	await _frames(3)
	await _tap("light_attack")
	await _seconds(1.0)
	_check("kill: 2 items drop, coins and souls gained (%d drops, +%d coins, +%d souls)" % [Loot.drop_count(), inv.coins - coins_before, inv.souls - souls_before],
			Loot.drop_count() >= 2 and inv.coins > coins_before and inv.souls > souls_before)
	var drop: Node3D = Loot.drops()[0]
	var count_before := inv.backpack.items.size()
	player.global_position = drop.global_position + Vector3(0.5, 0.05, 0)
	player.reset_physics_interpolation()
	await _frames(3)
	drop.call(&"interact", player)
	await _frames(5)
	_check("pick up a drop (backpack %d -> %d)" % [count_before, inv.backpack.items.size()], inv.backpack.items.size() == count_before + 1)

	# --- Merchants and bank -----------------------------------------------------------------
	var wenna := scene.get_node("Merchants/OldWenna") as Vendor
	var broker := scene.get_node("Merchants/SoulBroker") as Vendor
	_check("Soul Broker offers Rare+ gear for souls", broker.stock.size() == 4 and broker.stock.all(func(i: ItemInstance) -> bool: return i.rarity >= ItemInstance.Rarity.RARE))
	inv.coins = 500
	var antidote := wenna.offers()[0]
	_check("buy an antidote with coins", wenna.buy(player, antidote) == "" and inv.coins < 500)
	var coins_now := inv.coins
	var price := helm.sell_value()
	inv.unequip("head")
	inv.sell(helm.uid)
	_check("sell the helm (+%d coins)" % price, inv.coins == coins_now + price and inv.buyback.size() == 1)
	_check("buy it back", inv.buy_back(helm.uid) == "" and inv.backpack.items.has(helm.uid))
	_check("move it to the bank", inv.move_between(helm.uid) == "" and inv.bank.items.has(helm.uid))
	var rows := inv.bank.height
	inv.coins = 1000
	_check("buy a bank row", inv.buy_bank_row() == "" and inv.bank.height == rows + 1)

	# --- Saving --------------------------------------------------------------------------------
	var saved: Variant = JSON.parse_string(JSON.stringify(inv.to_dict()))
	var copy := Inventory.new()
	copy.load_dict(saved)
	_check("save and load: same gear, backpack, bank, money", copy.equipped.size() == inv.equipped.size()
			and copy.backpack.items.size() == inv.backpack.items.size() and copy.bank.items.has(helm.uid)
			and copy.coins == inv.coins and copy.souls == inv.souls)

	# --- Legendary, bow, consumables ------------------------------------------------------------
	var noose := ItemDB.make_item(ItemDB.get_item(&"item_hobbs_noose"), 8, 0)
	inv.add_item(noose)
	inv.equip(noose.uid)
	_check("Hobb's Noose is always Legendary", noose.rarity == ItemInstance.Rarity.LEGENDARY)
	player.take_damage(player.health + 50.0, true)
	_check("Hobb's Noose: a killing blow leaves you at 1 health", player.health == 1.0 and not player.is_dead())
	player.respawn()
	await _frames(3)
	var bow := ItemDB.make_item(ItemDB.get_item(&"item_hunting_bow"), 1, 0)
	inv.add_item(bow)
	inv.equip(bow.uid, "main1")
	await _frames(2)
	enemy.reset_from_rest()
	enemy.data = enemy.data.duplicate()
	enemy.global_position = player.global_position + Vector3(0, 0, -9)
	enemy.model.face_instantly(Vector3.BACK)
	enemy._cooldown = 99.0
	player.model.face_instantly(Vector3.FORWARD)
	player.camera_rig.yaw = 0.0
	var ehp := enemy.health
	await _frames(3)
	await _tap("light_attack")
	await _seconds(1.2)
	_check("bow: an arrow hits the Marauder 9 m away (%d -> %d)" % [ehp, enemy.health], enemy.health < ehp)
	player.effects.add_buildup(Effects.Status.POISON, 120.0)
	var cure := ItemDB.make_item(ItemDB.get_item(&"item_antidote"), 1, 0)
	inv.add_item(cure)
	var cure_uid := ""
	for uid in inv.backpack.items:
		if inv.backpack.items[uid].base.id == &"item_antidote":
			cure_uid = uid
	_check("antidote cures poison", player.use_item(cure_uid) == "" and player.effects.poison_left <= 0.0)

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


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
