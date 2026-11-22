extends Node
## Screenshots of the mill and its race (not pass/fail). Windowed. Saves user://shots/mill_*.png

func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(90)
	var cam := Camera3D.new()
	cam.far = 600.0
	cam.fov = 60.0
	scene.add_child(cam)
	cam.current = true
	var terrain: ZoneTerrain = scene.get_node("Terrain")
	var tgt := Vector3(-103, 0, -1.5)
	tgt.y = terrain.height_at(tgt.x, tgt.z) + 1.5
	for s in [["a_south", Vector3(-104, 9, 20)], ["b_east", Vector3(-80, 7, -2)], ["c_north", Vector3(-104, 9, -26)], ["d_high", Vector3(-100, 40, 25)], ["e_west", Vector3(-128, 6, -1)], ["f_close", Vector3(-97, 9.0, 8.0)], ["g_pond", Vector3(-106, 8.2, -11.0)]]:
		var p: Vector3 = s[1]
		cam.global_position = Vector3(p.x, maxf(p.y, terrain.height_at(p.x, p.z) + 3.0), p.z)
		cam.look_at(tgt)
		await _frames(25)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots/mill_%s.png" % s[0])
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
