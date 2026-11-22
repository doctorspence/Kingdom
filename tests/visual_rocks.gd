extends Node
## Close-ups of the biggest scattered boulders (Rocks node). Saves user://shots/<prefix>_rock*.png
func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var prefix: String = args[1] if args.size() > 1 else "rock"
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(90)
	var terrain: SculptedTerrain = scene.get_node("Terrain")
	var rocks: Array = []
	for r in scene.get_node("Rocks").get_children():
		if r is Node3D and r.get_script() != null:
			rocks.append(r)
	rocks.sort_custom(func(a: Node3D, b: Node3D) -> bool: return a.scale.x > b.scale.x)
	print("rocks: ", rocks.size())
	var cam := Camera3D.new()
	cam.far = 500.0
	cam.fov = 62.0
	scene.add_child(cam)
	cam.current = true
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	var n := 0
	for r: Node3D in rocks.slice(0, 5):
		var o := r.global_position
		print("rock ", n, " at ", o, " scale ", r.scale.x)
		var dir := Vector3(-o.x, 0, -o.z).normalized()
		var cp := o + dir * (6.0 + r.scale.x * 3.0)
		cp.y = terrain.height_at(cp.x, cp.z) + 1.7
		if player:
			player.global_position = Vector3(cp.x, cp.y - 1.5, cp.z)
		cam.global_position = cp
		cam.look_at(o + Vector3.UP * 1.5)
		await _frames(60)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots/%s_rock%d.png" % [prefix, n])
		n += 1
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
