class_name StoneWalls
extends Node3D
## Dry-stone walls built stone by stone along the lines in the land script
## (land.walls, plus the edges of land.fields that ask for a wall): courses of
## lumpy stones, upright coping stones on top, square piers at intervals. The
## walls follow the ground and open where a road, track, building or the river
## is in the way. One mesh per 24 m of wall, simple box colliders.

@export var terrain: SculptedTerrain
@export var wall_seed := 4
## Walls farther than this are not drawn.
@export var seen_from := 160.0

const STONE_TEX := "res://assets/textures/cliff/"

var _mat: StandardMaterial3D
var _rng := RandomNumberGenerator.new()
var _body: StaticBody3D


func _ready() -> void:
	_build.call_deferred()


func _build() -> void:
	if terrain == null:
		return
	terrain.height_at(0, 0)
	var land: Object = terrain.land
	if land == null:
		return
	_rng.seed = wall_seed
	_mat = _material()
	_body = StaticBody3D.new()
	_body.name = "WallColliders"
	add_child(_body)
	var lines: Array = []
	if land.get("walls") != null:
		lines.append_array(land.walls)
	if land.get("fields") != null:
		for f in land.fields:
			if f.get("wall", true):
				var pts: PackedVector2Array = (f.poly as PackedVector2Array).duplicate()
				pts.append(pts[0])
				lines.append({"points": pts, "height": f.get("wall_height", 1.0), "gate": f.get("gate", 0)})
	for w in lines:
		_wall(w)


func _material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(STONE_TEX + "color.jpg")
	m.normal_enabled = true
	m.normal_texture = load(STONE_TEX + "normal.jpg")
	m.roughness_texture = load(STONE_TEX + "rough.jpg")
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.9, 0.9, 0.9)
	m.vertex_color_use_as_albedo = true
	return m


## Is this spot free for a wall? Not on roads, tracks, pads or in the river.
func _free(p: Vector2) -> bool:
	if terrain._distance_to_lines(terrain.roads, p) < 4.0:
		return false
	if terrain._distance_to_lines(terrain.tracks, p) < 1.7:
		return false
	if terrain.in_pad(p.x, p.y) > 0.05:
		return false
	if terrain.height_at(p.x, p.y) < terrain.water_level_at(p.x, p.y) + 0.4:
		return false
	return true


func _wall(w: Dictionary) -> void:
	var pts: PackedVector2Array = w.points
	var height := float(w.get("height", 1.1))
	var pier_every := float(w.get("piers", 0.0))
	var gate := int(w.get("gate", -1))
	# Walk the line in 0.25 m steps and cut it into free runs.
	var runs: Array = []
	var run := PackedVector2Array()
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var n := maxi(1, int(a.distance_to(b) / 0.25))
		for k in n:
			var p := a.lerp(b, float(k) / n)
			var gap := i == gate and k > n / 2 - 7 and k < n / 2 + 7  # a 3.5 m field gate
			if _free(p) and not gap:
				run.append(p)
			elif run.size() > 0:
				runs.append(run)
				run = PackedVector2Array()
	if run.size() > 0:
		runs.append(run)
	for r in runs:
		if r.size() < 8:
			continue  # less than 2 m: not worth a stub
		_run(r, height, pier_every)


func _run(r: PackedVector2Array, height: float, pier_every: float) -> void:
	# Arc length along the run.
	var s := PackedFloat32Array([0.0])
	for i in range(1, r.size()):
		s.append(s[i - 1] + r[i].distance_to(r[i - 1]))
	var total := s[s.size() - 1]
	var chunk_len := 24.0
	var start := 0.0
	while start < total - 0.01:
		var end := minf(start + chunk_len, total)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var origin := _at(r, s, (start + end) * 0.5)
		var o3 := Vector3(origin.x, terrain.height_at(origin.x, origin.y), origin.y)
		# Courses of stones.
		var y := 0.0
		var course := 0
		while y < height - 0.22:
			var ch := _rng.randf_range(0.15, 0.24)
			var t := (y + ch * 0.5) / height
			var thick := lerpf(0.66, 0.46, t)
			var u := start + (_rng.randf_range(0.0, 0.25) if course % 2 == 0 else 0.25)
			while u < end:
				var l := _rng.randf_range(0.22, 0.7) if _rng.randf() > 0.12 else _rng.randf_range(0.8, 1.05)
				var mid := minf(u + l * 0.5, end)
				var p := _at(r, s, mid)
				var dir := (_at(r, s, minf(mid + 0.2, total)) - _at(r, s, maxf(mid - 0.2, 0.0))).normalized()
				dir = dir.rotated(_rng.randf_range(-0.1, 0.1))
				var g := terrain.height_at(p.x, p.y)
				var sh := ch * _rng.randf_range(0.75, 1.15)
				var size := Vector3(minf(l, (end - u) * 2.0) * 0.93, sh, thick * _rng.randf_range(0.9, 1.12))
				_stone(st, Vector3(p.x, g + y + sh * 0.5 - 0.06 + _rng.randf_range(-0.03, 0.03), p.y) - o3, dir, size, _tint(y < 0.35), minf(size.y, size.x) * 0.22)
				u += l
			y += ch
			course += 1
		# Coping: stones on edge along the top.
		var u2 := start
		while u2 < end:
			var cw := _rng.randf_range(0.18, 0.34)
			var p := _at(r, s, minf(u2 + cw * 0.5, end))
			var dir := (_at(r, s, minf(u2 + 0.3, total)) - _at(r, s, maxf(u2 - 0.3, 0.0))).normalized()
			var g := terrain.height_at(p.x, p.y)
			var ht := _rng.randf_range(0.16, 0.27)
			_stone(st, Vector3(p.x, g + y + ht * 0.5 - 0.06, p.y) - o3, dir.rotated(_rng.randf_range(-0.2, 0.2)), Vector3(cw * 0.92, ht, _rng.randf_range(0.44, 0.56)), _tint(false), 0.045)
			u2 += cw
		# Piers.
		if pier_every > 0.0:
			var pu := ceilf(start / pier_every) * pier_every
			while pu <= end:
				_pier(st, r, s, pu, height, o3)
				pu += pier_every
		st.generate_normals()
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = _mat
		mi.position = o3
		mi.visibility_range_end = seen_from
		add_child(mi)
		# Colliders: one box per 3 m.
		var c := start
		while c < end - 0.2:
			var c1 := minf(c + 3.0, end)
			var a := _at(r, s, c)
			var b := _at(r, s, c1)
			var m := (a + b) * 0.5
			var shape := BoxShape3D.new()
			shape.size = Vector3(0.6, height + 0.3, maxf(a.distance_to(b), 0.3))
			var cs := CollisionShape3D.new()
			cs.shape = shape
			cs.position = Vector3(m.x, terrain.height_at(m.x, m.y) + (height + 0.3) * 0.5 - 0.1, m.y)
			cs.rotation.y = atan2(b.x - a.x, b.y - a.y)
			_body.add_child(cs)
			c = c1
		start = end


func _pier(st: SurfaceTool, r: PackedVector2Array, s: PackedFloat32Array, u: float, height: float, o3: Vector3) -> void:
	var total := s[s.size() - 1]
	var p := _at(r, s, clampf(u, 0.0, total))
	var dir := (_at(r, s, minf(u + 0.3, total)) - _at(r, s, maxf(u - 0.3, 0.0))).normalized()
	var g := terrain.height_at(p.x, p.y)
	var y := 0.0
	while y < height + 0.2:
		var ch := _rng.randf_range(0.18, 0.26)
		_stone(st, Vector3(p.x, g + y + ch * 0.5 - 0.06, p.y) - o3, dir.rotated(_rng.randf_range(-0.04, 0.04)), Vector3(0.92, ch * 0.95, 0.92), _tint())
		y += ch
	_stone(st, Vector3(p.x, g + y + 0.07, p.y) - o3, dir, Vector3(1.08, 0.14, 1.08), _tint(), 0.015)


func _tint(low := false) -> Color:
	var base := _rng.randf_range(0.42, 0.82)
	var warm := _rng.randf_range(-0.06, 0.08)
	var c := Color(base + warm, base, base - warm * 0.6)
	# Lichen and moss, more on the lower courses that stay damp.
	if _rng.randf() < (0.35 if low else 0.15):
		c = c.lerp(Color(0.42, 0.5, 0.3), _rng.randf_range(0.2, 0.45))
	return c


## A lumpy stone: a box with jittered corners, aligned to the wall.
func _stone(st: SurfaceTool, c: Vector3, dir: Vector2, size: Vector3, tint: Color, jitter := 0.035) -> void:
	var fwd := Vector3(dir.x, 0.0, dir.y)
	var side := Vector3(-dir.y, 0.0, dir.x)
	var h := size * 0.5
	var corners: Array[Vector3] = []
	for k in 8:
		var sx := -1.0 if k & 1 == 0 else 1.0
		var sy := -1.0 if k & 2 == 0 else 1.0
		var sz := -1.0 if k & 4 == 0 else 1.0
		var j := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * jitter
		corners.append(c + fwd * (sx * h.x + j.x) + Vector3.UP * (sy * h.y + j.y) + side * (sz * h.z + j.z))
	var faces := [[0, 1, 3, 2], [4, 6, 7, 5], [0, 2, 6, 4], [1, 5, 7, 3], [2, 3, 7, 6], [0, 4, 5, 1]]
	for f in faces:
		var col := tint
		if f == [2, 3, 7, 6]:
			col = tint.lerp(Color(0.55, 0.62, 0.38), 0.35)  # moss on top
		elif f == [0, 4, 5, 1]:
			col = tint.darkened(0.4)
		for idx in [f[0], f[1], f[2], f[0], f[2], f[3]]:
			st.set_color(col)
			st.add_vertex(corners[idx])


func _at(r: PackedVector2Array, s: PackedFloat32Array, u: float) -> Vector2:
	# Point at arc length u (binary search).
	var lo := 0
	var hi := s.size() - 1
	while hi - lo > 1:
		var mid := (lo + hi) / 2
		if s[mid] < u:
			lo = mid
		else:
			hi = mid
	var t := clampf((u - s[lo]) / maxf(s[hi] - s[lo], 0.0001), 0.0, 1.0)
	return r[lo].lerp(r[hi], t)
