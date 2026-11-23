extends Node
## Screenshots of the combat rhythm pass (not a pass/fail check): the balance bar
## under an enemy's health bar, an enemy guarding, a deflect, and the gold
## "off balance" diamond. Run through tests/run.gd WITHOUT --headless:
##   Godot_console.exe --path . --resolution 1280x720 --script res://tests/run.gd -- visual_tempo
## Pictures go to user://shots/ (%APPDATA%\Godot\app_userdata\Kingdom\shots).

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
	enemy.data.combo_chance = 0.0
	enemy.data.counter_chance = 0.0

	player.global_position = Vector3(0, 0.05, 0)
	player.model.face_instantly(Vector3.FORWARD)
	player.camera_rig.yaw = deg_to_rad(-30.0)
	enemy.global_position = Vector3(0, 0, -2.0)
	enemy.model.face_instantly(Vector3.BACK)
	enemy.target = player
	enemy._set_state(Enemy.State.CHASE)
	enemy._cooldown = 999.0
	await _frames(30)

	# Two hits: the balance bar appears and the Marauder raises its guard.
	for i in 2:
		_tap("light_attack")
		await _frames(26)
	await _frames(6)
	await _shot("t01_balance_after_two_hits")
	_tap("light_attack")
	await _frames(14)
	await _shot("t02_guarded")
	await _frames(60)

	# Deflect the sweep.
	enemy._set_state(Enemy.State.CHASE)
	enemy._cooldown = 999.0
	await _frames(20)
	enemy._telegraphed = false
	enemy._set_state(Enemy.State.ATTACK)
	enemy._attack.start(enemy.data.attacks[0], enemy.model)
	var a := enemy._attack.attack
	while enemy.state == Enemy.State.ATTACK and enemy._attack.t < a.hit_start - 0.08 * a.anim_speed:
		await get_tree().physics_frame
	_send("block", true)
	await _frames(8)
	await _shot("t03_deflect")
	_send("block", false)
	await _frames(30)

	# Off balance: the gold diamond.
	enemy._poise = 1.0
	enemy._poise_timer = 99.0
	_tap("light_attack")
	await _frames(20)
	await _shot("t04_off_balance")
	await _frames(10)
	get_tree().quit()


func _tap(action: StringName) -> void:
	_send(action, true)
	await get_tree().physics_frame
	_send(action, false)


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
