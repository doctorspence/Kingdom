extends SceneTree
## One-off: re-lays levels/tithelands/tithelands.tscn to the new layout
## (ZONE1_OVERHAUL.md section 5). Switches the ground to SculptedTerrain and
## the tree/rock/clutter scatter to ForestScatter, moves every place, camp
## and enemy spawn, adds building pads and the village cottages.
##   Godot_console.exe --headless --path . --script res://tools/relayout_tithelands.gd

const SCENE := "res://levels/tithelands/tithelands.tscn"

# name: [x, z, yaw, extras]   extras: pad (Vector2), pad_blend, scale, y_offset
var PLACES := {
	"CrossroadsShrine": [-9, 116, 150, {"pad": Vector2(3, 3), "pad_blend": 2.0}],
	"Camp": [40, 128, 90, {}],
	"Gallows": [-9, 142, 90, {"pad": Vector2(3.6, 2.4), "pad_blend": 2.0}],
	"Signpost": [-12, 114, 60, {}],
	"OldWenna": [16, 104, -68, {}],
	"SoulBroker": [-13, 138, 90, {}],
	"Farm1": [-46, 84, -18, {"pad": Vector2(7.5, 6.5)}],
	"Farm2": [-36, 121, 180, {"pad": Vector2(7.5, 6.5)}],
	"FarmFence1": [-35, 70, 0, {}],
	"FarmFence2": [-29, 70, 0, {}],
	"FarmFence3": [-26, 73.1, 90, {}],
	"FarmFence4": [-26, 79.3, 90, {}],
	"FarmFence5": [-38, 73.1, 90, {}],
	"FarmFence6": [-38, 79.3, 90, {}],
	"FarmFence7": [-42, 126, 90, {}],
	"FarmCart": [-54, 82, 30, {}],
	"Burned1": [-60.6, 70.3, -67, {"pad": Vector2(6.6, 6.0)}],
	"Burned2": [-79.4, 61.7, 113, {"pad": Vector2(6.6, 6.0)}],
	"Burned3": [-86.4, 45.7, 113, {"pad": Vector2(6.6, 6.0)}],
	"HamletCottage": [-69.1, 49.1, -67, {"pad": Vector2(7.5, 6.5)}],
	"HamletCart": [-68.3, 54.2, 203, {}],
	"CheckpointBarricadeW": [-3.2, -113, 0, {}],
	"CheckpointBarricadeE": [3.6, -118, 0, {}],
	"CheckpointTent1": [13, -104, -90, {}],
	"CheckpointTent2": [-13, -102, 90, {}],
	"TitheBarn": [24, -50, -90, {"pad": Vector2(11.5, 17)}],
	"Bridge": [0, 2, -10, {}],
	"Mill": [-104, 3.5, 90, {"pad": Vector2(9, 10.5), "pad_blend": 2.0}],
	"MillShrine": [-80, 20, 120, {"pad": Vector2(3, 3), "pad_blend": 2.0}],
	"Weir": [-95, -6.66, 8, {}],
	"Chapel": [-49.9, 160, 0, {}],
	"Barrow": [150, -140, -47, {}],
	"HobbTent1": [-111.5, 27, 30, {}],
	"HobbTent2": [-118.5, 34.7, -20, {}],
	"HobbTent3": [-105.2, 37.5, 75, {}],
	"HobbBarricade": [-106, 27, 40, {}],
	"HobbBarrel1": [-108.5, 38, 0, {}],
	"HobbBarrel2": [-107.6, 38.9, 0, {}],
	"HobbCart": [-111, 41.5, 90, {}],
	"HobbPalisade": [-127, 30, 90, {}],
	"Watchtower": [105, 26, 0, {}],
	"TowerWall0": [120, 26, 90, {}],
	"TowerWall1": [115.6, 15.39, 135, {}],
	"TowerWall3": [94.39, 15.39, 225, {}],
	"TowerWall4": [90, 26, 270, {}],
	"TowerWall5": [94.39, 36.6, 315, {}],
	"TowerWall7": [115.6, 36.6, 405, {}],
	"QuarryShrine": [-118, -92, 90, {"pad": Vector2(3, 3), "pad_blend": 2.0}],
	"GulletMouth": [-169, -98, 90, {}],
	"GulletDoor": [-166.5, -98, 90, {}],
	"QuarryRock1": [-160, -90, 20, {"scale": 1.8}],
	"QuarryRock2": [-156, -106, 70, {"scale": 1.5}],
	"QuarryRock3": [-149, -108, 140, {"scale": 1.2}],
	"QuarryRock4": [-146, -90, 10, {"scale": 1.0}],
	"QuarryRock5": [-131, -86, 100, {"scale": 1.4}],
	"RoadCart1": [15, 64, 175, {}],
	"RoadCart2": [-9.5, 28, -15, {}],
	"RoadCart3": [12, -30, 180, {}],
	"RoadCart4": [-29, 116, 70, {}],
	"ForkSign1": [9, 107, -20, {}],
	"ForkSign2": [-84, 12, 40, {}],
	"ForkSign3": [57, 103, -140, {}],
	"HamletGallows": [-76.6, 73.5, 23, {"pad": Vector2(3.6, 2.4), "pad_blend": 2.0}],
	"CheckpointGallows": [-12, -97, 100, {}],
	"WoodsTentS": [90, 90, 40, {}],
	"WoodsCartS": [99, 82, 120, {}],
	"WoodsBarricadeM": [58, -50, 60, {}],
	"WoodsTentM": [68, -60, 200, {}],
	"WoodsTentN": [106, -46, 150, {}],
	"WoodsBarricadeN": [96, -47, 0, {}],
	"FordBarricade": [34, -29, 40, {}],
	"FordTent": [25, -37, 30, {}],
	"MillCart": [-96, 14, 20, {}],
	"QuarryTent": [-142, -88, 80, {}],
	"QuarryBarricade": [-135, -86, 60, {}],
	"TowerGate": [105, 41, 0, {}],
	"QuarryLadder": [-150, -85.5, 180, {}],
	"WoodsFireS": [94, 86, 0, {}],
	"WoodsFireM": [64, -55, 0, {}],
	"WoodsFireN": [102, -51, 0, {}],
	"WoodsSeatM": [61.5, -53.5, 60, {}],
	"WoodsCrateN": [105, -55, 30, {}],
	"FordTrophy": [41, -22, -60, {}],
	"CheckpointPaving": [0, -112, 0, {}],
	"CheckpointPaving2": [0, -104, 0, {}],
	"CrossroadsPaving": [-9, 116, 0, {"scale3": Vector3(0.45, 1, 0.45)}],
}

# Camps moved as a whole: prefix -> offset.
var SHIFTS := {"Hobb": Vector2(-6.5, 9.5), "Ford": Vector2(-1.5, -20.5)}

# New cottages around the village green.
var NEW_COTTAGES := {
	"VillageW": [-24, 96, 51],
	"VillageE": [18, 98, -55],
	"VillageS": [-20, 124, 127],
}

var SPAWNS := {
	"RoadPatrol": [5, 32, PackedVector3Array([Vector3(0, 0, 0), Vector3(2, 0, 30), Vector3(1, 0, -22)])],
	"Checkpoint": [0, -110], "CheckpointExtra": [8, -116],
	"TitheBarn": [13, -46], "TitheBarnPatrol": [8, -28, PackedVector3Array([Vector3(0, 0, 0), Vector3(-4, 0, -20), Vector3(-8, 0, -42)])],
	"Farms": [-40, 92], "Hamlet": [-72, 60], "HamletExtra": [-74, 44], "HamletEdge": [-90, 58],
	"Mill": [-92, 6], "HobbCamp": [-112.2, 30.5], "HobbCampBack": [-118.5, 38.9],
	"WoodsSouth": [93, 85], "WoodsMid": [65, -54], "WoodsNorth": [101, -50],
	"TowerYard": [99, 30], "TowerOutside": [105, 47],
	"QuarryRim": [-152, -72], "QuarryFloor": [-148, -98], "QuarryDeep": [-163, -106],
	"BridgeGuard": [10, 14], "RoadMid": [6, 46], "HamletRoad": [-52, 96], "FordCamp": [28, -32],
	"NorthRoad": [6, -62], "MillRoad": [-84, 30], "QuarryRoad": [-116, -62], "WoodsRoad": [60, 88], "FarmEdge": [-30, 88],
}


func _initialize() -> void:
	var packed: PackedScene = load(SCENE)
	var root: Node = packed.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	# --- ground ---
	var terrain: Node3D = root.get_node("Terrain")
	var first_run := (terrain.get_script() as Script).resource_path != "res://game/world/sculpted_terrain.gd"
	var tmat = terrain.get("material")
	var wmat = terrain.get("water_material")
	terrain.set_script(load("res://game/world/sculpted_terrain.gd"))
	terrain.set("zone_id", &"tithelands")
	terrain.set("zone_name", "The Tithelands")
	terrain.set("size", 364.0)
	terrain.set("cell", 1.0)
	terrain.set("material", tmat)
	terrain.set("water_material", wmat)
	terrain.set("land_script", load("res://levels/tithelands/tithelands_land.gd"))
	terrain.set("pad_root", NodePath("../Places"))
	# --- places ---
	var places: Node3D = root.get_node("Places")
	for n in PLACES:
		var node := places.get_node_or_null(n) as Node3D
		if node == null:
			push_error("missing place " + n)
			continue
		var d: Array = PLACES[n]
		node.position = Vector3(d[0], 0, d[1])
		node.rotation_degrees = Vector3(0, d[2], 0)
		var ex: Dictionary = d[3]
		if ex.has("pad"):
			node.set_meta("pad", ex.pad)
		if ex.has("pad_blend"):
			node.set_meta("pad_blend", ex.pad_blend)
		if ex.has("scale"):
			node.scale = Vector3.ONE * float(ex.scale)
		if ex.has("scale3"):
			node.scale = ex.scale3
	for c in places.get_children():
		for prefix in SHIFTS:
			if first_run and String(c.name).begins_with(prefix) and not PLACES.has(String(c.name)):
				var off: Vector2 = SHIFTS[prefix]
				c.position += Vector3(off.x, 0, off.y)
	var ladder := places.get_node("QuarryLadder")
	ladder.set("top_ground_point", Vector3(0, 0, -7))
	var cottage: PackedScene = load("res://levels/tithelands/props/cottage.tscn")
	for n in NEW_COTTAGES:
		if places.has_node(n):
			continue
		var c := cottage.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node3D
		c.name = n
		var d: Array = NEW_COTTAGES[n]
		c.position = Vector3(d[0], 0, d[1])
		c.rotation_degrees = Vector3(0, d[2], 0)
		c.set_meta("pad", Vector2(7.5, 6.5))
		places.add_child(c)
		c.owner = root
	# --- enemy spawns ---
	var spawns := root.get_node("EnemySpawns")
	for n in SPAWNS:
		var sp := spawns.get_node_or_null(n) as Node3D
		if sp == null:
			push_error("missing spawn " + n)
			continue
		var d: Array = SPAWNS[n]
		sp.position = Vector3(d[0], 0, d[1])
		if d.size() > 2:
			sp.set("patrol", d[2])
	# --- woods, rocks, clutter ---
	var tree_pine: PackedScene = load("res://levels/tithelands/props/tree_pine.tscn")
	var tree_dead: PackedScene = load("res://levels/tithelands/props/tree_dead.tscn")
	var rock: PackedScene = load("res://levels/tithelands/props/rock.tscn")
	var fs := load("res://game/world/forest_scatter.gd")
	var woods: Node3D = root.get_node("Woods")
	woods.set_script(fs)
	woods.set("terrain", terrain)
	# The Greenwood: species, variants and landmark trees come from the land script (tree_kind, landmark_trees).
	woods.set("scenes", [load("res://levels/tithelands/props/tree_oak.tscn")] as Array[PackedScene])
	woods.set("weights", PackedFloat32Array())
	woods.set("species_from_land", true)
	woods.set("landmarks", true)
	woods.set("leaf_shadows", true)
	woods.set("spacing", 5.0)
	woods.set("scatter_seed", 11)
	woods.set("keep_off_roads", 6.5)
	woods.set("keep_off_tracks", 2.5)
	woods.set("scale_range", Vector2(0.85, 1.2))
	woods.set("beyond_edge", 40.0)
	woods.set("max_slope", 0.8)
	woods.set("layer", "woodland")
	var oaks := root.get_node_or_null("Oaks") as Node3D
	if oaks == null:
		oaks = Node3D.new()
		oaks.name = "Oaks"
		oaks.set_script(fs)
		root.add_child(oaks)
		oaks.owner = root
	oaks.set("terrain", terrain)
	oaks.set("scenes", [load("res://levels/tithelands/props/tree_oak.tscn")] as Array[PackedScene])
	oaks.set("layer", "lone_trees")
	oaks.set("species_from_land", true)
	oaks.set("spacing", 7.0)
	oaks.set("scatter_seed", 77)
	oaks.set("keep_off_roads", 7.0)
	oaks.set("keep_off_tracks", 3.5)
	oaks.set("scale_range", Vector2(0.85, 1.25))
	oaks.set("beyond_edge", 40.0)
	oaks.set("max_slope", 0.7)
	oaks.set("leaf_shadows", true)
	var farm := root.get_node_or_null("FarmTrees")
	if farm:
		root.remove_child(farm)
		farm.free()
	var rocks: Node3D = root.get_node("Rocks")
	rocks.set_script(fs)
	rocks.set("terrain", terrain)
	rocks.set("scenes", [rock] as Array[PackedScene])
	rocks.set("layer", "rocks")
	rocks.set("spacing", 7.0)
	rocks.set("scatter_seed", 5)
	rocks.set("keep_off_roads", 4.5)
	rocks.set("scale_range", Vector2(0.6, 2.0))
	rocks.set("max_slope", 2.0)
	rocks.set("sink", 0.35)
	var clutter: Node3D = root.get_node("Clutter")
	var cl_scenes = clutter.get("scenes")
	clutter.set_script(fs)
	clutter.set("terrain", terrain)
	clutter.set("scenes", cl_scenes)
	clutter.set("layer", "clutter")
	clutter.set("spacing", 7.0)
	clutter.set("scatter_seed", 41)
	clutter.set("keep_off_roads", 3.2)
	clutter.set("keep_off_tracks", 1.5)
	clutter.set("scale_range", Vector2(0.7, 1.5))
	clutter.set("sink", 0.05)
	# --- stone walls and set dressing ---
	if not root.has_node("StoneWalls"):
		var sw := Node3D.new()
		sw.name = "StoneWalls"
		sw.set_script(load("res://game/world/stone_walls.gd"))
		root.add_child(sw)
		sw.owner = root
		sw.set("terrain", terrain)
	if not root.has_node("Dressing"):
		var dr := Node3D.new()
		dr.name = "Dressing"
		dr.set_script(load("res://game/world/set_dressing.gd"))
		root.add_child(dr)
		dr.owner = root
		dr.set("terrain", terrain)
		dr.set("dressing_script", load("res://levels/tithelands/tithelands_dressing.gd"))
	# --- scanned plants and rocks (Poly Haven, CC0) ---
	var ps := load("res://game/world/plant_scatter.gd")
	var plants := [
		# name, models, layer, spacing, scale range, target size, collide, shadows, seen from, extra
		["Shrubs", ["shrub_02"], "undergrowth", 4.0, Vector2(0.55, 1.05), 0.0, false, true, 110.0, {}],
		["Ferns", ["fern_02"], "ferns", 2.2, Vector2(1.0, 1.8), 0.0, false, false, 70.0, {}],
		["Weeds", ["nettle_plant", "weed_plant_02", "shrub_03"], "weeds", 2.4, Vector2(0.7, 1.4), 0.55, false, false, 55.0, {}],
		["Boulders", ["rock_moss_set_01", "rock_moss_set_02"], "rocks", 6.0, Vector2(0.5, 1.5), 0.0, true, true, 170.0, {"sink": 0.15}],
		["CliffFaces", ["rock_face_01", "rock_face_02"], "cliffs", 4.0, Vector2(1.0, 2.2), 0.0, false, true, 230.0, {"cliff": 0.7, "keep_off_roads": 5.0, "tint": Color(0.5, 0.5, 0.52)}],
		["Deadwood", ["tree_stump_01", "tree_stump_02", "dead_tree_trunk", "dry_branches_medium_01"], "deadwood", 8.0, Vector2(0.8, 1.2), 0.0, true, true, 90.0, {}],
	]
	for p in plants:
		var node := root.get_node_or_null(p[0]) as Node3D
		if node == null:
			node = Node3D.new()
			node.name = p[0]
			node.set_script(ps)
			root.add_child(node)
			node.owner = root
		node.set("terrain", terrain)
		node.set("models", PackedStringArray(p[1]))
		node.set("layer", p[2])
		node.set("spacing", p[3])
		node.set("scale_range", p[4])
		node.set("target_size", p[5])
		node.set("collide", p[6])
		node.set("shadows", p[7])
		node.set("seen_from", p[8])
		node.set("scatter_seed", hash(p[0]) % 1000)
		for k in p[9]:
			node.set(k, p[9][k])
	root.get_node("TitheExtras").set("code_ferns", false)
	rocks.set("density", 0.45)
	clutter.set("density", 0.5)
	var cull := root.get_node_or_null("UndergroundCull")
	if cull:
		var surf: Array[NodePath] = []
		for n in ["Woods", "Oaks", "Grass", "Clutter", "Rocks", "Highcrown", "StoneWalls", "Dressing", "Shrubs", "Ferns", "Weeds", "Boulders", "CliffFaces", "Deadwood"]:
			surf.append(NodePath("../" + n))
		cull.set("surface", surf)
	# --- the rest ---
	(root.get_node("Highcrown") as Node3D).position = Vector3(0, 0, -255)
	root.get_node("TitheExtras").set("checkpoint_shift", -34.0)
	var out := PackedScene.new()
	var err := out.pack(root)
	if err != OK:
		push_error("pack failed %d" % err)
		quit(1)
		return
	err = ResourceSaver.save(out, SCENE)
	print("saved: ", err)
	root.free()
	quit(0)
