extends Node
## Screenshots of the environment: camps, the road, the river, the overview
## (not a pass/fail check). Windowed. Saves user://shots/env_*.png.
##   Godot --path . --resolution 1280x720 --script res://tests/run.gd -- visual_env
## Optional: add a hand-picked list after the check name, as  x,z,yaw,name  ...

var player: Player


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	await get_tree().process_frame
	await _frames(60)
	player = get_tree().get_first_node_in_group(&"player") as Player
	var terrain: ZoneTerrain = scene.get_node("Terrain")
	var spots := [
		["env_bandit_camp", -88.0, 24.0, -90.0],
		["env_bandit_camp_in", -100.0, 22.0, 90.0],
		["env_ford_camp", 12.0, -12.0, -90.0],
		["env_raider_camp", 108.0, -66.0, -140.0],
		["env_camp_hearth", 24.0, 124.0, -90.0],
		["env_road_crossroads", 2.0, 128.0, 180.0],
		["env_river_bank", 20.0, 14.0, 0.0],
	]
	for a in OS.get_cmdline_user_args().slice(1):
		var bits := String(a).split(",")
		if bits.size() == 4:
			spots.append([bits[3], float(bits[0]), float(bits[1]), float(bits[2])])
	for spot in spots:
		var x: float = spot[1]
		var z: float = spot[2]
		player.global_position = Vector3(x, terrain.height_at(x, z) + 0.2, z)
		player.velocity = Vector3.ZERO
		player.reset_physics_interpolation()
		player.camera_rig.yaw = deg_to_rad(spot[3])
		player.camera_rig.global_position = player.global_position + Vector3.UP * 1.55
		await _frames(45)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % spot[0])
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
