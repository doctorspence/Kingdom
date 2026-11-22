extends Node
## Close-ups of the scattered cliff rock faces (not pass/fail). Saves user://shots/<prefix>_cliff*.png
func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var prefix: String = args[1] if args.size() > 1 else "cliff"
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(90)
	var terrain: SculptedTerrain = scene.get_node("Terrain")
	var spots: Array = []
	for mmi in scene.get_node("CliffFaces").get_children():
		var m := (mmi as MultiMeshInstance3D).multimesh if mmi is MultiMeshInstance3D else null
		if m == null:
			continue
		var bb: AABB = m.mesh.get_aabb()
		for i in m.instance_count:
			var t: Transform3D = m.get_instance_transform(i)
			spots.append([t.origin, t.basis.get_scale().x, (t * bb).size])
	print("cliff instances: ", spots.size())
	for s in spots.slice(0, 40):
		pass
	var cam := Camera3D.new()
	cam.far = 500.0
	cam.fov = 62.0
	scene.add_child(cam)
	cam.current = true
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	var picks: Array = []
	var step := maxi(1, spots.size() / 6)
	for i in range(0, spots.size(), step):
		picks.append(spots[i])
	var n := 0
	for s in picks.slice(0, 6):
		var o: Vector3 = s[0]
		print("cliff ", n, " at ", o, " scale ", s[1], " size ", s[2])
		var gy := terrain.height_at(o.x, o.z)
		# stand 14 m away toward the zone centre, at eye height
		var dir := Vector3(-o.x, 0, -o.z).normalized()
		var cp := o + dir * 14.0
		cp.y = terrain.height_at(cp.x, cp.z) + 1.7
		if player:
			player.global_position = Vector3(cp.x, cp.y - 1.5, cp.z)
		cam.global_position = cp
		cam.look_at(Vector3(o.x, gy + 2.0, o.z))
		await _frames(60)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots/%s_cliff%d.png" % [prefix, n])
		n += 1
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
