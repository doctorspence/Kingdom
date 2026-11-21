extends Node
## Screenshots of the new Gullet (not a pass/fail check). Windowed.
## Saves user://shots/gullet_*.png   (run with a resolution, not headless)

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
	# Overview from inside the rock: roofs are back-faces, so you see the floor plan.
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 105.0
	cam.far = 200.0
	get_tree().root.add_child(cam)
	cam.global_position = g.global_position + Vector3(0, 14.5, 0)
	cam.rotation_degrees = Vector3(-90, 0, 0)
	cam.current = true
	var sun := DirectionalLight3D.new()
	sun.light_energy = 2.5
	sun.rotation_degrees = Vector3(-90, 0, 0)
	sun.shadow_enabled = false
	sun.light_cull_mask = 0xFFFFF
	get_tree().root.add_child(sun)
	await _frames(20)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/gullet_overview.png")
	cam.queue_free()
	sun.queue_free()
	for spot in [["yard", Vector3(-55, 0.3, 25), -90.0], ["tunnel", Vector3(-36, 0.3, 25), -90.0], ["camp", Vector3(-10, 0.3, -4), -90.0], ["camp_up", Vector3(0, 4.4, -16), 90.0],
			["dig", Vector3(34, 0.3, 0), -90.0], ["falls", Vector3(47, 0.3, -6), 180.0], ["falls2", Vector3(47, 0.3, -6), 0.0], ["chamber", Vector3(49, 0.3, 26), 0.0]]:
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
