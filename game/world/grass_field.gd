class_name GrassField
extends Node3D
## Tufts of grass that grow around the camera: a few hundred per patch of
## ground, only on grassy ground (not roads, mud, rock or riverbanks), swaying
## in the wind. Patches far from you are removed, so the cost stays small
## however big the zone is. The same spot always grows the same grass.

@export var terrain: ZoneTerrain
## Size of one patch of ground (meters).
@export var chunk_size := 12.0
## How many patches out from the camera grass grows.
@export var view_chunks := 4
@export var tufts_per_chunk := 240
@export var seed_value := 3
@export var material: Material = preload("res://levels/common/materials/grass.tres")

var _chunks := {}  # Vector2i -> MultiMeshInstance3D
var _tuft: ArrayMesh
var _timer := 0.0
var _last_cell := Vector2i(99999, 99999)


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		set_process(false)  # nothing to see: keep the automated checks fast
		return
	_tuft = _make_tuft()


func _process(delta: float) -> void:
	_timer -= delta
	var cam := get_viewport().get_camera_3d()
	if cam == null or terrain == null or _timer > 0.0:
		return
	_timer = 0.15
	var here := _cell_of(cam.global_position)
	# Grow up to two missing patches per update (nearest first) so there is no hitch.
	var made := 0
	for ring in view_chunks + 1:
		for dz in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dz)) != ring:
					continue
				var cell := here + Vector2i(dx, dz)
				if not _chunks.has(cell) and made < 2:
					_chunks[cell] = _make_chunk(cell)
					made += 1
	# Remove patches that are now far behind you.
	for cell in _chunks.keys():
		if maxi(absi(cell.x - here.x), absi(cell.y - here.y)) > view_chunks + 2:
			(_chunks[cell] as Node).queue_free()
			_chunks.erase(cell)


func _cell_of(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / chunk_size), floori(p.z / chunk_size))


func _make_chunk(cell: Vector2i) -> MultiMeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(cell.x, cell.y, seed_value))
	var origin := Vector2(cell.x, cell.y) * chunk_size
	var spots: Array[Transform3D] = []
	for i in tufts_per_chunk:
		var x := origin.x + rng.randf() * chunk_size
		var z := origin.y + rng.randf() * chunk_size
		if absf(x) > terrain.size * 0.5 - 3.0 or absf(z) > terrain.size * 0.5 - 3.0:
			continue  # past the edge of the ground mesh: tufts would float in the air
		var y := terrain.height_at(x, z)
		var slope := (absf(terrain.height_at(x + 1.0, z) - y) + absf(terrain.height_at(x, z + 1.0) - y))
		if slope > 0.7 or y < terrain.water_level_at(x, z) + 0.3:
			continue
		var w := terrain._ground_weights(Vector3(x, y, z), slope)
		# Thicker where it is properly grassy, thin along edges, none on bare ground.
		if rng.randf() > pow(w.r, 1.6):
			continue
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.7, 1.5))
		spots.append(Transform3D(basis, Vector3(x, y - 0.04, z)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _tuft
	mm.instance_count = spots.size()
	for i in spots.size():
		mm.set_instance_transform(i, spots[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = (view_chunks + 0.5) * chunk_size
	mmi.visibility_range_end_margin = chunk_size
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(mmi)
	return mmi


## One tuft: seven thin, bent blades around a point.
func _make_tuft() -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for b in 5:
		var a := rng.randf() * TAU
		var dir := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-dir.z, 0, dir.x)
		var root := dir * rng.randf_range(0.0, 0.12)
		var height := rng.randf_range(0.26, 0.5)
		var lean := rng.randf_range(0.04, 0.2)
		var shade := rng.randf()
		var half := 0.032
		var b0 := root - side * half
		var b1 := root + side * half
		var m0 := root + dir * lean * 0.4 - side * half * 0.7 + Vector3.UP * height * 0.55
		var m1 := root + dir * lean * 0.4 + side * half * 0.7 + Vector3.UP * height * 0.55
		var tip := root + dir * lean + Vector3.UP * height
		_vert(st, b0, 0.0, shade)
		_vert(st, b1, 0.0, shade)
		_vert(st, m1, 0.55, shade)
		_vert(st, b0, 0.0, shade)
		_vert(st, m1, 0.55, shade)
		_vert(st, m0, 0.55, shade)
		_vert(st, m0, 0.55, shade)
		_vert(st, m1, 0.55, shade)
		_vert(st, tip, 1.0, shade)
	return st.commit()


func _vert(st: SurfaceTool, v: Vector3, height_factor: float, shade: float) -> void:
	st.set_color(Color(height_factor, shade, 0.0))
	st.set_normal(Vector3.UP)
	st.add_vertex(v)
