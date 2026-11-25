extends SceneTree
## Builds the bandits (assets/characters/bandit/) from code: for every outfit in bandit_outfits.gd
## it paints a texture and saves the character's meshes (BD_<outfit>.scn); then the held gear the
## bandits bring themselves (BD_shield.scn, BD_shield_iron.scn, BD_crossbow.scn). Their swords,
## daggers and maces are the game's existing weapon models (assets/equipment/Weapons/).
## Run it again after changing any bandit_*.gd file:
##   Godot_console --headless --path . --script res://tools/build_bandit.gd
## The first time (no textures yet) it asks for an import between two runs:
##   Godot_console --headless --path . --import

const DIR := "res://assets/characters/bandit/"
const Mesh_ := preload("res://assets/characters/bandit/bandit_mesh.gd")
const Paint := preload("res://assets/characters/bandit/bandit_paint.gd")
const Body := preload("res://assets/characters/bandit/bandit_body.gd")
const Hair := preload("res://assets/characters/bandit/bandit_hair.gd")
const Clothes := preload("res://assets/characters/bandit/bandit_clothes.gd")
const Armor := preload("res://assets/characters/bandit/bandit_armor.gd")
const Gear := preload("res://assets/characters/bandit/bandit_gear.gd")
const Outfits := preload("res://assets/characters/bandit/bandit_outfits.gd")
const RIG_SCENE := "res://assets/characters/mannequin/UAL1_Standard.glb"

## Texture sizes: deliberately small, for the chunky hand-painted look.
const BODY_ATLAS := 768
const GEAR_ATLAS := 384
const MESH_NAMES := {"Body": "BodyMesh", "Head": "HeadMesh", "Hair": "HairMesh", "Clothing": "ClothingMesh", "Armor": "ArmorMesh"}
## held gear: mesh group -> scene name
const GEAR := {"Shield": "BD_shield", "ShieldIron": "BD_shield_iron", "Crossbow": "BD_crossbow"}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(DIR + "textures")
	DirAccess.make_dir_recursive_absolute(DIR + "materials")

	# shapes and paint
	var bodies := {}
	var missing := false
	for name_: String in Outfits.OUTFITS:
		var o: Dictionary = Outfits.OUTFITS[name_]
		var m = Mesh_.new()
		Body.build(m, o)
		Hair.build(m, o)
		Clothes.build(m, o)
		Armor.build(m, o)
		m.pack(BODY_ATLAS)
		bodies[name_] = m
		missing = _paint(m, BODY_ATLAS, "bandit_" + name_, false, o.colors, o.patches) or missing
	var gear = Mesh_.new()
	Gear.shield(gear)
	Gear.shield(gear, true)
	Gear.crossbow(gear)
	gear.pack(GEAR_ATLAS)
	missing = _paint(gear, GEAR_ATLAS, "bandit_gear", true, {}, true) or missing
	print("painted textures in %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	if missing:
		print("NEXT: run Godot with --import, then run this tool again.")
		quit()
		return

	# the characters: skinned meshes on the shared UAL1 skeleton
	var rig: Node = (load(RIG_SCENE) as PackedScene).instantiate()
	var sk: Skeleton3D = rig.find_children("*", "Skeleton3D", true, false)[0]
	var bones := {}
	var skin := Skin.new()
	for i in sk.get_bone_count():
		bones[sk.get_bone_name(i)] = i
		skin.add_bind(i, sk.get_bone_global_rest(i).affine_inverse())
		skin.set_bind_name(i, sk.get_bone_name(i))
	rig.free()
	for name_: String in bodies:
		var mat := _material("bandit_" + name_, 0.96, 0.0, 0.08)
		var meshes: Dictionary = bodies[name_].meshes(BODY_ATLAS, mat, bones)
		var root := Node3D.new()
		root.name = "BD_" + name_
		var total := 0
		var parts: Array[String] = []
		for group in MESH_NAMES:
			if not meshes.has(group):
				continue
			var mi := MeshInstance3D.new()
			mi.name = MESH_NAMES[group]
			mi.mesh = meshes[group]
			mi.skin = skin
			root.add_child(mi)
			mi.owner = root
			var tris: int = (meshes[group] as ArrayMesh).surface_get_array_len(0) / 3
			total += tris
			parts.append("%s %d" % [mi.name, tris])
		root.set_meta("triangles", total)
		# how far behind the spine a stowed shield hangs (further out over a cloak)
		root.set_meta("shield_back", -0.292 if Outfits.OUTFITS[name_].cloak else -0.255)
		_save(root, DIR + "BD_%s.scn" % name_)
		print("%-9s %5d triangles  (%s)" % [name_, total, ", ".join(parts)])

	# the held gear
	var gear_mat := _material("bandit_gear", 0.74, 0.14, 0.2)
	var held: Dictionary = gear.meshes(GEAR_ATLAS, gear_mat)
	for group: String in GEAR:
		var item := Node3D.new()
		item.name = GEAR[group]
		var mi := MeshInstance3D.new()
		mi.name = group + "Mesh"
		mi.mesh = held[group]
		item.add_child(mi)
		mi.owner = item
		if group == "Crossbow":
			var tip := Marker3D.new()
			tip.name = "Tip"
			tip.position = Gear.CROSSBOW_TIP
			item.add_child(tip)
			tip.owner = item
		print("%-14s %5d triangles" % [GEAR[group], (held[group] as ArrayMesh).surface_get_array_len(0) / 3])
		_save(item, DIR + GEAR[group] + ".scn")
	print("done in %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	quit()


## Paints and saves one texture. True if Godot has not imported it yet.
func _paint(m, size: int, name_: String, separate: bool, colors: Dictionary, patches: bool) -> bool:
	var path := DIR + "textures/%s.png" % name_
	var err := (Paint.bake(m, size, separate, colors, patches) as Image).save_png(path)
	if err != OK:
		push_error("could not save %s (%d)" % [path, err])
	return not ResourceLoader.exists(path)


## Rough, non-glossy, painted: the texture does the shading work.
func _material(name_: String, roughness: float, metallic: float, specular: float) -> StandardMaterial3D:
	var path := DIR + "materials/%s.tres" % name_
	var m := StandardMaterial3D.new()
	m.resource_name = name_
	m.albedo_texture = load(DIR + "textures/%s.png" % name_)
	m.roughness = roughness
	m.metallic = metallic
	m.metallic_specular = specular
	m.cull_mode = BaseMaterial3D.CULL_DISABLED   # open hems, cuffs, hood and cloak show their inside
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var err := ResourceSaver.save(m, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("material %s: %d" % [name_, err])
	m.take_over_path(path)
	return m


func _save(root: Node, path: String) -> void:
	var ps := PackedScene.new()
	ps.pack(root)
	var err := ResourceSaver.save(ps, path, ResourceSaver.FLAG_COMPRESS)
	if err != OK:
		push_error("%s: %d" % [path, err])
	root.free()
