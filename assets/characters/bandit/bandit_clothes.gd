extends RefCounted
## Cloth and footwear: the dirty tunic with its ragged, split skirt, short ragged grey-olive
## sleeves, baggy trousers, cuffed leather boots, and a ragged brown cowl with its hood down.

const Shape := preload("res://assets/characters/bandit/bandit_shape.gd")
const Mesh_ := preload("res://assets/characters/bandit/bandit_mesh.gd")
const Body := preload("res://assets/characters/bandit/bandit_body.gd")

## Boot foot cross-sections from heel to toe: [z, half width, height].
const FOOT := [
	[-0.118, 0.040, 0.078], [-0.092, 0.058, 0.118], [-0.040, 0.062, 0.146], [0.010, 0.062, 0.120],
	[0.062, 0.068, 0.090], [0.122, 0.066, 0.074], [0.178, 0.044, 0.052],
]
const FOOT_X := 0.094


static func build(m, o: Dictionary) -> void:
	m.group = "Clothing"
	m.density = 1.0
	_tunic(m)
	_skirt(m)
	_trousers(m)
	for s in [1.0, -1.0]:
		_sleeve(m, s)
		_leg(m, s)
		_boot(m, s)
	match o.cowl:
		"full":
			_cowl(m, false, not o.hood)
		"ragged":
			_cowl(m, true, not o.hood)
		_:
			_collar(m)
	if o.hood:
		_hood(m)
	if o.mask:
		_mask(m)
	if o.cloak:
		_cloak(m)
	if o.get("fur", false):
		_fur(m)
	if o.get("noose", false):
		_noose(m)


static func _tunic(m) -> void:
	var rings := []
	for y in [0.96, 1.05, 1.15, 1.24, 1.33, 1.41, 1.47, 1.52, 1.552]:
		rings.append(Shape.torso_ring(y, 0.0, 14))
	m.loft("tunic", rings, Shape.torso_weights)


## The tunic's hem: mid-thigh, jagged, split at the front so the legs can move.
static func _skirt(m) -> void:
	# [height, half width, front z, back z, front split (radians)]
	var rows := [
		[1.040, 0.160, 0.122, -0.128, 0.015], [0.955, 0.188, 0.134, -0.148, 0.035],
		[0.855, 0.204, 0.140, -0.158, 0.100], [0.755, 0.216, 0.148, -0.162, 0.170],
	]
	var jag := [-0.070, 0.030, -0.040, 0.020, -0.085, 0.012, -0.045, 0.035, -0.065, 0.018, -0.050,
			0.026, -0.078, 0.012, -0.038, 0.030, -0.062, 0.016, -0.072]
	var n := 19
	var rings := []
	for k in rows.size():
		var r: Array = rows[k]
		var cz: float = (r[2] + r[3]) * 0.5
		var hd: float = (r[2] - r[3]) * 0.5
		var ring := []
		for i in n:
			var a := lerpf(r[4], TAU - r[4], float(i) / (n - 1))
			var s := sin(a)
			var c := cos(a)
			var p := Vector3(signf(s) * pow(absf(s), 0.78) * r[1], r[0], cz + signf(c) * pow(absf(c), 0.78) * hd)
			if k == rows.size() - 1:
				p.y += jag[i]
			ring.append(p)
		rings.append(ring)
	m.loft("tunic_skirt", rings, skirt_weights, {"closed": false, "inside": Vector3(0, 0.9, -0.01)})


## The hem follows the pelvis at the top and each thigh more and more toward the bottom.
static func skirt_weights(p: Vector3) -> Dictionary:
	var legs := clampf((1.03 - p.y) / 0.22, 0.0, 1.0) * 0.82
	var left := clampf(0.5 + p.x / 0.11, 0.0, 1.0)
	return {"pelvis": 1.0 - legs, "thigh_l": legs * left, "thigh_r": legs * (1.0 - left)}


## Hips and crotch under the skirt.
static func _trousers(m) -> void:
	var rings := []
	for r in [[0.835, 0.070, 0.060, -0.080], [0.900, 0.150, 0.092, -0.118], [0.975, 0.152, 0.092, -0.114], [1.03, 0.140, 0.092, -0.106]]:
		var cz: float = (r[2] + r[3]) * 0.5
		var hd: float = (r[2] - r[3]) * 0.5
		var ring := []
		for i in 12:
			var a := PI + TAU * i / 12.0
			ring.append(Vector3(sin(a) * r[1], r[0], cz + cos(a) * hd))
		rings.append(ring)
	var w := func(p: Vector3) -> Dictionary:
		if p.y > 0.95:
			return {"pelvis": 1.0}
		return {"pelvis": 0.55, Shape.sided("thigh", p.x if absf(p.x) > 0.001 else 1.0): 0.45}
	m.loft("trousers", rings, w, {"cap_start": true})


static func _leg(m, s: float) -> void:
	var thigh: String = Shape.sided("thigh", s)
	var calf: String = Shape.sided("calf", s)
	# [height, |x|, centre z, half width, half depth]
	var rows := [
		[0.955, 0.086, -0.008, 0.086, 0.100], [0.840, 0.094, -0.006, 0.090, 0.096], [0.690, 0.095, -0.004, 0.078, 0.082],
		[0.590, 0.094, -0.004, 0.066, 0.068], [0.535, 0.094, -0.002, 0.064, 0.074], [0.485, 0.095, -0.014, 0.080, 0.086],
		[0.435, 0.094, -0.018, 0.074, 0.080], [0.395, 0.093, -0.020, 0.056, 0.060],
	]
	var ws := [{"pelvis": 0.5, thigh: 0.5}, {"pelvis": 0.12, thigh: 0.88}, {thigh: 1.0}, {thigh: 0.8, calf: 0.2},
			{thigh: 0.5, calf: 0.5}, {thigh: 0.15, calf: 0.85}, {calf: 1.0}, {calf: 1.0}]
	var rings := []
	for i in rows.size():
		var r: Array = rows[i]
		var ring := Mesh_.ring(Vector3(r[1] * s, r[0], r[2]), Vector3.RIGHT, Vector3.BACK, r[3] * 1.08, r[4] * 1.08, 9, 2.3, -PI * 0.5)
		# creases: the baggy cloth above the boot is uneven
		if i == 5 or i == 6:
			for j in ring.size():
				ring[j].y += 0.012 * sin(j * 2.4 + i)
		rings.append(ring)
	m.loft("trousers", rings, ws)


static func _boot(m, s: float) -> void:
	var calf: String = Shape.sided("calf", s)
	var foot: String = Shape.sided("foot", s)
	var ball: String = Shape.sided("ball", s)
	# shaft
	var rows := [[0.405, -0.020, 0.068, 0.070], [0.300, -0.024, 0.065, 0.071], [0.200, -0.032, 0.056, 0.060], [0.115, -0.040, 0.054, 0.062], [0.065, -0.040, 0.056, 0.064]]
	var ws := [{calf: 1.0}, {calf: 1.0}, {calf: 1.0}, {calf: 0.5, foot: 0.5}, {foot: 1.0}]
	var rings := []
	for r in rows:
		rings.append(Mesh_.ring(Vector3(0.093 * s, r[0], r[1]), Vector3.RIGHT, Vector3.BACK, r[2], r[3], 8, 2.4, PI / 8.0))
	m.loft("boot", rings, ws)
	# the folded cuff at the top
	var cuff := []
	for r in [[0.352, -0.022, 0.076, 0.080], [0.365, -0.022, 0.089, 0.093], [0.445, -0.018, 0.083, 0.087], [0.440, -0.018, 0.062, 0.066]]:
		var ring := Mesh_.ring(Vector3(0.093 * s, r[0], r[1]), Vector3.RIGHT, Vector3.BACK, r[2], r[3], 8, 2.4, PI / 8.0)
		cuff.append(ring)
	m.loft("boot_cuff", cuff, {calf: 1.0}, {"inside": Vector3(0.093 * s, 0.40, -0.02)})
	# ankle strap
	var strap := []
	for r in [[0.150, 0.061, 0.070], [0.182, 0.060, 0.067]]:
		strap.append(Mesh_.ring(Vector3(0.093 * s, r[0], -0.035), Vector3.RIGHT, Vector3.BACK, r[1], r[2], 8, 2.4, PI / 8.0))
	m.loft("strap", strap, {calf: 0.7, foot: 0.3})
	# foot: a thick sole ledge under a rounded upper, toe turned slightly out
	var frings := []
	var fws := []
	for r in FOOT:
		var z: float = r[0]
		var hw: float = r[1]
		var h: float = r[2]
		var cx := (FOOT_X + maxf(z, 0.0) * 0.12) * s
		var ring := []
		for q in [[-1.0, 0.0, 0.006], [1.0, 0.0, 0.006], [1.0, 0.024, 0.006], [0.93, 0.030, 0.0], [0.82, h * 0.74, 0.0],
				[0.40, h, 0.0], [-0.40, h, 0.0], [-0.82, h * 0.74, 0.0], [-0.93, 0.030, 0.0], [-1.0, 0.024, 0.006]]:
			var x: float = q[0] * hw + signf(q[0]) * q[2]
			ring.append(Vector3(cx + x, q[1], z))
		frings.append(ring)
		if z < 0.05:
			fws.append({foot: 1.0})
		elif z < 0.10:
			fws.append({foot: 0.55, ball: 0.45})
		else:
			fws.append({ball: 1.0})
	m.loft("boot_foot", frings, fws, {"cap_start": true, "cap_end": true})


static func _sleeve(m, s: float) -> void:
	# [|x|, y, z, radius up/down, radius front/back]
	var rows := [
		[0.125, 1.420, -0.040, 0.076, 0.082], [0.188, 1.436, -0.058, 0.092, 0.092], [0.250, 1.440, -0.065, 0.083, 0.085],
		[0.318, 1.440, -0.068, 0.076, 0.078], [0.372, 1.440, -0.069, 0.078, 0.081],
	]
	var rings := []
	for k in rows.size():
		var r: Array = rows[k]
		var ring := Shape.arm_ring(s, r[0], r[1], r[2], r[3], r[4], 10)
		if k == rows.size() - 1:
			var jag := [0.022, -0.020, 0.012, -0.028, 0.028, -0.010, 0.016, -0.024, 0.006, -0.016]
			for i in ring.size():
				ring[i].x += jag[i] * s
		rings.append(ring)
	m.loft("sleeve", rings, Shape.arm_weights)


## A plain turned collar for those who go without a cowl.
static func _collar(m) -> void:
	var rings := []
	for r in [[1.500, 0.122, 0.082, -0.126], [1.540, 0.092, 0.068, -0.102], [1.566, 0.070, 0.052, -0.084]]:
		rings.append(_cowl_ring(12, r[0], r[1], r[2], r[3], 0.006))
	m.loft("trim", rings, cowl_weights, {"inside": Vector3(0, 1.48, -0.02)})


## The cowl: a thick roll round the neck falling to ragged points on the chest and back.
## `ragged` = shorter in front and torn all round; `folded_hood` = its hood hangs down the back.
static func _cowl(m, ragged: bool, folded_hood: bool) -> void:
	var n := 16
	var neck := _cowl_ring(n, 1.545, 0.066, 0.056, -0.084, 0.012)
	var roll := _cowl_ring(n, 1.578, 0.102, 0.088, -0.122, 0.022)
	var fold := _cowl_ring(n, 1.536, 0.152, 0.128, -0.170, 0.010)
	# the outer edge, point by point from the front round the left side to the back and home
	var left := [
		Vector3(0.000, 1.265, 0.176), Vector3(0.056, 1.372, 0.172), Vector3(0.114, 1.388, 0.164), Vector3(0.162, 1.478, 0.116),
		Vector3(0.208, 1.522, -0.016), Vector3(0.172, 1.470, -0.134), Vector3(0.124, 1.396, -0.188), Vector3(0.066, 1.366, -0.194),
		Vector3(0.000, 1.282, -0.196),
	]
	var edge := []
	for i in n:
		var j := i if i <= 8 else n - i
		var p: Vector3 = left[j]
		if i > 8:
			p.x = -p.x
			p.y += [0.0, 0.024, -0.016, 0.006, -0.008, -0.020, 0.018, -0.014][j]
		if ragged:
			if j == 0:
				p.y = 1.372
			elif j == 8:
				p.y = 1.335
			p.y += 0.022 if i % 2 == 0 else -0.026
			p.x *= 1.07
			if p.z < 0.0:
				p.z -= 0.012
		edge.append(p)
	# a ragged inner crease between the fold and the edge keeps the drape outside the vest
	var drape := []
	for i in n:
		var d: Vector3 = (fold[i] as Vector3).lerp(edge[i], 0.55)
		d += Vector3(d.x * 0.10, 0.012 if i % 2 == 0 else -0.004, signf(d.z) * 0.018)
		drape.append(d)
	m.loft("cowl", [neck, roll, fold, drape, edge], cowl_weights, {"inside": Vector3(0, 1.38, -0.02)})
	if not folded_hood:
		return
	# the hood, folded down the back
	var top_l := Vector3(0.100, 1.560, -0.150)
	var top_r := Vector3(-0.100, 1.560, -0.150)
	var mid := Vector3(0.0, 1.500, -0.236)
	var low := Vector3(0.014, 1.352, -0.208)
	var side_l := Vector3(0.112, 1.462, -0.192)
	var side_r := Vector3(-0.106, 1.448, -0.192)
	var inside := Vector3(0, 1.47, -0.12)
	for tri in [[top_l, mid, top_r], [top_l, side_l, mid], [top_r, mid, side_r], [side_l, low, mid], [side_r, mid, low]]:
		m.poly("hood", tri, cowl_weights, inside)


## A deep hood drawn up over the head, open round the face, dark inside.
static func _hood(m) -> void:
	# where the hood's front edge crosses each row
	const FRONT_Y := [1.530, 1.610, 1.690, 1.722, 1.752, 1.774]
	# [height, half width, front edge z, back z]
	var rows := [
		[1.530, 0.128, 0.066, -0.158], [1.610, 0.134, 0.108, -0.168], [1.690, 0.134, 0.136, -0.174],
		[1.765, 0.128, 0.150, -0.178], [1.825, 0.108, 0.150, -0.166], [1.868, 0.070, 0.134, -0.142],
	]
	var outer := []
	var lining := []
	for r in rows:
		var y: float = r[0]
		var hw: float = r[1]
		var f: float = r[2]
		var b: float = r[3]
		var half := [Vector2(hw * 0.80, f), Vector2(hw, f * 0.35), Vector2(hw * 0.94, b * 0.55), Vector2(hw * 0.46, b * 0.94)]
		var ring := []
		for q: Vector2 in half:
			ring.append(Vector3(q.x, y, q.y))
		ring.append(Vector3(0.0, y + 0.006, b))
		for i in range(3, -1, -1):
			ring.append(Vector3(-half[i].x, y, half[i].y))
		# the front edge dips toward the middle, shading the forehead
		var edge_y: float = FRONT_Y[outer.size()]
		ring[0].y = edge_y
		ring[8].y = edge_y
		outer.append(ring)
		var inner := []
		for p: Vector3 in ring:
			inner.append(Vector3(p.x * 0.93, p.y - 0.008, p.z * 0.93 - 0.003))
		lining.append(inner)
	# the crown comes to a soft point at the back
	var apex := Vector3(0.0, 1.893, -0.062)
	var brim := Vector3(0.0, 1.782, 0.156)
	var top: Array = outer[outer.size() - 1]
	var w := func(p: Vector3) -> Dictionary:
		if p.y < 1.56:
			return {"spine_03": 0.3, "neck_01": 0.4, "Head": 0.3}
		return {"Head": 1.0}
	var inside := Vector3(0, 1.70, -0.01)
	m.loft("hood_up", outer, w, {"closed": false, "inside": inside})
	m.loft("hood_lining", lining, w, {"closed": false, "inside": inside})
	for i in top.size() - 1:
		m.poly("hood_up", [top[i], top[i + 1], apex], w, inside)
	m.poly("hood_up", [top[0], apex, brim], w, inside)
	m.poly("hood_up", [apex, top[top.size() - 1], brim], w, inside)
	# the rolled hem round the face
	var edge := []
	for ring: Array in outer:
		edge.append(ring[0])
	edge.append(brim)
	for k in range(outer.size() - 1, -1, -1):
		edge.append(outer[k][outer[k].size() - 1])
	for i in edge.size() - 1:
		m.bar("hood_edge", edge[i], edge[i + 1], 0.016, 0.012, Vector3.BACK, w)


## A cloth tied over nose and mouth.
static func _mask(m) -> void:
	# [angle (degrees), height, distance out from the head] for the top, middle and bottom edges
	var rows := [
		[[-88.0, 1.690, 0.006], [-55.0, 1.674, 0.012], [-26.0, 1.672, 0.016], [0.0, 1.678, 0.030], [26.0, 1.672, 0.016], [55.0, 1.674, 0.012], [88.0, 1.690, 0.006]],
		[[-88.0, 1.650, 0.008], [-55.0, 1.628, 0.016], [-26.0, 1.622, 0.022], [0.0, 1.630, 0.046], [26.0, 1.622, 0.022], [55.0, 1.628, 0.016], [88.0, 1.650, 0.008]],
		[[-88.0, 1.612, 0.006], [-55.0, 1.580, 0.012], [-26.0, 1.550, 0.018], [0.0, 1.526, 0.022], [26.0, 1.550, 0.018], [55.0, 1.580, 0.012], [88.0, 1.612, 0.006]],
	]
	var rings := []
	for row: Array in rows:
		var ring := []
		for c: Array in row:
			var a := deg_to_rad(c[0])
			var head: Array = Body.head_ring(clampf(c[1], 1.570, 1.75), c[2])
			var rx := absf((head[3] as Vector3).x)
			var rz := (head[6] as Vector3).z - Body.HEAD_Z
			ring.append(Vector3(signf(sin(a)) * pow(absf(sin(a)), 0.8) * rx, c[1], Body.HEAD_Z + pow(maxf(cos(a), 0.0), 0.8) * rz))
		rings.append(ring)
	m.loft("mask", rings, {"Head": 1.0}, {"closed": false, "inside": Vector3(0, 1.62, -0.02)})


## A long torn cloak from the shoulders to the calves.
static func _cloak(m) -> void:
	# [height, half width, back z at the middle, z at the side edges]
	var rows := [
		[1.500, 0.150, -0.172, -0.140], [1.400, 0.212, -0.205, -0.140], [1.230, 0.220, -0.208, -0.135],
		[1.060, 0.232, -0.222, -0.140], [0.860, 0.258, -0.248, -0.152], [0.660, 0.278, -0.268, -0.165], [0.520, 0.290, -0.280, -0.175],
	]
	var jag := [-0.040, -0.120, 0.015, -0.085, -0.010, -0.140, 0.010, -0.070, -0.030, -0.105, 0.000]
	var n := 11
	var rings := []
	for k in rows.size():
		var r: Array = rows[k]
		var ring := []
		for i in n:
			var t := float(i) / (n - 1) * 2.0 - 1.0
			var p := Vector3(t * r[1], r[0], lerpf(r[2], r[3], pow(absf(t), 2.2)))
			# hanging folds
			if k > 0:
				p.z += (0.016 if i % 2 == 0 else -0.008) * minf(k / 3.0, 1.0)
			if k == rows.size() - 1:
				p.y += jag[i]
			ring.append(p)
		rings.append(ring)
	m.loft("cloak", rings, cloak_weights, {"closed": false, "inside": Vector3(0, 1.0, 0.1)})


## The cloak hangs from the shoulders; lower down it swings a little with each leg.
static func cloak_weights(p: Vector3) -> Dictionary:
	if p.y > 1.42:
		var side := smoothstep(0.08, 0.18, absf(p.x))
		return {"spine_03": 1.0 - side * 0.35, Shape.sided("clavicle", p.x): side * 0.35}
	if p.y > 1.20:
		return Shape.blend("spine_02", "spine_03", (p.y - 1.20) / 0.22)
	if p.y > 1.02:
		return Shape.blend("pelvis", "spine_02", (p.y - 1.02) / 0.18)
	var legs := clampf((1.02 - p.y) / 0.45, 0.0, 1.0) * 0.6
	var left := clampf(0.5 + p.x / 0.20, 0.0, 1.0)
	return {"pelvis": 1.0 - legs, "thigh_l": legs * left, "thigh_r": legs * (1.0 - left)}


## A shaggy fur mantle over the shoulders, its outline broken into pointed tufts.
static func _fur(m) -> void:
	var n := 18
	var neck := _cowl_ring(n, 1.556, 0.074, 0.058, -0.092, 0.010)
	var crest := _cowl_ring(n, 1.600, 0.150, 0.118, -0.168, 0.012)
	var shoulder := []
	var edge := []
	for i in n:
		var a := TAU * i / n
		var side := pow(sin(a), 2.0)
		var back := maxf(-cos(a), 0.0)
		# high over the shoulders, dipping to the chest and the back
		var rough := 0.012 if i % 2 == 0 else -0.012
		shoulder.append(Vector3(sin(a) * 0.236, lerpf(1.500, 1.566, side) + rough * 0.5,
				-0.025 + cos(a) * lerpf(0.200, 0.212, back)))
		edge.append(Vector3(sin(a) * 0.292, lerpf(lerpf(1.415, 1.385, back), 1.514, side) + rough * 1.6,
				-0.025 + cos(a) * lerpf(0.222, 0.235, back)))
	var inside := Vector3(0, 1.40, -0.02)
	m.loft("fur", [neck, crest, shoulder, edge], cowl_weights, {"inside": inside})
	# tufts hanging from the edge, and a few standing up along the crest
	for i in n:
		var a: Vector3 = edge[i]
		var b: Vector3 = edge[(i + 1) % n]
		var mid := (a + b) * 0.5
		var out := Vector3(mid.x, 0.0, mid.z + 0.025).normalized()
		var drop := 0.075 if i % 2 == 0 else 0.048
		var tip := mid + out * 0.016 + Vector3.DOWN * drop * (1.0 - smoothstep(0.14, 0.26, absf(mid.x)) * 0.55)
		m.poly("fur", [a, b, tip], cowl_weights, inside)
		var c: Vector3 = crest[i]
		var d: Vector3 = crest[(i + 1) % n]
		var up := (c + d) * 0.5
		up += Vector3(up.x * 0.10, 0.016 if i % 3 == 0 else 0.004, (up.z + 0.025) * 0.10)
		m.poly("fur", [c, d, up], cowl_weights, inside)


## Hobb's rope: two turns round the neck, a fat knot, and the cut end hanging down the chest.
static func _noose(m) -> void:
	var neck := {"neck_01": 0.35, "spine_03": 0.65}
	var n := 12
	for turn in 2:
		var radius := 0.092 - turn * 0.012
		var pts := []
		for i in n:
			var a := TAU * i / n
			pts.append(Vector3(sin(a) * radius, 1.552 + turn * 0.026 - cos(a) * 0.022, -0.016 + cos(a) * radius * 1.08))
		for i in n:
			var p: Vector3 = pts[i]
			var q: Vector3 = pts[(i + 1) % n]
			m.bar("rope", p, q + (q - p) * 0.12, 0.024, 0.024, Vector3.UP, neck)
	# the knot sits off-centre, where the loop meets the collar
	var knot := Shape.torso_face(0.036, 1.476, 1.0, 0.042)
	var rings := []
	for r in [[0.052, 0.014], [0.036, 0.030], [0.004, 0.026], [-0.004, 0.032], [-0.038, 0.029], [-0.050, 0.015]]:
		rings.append(Mesh_.ring(knot + Vector3(0, r[0], 0), Vector3.RIGHT, Vector3.BACK, r[1], r[1] * 0.85, 7))
	m.loft("rope", rings, Shape.torso_weights, {"cap_start": true, "cap_end": true})
	m.bar("rope", Vector3(0.050, 1.556, 0.070), knot + Vector3(0, 0.046, -0.006), 0.024, 0.024, Vector3.BACK, neck)
	var path := [knot + Vector3(0, -0.044, 0)]
	for q in [[0.050, 1.385], [0.058, 1.310], [0.052, 1.245]]:
		path.append(Shape.torso_face(q[0], q[1], 1.0, 0.040))
	for i in path.size() - 1:
		m.bar("rope", path[i], path[i + 1], 0.022, 0.022, Vector3.BACK, Shape.torso_weights)
	# frayed strands at the cut end
	var end: Vector3 = path[path.size() - 1]
	for x in [-0.018, 0.0, 0.017]:
		m.bar("rope", end, end + Vector3(x, -0.044 - absf(x) * 0.6, 0.004), 0.008, 0.008, Vector3.BACK, Shape.torso_weights)


static func _cowl_ring(n: int, y: float, hw: float, front: float, back: float, jitter: float) -> Array:
	var cz := (front + back) * 0.5
	var hd := (front - back) * 0.5
	var out := []
	for i in n:
		var a := TAU * i / n
		var p := Vector3(sin(a) * hw, y, cz + cos(a) * hd)
		# higher at the back, lower and uneven at the front
		p.y += -cos(a) * jitter + (0.006 if i % 3 == 0 else -0.003)
		out.append(p)
	return out


static func cowl_weights(p: Vector3) -> Dictionary:
	var neck := smoothstep(0.12, 0.07, absf(p.x)) * smoothstep(1.52, 1.58, p.y)
	var side := smoothstep(0.11, 0.23, absf(p.x))
	var w := {"spine_03": 1.0}
	if neck > 0.0:
		w = {"spine_03": 1.0 - neck * 0.45, "neck_01": neck * 0.45}
	elif side > 0.0:
		w = {"spine_03": 1.0 - side * 0.8, Shape.sided("clavicle", p.x): side * 0.45, Shape.sided("upperarm", p.x): side * 0.35}
	elif p.y < 1.36:
		w = {"spine_03": 0.7, "spine_02": 0.3}
	return w
