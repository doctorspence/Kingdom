extends Node
## Armor in motion: a contact sheet per armor set (rows = animations, columns = moments), to spot clipping.
## Run windowed: Godot_console.exe --path . --resolution 1280x720 --script res://tests/run.gd -- visual_armor_motion tag [set]
## Pictures: user://shots/armormotion_<tag>_<set>.png

const SETS := {
	"chain": ["item_chainmail_body", "item_chainmail_legs"],
	"plate": ["item_platebody", "item_plate_legs"],
	"leather": ["item_leather_body", "item_leather_breeches", "item_leather_gloves", "item_leather_boots"],
	"wizard": ["item_wizard_hat", "item_wizard_robe_top", "item_wizard_robe_bottom", "item_wizard_cloak"],
}
const SLOT := {1: "head", 3: "chest", 5: "legs", 4: "hands", 6: "feet", 7: "cloak"}
const ANIMS := ["Jog_Fwd", "Sprint", "Sword_Attack"]
const CELL := Vector2i(300, 330)


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var args := OS.get_cmdline_user_args()
	var tag: String = args[1] if args.size() > 1 else "a"
	var only: String = args[2] if args.size() > 2 else ""
	var world := Node3D.new()
	get_tree().root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = load("res://levels/common/overcast_env.tres")
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.light_energy = 1.3
	world.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 200, 0)
	fill.light_energy = 0.7
	world.add_child(fill)
	var cam := Camera3D.new()
	cam.fov = 28
	world.add_child(cam)
	cam.current = true
	for set_name in SETS:
		if only != "" and set_name != only:
			continue
		var cm := CharacterModel.new()
		cm.add_child((load("res://assets/characters/mannequin/UAL1_Standard.glb") as PackedScene).instantiate())
		world.add_child(cm)
		cm.set_body(false)
		cm.set_outfit(true, false)
		for id in SETS[set_name]:
			var item: ItemData = load("res://data/items/armor/%s.tres" % id)
			cm.set_armor(SLOT[item.slot], item.model_scene)
		var sheet := Image.create(CELL.x * 3, CELL.y * ANIMS.size(), false, Image.FORMAT_RGB8)
		for row in ANIMS.size():
			cm.play(StringName(ANIMS[row]), 0.0)
			await _frames(3)
			var length := cm.anim_length(StringName(ANIMS[row]))
			cm.hold(true)
			for col in 3:
				cm.seek(length * (0.15 + 0.3 * col))
				await _frames(3)
				var yaw := deg_to_rad(40.0 if col != 1 else -140.0)
				cam.look_at_from_position(Vector3(sin(yaw) * 5.2, 1.3, cos(yaw) * 5.2), Vector3(0, 0.95, 0))
				await _frames(2)
				await RenderingServer.frame_post_draw
				var img := get_viewport().get_texture().get_image()
				img.convert(Image.FORMAT_RGB8)
				var c := Vector2i(img.get_width() / 2, img.get_height() / 2)
				sheet.blit_rect(img, Rect2i(c - CELL / 2, CELL), Vector2i(col * CELL.x, row * CELL.y))
			cm.hold(false)
		sheet.save_png("user://shots/armormotion_%s_%s.png" % [tag, set_name])
		cm.queue_free()
		await _frames(2)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
