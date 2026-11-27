extends Node
## Pictures of the 2026-11-27 combat pass (not a pass/fail check): the stamina bar
## normal, exhausted (blinking green glow, two moments of the pulse) and recovered,
## the class bar (Mana for the Mystic), and side-view frame strips of the sprinting
## light and heavy attacks. Run through tests/run.gd WITHOUT --headless:
##   Godot_console.exe --path . --resolution 1280x720 --script res://tests/run.gd -- visual_stamina [mystic]
## Pictures go to user://shots/ (%APPDATA%\Godot\app_userdata\Kingdom\shots).

const STEPS := 10
const EVERY := 3
const CELL := Vector2i(150, 210)

var player: Player


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var mystic := "mystic" in OS.get_cmdline_user_args()
	if mystic:
		get_tree().root.get_node("Net").set(&"character", {"class": &"class_lamplighter"})
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _physics(40)
	player = get_tree().get_first_node_in_group(&"player") as Player
	for e in get_tree().get_nodes_in_group(&"enemies"):
		(e as Node3D).global_position = Vector3(60, 0, 60)
	var tag := "mystic" if mystic else "vanguard"
	await _shot("st_%s_1_normal" % tag)
	player._spend_stamina(player.max_stamina())
	await _physics(6)
	await _shot("st_%s_2_exhausted_a" % tag)
	await _physics(7)
	await _shot("st_%s_3_exhausted_b" % tag)
	player.restore_stamina(player.max_stamina() * 0.5)
	await _physics(60)  # let the chip catch up
	await _shot("st_%s_4_recovered" % tag)
	if mystic:
		get_tree().quit()
		return

	# Sprinting attacks from the side: sprint in, then light (row 1) or heavy (row 2).
	var cam := Camera3D.new()
	scene.add_child(cam)
	cam.fov = 55.0
	var sheet := Image.create(CELL.x * STEPS, CELL.y * 2, false, Image.FORMAT_RGB8)
	for row in 2:
		player.global_position = Vector3(0, 0.05, 16)
		player.model.face_instantly(Vector3.FORWARD)
		player.camera_rig.yaw = 0.0
		player.reset_physics_interpolation()
		player.stamina = player.max_stamina()
		await _physics(20)
		Input.action_press("move_forward")
		Input.action_press("dodge_sprint")
		await _physics(75)
		_tap("heavy_attack" if row == 1 else "light_attack")
		await _physics(1)
		var at := player.global_position
		cam.global_position = at + Vector3(6.5, 1.5, -1.6)
		cam.look_at(at + Vector3(0, 1.1, -1.6))
		cam.make_current()
		for col in STEPS:
			await _physics(EVERY)
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			var w := img.get_width()
			var h := img.get_height()
			var crop := img.get_region(Rect2i(w / 2 - w * 5 / 16, h / 10, w * 5 / 8, h * 8 / 10))
			crop.resize(CELL.x, CELL.y)
			sheet.blit_rect(crop, Rect2i(Vector2i.ZERO, CELL), Vector2i(col * CELL.x, row * CELL.y))
		Input.action_release("dodge_sprint")
		Input.action_release("move_forward")
		await _physics(60)
	sheet.save_png("user://shots/sprint_attacks.png")
	get_tree().quit()


func _shot(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % file_name)


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


func _physics(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
