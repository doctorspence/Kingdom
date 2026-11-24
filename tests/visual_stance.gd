extends Node
## Screenshots of combat-stance footwork (not a pass/fail check): locked on to a
## dummy, stepping sideways, backing off and diagonals, seen from the front so you
## can see the legs turn toward the step while the chest stays on the foe.
## Run through tests/run.gd WITHOUT --headless:
##   Godot_console.exe --path . --resolution 1280x720 --script res://tests/run.gd -- visual_stance
## Pictures go to user://shots/ (%APPDATA%\Godot\app_userdata\Kingdom\shots).

var player: Player
var cam: Camera3D


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var scene: Node = load("res://levels/sandbox/movement_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(30)
	player = get_tree().get_first_node_in_group(&"player") as Player
	cam = Camera3D.new()
	cam.fov = 50.0
	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	scene.add_child(cam)
	player.targeting.toggle()
	await _frames(40)

	for step in [["s01_sidestep_right", ["move_right"]], ["s02_sidestep_left", ["move_left"]],
			["s03_backpedal", ["move_back"]], ["s04_back_left", ["move_back", "move_left"]],
			["s05_forward_right", ["move_forward", "move_right"]]]:
		for a in step[1]:
			Input.action_press(a)
		await _seconds(0.8)
		await _shot(step[0])
		for a in step[1]:
			Input.action_release(a)
		await _seconds(0.6)

	# The same sidestep with the leg turn switched off, to compare.
	player.model._twist.yaw = 0.0
	var twist := player.model._twist
	player.model._twist = null
	Input.action_press("move_right")
	await _seconds(0.8)
	twist.yaw = 0.0
	await _shot("s06_sidestep_right_without_leg_turn")
	Input.action_release("move_right")
	await _frames(10)
	get_tree().quit()


## Look at the player from in front and a little to the side, so the legs show.
func _place_camera() -> void:
	var fwd := player.model.forward()
	var right := fwd.cross(Vector3.UP).normalized()
	var chest := player.global_position + Vector3.UP * 1.0
	cam.global_position = chest + fwd * 3.6 + right * 1.6 + Vector3.UP * 0.5
	cam.look_at(chest, Vector3.UP)
	cam.make_current()


func _shot(shot_name: String) -> void:
	_place_camera()
	await get_tree().process_frame
	print("%s player=%s fwd=%s cam=%s current=%s locked=%s twist=%.0f" % [shot_name, player.global_position,
			player.model.forward(), cam.global_position, get_viewport().get_camera_3d() == cam,
			player.targeting.has_target(), rad_to_deg(player.model._twist.yaw) if player.model._twist else 0.0])
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % shot_name)


func _seconds(s: float) -> void:
	var t := 0.0
	while t < s:
		await get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
