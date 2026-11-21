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
		# Posts under the long walkways.
		if d[2] - d[0] > 8.0 and d[3] - d[1] > 2.0:
			var x: float = d[0] + 1.0
			while x < d[2]:
				for z in [d[1] + 0.3, d[3] - 0.3]:
					var post := CSGBox3D.new()
					post.position = Vector3(x, d[4] * 0.5 - 0.2, z)
					post.size = Vector3(0.35, d[4] - 0.4, 0.35)
					post.material = wood
					combiner.add_child(post)
				x += 6.0
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
	_build_props()
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
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(7.2, 0.06, 0.06)
		mi.mesh = bm
		mi.position.y = 0.45
		rail.add_child(mi)
		rail.position = Vector3(29.0, 4.5, z)
		add_child(rail)


func _box(pos: Vector3, size: Vector3, color: Color, rot_y := 0.0, solid := true) -> Node3D:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	bm.material = m
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
	var crate := Color(0.42, 0.3, 0.17)
	var cloth := Color(0.3, 0.26, 0.2)
	# Entrance yard: broken barricade, carts.
	_box(px(160, 600), Vector3(2.4, 1.1, 0.5), crate, 0.3)
	_box(px(200, 700), Vector3(1.8, 0.9, 1.2), crate, 0.8)
	_box(px(240, 650), Vector3(2.0, 1.0, 1.4), Color(0.3, 0.24, 0.16), 0.0)
	# Camp: crates by the walls, bedrolls.
	for p in [[600, 500], [620, 505], [610, 480], [930, 500], [945, 480], [660, 255]]:
		_box(px(p[0], p[1]), Vector3(1.0, 0.9, 1.0), crate, randf() * 3.0)
	for p in [[620, 440], [640, 455], [690, 500]]:
		_box(px(p[0], p[1]), Vector3(0.8, 0.12, 2.0), cloth, 0.4, false)
	# Excavation: scaffolding, ore carts, the black stone formation.
	_box(px(1060, 300), Vector3(0.3, 4.0, 0.3), Color(0.35, 0.26, 0.15))
	_box(px(1060, 360), Vector3(0.3, 4.0, 0.3), Color(0.35, 0.26, 0.15))
	_box(px(1300, 400), Vector3(2.2, 1.0, 1.3), Color(0.3, 0.24, 0.16), 0.5)
	var black := Color(0.05, 0.05, 0.07)
	_box(px(1090, 380), Vector3(1.6, 3.2, 1.6), black, 0.5)
	_box(px(1104, 390), Vector3(1.0, 2.0, 1.0), black, 0.9)
	_box(px(1340, 420), Vector3(1.8, 2.8, 1.4), black, 0.2)
	_box(px(1325, 436), Vector3(1.0, 1.6, 1.0), black, 1.1)
	# Deep chamber: the exposed black stone in the south wall, and rubble.
	_box(px(1000, 825), Vector3(5.0, 5.0, 1.5), black, 0.0)
	_box(px(1010, 815), Vector3(2.2, 3.0, 1.0), black, 0.4)
	for p in [[830, 720], [900, 780], [1130, 770], [1150, 700], [990, 700]]:
		_box(px(p[0], p[1]), Vector3(1.4, 0.8, 1.2), Color(0.18, 0.16, 0.14), randf() * 3.0)


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
		var count := clampi(int(area / 18.0), 0, 40) if minf(w, d) >= 8.0 else 0
		for i in count:
			var onwall := rng.randi() % 4
			var sx := rng.randf_range(c[0] + 0.5, c[2] - 0.5)
			var sz := rng.randf_range(c[1] + 0.5, c[3] - 0.5)
			match onwall:
				0: sz = c[1] + rng.randf_range(0.5, 1.4)
				1: sz = c[3] - rng.randf_range(0.5, 1.4)
				2: sx = c[0] + rng.randf_range(0.5, 1.4)
				_: sx = c[2] - rng.randf_range(0.5, 1.4)
			var up := rng.randf() < 0.55
			var h := rng.randf_range(0.8, 2.6)
			var rad := rng.randf_range(0.18, 0.5)
			var cone := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.0 if up else rad
			cm.bottom_radius = rad if up else 0.0
			cm.height = h
			cm.radial_segments = 6
			cm.material = tint
			cone.mesh = cm
			cone.position = Vector3(sx, y0 + h * 0.5 if up else c[4] - h * 0.5, sz)
			add_child(cone)
			if false:
				var body := StaticBody3D.new()
				var cs := CollisionShape3D.new()
				var cyl := CylinderShape3D.new()
				cyl.radius = rad * 0.7
				cyl.height = h
				cs.shape = cyl
				body.add_child(cs)
				body.position = cone.position
				add_child(body)


func _build_river() -> void:
	for path in RIVER:
		var stream := WaterStream.new()
		var pts := PackedVector3Array()
		for p in path:
			pts.append(Vector3(p[0], 0.0, p[1]))
		stream.points = pts
		stream.width = RIVER_WIDTH
		add_child(stream)


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
	stairs.material = load(WOOD)
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
			var amp := 0.22 if n.y > 0.7 else 2.3
			_subdivide(a, b, c, n, sign_, amp, rock_verts, rock_norms, collide, 0)
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
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, load(STONE))
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	add_child(mi)
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
	return p + n * (amp * (v * 0.4 if v > 0.0 else v * 0.65))


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
			out_v.append(p)
			out_n.append((smooth[k] as Vector3).normalized())
			collide.append(p)


## Mine timbers: a post on each side and a heavy crossbeam every few meters inside the
## narrow tunnels (decoration only, nothing to bump into).
func _build_timbers() -> void:
	var wood := (load(WOOD) as StandardMaterial3D).duplicate() as StandardMaterial3D
	wood.albedo_color = Color(1.25, 1.0, 0.8)
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
		while t < length - 1.0:
			var p := Vector2(c[0] + t, (c[1] + c[3]) * 0.5) if along_x else Vector2((c[0] + c[2]) * 0.5, c[1] + t)
			t += 4.5
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
			for side in [-1.0, 1.0]:
				var post := MeshInstance3D.new()
				var pm := BoxMesh.new()
				pm.size = Vector3(0.45, h - 0.3, 0.45) if along_x else Vector3(0.45, h - 0.3, 0.45)
				pm.material = wood
				post.mesh = pm
				var off: float = side * (span * 0.5 - 0.3)
				post.position = Vector3(p.x, y0 + (h - 0.3) * 0.5, p.y + off) if along_x else Vector3(p.x + off, y0 + (h - 0.3) * 0.5, p.y)
				post.rotation_degrees = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
				add_child(post)
			var beam := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.5, 0.4, span - 0.1) if along_x else Vector3(span - 0.1, 0.4, 0.5)
			bm.material = wood
			beam.mesh = bm
			beam.position = Vector3(p.x, y0 + h - 0.55, p.y)
			add_child(beam)
			# Warm torch on every other frame, plank floor and rubble around it.
			if int(t / 4.5) % 2 == 0:
				var tp := Vector3(p.x, y0 + 2.0, p.y)
				var off2: float = (span * 0.5 - 0.75)
				if along_x:
					tp.z += off2
				else:
					tp.x += off2
				var flame := MeshInstance3D.new()
				var fm := SphereMesh.new()
				fm.radius = 0.12
				fm.height = 0.3
				var fmat := StandardMaterial3D.new()
				fmat.albedo_color = Color(1.0, 0.7, 0.3)
				fmat.emission_enabled = true
				fmat.emission = Color(1.0, 0.6, 0.2)
				fmat.emission_energy_multiplier = 4.0
				fm.material = fmat
				flame.mesh = fm
				flame.position = tp
				add_child(flame)
				var handle := MeshInstance3D.new()
				var hm := BoxMesh.new()
				hm.size = Vector3(0.08, 0.6, 0.08)
				hm.material = wood
				handle.mesh = hm
				handle.position = tp - Vector3(0, 0.4, 0)
				add_child(handle)
				var tl := OmniLight3D.new()
				tl.position = tp + Vector3(0, 0.2, 0)
				tl.light_color = Color(1.0, 0.62, 0.3)
				tl.light_energy = 3.2
				tl.omni_range = 10.0
				add_child(tl)
			var planks := MeshInstance3D.new()
			var plm := BoxMesh.new()
			plm.size = Vector3(3.4, 0.07, span * 0.55) if along_x else Vector3(span * 0.55, 0.07, 3.4)
			plm.material = wood
			planks.mesh = plm
			planks.position = Vector3(p.x, y0 + 0.2, p.y)
			add_child(planks)
			for k in 4:
				var rock := MeshInstance3D.new()
				var rm := BoxMesh.new()
				rm.size = Vector3(randf_range(0.3, 0.8), randf_range(0.15, 0.4), randf_range(0.3, 0.7))
				var rmat := StandardMaterial3D.new()
				rmat.albedo_color = Color(0.38, 0.3, 0.24)
				rmat.roughness = 0.95
				rm.material = rmat
				rock.mesh = rm
				var side2 := 1.0 if randf() < 0.5 else -1.0
				var sp := side2 * (span * 0.5 - randf_range(0.7, 1.3))
				var al := randf_range(-2.0, 2.0)
				rock.position = Vector3(p.x + al, y0 + 0.15, p.y + sp) if along_x else Vector3(p.x + sp, y0 + 0.15, p.y + al)
				rock.rotation = Vector3(randf(), randf() * TAU, randf())
				add_child(rock)


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
