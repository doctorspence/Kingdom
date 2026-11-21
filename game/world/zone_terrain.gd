@tool
class_name ZoneTerrain
extends Node3D
## The ground of a zone, built from a few shapes you can edit in the Inspector:
## gentle noise hills, raised edges, round hills and pits (quarry), a river
## channel, and flat strips for roads. Colors the ground by type (grass, mud,
## road, rock) and builds the collision so you can walk on it.
##
## Coordinates are meters, x = east, z = south (north is -z).

@export var size := 520.0:
	set(v):
		size = v
		_queue_rebuild()
@export var cell := 2.5:
	set(v):
		cell = maxf(v, 0.5)
		_queue_rebuild()
@export var hill_height := 5.0
@export var noise_seed := 7
## The ground rises this much at the zone's edges (a natural bowl).
@export var edge_rise := 26.0
@export var edge_width := 40.0
## River centerline (x, z points) and its width and depth.
@export var river := PackedVector2Array([Vector2(-260, -30), Vector2(-150, -15), Vector2(-60, -8), Vector2(0, -5), Vector2(80, 5), Vector2(170, -10), Vector2(260, 15)])
@export var river_width := 9.0
@export var river_depth := 1.6
## Road centerlines: each road is a list of points; roads are flattened.
@export var roads: Array[PackedVector2Array] = [
	PackedVector2Array([Vector2(0, 230), Vector2(0, 120), Vector2(2, 0), Vector2(0, -120), Vector2(0, -255)]),
	PackedVector2Array([Vector2(0, 160), Vector2(-60, 130), Vector2(-100, 60), Vector2(-115, -20)]),
	PackedVector2Array([Vector2(-115, -20), Vector2(-150, -90), Vector2(-165, -115)]),
	PackedVector2Array([Vector2(10, 180), Vector2(60, 160), Vector2(110, 100), Vector2(140, 55)]),
]
@export var road_width := 6.0
## Round hills (x, z, radius, height). Negative height = a pit.
@export var mounds := PackedVector4Array([Vector4(150, 40, 45, 11), Vector4(-190, -165, 55, -14), Vector4(80, -170, 50, 5)])
## Steepness of pit walls (higher = sheer cliffs).
@export var pit_sharpness := 3.0
@export var material: Material:
	set(v):
		material = v
		_queue_rebuild()

var _noise := FastNoiseLite.new()
var _built: Node3D
var _rebuild_queued := false


func _ready() -> void:
	add_to_group(&"zone_terrain")
	_rebuild()


func _queue_rebuild() -> void:
	if is_inside_tree() and not _rebuild_queued:
		_rebuild_queued = true
		_rebuild.call_deferred()


## Ground height (meters) at a world x, z. Also used to place things on the ground.
func height_at(x: float, z: float) -> float:
	var h := _noise.get_noise_2d(x, z) * hill_height + hill_height * 1.3
	h += _noise.get_noise_2d(x * 3.1 + 500.0, z * 3.1) * hill_height * 0.25
	# Edges rise into a bowl.
	var half := size * 0.5
	var d_edge := minf(half - absf(x), half - absf(z))
	if d_edge < edge_width:
		var t := 1.0 - clampf(d_edge / edge_width, 0.0, 1.0)
		h += edge_rise * t * t
	# Hills and pits.
	for m in mounds:
		var d := Vector2(x - m.x, z - m.y).length() / m.z
		if m.w >= 0.0:
			h += m.w * exp(-d * d * 2.0)
		else:
			var inside := 1.0 - smoothstep(0.8 - 0.25 / pit_sharpness, 0.8 + 0.25 / pit_sharpness, d)
			h += m.w * inside
	# Roads: flatten toward a smooth version of the ground.
	var road_d := _distance_to_lines(roads, Vector2(x, z))
	if road_d < road_width * 1.6:
		var smooth := _noise.get_noise_2d(x * 0.3, z * 0.3) * hill_height * 0.3 + hill_height * 1.3
		var t2 := smoothstep(road_width * 0.5, road_width * 1.6, road_d)
		h = lerpf(smooth, h, t2)
	# River channel.
	var river_d := _distance_to_line(river, Vector2(x, z))
	if river_d < river_width * 1.5:
		var t3 := 1.0 - smoothstep(river_width * 0.35, river_width * 1.5, river_d)
		h = lerpf(h, water_level() - river_depth, t3)
	return h


## The river's water surface height.
func water_level() -> float:
	return hill_height * 1.3 - 0.9


## How far a point is from the river centerline (for wading).
func river_distance(x: float, z: float) -> float:
	return _distance_to_line(river, Vector2(x, z))


func _rebuild() -> void:
	_rebuild_queued = false
	if not is_inside_tree():
		return
	_noise.seed = noise_seed
	_noise.frequency = 0.006
	_noise.fractal_octaves = 3
	if _built:
		_built.queue_free()
	var n := int(size / cell) + 1
	var half := size * 0.5
	var heights := PackedFloat32Array()
	heights.resize(n * n)
	for iz in n:
		for ix in n:
			heights[iz * n + ix] = height_at(-half + ix * cell, -half + iz * cell)
	# One vertex per grid point (colored once), triangles share them.
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	verts.resize(n * n)
	colors.resize(n * n)
	for iz in n:
		for ix in n:
			var i := iz * n + ix
			var v := Vector3(-half + ix * cell, heights[i], -half + iz * cell)
			verts[i] = v
			var hx := heights[i + 1] if ix < n - 1 else heights[i]
			var hz := heights[i + n] if iz < n - 1 else heights[i]
			var slope := (absf(hx - v.y) + absf(hz - v.y)) / cell
			colors[i] = _ground_color(v, slope)
	var indices := PackedInt32Array()
	var faces := PackedVector3Array()
	for iz in n - 1:
		for ix in n - 1:
			var a := iz * n + ix
			var b := a + 1
			var c := a + n
			var d := c + 1
			for idx in [a, b, d, a, d, c]:
				indices.append(idx)
				faces.append(verts[idx])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var st := SurfaceTool.new()
	st.create_from_arrays(arrays)
	st.generate_normals()
	var mesh := st.commit()
	_built = Node3D.new()
	_built.name = "Built"
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	_built.add_child(mi)
	var body := StaticBody3D.new()
	var shape := ConcavePolygonShape3D.new()
	# The mesh winds clockwise from above; collision wants the same faces.
	shape.set_faces(faces)
	shape.backface_collision = true
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	_built.add_child(body)
	# Water: a ribbon that follows the river only.
	var wst := SurfaceTool.new()
	wst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := river_width * 0.95
	for i in river.size() - 1:
		var a := river[i]
		var b := river[i + 1]
		var steps := maxi(1, int(a.distance_to(b) / 3.0))
		for s in steps:
			var p0 := a.lerp(b, float(s) / steps)
			var p1 := a.lerp(b, float(s + 1) / steps)
			var nrm := (p1 - p0).normalized().orthogonal() * w
			var y := water_level()
			var v0 := Vector3(p0.x - nrm.x, y, p0.y - nrm.y)
			var v1 := Vector3(p0.x + nrm.x, y, p0.y + nrm.y)
			var v2 := Vector3(p1.x - nrm.x, y, p1.y - nrm.y)
			var v3 := Vector3(p1.x + nrm.x, y, p1.y + nrm.y)
			for v in [v0, v2, v1, v1, v2, v3]:
				wst.set_normal(Vector3.UP)
				wst.add_vertex(v)
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.1, 0.14, 0.16, 0.8)
	wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	wmat.roughness = 0.08
	wmat.metallic = 0.3
	var water := MeshInstance3D.new()
	water.mesh = wst.commit()
	water.material_override = wmat
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_built.add_child(water)
	add_child(_built)


func _ground_color(v: Vector3, slope: float) -> Color:
	var p := Vector2(v.x, v.z)
	var grass := Color(0.24, 0.25, 0.16)
	var mud := Color(0.22, 0.18, 0.13)
	var road := Color(0.27, 0.23, 0.18)
	var rock := Color(0.33, 0.32, 0.3)
	var c := grass.lerp(mud, clampf(_noise.get_noise_2d(v.x * 4.0, v.z * 4.0) * 0.8 + 0.3, 0.0, 1.0))
	if _distance_to_lines(roads, p) < road_width * 0.55:
		c = road
	if _distance_to_line(river, p) < river_width * 0.9:
		c = mud.darkened(0.2)
	# Steep ground and pits are rock.
	if slope > 0.75 or v.y < -6.0:
		c = rock
	return c


func _distance_to_lines(lines: Array[PackedVector2Array], p: Vector2) -> float:
	var best := INF
	for line in lines:
		best = minf(best, _distance_to_line(line, p))
	return best


func _distance_to_line(line: PackedVector2Array, p: Vector2) -> float:
	var best := INF
	for i in line.size() - 1:
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, line[i], line[i + 1])))
	return best
