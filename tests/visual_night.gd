extends Node
## Screenshots of the Tithelands at dusk, at night (with the lantern) and in the
## rain (not a pass/fail check). Saves user://shots/time_*.png. Windowed.

func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(40)
	var player := get_tree().get_first_node_in_group(&"player") as Player
	var dn := scene.get_node("DayNight") as DayNight
	var terrain: ZoneTerrain = scene.get_node("Terrain")
	var p := Vector3(-70, 0, 110)
	player.global_position = Vector3(p.x, terrain.height_at(p.x, p.z) + 0.2, p.z)
	player.reset_physics_interpolation()
	player.camera_rig.yaw = deg_to_rad(40.0)
	for shot in [["time_day", 0.3, false], ["time_dusk", dn.day_share() - 0.02, false], ["time_night", dn.day_share() + 0.1, false], ["time_rain", 0.3, true]]:
		dn.set_time(shot[1])
		dn.set_rain(shot[2])
		dn.rain_amount = 1.0 if shot[2] else 0.0
		await get_tree().create_timer(2.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % shot[0])
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
