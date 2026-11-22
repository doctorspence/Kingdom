extends Node3D
## Development scene: every equipment item's inventory icon next to its real 3D model, plus
## mannequins wearing the sets. Keys: 1 = weapons, 2 = armor, 3 = characters, 4 = close-up of
## the first wearer. Run: Godot --path . res://levels/sandbox/equipment_gallery.tscn
## Command line (after --): view=weapons|armor|chars|close

const Catalog := preload("res://assets/equipment/eq_catalog.gd")
const Builder := preload("res://tools/build_equipment.gd")
const MODEL_SCRIPT := preload("res://game/characters/character_model.gd")
const MANNEQUIN := preload("res://assets/characters/mannequin/UAL1_Standard.glb")

var _cam: Camera3D
var _views := {}


func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = load("res://levels/common/overcast_env.tres")
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -28, 0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	add_child(sun)
	var floor_ := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(120, 60)
	floor_.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.13, 0.12, 0.11)
	fm.roughness = 0.95
	pm.material = fm
	floor_.position = Vector3(0, -0.01, -10)
	add_child(floor_)
	_cam = Camera3D.new()
	_cam.fov = 38
	add_child(_cam)
	_build_weapons()
	_build_armor()
	_build_wearers()
	var view := "weapons"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("view="):
			view = a.get_slice("=", 1)
	_show(view)


func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed:
		match ev.keycode:
			KEY_1: _show("weapons")
			KEY_2: _show("armor")
			KEY_3: _show("chars")
			KEY_4: _show("close")


func _show(view: String) -> void:
	var v: Array = _views.get(view, _views["weapons"])
	_cam.position = v[0]
	_cam.look_at(v[1])


## One cell: the icon on the left, the model standing beside it, a name underneath.
func _cell(e: Dictionary, at: Vector3) -> void:
	var path := Builder.scene_path(e)
	if not ResourceLoader.exists(path):
		return
	var icon := Sprite3D.new()
	var ipath := Builder.icon_path(e)
	if ResourceLoader.exists(ipath):
		icon.texture = load(ipath)
	icon.pixel_size = 0.0018 if e.kind != "armor" else 0.0016
	icon.position = at + Vector3(-0.55, 1.0, 0)
	icon.shaded = false
	icon.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(icon)
	var small := Sprite3D.new()   # the same icon at inventory size, to judge readability
	small.texture = icon.texture
	small.pixel_size = 0.0018 * 256.0 / 56.0 * 0.5
	small.position = at + Vector3(-0.55, 0.28, 0)
	small.shaded = false
	small.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(small)
	var node: Node3D = (load(path) as PackedScene).instantiate()
	node.position = at + Vector3(0.45, 0.9, 0)
	if e.kind == "shield":
		node.basis = Catalog.W.SHIELD_BASIS.inverse()
	elif e.kind == "armor":
		node.position = at + Vector3(0.5, 0.0, 0)
	add_child(node)
	var lab := Label3D.new()
	lab.text = e.name
	lab.font_size = 36
	lab.pixel_size = 0.0035
	lab.position = at + Vector3(0, -0.12, 0)
	lab.modulate = Color(0.9, 0.85, 0.75)
	add_child(lab)


func _build_weapons() -> void:
	var cols := ["Daggers", "Swords", "TwoHandedSwords", "Maces", "Shields", "Bows"]
	var tiers := ["bronze", "iron", "steel"]
	var by := {}
	for e in Catalog.entries():
		by["%s/%s" % [e.cat, e.tier]] = e
	for ci in cols.size():
		for ti in tiers.size():
			var e = by.get("%s/%s" % [cols[ci], tiers[ti]])
			if e:
				_cell(e, Vector3(-9.0 + ci * 3.5, 2.2 - ti * 2.4 + 0.0, 0))
	for e in Catalog.entries():
		if e.cat == "Staves":
			_cell(e, Vector3(-3.0 + (0 if e.id == "item_wooden_staff" else 3.5), -4.6, 0))
	_views["weapons"] = [Vector3(1.0, -0.3, 17.0), Vector3(1.0, -0.4, 0)]


func _build_armor() -> void:
	var x := -9.0
	var row := 0
	for e in Catalog.armor_entries():
		_cell(e, Vector3(-11.0 + (row % 6) * 4.2, -5.0 - (row / 6) * 2.4, -12.0))
		row += 1
	_views["armor"] = [Vector3(1.0, -4.5, 6.0), Vector3(1.0, -4.5, -12.0)]


func _wearer(ids: Array, at: Vector3, yaw := 0.0) -> Node3D:
	var vis := Node3D.new()
	vis.set_script(MODEL_SCRIPT)
	vis.add_child(MANNEQUIN.instantiate())
	vis.position = at
	vis.rotation_degrees.y = yaw
	vis.set("idle_anim", &"Sword_Idle")
	add_child(vis)
	vis.set_tint(Color(0.42, 0.4, 0.37))
	var main: ItemData
	var off: ItemData
	for id in ids:
		var it := _item(id)
		if it == null:
			continue
		if it.weapon:
			main = it
		elif it.shield:
			off = it
		elif it.model_scene and vis.has_method("set_armor"):
			vis.call("set_armor", _slot_key(it.slot), it.model_scene)
	if main and main.weapon.visual_scene:
		vis.attach_to_hand(main.weapon.visual_scene.instantiate(), "r")
	if off and off.shield.visual_scene:
		vis.attach_to_hand(off.shield.visual_scene.instantiate(), "l")
	return vis


func _item(id: String) -> ItemData:
	var p := ""
	for sub in ["weapons", "armor"]:
		var cand := "res://data/items/%s/%s.tres" % [sub, id]
		if ResourceLoader.exists(cand):
			p = cand
	return load(p) as ItemData if p != "" else null


func _build_wearers() -> void:
	var sets := [
		["item_iron_sword", "item_iron_shield"],
		["item_steel_sword", "item_steel_shield", "item_chainmail_coif", "item_chainmail_body", "item_chainmail_legs"],
		["item_steel_2h_sword", "item_platebody", "item_plate_helm", "item_plate_legs"],
		["item_bronze_bow", "item_leather_hood", "item_leather_body", "item_leather_breeches"],
		["item_mystic_staff", "item_wizard_hat", "item_wizard_robe_top", "item_wizard_robe_bottom"],
		["item_iron_dagger", "item_bronze_mace", "item_wizard_hat_grey", "item_wizard_robe_top", "item_wizard_robe_bottom"],
	]
	for i in sets.size():
		_wearer(sets[i], Vector3(-7.5 + i * 3.0, 0, 30))
	_views["chars"] = [Vector3(4.0, 1.4, 36.0), Vector3(4.0, 1.0, 30)]
	_views["close"] = [Vector3(-6.5, 1.35, 32.8), Vector3(-7.0, 1.1, 30)]


func _slot_key(slot: int) -> String:
	match slot:
		ItemData.Slot.HEAD: return "head"
		ItemData.Slot.CHEST: return "chest"
		ItemData.Slot.LEGS: return "legs"
		ItemData.Slot.FEET: return "feet"
		ItemData.Slot.HANDS: return "hands"
	return "other"
