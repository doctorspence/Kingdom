extends Node
## Frame-rate measurement at 10 fixed spots in the Tithelands (not pass/fail).
## Windowed (needs a GPU):
##   Godot --path . --resolution 1920x1080 --script res://tests/run.gd -- perf_zone
## Prints average FPS over 90 frames, draw calls and thousands of primitives.
## Add "nogrow" after the name to hide trees/plants/boulders and see what the
## scatter costs.

var player: Player


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	var t0 := Time.get_ticks_msec()
	get_tree().root.add_child(scene)
	await get_tree().process_frame
	print("LOAD zone ready in %d ms" % (Time.get_ticks_msec() - t0))
	for i in 90:
		await get_tree().process_frame
	player = get_tree().get_first_node_in_group(&"player") as Player
	var terrain: ZoneTerrain = scene.get_node("Terrain")
	if "nogrow" in OS.get_cmdline_user_args():
		_hide_scatter(scene)
	# "hide:Highcrown,Places" hides those top-level nodes; "only:spawn_north" measures one spot.
	var only := ""
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("hide:"):
			for n in String(a).substr(5).split(","):
				var node := scene.get_node_or_null(n) as Node3D
				if node:
					node.visible = false
		elif String(a).begins_with("only:"):
			only = String(a).substr(5)
	for c in scene.get_children():
		var tt := _tris(c)
		if tt > 20000:
			print("TRIS %-14s %7dk" % [c.name, tt / 1000])
	for c in scene.get_node("Terrain").get_children():
		print("TRIS Terrain/%s %dk" % [c.name, _tris(c) / 1000])
	# Experiments: which render features cost the most?
	var args := OS.get_cmdline_user_args()
	var we := scene.get_node("WorldEnvironment") as WorldEnvironment
	if "noomni" in args:
		for l in scene.find_children("*", "Light3D", true, false):
			if not l is DirectionalLight3D:
				(l as Light3D).shadow_enabled = false
	if "nosun" in args:
		(scene.get_node("Sun") as DirectionalLight3D).shadow_enabled = false
	if "nossao" in args:
		we.environment.ssao_enabled = false
		we.environment.ssil_enabled = false
	if "novolfog" in args:
		we.environment.volumetric_fog_enabled = false
	if "noglow" in args:
		we.environment.glow_enabled = false
	var spots := [
		["spawn_north", 2.0, 128.0, 0.0],
		["spawn_south", 2.0, 128.0, 180.0],
		["farms", -20.0, 60.0, -90.0],
		["river_bank", 20.0, 14.0, 0.0],
		["mill", 12.0, -12.0, -90.0],
		["hobb_camp", -88.0, 24.0, -90.0],
		["raider_camp", 108.0, -66.0, -140.0],
		["road_checkpoint", 2.0, 40.0, 0.0],
		["east_woods", 90.0, 20.0, 90.0],
		["camp_hearth", 24.0, 124.0, -90.0],
	]
	for spot in spots:
		if only != "" and spot[0] != only:
			continue
		var x: float = spot[1]
		var z: float = spot[2]
		player.global_position = Vector3(x, terrain.height_at(x, z) + 0.2, z)
		player.velocity = Vector3.ZERO
		player.reset_physics_interpolation()
		player.camera_rig.yaw = deg_to_rad(spot[3])
		player.camera_rig.pitch = deg_to_rad(8.0)
		player.camera_rig.global_position = player.global_position + Vector3.UP * 1.55
		for i in 40:
			await get_tree().process_frame
		var t := Time.get_ticks_usec()
		for i in 90:
			await get_tree().process_frame
		var ms := (Time.get_ticks_usec() - t) / 90000.0
		print("PERF %-16s %5.1f FPS (%5.1f ms)  %4d draw calls  %5dk primitives" % [spot[0], 1000.0 / ms, ms, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000])
	get_tree().quit()


func _hide_scatter(scene: Node) -> void:
	for n in scene.find_children("*", "ForestScatter", true, false):
		(n as Node3D).visible = false
	for n in scene.find_children("*", "PlantScatter", true, false):
		(n as Node3D).visible = false


## Triangles (index count / 3) under a node, counting MultiMesh instances.
func _tris(n: Node) -> int:
	var t := 0
	if n is MultiMeshInstance3D:
		var mm := (n as MultiMeshInstance3D).multimesh
		if mm and mm.mesh:
			t += _mesh_tris(mm.mesh) * mm.instance_count
	elif n is MeshInstance3D and (n as MeshInstance3D).mesh:
		t += _mesh_tris((n as MeshInstance3D).mesh)
	for c in n.get_children():
		t += _tris(c)
	return t


func _mesh_tris(m: Mesh) -> int:
	var t := 0
	for s in m.get_surface_count():
		var a := m.surface_get_arrays(s)
		var idx = a[Mesh.ARRAY_INDEX]
		t += (idx.size() if idx != null else a[Mesh.ARRAY_VERTEX].size()) / 3
	return t
