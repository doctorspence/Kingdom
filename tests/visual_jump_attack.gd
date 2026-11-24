extends Node
## Side-view frame strips of the jumping light attack, the jumping heavy attack and the
## ground heavy (not a pass/fail check). Run through tests/run.gd WITHOUT --headless:
##   Godot_console.exe --path . --resolution 960x720 --script res://tests/run.gd -- visual_jump_attack [game]
## ("game" = through the real game camera, behind the player; otherwise from the side)
## The sheet goes to user://shots/jump_attacks.png (%APPDATA%\Godot\app_userdata\Kingdom\shots).

const STEPS := 9
const EVERY := 2  # physics frames between pictures
const CELL := Vector2i(160, 220)

var player: Player


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(30)
	player = get_tree().get_first_node_in_group(&"player") as Player
	for e in get_tree().get_nodes_in_group(&"enemies"):
		(e as Node3D).global_position = Vector3(60, 0, 60)
	var cam := Camera3D.new()
	scene.add_child(cam)
	cam.fov = 55.0
	var rows := [["jump", "light_attack"], ["jump", "heavy_attack"], ["", "heavy_attack"]]
	var sheet := Image.create(CELL.x * STEPS, CELL.y * rows.size(), false, Image.FORMAT_RGB8)
	for row in rows.size():
		player.global_position = Vector3(0, 0.05, 0)
		player.model.face_instantly(Vector3.FORWARD)
		player.reset_physics_interpolation()
		player.stamina = player.max_stamina()
		cam.global_position = Vector3(5.5, 1.6, -0.8)
		cam.look_at(Vector3(0, 1.3, -0.8))
		if "game" in OS.get_cmdline_user_args():
			player.camera_rig.yaw = 0.0  # the real game camera, behind the player
			player.camera_rig.camera.make_current()
		else:
			cam.make_current()
		await _physics(30)
		if rows[row][0] != "":
			_tap(rows[row][0])
			await _physics(6)
		_tap(rows[row][1])
		for col in STEPS:
			await _physics(EVERY)
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			var w := img.get_width()
			var h := img.get_height()
			var crop := img.get_region(Rect2i(w / 2 - w * 3 / 16, h / 20, w * 3 / 8, h * 17 / 20))
			crop.resize(CELL.x, CELL.y)
			sheet.blit_rect(crop, Rect2i(Vector2i.ZERO, CELL), Vector2i(col * CELL.x, row * CELL.y))
		await _physics(60)
	sheet.save_png("user://shots/jump_attacks.png")
	get_tree().quit()


func _tap(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().physics_frame
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)


func _physics(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
