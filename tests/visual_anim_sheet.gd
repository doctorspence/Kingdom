extends Node
## Contact sheet of attack animations (not a pass/fail check): the player frozen at
## evenly spaced moments of each animation, seen from the side. Used to pick which
## animation reads as a downward swing. Run through tests/run.gd WITHOUT --headless:
##   Godot_console.exe --path . --resolution 640x480 --script res://tests/run.gd -- visual_anim_sheet [anim,anim,...]
## The sheet goes to user://shots/anim_sheet.png (%APPDATA%\Godot\app_userdata\Kingdom\shots).

const DEFAULT := [&"Sword_Attack", &"ual2/Sword_Regular_C", &"TreeChopping", &"ual2/Sword_Heavy_Combo", &"ual2/Sword_Dash"]
const STEPS := 8
## Optional time window (seconds) per animation: "name@from-to".

const CELL := Vector2i(180, 240)

var player: Player


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var anims: Array = DEFAULT
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "visual_anim_sheet" and i + 1 < args.size():
			anims = Array(args[i + 1].split(","))
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(30)
	player = get_tree().get_first_node_in_group(&"player") as Player
	for e in get_tree().get_nodes_in_group(&"enemies"):
		(e as Node3D).global_position = Vector3(60, 0, 60)
	player.global_position = Vector3(0, 0.05, 0)
	player.model.face_instantly(Vector3.FORWARD)
	var cam := Camera3D.new()
	scene.add_child(cam)
	cam.fov = 50.0
	cam.global_position = Vector3(5.5, 1.3, -0.6)
	cam.look_at(Vector3(0, 1.1, -0.6))
	cam.make_current()  # look at the player from the side, at chest height
	await _frames(20)
	player.set_physics_process(false)
	var sheet := Image.create(CELL.x * STEPS, CELL.y * anims.size(), false, Image.FORMAT_RGB8)
	for row in anims.size():
		var spec := String(anims[row]).split("@")
		var anim := StringName(spec[0])
		var t0 := 0.0
		var length := player.model.anim_length(anim)
		if spec.size() > 1:
			t0 = spec[1].split("-")[0].to_float()
			length = spec[1].split("-")[1].to_float() - t0
		print("%s: %.2f s" % [anim, length])
		for col in STEPS:
			var t := t0 + length * (col + 0.5) / STEPS
			player.model.hold(false)
			player.model.play(anim, 0.0, 1.0, true)
			player.model.seek(t)
			player.model.hold(true)
			await _frames(3)
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			var w := img.get_width()
			var h := img.get_height()
			var crop := img.get_region(Rect2i(w / 2 - w * 3 / 16, h / 10, w * 3 / 8, h * 8 / 10))
			crop.resize(CELL.x, CELL.y)
			sheet.blit_rect(crop, Rect2i(Vector2i.ZERO, CELL), Vector2i(col * CELL.x, row * CELL.y))
	sheet.save_png("user://shots/anim_sheet.png")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
