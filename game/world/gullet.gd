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
	add_child(combiner)

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
		light.light_energy = l[2] * 3.0
		light.omni_range = 14.0
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
