extends Node
## Screenshots of the inventory book (not a pass/fail check). Needs a window:
##   Godot_console.exe --path . --resolution 1920x1080 --script res://tests/run.gd -- visual_inventory
## Saves user://shots/inv_*.png (%APPDATA%\Godot\app_userdata\Kingdom\shots).

var player: Player
var hud: Hud


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(30)
	player = get_tree().get_first_node_in_group(&"player") as Player
	player.stats.set_level(7)
	player.stats.add_xp(400)
	var inv := player.inventory
	var gear := [["item_kettle_helm", 2], ["item_bone_amulet", 3], ["item_iron_ring", 1], ["item_tattered_cloak", 0],
			["item_leather_boots", 1], ["item_leather_gloves", 0], ["item_leather_pauldrons", 1], ["item_chainmail_legs", 2]]
	for g in gear:
		var it := ItemDB.make_item(ItemDB.get_item(StringName(g[0])), 5, g[1])
		inv.add_item(it)
		inv.equip(it.uid)
	var bag := [["item_executioners_greatsword", 3], ["item_woodcutters_axe", 2], ["item_lantern_staff", 1],
			["item_kite_shield", 0], ["item_hunting_bow", 2], ["item_bronze_dagger", 1], ["item_platebody", 1],
			["item_leather_boots", 0], ["item_mail_gauntlets", 2], ["item_copper_ring", 0], ["item_blackstone_amulet", 3],
			["item_plate_helm", 4], ["item_rusty_sword", 0]]
	for b in bag:
		inv.add_item(ItemDB.make_item(ItemDB.get_item(StringName(b[0])), 6, b[1]))
	for c in [["item_health_potion", 4], ["item_antidote", 2], ["item_bread", 5], ["item_bandage", 3], ["item_warming_draught", 2]]:
		var it2 := ItemDB.make_item(ItemDB.get_item(StringName(c[0])), 1, 0)
		it2.count = c[1]
		inv.add_item(it2)
	inv.add_money(17758, 412)
	inv.sort_backpack()
	for n in get_tree().root.find_children("*", "Hud", true, false):
		hud = n
	hud._show_book_page("inventory")
	var book := hud._book
	await _frames(20)
	# the cursor on the greatsword: its card shows
	book._grid.grab_focus()
	book._nav_keys = true  # as if you had used the keyboard: the selection shows its card
	book._cursor = _find(inv, &"item_executioners_greatsword")
	book._redraw()
	await _frames(20)
	await _shot("inv_main")
	book._compare = true
	book._cursor = _find(inv, &"item_plate_helm")
	book._redraw()
	await _frames(5)
	await _shot("inv_compare")
	book._compare = false
	# carrying the bow with a gamepad, turned on its side
	book._cursor = _find(inv, &"item_hunting_bow")
	book._start_carry(inv.backpack.item_at(book._cursor), "grid", true)
	book._rotate_carry()
	book._cursor = Vector2i(5, 5)
	book._clamp_carry()
	book._pad = true
	book._redraw()
	await _frames(5)
	await _shot("inv_carry_pad")
	book._cancel_carry()
	book._pad = false
	# dragging the shield with the mouse over the off-hand slot
	book._cursor = _find(inv, &"item_kite_shield")
	book._press_pos = book.GRID_POS + Vector2(book._cursor) * book._cell + Vector2(30, 30)
	book._start_carry(inv.backpack.item_at(book._cursor), "grid", false)
	book._mouse = (book._slots["off"] as Control).get_rect().get_center()
	book._redraw()
	await _frames(5)
	await _shot("inv_drag_mouse")
	book._cancel_carry()
	book._filter = 1
	book._redraw()
	await _frames(3)
	await _shot("inv_filter_weapons")
	book._filter = 0
	book._nav_keys = false  # back on the mouse
	hud._show_book_page("character")
	await _frames(5)
	await _shot("inv_character")
	hud._show_book_page("talents")
	await _frames(5)
	await _shot("inv_talents")
	hud._show_book_page("system")
	await _frames(5)
	await _shot("inv_system")
	hud._show_book_page("inventory")
	book._grid.grab_focus()
	book._nav_keys = true  # as if you had used the keyboard: the selection shows its card
	await _frames(5)
	# resolution independence: a narrow and an ultra-wide window
	for res in [Vector2i(1280, 720), Vector2i(2560, 1080)]:
		get_window().size = res
		await _frames(10)
		await _shot("inv_%dx%d" % [res.x, res.y])
	# Tab opens the inventory and closes it again
	get_window().size = Vector2i(1920, 1080)
	hud._close_panels()
	await _frames(5)
	await _tap(KEY_TAB)
	print("tab opens the inventory: ", hud._book.visible and hud._book.page == "inventory")
	await _tap(KEY_TAB)
	print("tab closes it: ", not hud._book.visible)
	get_tree().quit()


func _find(inv: Inventory, id: StringName) -> Vector2i:
	for uid in inv.backpack.items:
		if inv.backpack.items[uid].base.id == id:
			return inv.backpack.positions[uid]
	return Vector2i.ZERO


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % shot_name)
	print("shot ", shot_name)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _tap(key: Key) -> void:
	for down in [true, false]:
		var e := InputEventKey.new()
		e.physical_keycode = key
		e.keycode = key
		e.pressed = down
		Input.parse_input_event(e)
		await _frames(3)
