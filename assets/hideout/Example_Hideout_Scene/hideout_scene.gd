extends RefCounted
## Assembles the example bandit hideout from the asset library: a big natural chamber with an
## improvised multi-level timber camp against the north wall, a communal fire, a mining corner
## with carts on track, sleeping areas, storage, torchlight and dark tunnels leading deeper.
## Layout is deliberately lopsided. +Z is the camera/south side, the main wall is at z = -12.

const Cave := preload("res://assets/hideout/Cave_Geometry/cave.gd")
const CaveX := preload("res://assets/hideout/Cave_Geometry/cave_extra.gd")
const Struct := preload("res://assets/hideout/Wooden_Structures/structures.gd")
const StructX := preload("res://assets/hideout/Wooden_Structures/structures_extra.gd")
const Store := preload("res://assets/hideout/Storage_Containers/storage.gd")
const StoreX := preload("res://assets/hideout/Storage_Containers/storage_extra.gd")
const Camp := preload("res://assets/hideout/Camp_Equipment/camp.gd")
const CampX := preload("res://assets/hideout/Camp_Equipment/camp_extra.gd")
const Mine := preload("res://assets/hideout/Mining_Equipment/mining.gd")
const MineX := preload("res://assets/hideout/Mining_Equipment/mining_extra.gd")
const Light := preload("res://assets/hideout/Lighting_Props/lighting.gd")
const LightX := preload("res://assets/hideout/Lighting_Props/lighting_extra.gd")
const Props := preload("res://assets/hideout/Environmental_Props/props.gd")

const CEILING := 5.4


static func _add(parent: Node3D, n: Node3D, pos: Vector3, yaw_deg := 0.0) -> Node3D:
	parent.add_child(n)
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	return n


static func build() -> Node3D:
	var root := Node3D.new()
	root.name = "BanditHideout"
	root.add_child(_environment())
	var shell := Node3D.new()
	shell.name = "CaveShell"
	root.add_child(shell)
	_cave_shell(shell)
	var camp := Node3D.new()
	camp.name = "Camp"
	root.add_child(camp)
	_timber_camp(camp)
	_central_camp(camp)
	_mining_corner(camp)
	_storage_and_beds(camp)
	var lights := Node3D.new()
	lights.name = "Lighting"
	root.add_child(lights)
	_lighting(lights)
	return root


static func _environment() -> Node3D:
	var n := Node3D.new()
	n.name = "Environment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.005, 0.005, 0.007)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.46, 0.56)
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.ssao_radius = 0.9
	env.ssao_intensity = 2.0
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.06
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.045, 0.045)
	env.fog_density = 0.014
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	n.add_child(we)
	return n


static func _cave_shell(p: Node3D) -> void:
	# floor and ceiling: 6 x 6 tiles of 4 m
	var idx := 0
	for ix in 6:
		for iz in 6:
			var x := -10.0 + 4.0 * ix
			var z := -10.0 + 4.0 * iz
			_add(p, Cave.floor_section(4.0, 200 + idx), Vector3(x, 0, z))
			_add(p, Cave.ceiling_section(4.0, 300 + idx), Vector3(x, CEILING, z))
			idx += 1
	# walls: north (with two openings), west, east, south
	for ix in 6:
		var x := -10.0 + 4.0 * ix
		if ix != 4:
			_add(p, Cave.wall_section(4.0, CEILING, 400 + ix), Vector3(x, 0, -12.0))
		_add(p, Cave.wall_section(4.0, CEILING, 430 + ix), Vector3(x, 0, 12.0), 180)
	for iz in 6:
		var z := -10.0 + 4.0 * iz
		if iz != 2:
			_add(p, Cave.wall_section(4.0, CEILING, 460 + iz), Vector3(-12.0, 0, z), 90)
		_add(p, Cave.wall_section(4.0, CEILING, 490 + iz), Vector3(12.0, 0, z), -90)
	# tunnels leading deeper, with their openings
	_add(p, CaveX.cave_opening(3.2, 3.0, 112, CEILING), Vector3(6.0, 0, -11.9))
	_add(p, CaveX.tunnel(8.0), Vector3(6.0, 0, -16.5))
	_add(p, CaveX.tunnel(8.0, 3.2, 2.8, 120), Vector3(6.0, 0, -24.0))
	_add(p, CaveX.cave_opening(3.2, 3.0, 119, CEILING), Vector3(-11.9, 0, -2.0), 90)
	_add(p, CaveX.tunnel(8.0, 3.2, 2.8, 121), Vector3(-16.5, 0, -2.0), 90)
	_add(p, CaveX.collapsed_rock(), Vector3(-20.5, 0, -2.0), 90)
	# rock formations, pillars, ledges, water, stalactites
	_add(p, Cave.rock_formation("large", 31), Vector3(10.0, 0, 9.5))
	_add(p, Cave.rock_formation("large", 33), Vector3(-9.5, 0, 9.5), 70)
	_add(p, Cave.rock_formation("medium", 35), Vector3(3.5, 0, 10.4))
	_add(p, Cave.rock_formation("small", 36), Vector3(-2.0, 0, 8.5))
	_add(p, Cave.rock_formation("small", 37), Vector3(9.0, 0, 1.0))
	_add(p, CaveX.rock_pillar(CEILING, 0.7, 41), Vector3(-1.2, 0, -5.8))
	_add(p, CaveX.rock_pillar(CEILING, 0.6, 42), Vector3(5.5, 0, 6.5))
	_add(p, CaveX.stone_ledge(3.0, 43), Vector3(-2.5, 0, -11.2))
	_add(p, Cave.water_pool(1.3, 44), Vector3(10.2, 0.02, -3.2))
	_add(p, Cave.stalagmites(5, false, 45), Vector3(11.0, 0, -5.8))
	_add(p, Cave.stalagmites(4, false, 46), Vector3(-10.8, 0, 7.5))
	for s in [[Vector3(2.0, CEILING, -4.0), 5], [Vector3(-6.0, CEILING, 1.0), 4], [Vector3(8.5, CEILING, 5.0), 6], [Vector3(-1.0, CEILING, 9.0), 4]]:
		_add(p, Cave.stalagmites(s[1], true, 50 + s[1]), s[0])


## The improvised multi-level timber camp against the north wall (west side).
static func _timber_camp(p: Node3D) -> void:
	# upper deck A (top at y = 2.0) and lower deck B (top at y = 1.0): unequal, crooked heights
	_add(p, Struct.platform(4.0, 2.0, 2.0, "plain", 61), Vector3(-7.5, 2.0, -10.9))
	_add(p, Struct.platform(2.0, 4.0, 1.0, "worn", 62), Vector3(-4.5, 1.0, -9.6))
	# stairs up to deck B (climb toward -Z), ladder from B to A
	_add(p, Struct.stairs(1.0, 1.0, 63), Vector3(-4.5, 0, -6.4))
	_add(p, Struct.ladder(1.5, 64), Vector3(-5.6, 1.0, -9.4), 90)
	# railings and posts
	_add(p, Struct.railing(4.0, 1.0, 65), Vector3(-9.5, 2.0, -9.95))
	_add(p, Struct.railing(4.0, 1.0, 66), Vector3(-3.5, 1.0, -11.6), -90)
	_add(p, Struct.railing(1.0, 1.0, 67), Vector3(-9.5, 2.0, -10.9), -90)
	_add(p, Struct.post(1.6, 0.1, 68), Vector3(-9.45, 2.0, -9.95))
	_add(p, Struct.post(3.0, 0.12, 69), Vector3(-3.45, 0, -7.7))
	_add(p, StructX.shelf(1.3, 1.9, 4, 70), Vector3(-7.6, 2.0, -11.6))
	_add(p, StructX.hanging_platform(1.6, 1.4, 3.4, 71), Vector3(-2.2, 2.0, -4.6))
	# scaffold + door on the east of the wall, a barricade across the south approach
	_add(p, StructX.scaffold(2.0, 1.6, 3.2, 1.6, 72), Vector3(10.0, 0, -9.6))
	_add(p, StructX.door("door", 73), Vector3(-11.55, 0, 6.0), 90)
	_add(p, StructX.door("gate", 74), Vector3(0.0, 0, 11.6), 180)
	_add(p, StructX.barricade(2.6, 75), Vector3(-5.0, 0, 7.0), 15)
	_add(p, StructX.bridge(3.0, 1.2, 76), Vector3(8.7, 0.12, -3.2), 90)
	# furnishing the decks
	_add(p, Store.barrel("large", 81), Vector3(-9.0, 2.0, -11.2))
	_add(p, Store.crate("small", 82), Vector3(-8.2, 2.0, -9.9), 12)
	_add(p, CampX.bedding("open", 83), Vector3(-6.2, 2.0, -10.8), 90)
	_add(p, StoreX.chest("closed", 84), Vector3(-5.8, 2.0, -10.0), 8)
	_add(p, Store.crate("open", 85), Vector3(-4.6, 1.0, -11.1), -15)
	_add(p, Store.barrel("small", 86), Vector3(-4.1, 1.0, -9.0))
	_add(p, Store.sack("grain", 3), Vector3(-4.6, 1.0, -8.2), 20)
	_add(p, Props.weapon_rack(87), Vector3(-1.4, 0, -11.4))
	_add(p, Props.sign_board("post", 88), Vector3(3.8, 0, -9.0), 20)
	_add(p, Props.hook("rope", 89), Vector3(-10.4, 3.0, -11.4))


static func _central_camp(p: Node3D) -> void:
	_add(p, Camp.campfire("communal", 91), Vector3(0.5, 0, 2.5))
	_add(p, Camp.stool(0, 92), Vector3(-1.9, 0, 3.0), 30)
	_add(p, CampX.chair(1, 93), Vector3(2.8, 0, 2.2), -100)
	_add(p, CampX.chair(2, 94), Vector3(0.0, 0, -0.2), 180)
	_add(p, Camp.stool(2, 95), Vector3(1.5, 0, 5.3), 200)
	_add(p, CampX.table("trestle", 96), Vector3(-3.6, 0, 5.5), 95)
	var u := CampX.utensils(97)
	_add(p, u, Vector3(-3.6, 0.78, 5.5), 70)
	_add(p, CampX.chair(0, 98), Vector3(-2.3, 0, 5.4), -90)
	_add(p, CampX.chair(0, 99), Vector3(-5.0, 0, 5.6), 85)
	_add(p, CampX.meat_rack(100), Vector3(4.4, 0, 4.4), -20)
	_add(p, Camp.tripod_pot(101), Vector3(-3.0, 0, 1.2))
	_add(p, Camp.campfire("ring", 102, true), Vector3(-3.0, 0, 1.2))
	_add(p, StoreX.bucket("water", 103), Vector3(2.4, 0, 5.0))
	_add(p, StoreX.basket("turnips", 104), Vector3(1.0, 0, 6.2), 30)
	_add(p, StoreX.basket("bread", 105), Vector3(-0.6, 0, 6.0), -40)


static func _mining_corner(p: Node3D) -> void:
	# track from the east tunnel mouth into the chamber (pieces are 2 m)
	for i in 6:
		_add(p, Mine.track(110 + i), Vector3(6.0, 0, -10.0 + 2.0 * i), 90)
	_add(p, MineX.support_frame(2.4, 2.5, "intact", 111), Vector3(6.0, 0, -11.2))
	_add(p, Mine.mine_cart(true, 112), Vector3(6.0, 0, -5.4), 90)
	_add(p, Mine.mine_cart(false, 113), Vector3(6.0, 0, -0.6), 92)
	_add(p, Mine.ore_pile(1.3, 114), Vector3(9.4, 0, -6.6), 30)
	_add(p, MineX.wheelbarrow(true, 115), Vector3(8.2, 0, -8.4), 35)
	_add(p, MineX.wheelbarrow(false, 116), Vector3(8.4, 0, 1.2), -60)
	_add(p, MineX.winch(117), Vector3(10.6, 0, 4.0), -90)
	_add(p, MineX.pulley(118), Vector3(10.4, 0, -1.3), 180)
	_add(p, MineX.rubble(1.2, 119), Vector3(4.4, 0, -10.4))
	_add(p, MineX.broken_tools(120), Vector3(8.2, 0, -0.6), 40)
	_add(p, Mine.pickaxe(121), Vector3(9.3, 0, -4.2), 70)
	_add(p, Mine.shovel(122), Vector3(8.0, 0, -4.6), -20)
	_add(p, MineX.hammer(123), Vector3(9.6, 0, -9.5), 10)
	_add(p, Mine.rope_coil(124), Vector3(4.8, 0, -2.4))
	_add(p, StoreX.mining_box("tools", 125), Vector3(11.1, 0, -7.6), -90)
	_add(p, StoreX.mining_box("empty", 126), Vector3(10.2, 0, -10.8), 8)
	_add(p, Props.sign_board("mining", 127), Vector3(6.0, 1.15, -10.9))


static func _storage_and_beds(p: Node3D) -> void:
	# south-east storage corner
	_add(p, Store.barrel_stack(130), Vector3(8.4, 0, 8.8), -25)
	_add(p, Store.crate("large", 131), Vector3(6.2, 0, 10.4), 8)
	_add(p, Store.crate("small", 132), Vector3(6.4, 0.88, 10.3), -20)
	_add(p, Store.crate("broken", 133), Vector3(4.6, 0, 8.4), 40)
	_add(p, Store.barrel("water", 134), Vector3(9.8, 0, 6.3))
	_add(p, Store.barrel("broken", 135), Vector3(7.4, 0, 6.4), 60)
	_add(p, Store.barrel("grain", 136), Vector3(10.2, 0, 7.4))
	_add(p, Store.sack("grain", 137), Vector3(3.4, 0, 8.3), 10)
	_add(p, Store.sack("slumped", 138), Vector3(2.7, 0, 9.4), 70)
	_add(p, StoreX.chest("broken", 139), Vector3(1.0, 0, 10.6), -10)
	# south-west sleeping corner
	_add(p, CampX.tent(140), Vector3(-6.2, 0, 8.6), 20)
	_add(p, CampX.personal_area(141), Vector3(-9.2, 0, 3.0), 90)
	_add(p, CampX.bedding("straw", 142), Vector3(-8.8, 0, 6.2), 80)
	_add(p, CampX.bedding("blanket", 143), Vector3(-7.4, 0, 3.4), 25)
	_add(p, CampX.bedding("rolled", 144), Vector3(-9.8, 0, 8.6), -30)
	_add(p, CampX.bedding("open", 145), Vector3(-3.0, 0, 8.2), 100)
	_add(p, StoreX.chest("open", 146), Vector3(-1.7, 0, 9.4), 15)
	_add(p, Store.crate("open", 147), Vector3(-0.5, 0, 9.8), -8)
	_add(p, Mine.pickaxe(148), Vector3(-4.0, 0, 10.0), 30)


static func _lighting(p: Node3D) -> void:
	# wall torches along the walls: the main light source
	for x in [-9.0, -3.0, 2.0, 9.0]:
		_add(p, Light.wall_torch("bracket" if int(x) % 2 == 0 else "cresset", true, int(x) + 200), Vector3(x, 2.4, -11.45))
	for z in [-9.0, 2.0, 8.0]:
		_add(p, Light.wall_torch("cresset", true, int(z) + 210), Vector3(-11.5, 2.4, z), 90)
	for z in [-9.0, -1.0, 6.0]:
		_add(p, Light.wall_torch("bracket", true, int(z) + 220), Vector3(11.5, 2.4, z), -90)
	_add(p, Light.wall_torch("bracket", true, 231), Vector3(5.0, 2.4, 11.5), 180)
	_add(p, Light.torch_stand(232), Vector3(4.0, 0, -1.0))
	_add(p, Light.torch_stand(233), Vector3(-7.5, 0, 0.5))
	_add(p, Light.brazier(234), Vector3(-1.8, 0, -2.0))
	_add(p, Light.brazier(235), Vector3(7.0, 0, 7.4))
	# a lantern on a chain over the camp, one on the upper deck
	_add(p, Props.chain(2.4, 236), Vector3(2.4, CEILING, 3.8))
	_add(p, LightX.lantern(true, 237), Vector3(2.4, CEILING - 2.4, 3.8))
	_add(p, LightX.lantern(true, 238), Vector3(-9.45, 3.55, -9.95))
	_add(p, LightX.candles(3, 239), Vector3(-5.5, 2.0 + 0.0, -10.3))
	_add(p, LightX.oil_lamp(240), Vector3(-3.7, 0.78, 5.3))
	_add(p, LightX.candles(1, 241), Vector3(-4.0, 1.0, -10.6))
