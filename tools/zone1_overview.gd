extends Node
## Top-down picture of the Tithelands ground with places (white), enemy
## spawns (red) and trees (dark dots). Saves user://shots/zone1_overview.png.
##   Godot_console.exe --headless --path . --script res://tests/run.gd -- ../tools/zone1_overview

func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	for i in 20:
		await get_tree().process_frame
	var terrain: ZoneTerrain = scene.get_node("Terrain")
	var px := 728
	var img := terrain.map_image(px)
	var k := px / terrain.size
	var half := terrain.size * 0.5
	var trunks := scene.get_node_or_null("Woods/Trunks")
	if trunks:
		for t in trunks.get_children():
			_dot(img, (t.global_position.x + half) * k, (t.global_position.z + half) * k, 1, Color(0.08, 0.12, 0.06))
	for r in scene.get_node("Rocks").get_children():
		_dot(img, (r.global_position.x + half) * k, (r.global_position.z + half) * k, 1, Color(0.6, 0.6, 0.6))
	for c in scene.get_node("Places").get_children():
		if c is Node3D:
			_dot(img, (c.global_position.x + half) * k, (c.global_position.z + half) * k, 2, Color(1, 1, 1))
	for c in scene.get_node("EnemySpawns").get_children():
		_dot(img, (c.global_position.x + half) * k, (c.global_position.z + half) * k, 2, Color(0.9, 0.1, 0.1))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	img.save_png("user://shots/zone1_overview.png")
	print("saved overview")
	get_tree().quit()


func _dot(img: Image, x: float, y: float, r: int, c: Color) -> void:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var xi := int(x) + dx
			var yi := int(y) + dy
			if xi >= 0 and yi >= 0 and xi < img.get_width() and yi < img.get_height():
				img.set_pixel(xi, yi, c)
