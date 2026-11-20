extends Node
## Debug picture: which way is "out of the fist"? Shows colored sticks from the
## right hand in the sword-idle pose and mid-swing. Pictures go to user://shots/.

func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var world := Node3D.new()
	get_tree().root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = load("res://levels/common/overcast_env.tres")
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	world.add_child(sun)
	var model_root: Node3D = (load("res://assets/characters/mannequin/UAL1_Standard.glb") as PackedScene).instantiate()
	var cm := CharacterModel.new()
	cm.add_child(model_root)
	world.add_child(cm)
	var skel: Skeleton3D = cm.find_children("*", "Skeleton3D", true, false)[0]
	var holder := BoneAttachment3D.new()
	holder.bone_name = "hand_r"
	skel.add_child(holder)
	for spec in [[Vector3(0, 0, 1), Color.RED], [Vector3(0, 0, -1), Color.BLUE], [Vector3(1, 0, 0), Color.GREEN], [Vector3(-1, 0, 0), Color.YELLOW]]:
		var m := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.03, 0.03, 0.6)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = spec[1]
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		box.material = mat
		m.mesh = box
		holder.add_child(m)
		var dir: Vector3 = spec[0]
		m.position = Vector3(0, 0.08, 0) + dir * 0.3
		m.look_at_from_position(m.position, m.position + dir, Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT)
		m.position = Vector3(0, 0.08, 0) + dir * 0.3
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.look_at_from_position(Vector3(1.6, 1.5, 1.8), Vector3(0, 1.0, 0))
	cam.current = true
	for anim in [&"Sword_Idle", &"ual2/Sword_Regular_A", &"ual2/Idle_Shield"]:
		cm.play(anim, 0.0, 1.0, true)
		await _frames(2)
		if anim == &"ual2/Sword_Regular_A":
			cm.seek(0.12)
			cm.set_speed(0.0)
		await _frames(10)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots/axes_%s.png" % String(anim).replace("/", "_"))
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
