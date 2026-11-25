extends SceneTree
## Bakes the White Knights Outpost asset library (assets/outpost/, see its README.md).
##   1. Paint the textures (PNG files plus their import settings):
##        Godot_console --headless --path . --script res://tools/export_outpost.gd -- textures
##   2. Import them: Godot_console --headless --path . --import   (or open the editor once)
##   3. Bake every asset to <folder>/<ID_name>.scn and the shared materials to materials/*.tres:
##        Godot_console --headless --path . --script res://tools/export_outpost.gd
## Step 3 alone is enough after changing a builder; steps 1-2 only after changing painter.gd.

const Painter := preload("res://assets/outpost/materials/painter.gd")
const Kit := preload("res://assets/outpost/materials/outpost_kit.gd")
const Catalog := preload("res://assets/outpost/catalog.gd")
const BASE := "res://assets/outpost/"

const IMPORT := """[remap]

importer="texture"
type="CompressedTexture2D"

[deps]

source_file="%s"

[params]

compress/mode=2
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=true
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=0
"""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and args[0] == "textures":
		_textures(args.slice(1))
	else:
		_bake()
	quit()


func _textures(only: Array) -> void:
	DirAccess.make_dir_recursive_absolute(BASE + "materials/textures")
	for name: String in Painter.all().keys():
		if not only.is_empty() and not only.has(name):
			continue
		var t0 := Time.get_ticks_msec()
		var img := Painter.paint(name)
		var path := BASE + "materials/textures/%s.png" % name
		var err := img.save_png(path)
		if err != OK:
			push_error("%s: %d" % [path, err])
			continue
		if not FileAccess.file_exists(path + ".import"):
			var f := FileAccess.open(path + ".import", FileAccess.WRITE)
			f.store_string(IMPORT % path)
			f.close()
		print("%-18s %4dx%-4d %5d ms" % [name, img.get_width(), img.get_height(), Time.get_ticks_msec() - t0])
	print("Now import them: --headless --path . --import (or open the editor).")


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


func _bake() -> void:
	var entries := Catalog.entries()
	# 1. Build everything once so every shared material exists, then save the materials.
	var built: Array = []
	for e in entries:
		built.append((e[2] as Callable).call())
	var saved := 0
	for key: String in Kit._cache.keys():
		var mat = Kit._cache[key]
		if mat is Material:
			var err := ResourceSaver.save(mat, BASE + "materials/%s.tres" % key, ResourceSaver.FLAG_CHANGE_PATH)
			if err == OK:
				saved += 1
			else:
				push_error("material %s: %d" % [key, err])
	print("materials saved: ", saved)
	# 2. Save each asset.
	var total := 0
	var ok := 0
	for i in entries.size():
		var e: Array = entries[i]
		var node: Node3D = built[i]
		node.name = e[1]
		DirAccess.make_dir_recursive_absolute(BASE + e[0])
		var path := BASE + "%s/%s.scn" % [e[0], e[1]]
		var tris := 0
		for mi in node.find_children("*", "MeshInstance3D", true, false):
			tris += Kit.tris((mi as MeshInstance3D).mesh)
		total += tris
		var size := Vector3.ZERO
		var mesh_node := node.get_node_or_null("Mesh") as MeshInstance3D
		if mesh_node:
			size = mesh_node.mesh.get_aabb().size
		var err := _save_scene(node, path)
		if err == OK:
			ok += 1
		else:
			push_error("%s failed: %d" % [path, err])
		print("%-15s %-40s %6d tris  %5.2f x %5.2f x %5.2f m" % [e[0], e[1], tris, size.x, size.y, size.z])
	print("assets saved: %d / %d, %d triangles total" % [ok, entries.size(), total])
	for n in built:
		(n as Node).free()
