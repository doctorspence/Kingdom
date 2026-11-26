extends SceneTree
## Builds the bandits (assets/characters/bandit/) from code: for every outfit in bandit_outfits.gd
## it paints a texture and saves the character's meshes (BD_<outfit>.scn); then the held gear the
## bandits bring themselves (BD_shield.scn, BD_shield_iron.scn, BD_crossbow.scn, BD_axe.scn) and
## Harl's pick (BD_harl_pick.scn). Their swords, daggers and maces are the game's existing weapon
## models (assets/equipment/Weapons/).
## Run it again after changing any bandit_*.gd or harl_*.gd file:
##   Godot_console --headless --path . --script res://tools/build_bandit.gd
## To rebuild only some of it, name them after "--": outfit names, "gear", for example
##   ... --script res://tools/build_bandit.gd -- harl
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
const Harl := preload("res://assets/characters/bandit/harl_parts.gd")
const Outfits := preload("res://assets/characters/bandit/bandit_outfits.gd")
const RIG_SCENE := "res://assets/characters/mannequin/UAL1_Standard.glb"

## Texture sizes: deliberately small, for the chunky hand-painted look.
const BODY_ATLAS := 768
const GEAR_ATLAS := 384
const MESH_NAMES := {"Body": "BodyMesh", "Head": "HeadMesh", "Hair": "HairMesh", "Clothing": "ClothingMesh", "Armor": "ArmorMesh"}
## held gear: mesh group -> scene name
const GEAR := {"Shield": "BD_shield", "ShieldIron": "BD_shield_iron", "Crossbow": "BD_crossbow", "Axe": "BD_axe"}
## where the weapon trail comes from, on the gear that needs it
const TIPS := {"Crossbow": Gear.CROSSBOW_TIP, "Axe": Vector3(0.3, 0.92, 0.0), "Pick": Vector3(0.3, 0.92, 0.0)}
## long hafted weapons: hung on the hip with the head turned up (bandit_model.gd)
const BLADE_UP := ["Axe", "Pick"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	var only := Array(OS.get_cmdline_user_args())
	DirAccess.make_dir_recursive_absolute(DIR + "textures")
	DirAccess.make_dir_recursive_absolute(DIR + "materials")

	# shapes and paint
	var bodies := {}
	var missing := false
	for name_: String in Outfits.OUTFITS:
		if not only.is_empty() and not name_ in only:
			continue
		var o: Dictionary = Outfits.OUTFITS[name_]
		var m = Mesh_.new()
		Body.build(m, o)
		Hair.build(m, o)
		Clothes.build(m, o)
		Armor.build(m, o)
		if o.get("harl", false):
			Harl.build(m)
		var atlas: int = o.get("atlas", BODY_ATLAS)
		m.pack(atlas)
		bodies[name_] = m
		if o.get("harl", false):
			# two skins: before and after the stone answers
			for phase in [1, 2]:
				var opts := {"dust": true, "scars": true, "marks": phase, "glow": true}
				missing = _paint(m, atlas, "bandit_" + name_ + ("_stone" if phase == 2 else ""), false, o.colors, o.patches, opts) or missing
		else:
			missing = _paint(m, atlas, "bandit_" + name_, false, o.colors, o.patches) or missing
	var gear = null
	if only.is_empty() or "gear" in only:
		gear = Mesh_.new()
		Gear.shield(gear)
		Gear.shield(gear, true)
		Gear.crossbow(gear)
		Gear.axe(gear)
		gear.pack(GEAR_ATLAS)
		missing = _paint(gear, GEAR_ATLAS, "bandit_gear", true, {}, true) or missing
	var pick = null
	if only.is_empty() or "harl" in only:
		pick = Mesh_.new()
		Harl.pick(pick)
		pick.pack(GEAR_ATLAS)
		missing = _paint(pick, GEAR_ATLAS, "bandit_harl_pick", true, {}, true, {"marks": 1, "glow": true}) or missing
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
		var o: Dictionary = Outfits.OUTFITS[name_]
		var boss: bool = o.get("harl", false)
		var mat := _material("bandit_" + name_, 0.96, 0.0, 0.08, 1.0 if boss else 0.0)
		var meshes: Dictionary = bodies[name_].meshes(o.get("atlas", BODY_ATLAS), mat, bones)
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
		root.set_meta("shield_back", -0.292 if o.cloak else -0.255)
		if boss:
			root.set_meta("stone_material", _material("bandit_" + name_ + "_stone", 0.96, 0.0, 0.08, 2.8))
		_save(root, DIR + "BD_%s.scn" % name_)
		print("%-9s %5d triangles  (%s)" % [name_, total, ", ".join(parts)])

	# the held gear
	if gear:
		var gear_mat := _material("bandit_gear", 0.74, 0.14, 0.2)
		var held: Dictionary = gear.meshes(GEAR_ATLAS, gear_mat)
		for group: String in GEAR:
			_save_item(group, GEAR[group], held[group])
	if pick:
		var pick_mat := _material("bandit_harl_pick", 0.74, 0.14, 0.2, 1.0)
		var held: Dictionary = pick.meshes(GEAR_ATLAS, pick_mat)
		var bright := pick_mat.duplicate() as StandardMaterial3D
		bright.emission_energy_multiplier = 2.8
		_save_item("Pick", "BD_harl_pick", held["Pick"], bright)
	print("done in %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	quit()


## A held item's scene: the mesh, with a "Tip" marker where one is needed.
func _save_item(group: String, scene_name: String, mesh: ArrayMesh, stone_material: Material = null) -> void:
	var item := Node3D.new()
	item.name = scene_name
	var mi := MeshInstance3D.new()
	mi.name = group + "Mesh"
	mi.mesh = mesh
	item.add_child(mi)
	mi.owner = item
	if TIPS.has(group):
		var tip := Marker3D.new()
		tip.name = "Tip"
		tip.position = TIPS[group]
		item.add_child(tip)
		tip.owner = item
	if group in BLADE_UP:
		item.set_meta("blade_up_on_hip", true)
	if stone_material:
		item.set_meta("stone_material", stone_material)
	print("%-14s %5d triangles" % [scene_name, mesh.surface_get_array_len(0) / 3])
	_save(item, DIR + scene_name + ".scn")


## Paints and saves one texture (and its light map, if `opts` asks for glow). True if Godot has
## not imported it yet.
func _paint(m, size: int, name_: String, separate: bool, colors: Dictionary, patches: bool, opts := {}) -> bool:
	var images := {"": Paint.bake(m, size, separate, colors, patches, opts)}
	if opts.get("glow", false):
		images["_glow"] = opts["glow_image"]
	var missing := false
	for suffix: String in images:
		var path := DIR + "textures/%s%s.png" % [name_, suffix]
		var err := (images[suffix] as Image).save_png(path)
		if err != OK:
			push_error("could not save %s (%d)" % [path, err])
		missing = missing or not ResourceLoader.exists(path)
	return missing


## Rough, non-glossy, painted: the texture does the shading work. `glow` > 0 = lit from its own
## light map, that strongly.
func _material(name_: String, roughness: float, metallic: float, specular: float, glow := 0.0) -> StandardMaterial3D:
	var path := DIR + "materials/%s.tres" % name_
	var m := StandardMaterial3D.new()
	m.resource_name = name_
	m.albedo_texture = load(DIR + "textures/%s.png" % name_)
	m.roughness = roughness
	m.metallic = metallic
	m.metallic_specular = specular
	m.cull_mode = BaseMaterial3D.CULL_DISABLED   # open hems, cuffs, hood and cloak show their inside
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = Color.BLACK   # (added to the map)
		m.emission_texture = load(DIR + "textures/%s_glow.png" % name_)
		m.emission_energy_multiplier = glow
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
