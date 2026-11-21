extends SceneTree
## Bakes the bandit-hideout asset library to scene files and material resources.
##   Godot_console.exe --headless --path . --script res://tools/export_hideout.gd
## Writes <folder>/<name>.scn for every catalog entry, Materials/*.tres for the shared materials
## and Example_Hideout_Scene/hideout_example.scn.

const Kit := preload("res://assets/hideout/Materials/kit.gd")
const Catalog := preload("res://assets/hideout/Materials/catalog.gd")
const Scene := preload("res://assets/hideout/Example_Hideout_Scene/hideout_scene.gd")
const BASE := "res://assets/hideout/"


func _initialize() -> void:
	_run.call_deferred()


func _own(n: Node, owner_: Node) -> void:
	for c in n.get_children():
		c.owner = owner_
		_own(c, owner_)


func _save_scene(root: Node, path: String) -> int:
	_own(root, root)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		return err
	return ResourceSaver.save(ps, path)


func _tris(n: Node) -> int:
	var t := 0
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var m := (c as MeshInstance3D).mesh
		if m:
			for s in m.get_surface_count():
				t += m.surface_get_array_len(s) / 3
	return t


func _run() -> void:
	var entries := Catalog.entries()
	# 1. build everything once so every shared material exists, then save materials as resources
	var built: Array = []
	for e in entries:
		built.append((e[2] as Callable).call())
	var saved := 0
	for key in Kit._cache.keys():
		var k: String = key
		if k.begins_with("plain_") or k == "soft":
			continue
		var mat = Kit._cache[key]
		if mat is Material:
			var err := ResourceSaver.save(mat, BASE + "Materials/%s.tres" % k, ResourceSaver.FLAG_CHANGE_PATH)
			if err == OK:
				saved += 1
			else:
				push_error("material %s: %d" % [k, err])
	print("materials saved: ", saved)
	# 2. save each asset
	var total_tris := 0
	var ok_count := 0
	for i in entries.size():
		var e: Array = entries[i]
		var node: Node = built[i]
		node.name = e[1]
		var path := BASE + "%s/%s.scn" % [e[0], e[1]]
		var tris := _tris(node)
		total_tris += tris
		var err := _save_scene(node, path)
		if err == OK:
			ok_count += 1
		else:
			push_error("%s failed: %d" % [path, err])
		print("%-22s %-28s %6d tris" % [e[0], e[1], tris])
	print("assets saved: %d / %d, %d triangles total" % [ok_count, entries.size(), total_tris])
	# 3. the assembled scene (built from the live builders; instances share the saved materials)
	var scene := Scene.build()
	var err2 := _save_scene(scene, BASE + "Example_Hideout_Scene/hideout_example.scn")
	print("example scene: ", "ok" if err2 == OK else "FAILED %d" % err2, "  tris=", _tris(scene))
	quit()

