extends Node
## Screenshot of the map screen after a little exploring (not a pass/fail check).
## Saves user://shots/map.png. Windowed.

func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(30)
	var player := get_tree().get_first_node_in_group(&"player") as Player
	var terrain: ZoneTerrain = scene.get_node("Terrain")
	# Walk the old road north, then west to the mill.
	for p in [Vector3(0, 0, 84), Vector3(0, 0, 42), Vector3(0, 0, 0), Vector3(-40, 0, -20), Vector3(-90, 0, -30), Vector3(-110, 0, -40)]:
		player.global_position = Vector3(p.x, terrain.height_at(p.x, p.z) + 0.2, p.z)
		await get_tree().create_timer(0.6).timeout
	var hud := scene.get_node("Hud")
	(hud.get(&"_map_panel") as MapPanel).open(player, true)
	await _frames(20)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/map.png")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
