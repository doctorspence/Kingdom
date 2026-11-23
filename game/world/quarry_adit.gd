extends Node3D
## The Gullet's way in: a squared opening cut into the quarry's lowest face, faced
## with courses of cut limestone, shored with old oak frames (posts, cap beams,
## braces, ceiling lagging), a mine track running in, rubble at its foot and a
## lantern on the lintel. Local +z points out of the face (toward the quarry
## floor); the origin is on the floor at the foot of the facade. The CaveDoor
## that leads down stays its own node in front of it.

const W := 3.3      # opening width
const H := 3.6      # opening height
const DEPTH := 9.0  # how far the tunnel runs before it is lost in the dark

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 1201
	var stone := SurfaceTool.new()
	stone.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rock := SurfaceTool.new()
	rock.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wood := SurfaceTool.new()
	wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	_facade(stone)
	_tunnel(rock)
	_timbers(wood)
	var stone_m := QuarryKit.stone_material()
	var rock_m := stone_m.duplicate() as StandardMaterial3D
	rock_m.albedo_color = Color(0.55, 0.54, 0.5)  # the tunnel's own walls, in shadow
	for pair in [[stone, stone_m], [rock, rock_m], [wood, QuarryKit.timber_material()]]:
		var st: SurfaceTool = pair[0]
		st.generate_normals()
		st.set_material(pair[1])
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		add_child(mi)
	# (the tunnel carries on: quarry_descent.gd continues it, so no dark curtain at the end)
	_collision()
	_props()


## The living rock round the opening: big rough, irregular masses (no courses,
## no straight joints) that close the gap between the timber frame and the
## quarry face, heavier low down and breaking up toward the top.
func _facade(st: SurfaceTool) -> void:
	# Over the opening: one massive rough brow the frame holds up.
	QuarryKit.rock_box(st, Vector3(0, H + 1.1, -1.9), Vector3(W + 2.6, 2.2, 2.8), _rng.randf_range(-0.08, 0.08), _rng, 0.22)
	for side: float in [-1.0, 1.0]:
		var y := 0.0
		while y < 6.5:
			var h := _rng.randf_range(1.6, 2.8)
			var w := _rng.randf_range(2.2, 3.6) * (1.0 - y / 12.0)
			var x := side * (W * 0.5 + w * 0.5 + 0.35 + _rng.randf_range(-0.2, 0.3))
			QuarryKit.rock_box(st, Vector3(x, y + h * 0.5, -1.9 + _rng.randf_range(-0.4, 0.3)), Vector3(w, h, 2.6), _rng.randf_range(-0.25, 0.25), _rng, 0.3)
			y += h * 0.8
		# A second, smaller mass further out so the edge melts into the face.
		QuarryKit.rock_box(st, Vector3(side * (W * 0.5 + 4.2), 1.2, -2.3), Vector3(2.4, 2.4, 2.2), _rng.randf() * TAU, _rng, 0.35)


func _tunnel(st: SurfaceTool) -> void:
	var z := -0.6
	while z > -DEPTH:
		var seg := 1.5
		for side: float in [-1.0, 1.0]:
			QuarryKit.rock_box(st, Vector3(side * (W * 0.5 + 0.5), H * 0.5, z - seg * 0.5), Vector3(1.0, H + 0.4, seg), 0.0, _rng, 0.12)
		QuarryKit.rock_box(st, Vector3(0, H + 0.5, z - seg * 0.5), Vector3(W + 1.6, 1.0, seg), 0.0, _rng, 0.1)
		QuarryKit.rock_box(st, Vector3(0, -0.15, z - seg * 0.5), Vector3(W + 0.6, 0.3, seg), 0.0, _rng, 0.04)
		z -= seg


## Oak shoring sets: two posts, a cap beam and lagging planks over it; the front
## set has knee braces. Slightly out of true, as old timber is.
func _timbers(st: SurfaceTool) -> void:
	for set_z: float in [-0.35, -2.6, -4.9, -7.2]:
		var lean := _rng.randf_range(-0.03, 0.03)
		for side: float in [-1.0, 1.0]:
			var post := Vector3(side * (W * 0.5 - 0.2), H * 0.5 - 0.1, set_z)
			QuarryKit.rock_box(st, post, Vector3(0.3, H - 0.2, 0.3), lean * side, _rng, 0.02)
		QuarryKit.rock_box(st, Vector3(0, H - 0.05, set_z), Vector3(W + 0.2, 0.34, 0.38), 0.0, _rng, 0.02)
		if set_z > -1.0:
			for side: float in [-1.0, 1.0]:
				_strut(st, Vector3(side * (W * 0.5 - 0.25), H - 0.9, set_z), Vector3(side * (W * 0.5 - 0.95), H - 0.2, set_z))
	# Lagging: planks laid across the cap beams.
	var z := -0.2
	while z > -7.6:
		QuarryKit.rock_box(st, Vector3(0, H + 0.2, z - 0.12), Vector3(W + 0.4, 0.07, 0.22), 0.0, _rng, 0.02)
		z -= 0.3


func _strut(st: SurfaceTool, a: Vector3, b: Vector3) -> void:
	var mid := (a + b) * 0.5
	var length := a.distance_to(b)
	var dir := (b - a).normalized()
	# A thin box along dir: build it upright, then rotate about z.
	var ang := atan2(dir.x, dir.y)
	var tmp := SurfaceTool.new()
	tmp.begin(Mesh.PRIMITIVE_TRIANGLES)
	QuarryKit.rock_box(tmp, Vector3.ZERO, Vector3(0.2, length, 0.2), 0.0, _rng, 0.0)
	var arrays := tmp.commit_to_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for v in verts:
		st.add_vertex(mid + v.rotated(Vector3.BACK, -ang))


## Deep in the tunnel the light gives out: a black card that fades in with depth.
func _darkness() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.01, 0.01, 0.012)
	for i in 3:
		var q := MeshInstance3D.new()
		var pm := QuadMesh.new()
		pm.size = Vector2(W + 1.0, H + 0.6)
		q.mesh = pm
		q.material_override = mat
		q.position = Vector3(0, H * 0.5, -DEPTH + 0.5 + i * 0.01)
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(q)
	# A soft fall-off of darkness toward the back (fog volume), so it isn't a flat black wall.
	var fog := FogVolume.new()
	fog.size = Vector3(W, H, DEPTH - 2.0)
	fog.position = Vector3(0, H * 0.5, -DEPTH * 0.5 - 1.5)
	var fm := FogMaterial.new()
	fm.density = 1.2
	fm.albedo = Color(0.0, 0.0, 0.0)
	fog.material = fm
	add_child(fog)


func _collision() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	var boxes := [
		[Vector3(-(W * 0.5 + 3.0), 4.0, -1.9), Vector3(6.0, 8.0, 2.6)],   # facade left of the opening
		[Vector3(W * 0.5 + 3.0, 4.0, -1.9), Vector3(6.0, 8.0, 2.6)],      # facade right
		[Vector3(0, H + 2.2, -1.9), Vector3(W + 0.2, 4.4, 2.6)],          # over the opening
		[Vector3(-(W * 0.5 + 0.5), H * 0.5, -DEPTH * 0.5), Vector3(1.0, H, DEPTH)],
		[Vector3(W * 0.5 + 0.5, H * 0.5, -DEPTH * 0.5), Vector3(1.0, H, DEPTH)],
		[Vector3(0, -0.2, -4.9), Vector3(W + 1.0, 0.4, 9.6)],            # the floor (the ground surface is cut away here, see tithelands_land.gd holes)
	]
	for b in boxes:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = b[1]
		cs.shape = sh
		cs.position = b[0]
		body.add_child(cs)


## A mine track running in, rubble at the foot of the jambs, a lantern on the lintel.
func _props() -> void:
	var track := load("res://assets/hideout/Mining_Equipment/track_2m.scn") as PackedScene
	if track:
		for i in 6:
			var t := track.instantiate() as Node3D
			t.position = Vector3(0, 0.02, 3.0 - i * 2.0)
			for body in t.find_children("*", "CollisionObject3D", true, false):
				(body as CollisionObject3D).collision_layer = 0  # rails are for looking at: you walk right over them
			add_child(t)
	var rubble := load("res://assets/hideout/Mining_Equipment/rubble_small.scn") as PackedScene
	if rubble:
		for p: Vector3 in [Vector3(-2.6, 0, 0.6), Vector3(2.9, 0, 0.4), Vector3(-4.5, 0, 0.9)]:
			var r := rubble.instantiate() as Node3D
			r.position = p
			r.rotation.y = _rng.randf() * TAU
			add_child(r)
	var lantern := load("res://assets/hideout/Lighting_Props/lantern.scn") as PackedScene
	if lantern:
		var l := lantern.instantiate() as Node3D
		l.position = Vector3(1.1, H - 0.55, 0.15)
		add_child(l)
