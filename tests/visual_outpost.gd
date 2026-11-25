extends SceneTree
## Pictures of the White Knights Outpost asset library (not a pass/fail check). Windowed.
## Uses the baked scenes in assets/outpost/, so bake first (tools/export_outpost.gd).
##   Godot_console --path . --resolution 1600x900 --script res://tests/visual_outpost.gd -- <out dir> [shots...]
## Shots: wk_overview wk_wall wk_stand wk_pennant

const WK_DIR := "res://assets/outpost/white_knights/"
const WK := preload("res://assets/outpost/white_knights/white_knights.gd")
const ENV := preload("res://levels/common/tithelands_env.tres")
const STONE := preload("res://levels/common/materials/stone.tres")

var stage: Node3D
var cam: Camera3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else "user://shots"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var shots: Array = ["wk_overview", "wk_wall", "wk_stand", "wk_pennant"]
	if args.size() > 1:
		shots = args.slice(1)
	_build()
	for s in shots:
		call("_shot_" + s)
		for i in 40:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/outpost_%s.png" % [out_dir, s])
		print("saved ", s)
	quit()


func _wk(id: String, pos: Vector3, yaw := 0.0) -> Node3D:
	var n := (load(WK_DIR + id + ".scn") as PackedScene).instantiate() as Node3D
	n.position = pos
	n.rotation_degrees.y = yaw
	stage.add_child(n)
	return n


func _build() -> void:
	stage = Node3D.new()
	root.add_child(stage)
	var we := WorldEnvironment.new()
	var env := ENV.duplicate() as Environment
	env.volumetric_fog_enabled = false  # slow on a software renderer; ordinary fog stays
	env.ssil_enabled = false
	we.environment = env
	stage.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-32, 35, 0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.shadow_enabled = true
	stage.add_child(sun)
	cam = Camera3D.new()
	cam.fov = 55.0
	stage.add_child(cam)
	# Ground: the zone's path texture.
	var gm := StandardMaterial3D.new()
	gm.albedo_texture = load("res://assets/textures/path/color.jpg")
	gm.normal_enabled = true
	gm.normal_texture = load("res://assets/textures/path/normal.jpg")
	gm.uv1_scale = Vector3(18, 18, 1)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	ground.mesh = pm
	ground.material_override = gm
	stage.add_child(ground)
	# A stone wall for the wall-mounted pieces (front face at z = -2.7).
	var wall := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(8.0, 5.0, 0.6)
	wall.mesh = bm
	wall.material_override = STONE
	wall.position = Vector3(-4.0, 2.5, -3.0)
	stage.add_child(wall)
	var zw := -2.7
	_wk("WK01_large_white_knights_banner", Vector3(-6.6, 4.9, zw + 0.08))
	_wk("WK07_coat_of_arms_plaque", Vector3(-4.2, 2.45, zw))
	_wk("WK09_faction_notice_seal", Vector3(-4.2, 2.0, zw))
	_wk("WK10_stone_insignia", Vector3(-2.5, 3.0, zw))
	_wk("WK05_wooden_shield_red_cross", Vector3(-2.5, 1.65, zw))
	_wk("WK11_banner_ropes_and_fittings", Vector3(-1.0, 3.7, zw))
	# Free-standing pieces.
	var stand := _wk("WK12_banner_stand", Vector3(1.6, 0, -1.6))
	_wk("WK02_narrow_hanging_banner", stand.position + WK.STAND_HOOK)
	_wk("WK04_mounted_standard", Vector3(3.7, 0, -2.2))
	_wk("WK08_red_ivory_market_awning", Vector3(7.4, 0, -2.4), -8.0)
	_wk("WK06_heraldic_signboard", Vector3(4.6, 0, 0.6), -25.0)
	# A plain pole for the pennant.
	var pole := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.045
	cm.bottom_radius = 0.055
	cm.height = 3.3
	pole.mesh = cm
	pole.material_override = load("res://assets/outpost/materials/oak_stained.tres")
	pole.position = Vector3(10.6, 1.65, 0.2)
	stage.add_child(pole)
	_wk("WK03_small_triangular_pennant", Vector3(10.6, 3.2, 0.2), 20.0)
	# A 1.85 m mannequin for scale.
	var man := (load("res://assets/characters/mannequin/Mannequin_F.glb") as PackedScene).instantiate() as Node3D
	man.position = Vector3(2.9, 0, 0.9)
	man.rotation_degrees.y = 200.0
	stage.add_child(man)


func _look(from: Vector3, at: Vector3) -> void:
	cam.position = from
	cam.look_at(at)


func _shot_wk_overview() -> void:
	_look(Vector3(2.0, 3.0, 11.5), Vector3(1.8, 2.0, -2.0))


func _shot_wk_wall() -> void:
	_look(Vector3(-3.6, 2.6, 3.4), Vector3(-3.8, 2.6, -2.7))


func _shot_wk_stand() -> void:
	_look(Vector3(5.6, 2.3, 6.2), Vector3(4.8, 2.1, -1.6))


func _shot_wk_pennant() -> void:
	_look(Vector3(9.4, 3.0, 2.6), Vector3(10.9, 2.95, 0.2))
