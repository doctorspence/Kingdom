extends SceneTree
## Builds the equipment pack: materials, model scenes, item + weapon + shield definitions.
##   Godot_console.exe --headless --path . --script res://tools/build_equipment.gd [-- id1,id2 | -- all]
## Run tools/gen_equipment_textures.gd and an --import first (textures must be imported).
## After the models exist, tools/render_equipment_icons.gd renders the icons; run this again
## afterwards so the item definitions pick the icons up.

const Kit := preload("res://assets/equipment/eq_kit.gd")
const Catalog := preload("res://assets/equipment/eq_catalog.gd")
const A := preload("res://assets/equipment/eq_armor.gd")
const BASE := "res://assets/equipment/"

var _only := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


static func _own(n: Node, owner_: Node) -> void:
	for c in n.get_children():
		c.owner = owner_
		_own(c, owner_)


static func _tris(n: Node) -> int:
	var t := 0
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var m := (c as MeshInstance3D).mesh
		if m:
			for s in m.get_surface_count():
				t += m.surface_get_array_len(s) / 3
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var m := (n as MeshInstance3D).mesh
		for s in m.get_surface_count():
			t += m.surface_get_array_len(s) / 3
	return t


static func scene_path(e: Dictionary) -> String:
	return "%s%s/%s/%s.scn" % [BASE, e.folder, e.cat, String(e.id).trim_prefix("item_")]


static func icon_path(e: Dictionary) -> String:
	return "%sInventoryIcons/%s/%s.png" % [BASE, "Armor" if e.folder == "Armor" else "Weapons", e.id]


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var bake := args.size() > 0 and (args[0] == "bake" or args[0] == "bake_fast")
	if args.size() > 0 and args[0] == "bake_fast":
		A.big_mult = 1
	if bake:
		args = args.slice(1)
	if args.size() > 0 and args[0] != "all":
		_only = args[0].split(",")
	# 1. materials
	for name in Kit.all_names():
		var d: Array = Kit.DEFS[name]
		var dir: String = BASE + "Materials/" + String(d[0])
		DirAccess.make_dir_recursive_absolute(dir)
		var m := Kit.build(name)
		var err := ResourceSaver.save(m, "%s/%s.tres" % [dir, name], ResourceSaver.FLAG_CHANGE_PATH)
		if err != OK:
			push_error("material %s: %d" % [name, err])
		Kit._cache[name] = m
	var all: Array = Catalog.entries()
	all.append_array(Catalog.armor_entries())
	var report: Array[String] = []
	for e in all:
		if not _only.is_empty() and not (String(e.id) in _only):
			continue
		if bake:
			if e.kind == "armor":
				_bake(e)
			continue
		var model: Node3D = null
		if e.kind == "armor":
			model = A.painted_root("Armor_" + String(e.id).trim_prefix("item_"), String(e.id), _mesh_path(e))
		if model == null:
			model = Catalog.build_model(e)
		if model == null:
			push_error("no model for " + String(e.id))
			continue
		var tris := _tris(model)
		var path := scene_path(e)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		_own(model, model)
		var ps := PackedScene.new()
		ps.pack(model)
		var err := ResourceSaver.save(ps, path)
		model.free()
		if err != OK:
			push_error("scene %s: %d" % [path, err])
			continue
		if e.kind == "armor":
			# the slender body still wears the mannequin fit: saved next to it as <id>_f.scn
			var fm := Catalog.build_model(e, "mannequin")
			var fpath := path.replace(".scn", "_f.scn")
			_own(fm, fm)
			var fps := PackedScene.new()
			fps.pack(fm)
			ResourceSaver.save(fps, fpath)
			fm.free()
		_make_definitions(e, load(path) if ResourceLoader.exists(path) else ps)
		report.append("%s  %d tris" % [e.id, tris])
	print("\n".join(report))
	print("built ", report.size(), " items")
	quit()


func _make_definitions(e: Dictionary, scene: PackedScene) -> void:
	var item_path := "res://data/items/%s/%s.tres" % ["weapons" if e.folder == "Weapons" else "armor", e.id]
	var item: ItemData = load(item_path) if ResourceLoader.exists(item_path) else ItemData.new()
	var is_new := item.id == &"item_unnamed"
	if is_new:
		item.id = StringName(e.id)
		item.display_name = e.name
		item.flavor = e.get("flavor", "")
		item.slot = e.slot
		item.grid_size = e.grid
		item.weight = e.weight
		item.value = int(e.value)
		item.armor = e.get("armor", 0.0)
		item.stats = e.get("stats", {})
	item.required_level = e.level
	item.tier = StringName(e.tier)
	item.icon_color = _tier_color(e.tier)
	var ipath := icon_path(e)
	item.icon = load(ipath) if ResourceLoader.exists(ipath) else null
	var wid := String(e.id).trim_prefix("item_")
	match e.kind:
		"weapon":
			var wd: WeaponData = item.weapon
			if wd == null:
				wd = (load("res://data/weapons/%s.tres" % e.template) as WeaponData).duplicate(true)
				wd.id = StringName("weapon_" + wid)
				wd.display_name = e.name
				var dmg: float = e.base_dmg * Catalog.TIER_DMG.get(e.tier, 1.0)
				wd.damage = roundf(dmg)
				if e.has("int_scaling"):
					wd.scaling_intellect = e.int_scaling
				wd.visual_scene = scene
				var wpath := "res://data/weapons/weapon_%s.tres" % wid
				ResourceSaver.save(wd, wpath)
				wd = load(wpath)
			else:
				wd.visual_scene = scene
				ResourceSaver.save(wd)
			item.weapon = wd
		"shield":
			var sd: ShieldData = item.shield
			if sd == null:
				sd = (load("res://data/shields/%s.tres" % e.template) as ShieldData).duplicate(true)
				sd.id = StringName("shield_" + e.tier)
				sd.display_name = e.name
				sd.stamina_per_damage = {"bronze": 0.62, "iron": 0.5, "steel": 0.42}[e.tier]
				sd.visual_scene = scene
				var spath := "res://data/shields/shield_%s.tres" % e.tier
				ResourceSaver.save(sd, spath)
				sd = load(spath)
			else:
				sd.visual_scene = scene
				ResourceSaver.save(sd)
			item.shield = sd
		"armor":
			item.model_scene = scene
	DirAccess.make_dir_recursive_absolute(item_path.get_base_dir())
	ResourceSaver.save(item, item_path)


static func _tier_color(t: String) -> Color:
	match t:
		"bronze": return Color(0.62, 0.4, 0.22)
		"iron": return Color(0.4, 0.4, 0.43)
		"steel": return Color(0.68, 0.7, 0.75)
	return Color(0.45, 0.33, 0.22)


static func _mesh_path(e: Dictionary) -> String:
	return scene_path(e).replace(".scn", ".mesh.res")


## Bakes one armor piece: builds it with painting on, saves the painted textures and the UV'd mesh.
## Run again without "bake" after an --import to assemble the scenes.
func _bake(e: Dictionary) -> void:
	A.paint_size = 1024
	var model := A.build(e.build, "outcast")
	A.paint_size = 0
	if model == null:
		push_error("no model for " + String(e.id))
		return
	DirAccess.make_dir_recursive_absolute(A.PAINT_DIR)
	var paint: Image = model.get_meta("paint")
	var mask: Image = model.get_meta("mask")
	paint.save_png("%s%s_paint.png" % [A.PAINT_DIR, e.id])
	mask.save_png("%s%s_mask.png" % [A.PAINT_DIR, e.id])
	var mesh := (model.get_child(0) as MeshInstance3D).mesh
	var path := _mesh_path(e)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	ResourceSaver.save(mesh, path)
	print("baked %s: %d tris, %dx%d, %.2f mm per texel" % [e.id, mesh.surface_get_array_len(0) / 3, paint.get_width(), paint.get_height(), model.get_meta("texel_mm")])
	model.free()
