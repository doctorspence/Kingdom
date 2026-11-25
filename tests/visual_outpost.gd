extends SceneTree
## Pictures of the White Knights Outpost asset library (not a pass/fail check). Windowed.
## Uses the baked scenes in assets/outpost/, so bake first (tools/export_outpost.gd).
##   Godot_console --path . --resolution 1600x900 --script res://tests/visual_outpost.gd -- <out dir> [shots...]
## Shots: wk_overview wk_wall wk_stand wk_pennant (the White Knights set)
##        cp_overview cp_left cp_right cp_table cp_dusk (a checkpoint laid out with stage 2's pieces)
##        b07_outside b07_door b07_in (the cottage; the door and inside views through the game's
##        own camera arm: 1.7 m up, 3 m back, pulled in by walls)
##        vil_overview vil_market vil_b08_in vil_shed (stage 3's buildings as a village corner)

const WK_DIR := "res://assets/outpost/white_knights/"
const CP_DIR := "res://assets/outpost/castle_approach/"
const WK := preload("res://assets/outpost/white_knights/white_knights.gd")
const CP := preload("res://assets/outpost/castle_approach/castle_approach.gd")
## Where the checkpoint layout stands, away from the White Knights set.
const CPO := Vector3(40, 0, 0)
## Where the cottage stands.
const CB := Vector3(-45, 0, 40)
## Where the village corner stands.
const VB := Vector3(-45, 0, -25)
const BLD := preload("res://assets/outpost/buildings/buildings.gd")
const ENV := preload("res://levels/common/tithelands_env.tres")
const STONE := preload("res://levels/common/materials/stone.tres")

var stage: Node3D
var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var arm: SpringArm3D
var arm_cam: Camera3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else "user://shots"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var shots: Array = ["wk_overview", "wk_wall", "wk_stand", "wk_pennant", "cp_overview", "cp_left", "cp_right", "cp_table", "cp_dusk",
		"b07_outside", "b07_door", "b07_in", "vil_overview", "vil_market", "vil_b08_in", "vil_shed"]
	if args.size() > 1:
		shots = args.slice(1)
	_build()
	for s in shots:
		_day()
		call("_shot_" + s)
		for i in 40:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/outpost_%s.png" % [out_dir, s])
		print("saved ", s)
	quit()


func _wk(id: String, pos: Vector3, yaw := 0.0) -> Node3D:
	var dir := CP_DIR if id.begins_with("CP") else WK_DIR
	if id.begins_with("B"):
		dir = "res://assets/outpost/buildings/"
	var n := (load(dir + id + ".scn") as PackedScene).instantiate() as Node3D
	n.position = pos
	n.rotation_degrees.y = yaw
	stage.add_child(n)
	return n


func _build() -> void:
	stage = Node3D.new()
	root.add_child(stage)
	var we := WorldEnvironment.new()
	env = ENV.duplicate() as Environment
	env.volumetric_fog_enabled = false  # slow on a software renderer; ordinary fog stays
	env.ssil_enabled = false
	we.environment = env
	stage.add_child(we)
	sun = DirectionalLight3D.new()
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
	gm.uv1_scale = Vector3(54, 54, 1)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(240, 240)
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
	_build_cp()
	_build_b07()
	_build_village()


## A checkpoint across a 12 m road running north (-Z) toward the castle.
func _build_cp() -> void:
	var o := CPO
	for s in [-1.0, 1.0]:
		_wk("CP06_wooden_road_barrier", o + Vector3(s * 6.2, 0, -2.0), 0.0 if s < 0.0 else 180.0)
		_wk("CP08_guard_inspection_shelter", o + Vector3(s * 9.2, 0, -3.6), -90.0 * s)
		_wk("CP17_iron_lantern", o + Vector3(s * 7.3, 3.32, -3.6))
		_wk("CP05_standing_iron_brazier", o + Vector3(s * 6.6, 0, 0.9))
		_wk("CP04_stone_torch_holder", o + Vector3(s * 6.9, 0, -6.4))
		_wk("CP03_banner_pole", o + Vector3(s * 7.6, 0, 2.8))
		_wk("WK03_small_triangular_pennant", o + Vector3(s * 7.6, 0, 2.8) + CP.POLE_PENNANT, 0.0 if s < 0.0 else 180.0)
		_wk("WK04_mounted_standard", o + Vector3(s * 6.4, 0, -10.5))
	_wk("CP09_toll_inspection_table", o + Vector3(-4.4, 0, 1.6))
	_wk("CP10_guard_bench", o + Vector3(-10.4, 0, 1.4), 90.0)
	_wk("CP11_spear_rack", o + Vector3(10.6, 0, 0.6), -90.0)
	_wk("CP12_weapon_storage_chest", o + Vector3(9.8, 0, -7.0), -90.0)
	_wk("CP13_wooden_shield_display", o + Vector3(-11.0, 0, -7.6), 90.0)
	_wk("CP14_supply_barrels", o + Vector3(11.2, 0, -2.8), -60.0)
	_wk("CP15_supply_crates", o + Vector3(-11.4, 0, -1.2), 80.0)
	_wk("CP16_rope_and_chain_bundles", o + Vector3(10.0, 0, 3.2))
	_wk("CP07_movable_timber_barricade", o + Vector3(9.0, 0, 5.6), 15.0)
	_wk("CP18_warning_sign", o + Vector3(7.4, 0, 7.4), -10.0)
	_wk("CP20_stone_boundary_marker", o + Vector3(-7.6, 0, 9.2), 15.0)
	var man := (load("res://assets/characters/mannequin/Mannequin_F.glb") as PackedScene).instantiate() as Node3D
	man.position = o + Vector3(-1.4, 0, 3.8)
	man.rotation_degrees.y = 160.0
	stage.add_child(man)


## Daylight (the dusk shot dims it; every other shot starts from this).
func _day() -> void:
	sun.light_energy = 1.15
	env.ambient_light_energy = ENV.ambient_light_energy
	env.background_energy_multiplier = ENV.background_energy_multiplier
	env.fog_light_energy = ENV.fog_light_energy


func _look(from: Vector3, at: Vector3) -> void:
	cam.current = true
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


func _shot_cp_overview() -> void:
	_look(CPO + Vector3(0, 5.0, 21.0), CPO + Vector3(0, 1.2, -3.0))


func _shot_cp_left() -> void:
	_look(CPO + Vector3(-2.5, 2.3, 7.5), CPO + Vector3(-9.0, 1.4, -2.5))


func _shot_cp_right() -> void:
	_look(CPO + Vector3(3.0, 2.3, 8.0), CPO + Vector3(9.8, 1.0, -1.5))


func _shot_cp_table() -> void:
	_look(CPO + Vector3(-2.6, 1.9, 5.0), CPO + Vector3(-4.6, 0.85, 1.4))


## The same view at nightfall, to see the braziers, torches and lanterns.
func _shot_cp_dusk() -> void:
	sun.light_energy = 0.05
	env.ambient_light_energy = 0.18
	env.background_energy_multiplier = 0.25
	env.fog_light_energy = 0.15
	_look(CPO + Vector3(0, 3.2, 15.0), CPO + Vector3(0, 1.2, -3.0))


func _man(pos: Vector3, yaw: float) -> void:
	var m := (load("res://assets/characters/mannequin/Mannequin_F.glb") as PackedScene).instantiate() as Node3D
	m.position = pos
	m.rotation_degrees.y = yaw
	stage.add_child(m)


func _build_b07() -> void:
	var k: float = BLD.SIZE
	_wk("B07_small_cottage", CB)
	_wk("CP08_guard_inspection_shelter", CB + Vector3(7.5, 0, 3.0), -30.0)
	_wk("CP09_toll_inspection_table", CB + Vector3(5.6, 0, 6.2), -20.0)
	_man(CB + Vector3(-1.0 * k + 1.0, 0, 2.3 * k + 1.2), 200.0)
	_man(CB + Vector3(0.8 * k, 0, 0.2), -90.0)
	# The game's camera: a 3 m spring arm 1.7 m above the player that pulls in at walls.
	arm = SpringArm3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.2
	arm.shape = sh
	arm.spring_length = 3.0
	arm.margin = 0.05
	arm.collision_mask = 1
	stage.add_child(arm)
	arm_cam = Camera3D.new()
	arm_cam.fov = 58.0
	arm.add_child(arm_cam)


## The view through the game camera of a player standing at feet, facing away along yaw_deg
## (0 = the player faces -Z, the camera sits behind toward +Z).
func _arm_shot(feet: Vector3, yaw_deg: float, pitch_deg := -15.0) -> void:
	var yaw := deg_to_rad(yaw_deg)
	arm.global_position = feet + Vector3(0, 1.7, 0) + Basis(Vector3.UP, yaw) * Vector3(0.12, 0, 0)
	arm.rotation = Vector3(deg_to_rad(pitch_deg), yaw, 0)
	arm_cam.current = true


func _shot_b07_outside() -> void:
	_look(CB + Vector3(2.0, 2.4, 16.0), CB + Vector3(1.5, 3.0, 0.0))


func _shot_b07_door() -> void:
	_arm_shot(CB + Vector3(-1.0 * BLD.SIZE, 0, 2.3 * BLD.SIZE + 2.2), 0.0, -8.0)


func _shot_b07_in() -> void:
	_arm_shot(CB + Vector3(0.8 * BLD.SIZE, 0, 0.2), 90.0)


func _build_village() -> void:
	var k: float = BLD.SIZE
	_wk("B08_medium_cottage", VB + Vector3(-13, 0, 0), 8.0)
	_wk("B07_small_cottage", VB + Vector3(3, 0, -2), -6.0)
	_wk("B09_storage_shed", VB + Vector3(13, 0, 1), -18.0)
	_wk("B04_large_market_shelter", VB + Vector3(0, 0, 16))
	_wk("B05_small_market_stall", VB + Vector3(-2.6, 0, 16.4))
	_wk("B05_small_market_stall", VB + Vector3(2.6, 0, 16.4))
	_wk("WK08_red_ivory_market_awning", VB + Vector3(9.5, 0, 17), -10.0)
	_man(VB + Vector3(1.0, 0, 19.2), 180.0)
	_man(VB + Vector3(-13 - 1.0 * k, 0, 0.3), 90.0)


func _shot_vil_overview() -> void:
	_look(VB + Vector3(0, 10.0, 36.0), VB + Vector3(0, 2.0, 5.0))


func _shot_vil_market() -> void:
	_look(VB + Vector3(5.0, 2.4, 25.0), VB + Vector3(0, 1.7, 16.0))


func _shot_vil_b08_in() -> void:
	_arm_shot(VB + Vector3(-13 - 1.0 * BLD.SIZE, 0, 0.3), -90.0)


func _shot_vil_shed() -> void:
	_look(VB + Vector3(9.5, 2.2, 8.5), VB + Vector3(13, 1.6, 1.0))
