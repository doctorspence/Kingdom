extends Node
## Pictures of the base Outcast outfit on both bodies: front, back, side, face, and walking.
## Run windowed: Godot_console.exe --path . --resolution 1280x720 --script res://tests/run.gd -- visual_outcast [anim]
## Pictures go to user://shots/outcast_*.png

const Outcast := preload("res://assets/equipment/eq_outcast.gd")


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var t0 := Time.get_ticks_msec()
	Outcast.parts(false)
	var t1 := Time.get_ticks_msec()
	Outcast.parts(true)
	print("outfit build ms: broad %d, slender %d" % [t1 - t0, Time.get_ticks_msec() - t1])
	print("outfit triangles: broad %d, slender %d" % [Outcast.triangle_count(false), Outcast.triangle_count(true)])
	var world := Node3D.new()
	get_tree().root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = load("res://levels/common/overcast_env.tres")
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.light_energy = 1.3
	world.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 200, 0)
	fill.light_energy = 0.7
	world.add_child(fill)
	var floor_ := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(10, 10)
	floor_.mesh = pm
	world.add_child(floor_)
	var anim := StringName(OS.get_cmdline_user_args()[1]) if OS.get_cmdline_user_args().size() > 1 else &"Idle"
	var models: Array = []
	for i in 2:
		var cm := CharacterModel.new()
		cm.add_child((load("res://assets/characters/mannequin/UAL1_Standard.glb") as PackedScene).instantiate())
		cm.position = Vector3(-0.6 + 1.2 * i, 0, 0)
		cm.body_tint = Classes.LOOK_COLORS[1]
		world.add_child(cm)
		cm.set_body(i == 1)
		cm.set_outfit(true, i == 1)
		cm.set_tint(Classes.LOOK_COLORS[1])
		cm.play(anim, 0.0)
		models.append(cm)
	var cam := Camera3D.new()
	cam.fov = 40
	world.add_child(cam)
	cam.current = true
	await _frames(20)
	for m in models:
		m.set_speed(0.0)
	var shots := {
		"front": [Vector3(0, 1.1, 4.2), Vector3(0, 0.95, 0)],
		"back": [Vector3(0, 1.1, -4.2), Vector3(0, 0.95, 0)],
		"side": [Vector3(4.2, 1.1, 0.6), Vector3(0, 0.95, 0)],
		"three_q": [Vector3(3.0, 1.4, 3.0), Vector3(0, 0.95, 0)],
		"face_m": [Vector3(-0.6, 1.72, 0.75), Vector3(-0.6, 1.62, 0)],
		"face_f": [Vector3(0.6, 1.7, 0.75), Vector3(0.6, 1.58, 0)],
	}
	for k in shots:
		cam.look_at_from_position(shots[k][0], shots[k][1])
		await _frames(4)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots/outcast_%s_%s.png" % [String(anim).replace("/", "_"), k])
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
