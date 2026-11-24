extends Node
## Armor on the base Outcast: front / side / back pictures of each armor set worn over the model.
## Run windowed: Godot_console.exe --path . --resolution 1280x720 --script res://tests/run.gd -- visual_armor_fit [tag]
## Pictures go to user://shots/armorfit_<tag>_<set>_<view>.png

const SETS := {
	"none": [],
	"b_chain": ["item_chainmail_body"],
	"b_plate": ["item_platebody"],
	"b_leather": ["item_leather_body"],
	"chain": ["item_chainmail_body", "item_chainmail_legs"],
	"plate": ["item_platebody", "item_plate_legs"],
	"leather": ["item_leather_body", "item_leather_breeches", "item_leather_gloves", "item_leather_boots"],
	"wizard": ["item_wizard_hat", "item_wizard_robe_top", "item_wizard_robe_bottom", "item_wizard_cloak"],
}
const SLOT := {1: "head", 3: "chest", 5: "legs", 4: "hands", 6: "feet", 7: "cloak"}


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
	cam.fov = 32
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
			var scene: PackedScene = load(Catalog_path(id))
			cm.set_armor(SLOT[item.slot], scene)
		cm.play(&"Idle", 0.0)
		await _frames(20)
		cm.set_speed(0.0)
		var shots := {
			"front": [Vector3(0, 1.1, 4.4), Vector3(0, 0.95, 0)],
			"side": [Vector3(4.4, 1.1, 0), Vector3(0, 0.95, 0)],
			"back": [Vector3(0, 1.1, -4.4), Vector3(0, 0.95, 0)],
			"upper": [Vector3(1.9, 1.5, 1.9), Vector3(0, 1.25, 0)],
			"upper_front": [Vector3(0, 1.4, 2.6), Vector3(0, 1.2, 0)],
		}
		for k in shots:
			cam.look_at_from_position(shots[k][0], shots[k][1])
			await _frames(3)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://shots/armorfit_%s_%s_%s.png" % [tag, set_name, k])
		cm.queue_free()
		await _frames(2)
	get_tree().quit()


func Catalog_path(id: String) -> String:
	var n := id.trim_prefix("item_")
	if n == "leather_breeches":
		n = "leather_breeches"
	for d in DirAccess.get_directories_at("res://assets/equipment/Armor"):
		var p := "res://assets/equipment/Armor/%s/%s.scn" % [d, n]
		if FileAccess.file_exists(p):
			return p
	return ""


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
