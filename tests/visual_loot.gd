extends Node
## Screenshots of loot (not a pass/fail check). Windowed. Saves user://shots/loot_*.png

var player: Player


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(30)
	player = get_tree().get_first_node_in_group(&"player") as Player
	var inv := player.inventory
	# Fill the backpack with a spread of rolled items and some money.
	var bases := ["item_woodcutters_axe", "item_kite_shield", "item_gambeson", "item_iron_ring", "item_bone_amulet",
			"item_leather_boots", "item_hunting_bow", "item_antidote", "item_mail_mantle"]
	var i := 0
	for id in bases:
		inv.add_item(ItemDB.make_item(ItemDB.get_item(StringName(id)), 4, i % 5))
		i += 1
	inv.add_money(240, 410)
	# Some drops on the ground in front of the player.
	for r in 5:
		var it := ItemDB.make_item(ItemDB.get_item(&"item_flanged_mace"), 3, r)
		Loot._spawn_drop(900 + r, it.to_dict(), player.global_position + Vector3(-2.0 + r, 0, -3.5), false)
	await _frames(30)
	await _shot("loot_ground")
	var hud: Hud
	for n in get_tree().root.find_children("*", "Hud", true, false):
		hud = n
	hud._show_book_page("inventory")
	hud._book._cursor = Vector2i(0, 0)
	await _frames(10)
	await _shot("loot_inventory")
	hud._close_panels()
	hud._on_menu_requested(&"shop", scene.get_node("Merchants/SoulBroker"))
	await _frames(10)
	await _shot("loot_soul_broker")
	get_tree().quit()


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % shot_name)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
