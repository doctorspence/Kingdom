class_name QuarryDescent
extends Node3D
## The way down into the Gullet: a hewn incline that starts where the quarry adit ends and
## winds down under the cliff to the Gullet's entrance yard, 52 m lower. You walk it; there
## is no door and no loading. The route is a few straight legs with flat landings at the
## corners. Everything underground is built here (floor ramp with timber cleats, rough walls
## and roof, oak frames, lanterns, collision).
##
## `path_s(pos)` tells the rest of the game how far along the tunnel a position is, so the
## light, sound and level-of-detail can fade in with depth instead of switching on a height.

const HW := 1.7          # half the clear width
const H := 3.7           # clear height above the floor
const PAD := 2.2         # flat floor either side of a corner (m)
const STEP := 1.0        # station spacing along the ramp (m)
const MOUTH_Y := 12.0    # the quarry floor at the adit
const YARD_Y := -40.0    # the Gullet's floor

## Centerline corners (world x, z). The first is the adit's mouth, the second where the adit
## ends and this tunnel begins; the last is inside the Gullet's new west doorway.
const CORNERS := [
	Vector2(-169.0, -98.0), Vector2(-178.0, -98.0), Vector2(-200.0, -98.0), Vector2(-200.0, -126.0),
	Vector2(-194.0, -126.0), Vector2(-194.0, -77.5), Vector2(-189.5, -77.5),
]

static var pts := PackedVector3Array()   # floor-center stations from the mouth to the yard
static var cum := PackedFloat32Array()   # distance along the path at each station
static var corner_idx := PackedInt32Array()
static var slope := 0.0

var _noise := FastNoiseLite.new()
var _tris := PackedVector3Array()        # collision


# ---- Route (static, so any system can ask about it) -----------------------------------------

static func compute() -> void:
	if pts.size() > 0:
		return
	var legs := CORNERS.size() - 1
	# Descending length: every leg after the first (flat) one, minus the pads at its corners; the last leg is flat.
	var total := 0.0
	for i in range(1, legs - 1):
		var leg_len := (CORNERS[i + 1] as Vector2).distance_to(CORNERS[i])
		total += leg_len - PAD * (1.0 if i == 1 else 2.0)
	slope = (MOUTH_Y - YARD_Y) / total
	var y := MOUTH_Y
	pts.append(Vector3(CORNERS[0].x, y, CORNERS[0].y))
	corner_idx.append(0)
	for i in legs:
		var a: Vector2 = CORNERS[i]
		var b: Vector2 = CORNERS[i + 1]
		var leg_len := a.distance_to(b)
		var dir := (b - a) / leg_len
		var desc_from := 0.0
		var desc_to := 0.0
		if i >= 1 and i < legs - 1:
			desc_from = PAD if i > 1 else 0.0
			desc_to = leg_len - PAD
		var t := 0.0
		var marks: Array[float] = [0.0]
		if desc_to > desc_from:
			marks.append(desc_from)
			var m := desc_from + STEP
			while m < desc_to - 0.01:
				marks.append(m)
				m += STEP
			marks.append(desc_to)
		marks.append(leg_len)
		var y0 := y
		for mk in marks:
			if mk <= 0.0:
				continue
			t = mk
			var yy := y0 - slope * (clampf(t, desc_from, desc_to) - desc_from) if desc_to > desc_from else y0
			var p := a + dir * t
			pts.append(Vector3(p.x, yy, p.y))
			if is_equal_approx(t, leg_len):
				corner_idx.append(pts.size() - 1)
			y = yy
	cum.resize(pts.size())
	cum[0] = 0.0
	for k in range(1, pts.size()):
		cum[k] = cum[k - 1] + pts[k].distance_to(pts[k - 1])


## Distance along the tunnel (m) of a world position inside it, or -1 if it is not in the tunnel.
static func path_s(p: Vector3) -> float:
	compute()
	var best := 2.7
	var s := -1.0
	var mid := Vector3(0, 1.8, 0)
	for k in range(pts.size() - 1):
		var a := pts[k] + mid
		var b := pts[k + 1] + mid
		var ab := b - a
		var l2 := ab.length_squared()
		if l2 < 0.0001:
			continue
		var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
		var d := p.distance_to(a + ab * t)
		if d < best:
			best = d
			s = cum[k] + t * sqrt(l2)
	return s


## 0 outside, rising to 1 a few strides inside: how deep underground the light and sound are.
static func depth_cave(p: Vector3) -> float:
	var s := path_s(p)
	if s < 0.0:
		return 0.0
	return smoothstep(3.0, 40.0, s)


# ---- Building -------------------------------------------------------------------------------

func _ready() -> void:
	compute()
	_noise.seed = 31
	_noise.frequency = 0.55
	var stone := SurfaceTool.new()
	stone.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wood := SurfaceTool.new()
	wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	_shell(stone)
	_frames_and_cleats(wood)
	var sm := QuarryKit.stone_material().duplicate() as StandardMaterial3D
	sm.albedo_color = Color(1, 1, 1)
	sm.vertex_color_use_as_albedo = true
	sm.cull_mode = BaseMaterial3D.CULL_BACK
	stone.generate_normals()
	stone.set_material(sm)
	wood.generate_normals()
	wood.set_material(QuarryKit.timber_material())
	for st: SurfaceTool in [stone, wood]:
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		add_child(mi)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(_tris)
	shape.backface_collision = true
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	_lanterns()


static func _hdir(a: Vector3, b: Vector3) -> Vector3:
	var d := Vector3(b.x - a.x, 0.0, b.z - a.z)
	return d.normalized() if d.length() > 0.0001 else Vector3.FORWARD


func _tint(y: float) -> Color:
	# Pale quarry limestone at the mouth, sinking to the Gullet's dark stone.
	var t := smoothstep(MOUTH_Y, MOUTH_Y - 30.0, y)
	return Color(0.95, 0.9, 0.82).lerp(Color(0.5, 0.47, 0.45), t)


## One triangle, wound so it faces `toward`.
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, toward: Vector3) -> void:
	var n := (b - a).cross(c - a)
	var pts3 := [a, c, b] if n.dot(toward) > 0.0 else [a, b, c]
	for v: Vector3 in pts3:
		st.set_color(_tint(v.y))
		st.add_vertex(v)
		_tris.append(v)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, toward: Vector3) -> void:
	_tri(st, a, b, c, toward)
	_tri(st, a, c, d, toward)


func _shell(st: SurfaceTool) -> void:
	# Start building at index 1: the adit (quarry_adit.gd) is the first 9 m.
	var n := pts.size()
	var left := PackedVector3Array()
	var right := PackedVector3Array()
	var outl := PackedVector3Array()
	for k in n:
		var d0 := _hdir(pts[k - 1], pts[k]) if k > 0 else _hdir(pts[k], pts[k + 1])
		var d1 := _hdir(pts[k], pts[k + 1]) if k < n - 1 else d0
		var n0 := Vector3(d0.z, 0, -d0.x)
		var n1 := Vector3(d1.z, 0, -d1.x)
		var m := n0 + n1
		var off := n1 * HW
		if m.length() > 0.001:
			var mu := m.normalized()
			off = mu * (HW / maxf(mu.dot(n1), 0.3))
		left.append(pts[k] + off)
		right.append(pts[k] - off)
		outl.append(off.normalized())
	const R := 4
	const C := 4
	for k in range(1, n - 1):
		var k2 := k + 1
		# Floor.
		_quad(st, left[k], right[k], right[k2], left[k2], Vector3.UP)
		# Walls: rows of vertices pushed outward by noise (never inward, so the width holds).
		for side in 2:
			var edge := left if side == 0 else right
			var sgn := 1.0 if side == 0 else -1.0
			for r in R:
				var p00 := _wall_pt(edge[k], outl[k] * sgn, pts[k].y, r, R)
				var p10 := _wall_pt(edge[k2], outl[k2] * sgn, pts[k2].y, r, R)
				var p11 := _wall_pt(edge[k2], outl[k2] * sgn, pts[k2].y, r + 1, R)
				var p01 := _wall_pt(edge[k], outl[k] * sgn, pts[k].y, r + 1, R)
				_quad(st, p00, p10, p11, p01, -outl[k] * sgn)
		# Roof: a grid across the width, pushed up by noise.
		for c in C:
			var a0 := _roof_pt(left[k], right[k], pts[k].y, c, C)
			var a1 := _roof_pt(left[k], right[k], pts[k].y, c + 1, C)
			var b0 := _roof_pt(left[k2], right[k2], pts[k2].y, c, C)
			var b1 := _roof_pt(left[k2], right[k2], pts[k2].y, c + 1, C)
			_quad(st, a0, a1, b1, b0, Vector3.DOWN)


func _wall_pt(edge: Vector3, out: Vector3, floor_y: float, r: int, rows: int) -> Vector3:
	var p := Vector3(edge.x, floor_y + H * float(r) / float(rows), edge.z)
	if r > 0 and r < rows:
		p += out * ((0.5 + 0.5 * _noise.get_noise_3dv(p)) * 0.3)
	return p


func _roof_pt(l: Vector3, r: Vector3, floor_y: float, c: int, cols: int) -> Vector3:
	var p := l.lerp(r, float(c) / float(cols))
	p.y = floor_y + H
	if c > 0 and c < cols:
		p.y += (0.5 + 0.5 * _noise.get_noise_3dv(p * 1.3)) * 0.35
	return p


# ---- Oak frames, cleats, lanterns -------------------------------------------------------------

## Position and horizontal direction `s` meters along the path.
func _at(s: float) -> Array:
	for k in range(pts.size() - 1):
		if s <= cum[k + 1]:
			var t := (s - cum[k]) / maxf(cum[k + 1] - cum[k], 0.0001)
			return [pts[k].lerp(pts[k + 1], t), _hdir(pts[k], pts[k + 1])]
	return [pts[pts.size() - 1], Vector3.RIGHT]


func _near_corner(s: float, margin: float) -> bool:
	for ci in corner_idx:
		if absf(cum[ci] - s) < margin:
			return true
	return false


static func _box(st: SurfaceTool, center: Vector3, basis: Basis, size: Vector3) -> void:
	var h := size * 0.5
	var c: Array[Vector3] = []
	for i in 8:
		c.append(center + basis * Vector3(h.x if i & 1 else -h.x, h.y if i & 2 else -h.y, h.z if i & 4 else -h.z))
	var faces := [[0, 2, 3, 1], [4, 5, 7, 6], [0, 1, 5, 4], [2, 6, 7, 3], [0, 4, 6, 2], [1, 3, 7, 5]]
	for f: Array in faces:
		var a: Vector3 = c[f[0]]
		var b: Vector3 = c[f[1]]
		var cc: Vector3 = c[f[2]]
		var d: Vector3 = c[f[3]]
		var nrm := (b - a).cross(cc - a)
		var mid := (a + b + cc + d) * 0.25
		var order := [a, cc, b, a, d, cc] if nrm.dot(mid - center) > 0.0 else [a, b, cc, a, cc, d]
		for v: Vector3 in order:
			st.add_vertex(v)


func _frames_and_cleats(st: SurfaceTool) -> void:
	var total := cum[cum.size() - 1]
	# Oak frames (two posts and a cap beam), every 4.5 m once the walls are solid.
	var s := 12.0
	while s < total - 6.0:
		if not _near_corner(s, 3.0):
			var a := _at(s)
			var p: Vector3 = a[0]
			var d: Vector3 = a[1]
			var lat := Vector3(d.z, 0, -d.x)
			var b := Basis.looking_at(d, Vector3.UP)
			for side: float in [-1.0, 1.0]:
				_box(st, p + lat * side * (HW - 0.15) + Vector3(0, H * 0.5 - 0.05, 0), Basis.IDENTITY, Vector3(0.3, H - 0.1, 0.3))
			_box(st, p + Vector3(0, H - 0.1, 0), b, Vector3(HW * 2.0 + 0.3, 0.34, 0.38))
		s += 4.5
	# Cleats across the ramp, so boots get a grip and the slope reads as a worked incline.
	for k in range(1, pts.size() - 1):
		var p0 := pts[k]
		var p1 := pts[k + 1]
		if p0.y - p1.y < 0.01:
			continue
		var f := (p1 - p0).normalized()
		var bas := Basis.looking_at(f, Vector3.UP)
		var l := p0.distance_to(p1)
		var t := 0.2
		while t < l:
			_box(st, p0 + f * t + Vector3.UP * 0.035, bas, Vector3(HW * 2.0 - 0.5, 0.07, 0.15))
			t += 0.9


func _lanterns() -> void:
	var lantern := load("res://assets/hideout/Lighting_Props/lantern.scn") as PackedScene
	var total := cum[cum.size() - 1]
	var s := 16.0
	var side := 1.0
	while s < total - 4.0:
		if not _near_corner(s, 2.5):
			var a := _at(s)
			var p: Vector3 = a[0]
			var d: Vector3 = a[1]
			var lat := Vector3(d.z, 0, -d.x)
			var pos := p + lat * side * (HW - 0.45) + Vector3(0, H - 1.0, 0)
			if lantern:
				var l := lantern.instantiate() as Node3D
				l.position = pos
				add_child(l)
			var light := OmniLight3D.new()
			light.light_color = Color(1.0, 0.62, 0.3)
			light.light_energy = 1.8
			light.omni_range = 8.5
			light.shadow_enabled = false
			light.distance_fade_enabled = true
			light.distance_fade_begin = 45.0
			light.distance_fade_length = 15.0
			light.position = pos + lat * side * -0.2 + Vector3(0, 0.2, 0)
			add_child(light)
			side = -side
		s += 9.0
