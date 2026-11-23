extends Node
## Screenshots of Harl's Stone Eruption ring: warning, then spikes. Saves user://shots/burst_*.png
func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(60)
	var terrain: SculptedTerrain = scene.get_node("Terrain")
	var p := Vector3(4, 0, 150)
	p.y = terrain.height_at(p.x, p.z)
	var b := StoneBurst.new()
	b.radius = 2.4
	b.delay = 1.2
	b.damage = 0.0
	scene.add_child(b)
	b.global_position = p
	var cam := Camera3D.new()
	scene.add_child(cam)
	cam.current = true
	cam.global_position = p + Vector3(0, 4.5, 7.5)
	cam.look_at(p + Vector3(0, 0.5, 0))
	for s in [["warn", 40], ["late", 22], ["spikes", 12]]:
		await _frames(s[1])
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots/burst_%s.png" % s[0])
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
