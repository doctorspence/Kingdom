extends Node
## Tree gallery: every species and variant from TreeSpecies in rows on a lawn
## under the zone's light (not a check). Windowed:
##   Godot --path . --resolution 1600x900 --script res://tests/run.gd -- ../tools/preview_trees [kind ...]
## Saves user://shots/trees_<kind>.png (one row per kind, near detail),
## trees_<kind>_far.png (the far version) and trees_lineup.png (one of each).
## Prints the triangle counts.

func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var we := WorldEnvironment.new()
	we.environment = load("res://levels/common/tithelands_env.tres")
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, 35, 0)
	sun.light_energy = 1.6
	sun.light_color = Color(0.98, 0.9, 0.78)
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.29, 0.33, 0.22)
	gm.roughness = 1.0
	ground.material_override = gm
	add_child(ground)
	var cam := Camera3D.new()
	cam.fov = 50
	add_child(cam)
	var kinds: Array = []
	for a in OS.get_cmdline_user_args().slice(1):
		kinds.append(String(a))
	if kinds.is_empty():
		kinds = TreeSpecies.KINDS.keys()
	var t0 := Time.get_ticks_msec()
	for kind: String in kinds:
		var row := Node3D.new()
		add_child(row)
		var n := TreeSpecies.count(kind)
		var spacing := 20.0 if kind == "oak_ancient" else 13.0
		var tris := 0
		for i in n:
			var d := TreeSpecies.build(kind, i)
			for m: Mesh in d.near:
				var mi := MeshInstance3D.new()
				mi.mesh = m
				mi.position = Vector3((i - (n - 1) * 0.5) * spacing, 0, 0)
				row.add_child(mi)
				tris += _tris(m)
		var width := n * spacing
		cam.position = Vector3(0, 6.0, width * 0.62 + 10.0)
		cam.look_at(Vector3(0, 6.0, 0))
		await _shot("trees_%s" % kind)
		print("TREES %-12s %d variants, %d triangles each on average" % [kind, n, tris / n])
		# The far versions, same spots.
		for c in row.get_children():
			c.queue_free()
		for i in n:
			var d := TreeSpecies.build(kind, i)
			var mi := MeshInstance3D.new()
			mi.mesh = d.far
			mi.position = Vector3((i - (n - 1) * 0.5) * spacing, 0, 0)
			row.add_child(mi)
		await _shot("trees_%s_far" % kind)
		print("TREES %-12s far version %d triangles" % [kind, _tris(TreeSpecies.build(kind, 0).far)])
		row.queue_free()
	print("TREES built in %d ms" % (Time.get_ticks_msec() - t0))
	# Line-up: one of each, side by side.
	var line := ["oak", "oak_ancient", "oak_dead", "beech", "ash", "birch", "yew"]
	var x := -48.0
	for kind: String in line:
		var d := TreeSpecies.build(kind, 3 if kind == "oak" else 0)
		for m: Mesh in d.near:
			var mi := MeshInstance3D.new()
			mi.mesh = m
			mi.position = Vector3(x, 0, 0)
			add_child(mi)
		x += 18.0 if kind == "oak_ancient" else 15.0
	cam.position = Vector3(0, 7.0, 72.0)
	cam.look_at(Vector3(0, 7.0, 0))
	await _shot("trees_lineup")
	get_tree().quit()


func _shot(name: String) -> void:
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % name)


func _tris(m: Mesh) -> int:
	var t := 0
	for s in m.get_surface_count():
		t += m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX].size() / 3
	return t
