extends Node
## Screenshots down the quarry descent, from the quarry floor to the Gullet's yard.
## Saves user://shots/descent_<n>.png   (windowed: --resolution 1280x720)
func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	for i in 90:
		await get_tree().process_frame
	var player := get_tree().get_first_node_in_group(&"player") as Player
	QuarryDescent.compute()
	var total: float = QuarryDescent.cum[QuarryDescent.cum.size() - 1]
	var spots: Array = [-12.0, -4.0, 4.0, 10.0, 16.0, 24.0, 34.0, 48.0, 62.0, 78.0, 96.0, 112.0, 124.0, total - 3.0]
	var n := 0
	for s: float in spots:
		var pos := Vector3.ZERO
		var dir := Vector3.RIGHT
		if s < 0.0:
			# outside, on the quarry floor, looking at the mouth
			pos = QuarryDescent.pts[0] + Vector3(-s, 0.2, 0)
			dir = Vector3.LEFT
		else:
			for k in range(QuarryDescent.pts.size() - 1):
				if s <= QuarryDescent.cum[k + 1]:
					var t: float = (s - QuarryDescent.cum[k]) / maxf(QuarryDescent.cum[k + 1] - QuarryDescent.cum[k], 0.001)
					pos = QuarryDescent.pts[k].lerp(QuarryDescent.pts[k + 1], t) + Vector3(0, 0.2, 0)
					dir = Vector3(QuarryDescent.pts[k + 1].x - QuarryDescent.pts[k].x, 0, QuarryDescent.pts[k + 1].z - QuarryDescent.pts[k].z).normalized()
					break
		player.global_position = pos
		player.velocity = Vector3.ZERO
		player.reset_physics_interpolation()
		player.camera_rig.yaw = atan2(-dir.x, -dir.z)
		DayNight.cave = QuarryDescent.depth_cave(pos + Vector3(0, 1.0, 0))
		for i in 45:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots/descent_%02d.png" % n)
		print("shot ", n, " s=", s, " cave=", DayNight.cave)
		n += 1
	get_tree().quit()
