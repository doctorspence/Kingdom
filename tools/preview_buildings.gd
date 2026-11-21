extends Node
## Photos of baked buildings on a plain lawn under the zone's light (not a check). Windowed:
##   Godot --path . --resolution 1280x720 --script res://tests/run.gd -- ../tools/preview_buildings cottage_0 tent_1 ...
## Saves user://shots/b_<name>_<view>.png (front three-quarter, back three-quarter, close).

const VIEWS := [["a", Vector3(8.5, 3.2, 10.5), Vector3(0, 2.4, 0)], ["b", Vector3(-9.5, 4.0, -9.0), Vector3(0, 2.6, 0)],
	["c", Vector3(2.4, 1.7, 5.2), Vector3(0.2, 1.6, 1.5)]]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var we := WorldEnvironment.new()
	we.environment = load("res://levels/common/tithelands_env.tres")
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, 35, 0)
	sun.light_color = Color(0.98, 0.9, 0.78)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	ground.mesh = pm
	ground.material_override = load("res://levels/common/materials/grass.tres")
	add_child(ground)
	var cam := Camera3D.new()
	cam.fov = 60
	add_child(cam)
	cam.make_current()
	for nm in OS.get_cmdline_user_args().slice(1):
		var b := (load("res://assets/buildings/%s.scn" % nm) as PackedScene).instantiate() as Node3D
		add_child(b)
		for v: Array in VIEWS:
			var scale := 0.6 if String(nm).begins_with("tent") else (1.6 if String(nm).begins_with("barn") or String(nm).begins_with("tower") or String(nm).begins_with("mill") else 1.0)
			cam.position = (v[1] as Vector3) * Vector3(scale, scale, scale)
			cam.look_at((v[2] as Vector3) * scale)
			await _frames(20)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://shots/b_%s_%s.png" % [nm, v[0]])
		b.queue_free()
		await _frames(2)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
