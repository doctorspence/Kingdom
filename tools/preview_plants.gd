extends Node
## Plant gallery: every PlantKit plant (3 variants each) in a row on a lawn under the
## zone's light (not a check). Windowed:
##   Godot --path . --resolution 1600x900 --script res://tests/run.gd -- ../tools/preview_plants
## Saves user://shots/plants_lineup.png and plants_close.png.

func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var we := WorldEnvironment.new()
	we.environment = load("res://levels/common/tithelands_env.tres")
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, 35, 0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.25, 0.22, 0.17)
	ground.material_override = gm
	add_child(ground)
	var x := -14.0
	for n: String in PlantKit.NAMES:
		for v in 3:
			var mi := MeshInstance3D.new()
			mi.mesh = PlantKit.mesh(n, v)
			mi.position = Vector3(x + v * 0.9, 0, v * 0.6 - 0.6)
			add_child(mi)
		x += 3.2
	var cam := Camera3D.new()
	cam.fov = 50
	add_child(cam)
	cam.position = Vector3(0, 2.6, 13.0)
	cam.look_at(Vector3(0, 0.5, 0))
	await _shot("plants_lineup")
	cam.position = Vector3(-11, 1.6, 6.0)
	cam.look_at(Vector3(-11, 0.5, 0))
	await _shot("plants_close")
	get_tree().quit()


func _shot(n: String) -> void:
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % n)
