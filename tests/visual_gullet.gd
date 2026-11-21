extends Node
## Screenshots of the Gullet (not a pass/fail check). Windowed.
## Saves user://shots/gullet_*.png

var player: Player


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(60)
	player = get_tree().get_first_node_in_group(&"player") as Player
	var g: Node3D = scene.get_node("Gullet")
	for spot in [["hall", Vector3(0, 0.3, 43), 0.0], ["gallery", Vector3(0, 0.3, 14), 0.0], ["shrine", Vector3(-30, 0.3, -22), 0.0],
			["gate", Vector3(-30, 0.3, -42), 0.0], ["chapel", Vector3(-30, 0.3, -52), 0.0]]:
		player.global_position = g.global_position + spot[1]
		player.velocity = Vector3.ZERO
		player.reset_physics_interpolation()
		player.camera_rig.yaw = deg_to_rad(spot[2])
		await _frames(50)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots/gullet_%s.png" % spot[0])
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
