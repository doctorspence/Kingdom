extends Node
## Colors each region of a fitted Outcast model (head, torso, forearms, legs, feet, cloak) in the
## T-pose, to check how tools/fit_outcast.gd split it. Pictures: user://shots/regions_*.png
## Args: [model name, default outcast_male]

const COLORS := {"head": Color(0.9, 0.8, 0.2), "torso": Color(0.9, 0.3, 0.3), "forearms": Color(0.3, 0.8, 0.9),
	"legs": Color(0.3, 0.4, 0.9), "feet": Color(0.6, 0.3, 0.8), "cloak": Color(0.2, 0.8, 0.2)}

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var name_: String = args[1] if args.size() > 1 else "outcast_male"
	var world := Node3D.new()
	get_tree().root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = load("res://levels/common/overcast_env.tres")
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 20, 0)
	world.add_child(sun)
	var src: ArrayMesh = load("res://assets/characters/outcast/%s.res" % name_)
	for s in src.get_surface_count():
		var arr := src.surface_get_arrays(s)
		arr[Mesh.ARRAY_BONES] = null
		arr[Mesh.ARRAY_WEIGHTS] = null
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = COLORS.get(src.surface_get_name(s), Color.WHITE)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.surface_set_material(0, mat)
		var mi := MeshInstance3D.new()
		mi.mesh = m
		world.add_child(mi)
	var cam := Camera3D.new()
	cam.fov = 35
	world.add_child(cam)
	cam.current = true
	for k in [["front", Vector3(0, 1.0, 4.5)], ["back", Vector3(0, 1.0, -4.5)], ["side", Vector3(4.5, 1.0, 0)]]:
		cam.look_at_from_position(k[1], Vector3(0, 0.95, 0))
		for i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots/regions_%s_%s.png" % [name_, k[0]])
	get_tree().quit()
