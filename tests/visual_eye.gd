extends Node
## Screenshots of the stealth eye (not a pass/fail check): closed, half open (an enemy
## is suspicious) and red (an enemy fights you), in the real HUD while crouched.
## Run through tests/run.gd WITHOUT --headless:
##   Godot_console.exe --path . --resolution 1280x720 --script res://tests/run.gd -- visual_eye
## Pictures go to user://shots/ (eye_*.png, a zoomed corner of the HUD).

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
		(e as Node3D).global_position = Vector3(80, 0, 80)
	player.global_position = Vector3(0, 0.05, 0)
	player.is_crouching = true
	await _seconds(1.0)
	await _shot("eye_0_closed")
	var b := (load("res://game/enemies/bandit_sword.tscn") as PackedScene).instantiate() as Enemy
	b.position = Vector3(0, 0, -6)
	b.rotation_degrees.y = 0.0
	scene.add_child(b, true)
	b.model.face_instantly(Vector3(0, 0, 1))
	player.is_crouching = true
	for i in 400:
		await get_tree().physics_frame
		if b.state == Enemy.State.SUSPICIOUS:
			break
	await _seconds(0.5)
	print("enemy state: ", Enemy.State.keys()[b.state], " awareness ", b.awareness_of(player))
	await _shot("eye_1_suspicious")
	var h := HitInfo.new()
	h.damage = 1.0
	h.attacker = player
	h.origin = player.global_position
	b.receive_hit(h)
	player.is_crouching = true
	await _seconds(0.6)
	print("enemy state: ", Enemy.State.keys()[b.state])
	await _shot("eye_2_fighting")
	get_tree().quit()


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://shots/%s_full.png" % shot_name)
	var crop := img.get_region(Rect2i(0, 0, 420, 140))
	crop.resize(1260, 420, Image.INTERPOLATE_NEAREST)
	crop.save_png("user://shots/%s.png" % shot_name)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s, true, true).timeout
