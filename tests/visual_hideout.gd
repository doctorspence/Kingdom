extends SceneTree
## Screenshots of the bandit-hideout asset library samples (not a pass/fail check). Windowed.
##   Godot_console.exe --path . --resolution 1280x720 --script res://tests/visual_hideout.gd -- <out dir> [shot names...]
## Shots: storage structures camp mining cave

const Kit := preload("res://assets/hideout/Materials/kit.gd")
const Storage := preload("res://assets/hideout/Storage_Containers/storage.gd")
const Structures := preload("res://assets/hideout/Wooden_Structures/structures.gd")
const Camp := preload("res://assets/hideout/Camp_Equipment/camp.gd")
const Mining := preload("res://assets/hideout/Mining_Equipment/mining.gd")
const Lighting := preload("res://assets/hideout/Lighting_Props/lighting.gd")
const Cave := preload("res://assets/hideout/Cave_Geometry/cave.gd")

var stage: Node3D
var cam: Camera3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else "user://shots"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var shots: Array = ["storage", "structures", "camp", "mining", "cave", "storage_close", "camp_close", "mining_close"]
	if args.size() > 1:
		shots = args.slice(1)
	for s in shots:
		if s.begins_with("example"):
			_bare_stage()
		else:
			_new_stage()
		call("_shot_" + s)
		for i in 150:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/hideout_%s.png" % [out_dir, s])
		stage.queue_free()
		await process_frame
	quit()


func _new_stage() -> void:
	stage = Node3D.new()
	root.add_child(stage)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.008, 0.008, 0.01)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.55, 0.65)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.ssao_radius = 0.8
	env.ssao_intensity = 2.0
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.08
	env.fog_enabled = true
	env.fog_light_color = Color(0.04, 0.04, 0.05)
	env.fog_density = 0.012
	var we := WorldEnvironment.new()
	we.environment = env
	stage.add_child(we)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.12
	fill.light_color = Color(0.6, 0.7, 1.0)
	fill.rotation_degrees = Vector3(-50, 30, 0)
	stage.add_child(fill)
	# cave floor and a back wall
	for x in [-8.0, -4.0, 0.0, 4.0, 8.0]:
		for z in [-4.0, 0.0, 4.0]:
			_place(Cave.floor_section(4.0, int(x * 7 + z * 3 + 40)), Vector3(x, 0, z))
	for x in [-16.0, -12.0, -8.0, -4.0, 0.0, 4.0, 8.0, 12.0, 16.0]:
		_place(Cave.wall_section(4.0, 4.4, int(x) + 70), Vector3(x, 0, -6.0))
	var bounce := OmniLight3D.new()
	bounce.position = Vector3(0, 3.0, 0.5)
	bounce.light_color = Color(1.0, 0.62, 0.35)
	bounce.light_energy = 1.3
	bounce.omni_range = 12.0
	stage.add_child(bounce)
	cam = Camera3D.new()
	cam.fov = 58
	cam.far = 80
	stage.add_child(cam)
	cam.current = true


func _place(n: Node3D, pos: Vector3, yaw_deg := 0.0) -> Node3D:
	stage.add_child(n)
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	return n


func _look(from: Vector3, at: Vector3) -> void:
	cam.position = from
	cam.look_at_from_position(from, at)


func _shot_storage() -> void:
	var z1 := -3.4
	_place(Storage.barrel("small", 1), Vector3(-3.6, 0, z1))
	_place(Storage.barrel("large", 2), Vector3(-2.5, 0, z1))
	_place(Storage.barrel("water", 3), Vector3(-1.3, 0, z1))
	_place(Storage.barrel("grain", 4), Vector3(-0.2, 0, z1), 30)
	_place(Storage.barrel("broken", 5), Vector3(1.0, 0, z1), -20)
	_place(Storage.barrel_stack(6), Vector3(3.0, 0, z1 - 0.2), 8)
	var z2 := -1.0
	_place(Storage.crate("small", 7), Vector3(-3.3, 0, z2), 12)
	_place(Storage.crate("large", 8), Vector3(-1.9, 0, z2 - 0.1), -6)
	_place(Storage.crate("open", 9), Vector3(-0.2, 0, z2), 8)
	_place(Storage.crate("broken", 10), Vector3(1.4, 0, z2), -10)
	_place(Storage.sack("grain", 3), Vector3(2.9, 0, z2 + 0.2))
	_place(Storage.sack("grain", 4), Vector3(3.35, 0, z2 - 0.1), 40)
	_place(Storage.sack("slumped", 5), Vector3(3.2, 0, z2 + 0.8), -30)
	_place(Lighting.wall_torch("bracket"), Vector3(-2.2, 2.2, -5.6))
	_place(Lighting.wall_torch("cresset"), Vector3(2.0, 2.2, -5.7))
	_look(Vector3(0.3, 1.5, 3.0), Vector3(0.0, 0.5, -2.4))


func _shot_structures() -> void:
	_place(Structures.platform(4.0, 2.0, 1.5, "plain", 1), Vector3(0, 1.5, -4.2))
	var st := _place(Structures.stairs(1.5, 1.0), Vector3(4.2, 0, -4.2), 90)
	_place(Structures.railing(4.0), Vector3(-2.0, 1.5, -3.2))
	var r2 := _place(Structures.railing(2.0), Vector3(2.0, 1.5, -5.2), 90)
	_place(Structures.ladder(2.5), Vector3(-2.12, 0, -4.2), 90)
	_place(Structures.post(2.9), Vector3(-1.9, 0, -3.25))
	_place(Structures.post(2.9, 0.12, 8), Vector3(1.9, 0, -3.25))
	_place(Structures.crossbeam(3.9), Vector3(0, 2.85, -3.25))
	_place(Structures.platform(2.0, 2.0, 0.55, "worn", 4), Vector3(-4.5, 0.55, -2.8))
	_place(Storage.barrel("large", 2), Vector3(-0.8, 1.5, -4.4))
	_place(Storage.crate("small", 3), Vector3(0.5, 1.5, -4.6), 15)
	_place(Lighting.wall_torch("bracket"), Vector3(-1.0, 2.6, -5.7))
	_place(Lighting.torch_stand(), Vector3(3.1, 0, -2.2))
	_look(Vector3(1.8, 2.3, 4.0), Vector3(-0.2, 1.3, -4.0))


func _shot_camp() -> void:
	_place(Camp.campfire("ring"), Vector3(-0.6, 0, -2.2))
	_place(Camp.tripod_pot(), Vector3(-0.6, 0, -2.2))
	_place(Camp.campfire("communal", 14), Vector3(3.6, 0, -3.0))
	_place(Camp.stool(0), Vector3(-2.1, 0, -1.4), 20)
	_place(Camp.stool(1), Vector3(0.9, 0, -0.9))
	_place(Camp.stool(2), Vector3(-2.0, 0, -3.4), 60)
	_place(Storage.barrel("small", 2), Vector3(1.0, 0, -4.2))
	_place(Storage.sack("slumped", 5), Vector3(-3.4, 0, -2.6), 80)
	_place(Mining.rope_coil(), Vector3(0.6, 0, -1.4))
	_look(Vector3(0.8, 1.6, 3.2), Vector3(0.6, 0.7, -2.4))


func _shot_mining() -> void:
	for x in [-2.0, 0.0, 2.0]:
		_place(Mining.track(), Vector3(x, 0, -2.6))
	_place(Mining.mine_cart(true), Vector3(-0.4, 0, -2.6))
	_place(Mining.mine_cart(false, 33), Vector3(2.8, 0, -2.6))
	_place(Mining.ore_pile(1.1), Vector3(-3.6, 0, -1.8), 20)
	_place(Mining.pickaxe(), Vector3(-1.0, 0, -0.6), 25)
	_place(Mining.shovel(), Vector3(0.9, 0, -0.9), -35)
	_place(Mining.rope_coil(), Vector3(-2.0, 0, -0.8))
	_place(Lighting.brazier(), Vector3(-1.9, 0, -4.2))
	_place(Lighting.wall_torch("cresset"), Vector3(1.6, 2.1, -5.6))
	_place(Lighting.torch_stand(), Vector3(4.2, 0, -4.4))
	_look(Vector3(0.6, 1.5, 3.0), Vector3(0.0, 0.5, -2.8))


func _shot_cave() -> void:
	_place(Cave.stalagmites(6, false, 4), Vector3(-3.0, 0, -3.4))
	_place(Cave.stalagmites(4, false, 8), Vector3(4.3, 0, -1.2))
	_place(Cave.water_pool(1.2), Vector3(0.6, 0.04, -2.2))
	_place(Cave.rock_formation("large", 3), Vector3(4.2, 0, -4.4))
	_place(Cave.rock_formation("medium", 6), Vector3(-4.8, 0, -1.0))
	_place(Cave.rock_formation("small", 9), Vector3(-1.4, 0, -0.5))
	_place(Cave.rock_formation("small", 12), Vector3(2.2, 0, -0.1))
	for x in [-4.0, 0.0, 4.0]:
		_place(Cave.ceiling_section(4.0, int(x) + 99), Vector3(x, 4.4, -4.0))
	_place(Cave.stalagmites(5, true, 21), Vector3(-1.8, 4.4, -3.2))
	_place(Cave.stalagmites(4, true, 22), Vector3(2.2, 4.4, -3.6))
	_place(Lighting.brazier(), Vector3(1.8, 0, -0.9))
	_place(Lighting.torch_stand(), Vector3(-3.4, 0, -0.2))
	_look(Vector3(0.0, 1.5, 4.0), Vector3(0.0, 1.5, -3.0))


func _shot_storage_close() -> void:
	_shot_storage()
	_look(Vector3(-1.9, 1.15, 1.2), Vector3(-1.5, 0.5, -2.6))


func _shot_camp_close() -> void:
	_shot_camp()
	_look(Vector3(0.9, 1.25, 0.6), Vector3(-0.6, 0.65, -2.2))


func _shot_mining_close() -> void:
	_shot_mining()
	_look(Vector3(0.3, 0.95, -0.3), Vector3(-0.3, 0.35, -2.6))


const BAKED := "res://assets/hideout/%s/%s.scn"


func _inst(folder: String, nm: String, pos: Vector3, yaw_deg := 0.0) -> Node3D:
	var n := (load(BAKED % [folder, nm]) as PackedScene).instantiate() as Node3D
	return _place(n, pos, yaw_deg)


func _bare_stage() -> void:
	stage = Node3D.new()
	root.add_child(stage)
	cam = Camera3D.new()
	cam.fov = 70
	cam.far = 120
	stage.add_child(cam)
	cam.current = true
	stage.add_child((load("res://assets/hideout/Example_Hideout_Scene/hideout_example.scn") as PackedScene).instantiate())


func _shot_example_a() -> void:
	_look(Vector3(0.0, 3.0, 10.8), Vector3(-1.0, 1.6, -4.0))


func _shot_example_b() -> void:
	_look(Vector3(4.0, 1.7, 9.0), Vector3(-1.5, 1.0, 2.5))


func _shot_example_c() -> void:
	_look(Vector3(-2.0, 2.2, -1.0), Vector3(-7.0, 1.7, -10.0))


func _shot_example_d() -> void:
	_look(Vector3(2.0, 1.7, 7.2), Vector3(8.5, 1.0, -6.0))


func _shot_example_e() -> void:
	_look(Vector3(6.0, 1.6, -4.0), Vector3(6.0, 1.4, -22.0))


func _shot_more_structures() -> void:
	var W := "Wooden_Structures"
	_inst(W, "door_door", Vector3(-4.6, 0, -4.8))
	_inst(W, "door_broken", Vector3(-2.2, 0, -4.8))
	_inst(W, "door_gate", Vector3(0.9, 0, -4.8))
	_inst(W, "shelf_4tier", Vector3(3.6, 0, -5.3))
	_inst(W, "scaffold", Vector3(-3.6, 0, -1.6))
	_inst(W, "barricade", Vector3(0.0, 0, -1.2), 10)
	_inst(W, "bridge_3m", Vector3(2.0, 0.12, 0.2))
	_inst(W, "hanging_platform", Vector3(4.6, 1.2, -2.4)).position.y = 1.2
	_inst("Lighting_Props", "torch_wall_bracket", Vector3(-2.0, 2.3, -5.7))
	_inst("Lighting_Props", "torch_wall_cresset", Vector3(2.4, 2.3, -5.7))
	_look(Vector3(0.0, 2.1, 4.6), Vector3(0.0, 1.0, -2.6))


func _shot_more_camp() -> void:
	var C := "Camp_Equipment"
	for v in 3:
		_inst(C, "chair_%d" % v, Vector3(-3.6 + 0.9 * v, 0, -2.4), 5.0 - 10.0 * v)
	_inst(C, "table_trestle", Vector3(-0.2, 0, -3.0), 10)
	_inst(C, "utensils", Vector3(-0.2, 0.78, -3.0), 10)
	_inst(C, "table_slab", Vector3(2.3, 0, -3.4), -20)
	_inst(C, "tent_small", Vector3(-4.8, 0, -4.4), 25)
	_inst(C, "meat_rack", Vector3(4.4, 0, -4.0), -15)
	_inst(C, "bedding_open", Vector3(-1.4, 0, -0.4), 90)
	_inst(C, "bedding_straw", Vector3(0.9, 0, 0.1), 10)
	_inst(C, "bedding_blanket", Vector3(2.7, 0, -0.4), 30)
	_inst(C, "bedding_rolled", Vector3(3.9, 0, 0.3), 80)
	_inst(C, "personal_area", Vector3(-4.2, 0, 0.8), 90)
	_inst("Lighting_Props", "torch_stand", Vector3(1.2, 0, -1.8))
	_inst("Lighting_Props", "brazier", Vector3(-2.8, 0, -3.8))
	_look(Vector3(0.0, 2.0, 5.2), Vector3(0.0, 0.7, -1.6))


func _shot_more_mining() -> void:
	var M := "Mining_Equipment"
	_inst(M, "support_frame", Vector3(-3.2, 0, -4.4))
	_inst(M, "support_frame_broken", Vector3(0.4, 0, -4.4))
	_inst(M, "winch", Vector3(3.4, 0, -4.4))
	_inst(M, "pulley_gantry", Vector3(-4.6, 0, -1.8))
	_inst(M, "wheelbarrow_loaded", Vector3(-1.6, 0, -1.2), 30)
	_inst(M, "wheelbarrow_empty", Vector3(0.3, 0, -0.8), -20)
	_inst(M, "mining_hammer", Vector3(1.8, 0, 0.2), 20)
	_inst(M, "broken_tools", Vector3(3.2, 0, -0.6), 30)
	_inst(M, "rubble_large", Vector3(-3.4, 0, 0.6))
	_inst("Storage_Containers", "mining_box_tools", Vector3(2.2, 0, -2.0), -10)
	_inst("Environmental_Props", "sign_mining", Vector3(-3.2, 1.0, -4.3))
	_inst("Lighting_Props", "torch_wall_cresset", Vector3(0.0, 2.2, -5.7))
	_inst("Lighting_Props", "brazier", Vector3(5.0, 0, -1.6))
	_look(Vector3(0.0, 1.9, 4.8), Vector3(0.0, 0.9, -2.0))


func _shot_more_props() -> void:
	var S := "Storage_Containers"
	_inst(S, "chest_closed", Vector3(-3.6, 0, -2.0), 10)
	_inst(S, "chest_open", Vector3(-2.2, 0, -2.0), -5)
	_inst(S, "chest_broken", Vector3(-0.7, 0, -2.0), 8)
	_inst(S, "bucket_water", Vector3(0.7, 0, -1.8))
	_inst(S, "basket_turnips", Vector3(1.6, 0, -1.6))
	_inst(S, "basket_bread", Vector3(2.5, 0, -1.8), 40)
	_inst(S, "mining_box_empty", Vector3(3.8, 0, -2.0), -10)
	var L := "Lighting_Props"
	_inst(L, "candles_3", Vector3(-3.6, 0, -0.2))
	_inst(L, "oil_lamp", Vector3(-2.7, 0, -0.2))
	_inst(L, "lantern", Vector3(-1.8, 0.35, -0.2))
	_inst("Environmental_Props", "weapon_rack", Vector3(0.3, 0, -5.4))
	_inst("Environmental_Props", "sign_post", Vector3(2.8, 0, -4.0), 20)
	_inst("Environmental_Props", "chain_2m", Vector3(-3.4, 3.2, -4.0))
	_inst("Environmental_Props", "hook_rope", Vector3(-2.0, 1.8, -5.6))
	_inst(L, "torch_wall_bracket", Vector3(-3.0, 2.3, -5.7))
	_inst(L, "torch_wall_cresset", Vector3(3.4, 2.3, -5.7))
	_look(Vector3(0.0, 1.8, 3.6), Vector3(0.0, 0.8, -2.2))


func _shot_more_cave() -> void:
	var G := "Cave_Geometry"
	_inst(G, "tunnel_4m", Vector3(-4.0, 0, -4.2))
	_inst(G, "cave_opening", Vector3(1.4, 0, -4.4))
	_inst(G, "collapsed_rock", Vector3(5.6, 0, -2.8))
	_inst(G, "rock_pillar", Vector3(-1.6, 0, -1.4))
	_inst(G, "stone_ledge_3m", Vector3(-6.0, 0, -5.4))
	_inst(G, "cave_wall_wet_4m", Vector3(-8.0, 0, -6.0))
	_inst(G, "rock_medium", Vector3(3.2, 0, 0.2))
	_inst("Lighting_Props", "brazier", Vector3(-2.2, 0, 0.4))
	_inst("Lighting_Props", "torch_stand", Vector3(2.0, 0, -0.8))
	_look(Vector3(-0.5, 1.9, 4.4), Vector3(0.0, 1.3, -3.4))
