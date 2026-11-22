extends RefCounted
## Shared PBR materials of the equipment pack. Each is a StandardMaterial3D with color / normal /
## roughness textures (512px, tileable, in Materials/tex) and a metallic value. Textures are mapped
## triplanar in object space, so meshes need no UVs. Materials are saved as .tres by
## tools/build_equipment.gd and reused by every item (few draw calls, no duplicate textures).

const DIR := "res://assets/equipment/Materials/"
const WOOD_DIR := "res://assets/textures/wood/"

static var _cache := {}

# name -> [group folder, texture set, tint, metallic, uv tile size (m), roughness mult, extra]
const DEFS := {
	"bronze": ["Metals", "bronze", Color(1, 1, 1), 0.8, 0.30],
	"iron": ["Metals", "iron", Color(1, 1, 1), 0.55, 0.30],
	"steel": ["Metals", "steel", Color(1, 1, 1), 0.72, 0.30],
	"dark_steel": ["Metals", "steel", Color(0.5, 0.51, 0.55), 0.6, 0.30],
	"chainmail": ["Metals", "chainmail", Color(1, 1, 1), 0.6, 1.3],
	"leather": ["Leather", "leather", Color(1, 1, 1), 0.0, 0.5],
	"leather_dark": ["Leather", "leather", Color(0.6, 0.5, 0.45), 0.0, 0.5],
	"wood": ["Wood", "wood", Color(1.05, 0.86, 0.7), 0.0, 0.8],
	"wood_dark": ["Wood", "wood", Color(0.55, 0.46, 0.4), 0.0, 0.8],
	"cloth_coarse": ["Cloth", "cloth", Color(0.5, 0.42, 0.33), 0.0, 0.3],
	"cloth_blue": ["Cloth", "cloth", Color(0.17, 0.23, 0.4), 0.0, 0.3],
	"cloth_grey": ["Cloth", "cloth", Color(0.32, 0.32, 0.34), 0.0, 0.3],
	"cloth_red": ["Cloth", "cloth", Color(0.5, 0.15, 0.12), 0.0, 0.3],
	"cloth_trim": ["Cloth", "cloth", Color(0.62, 0.47, 0.2), 0.0, 0.3],
	"gem_purple": ["Gemstones", "", Color(0.45, 0.2, 0.75), 0.0, 1.0],
}


static func get_mat(name: String) -> StandardMaterial3D:
	if _cache.has(name):
		return _cache[name]
	var d: Array = DEFS[name]
	var path := "%s%s/%s.tres" % [DIR, d[0], name]
	var m: StandardMaterial3D
	if ResourceLoader.exists(path):
		m = load(path)
	else:
		m = build(name)
	_cache[name] = m
	return m


static func build(name: String) -> StandardMaterial3D:
	var d: Array = DEFS[name]
	var m := StandardMaterial3D.new()
	m.resource_name = name
	m.albedo_color = d[2]
	m.metallic = d[3]
	if name == "gem_purple":
		m.roughness = 0.12
		m.metallic_specular = 0.9
		m.emission_enabled = true
		m.emission = Color(0.45, 0.2, 0.8)
		m.emission_energy_multiplier = 0.7
		return m
	var tex: String = d[1]
	if tex == "wood":
		m.albedo_texture = load(WOOD_DIR + "color.jpg")
		m.normal_enabled = true
		m.normal_texture = load(WOOD_DIR + "normal.jpg")
		m.roughness_texture = load(WOOD_DIR + "rough.jpg")
		m.roughness = 1.0
	else:
		m.albedo_texture = load("%stex/%s_color.png" % [DIR, tex])
		m.normal_enabled = true
		m.normal_texture = load("%stex/%s_normal.png" % [DIR, tex])
		m.roughness_texture = load("%stex/%s_rough.png" % [DIR, tex])
		m.roughness = 1.0
	m.normal_scale = 0.8
	if d[0] == "Cloth" or d[0] == "Leather" or name == "chainmail":
		m.cull_mode = BaseMaterial3D.CULL_DISABLED   # open hems and sleeve ends show their inside
	m.metallic_specular = 0.5
	m.uv1_triplanar = true
	m.uv1_triplanar_sharpness = 4.0
	var s := 1.0 / float(d[4])
	m.uv1_scale = Vector3(s, s, s)
	return m


static func all_names() -> Array:
	return DEFS.keys()
