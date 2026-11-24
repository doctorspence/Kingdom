extends Node
## Lines the raw TRELLIS Outcast up against the mannequin's rest T-pose (pictures in user://shots).

const RAW := "res://assets/characters/outcast/outcast_male_raw.glb"

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var sc := float(args[1]) if args.size() > 1 else 1.83
	var world := Node3D.new()
	get_tree().root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = load("res://levels/common/overcast_env.tres")
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 20, 0)
	world.add_child(sun)
	var man: Node3D = (load("res://assets/characters/mannequin/UAL1_Standard.glb") as PackedScene).instantiate()
	world.add_child(man)
	var sk: Skeleton3D = man.find_children("*", "Skeleton3D", true, false)[0]
	sk.reset_bone_poses()
	for ap in man.find_children("*", "AnimationPlayer", true, false):
		(ap as AnimationPlayer).stop()
	var ghost := StandardMaterial3D.new()
	ghost.albedo_color = Color(0.2, 0.5, 1.0, 0.35)
	ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for mi in man.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = ghost
	var raw: Node3D = (load(RAW) as PackedScene).instantiate()
	world.add_child(raw)
	raw.scale = Vector3.ONE * sc
	raw.position = Vector3(0, 0.5 * sc, 0)
	var cam := Camera3D.new()
	cam.fov = 35
	world.add_child(cam)
	cam.current = true
	for k in [["front", Vector3(0, 1.0, 4.5)], ["side", Vector3(4.5, 1.0, 0)], ["back", Vector3(0, 1.0, -4.5)]]:
		cam.look_at_from_position(k[1], Vector3(0, 0.95, 0))
		for i in 6:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots/outcast_fit_%s.png" % k[0])
	get_tree().quit()
