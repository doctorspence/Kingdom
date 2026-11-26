extends "res://tools/render_equipment_icons.gd"
## Inventory icons for the items that had none (potions, food, jewelry, gloves, boots, older
## weapons and shields...). Each gets a small stand-in 3D model built from the equipment pack's
## materials, rendered with the same camera, light, outline and shadow as the other icons.
## Needs a real window (not --headless):
##   Godot_console.exe --path . --resolution 320x200 --script res://tools/render_extra_icons.gd [-- id1,id2]
## Then import (Godot --headless --import) and run tools/assign_icons.ps1 to point the items at them.
## When an item gets a real model later, render its icon from that instead.

const Mesh2 := preload("res://assets/equipment/eq_mesh.gd")
const Kit := preload("res://assets/equipment/eq_kit.gd")

## [id, folder, kind ("weapon", "face", "object", "flat", "armor"), builder]
const LIST := [
	["item_rusty_sword", "Weapons", "weapon", "rusty_sword"],
	["item_woodcutters_axe", "Weapons", "weapon", "axe"],
	["item_boar_spear", "Weapons", "weapon", "spear"],
	["item_executioners_greatsword", "Weapons", "weapon", "executioner"],
	["item_flanged_mace", "Weapons", "weapon", "flanged_mace"],
	["item_harls_pick", "Weapons", "weapon", "harls_pick"],
	["item_steel_pickaxe", "Weapons", "weapon", "pickaxe"],
	["item_hunting_bow", "Weapons", "weapon", "hunting_bow"],
	["item_lantern_staff", "Weapons", "weapon", "lantern_staff"],
	["item_iron_buckler", "Weapons", "face", "buckler"],
	["item_kite_shield", "Weapons", "face", "kite"],
	["item_round_shield", "Weapons", "face", "round_shield"],
	["item_health_potion", "Items", "object", "potion_red"],
	["item_antidote", "Items", "object", "vial_green"],
	["item_warming_draught", "Items", "object", "bottle_orange"],
	["item_bandage", "Items", "object", "bandage"],
	["item_bread", "Items", "object", "bread"],
	["item_cooked_meat", "Items", "object", "meat"],
	["item_copper_ring", "Items", "flat", "ring_copper"],
	["item_iron_ring", "Items", "flat", "ring_iron"],
	["item_bone_amulet", "Items", "flat", "amulet_bone"],
	["item_blackstone_amulet", "Items", "flat", "amulet_black"],
	["item_hobbs_noose", "Items", "flat", "noose"],
	["item_kettle_helm", "Armor", "object", "kettle_helm"],
	["item_tallow_crown", "Armor", "object", "tallow_crown"],
	["item_leather_pauldrons", "Armor", "object", "pauldrons"],
	["item_mail_mantle", "Armor", "object", "mantle"],
	["item_leather_gloves", "Armor", "object", "gloves_leather"],
	["item_mail_gauntlets", "Armor", "object", "gloves_mail"],
	["item_leather_boots", "Armor", "object", "boots_leather"],
	["item_ironshod_boots", "Armor", "object", "boots_iron"],
	["item_tattered_cloak", "Armor", "object", "cloak"],
	["item_padded_cowl", "Armor", "armor", "leather_hood:cowl"],
	["item_gambeson", "Armor", "armor", "leather_body:gambeson"],
	["item_padded_robe", "Armor", "armor", "wizard_robe_top:robe"],
	["item_rusty_hauberk", "Armor", "armor", "chainmail_body:rust"],
	["item_mail_chausses", "Armor", "armor", "chainmail_legs:dark"],
]


func _display_basis(e: Dictionary) -> Basis:
	match e.kind:
		"face":
			return Basis(Vector3.RIGHT, deg_to_rad(-8)) * Basis(Vector3.UP, deg_to_rad(-22))
		"object":
			return Basis(Vector3.RIGHT, deg_to_rad(14)) * Basis(Vector3.UP, deg_to_rad(28))
		"flat":
			return Basis(Vector3.RIGHT, deg_to_rad(62)) * Basis(Vector3.FORWARD, deg_to_rad(-20))
	return super(e)


func _run() -> void:
	_setup()
	var args := OS.get_cmdline_user_args()
	var only := PackedStringArray()
	if args.size() > 0 and args[0] != "all":
		only = args[0].split(",")
	var done := 0
	for row in LIST:
		var e := {"id": row[0], "folder": row[1], "kind": row[2], "build": row[3]}
		if not only.is_empty() and not (String(e.id) in only):
			continue
		var node: Node3D
		if e.kind == "armor":
			var parts: PackedStringArray = String(e.build).split(":")
			var built := A.build(parts[0])
			_recolor(built, parts[1])
			node = A.preview(e, _pack(built))
			built.free()
			_pivot.add_child(node)
			await process_frame
			A.pose_preview(node)
		else:
			node = _make(e.build)
			_pivot.add_child(node)
		var fit_kind := "armor" if e.kind == "armor" else ""
		_fit(node, _display_basis(e), fit_kind)
		for i in 8:
			await RenderingServer.frame_post_draw
		var img := _vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		DirAccess.make_dir_recursive_absolute(BASE + e.folder)
		DirAccess.make_dir_recursive_absolute(BASE + "Source512")
		var fin := _polish(img)
		fin.save_png("%sSource512/%s.png" % [BASE, e.id])
		var small := fin.duplicate() as Image
		small.resize(256, 256, Image.INTERPOLATE_LANCZOS)
		small.save_png("%s%s/%s.png" % [BASE, e.folder, e.id])
		_pivot.remove_child(node)
		node.free()
		done += 1
		print("icon ", e.id)
	print("icons: ", done)
	quit()


func _pack(n: Node3D) -> PackedScene:
	for c in n.find_children("*", "", true, false):
		c.owner = n
	var ps := PackedScene.new()
	ps.pack(n)
	return ps


## Swap the pack's materials on a built armor piece for this item's look.
func _recolor(n: Node3D, look: String) -> void:
	var swaps := {}
	match look:
		"cowl":
			swaps = {"leather": _tint("cloth_coarse", Color(0.62, 0.55, 0.42)), "leather_dark": _tint("cloth_coarse", Color(0.45, 0.4, 0.32))}
		"gambeson":
			swaps = {"leather": _tint("cloth_coarse", Color(0.66, 0.58, 0.44)), "leather_dark": _tint("cloth_coarse", Color(0.5, 0.43, 0.32)),
					"cloth_coarse": _tint("cloth_coarse", Color(0.58, 0.5, 0.38))}
		"robe":
			swaps = {"cloth_blue": _tint("cloth_coarse", Color(0.56, 0.5, 0.42)), "cloth_trim": _tint("leather", Color(0.5, 0.38, 0.26))}
		"rust":
			swaps = {"chainmail": _tint("chainmail", Color(0.62, 0.4, 0.26), 0.35), "leather": _tint("leather", Color(0.45, 0.36, 0.28))}
		"dark":
			swaps = {"chainmail": _tint("chainmail", Color(0.55, 0.56, 0.6))}
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := (mi as MeshInstance3D).mesh.duplicate() as ArrayMesh
		for s in m.get_surface_count():
			var mat := m.surface_get_material(s)
			for k in swaps:
				if mat == Kit.get_mat(k):
					m.surface_set_material(s, swaps[k])
		(mi as MeshInstance3D).mesh = m


func _tint(base: String, c: Color, metallic := -1.0) -> StandardMaterial3D:
	var m: StandardMaterial3D = Kit.get_mat(base).duplicate()
	m.albedo_color = c
	if metallic >= 0.0:
		m.metallic = metallic
	return m


func _plain(c: Color, metallic := 0.0, rough := 0.6, glow := Color.BLACK, glow_energy := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metallic
	m.roughness = rough
	m.metallic_specular = 0.6
	if glow_energy > 0.0:
		m.emission_enabled = true
		m.emission = glow
		m.emission_energy_multiplier = glow_energy
	return m


func _glass(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.05
	m.metallic_specular = 1.0
	m.rim_enabled = true
	m.rim = 0.6
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _node(name: String, m) -> Node3D:
	var root := Node3D.new()
	root.name = name
	var mi := MeshInstance3D.new()
	mi.mesh = m.finish()
	root.add_child(mi)
	return root


## A ring (torus) lying in the XZ plane.
func _torus(m, mat, c: Vector3, big: float, small: float, seg := 24, squash := 1.0, b := Basis.IDENTITY) -> void:
	var prof := []
	for i in 13:
		var a := -PI * 0.5 + TAU * i / 12.0
		prof.append([big + cos(a) * small, sin(a) * small * squash])
	m.lathe(mat, Transform3D(b, c), prof, seg, true, false)


func _make(build: String) -> Node3D:
	var m := Mesh2.new()
	var iron = Kit.get_mat("iron")
	var steel = Kit.get_mat("steel")
	var wood = Kit.get_mat("wood")
	var wood_dark = Kit.get_mat("wood_dark")
	var leather = Kit.get_mat("leather")
	var leather_dark = Kit.get_mat("leather_dark")
	match build:
		"rusty_sword":
			var n := W.sword_like("sword", "iron")
			_swap(n, {Kit.get_mat("iron"): _tint("iron", Color(0.7, 0.45, 0.3), 0.3)})
			return n
		"executioner":
			var n2 := W.sword_like("sword2h", "steel")
			_swap(n2, {Kit.get_mat("steel"): Kit.get_mat("dark_steel")})
			return n2
		"hunting_bow":
			var n3 := W.bow("bronze")
			_swap(n3, {Kit.get_mat("bronze"): Kit.get_mat("leather_dark"), Kit.get_mat("wood"): Kit.get_mat("wood_dark")})
			return n3
		"axe":
			m.lathe(wood, Transform3D.IDENTITY, [[0.02, -0.3], [0.024, -0.28], [0.021, 0.2], [0.023, 0.42], [0.022, 0.46]], 8, true, true)
			W._grip(m, -0.26, -0.06, 0.024, leather, iron, 4)
			# the head: thick at the eye, thin at the bit, the bit flared up and down
			var hy := 0.38
			m.box(iron, Vector3(0, hy, 0), Vector3(0.06, 0.07, 0.05))
			var bit := [Vector3(0.03, hy - 0.035, 0.022), Vector3(0.03, hy + 0.035, 0.022), Vector3(0.03, hy + 0.035, -0.022), Vector3(0.03, hy - 0.035, -0.022)]
			var edge := [Vector3(0.17, hy - 0.08, 0.003), Vector3(0.17, hy + 0.07, 0.003), Vector3(0.17, hy + 0.07, -0.003), Vector3(0.17, hy - 0.08, -0.003)]
			m.loft(iron, [PackedVector3Array(bit), PackedVector3Array(edge)], false, true, true)
			m.box(iron, Vector3(-0.045, hy, 0), Vector3(0.04, 0.05, 0.045))
			return _node("axe", m)
		"spear":
			m.lathe(wood, Transform3D.IDENTITY, [[0.02, -0.9], [0.023, -0.88], [0.021, 0.5], [0.022, 0.8], [0.02, 0.84]], 8, true, true)
			m.lathe(iron, Transform3D(Basis.IDENTITY, Vector3(0, -0.92, 0)), [[0.008, 0.0], [0.022, 0.06], [0.022, 0.08]], 8, true, true)
			W._grip(m, -0.2, 0.1, 0.023, leather, iron, 4)
			m.lathe(iron, Transform3D(Basis.IDENTITY, Vector3(0, 0.82, 0)), [[0.022, 0.0], [0.026, 0.04], [0.016, 0.1]], 8, true, true)
			W._blade(m, iron, 0.92, 0.3, 0.02, 0.05, 0.35, 0.012, 0.35)
			# the boar-spear wings below the blade
			m.box(iron, Vector3(0, 0.9, 0), Vector3(0.16, 0.022, 0.022))
			return _node("spear", m)
		"flanged_mace":
			m.lathe(wood_dark, Transform3D.IDENTITY, [[0.02, -0.14], [0.025, -0.13], [0.022, 0.0], [0.021, 0.3], [0.023, 0.48]], 8, true, true)
			W._grip(m, -0.1, 0.12, 0.024, leather, iron, 5)
			m.lathe(iron, Transform3D(Basis.IDENTITY, Vector3(0, 0.46, 0)), [[0.026, 0.0], [0.03, 0.16], [0.018, 0.2]], 8, true, true)
			for i in 6:
				var a := TAU * i / 6.0
				m.frustum(iron, Vector3(0, 0.57, 0), Vector2(0.14, 0.014), Vector2(0.09, 0.01), 0.17, Basis(Vector3.UP, a) * Basis(Vector3.FORWARD, 0.0))
			m.sphere(iron, Vector3(0, 0.67, 0), 0.025, 8, 5)
			return _node("flanged_mace", m)
		"pickaxe":
			m.lathe(wood, Transform3D.IDENTITY, [[0.022, -0.32], [0.026, -0.3], [0.023, 0.3], [0.025, 0.5]], 8, true, true)
			W._grip(m, -0.28, -0.05, 0.025, leather, iron, 4)
			var y := 0.47
			m.box(steel, Vector3(0, y, 0), Vector3(0.06, 0.07, 0.06))
			for s in [-1.0, 1.0]:
				var pts := [Vector3(0, y, 0), Vector3(s * 0.12, y + 0.01, 0), Vector3(s * 0.22, y - 0.02, 0), Vector3(s * 0.3, y - 0.07, 0)]
				for k in 3:
					m.rod(steel, pts[k], pts[k + 1], 0.03 - k * 0.008, 0.022 - k * 0.008 if k < 2 else 0.002, 6)
			return _node("pick", m)
		"harls_pick":
			# a real model: the pick as the player carries it
			return (load("res://assets/characters/bandit/harls_black_pick.tscn") as PackedScene).instantiate()
		"lantern_staff":
			var n4 := W.staff()
			var lm := Mesh2.new()
			var glow := _plain(Color(1.0, 0.8, 0.45), 0.0, 0.4, Color(1.0, 0.6, 0.2), 3.0)
			var top := Vector3(0.0, 1.3, 0.0)
			lm.rod(iron, top, top + Vector3(0.12, 0.05, 0), 0.01, 0.01, 6)
			var c := top + Vector3(0.12, -0.08, 0)
			lm.rod(iron, c + Vector3(0, 0.13, 0), c + Vector3(0, 0.07, 0), 0.004, 0.004, 4)
			lm.lathe(iron, Transform3D(Basis.IDENTITY, c), [[0.04, -0.07], [0.05, -0.06], [0.05, -0.055], [0.0, -0.05]], 6, false, true)
			lm.lathe(iron, Transform3D(Basis.IDENTITY, c), [[0.05, 0.04], [0.04, 0.06], [0.01, 0.075]], 6, false, true)
			for i in 6:
				var a := TAU * i / 6.0
				lm.rod(iron, c + Vector3(cos(a) * 0.046, -0.055, sin(a) * 0.046), c + Vector3(cos(a) * 0.046, 0.042, sin(a) * 0.046), 0.005, 0.005, 4)
			lm.sphere(glow, c, 0.032, 8, 5)
			var lmi := MeshInstance3D.new()
			lmi.mesh = lm.finish()
			# bigger than life, so it reads at inventory size (scaled about the staff's top)
			lmi.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 1.7), top - top * 1.7)
			n4.add_child(lmi)
			return n4
		"buckler":
			m.lathe(iron, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), [[0.19, -0.01], [0.195, 0.0], [0.18, 0.02], [0.12, 0.045], [0.0, 0.06]], 24, true, true)
			m.lathe(steel, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.05)), [[0.06, 0.0], [0.05, 0.02], [0.0, 0.035]], 12, true, false)
			_torus(m, iron, Vector3.ZERO, 0.19, 0.012, 24, 1.0, Basis(Vector3.RIGHT, PI * 0.5))
			return _node("buckler", m)
		"round_shield":
			var face := Basis(Vector3.RIGHT, PI * 0.5)
			m.lathe(wood, Transform3D(face, Vector3.ZERO), [[0.33, -0.012], [0.33, 0.012], [0.0, 0.03]], 28, true, true)
			for x in [-0.165, 0.0, 0.165]:
				m.box(wood_dark, Vector3(x, 0, 0.026), Vector3(0.006, 0.6, 0.006))
			_torus(m, iron, Vector3.ZERO, 0.33, 0.016, 32, 1.0, Basis(Vector3.RIGHT, PI * 0.5))
			m.lathe(iron, Transform3D(face, Vector3(0, 0, 0.025)), [[0.08, 0.0], [0.07, 0.02], [0.03, 0.05], [0.0, 0.055]], 14, true, false)
			for a in 8:
				var ang := TAU * a / 8.0
				m.sphere(iron, Vector3(cos(ang) * 0.28, sin(ang) * 0.28, 0.025), 0.012, 6, 3)
			return _node("round_shield", m)
		"kite":
			var outline := PackedVector2Array([Vector2(0, 0.34), Vector2(0.14, 0.33), Vector2(0.23, 0.27), Vector2(0.24, 0.15), Vector2(0.2, -0.05),
					Vector2(0.12, -0.28), Vector2(0, -0.5), Vector2(-0.12, -0.28), Vector2(-0.2, -0.05), Vector2(-0.24, 0.15), Vector2(-0.23, 0.27), Vector2(-0.14, 0.33)])
			var cen := Vector2(0, 0.02)
			var paint := _tint("cloth_red", Color(0.42, 0.12, 0.1))
			var rings := []
			for lv in [[1.0, -0.03], [1.0, 0.0], [0.8, 0.02], [0.35, 0.035]]:
				var r := PackedVector3Array()
				for p in outline:
					var q: Vector2 = cen + (p - cen) * lv[0]
					r.append(Vector3(q.x, q.y, lv[1]))
				rings.append(r)
			m.loft(wood, rings.slice(0, 2), false, true, false)
			m.loft(paint, rings.slice(1), false, false, true)
			for i in outline.size():
				var a2: Vector2 = outline[i]
				var b2: Vector2 = outline[(i + 1) % outline.size()]
				m.rod(iron, Vector3(a2.x, a2.y, 0.004), Vector3(b2.x, b2.y, 0.004), 0.013, 0.013, 6)
			# a pale band across the top
			var band := _tint("cloth_coarse", Color(0.8, 0.74, 0.6))
			m.box(band, Vector3(0, 0.2, 0.026), Vector3(0.44, 0.07, 0.01))
			m.lathe(iron, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.02, 0.03)), [[0.05, 0.0], [0.04, 0.015], [0.0, 0.03]], 12, true, false)
			return _node("kite", m)
		"potion_red", "vial_green", "bottle_orange":
			var col: Color = {"potion_red": Color(0.55, 0.02, 0.03), "vial_green": Color(0.25, 0.7, 0.2), "bottle_orange": Color(0.95, 0.45, 0.08)}[build]
			var liquid := _plain(col, 0.0, 0.2, col, 0.6)
			var glass := _glass(Color(0.75, 0.85, 0.9, 0.28))
			var cork := _tint("wood", Color(0.75, 0.55, 0.35))
			var prof: Array
			var fill: Array
			var seg := 16
			match build:
				"potion_red":
					prof = [[0.0, 0.0], [0.05, 0.004], [0.075, 0.04], [0.078, 0.07], [0.06, 0.11], [0.022, 0.135], [0.02, 0.17], [0.026, 0.18]]
					fill = [[0.0, 0.006], [0.046, 0.01], [0.07, 0.04], [0.072, 0.07], [0.055, 0.1], [0.0, 0.1]]
				"vial_green":
					prof = [[0.0, 0.0], [0.026, 0.003], [0.03, 0.02], [0.03, 0.15], [0.02, 0.165], [0.018, 0.19], [0.024, 0.2]]
					fill = [[0.0, 0.004], [0.026, 0.006], [0.027, 0.02], [0.027, 0.12], [0.0, 0.12]]
				_:
					seg = 4
					prof = [[0.0, 0.0], [0.07, 0.004], [0.075, 0.02], [0.075, 0.11], [0.06, 0.13], [0.024, 0.15], [0.022, 0.18], [0.028, 0.19]]
					fill = [[0.0, 0.006], [0.066, 0.008], [0.068, 0.02], [0.068, 0.1], [0.0, 0.1]]
			m.lathe(liquid, Transform3D(Basis(Vector3.UP, PI * 0.25 if seg == 4 else 0.0), Vector3.ZERO), fill, seg, seg != 4, true)
			m.lathe(glass, Transform3D(Basis(Vector3.UP, PI * 0.25 if seg == 4 else 0.0), Vector3.ZERO), prof, seg, seg != 4, false)
			var top_y: float = prof[prof.size() - 1][1]
			m.lathe(cork, Transform3D(Basis.IDENTITY, Vector3(0, top_y - 0.02, 0)), [[0.017, 0.0], [0.02, 0.03], [0.018, 0.05]], 10, true, true)
			if build == "potion_red":
				m.lathe(_tint("cloth_coarse", Color(0.8, 0.72, 0.55)), Transform3D(Basis.IDENTITY, Vector3(0, 0.135, 0)), [[0.025, 0.0], [0.028, 0.01], [0.025, 0.02]], 10, true, true)
			return _node(build, m)
		"bandage":
			var cloth := _tint("cloth_coarse", Color(0.88, 0.84, 0.74))
			var side := Basis(Vector3.FORWARD, PI * 0.5)
			m.lathe(cloth, Transform3D(side, Vector3.ZERO), [[0.012, -0.05], [0.05, -0.05], [0.053, -0.045], [0.055, 0.0], [0.053, 0.045], [0.05, 0.05], [0.012, 0.05]], 18, true, true)
			for i in 3:
				var x := -0.03 + i * 0.03
				m.lathe(_tint("cloth_coarse", Color(0.8, 0.75, 0.64)), Transform3D(side, Vector3(x, 0, 0)), [[0.054, -0.002], [0.056, 0.0], [0.054, 0.002]], 18, true, false)
			return _node("bandage", m)
		"bread":
			var crust := _tint("leather", Color(0.78, 0.5, 0.24))
			var crumb := _tint("cloth_coarse", Color(0.92, 0.8, 0.58))
			m.lathe(crust, Transform3D(Basis.IDENTITY.scaled(Vector3(1.6, 1.0, 1.0)), Vector3.ZERO), [[0.0, 0.0], [0.07, 0.004], [0.085, 0.025], [0.08, 0.05], [0.055, 0.075], [0.0, 0.085]], 18, true, false)
			for i in 3:
				m.box(crumb, Vector3(-0.06 + i * 0.06, 0.078, 0), Vector3(0.012, 0.01, 0.07), Basis(Vector3.UP, 0.5))
			return _node("bread", m)
		"meat":
			var meat := _tint("leather", Color(0.55, 0.24, 0.12))
			var bone := _plain(Color(0.9, 0.86, 0.75), 0.0, 0.5)
			var tilt := Basis(Vector3.FORWARD, -0.9)
			m.lathe(meat, Transform3D(tilt, Vector3.ZERO), [[0.0, -0.08], [0.045, -0.07], [0.065, -0.03], [0.06, 0.02], [0.035, 0.06], [0.02, 0.075]], 14, true, true)
			m.rod(bone, tilt * Vector3(0, 0.07, 0), tilt * Vector3(0, 0.17, 0), 0.014, 0.014, 8)
			m.sphere(bone, tilt * Vector3(-0.012, 0.175, 0), 0.02, 8, 5)
			m.sphere(bone, tilt * Vector3(0.012, 0.175, 0), 0.02, 8, 5)
			return _node("meat", m)
		"ring_copper", "ring_iron":
			var metal = _tint("bronze", Color(1.0, 0.62, 0.42), 0.9) if build == "ring_copper" else iron
			_torus(m, metal, Vector3.ZERO, 0.03, 0.007, 28, 1.6)
			if build == "ring_iron":
				m.lathe(steel, Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(0.036, 0, 0)), [[0.014, -0.004], [0.016, 0.0], [0.014, 0.006]], 6, false, true)
			return _node(build, m)
		"amulet_bone", "amulet_black":
			var cord := _tint("leather_dark", Color(0.42, 0.3, 0.2))
			_torus(m, cord, Vector3(0, 0, -0.05), 0.052, 0.0045, 28)
			if build == "amulet_bone":
				var bone2 := _plain(Color(0.9, 0.85, 0.72), 0.0, 0.55)
				m.rod(bone2, Vector3(0, 0, 0.008), Vector3(0, 0, 0.09), 0.019, 0.003, 10)
				m.sphere(cord, Vector3(0, 0, 0.004), 0.013, 8, 4)
			else:
				var stone := _plain(Color(0.05, 0.05, 0.06), 0.1, 0.18, Color(0.35, 0.3, 0.5), 0.15)
				m.lathe(stone, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.04)), [[0.0, -0.018], [0.036, -0.005], [0.03, 0.013], [0.0, 0.021]], 5, false, true)
				m.rod(_tint("iron", Color(0.6, 0.6, 0.62)), Vector3(0, 0, 0.0), Vector3(0, 0, 0.008), 0.007, 0.007, 6)
			return _node(build, m)
		"noose":
			var rope := _tint("cloth_coarse", Color(0.62, 0.5, 0.33))
			_torus(m, rope, Vector3(0, 0, 0.03), 0.055, 0.011, 28)
			for i in 6:
				m.lathe(rope, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.032 - i * 0.012)), [[0.013, -0.006], [0.017, 0.0], [0.013, 0.006]], 12, true, false)
			m.rod(rope, Vector3(0, 0, -0.1), Vector3(0.01, 0, -0.15), 0.01, 0.008, 8)
			return _node("noose", m)
		"kettle_helm":
			m.lathe(iron, Transform3D.IDENTITY, [[0.12, 0.0], [0.125, 0.04], [0.118, 0.1], [0.09, 0.16], [0.04, 0.195], [0.0, 0.2]], 22, true, false)
			m.lathe(iron, Transform3D.IDENTITY, [[0.118, 0.012], [0.2, -0.02], [0.215, -0.03], [0.2, -0.025], [0.118, 0.0]], 26, true, false)
			_torus(m, steel, Vector3(0, 0.012, 0), 0.12, 0.008, 24)
			m.box(iron, Vector3(0, 0.16, 0), Vector3(0.012, 0.09, 0.24), Basis(Vector3.RIGHT, 0.0))
			return _node("kettle_helm", m)
		"tallow_crown":
			var wax := _plain(Color(0.92, 0.86, 0.68), 0.0, 0.55)
			var flame := _plain(Color(1.0, 0.75, 0.35), 0.0, 0.5, Color(1.0, 0.55, 0.15), 4.0)
			m.lathe(_tint("bronze", Color(0.7, 0.58, 0.4), 0.7), Transform3D.IDENTITY, [[0.11, 0.0], [0.115, 0.01], [0.115, 0.04], [0.11, 0.05]], 24, true, false)
			for i in 7:
				var a := TAU * i / 7.0
				var p := Vector3(cos(a) * 0.112, 0.04, sin(a) * 0.112)
				var h := 0.05 + 0.03 * ((i * 3) % 4) / 3.0
				m.rod(wax, p, p + Vector3(0, h, 0), 0.014, 0.012, 8)
				m.sphere(wax, p + Vector3(0, 0.005, 0) + Vector3(cos(a), 0, sin(a)) * 0.012, 0.008, 6, 3)
				m.cone(flame, p + Vector3(0, h + 0.004, 0), p + Vector3(0, h + 0.035, 0), 0.008, 6)
			return _node("tallow_crown", m)
		"pauldrons":
			for s in [-1.0, 1.0]:
				var c2 := Vector3(s * 0.15, 0, 0)
				var b := Basis(Vector3.FORWARD, s * 0.35)
				m.lathe(leather, Transform3D(b, c2), [[0.1, -0.05], [0.105, -0.02], [0.095, 0.02], [0.065, 0.06], [0.0, 0.075]], 16, true, false)
				m.lathe(leather_dark, Transform3D(b, c2 + b * Vector3(0, -0.06, 0)), [[0.11, 0.0], [0.115, 0.02], [0.1, 0.03]], 16, true, false)
				m.box(leather_dark, c2 + b * Vector3(0, 0.0, 0.0), Vector3(0.02, 0.17, 0.215), b)
				m.sphere(iron, c2 + b * Vector3(0, 0.07, 0.0), 0.012, 6, 3)
			m.box(leather_dark, Vector3(0, 0.03, 0), Vector3(0.16, 0.02, 0.05))
			return _node("pauldrons", m)
		"mantle":
			var mail := Kit.get_mat("chainmail")
			m.lathe(mail, Transform3D.IDENTITY, [[0.27, -0.12], [0.25, -0.06], [0.2, 0.0], [0.13, 0.05], [0.09, 0.07]], 28, true, false)
			m.lathe(leather_dark, Transform3D.IDENTITY, [[0.09, 0.07], [0.085, 0.11], [0.09, 0.115]], 20, true, false)
			_torus(m, leather_dark, Vector3(0, -0.12, 0), 0.27, 0.008, 28)
			return _node("mantle", m)
		"gloves_leather", "gloves_mail":
			var mat = leather if build == "gloves_leather" else Kit.get_mat("chainmail")
			var cuff = leather_dark if build == "gloves_leather" else steel
			for s in [-1.0, 1.0]:
				var o := Vector3(s * 0.075, 0, 0)
				var tb := Basis(Vector3.FORWARD, s * 0.12)
				m.frustum(mat, o + tb * Vector3(0, 0.03, 0), Vector2(0.075, 0.03), Vector2(0.08, 0.026), 0.09, tb)
				for f in 4:
					var fx := -0.028 + f * 0.0187
					var base := o + tb * Vector3(fx, 0.075, 0)
					var ln := 0.07 if f in [1, 2] else 0.058
					m.rod(mat, base, base + tb * Vector3(fx * 0.15, ln, 0), 0.0095, 0.0085, 6)
					m.sphere(mat, base + tb * Vector3(fx * 0.15, ln, 0), 0.0085, 6, 3)
				m.rod(mat, o + tb * Vector3(-s * 0.035, 0.02, 0), o + tb * Vector3(-s * 0.07, 0.07, 0), 0.011, 0.009, 6)
				m.lathe(cuff, Transform3D(tb, o + tb * Vector3(0, -0.06, 0)), [[0.05, 0.0], [0.055, 0.02], [0.05, 0.05], [0.046, 0.055]], 12, true, false)
				if build == "gloves_mail":
					m.box(steel, o + tb * Vector3(0, 0.05, 0.016), Vector3(0.07, 0.045, 0.01), tb)
			return _node(build, m)
		"boots_leather", "boots_iron":
			var top_mat = leather if build == "boots_leather" else leather_dark
			for s in [-1.0, 1.0]:
				var o2 := Vector3(s * 0.07, 0, s * 0.03)
				m.lathe(top_mat, Transform3D(Basis.IDENTITY, o2), [[0.045, 0.05], [0.048, 0.12], [0.05, 0.2], [0.056, 0.23]], 12, true, false)
				m.frustum(top_mat, o2 + Vector3(0, 0.035, 0.04), Vector2(0.085, 0.16), Vector2(0.08, 0.13), 0.07)
				m.lathe(top_mat, Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 0.75, 1.25)), o2 + Vector3(0, 0.004, 0.1)), [[0.042, 0.0], [0.042, 0.02], [0.03, 0.05], [0.0, 0.06]], 12, true, false)
				m.box(leather_dark, o2 + Vector3(0, 0.004, 0.04), Vector3(0.09, 0.012, 0.21))
				if build == "boots_iron":
					m.lathe(iron, Transform3D(Basis.IDENTITY.scaled(Vector3(1.05, 0.78, 1.3)), o2 + Vector3(0, 0.004, 0.102)), [[0.043, 0.0], [0.043, 0.02], [0.031, 0.05], [0.0, 0.061]], 12, true, false)
					m.lathe(iron, Transform3D(Basis.IDENTITY, o2), [[0.052, 0.1], [0.055, 0.2], [0.06, 0.215]], 12, true, false)
				else:
					m.lathe(leather_dark, Transform3D(Basis.IDENTITY, o2), [[0.058, 0.215], [0.062, 0.235], [0.058, 0.24]], 12, true, false)
			return _node(build, m)
		"cloak":
			var cl := _tint("cloth_grey", Color(0.3, 0.27, 0.24))
			var rows := 9
			var cols := 14
			var grid := []
			for r in rows + 1:
				var row := []
				var t := float(r) / rows
				for c3 in cols + 1:
					var u := float(c3) / cols
					var width := lerpf(0.16, 0.34, t)
					var x := (u - 0.5) * 2.0 * width
					var z := -cos((u - 0.5) * PI) * 0.06 + sin(u * TAU * 2.0 + t * 2.0) * 0.012 * t
					var y := 0.3 - t * 0.6
					if r == rows:
						y += sin(u * 41.0) * 0.035 + ((c3 * 7) % 3) * 0.02  # ragged hem
					row.append(Vector3(x, y, z))
				grid.append(row)
			for r in rows:
				for c3 in cols:
					m.quad(cl, grid[r][c3], grid[r][c3 + 1], grid[r + 1][c3 + 1], grid[r + 1][c3], Vector3(0, 0, -0.5))
			_torus(m, leather_dark, Vector3(0, 0.3, -0.03), 0.12, 0.01, 20, 1.0)
			m.sphere(_tint("bronze", Color(0.8, 0.65, 0.4), 0.8), Vector3(0, 0.3, 0.09), 0.02, 8, 4)
			var cmat: StandardMaterial3D = cl
			cmat.cull_mode = BaseMaterial3D.CULL_DISABLED
			return _node("cloak", m)
	push_error("no icon builder for " + build)
	return Node3D.new()


func _swap(n: Node3D, swaps: Dictionary) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := (mi as MeshInstance3D).mesh.duplicate() as ArrayMesh
		for s in m.get_surface_count():
			var mat := m.surface_get_material(s)
			if swaps.has(mat):
				m.surface_set_material(s, swaps[mat])
		(mi as MeshInstance3D).mesh = m
