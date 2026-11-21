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

	_build_cave_detail(mat)
	_build_shafts()
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
				for k in 2:
					var rock := MeshInstance3D.new()
					var sm := SphereMesh.new()
					sm.radial_segments = 6
					sm.rings = 3
					sm.material = tint
					rock.mesh = sm
					var r := rng.randf_range(0.5, 1.5) * clampf(hgt / 4.0, 0.8, 1.8)
					rock.scale = Vector3(r * rng.randf_range(0.7, 1.4), r * rng.randf_range(1.0, 2.6), r * rng.randf_range(0.7, 1.4))
					rock.rotation = Vector3(rng.randf() * 0.6, rng.randf() * TAU, rng.randf() * 0.6)
					rock.position = pos + Vector3(0, y0 + rng.randf() * hgt, 0) - out * rng.randf_range(-0.1, 0.35) * r
					add_child(rock)
		# Stalagmites and stalactites inside the bigger rooms, kept near the walls.
		var count := clampi(int(area / 18.0), 0, 40)
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
			if up:
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
		l.light_color = Color(0.5, 0.6, 0.85)
		l.light_energy = 1.8
		l.omni_range = clampf(maxf(c[2] - c[0], c[3] - c[1]) * 0.7, 9.0, 30.0)
		add_child(l)
