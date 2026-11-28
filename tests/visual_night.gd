extends Node
## Screenshots of the Tithelands at dawn, dusk, night (stars, lit windows) and in
## the rain (not a pass/fail check). Saves user://shots/time_*.png. Windowed.

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
	var ds := dn.day_share()
	# name, time, rain, x, z, yaw, pitch
	var shots := [
		["time_day", 0.3, false, -70, 110, 40, 8],
		["time_golden", ds * 0.92, false, -70, 110, 40, 8],
		["time_dawn", ds * 0.05, false, -70, 110, 40, 8],
		["time_dusk", ds - 0.02, false, -70, 110, 40, 8],
		["time_night", ds + 0.1, false, -70, 110, 40, 8],
		["time_night_sky", ds + 0.1, false, -70, 110, 40, 40],
		["time_night_hamlet", ds + 0.1, false, -49, 77, 40, 6],
		["time_night_farm", ds + 0.1, false, -44, 98, 180, 6],
		["time_golden_farm", ds * 0.93, false, -44, 98, 180, 6],
		["time_night_farm_near", ds + 0.1, false, -40, 93, 170, 4],
		["time_night_farm_back", ds + 0.1, false, -37, 79, 0, 4],
		["time_rain", 0.3, true, -70, 110, 40, 8],
		["time_rain_hamlet", 0.3, true, -49, 77, 40, 6],
		["time_dawn_dell", ds * 0.05, false, 140, 40, -120, 6],
		["time_night_woods", ds + 0.1, false, 94, 92, 180, 6],
		["time_rain_woods", 0.3, true, 94, 92, 180, 6],
		["time_day_farm_near", 0.3, false, -40, 93, 170, 4],
		# Facing the moon (yaw "moon"): its rays through the trees.
		["time_night_moon", ds + 0.1, false, -70, 110, "moon", 6],
		["time_night_woods_moon", ds + 0.1, false, 94, 92, "moon", 6],
		["time_night_hamlet_moon", ds + 0.1, false, -49, 77, "moon", 4],
	]
	for a in OS.get_cmdline_user_args().slice(1):
		shots = shots.filter(func(s): return s[0] in OS.get_cmdline_user_args())
		break
	for shot in shots:
		var x: float = shot[3]
		var z: float = shot[4]
		player.global_position = Vector3(x, terrain.height_at(x, z) + 0.2, z)
		player.velocity = Vector3.ZERO
		player.reset_physics_interpolation()
		dn.set_time(shot[1])
		if shot[5] is String:
			var d: Vector3 = dn.sun.global_transform.basis.z
			player.camera_rig.yaw = atan2(-d.x, -d.z)
		else:
			player.camera_rig.yaw = deg_to_rad(shot[5])
		player.camera_rig.pitch = deg_to_rad(shot[6])
		dn.set_rain(shot[2])
		dn.rain_amount = 1.0 if shot[2] else 0.0
		dn.wet_ground = 1.0 if shot[2] else 0.0
		await get_tree().create_timer(2.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % shot[0])
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
