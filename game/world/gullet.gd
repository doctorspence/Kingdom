class_name Gullet
extends Node3D
## The Gullet: an abandoned quarry held by bandits (GULLET_DESIGN.md, floor plan in
## GULLET_MAP.svg). Built from a block of rock with rooms and tunnels carved out.
## Local meters: x east, z south, the ground floor is y = 0.
## Map pixels convert as x = (px - 700) / 10, z = (py - 430) / 10.
##
##   1 Entrance yard   2 Old tunnels   3 Bandit camp (two stories)   4 Shrine alcove
##   5 The Excavation (two stories)   6 Deep chamber (boss)
## A small river runs through the camp and the Excavation.

const STONE := "res://levels/common/materials/dark_stone.tres"
const WOOD := "res://levels/common/materials/wood.tres"
const DARK_WOOD := "res://levels/common/materials/dark_wood.tres"

## Carved space: [x0, z0, x1, z1, height, floor y (optional, default 0)]
const CARVES := [
	[-59, 16, -42, 34, 6],            # 1 entrance yard
	[-43.5, 23, -25, 27, 3.8],        # 2 tunnel: yard to the first bend
	[-29, 11, -25, 27, 3.8],          #   up the long hall
	[-41, 11, -25, 15, 3.8],          #   west along the bottom of the loop
	[-41, -7, -37, 15, 3.8],          #   north up the west side
	[-41, -7, -14, -3, 3.8],          #   east to the camp's west door
	[-28, 11.3, -16.3, 14.7, 3.6],    #   barricade route: east...
	[-19.7, -6.7, -16.3, 14.7, 3.6],  #   ...and north to the camp door
	[-35, 7.5, -30.8, 11.5, 4.0],     #   the nook for the archer
	[-50, 2.3, -37, 5.7, 3.6],        #   branch to the hidden chest (secret wall at x -45)
	[-57, 1, -48.5, 7, 4.5],          #   hidden chest room
	[-14.5, -19, 27.5, 9, 10.0],      # 3 bandit camp (ground floor, upper walkway inside it)
	[27, -4.2, 31.5, 0.2, 3.8],       #   east corridor to the Excavation
	[15.3, 8, 18.7, 15.8, 3.8],       #   south to the shrine
	[9, 14.2, 25, 21, 5.0],           # 4 shrine alcove
	[25, -18, 33.5, -14, 7.2, 2.0],   #   rope bridge passage (upper level)
	[30, -28, 68, 5, 11.0],           # 5 the Excavation
	[47, 3.5, 51, 24, 3.8],           #   corridor south to the fog gate
	[6, 23.2, 59, 41, 9.0],           # 6 deep chamber
	[-43.5, 28.5, 6.5, 31.5, 3.6],    #   shortcut back to the entrance (opens after the boss)
]
## Rock around everything: center x, y, z, then size.
const ROCK := [0.0, 6.0, 0.0, 150.0, 18.0, 100.0]

## Wooden walkways: [x0, z0, x1, z1, top y]. 0.4 thick.
const DECKS := [
	[-12.5, -18.6, 25.5, -13.4, 4.0],   # camp: upper walkway
	[32.5, -27.2, 66.0, -21.5, 4.0],    # Excavation: north gallery
	[32.5, -27.2, 37.5, -10.5, 4.0],    # Excavation: west gallery
	[25.4, -16.6, 32.6, -15.2, 4.0],    # the rope bridge deck
]

## The river, in two lengths with a hidden culvert between. [points], width.
const RIVER := [
	[[16, -18.8], [15.2, -13], [17.5, -8], [19, -3.5], [22.5, -1.2], [26, -0.7], [29, -0.7], [31.5, -0.7],
	[34, 0.3], [38, 1.8], [43, 2.4], [49, 1.4], [55, 2.6], [61, 2.0], [66, 3.4]],
]
const RIVER_WIDTH := 1.9

## Torch and fire lights, in map pixels: [px, py, brightness, height]
const LIGHTS := [
	[120, 612, 0.8, 2.2], [255, 612, 0.8, 2.2], [440, 575, 0.6, 2.2], [300, 395, 0.6, 2.2], [545, 372, 0.6, 2.2],
	[1000, 402, 0.6, 2.2], [590, 262, 0.9, 5.8], [945, 262, 0.9, 5.8], [575, 500, 0.9, 3.5], [950, 500, 0.9, 3.5],
	[1045, 178, 0.9, 5.8], [1350, 178, 0.9, 5.8], [1040, 460, 0.9, 3.5], [1350, 455, 0.9, 3.5], [1190, 490, 0.5, 2.2],
	[1190, 570, 0.5, 2.2], [520, 430, 0.5, 2.2], [1190, 636, 0.6, 2.2], [785, 820, 0.8, 3.0], [1270, 700, 0.8, 3.0],
	[240, 730, 0.4, 2.2], [900, 606, 1.0, 2.5], [1090, 330, 0.8, 3.5], [1000, 740, 0.6, 4.0],
]

## Pillars in the deep chamber (cover from Harl's Black Shard): map pixels.
const PILLARS := [[880, 700], [880, 800], [1080, 690], [1080, 810], [1200, 730], [960, 750]]


## Ceiling holes: [x, z, radius, ceiling y at that spot]
const SHAFTS := [
	[-51.0, 25.0, 3.0, 6.0],   # entrance yard
	[-4.0, -4.0, 2.4, 10.0],   # camp
	[14.0, -10.0, 2.0, 10.0],  # camp, east end
	[44.0, -12.0, 3.2, 11.0],  # Excavation, west
	[60.0, -8.0, 2.6, 11.0],   # Excavation, east
	[30.0, 32.0, 2.4, 9.0],    # deep chamber
	[48.0, 36.0, 1.8, 9.0],    # deep chamber, east
	[16.0, 18.0, 1.4, 5.0],    # shrine
]


static func px(x: float, y: float) -> Vector3:
	return Vector3((x - 700.0) * 0.1, 0.0, (y - 430.0) * 0.1)


func _ready() -> void:
	var combiner := CSGCombiner3D.new()
	combiner.use_collision = true
	var mat: Material = load(STONE)
	var rock := CSGBox3D.new()
	rock.position = Vector3(ROCK[0], ROCK[1], ROCK[2])
	rock.size = Vector3(ROCK[3], ROCK[4], ROCK[5])
	rock.material = mat
	combiner.add_child(rock)
	for c in CARVES:
		var y0: float = c[5] if c.size() > 5 else 0.0
		var box := CSGBox3D.new()
		box.operation = CSGShape3D.OPERATION_SUBTRACTION
		box.position = Vector3((c[0] + c[2]) * 0.5, y0 + (c[4] - y0) * 0.5, (c[1] + c[3]) * 0.5)
		box.size = Vector3(c[2] - c[0], c[4] - y0, c[3] - c[1])
		box.material = mat
		combiner.add_child(box)
	var wood: Material = load(WOOD)
	for d in DECKS:
		var slab := CSGBox3D.new()
		slab.position = Vector3((d[0] + d[2]) * 0.5, d[4] - 0.2, (d[1] + d[3]) * 0.5)
		slab.size = Vector3(d[2] - d[0], 0.4, d[3] - d[1])
		slab.material = wood
		combiner.add_child(slab)
	# Deep chamber pillars.
	for p in PILLARS:
		var v := px(p[0], p[1])
		var pillar := CSGBox3D.new()
		pillar.position = Vector3(v.x, 4.5, v.z)
		pillar.size = Vector3(2.0, 9.0, 2.0)
		pillar.material = mat
		combiner.add_child(pillar)
	# Holes in the cave ceiling: daylight (cool blue) falls through them.
	for s in SHAFTS:
		var hole := CSGCylinder3D.new()
		hole.operation = CSGShape3D.OPERATION_SUBTRACTION
		hole.radius = s[2]
		hole.height = 20.0
		hole.sides = 9
		hole.position = Vector3(s[0], s[3] + 9.0, s[1])
		hole.rotation = Vector3(deg_to_rad(randf_range(-4, 4)), 0.0, deg_to_rad(randf_range(-4, 4)))
		hole.material = mat
		combiner.add_child(hole)
	add_child(combiner)

	_roughen(combiner)
	_build_cave_detail(mat)
	_build_shafts()
	_build_timbers()
	_build_excavation_light()
	_build_room_glow()
	_build_rails()
	_build_scaffolds()
	_build_atmosphere()
	_build_falls()
	_build_camp()
	_build_dig_dressing()
	_build_props()
	_build_cave_assets()
	_light_stairs()
	_build_realism()
	_build_river()
	_build_lights()
	_build_stairs_and_ladders()


## Rope rails on both sides of the bridge (solid, so nobody walks off it).
func _build_rails() -> void:
	for z in [-16.65, -15.15]:
		var rail := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(7.2, 1.0, 0.1)
		cs.shape = box
		rail.add_child(cs)
		rail.position = Vector3(29.0, 4.5, z)
		add_child(rail)
		# Posts every 1.2 m with a wooden top rail and a rope rail below it.
		for k in 7:
			_timber(Vector3(25.6 + k * 1.2, 4.55, z), 1.1, 0.1, 0.1, 1)
		_timber(Vector3(29.0, 5.08, z), 7.2, 0.07, 0.1, 0)
		var rope := _timber(Vector3(29.0, 4.55, z), 7.2, 0.035, 0.035, 0)
		rope.material_override = _rope()


func _box(pos: Vector3, size: Vector3, color: Color, rot_y := 0.0, solid := true, wooden := false) -> Node3D:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	bm.material = _wood_pick() if wooden else m
	mi.mesh = bm
	body.add_child(mi)
	if solid:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		body.add_child(cs)
	body.position = pos + Vector3(0, size.y * 0.5, 0)
	body.rotation.y = rot_y
	add_child(body)
	return body


## Crates, carts, bedrolls and the black stone: graybox set dressing.
func _build_props() -> void:
	# Entrance yard: broken barricade, carts.
	_asset("Wooden_Structures/barricade", px(160, 600), 0.3, true)
	_asset("Mining_Equipment/mine_cart_empty", px(200, 700), 0.8, true)
	_asset("Storage_Containers/crate_large", px(240, 650), 0.0, true)
	_asset("Storage_Containers/barrel_small", px(255, 640) + Vector3(0.6, 0, 0.8), 0.0, true)
	_asset("Storage_Containers/crate_broken", px(180, 680), 1.1)
	var crate_kinds := ["crate_large", "crate_small", "crate_open", "barrel_small", "crate_large", "crate_broken"]
	for ci in 6:
		var pp: Array = [[600, 500], [620, 505], [610, 480], [930, 500], [945, 480], [660, 255]][ci]
		_asset("Storage_Containers/" + crate_kinds[ci], px(pp[0], pp[1]), randf() * 3.0, ci != 5)
	for p in [[620, 440], [640, 455], [690, 500]]:
		_asset("Camp_Equipment/bedding_open", px(p[0], p[1]), 0.4)
	# Excavation: an ore cart and the black stone formations (shard crystals).
	_shards(px(1090, 380), 0.8, 11)
	_shards(px(1340, 420), 0.7, 23)
	# Deep chamber: the exposed black stone in the south wall, and rubble.
	_shards(px(1000, 820), 1.6, 5)
	for p in [[830, 720], [900, 780], [1130, 770], [1150, 700], [990, 700]]:
		var c := px(p[0], p[1])
		for k in 7:
			_rock_chunk(c + Vector3(randf_range(-1.2, 1.2), 0.2, randf_range(-1.2, 1.2)), randf_range(0.25, 0.7))


## Blue daylight pouring through each ceiling hole: a spotlight, a faint glowing
## shaft, and a cool fill light near the floor so the rooms are not black.
func _build_shafts() -> void:
	var shaft_mat := StandardMaterial3D.new()
	shaft_mat.albedo_color = Color(0.5, 0.75, 1.0, 0.022)
	shaft_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shaft_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shaft_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shaft_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	for s in SHAFTS:
		var top: float = s[3]
		var spot := SpotLight3D.new()
		spot.position = Vector3(s[0], top + 1.5, s[1])
		spot.rotation_degrees = Vector3(-90, 0, 0)
		spot.light_color = Color(0.45, 0.7, 1.0)
		spot.light_energy = 14.0
		spot.spot_range = top + 6.0
		spot.spot_angle = 26.0
		spot.spot_angle_attenuation = 0.6
		spot.shadow_enabled = true
		add_child(spot)
		var fill := OmniLight3D.new()
		fill.position = Vector3(s[0], 1.6, s[1])
		fill.light_color = Color(0.4, 0.62, 1.0)
		fill.light_energy = 4.0
		fill.omni_range = 22.0
		add_child(fill)
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = s[2] * 0.9
		cm.bottom_radius = s[2] * 1.8
		cm.height = top
		cm.radial_segments = 12
		cm.material = shaft_mat
		cone.mesh = cm
		cone.position = Vector3(s[0], top * 0.5, s[1])
		cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(cone)


## Roughs up the straight carved walls: jagged boulders and slabs jutting from every
## wall, stalagmites on the floor, stalactites hanging from the ceiling.
func _build_cave_detail(mat: Material) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var tint := StandardMaterial3D.new()
	tint.albedo_color = Color(0.62, 0.6, 0.58)
	tint.albedo_texture = (mat as StandardMaterial3D).albedo_texture
	tint.normal_enabled = true
	tint.normal_texture = (mat as StandardMaterial3D).normal_texture
	tint.uv1_scale = Vector3(0.5, 0.5, 0.5)
	tint.uv1_triplanar = true
	tint.roughness = 0.85
	for c in CARVES:
		var y0: float = c[5] if c.size() > 5 else 0.0
		var hgt: float = c[4] - y0
		var w: float = c[2] - c[0]
		var d: float = c[3] - c[1]
		var area := w * d
		# Wall chunks along the four walls.
		var steps_x := maxi(1, int(w / 2.2))
		var steps_z := maxi(1, int(d / 2.2))
		for side in 4:
			var n := steps_x if side < 2 else steps_z
			for i in n:
				var t := (i + rng.randf()) / float(n)
				var pos: Vector3
				var out: Vector3
				match side:
					0: pos = Vector3(c[0] + w * t, 0, c[1]); out = Vector3(0, 0, -1)
					1: pos = Vector3(c[0] + w * t, 0, c[3]); out = Vector3(0, 0, 1)
					2: pos = Vector3(c[0], 0, c[1] + d * t); out = Vector3(-1, 0, 0)
					_: pos = Vector3(c[2], 0, c[1] + d * t); out = Vector3(1, 0, 0)
				for k in 0:
					var rock := MeshInstance3D.new()
					var sm := SphereMesh.new()
					sm.radial_segments = 6
					sm.rings = 3
					sm.material = tint
					rock.mesh = sm
					var r := rng.randf_range(0.5, 1.5) * clampf(hgt / 4.0, 0.8, 1.8)
					rock.scale = Vector3(r * rng.randf_range(0.7, 1.4), r * rng.randf_range(1.0, 2.6), r * rng.randf_range(0.7, 1.4))
					rock.rotation = Vector3(rng.randf() * 0.6, rng.randf() * TAU, rng.randf() * 0.6)
					rock.position = pos + Vector3(0, y0 + rng.randf() * hgt, 0) + out * rng.randf_range(0.55, 0.9) * r * 1.2
					add_child(rock)
		# Stalagmites and stalactites inside the bigger rooms, kept near the walls.
		var count := clampi(int(area / 40.0), 0, 14) if minf(w, d) >= 8.0 else 0
		for i in count:
			var onwall := rng.randi() % 4
			var sx := rng.randf_range(c[0] + 0.5, c[2] - 0.5)
			var sz := rng.randf_range(c[1] + 0.5, c[3] - 0.5)
			match onwall:
				0: sz = c[1] + rng.randf_range(0.5, 1.4)
				1: sz = c[3] - rng.randf_range(0.5, 1.4)
				2: sx = c[0] + rng.randf_range(0.5, 1.4)
				_: sx = c[2] - rng.randf_range(0.5, 1.4)
			var up := rng.randf() < 0.5
			var kind := "stalagmites" if up else "stalactites"
			_asset("Cave_Geometry/" + kind, Vector3(sx, y0 if up else c[4] - 0.15, sz), rng.randf() * TAU, false, rng.randf_range(0.7, 1.3))


func _build_river() -> void:
	for path in RIVER:
		var stream := WaterStream.new()
		var pts := PackedVector3Array()
		for p in path:
			pts.append(Vector3(p[0], 0.0, p[1]))
		stream.points = pts
		stream.width = RIVER_WIDTH
		stream.shader_material = _water_material()
		add_child(stream)
		# Smooth wet stones along the banks.
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var side := (b - a).cross(Vector3.UP).normalized()
			for k in 4:
				var base := a.lerp(b, rng.randf())
				var sgn := 1.0 if rng.randf() < 0.5 else -1.0
				_rock_chunk(base + side * sgn * (RIVER_WIDTH * 0.5 + rng.randf_range(0.0, 0.3)) + Vector3(0, 0.1, 0), rng.randf_range(0.15, 0.4))


func _build_lights() -> void:
	for l in LIGHTS:
		var v := px(l[0], l[1])
		var light := OmniLight3D.new()
		light.position = Vector3(v.x, l[3], v.z)
		light.light_color = Color(1.0, 0.68, 0.38)
		light.light_energy = l[2] * 5.5
		light.omni_range = 16.0
		light.omni_attenuation = 1.4
		add_child(light)
	var fire := Campfire.new()
	fire.position = px(765, 400)
	fire.light_energy = 3.6
	fire.light_range = 18.0
	add_child(fire)


func _build_stairs_and_ladders() -> void:
	# West stairs up to the camp walkway: 20 steps, 4 m up, running north.
	var stairs := GrayboxStairs.new()
	stairs.steps = 20
	stairs.rise = 0.2
	stairs.tread = 0.36
	stairs.width = 3.4
	stairs.material = _wood_pick()
	stairs.position = Vector3(-10.5, 0.0, -6.0)
	stairs.rotation_degrees = Vector3(0, 90, 0)
	add_child(stairs)
	# East ladder up to the camp walkway.
	_ladder(Vector3(23.2, 0.0, -13.0))
	# Ladder at the east end of the Excavation's north gallery.
	_ladder(Vector3(64.2, 0.0, -21.0))


func _ladder(at: Vector3) -> void:
	var l := Ladder.new()
	l.height = 4.0
	l.top_exit = Vector3(0, 4.0, -0.9)
	l.position = at
	add_child(l)


## A dim cool glow in the middle of every carved room, so no room is pitch black.
func _build_room_glow() -> void:
	for c in CARVES:
		var y0: float = c[5] if c.size() > 5 else 0.0
		var l := OmniLight3D.new()
		l.position = Vector3((c[0] + c[2]) * 0.5, y0 + minf(c[4] - y0, 6.0) * 0.6, (c[1] + c[3]) * 0.5)
		l.light_color = Color(0.75, 0.62, 0.5)
		l.light_energy = 4.5
		l.omni_range = clampf(maxf(c[2] - c[0], c[3] - c[1]) * 0.7, 9.0, 30.0)
		add_child(l)


# ---- Rough cave surface -------------------------------------------------------
# The carved rock is made of big flat boxes. After it is built, its stone faces are
# chopped into small triangles and pushed (toward the inside of the room only) by
# noise, so walls, ceilings and floors become lumpy and jagged. The pushed mesh is
# also the walkable collision. The flat rock stays behind it, so there are no holes.

const ROUGH_EDGE := 1.2

var _noise_a := FastNoiseLite.new()
var _noise_b := FastNoiseLite.new()
var _noise_l := FastNoiseLite.new()

func _rough_at(p: Vector3) -> float:
	# Three scales: wide flowing hollows and swells, medium fractured ridges, small grit.
	var big := _noise_l.get_noise_3dv(p)
	var ridge := 1.0 - absf(_noise_a.get_noise_3dv(p))
	ridge = ridge * ridge * 1.4 - 0.5
	var grit := _noise_b.get_noise_3dv(p)
	return clampf(0.75 * big + 0.45 * ridge + 0.2 * grit, -1.0, 1.0)


func _roughen(combiner: CSGCombiner3D) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var baked: ArrayMesh = combiner.bake_static_mesh()
	if baked == null or baked.get_surface_count() == 0:
		return
	_noise_a.seed = 7
	_noise_a.frequency = 0.26
	_noise_l.seed = 3
	_noise_l.frequency = 0.085
	_noise_b.seed = 19
	_noise_b.frequency = 0.9
	var wood_mesh := ArrayMesh.new()
	var rock_verts := PackedVector3Array()
	var rock_norms := PackedVector3Array()
	var collide := PackedVector3Array()
	var back_v := PackedVector3Array()
	var back_n := PackedVector3Array()
	var cut_v := PackedVector3Array()
	var cut_n := PackedVector3Array()
	var cut_amp := PackedFloat32Array()
	var cut_sign := PackedFloat32Array()
	for s in baked.get_surface_count():
		var arr := baked.surface_get_arrays(s)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var idx = arr[Mesh.ARRAY_INDEX]
		var m := baked.surface_get_material(s)
		var is_stone := m != null and m.resource_path == STONE
		if not is_stone:
			wood_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			wood_mesh.surface_set_material(wood_mesh.get_surface_count() - 1, m)
		var count: int = idx.size() if idx != null and idx.size() > 0 else vs.size()
		var i := 0
		while i + 2 < count:
			var ia: int = idx[i] if idx != null and idx.size() > 0 else i
			var ib: int = idx[i + 1] if idx != null and idx.size() > 0 else i + 1
			var ic: int = idx[i + 2] if idx != null and idx.size() > 0 else i + 2
			i += 3
			var a := vs[ia]
			var b := vs[ib]
			var c := vs[ic]
			if not is_stone:
				collide.append_array(PackedVector3Array([a, b, c]))
				continue
			if _on_outer_shell(a, b, c):
				continue
			var n := ns[ia]
			var sign_ := 1.0 if (b - a).cross(c - a).dot(n) >= 0.0 else -1.0
			if not (_in_pillar(a) and _in_pillar(b) and _in_pillar(c)):
				back_v.append_array(PackedVector3Array([a, b, c]))
				back_n.append_array(PackedVector3Array([ns[ia], ns[ib], ns[ic]]))
			var amp := 0.22 if n.y > 0.7 else 2.3
			cut_v.append_array(PackedVector3Array([a, b, c]))
			cut_n.append(n)
			cut_amp.append(amp)
			cut_sign.append(sign_)
	_conform_split(cut_v, cut_n, cut_amp, cut_sign, rock_verts, rock_norms)
	var raw_v := rock_verts
	var raw_n := rock_norms
	rock_verts = PackedVector3Array()
	rock_norms = PackedVector3Array()
	_finish_rough(raw_v, raw_n, rock_verts, rock_norms, collide)
	if rock_verts.is_empty():
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = rock_verts
	arrays[Mesh.ARRAY_NORMAL] = rock_norms
	arrays[Mesh.ARRAY_COLOR] = _tint_colors(rock_verts, false)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _rock_material())
	if not _floor_v.is_empty():
		var farr := []
		farr.resize(Mesh.ARRAY_MAX)
		farr[Mesh.ARRAY_VERTEX] = _floor_v
		farr[Mesh.ARRAY_NORMAL] = _floor_n
		farr[Mesh.ARRAY_COLOR] = _tint_colors(_floor_v, true)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, farr)
		mesh.surface_set_material(1, _floor_material())
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	add_child(mi)
	_build_backing(back_v, back_n)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(collide)
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	combiner.use_collision = false
	combiner.visible = false
	if wood_mesh.get_surface_count() > 0:
		var wmi := MeshInstance3D.new()
		wmi.mesh = wood_mesh
		add_child(wmi)


func _in_pillar(p: Vector3) -> bool:
	for pl in PILLARS:
		var v := px(pl[0], pl[1])
		if absf(p.x - v.x) < 1.05 and absf(p.z - v.z) < 1.05 and p.y < 9.05:
			return true
	return false


## The flat rock, pushed 1.5 m back behind the carved surface (floors 0.5 m down), so any
## crack between displaced triangles at corners and wall/floor seams shows rock, not void.
func _build_backing(bv: PackedVector3Array, bn: PackedVector3Array) -> void:
	var sums := {}
	for i in bv.size():
		var k := _vkey(bv[i])
		sums[k] = sums.get(k, Vector3.ZERO) + bn[i]
	var ov := PackedVector3Array()
	var on := PackedVector3Array()
	for i in bv.size():
		var nn: Vector3 = (sums[_vkey(bv[i])] as Vector3).normalized()
		var off := 0.5 if nn.y > 0.75 else 1.5
		ov.append(bv[i] - nn * off)
		on.append(bn[i])
	if ov.is_empty():
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = ov
	arrays[Mesh.ARRAY_NORMAL] = on
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var fill := StandardMaterial3D.new()
	fill.albedo_color = Color(0.2, 0.15, 0.11)
	fill.emission_enabled = true
	fill.emission = Color(0.2, 0.145, 0.1)
	fill.emission_energy_multiplier = 1.0
	fill.roughness = 1.0
	mesh.surface_set_material(0, fill)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _on_outer_shell(a: Vector3, b: Vector3, c: Vector3) -> bool:
	for axis in 3:
		var lim: float = [ROCK[3] * 0.5, ROCK[1] + ROCK[4] * 0.5, ROCK[5] * 0.5][axis]
		var lo: float = [-ROCK[3] * 0.5, ROCK[1] - ROCK[4] * 0.5, -ROCK[5] * 0.5][axis]
		if (absf(a[axis] - lim) < 0.01 and absf(b[axis] - lim) < 0.01 and absf(c[axis] - lim) < 0.01) \
				or (absf(a[axis] - lo) < 0.01 and absf(b[axis] - lo) < 0.01 and absf(c[axis] - lo) < 0.01):
			return true
	return false


func _push(p: Vector3, n: Vector3, amp: float) -> Vector3:
	var v := _rough_at(p)
	if absf(n.y) > 0.8 and amp < 0.5:
		return p + n * (amp * (v * 0.6 if v > 0.0 else v * 0.2))
	var d := amp * (v * 0.4 if v > 0.0 else v * 0.65)
	if amp > 1.0 and absf(n.y) < 0.5:
		# Rock strata: each layer swells out slowly and drops back sharply, so walls
		# grow shelves and undercut lips like weathered sedimentary rock.
		var t := p.y * 0.55 + _noise_l.get_noise_3dv(p * 1.3) * 1.9
		var f := t - floorf(t)
		var prof := pow(f / 0.78, 1.6) if f < 0.78 else 1.0 - (f - 0.78) / 0.22
		d += (prof - 0.35) * 0.5 * clampf(p.y / 1.2, 0.0, 1.0)
	return p + n * d


func _subdivide(a: Vector3, b: Vector3, c: Vector3, n: Vector3, sign_: float, amp: float,
		out_v: PackedVector3Array, out_n: PackedVector3Array, collide: PackedVector3Array, depth: int) -> void:
	var longest := maxf(a.distance_squared_to(b), maxf(b.distance_squared_to(c), c.distance_squared_to(a)))
	if longest > ROUGH_EDGE * ROUGH_EDGE and depth < 7:
		var ab := (a + b) * 0.5
		var bc := (b + c) * 0.5
		var ca := (c + a) * 0.5
		_subdivide(a, ab, ca, n, sign_, amp, out_v, out_n, collide, depth + 1)
		_subdivide(ab, b, bc, n, sign_, amp, out_v, out_n, collide, depth + 1)
		_subdivide(ca, bc, c, n, sign_, amp, out_v, out_n, collide, depth + 1)
		_subdivide(ab, bc, ca, n, sign_, amp, out_v, out_n, collide, depth + 1)
		return
	out_v.append(a)
	out_v.append(b)
	out_v.append(c)
	out_n.append(n)
	out_n.append(n)
	out_n.append(n)
	_raw_amp.append(amp)
	_raw_sign.append(sign_)


var _raw_amp := PackedFloat32Array()
var _raw_sign := PackedFloat32Array()


func _vkey(p: Vector3) -> Vector3i:
	return Vector3i(roundi(p.x * 50.0), roundi(p.y * 50.0), roundi(p.z * 50.0))


## Second pass: vertices at the same spot move together (along the average of the
## faces that meet there), so corners between walls stay joined.
func _finish_rough(raw_v: PackedVector3Array, raw_n: PackedVector3Array, out_v: PackedVector3Array,
		out_n: PackedVector3Array, collide: PackedVector3Array) -> void:
	var sums := {}
	var amps := {}
	for i in raw_v.size():
		var k := _vkey(raw_v[i])
		sums[k] = sums.get(k, Vector3.ZERO) + raw_n[i]
		amps[k] = maxf(amps.get(k, 0.0), _raw_amp[i / 3])
	var moved := {}
	for i in raw_v.size():
		var k := _vkey(raw_v[i])
		if not moved.has(k):
			var nn: Vector3 = (sums[k] as Vector3).normalized()
			moved[k] = _push(raw_v[i], nn, amps[k])
	var smooth := {}
	var tri_n := PackedVector3Array()
	for t in raw_v.size() / 3:
		var pa: Vector3 = moved[_vkey(raw_v[t * 3])]
		var pb: Vector3 = moved[_vkey(raw_v[t * 3 + 1])]
		var pc: Vector3 = moved[_vkey(raw_v[t * 3 + 2])]
		var fn := (pb - pa).cross(pc - pa) * _raw_sign[t]
		tri_n.append(fn)
		for j in 3:
			var k := _vkey(raw_v[t * 3 + j])
			smooth[k] = smooth.get(k, Vector3.ZERO) + fn
	for t in raw_v.size() / 3:
		for j in 3:
			var k := _vkey(raw_v[t * 3 + j])
			var p: Vector3 = moved[k]
			var sn: Vector3 = (smooth[k] as Vector3).normalized()
			if raw_n[t * 3].y > 0.7:
				_floor_v.append(p)
				_floor_n.append(sn)
			else:
				out_v.append(p)
				out_n.append(sn)
			collide.append(p)


# ---- Timber, scaffolding and set dressing --------------------------------------
# Every timber piece is a long box lying along its length, so the wood grain always
# runs the long way: up and down on posts, along the span on beams and boards.

var _wood_variants: Array[StandardMaterial3D] = []
var _rope_mat: StandardMaterial3D
var _iron_mat: StandardMaterial3D
var _chunk_mat: StandardMaterial3D


func _wood_pick() -> StandardMaterial3D:
	if _wood_variants.is_empty():
		var base := load(WOOD) as StandardMaterial3D
		for tint in [Color(1.15, 0.95, 0.78), Color(0.95, 0.8, 0.66), Color(1.3, 1.05, 0.85),
				Color(0.8, 0.7, 0.6), Color(1.05, 0.9, 0.8)]:
			var m := base.duplicate() as StandardMaterial3D
			m.albedo_color = tint
			m.uv1_scale = Vector3(0.9, 0.9, 0.9)
			_wood_variants.append(m)
	return _wood_variants[randi() % _wood_variants.size()]


func _iron() -> StandardMaterial3D:
	if _iron_mat == null:
		_iron_mat = StandardMaterial3D.new()
		_iron_mat.albedo_color = Color(0.12, 0.11, 0.1)
		_iron_mat.metallic = 0.7
		_iron_mat.roughness = 0.55
	return _iron_mat


func _rope() -> StandardMaterial3D:
	if _rope_mat == null:
		_rope_mat = StandardMaterial3D.new()
		_rope_mat.albedo_color = Color(0.4, 0.31, 0.19)
		_rope_mat.roughness = 1.0
	return _rope_mat


func _chunk() -> StandardMaterial3D:
	if _chunk_mat == null:
		_chunk_mat = (load(STONE) as StandardMaterial3D).duplicate() as StandardMaterial3D
		_chunk_mat.albedo_color = Color(0.7, 0.64, 0.58)
		_chunk_mat.uv1_scale = Vector3(1.4, 1.4, 1.4)
	return _chunk_mat


## axis: 0 = runs along x, 1 = runs up, 2 = runs along z. length is along that axis.
func _timber(pos: Vector3, length: float, t1: float, t2: float, axis: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(length, t1, t2)
	bm.material = _wood_pick()
	mi.mesh = bm
	if axis == 1:
		mi.rotation_degrees.z = 90.0
	elif axis == 2:
		mi.rotation_degrees.y = 90.0
	mi.position = pos
	add_child(mi)
	return mi


func _timber_between(a: Vector3, b: Vector3, t: float) -> void:
	var dir := b - a
	var mi := _timber((a + b) * 0.5, dir.length(), t, t, 0)
	mi.basis = Basis(Quaternion(Vector3.RIGHT, dir.normalized()))


func _rope_ring(pos: Vector3, radius: float) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = 0.1
	cm.radial_segments = 8
	cm.material = _rope()
	mi.mesh = cm
	mi.position = pos
	add_child(mi)


func _iron_box(pos: Vector3, size: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = _iron()
	mi.mesh = bm
	mi.position = pos
	add_child(mi)


## A wall torch: iron bracket, wrapped head, small flame and a flickering light.
func _torch(pos: Vector3, energy := 3.2) -> void:
	_iron_box(pos - Vector3(0, 0.35, 0), Vector3(0.05, 0.55, 0.05))
	var head := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.08
	hm.bottom_radius = 0.05
	hm.height = 0.26
	hm.radial_segments = 8
	hm.material = _rope()
	head.mesh = hm
	head.position = pos
	add_child(head)
	var flame := MeshInstance3D.new()
	var fm := SphereMesh.new()
	fm.radius = 0.07
	fm.height = 0.3
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(1.0, 0.75, 0.35)
	fmat.emission_enabled = true
	fmat.emission = Color(1.0, 0.55, 0.15)
	fmat.emission_energy_multiplier = 2.5
	fm.material = fmat
	flame.mesh = fm
	flame.position = pos + Vector3(0, 0.24, 0)
	add_child(flame)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 0.3, 0)
	light.light_color = Color(1.0, 0.6, 0.28)
	light.light_energy = energy
	light.omni_range = 10.0
	add_child(light)
	var tw := light.create_tween().set_loops()
	tw.tween_property(light, "light_energy", energy * 1.2, randf_range(0.1, 0.22))
	tw.tween_property(light, "light_energy", energy * 0.8, randf_range(0.1, 0.22))


func _rock_chunk(pos: Vector3, size: float) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radial_segments = 6
	sm.rings = 3
	sm.material = _chunk()
	mi.mesh = sm
	mi.scale = Vector3(size * randf_range(0.8, 1.5), size * randf_range(0.5, 0.9), size * randf_range(0.8, 1.4))
	mi.rotation = Vector3(randf() * 0.5, randf() * TAU, randf() * 0.5)
	mi.position = pos
	add_child(mi)


## Mine timbers: a post on each side with a heavy iron-banded crossbeam and corner
## braces every few meters inside the narrow tunnels, plus torches, boards and rubble.
## Decoration only: nothing to bump into.
func _build_timbers() -> void:
	var skip := [Vector2(-18, 5.4), Vector2(5.8, 30), Vector2(-45, 4.0), Vector2(49, 22.6)]
	for c in CARVES:
		var y0: float = c[5] if c.size() > 5 else 0.0
		var h: float = c[4] - y0
		var w: float = c[2] - c[0]
		var d: float = c[3] - c[1]
		if minf(w, d) >= 8.0 or h > 4.6:
			continue
		var along_x := w > d
		var length := w if along_x else d
		var span := d if along_x else w
		var t := 2.0
		var index := 0
		while t < length - 1.0:
			var p := Vector2(c[0] + t, (c[1] + c[3]) * 0.5) if along_x else Vector2((c[0] + c[2]) * 0.5, c[1] + t)
			t += 4.5
			index += 1
			var inside := 0
			for o in CARVES:
				if p.x > o[0] - 1.0 and p.x < o[2] + 1.0 and p.y > o[1] - 1.0 and p.y < o[3] + 1.0:
					inside += 1
			var near_gate := false
			for s in skip:
				if p.distance_to(s) < 3.0:
					near_gate = true
			if inside != 1 or near_gate:
				continue
			# tp(): a point in this tunnel. across = sideways, along = down the tunnel.
			var tp := func(across: float, y: float, along: float = 0.0) -> Vector3:
				return Vector3(p.x + along, y, p.y + across) if along_x else Vector3(p.x + across, y, p.y + along)
			for side in [-1.0, 1.0]:
				var off: float = side * (span * 0.5 - 0.3)
				var post := _timber(tp.call(off, y0 + (h - 0.3) * 0.5), h - 0.3, 0.42, 0.42, 1)
				post.rotation_degrees.x = randf_range(-1.5, 1.5)
				_rope_ring(tp.call(off, y0 + 1.1), 0.27)
				# Corner brace from the post up to the beam.
				_timber_between(tp.call(off, y0 + h - 1.5), tp.call(off - side * 0.95, y0 + h - 0.62), 0.16)
			var across_axis := 2 if along_x else 0
			_timber(tp.call(0.0, y0 + h - 0.55), span - 0.1, 0.4, 0.5, across_axis)
			for k in [-0.28, 0.28]:
				var band_pos: Vector3 = tp.call(span * k, y0 + h - 0.55)
				_iron_box(band_pos, Vector3(0.1, 0.44, 0.54) if along_x else Vector3(0.54, 0.44, 0.1))
			if index % 2 == 1:
				var tside := 1.0 if randf() < 0.5 else -1.0
				_torch(tp.call(tside * (span * 0.5 - 0.75), y0 + 2.0))
			# Boards along the tunnel floor, some missing, some skewed.
			var board_count := int(span * 0.55 / 0.32)
			for i in board_count:
				if randf() < 0.18:
					continue
				var across := (i - board_count * 0.5) * 0.32
				var b := _timber(tp.call(across, y0 + 0.2, randf_range(-0.3, 0.3)), randf_range(2.4, 3.6), 0.05, 0.28,
						0 if along_x else 2)
				b.rotation.y += randf_range(-0.04, 0.04)
			for k in 5:
				var side2 := 1.0 if randf() < 0.5 else -1.0
				_rock_chunk(tp.call(side2 * (span * 0.5 - randf_range(0.6, 1.4)), y0 + 0.15, randf_range(-2.2, 2.2)), randf_range(0.2, 0.5))


## Real-looking scaffolding for the two-story walkways: uprights with rope lashings,
## ledgers and transoms under the deck, diagonal bracing, individual deck boards, hand
## rails and hanging lanterns.
const SCAFFOLD_GAPS := [Vector2(-10.5, -13.4), Vector2(23.2, -13.4), Vector2(64.2, -21.5)]


func _deck_pt(d: Array, along_x: bool, u: float, v: float, y: float) -> Vector3:
	return Vector3(d[0] + u, y, d[1] + v) if along_x else Vector3(d[0] + v, y, d[1] + u)


## True where a point sits over a different deck than deck `di` (rails must not cross walkways).
func _in_other_deck(di: int, p: Vector3) -> bool:
	for j in DECKS.size():
		if j == di:
			continue
		var o: Array = DECKS[j]
		if p.x > o[0] - 0.2 and p.x < o[2] + 0.2 and p.z > o[1] - 0.2 and p.z < o[3] + 0.2:
			return true
	return false


func _build_scaffolds() -> void:
	for di in DECKS.size():
		var d: Array = DECKS[di]
		var w: float = d[2] - d[0]
		var dd: float = d[3] - d[1]
		if maxf(w, dd) < 8.0:
			continue  # the rope bridge has its own rails
		var along_x := w >= dd
		var L := w if along_x else dd
		var W := dd if along_x else w
		var top: float = d[4]
		var along := 0 if along_x else 2
		var across := 2 if along_x else 0
		var n := maxi(1, ceili((L - 0.7) / 3.0))
		var step := (L - 0.7) / n
		var sides := [0.28, W - 0.28]
		for i in n + 1:
			var u := 0.35 + i * step
			# Transom across the width under the deck.
			_timber(_deck_pt(d, along_x, u, W * 0.5, top - 0.52), W, 0.2, 0.2, across)
			for si in 2:
				var v: float = sides[si]
				var inward := 0.2 if si == 0 else -0.2
				var over := _in_other_deck(di, _deck_pt(d, along_x, u, v, top))
				if not over:
					var upright := _timber(_deck_pt(d, along_x, u, v, (top + 1.15) * 0.5), top + 1.15, 0.3, 0.3, 1)
					upright.rotation_degrees.x = randf_range(-0.8, 0.8)
					_rope_ring(_deck_pt(d, along_x, u, v, top - 0.62), 0.2)
					_rope_ring(_deck_pt(d, along_x, u, v, top + 0.58), 0.2)
				# Diagonal bracing, alternating direction bay to bay.
				if i < n:
					var ua := u
					var ub := u + step
					var low := _deck_pt(d, along_x, ua, v - inward, 0.35)
					var high := _deck_pt(d, along_x, ub, v - inward, top - 0.72)
					if (i + si) % 2 == 1:
						low = _deck_pt(d, along_x, ub, v - inward, 0.35)
						high = _deck_pt(d, along_x, ua, v - inward, top - 0.72)
					_timber_between(low, high, 0.17)
					# Hand rails between uprights (skipped where stairs and ladders arrive).
					var mid := _deck_pt(d, along_x, u + step * 0.5, v, top)
					var open := not _in_other_deck(di, mid)
					for g in SCAFFOLD_GAPS:
						if Vector2(mid.x, mid.z).distance_to(g) < 2.9:
							open = false
					if open:
						_timber(_deck_pt(d, along_x, u + step * 0.5, v, top + 1.05), step, 0.12, 0.14, along)
						_timber(_deck_pt(d, along_x, u + step * 0.5, v, top + 0.55), step, 0.1, 0.12, along)
				if i % 3 == 1 and si == 1 and not over:
					var lp := _deck_pt(d, along_x, u, v + inward * 1.4, top + 0.95)
					_iron_box(lp, Vector3(0.2, 0.3, 0.2))
					var glow := MeshInstance3D.new()
					var gm := BoxMesh.new()
					gm.size = Vector3(0.14, 0.2, 0.14)
					var gmat := StandardMaterial3D.new()
					gmat.albedo_color = Color(1.0, 0.8, 0.45)
					gmat.emission_enabled = true
					gmat.emission = Color(1.0, 0.6, 0.2)
					gmat.emission_energy_multiplier = 3.0
					gm.material = gmat
					glow.mesh = gm
					glow.position = lp
					add_child(glow)
					var ll := OmniLight3D.new()
					ll.position = lp
					ll.light_color = Color(1.0, 0.65, 0.32)
					ll.light_energy = 2.4
					ll.omni_range = 9.0
					add_child(ll)
		# Ledgers under the deck, one on each side.
		for si in 2:
			var v: float = sides[si]
			var inward := 0.2 if si == 0 else -0.2
			_timber(_deck_pt(d, along_x, L * 0.5, v + inward, top - 0.62), L, 0.26, 0.2, along)
		# Deck boards, each a little different.
		var count := floori(L / 0.27)
		for i in count:
			var u := 0.135 + i * 0.27
			var board := _timber(_deck_pt(d, along_x, u, W * 0.5 + randf_range(-0.03, 0.03), top + 0.02 + randf_range(-0.006, 0.006)),
					W + randf_range(-0.05, 0.07), 0.05, 0.25, across)
			board.rotation.y += randf_range(-0.012, 0.012)


## One faceted crystal: a six-sided shaft with a bent, irregular point. Flat shaded.
func _crystal_mesh(h: float, r: float, rng: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 6
	var rings := [[0.0, 1.0], [0.62, 0.82 + rng.randf() * 0.1]]
	var tip := Vector3(rng.randf_range(-0.25, 0.25) * r, h, rng.randf_range(-0.25, 0.25) * r)
	var prev: Array = []
	for ri in rings.size():
		var ring: Array = []
		for s in sides:
			var a := TAU * s / sides + ri * 0.12
			var rr: float = r * float(rings[ri][1]) * rng.randf_range(0.85, 1.12)
			ring.append(Vector3(cos(a) * rr, h * float(rings[ri][0]) * 0.97, sin(a) * rr))
		prev.append(ring)
	for ri in prev.size() - 1:
		var r0: Array = prev[ri]
		var r1: Array = prev[ri + 1]
		for s in sides:
			var s2 := (s + 1) % sides
			st.add_vertex(r0[s])
			st.add_vertex(r1[s2])
			st.add_vertex(r1[s])
			st.add_vertex(r0[s])
			st.add_vertex(r0[s2])
			st.add_vertex(r1[s2])
	var top: Array = prev[prev.size() - 1]
	for s in sides:
		var s2 := (s + 1) % sides
		st.add_vertex(top[s])
		st.add_vertex(top[s2])
		st.add_vertex(tip)
	st.generate_normals()
	return st.commit()


## Cluster of black shard crystals (the Black Shard the bandits dug up): many faceted
## obsidian spikes leaning away from the middle, with a skirt of cracked stone.
func _shards(pos: Vector3, scale_: float, seed_: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.025, 0.025, 0.04)
	mat.metallic = 0.15
	mat.metallic_specular = 0.9
	mat.roughness = 0.12
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.6
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = Color(0.16, 0.03, 0.28)
	mat.emission_energy_multiplier = 0.35
	for i in 9:
		var big := i == 0
		var h := scale_ * rng.randf_range(0.9, 2.6) * (1.9 if big else 1.0)
		var r := scale_ * rng.randf_range(0.14, 0.34) * (1.6 if big else 1.0)
		var mi := MeshInstance3D.new()
		mi.mesh = _crystal_mesh(h, r, rng)
		mi.material_override = mat
		var ang := rng.randf() * TAU
		var dist := 0.0 if big else rng.randf_range(0.25, 1.0) * scale_
		mi.position = pos + Vector3(cos(ang) * dist, -0.05, sin(ang) * dist)
		var lean := 0.0 if big else rng.randf_range(0.15, 0.55)
		mi.rotation = Vector3(sin(ang) * lean, rng.randf() * TAU, -cos(ang) * lean)
		add_child(mi)
	for i in 8:
		var a := rng.randf() * TAU
		_rock_chunk(pos + Vector3(cos(a), 0.1, sin(a)) * scale_ * rng.randf_range(0.9, 1.6), scale_ * rng.randf_range(0.2, 0.4))
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = scale_ * 0.5
	sh.height = scale_ * 2.5
	cs.shape = sh
	body.add_child(cs)
	body.position = pos + Vector3(0, scale_ * 1.25, 0)
	add_child(body)
	var glow := OmniLight3D.new()
	glow.position = pos + Vector3(0, scale_ * 1.5, 0)
	glow.light_color = Color(0.55, 0.25, 1.0)
	glow.light_energy = 1.6
	glow.omni_range = 7.0
	add_child(glow)


## Extra warm and cool light for the big Excavation, which was too dark.
func _build_excavation_light() -> void:
	for x in [36.0, 46.0, 56.0, 64.0]:
		for z in [-22.0, -4.0]:
			var l := OmniLight3D.new()
			l.position = Vector3(x, 6.0, z)
			l.light_color = Color(1.0, 0.65, 0.35) if int(x + z) % 2 == 0 else Color(0.45, 0.65, 1.0)
			l.light_energy = 5.0
			l.omni_range = 18.0
			add_child(l)


var _floor_v := PackedVector3Array()
var _floor_n := PackedVector3Array()


## Pebbly gravel for the cave floor (ambientCG Rocks011).
func _floor_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/scree/color.jpg")
	m.albedo_color = Color(0.85, 0.76, 0.68)
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/scree/normal.jpg")
	m.normal_scale = 1.0
	m.roughness_texture = load("res://assets/textures/scree/rough.jpg")
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.36, 0.36, 0.36)
	m.vertex_color_use_as_albedo = true
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


# ---- Atmosphere: ground fog, hazy light shafts, waterfalls ---------------------

func _fog_volume(shape: int, pos: Vector3, size: Vector3, albedo: Color, density: float, emission := Color.BLACK) -> void:
	var fv := FogVolume.new()
	fv.shape = shape
	fv.size = size
	fv.position = pos
	var fm := FogMaterial.new()
	fm.albedo = albedo
	fm.density = density
	fm.emission = emission
	fm.height_falloff = 0.0
	fv.material = fm
	add_child(fv)


## Low cool mist over the floors of the big rooms and a soft haze inside every light shaft.
func _build_atmosphere() -> void:
	for c in CARVES:
		var w: float = c[2] - c[0]
		var d: float = c[3] - c[1]
		if minf(w, d) < 8.0:
			continue
		_fog_volume(RenderingServer.FOG_VOLUME_SHAPE_BOX, Vector3((c[0] + c[2]) * 0.5, 1.0, (c[1] + c[3]) * 0.5),
				Vector3(w, 2.0, d), Color(0.55, 0.65, 0.8), 0.012)
	for s in SHAFTS:
		_fog_volume(RenderingServer.FOG_VOLUME_SHAPE_CYLINDER, Vector3(s[0], s[3] * 0.5, s[1]),
				Vector3(s[2] * 3.2, s[3], s[2] * 3.2), Color(0.5, 0.7, 1.0), 0.07, Color(0.0, 0.01, 0.02))


## Waterfalls spilling from clefts in the Excavation's south wall into the river,
## each with a splash pool, rolling mist and a cold glow.
var _water_normal: NoiseTexture2D
var _water_noise: NoiseTexture2D


func _water_textures() -> void:
	if _water_normal:
		return
	var n1 := FastNoiseLite.new()
	n1.frequency = 0.03
	n1.fractal_octaves = 4
	_water_normal = NoiseTexture2D.new()
	_water_normal.noise = n1
	_water_normal.as_normal_map = true
	_water_normal.bump_strength = 5.0
	_water_normal.seamless = true
	_water_normal.width = 256
	_water_normal.height = 256
	var n2 := FastNoiseLite.new()
	n2.frequency = 0.025
	n2.seed = 9
	n2.fractal_octaves = 3
	_water_noise = NoiseTexture2D.new()
	_water_noise.noise = n2
	_water_noise.seamless = true
	_water_noise.width = 256
	_water_noise.height = 256


func _water_material(flow := Vector2.ZERO) -> ShaderMaterial:
	_water_textures()
	var sm := ShaderMaterial.new()
	sm.shader = load("res://game/world/shaders/cave_water.gdshader")
	sm.set_shader_parameter("normal_tex", _water_normal)
	sm.set_shader_parameter("noise_tex", _water_noise)
	sm.set_shader_parameter("flow", flow)
	return sm


## Little white droplets that leap and fall, for waterfall bases.
func _splash(pos: Vector3, radius: float) -> void:
	var gp := GPUParticles3D.new()
	gp.amount = 70
	gp.lifetime = 1.1
	gp.position = pos
	gp.visibility_aabb = AABB(Vector3(-4, -1, -4), Vector3(8, 6, 8))
	gp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = radius
	pm.direction = Vector3(0, 1, 0.4)
	pm.spread = 55.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 3.2
	pm.gravity = Vector3(0, -6.0, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.5
	gp.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(0.9, 0.96, 1.0, 0.7)
	mat.albedo_texture = _soft_dot()
	q.material = mat
	gp.draw_pass_1 = q
	add_child(gp)


func _build_falls() -> void:
	_water_textures()
	var fall_mat := ShaderMaterial.new()
	fall_mat.shader = load("res://game/world/shaders/cave_waterfall.gdshader")
	fall_mat.set_shader_parameter("noise_tex", _water_noise)
	for x in [38.0, 48.0, 57.0]:
		var top := 9.5
		var wallz := 3.9
		var width := 1.5 if x != 48.0 else 2.4
		var sheet := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(width, top)
		qm.subdivide_depth = 24
		qm.subdivide_width = 4
		qm.material = fall_mat
		sheet.mesh = qm
		sheet.position = Vector3(x, top * 0.5, wallz)
		sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(sheet)
		# A rough rock lip the water pours over, and wet boulders at its foot.
		for k in 3:
			_rock_chunk(Vector3(x + (k - 1) * width * 0.4, top - 0.1, wallz + 0.35), 0.5)
		for k in 6:
			_rock_chunk(Vector3(x + randf_range(-1.8, 1.8), 0.15, wallz - randf_range(1.8, 2.8)), randf_range(0.2, 0.45))
		var pool := MeshInstance3D.new()
		var pm := QuadMesh.new()
		pm.size = Vector2(5.6, 5.6)
		var pmat := _water_material(Vector2(0.0, -1.0))
		pmat.set_shader_parameter("pool", true)
		pm.material = pmat
		pool.mesh = pm
		pool.rotation.x = -PI / 2.0
		pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pool.position = Vector3(x, 0.08, wallz - 1.1)
		add_child(pool)
		_splash(Vector3(x, 0.2, wallz - 0.7), width * 0.35)
		_fog_volume(RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID, Vector3(x, 1.4, wallz - 1.0),
				Vector3(5.0, 2.6, 4.0), Color(0.8, 0.9, 1.0), 0.12)
		var glow := OmniLight3D.new()
		glow.position = Vector3(x, 2.0, wallz - 1.2)
		glow.light_color = Color(0.4, 0.75, 1.0)
		glow.light_energy = 1.4
		glow.omni_range = 11.0
		add_child(glow)


# ---- The bandit camp: a lived-in layout ----------------------------------------

func _mesh_at(mesh: Mesh, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	add_child(mi)
	return mi



const HIDEOUT := "res://assets/hideout/"


## Instance a baked hideout asset (e.g. "Camp_Equipment/tent_small"). Props are walk-through
## unless solid, so they can never trap a player or block an enemy.
func _asset(path: String, pos: Vector3, rot_y := 0.0, solid := false, scl := 1.0) -> Node3D:
	var ps := load(HIDEOUT + path + ".scn") as PackedScene
	if ps == null:
		push_warning("Gullet: missing asset " + path)
		return null
	var n := ps.instantiate() as Node3D
	n.position = pos
	n.rotation.y = rot_y
	n.scale = Vector3.ONE * scl
	if not solid:
		var col := n.get_node_or_null("Collision")
		if col:
			col.queue_free()
	add_child(n)
	return n


func _build_camp() -> void:
	var fire := px(765, 400)
	var cloth_red: Material = (load("res://levels/common/materials/cloth_red.tres") as Material).duplicate()
	if cloth_red is BaseMaterial3D:
		(cloth_red as BaseMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	# Central fire with log seats and stools around it.
	_asset("Camp_Equipment/campfire_communal", fire)
	for i in 5:
		var a := TAU * (i + 0.5) / 5.0
		_asset("Camp_Equipment/stool_%d" % (i % 3), fire + Vector3(cos(a) * 3.0, 0, sin(a) * 3.0), rng.randf() * TAU)
	_asset("Camp_Equipment/tripod_pot", fire + Vector3(2.6, 0, 1.2))
	_asset("Camp_Equipment/meat_rack", fire + Vector3(-3.6, 0, -2.2), 0.5)
	# Table with a lantern, utensils and stools.
	var tbl := Vector3(-1.0, 0, -9.5)
	_asset("Camp_Equipment/table_slab", tbl, 0.0, true)
	_asset("Camp_Equipment/utensils", tbl + Vector3(-0.5, 0.95, 0.1))
	_asset("Lighting_Props/lantern", tbl + Vector3(0.6, 0.95, 0.0))
	_asset("Camp_Equipment/chair_0", tbl + Vector3(-0.6, 0, 1.3), PI)
	_asset("Camp_Equipment/stool_1", tbl + Vector3(0.9, 0, 1.3), 0.4)
	_asset("Camp_Equipment/chair_2", tbl + Vector3(2.4, 0, 0.6), -1.2)
	_torch(tbl + Vector3(1.3, 1.3, -0.2), 2.0)
	# Weapon rack against the north wall.
	_asset("Environmental_Props/weapon_rack", Vector3(-11.5, 0, -13.1))
	# Lean-to tents along the south wall, each with a bed and a personal area.
	for t in [[-3.0, 6.0, 0.2], [11.0, 6.2, -0.15], [21.0, 4.8, 0.35]]:
		_asset("Camp_Equipment/tent_small", Vector3(t[0], 0, t[1]), PI + t[2], true)
		_asset("Camp_Equipment/bedding_%s" % ["rolled", "open", "straw"][rng.randi() % 3], Vector3(t[0] + 2.4, 0, t[1] - 1.8), rng.randf() * TAU)
	_asset("Camp_Equipment/personal_area", Vector3(-8.0, 0, 5.0), 0.3)
	# Storage clusters: barrels, crates, sacks.
	var cl := 0
	for p in [Vector3(24.5, 0, -9.5), Vector3(-9.5, 0, 3.5), Vector3(25.0, 0, 6.3)]:
		cl += 1
		_asset("Storage_Containers/barrel_stack", p, rng.randf() * TAU, true)
		_asset("Storage_Containers/sack_grain", p + Vector3(1.6, 0, 0.5), rng.randf() * TAU)
		_asset("Storage_Containers/crate_large", p + Vector3(1.0, 0, 1.6), rng.randf() * 3.0, true)
		_asset("Storage_Containers/crate_small", p + Vector3(1.1, 0.9, 1.5), rng.randf() * 3.0)
		_asset("Storage_Containers/barrel_%s" % ["water", "grain", "broken"][cl - 1], p + Vector3(-1.2, 0, 0.9), 0.0, true)
	_asset("Storage_Containers/chest_closed", Vector3(-13.2, 0, 6.8), 1.2, true)
	_asset("Storage_Containers/mining_box_tools", Vector3(24.0, 0, 2.0), 0.4)
	_asset("Mining_Equipment/pickaxe", Vector3(-9.0, 0.0, 2.6), 1.0)
	_asset("Mining_Equipment/shovel", Vector3(23.2, 0.0, -8.3), 2.0)
	# Braziers and standing torches (they carry their own flickering lights).
	for p in [Vector3(-12.6, 0, -0.6), Vector3(25.8, 0, -7.0)]:
		_asset("Lighting_Props/brazier", p)
	# Red banners hanging from the upper walkway.
	for x in [-6.0, 3.0, 12.0, 21.0]:
		var banner := QuadMesh.new()
		banner.size = Vector2(1.3, 2.4)
		banner.material = cloth_red
		_mesh_at(banner, Vector3(x, 2.7, -12.95))
	# Floor litter.
	for i in 22:
		var pos := Vector3(rng.randf_range(-12.0, 25.5), 0.0, rng.randf_range(-12.0, 7.5))
		if Vector2(pos.x - fire.x, pos.z - fire.z).length() < 2.0:
			continue
		if i % 3 == 0:
			_asset("Mining_Equipment/rubble_small", pos, rng.randf() * TAU)
		elif i % 3 == 1:
			_asset("Mining_Equipment/broken_tools", pos, rng.randf() * TAU)
		else:
			_rock_chunk(pos + Vector3(0, 0.15, 0), rng.randf_range(0.12, 0.3))


## Mining gear in the Excavation: carts on a track, a winch, frames, ore and rubble.
func _build_dig_dressing() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i in 4:
		_asset("Mining_Equipment/track_2m", Vector3(54.0 + i * 2.0, 0, -4.0))
	_asset("Mining_Equipment/mine_cart_loaded", Vector3(57.0, 0, -4.0), 0.0, true)
	_asset("Mining_Equipment/mine_cart_empty", Vector3(61.0, 0, -4.0), PI, true)
	_asset("Mining_Equipment/wheelbarrow_loaded", Vector3(66.0, 0, 1.0), 0.8)
	_asset("Mining_Equipment/winch", Vector3(40.0, 0, -9.5), 0.3, true)
	_asset("Mining_Equipment/ore_pile", Vector3(65.0, 0, -9.0), 0.4)
	_asset("Mining_Equipment/rope_coil", Vector3(41.5, 0, -8.0), 1.0)
	_asset("Mining_Equipment/support_frame", Vector3(44.0, 0, 4.0))
	_asset("Mining_Equipment/support_frame_broken", Vector3(62.0, 0, 4.0))
	for p in [Vector3(38.0, 0, -11.0), Vector3(66.0, 0, -11.5), Vector3(36.0, 0, 3.0), Vector3(68.0, 0, 3.0)]:
		_asset("Mining_Equipment/rubble_large", p, rng.randf() * TAU)
	_asset("Storage_Containers/barrel_stack", Vector3(68.0, 0, -6.0), 0.3, true)
	_asset("Storage_Containers/crate_large", Vector3(37.0, 0, -6.0), 0.2, true)
	_asset("Lighting_Props/brazier", Vector3(52.0, 0, -9.0))
	_asset("Lighting_Props/brazier", Vector3(64.0, 0, 0.0))


## Rock arches round the tunnel mouths, flared pillars in the deep chamber, boulders and
## ledges at room edges, from the hideout cave kit. All walk-through dressing.
func _build_cave_assets() -> void:
	# [x, z, rotation (radians), scale]: arch faces the room it opens into.
	for o in [[-42.3, 25.0, -PI * 0.5, 1.3], [-14.3, -5.0, PI * 0.5, 1.3], [27.3, -2.0, -PI * 0.5, 1.4],
			[17.0, 8.2, PI, 1.15], [49.0, 3.6, PI, 1.3]]:
		_asset("Cave_Geometry/cave_opening", Vector3(o[0], 0, o[1]), o[2], false, o[3])
	for pl in PILLARS:
		var v := px(pl[0], pl[1])
		var n := _asset("Cave_Geometry/rock_pillar", v, randf() * TAU, false, 1.0)
		if n:
			n.scale = Vector3(1.7, 2.8, 1.7)
	var rocks := [["large", -57.5, 18.5], ["medium", -57.0, 32.4], ["large", -13.4, 8.0], ["medium", 26.6, -17.0],
			["large", 66.5, 3.6], ["medium", 8.0, 25.0], ["large", 8.2, 39.5], ["medium", 57.5, 39.5], ["small", -44.0, 18.0]]
	for r in rocks:
		_asset("Cave_Geometry/rock_" + r[0], Vector3(r[1], 0, r[2]), randf() * TAU)
	_asset("Cave_Geometry/stone_ledge_3m", Vector3(-51.0, 0, 16.3), 0.0)
	_asset("Cave_Geometry/stone_ledge_3m", Vector3(-9.0, 0, 8.5), PI)


## The west stairs run under the walkway and were left in its shadow: stand torches beside them.
func _light_stairs() -> void:
	_asset("Lighting_Props/torch_stand", Vector3(-8.3, 0, -5.4))
	_asset("Lighting_Props/torch_stand", Vector3(-12.5, 0, -8.5))


# ---- Crack-free subdivision ------------------------------------------------------
# Every triangle edge is first made to include each vertex that lies on it (the baked CSG
# leaves T-junctions), then every segment is cut at fixed spots computed from its two ends,
# so two faces meeting along a seam always share identical points. Interiors are filled
# with a jittered lattice and a Delaunay triangulation. Displacement is a function of
# position only, so shared points move together and no cracks can open.

func _vkey_lt(a: Vector3i, b: Vector3i) -> bool:
	if a.x != b.x:
		return a.x < b.x
	if a.y != b.y:
		return a.y < b.y
	return a.z < b.z


func _edge_points(p0: Vector3, p1: Vector3, grid: Dictionary, cell: float, cache: Dictionary) -> PackedVector3Array:
	var k0 := _vkey(p0)
	var k1 := _vkey(p1)
	var flip := _vkey_lt(k1, k0)
	var lo := p1 if flip else p0
	var hi := p0 if flip else p1
	var ck := [mini(k0.x, k1.x) * 1000003 + k0.y + k1.y, k0 if not flip else k1, k1 if not flip else k0]
	var res: PackedVector3Array
	if cache.has(ck):
		res = cache[ck]
	else:
		var lo_c := Vector3i(floori((minf(lo.x, hi.x) - 0.02) / cell), floori((minf(lo.y, hi.y) - 0.02) / cell), floori((minf(lo.z, hi.z) - 0.02) / cell))
		var hi_c := Vector3i(floori((maxf(lo.x, hi.x) + 0.02) / cell), floori((maxf(lo.y, hi.y) + 0.02) / cell), floori((maxf(lo.z, hi.z) + 0.02) / cell))
		var found: Array = []
		var klo := _vkey(lo)
		var khi := _vkey(hi)
		var dir := hi - lo
		var len2 := dir.length_squared()
		for cx in range(lo_c.x, hi_c.x + 1):
			for cy in range(lo_c.y, hi_c.y + 1):
				for cz in range(lo_c.z, hi_c.z + 1):
					var bucket = grid.get(Vector3i(cx, cy, cz))
					if bucket == null:
						continue
					for q in bucket:
						var kq := _vkey(q)
						if kq == klo or kq == khi:
							continue
						var tt: float = (q - lo).dot(dir) / len2
						if tt <= 0.0 or tt >= 1.0:
							continue
						if (lo + dir * tt).distance_to(q) < 0.02:
							found.append([tt, q])
		found.sort_custom(func(x, y): return x[0] < y[0])
		var chain := PackedVector3Array([lo])
		for f in found:
			chain.append(f[1])
		chain.append(hi)
		res = PackedVector3Array([lo])
		for j in chain.size() - 1:
			var q0 := chain[j]
			var q1 := chain[j + 1]
			var k := maxi(1, ceili(q0.distance_to(q1) / ROUGH_EDGE))
			for s in range(1, k):
				res.append(q0.lerp(q1, float(s) / k))
			res.append(q1)
		cache[ck] = res
	if flip:
		var r := PackedVector3Array()
		for j in range(res.size() - 1, -1, -1):
			r.append(res[j])
		return r
	return res


func _conform_split(tv: PackedVector3Array, tn: PackedVector3Array, tamp: PackedFloat32Array,
		tsign: PackedFloat32Array, out_v: PackedVector3Array, out_n: PackedVector3Array) -> void:
	var cell := 4.0
	var grid := {}
	var seen := {}
	for p in tv:
		var k := _vkey(p)
		if seen.has(k):
			continue
		seen[k] = true
		var c := Vector3i(floori(p.x / cell), floori(p.y / cell), floori(p.z / cell))
		if not grid.has(c):
			grid[c] = []
		grid[c].append(p)
	var cache := {}
	var bad := 0
	var s := ROUGH_EDGE
	for t in tv.size() / 3:
		var corners := [tv[t * 3], tv[t * 3 + 1], tv[t * 3 + 2]]
		var n: Vector3 = tn[t]
		var sg: float = tsign[t]
		var orig_area: float = ((corners[1] - corners[0]).cross(corners[2] - corners[0])).length() * 0.5
		if orig_area < 1e-6:
			continue
		var loop := PackedVector3Array()
		for e in 3:
			var pts := _edge_points(corners[e], corners[(e + 1) % 3], grid, cell, cache)
			for j in pts.size() - 1:
				loop.append(pts[j])
		var d := 0
		if absf(n.y) >= absf(n.x) and absf(n.y) >= absf(n.z):
			d = 1
		elif absf(n.z) >= absf(n.x):
			d = 2
		var ua := (d + 1) % 3
		var va := (d + 2) % 3
		var pts3 := PackedVector3Array(loop)
		var pts2 := PackedVector2Array()
		for p in loop:
			pts2.append(Vector2(p[ua], p[va]))
		var tri2 := PackedVector2Array([Vector2(corners[0][ua], corners[0][va]), Vector2(corners[1][ua], corners[1][va]), Vector2(corners[2][ua], corners[2][va])])
		var minp := Vector2(minf(tri2[0].x, minf(tri2[1].x, tri2[2].x)), minf(tri2[0].y, minf(tri2[1].y, tri2[2].y)))
		var maxp := Vector2(maxf(tri2[0].x, maxf(tri2[1].x, tri2[2].x)), maxf(tri2[0].y, maxf(tri2[1].y, tri2[2].y)))
		if orig_area > s * s * 0.8:
			for i in range(floori(minp.x / s), ceili(maxp.x / s) + 1):
				for j in range(floori(minp.y / s), ceili(maxp.y / s) + 1):
					var h1 := fmod(absf(sin(i * 12.9898 + j * 78.233) * 43758.5453), 1.0)
					var h2 := fmod(absf(sin(i * 39.346 + j * 11.135) * 24634.6345), 1.0)
					var q := Vector2((i + 0.5 + (h1 - 0.5) * 0.5) * s, (j + 0.5 + (h2 - 0.5) * 0.5) * s)
					if not Geometry2D.is_point_in_polygon(q, tri2):
						continue
					var near := false
					for e in 3:
						var cp := Geometry2D.get_closest_point_to_segment(q, tri2[e], tri2[(e + 1) % 3])
						if cp.distance_to(q) < s * 0.45:
							near = true
							break
					if near:
						continue
					var p3 := corners[0] as Vector3
					var du := q.x - p3[ua]
					var dv := q.y - p3[va]
					var pd: float = p3[d] - (n[ua] * du + n[va] * dv) / n[d]
					var v3 := Vector3.ZERO
					v3[ua] = q.x
					v3[va] = q.y
					v3[d] = pd
					pts2.append(q)
					pts3.append(v3)
		var idx := Geometry2D.triangulate_delaunay(pts2)
		var area_sum := 0.0
		var made := PackedVector3Array()
		for i in range(0, idx.size(), 3):
			var pa := pts3[idx[i]]
			var pb := pts3[idx[i + 1]]
			var pc := pts3[idx[i + 2]]
			var cr := (pb - pa).cross(pc - pa)
			var ar := cr.length() * 0.5
			if ar < 1e-7:
				continue
			area_sum += ar
			if cr.dot(n) * sg < 0.0:
				var tmp := pb
				pb = pc
				pc = tmp
			made.append(pa)
			made.append(pb)
			made.append(pc)
		if absf(area_sum - orig_area) > orig_area * 0.08 + 0.01:
			bad += 1
			made = PackedVector3Array([corners[0], corners[1], corners[2]])
		for i in made.size() / 3:
			out_v.append(made[i * 3])
			out_v.append(made[i * 3 + 1])
			out_v.append(made[i * 3 + 2])
			out_n.append(n)
			out_n.append(n)
			out_n.append(n)
			_raw_amp.append(tamp[t])
			_raw_sign.append(sg)
	print("Gullet rock: %d triangles, %d fell back" % [out_v.size() / 3, bad])


# ---- Realism: weathering tints, stalactites, puddles, dust ---------------------

var _tint_noise := FastNoiseLite.new()


func _rock_material() -> Material:
	var m := (load(STONE) as StandardMaterial3D).duplicate() as StandardMaterial3D
	m.vertex_color_use_as_albedo = true
	return m


## Per-vertex weathering: damp dark rock near the floor, mineral banding up the walls,
## soot on ceilings, and large soft patches of dirt and wet ground on the floor.
func _tint_colors(verts: PackedVector3Array, is_floor: bool) -> PackedColorArray:
	_tint_noise.seed = 41
	_tint_noise.frequency = 0.07
	var out := PackedColorArray()
	out.resize(verts.size())
	for i in verts.size():
		var p := verts[i]
		var n := _tint_noise.get_noise_3dv(p * (1.0 if is_floor else 0.8))
		var c: Color
		if is_floor:
			var v := 0.82 + 0.3 * n
			var wet := clampf((-n - 0.15) * 2.5, 0.0, 1.0)
			v *= 1.0 - 0.38 * wet
			c = Color(v, v * 0.97, v * (0.93 + 0.05 * wet))
		else:
			var band := sin(p.y * 2.1 + n * 5.0) * 0.06
			var v := 0.92 + 0.22 * n + band
			var damp := clampf(1.0 - p.y / 1.4, 0.0, 1.0)
			v *= 1.0 - 0.35 * damp
			if p.y > 3.5:
				v *= 0.86  # soot toward the ceiling
			c = Color(v * (1.0 - 0.06 * damp), v, v * (1.0 + 0.04 * damp))
		out[i] = c
	return out


func _dust(pos: Vector3, extents: Vector3, amount: int) -> void:
	var gp := GPUParticles3D.new()
	gp.amount = amount
	gp.lifetime = 9.0
	gp.preprocess = 9.0
	gp.position = pos
	gp.visibility_aabb = AABB(-extents - Vector3.ONE, extents * 2.0 + Vector3.ONE * 2.0)
	gp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = extents
	pm.gravity = Vector3(0.0, -0.01, 0.0)
	pm.direction = Vector3(0.3, -0.2, 0.1)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.03
	pm.initial_velocity_max = 0.14
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.25
	gp.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.022, 0.022)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(0.8, 0.88, 1.0, 0.5)
	mat.albedo_texture = _soft_dot()
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	q.material = mat
	gp.draw_pass_1 = q
	add_child(gp)


func _build_realism() -> void:
	# Stalactites hanging from the high ceilings.
	for s in [[-8.0, 9.9, -12.0], [8.0, 9.9, -14.0], [20.0, 9.9, 4.0], [-9.0, 9.9, 3.0], [40.0, 10.9, -4.0], [55.0, 10.9, -14.0],
			[64.0, 10.9, -2.0], [12.0, 8.9, 28.0], [22.0, 8.9, 37.0], [42.0, 8.9, 29.0], [55.0, 8.9, 38.0], [-55.0, 5.9, 19.0], [-47.0, 5.9, 31.0]]:
		_asset("Cave_Geometry/stalactites", Vector3(s[0], s[1], s[2]), randf() * TAU)
	# A few damp puddles.
	for p in [[-48.0, 20.0], [-33.0, 22.0], [12.0, -9.0], [26.0, 2.0], [45.0, -12.0], [20.0, 30.0], [50.0, 37.0]]:
		_asset("Cave_Geometry/water_pool", Vector3(p[0], 0.0, p[1]), randf() * TAU, false, 0.8)
	# Dust drifting in every shaft of daylight.
	for sh in SHAFTS:
		_dust(Vector3(sh[0], sh[3] * 0.5, sh[1]), Vector3(sh[2] * 0.8, sh[3] * 0.5, sh[2] * 0.8), 90)


## Soft round sprite so particles are blobs, not squares.
func _soft_dot() -> GradientTexture2D:
	var t := GradientTexture2D.new()
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 32
	t.height = 32
	t.gradient = Gradient.new()
	t.gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	return t
