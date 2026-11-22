extends Node
## Eye-height screenshots in woods and meadow (not pass/fail). Windowed. Saves user://shots/<prefix>_*.png
## Prefix is the first user arg after the check name (default "wood").

func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var args := OS.get_cmdline_user_args()
	var prefix: String = args[1] if args.size() > 1 else "wood"
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(90)
	var terrain: SculptedTerrain = scene.get_node("Terrain")
	var land: Object = terrain.land
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	var cam := Camera3D.new()
	cam.fov = 62.0
	cam.far = 500.0
	scene.add_child(cam)
	cam.current = true
	var woods: Array[Vector2] = []
	var meadows: Array[Vector2] = []
	var x := -150.0
	while x <= 170.0:
		var z := -150.0
		while z <= 170.0:
			var h := terrain.height_at(x, z)
			var sl := absf(terrain.height_at(x + 2, z) - h) + absf(terrain.height_at(x, z + 2) - h)
			if sl < 0.5 and terrain.in_pad(x, z) < 0.01 and terrain.river_distance(x, z) > 14.0 and terrain._distance_to_lines(terrain.roads, Vector2(x, z)) > 8.0:
				var f: float = land.forest(x, z)
				if f > 0.8:
					woods.append(Vector2(x, z))
				elif f < 0.05 and terrain.in_field(x, z) < 0.1:
					meadows.append(Vector2(x, z))
			z += 12.0
		x += 12.0
	print("woods candidates ", woods.size(), " meadows ", meadows.size())
	var shots: Array = []
	for i in 3:
		if woods.size() > 0:
			shots.append(["wood%d" % i, woods[(i * 7 + 3) % woods.size()], i * 120.0])
	for i in 3:
		if meadows.size() > 0:
			shots.append(["meadow%d" % i, meadows[(i * 11 + 5) % meadows.size()], i * 90.0 + 30.0])
	for s in shots:
		var p: Vector2 = s[1]
		var gy := terrain.height_at(p.x, p.y)
		if player:
			player.global_position = Vector3(p.x, gy + 0.2, p.y)  # keeps streaming/culling centred here
		cam.global_position = Vector3(p.x, gy + 1.7, p.y)
		cam.rotation = Vector3(deg_to_rad(-8.0), deg_to_rad(s[2]), 0.0)
		await _frames(80)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots/%s_%s.png" % [prefix, s[0]])
		print("shot ", s[0], " at ", p)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
