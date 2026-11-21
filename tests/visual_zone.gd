extends Node
## Screenshots of the Tithelands (not a pass/fail check). Windowed.
## Saves user://shots/zone_*.png and prints how long the zone took to load.

var player: Player


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var t0 := Time.get_ticks_msec()
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	await get_tree().process_frame
	print("ZONE load+build ms: ", Time.get_ticks_msec() - t0)
	await _frames(60)
	player = get_tree().get_first_node_in_group(&"player") as Player
	await _shot("zone_start")
	# Overview from straight above.
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 540.0
	cam.far = 1000.0
	scene.add_child(cam)
	cam.global_position = Vector3(0, 400, 0)
	cam.rotation_degrees = Vector3(-90, 0, 0)
	cam.current = true
	var env: WorldEnvironment = scene.get_node("WorldEnvironment")
	var fog_was := env.environment.fog_enabled
	env.environment.fog_enabled = false
	env.environment.volumetric_fog_enabled = false
	await _frames(10)
	await _shot("zone_overview")
	env.environment.fog_enabled = fog_was
	env.environment.volumetric_fog_enabled = true
	cam.queue_free()
	player.camera_rig.camera.current = true
	for spot in [["zone_watchtower", Vector3(140, 0, 75), 200.0], ["zone_quarry", Vector3(-145, 0, -100), 40.0],
			["zone_road_north", Vector3(0, 0, -60), 0.0], ["zone_hamlet", Vector3(-70, 0, 110), 40.0]]:
		var p: Vector3 = spot[1]
		var terrain: ZoneTerrain = scene.get_node("Terrain")
		player.global_position = Vector3(p.x, terrain.height_at(p.x, p.z) + 0.2, p.z)
		player.reset_physics_interpolation()
		player.camera_rig.yaw = deg_to_rad(spot[2])
		player.camera_rig.global_position = player.global_position + Vector3.UP * 1.55
		await _frames(40)
		await _shot(spot[0])
	get_tree().quit()


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % shot_name)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
