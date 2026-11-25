extends SceneTree
## Pictures of the White Knight (assets/characters/white_knight/), not a pass/fail check. Windowed.
##   Godot_console --path . --resolution 1600x900 --script res://tests/visual_white_knight.gd -- <out dir> [shots...]
## Shots:
##   cmp_front cmp_back cmp_side_r cmp_side_l   orthographic, the sheet's pose and scale (242 px/m),
##                                              for laying next to the owner's sheet
##   front back side_l side_r                    standing (the Idle animation), studio light
##   tpose_front tpose_back                      the rest pose
##   helm_front helm_34 helm_side helm_back shoulder chest belt boot   close-ups
##   walk attack guard roll                      frames of the game's animations

const WK := preload("res://assets/characters/white_knight/white_knight.gd")
## Loaded at run time (not preloaded): the character script needs the game's autoloads.
const KNIGHT := "res://assets/characters/white_knight/white_knight.tscn"
const CMP_PPM := 242.3

var knight: Node3D
var cam: Camera3D
var sk: Skeleton3D
var ap: AnimationPlayer


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else "user://shots"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var shots: Array = ["cmp_front", "cmp_back", "cmp_side_r", "cmp_side_l", "front", "back", "side_l", "side_r", "tpose_front", "tpose_back",
			"helm_front", "helm_34", "helm_side", "helm_back", "shoulder", "chest", "belt", "boot", "walk", "attack", "guard", "roll"]
	if args.size() > 1:
		shots = args.slice(1)
	_stage()
	for i in 4:
		await process_frame
	for s in shots:
		call("_shot_" + s)
		for i in 12:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/wk_%s.png" % [out_dir, s])
		print("saved ", s)
	quit()


func _stage() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.085, 0.085, 0.085)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.6, 0.57)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	we.environment = env
	root.add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-32, -28, 0)
	key.light_energy = 1.5
	key.light_color = Color(1.0, 0.94, 0.86)
	key.shadow_enabled = true
	root.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-12, 60, 0)
	fill.light_energy = 0.45
	fill.light_color = Color(0.82, 0.88, 1.0)
	root.add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-25, 170, 0)
	rim.light_energy = 0.9
	root.add_child(rim)
	cam = Camera3D.new()
	root.add_child(cam)
	knight = (load(KNIGHT) as PackedScene).instantiate()
	root.add_child(knight)
	sk = knight.find_children("*", "Skeleton3D", true, false)[0]
	ap = knight.find_children("*", "AnimationPlayer", true, false)[0]
	var audio := knight.get_node_or_null("CharacterAudio")
	if audio:
		audio.process_mode = Node.PROCESS_MODE_DISABLED


# ------------------------------------------------------------------ poses

func _pose_rest() -> void:
	ap.stop()
	sk.reset_bone_poses()


## The pose the owner's sheet was drawn in (arms down, feet apart), as white_knight.gd uses it.
func _pose_sheet() -> void:
	_pose_rest()
	var delta: Dictionary = WK.sheet_pose()
	var want := {}
	for i in sk.get_bone_count():
		want[i] = (delta.get(i, Transform3D.IDENTITY) as Transform3D) * sk.get_bone_global_rest(i)
	for i in sk.get_bone_count():
		var par := sk.get_bone_parent(i)
		var local: Transform3D = want[i] if par < 0 else (want[par] as Transform3D).affine_inverse() * want[i]
		sk.set_bone_pose_position(i, local.origin)
		sk.set_bone_pose_rotation(i, local.basis.get_rotation_quaternion())


func _pose_anim(anim: StringName, t: float) -> void:
	sk.reset_bone_poses()
	ap.play(anim)
	ap.seek(t, true)
	ap.pause()


# ------------------------------------------------------------------ cameras

func _ortho(from: Vector3) -> void:
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 900.0 / CMP_PPM
	cam.position = from + Vector3(0, 0.96, 0)
	cam.look_at(Vector3(0, 0.96, 0))


func _persp(from: Vector3, at: Vector3, fov := 30.0) -> void:
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = fov
	cam.position = from
	cam.look_at(at)


func _around(deg: float, dist := 5.6, h := 1.0, at := Vector3(0, 0.95, 0), fov := 30.0) -> void:
	var a := deg_to_rad(deg)
	_persp(at + Vector3(sin(a) * dist, h - at.y, cos(a) * dist), at, fov)


# ------------------------------------------------------------------ shots

func _shot_cmp_front() -> void:
	_pose_sheet()
	_ortho(Vector3(0, 0, 6))


func _shot_cmp_back() -> void:
	_pose_sheet()
	_ortho(Vector3(0, 0, -6))


func _shot_cmp_side_r() -> void:
	_pose_sheet()
	_ortho(Vector3(-6, 0, 0))


func _shot_cmp_side_l() -> void:
	_pose_sheet()
	_ortho(Vector3(6, 0, 0))


func _shot_front() -> void:
	_pose_anim(&"Idle", 0.5)
	_around(0.0)


func _shot_back() -> void:
	_pose_anim(&"Idle", 0.5)
	_around(180.0)


func _shot_side_l() -> void:
	_pose_anim(&"Idle", 0.5)
	_around(90.0)


func _shot_side_r() -> void:
	_pose_anim(&"Idle", 0.5)
	_around(-90.0)


func _shot_tpose_front() -> void:
	_pose_rest()
	_around(0.0, 6.4)


func _shot_tpose_back() -> void:
	_pose_rest()
	_around(180.0, 6.4)


func _shot_helm_front() -> void:
	_pose_anim(&"Idle", 0.5)
	_around(0.0, 1.25, 1.78, Vector3(0, 1.77, 0), 22.0)


func _shot_helm_34() -> void:
	_pose_anim(&"Idle", 0.5)
	_around(40.0, 1.25, 1.8, Vector3(0, 1.77, 0), 22.0)


func _shot_helm_side() -> void:
	_pose_anim(&"Idle", 0.5)
	_around(90.0, 1.25, 1.78, Vector3(0, 1.77, 0), 22.0)


func _shot_helm_back() -> void:
	_pose_anim(&"Idle", 0.5)
	_around(180.0, 1.25, 1.78, Vector3(0, 1.75, 0), 22.0)


func _shot_shoulder() -> void:
	_pose_anim(&"Idle", 0.5)
	_around(60.0, 1.4, 1.5, Vector3(0.2, 1.42, 0), 24.0)


func _shot_chest() -> void:
	_pose_anim(&"Idle", 0.5)
	_around(0.0, 1.7, 1.35, Vector3(0, 1.3, 0), 26.0)


func _shot_belt() -> void:
	_pose_anim(&"Idle", 0.5)
	_around(15.0, 1.4, 1.15, Vector3(0, 1.12, 0), 26.0)


func _shot_boot() -> void:
	_pose_anim(&"Idle", 0.5)
	_around(55.0, 1.5, 0.45, Vector3(0.12, 0.3, 0.05), 26.0)


func _shot_walk() -> void:
	_pose_anim(&"Walk", 0.35)
	_around(30.0)


func _shot_attack() -> void:
	_pose_anim(&"ual2/Sword_Regular_Combo", 0.7)
	_around(35.0)


func _shot_guard() -> void:
	_pose_anim(&"ual2/Idle_Shield", 0.3)
	_around(-30.0)


func _shot_roll() -> void:
	_pose_anim(&"Roll", 0.35)
	_around(70.0)
