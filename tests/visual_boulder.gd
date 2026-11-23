extends Node
## Boulder gallery: a row of generated boulders on a plain floor. Saves user://shots/<prefix>_boulders.png
func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var prefix: String = OS.get_cmdline_user_args()[1] if OS.get_cmdline_user_args().size() > 1 else "bg"
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.62, 0.7)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.62, 0.65)
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -35, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 40)
	floor_mesh.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.25, 0.3, 0.18)
	pm.material = fm
	add_child(floor_mesh)
	var scn: PackedScene = load("res://levels/tithelands/props/rock.tscn")
	for row in 2:
		for i in 5:
			var b: Node3D = scn.instantiate()
			add_child(b)
			b.position = Vector3(-9.0 + i * 4.5 + row * 7.3, 0.0, -2.0 - row * 6.0)
			b.scale = Vector3.ONE * (0.8 + 0.25 * i)
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 5.5, 9)
	cam.look_at(Vector3(0, 0.8, -5))
	cam.current = true
	for i in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/%s_boulders.png" % prefix)
	get_tree().quit()
