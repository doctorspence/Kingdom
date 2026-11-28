extends SceneTree
## Pictures of bandit face options side by side, to choose from (nothing in the game changes).
## Windowed (it renders):
##   Godot_console --path . --resolution 420x460 --script res://tools/face_options.gd -- [out dir] [outfit]
## Each option is a "face" entry (see FACE_DEFAULTS in bandit_body.gd). The sheets land in
## <out dir>/faces_<outfit>_<n>.png, two pictures per option: front and three-quarter.

const Mesh_ := preload("res://assets/characters/bandit/bandit_mesh.gd")
const Paint := preload("res://assets/characters/bandit/bandit_paint.gd")
const Body := preload("res://assets/characters/bandit/bandit_body.gd")
const Hair := preload("res://assets/characters/bandit/bandit_hair.gd")
const Clothes := preload("res://assets/characters/bandit/bandit_clothes.gd")
const Armor := preload("res://assets/characters/bandit/bandit_armor.gd")
const Outfits := preload("res://assets/characters/bandit/bandit_outfits.gd")

## low-detail shading: little painted shadow, no frown lines or scar
const PLAIN := {"socket": 0.2, "cheek": 0.12, "hollow": 0.15, "frown": 0.0, "scar": false}

var OPTIONS := [
	["0 Original (for comparison)", Body.ORIGINAL_FACE],
	# softer bars
	["1 Thin flat bar brows", {"brow_w": 0.008, "brow_t": 0.006, "brow_lift": 0.003, "brow_in": 1.705, "brow_out": 1.709}],
	["2 Thin bars, slight frown", {"brow_w": 0.009, "brow_t": 0.007, "brow_lift": 0.004, "brow_in": 1.702, "brow_out": 1.712}],
	["3 Thin bars, flat brow ridge, small nose", {"brow_w": 0.009, "brow_t": 0.007, "brow_lift": 0.003, "brow_in": 1.704, "brow_out": 1.710, "ridge": 0.4, "nose_tip": 0.018}],
	["4 Low bars, squinting", {"brow_w": 0.010, "brow_t": 0.007, "brow_lift": 0.004, "brow_in": 1.700, "brow_out": 1.705, "eye_h": 0.6, "eye": "dark", "nose_tip": 0.020}],
	# painted brows
	["5 Painted brows, white eyes", {"brow": "paint", "brow_in": 1.704, "brow_out": 1.712, "ridge": 0.3, "nose_tip": 0.018}],
	["6 Painted brows, dark eyes", {"brow": "paint", "brow_in": 1.704, "brow_out": 1.712, "ridge": 0.3, "nose_tip": 0.018, "eye": "dark"}],
	["7 Painted brows + painted eyes", {"brow": "paint", "brow_in": 1.704, "brow_out": 1.710, "ridge": 0.3, "nose_tip": 0.016, "eye": "none"}],
	["8 Thick painted brows, dark eyes", {"brow": "paint", "brow_paint_w": 0.009, "brow_in": 1.705, "brow_out": 1.709, "ridge": 0.3, "nose_tip": 0.018, "eye": "dark"}],
	["9 Stern painted brows", {"brow": "paint", "brow_in": 1.701, "brow_out": 1.712, "ridge": 0.4, "nose_tip": 0.020, "eye": "dark", "eye_h": 0.8}],
	["10 Tired (brows droop out)", {"brow": "paint", "brow_in": 1.709, "brow_out": 1.701, "ridge": 0.3, "nose_tip": 0.018, "eye": "dark", "eye_tilt": -0.12}],
	["11 No brows, dark eyes", {"brow": "none", "ridge": 0.0, "nose_tip": 0.018, "eye": "dark"}],
	# plain, low-detail
	["12 Plain: painted brows, small nose", PLAIN.merged({"brow": "paint", "brow_in": 1.705, "brow_out": 1.710, "ridge": 0.0, "nose_tip": 0.014, "nose_w": 0.017, "eye": "dark", "eye_w": 0.85, "eye_h": 0.8})],
	["13 Plain + mouth line", PLAIN.merged({"brow": "paint", "brow_in": 1.705, "brow_out": 1.710, "ridge": 0.0, "nose_tip": 0.014, "nose_w": 0.017, "eye": "dark", "eye_w": 0.85, "eye_h": 0.8, "mouth": 0.8})],
	["14 Plain, all painted (flat face)", PLAIN.merged({"brow": "paint", "brow_in": 1.705, "brow_out": 1.710, "ridge": 0.0, "nose": "none", "eye": "none", "eye_w": 0.85, "mouth": 0.7})],
	["15 Plain, block nose", PLAIN.merged({"brow": "paint", "brow_in": 1.705, "brow_out": 1.709, "ridge": 0.0, "nose_tip": 0.024, "nose_w": 0.020, "nose_top": 1.696, "eye": "dark", "eye_w": 0.85, "eye_h": 0.8})],
	["16 Plain, thin flat bars", PLAIN.merged({"brow_w": 0.007, "brow_t": 0.005, "brow_lift": 0.002, "brow_in": 1.706, "brow_out": 1.709, "ridge": 0.0, "nose_tip": 0.015, "eye": "dark", "eye_w": 0.85, "eye_h": 0.8})],
	["17 Plain, clean shaven look", PLAIN.merged({"brow": "paint", "brow_in": 1.705, "brow_out": 1.710, "ridge": 0.0, "nose_tip": 0.014, "eye": "dark", "eye_w": 0.85, "eye_h": 0.8, "stubble": 0.15})],
	["18 Plain, narrow jaw", PLAIN.merged({"brow": "paint", "brow_in": 1.705, "brow_out": 1.710, "ridge": 0.0, "nose_tip": 0.014, "eye": "dark", "eye_w": 0.85, "eye_h": 0.8, "jaw": 0.88})],
	["19 Plain, square jaw", PLAIN.merged({"brow": "paint", "brow_in": 1.704, "brow_out": 1.710, "ridge": 0.2, "nose_tip": 0.016, "eye": "dark", "eye_w": 0.85, "eye_h": 0.8, "jaw": 1.12})],
	["20 Plain, weathered (some shading)", {"brow": "paint", "brow_in": 1.704, "brow_out": 1.711, "ridge": 0.2, "nose_tip": 0.016, "eye": "dark", "eye_w": 0.85, "eye_h": 0.8, "socket": 0.45, "cheek": 0.25, "hollow": 0.35, "frown": 0.3, "scar": true}],
	["21 Plain, tiny dot eyes", PLAIN.merged({"brow": "paint", "brow_in": 1.706, "brow_out": 1.710, "ridge": 0.0, "nose_tip": 0.014, "eye": "none", "eye_w": 0.55, "eye_h": 1.3})],
	["22 Plain, no brows", PLAIN.merged({"brow": "none", "ridge": 0.0, "nose_tip": 0.014, "eye": "dark", "eye_w": 0.85, "eye_h": 0.8, "mouth": 0.6})],
	["23 Plain, heavy brow line", PLAIN.merged({"brow": "paint", "brow_paint_w": 0.010, "brow_paint": 1.0, "brow_in": 1.703, "brow_out": 1.708, "brow_len": 0.066, "ridge": 0.3, "nose_tip": 0.018, "eye": "dark", "eye_w": 0.85, "eye_h": 0.7})],
	["24 Plain, smaller head", PLAIN.merged({"brow": "paint", "brow_in": 1.705, "brow_out": 1.710, "ridge": 0.0, "nose_tip": 0.014, "eye": "dark", "eye_w": 0.85, "eye_h": 0.8, "head_w": 0.91, "head_d": 0.94})],
	["25 Plain, narrow long head", PLAIN.merged({"brow": "paint", "brow_in": 1.705, "brow_out": 1.710, "ridge": 0.0, "nose_tip": 0.016, "eye": "dark", "eye_w": 0.8, "eye_h": 0.8, "head_w": 0.88, "jaw": 0.95})],
	["26 Thin bars, smaller head", {"brow_w": 0.008, "brow_t": 0.006, "brow_lift": 0.003, "brow_in": 1.704, "brow_out": 1.710, "ridge": 0.3, "nose_tip": 0.016, "eye": "dark", "eye_w": 0.85, "eye_h": 0.8, "head_w": 0.91, "head_d": 0.94, "socket": 0.35, "cheek": 0.2, "hollow": 0.25, "frown": 0.0}],
]

const COLS := 3
const ROWS := 3
const ATLAS := 768

var stage: Node3D
var cam: Camera3D
var label: Label
var held: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://shots/faces"
	var outfit: String = args[1] if args.size() > 1 else "rough"
	DirAccess.make_dir_recursive_absolute(out_dir)
	_stage()
	var o: Dictionary = Outfits.OUTFITS[outfit].duplicate(true)
	var cells: Array[Image] = []
	for opt: Array in OPTIONS:
		o["face"] = Body.ORIGINAL_FACE.merged(opt[1], true)
		_show(o)
		label.text = opt[0]
		var pair: Array[Image] = []
		for yaw in [0.0, 38.0]:
			var a := deg_to_rad(yaw)
			cam.position = Vector3(sin(a) * 0.74, 1.70, cos(a) * 0.74)
			cam.look_at(Vector3(0, 1.685, 0.0))
			label.visible = yaw == 0.0
			for i in 4:
				await process_frame
			await RenderingServer.frame_post_draw
			pair.append(stage.get_viewport().get_texture().get_image())
		var w := pair[0].get_width()
		var h := pair[0].get_height()
		var cell := Image.create(w * 2, h, false, pair[0].get_format())
		cell.blit_rect(pair[0], Rect2i(0, 0, w, h), Vector2i(0, 0))
		cell.blit_rect(pair[1], Rect2i(0, 0, w, h), Vector2i(w, 0))
		cells.append(cell)
		print("done ", opt[0])
	# sheets
	var per := COLS * ROWS
	for s in ceili(cells.size() / float(per)):
		var cw := cells[0].get_width()
		var ch := cells[0].get_height()
		var sheet := Image.create(cw * COLS + 6 * (COLS - 1), ch * ROWS + 6 * (ROWS - 1), false, cells[0].get_format())
		sheet.fill(Color(0.9, 0.9, 0.9))
		for i in per:
			var k := s * per + i
			if k >= cells.size():
				break
			sheet.blit_rect(cells[k], Rect2i(0, 0, cw, ch), Vector2i((i % COLS) * (cw + 6), (i / COLS) * (ch + 6)))
		var path := out_dir.path_join("faces_%s_%d.png" % [outfit, s + 1])
		sheet.save_png(path)
		print("saved ", ProjectSettings.globalize_path(path))
	quit()


func _stage() -> void:
	stage = Node3D.new()
	get_root().add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.16, 0.17, 0.19)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.62, 0.62, 0.66)
	env.environment.ambient_light_energy = 0.55
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.25
	sun.light_color = Color(1.0, 0.95, 0.86)
	stage.add_child(sun)
	sun.look_at_from_position(Vector3(0.6, 2.6, 1.4), Vector3(0, 1.6, 0))
	cam = Camera3D.new()
	cam.fov = 30.0
	stage.add_child(cam)
	cam.make_current()
	var layer := CanvasLayer.new()
	stage.add_child(layer)
	label = Label.new()
	label.position = Vector2(10, 8)
	label.add_theme_font_size_override("font_size", 44)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 10)
	layer.add_child(label)


## Builds and paints the outfit with its face, in place of the last one.
func _show(o: Dictionary) -> void:
	if held:
		held.free()
	var m = Mesh_.new()
	Body.build(m, o)
	Hair.build(m, o)
	Clothes.build(m, o)
	Armor.build(m, o)
	m.pack(ATLAS)
	var img: Image = Paint.bake(m, ATLAS, false, o.colors, o.patches)
	img.generate_mipmaps()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.roughness = 0.96
	mat.metallic_specular = 0.08
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	held = Node3D.new()
	stage.add_child(held)
	var meshes: Dictionary = m.meshes(ATLAS, mat)
	for g in meshes:
		var mi := MeshInstance3D.new()
		mi.mesh = meshes[g]
		held.add_child(mi)
