extends Node3D
## Small things that tell the Greenwood's story, built in code from the quarry kit's
## stone and oak: wayside shrines (a stone step, an oak post with a little shingled
## roof over a carved cross), stone mile markers along the Tithe Road, a hunters'
## high seat at the edge of the East Woods, a cart abandoned in the ruts of the ford
## track, and English ivy climbing the chapel and watchtower walls.
## Positions are world x, z (set back from the roads); heights come from the terrain.

@export var terrain: SculptedTerrain

## [x, z, yaw degrees] — facing the road they stand beside.
const SHRINES := [[10.5, 171.0, -90.0], [-61.0, 99.5, 160.0]]
## Mile stones on the Tithe Road verge: [x, z, yaw].
const MILESTONES := [[12.8, 79.0, -80.0], [8.0, -21.0, -95.0], [6.0, -82.0, -90.0], [3.6, -145.0, -90.0]]
## The hunters' high seat, looking out over the clearing below the crag: [x, z, yaw].
const HIGH_SEAT := [74.0, 62.0, 210.0]
## A cart left in the ruts of the ford track, one wheel sunk: [x, z, yaw].
const CART := [88.5, -62.5, 35.0]
## Ivy on walls: [x, z, yaw of the wall face (degrees, the way the face looks), width, height].
const IVY_WALLS := [
	[-49.0, 163.45, 0.0, 9.0, 3.8],    # chapel nave, south wall
	[-45.0, 163.4, 0.0, 3.0, 2.4],     # chapel nave, south wall, by the chancel
	[-55.5, 160.0, -90.0, 4.5, 4.5],   # chapel west gable
	[-49.0, 156.6, 180.0, 6.0, 1.8],   # chapel north wall (low)
]
## Ivy round the watchtower: [center x, z, radius, from angle, to angle (radians, world), height].
const IVY_TOWER := [105.0, 26.0, 4.15, 2.35, 3.95, 5.0]


func _ready() -> void:
	_build.call_deferred()


func _build() -> void:
	if terrain == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 7007
	var body := StaticBody3D.new()
	add_child(body)
	# Each prop is its own mesh (a mesh spanning the whole zone would be culled by its middle).
	for s: Array in SHRINES:
		var t := _tools()
		_shrine(t[0], t[1], _xf(s), rng, body)
		_flush(t)
	for m: Array in MILESTONES:
		var t := _tools()
		_milestone(t[0], _xf(m), rng, body)
		_flush(t)
	var ts := _tools()
	_high_seat(ts[1], _xf(HIGH_SEAT), rng, body)
	_flush(ts)
	for w: Array in IVY_WALLS:
		var t := _tools()
		_ivy_wall(t[2], w, rng)
		_flush(t)
	var ti := _tools()
	_ivy_tower(ti[2], rng)
	_flush(ti)
	_cart()
	if OS.get_cmdline_user_args().has("props_debug"):
		for c in get_children():
			if c is MeshInstance3D:
				print("PROPS ", (c as MeshInstance3D).get_aabb())


func _xf(a: Array) -> Transform3D:
	var x: float = a[0]
	var z: float = a[1]
	return Transform3D(Basis(Vector3.UP, deg_to_rad(float(a[2]))), Vector3(x, terrain.height_at(x, z), z) - global_position)


func _box(st: SurfaceTool, xf: Transform3D, center: Vector3, size: Vector3, rng: RandomNumberGenerator, jag: float, yaw := 0.0) -> void:
	var tmp := SurfaceTool.new()
	tmp.begin(Mesh.PRIMITIVE_TRIANGLES)
	QuarryKit.rock_box(tmp, center, size, yaw, rng, jag)
	for v: Vector3 in tmp.commit_to_arrays()[Mesh.ARRAY_VERTEX]:
		st.add_vertex(xf * v)


func _collide(body: StaticBody3D, xf: Transform3D, center: Vector3, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.transform = xf * Transform3D(Basis(), center)
	body.add_child(cs)


## A wayside shrine: a worn stone step, an oak post with a carved cross board under a
## small shingled pent roof, offerings of stones on the step.
func _shrine(stone: SurfaceTool, wood: SurfaceTool, xf: Transform3D, rng: RandomNumberGenerator, body: StaticBody3D) -> void:
	_box(stone, xf, Vector3(0, 0.12, 0), Vector3(1.3, 0.4, 0.9), rng, 0.08)
	_box(stone, xf, Vector3(0, 0.38, -0.05), Vector3(0.8, 0.2, 0.6), rng, 0.06)
	_box(wood, xf, Vector3(0, 1.3, -0.1), Vector3(0.22, 2.0, 0.22), rng, 0.02)
	# The cross: an upright and a bar on a backing board.
	_box(wood, xf, Vector3(0, 1.75, 0.02), Vector3(0.5, 0.6, 0.06), rng, 0.01)
	_box(stone, xf, Vector3(0, 1.75, 0.07), Vector3(0.08, 0.46, 0.04), rng, 0.0)
	_box(stone, xf, Vector3(0, 1.84, 0.07), Vector3(0.3, 0.07, 0.04), rng, 0.0)
	# Pent roof: two sloping boards and a ridge.
	for s: float in [-1.0, 1.0]:
		var tmp_xf := xf * Transform3D(Basis(Vector3(0, 0, 1), s * 0.55), Vector3(s * 0.26, 2.2, 0.0))
		_box(wood, tmp_xf, Vector3.ZERO, Vector3(0.62, 0.05, 0.6), rng, 0.02)
	_box(wood, xf, Vector3(0, 2.38, 0), Vector3(0.08, 0.08, 0.64), rng, 0.0)
	for i in 4:
		_box(stone, xf, Vector3(rng.randf_range(-0.35, 0.35), 0.5, rng.randf_range(0.0, 0.2)), Vector3.ONE * rng.randf_range(0.06, 0.12), rng, 0.3)
	_collide(body, xf, Vector3(0, 0.7, 0), Vector3(1.3, 1.4, 0.9))


## A mile marker: a squared stone, weathered and leaning a little, with a cut band near the top.
func _milestone(stone: SurfaceTool, xf: Transform3D, rng: RandomNumberGenerator, body: StaticBody3D) -> void:
	var lean := Basis(Vector3(1, 0, 0), rng.randf_range(-0.08, 0.08)) * Basis(Vector3(0, 0, 1), rng.randf_range(-0.06, 0.06))
	var lxf := xf * Transform3D(lean, Vector3.ZERO)
	_box(stone, lxf, Vector3(0, 0.45, 0), Vector3(0.45, 1.2, 0.32), rng, 0.06)
	_box(stone, lxf, Vector3(0, 0.95, 0), Vector3(0.5, 0.1, 0.36), rng, 0.04)
	_collide(body, xf, Vector3(0, 0.5, 0), Vector3(0.5, 1.0, 0.36))


## A hunters' high seat: four splayed oak legs, a plank floor 3 m up with a rail on three
## sides and a little roof, and a ladder up the back.
func _high_seat(wood: SurfaceTool, xf: Transform3D, rng: RandomNumberGenerator, body: StaticBody3D) -> void:
	var floor_y := 3.0
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var top := Vector3(c.x * 0.75, floor_y, c.y * 0.75)
		var foot := Vector3(c.x * 1.1, -0.2, c.y * 1.1)
		_pole(wood, xf, foot, top + Vector3(0, 1.6, 0), 0.09, rng)
	_box(wood, xf, Vector3(0, floor_y, 0), Vector3(1.8, 0.1, 1.8), rng, 0.02)
	for s: float in [-1.0, 1.0]:
		_box(wood, xf, Vector3(s * 0.85, floor_y + 0.8, 0), Vector3(0.08, 0.08, 1.7), rng, 0.02)
	_box(wood, xf, Vector3(0, floor_y + 0.8, 0.85), Vector3(1.7, 0.08, 0.08), rng, 0.02)
	_box(wood, xf, Vector3(0, floor_y + 1.7, 0), Vector3(2.0, 0.06, 2.0), rng, 0.02)
	# Ladder up the back (-z).
	for s: float in [-1.0, 1.0]:
		_pole(wood, xf, Vector3(s * 0.25, -0.1, -1.8), Vector3(s * 0.25, floor_y, -0.85), 0.04, rng)
	for k in 7:
		var t := (k + 0.5) / 7.0
		var p := Vector3(0, -0.1, -1.8).lerp(Vector3(0, floor_y, -0.85), t)
		_box(wood, xf, p, Vector3(0.55, 0.05, 0.06), rng, 0.0)
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		_collide(body, xf, Vector3(c.x * 0.9, 1.4, c.y * 0.9), Vector3(0.2, 2.8, 0.2))


func _pole(wood: SurfaceTool, xf: Transform3D, a: Vector3, b: Vector3, r: float, rng: RandomNumberGenerator) -> void:
	var tmp := SurfaceTool.new()
	tmp.begin(Mesh.PRIMITIVE_TRIANGLES)
	QuarryKit.rock_box(tmp, Vector3.ZERO, Vector3(r * 2.0, a.distance_to(b), r * 2.0), 0.0, rng, 0.02)
	var up := (b - a).normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	var basis := Basis(side, up, side.cross(up))
	var pxf := xf * Transform3D(basis, (a + b) * 0.5)
	for v: Vector3 in tmp.commit_to_arrays()[Mesh.ARRAY_VERTEX]:
		wood.add_vertex(pxf * v)


## The zone's own cart prop, tipped to one side as if a wheel had sunk and broken in the ruts.
func _cart() -> void:
	var ps := load("res://levels/tithelands/props/cart.tscn") as PackedScene
	if ps == null:
		return
	var cart := ps.instantiate() as Node3D
	add_child(cart)
	var x: float = CART[0]
	var z: float = CART[1]
	cart.global_position = Vector3(x, terrain.height_at(x, z) - 0.25, z)
	cart.rotation = Vector3(0.0, deg_to_rad(float(CART[2])), deg_to_rad(11.0))


## Ivy leaf cards flat against a wall face, thick at the foot and thinning upward, in
## ragged tongues rather than an even sheet.
func _ivy_wall(st: SurfaceTool, w: Array, rng: RandomNumberGenerator) -> void:
	var yaw := deg_to_rad(float(w[2]))
	var normal := Vector3(sin(yaw), 0.0, cos(yaw))
	var along := Vector3(cos(yaw), 0.0, -sin(yaw))
	var center := Vector3(w[0], 0.0, w[1])
	var width: float = w[3]
	var height: float = w[4]
	var tongues := int(width / 0.9) + 1
	for t in tongues:
		var u := (t + rng.randf_range(0.0, 0.8)) / tongues - 0.5
		var reach := height * rng.randf_range(0.35, 1.0)
		var n := int(reach * 30.0)
		for k in n:
			var h := pow(rng.randf(), 1.5) * reach
			var x := u * width + rng.randf_range(-0.45, 0.45) * (1.0 - h / reach * 0.6)
			var base := center + along * x
			var p := Vector3(base.x, terrain.height_at(base.x, base.z) - 0.2 + h, base.z) + normal * 0.06 - global_position
			_ivy_card(st, p, normal, along, rng.randf_range(0.5, 0.85), rng)


func _ivy_tower(st: SurfaceTool, rng: RandomNumberGenerator) -> void:
	var c := Vector3(IVY_TOWER[0], 0.0, IVY_TOWER[1])
	var r: float = IVY_TOWER[2]
	var a0: float = IVY_TOWER[3]
	var a1: float = IVY_TOWER[4]
	var height: float = IVY_TOWER[5]
	var ground := terrain.height_at(c.x, c.z)
	for k in 650:
		var a := lerpf(a0, a1, rng.randf())
		var mid := absf(a - (a0 + a1) * 0.5) / ((a1 - a0) * 0.5)
		var h := pow(rng.randf(), 1.4) * height * (1.0 - 0.5 * mid)
		var normal := Vector3(cos(a), 0.0, sin(a))
		var p := c + normal * (r + 0.05 - minf(h, 3.0) * 0.28) + Vector3(0, ground - 0.5 + h, 0) - global_position
		_ivy_card(st, p, normal, normal.cross(Vector3.UP), rng.randf_range(0.5, 0.85), rng)


func _ivy_card(st: SurfaceTool, p: Vector3, normal: Vector3, along: Vector3, size: float, rng: RandomNumberGenerator) -> void:
	var up := Vector3.UP.rotated(normal, rng.randf_range(-0.7, 0.7))
	var side := normal.cross(up).normalized()
	var h1 := side * size * 0.5
	var h2 := up * size * 0.5
	var corners := [p - h1 - h2, p + h1 - h2, p + h1 + h2, p - h1 + h2]
	var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	var tint := Color(1, 1, 1).lerp(Color(0.8, 0.85, 0.72), rng.randf())
	for i in [0, 1, 2, 0, 2, 3]:
		st.set_normal(normal)
		st.set_color(tint)
		st.set_uv(uvs[i])
		st.add_vertex(corners[i])


## [stone, wood, ivy] surface tools, each with a flag of whether anything went in.
func _tools() -> Array:
	var out := []
	for i in 3:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		out.append(st)
	return out


func _flush(t: Array) -> void:
	var mats: Array = [QuarryKit.stone_material(), QuarryKit.timber_material(), PlantKit._material("ivy")]
	for i in 3:
		var st: SurfaceTool = t[i]
		var arrays := st.commit_to_arrays()
		if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX] == null or (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():
			continue
		if i < 2:
			st.generate_normals()
		st.set_material(mats[i])
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		if i == 2:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
