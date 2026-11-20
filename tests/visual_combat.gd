extends Node
## Takes screenshots of combat moments (not an automated pass/fail check).
## Run through tests/run.gd WITHOUT --headless; pictures go to user://shots/.

var player: Player
var enemy: Enemy


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(30)
	player = get_tree().get_first_node_in_group(&"player") as Player
	enemy = scene.get_node("Enemies/Marauder") as Enemy
	(scene.get_node("Enemies/Marauder2") as Node3D).global_position = Vector3(60, 0, 60)

	# Duel position, camera from the side-behind.
	player.global_position = Vector3(0, 0.05, 0)
	player.model.face_instantly(Vector3.FORWARD)
	player.camera_rig.yaw = deg_to_rad(-35.0)
	enemy.global_position = Vector3(0, 0, -2.6)
	enemy.model.face_instantly(Vector3.BACK)
	enemy.target = player
	enemy._set_state(Enemy.State.CHASE)
	enemy._cooldown = 999.0
	await _frames(30)
	await _shot("c01_standoff")

	_send("block", true)
	await _frames(20)
	await _shot("c02_block")
	_send("block", false)
	await _frames(15)

	_send("light_attack", true)
	await _frames(1)
	_send("light_attack", false)
	await _frames(12)
	await _shot("c03_swing_hit")
	await _frames(30)

	# Enemy telegraphs
	_force(0)
	await _frames(12)
	await _shot("c04_glint_parryable")
	await _frames(90)
	enemy._cooldown = 999.0
	_force(2)
	await _frames(20)
	await _shot("c05_red_unblockable")
	await _frames(40)
	await _shot("c06_after_crush")
	await _frames(60)
	get_tree().quit()


func _force(i: int) -> void:
	enemy.model.face_instantly(player.global_position - enemy.global_position)
	enemy._telegraphed = false
	enemy._set_state(Enemy.State.ATTACK)
	enemy._attack.start(enemy.data.attacks[i], enemy.model)


func _send(action: StringName, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % shot_name)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
