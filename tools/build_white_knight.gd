extends SceneTree
## Builds the White Knight (assets/characters/white_knight/): its materials (materials/*.tres)
## the outfit mesh (WK_white_knight.scn) and the held shield (WK_heater_shield.scn). Run tools/white_knight_textures.py and an
## --import first, so the textures exist.
##   Godot_console --headless --path . --script res://tools/build_white_knight.gd

const WK := preload("res://assets/characters/white_knight/white_knight.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(WK.MAT_DIR)
	for n in WK.MATS:
		var m := WK.make_mat(n)
		var err := ResourceSaver.save(m, WK.MAT_DIR + n + ".tres", ResourceSaver.FLAG_CHANGE_PATH)
		if err != OK:
			push_error("material %s: %d" % [n, err])
		WK._mats[n] = m
	var t0 := Time.get_ticks_msec()
	var root := WK.build()
	for c in root.get_children():
		c.owner = root
	var ps := PackedScene.new()
	ps.pack(root)
	var path: String = WK.DIR + WK.NAME + ".scn"
	var err := ResourceSaver.save(ps, path)
	if err != OK:
		push_error("scene: %d" % err)
	var mesh: ArrayMesh = (root.get_node("Mesh") as MeshInstance3D).mesh
	var lines: Array[String] = []
	for s in mesh.get_surface_count():
		lines.append("  %s: %d triangles" % [mesh.surface_get_material(s).resource_name, mesh.surface_get_array_len(s) / 3])
	print("\n".join(lines))
	print("built %s: %d triangles in %d surfaces, %.1f s" % [path, root.get_meta("triangles"), mesh.get_surface_count(), (Time.get_ticks_msec() - t0) / 1000.0])
	root.free()
	var sh := WK.shield()
	for c in sh.get_children():
		c.owner = sh
	var sps := PackedScene.new()
	sps.pack(sh)
	err = ResourceSaver.save(sps, WK.DIR + WK.SHIELD_NAME + ".scn")
	if err != OK:
		push_error("shield: %d" % err)
	print("built shield")
	sh.free()
	quit()
