extends RefCounted
## Scavenged leather and fittings: the leather vest and its laces, chest straps, shoulder guards,
## forearm wraps and bracers, the belt with its dull buckle and hanging tail, a belt pouch and a
## quiver. Which of these a bandit wears comes from bandit_outfits.gd.

const Shape := preload("res://assets/characters/bandit/bandit_shape.gd")
const Mesh_ := preload("res://assets/characters/bandit/bandit_mesh.gd")
const Clothes := preload("res://assets/characters/bandit/bandit_clothes.gd")
const Body := preload("res://assets/characters/bandit/bandit_body.gd")

## How far the vest sits out from the tunic.
const VEST := 0.013
## Half the width of the vest's front opening.
const GAP := 0.020


static func build(m, o: Dictionary) -> void:
	m.group = "Armor"
	m.density = 1.0
	# what the straps and belt lie on
	var skin: float = o.get("belt_margin", VEST if o.vest else 0.002)
	if o.vest:
		_vest(m, o.laces)
	if o.laces:
		_laces(m)
	match o.straps:
		"single":
			_diagonal(m, 1.0, skin)
		"cross":
			_diagonal(m, 1.0, skin)
			_diagonal(m, -1.0, skin + 0.004)
			_clasp(m, skin)
		"braces":
			_braces(m, skin)
	_belt(m, skin)
	if o.get("pouch", true):
		_pouch(m)
	for s: float in o.pauldrons:
		_shoulder(m, s, o.get("pauldron_style", "pauldron"))
	for s: float in o.forearms:
		_forearm(m, s, o.forearms[s] == "bracer")
	if o.quiver:
		_quiver(m)
	if o.get("helm", false):
		_helm(m)


## A dented iron cap with a riveted rim, a ridge over the crown and a bar down the nose.
static func _helm(m) -> void:
	var w := {"Head": 1.0}
	var rings := []
	for r in [[1.730, 0.012], [1.766, 0.017], [1.806, 0.019]]:
		var ring: Array = Body.head_ring(r[0], r[1])
		if rings.is_empty():
			# lifted over the brows
			for i in ring.size():
				ring[i].y += 0.018 * clampf((ring[i].z - 0.02) / 0.08, 0.0, 1.0)
		rings.append(ring)
	for r in [[1.842, 0.80], [1.868, 0.46]]:
		var ring := []
		for p: Vector3 in Body.head_ring(1.806, 0.019):
			ring.append(Vector3(p.x * r[1], r[0], (p.z - Body.HEAD_Z) * r[1] + Body.HEAD_Z - 0.006))
		rings.append(ring)
	m.loft("plate", rings, w, {"cap_end": true})
	var rim: Array = rings[0]
	for i in rim.size():
		var p: Vector3 = rim[i]
		var q: Vector3 = rim[(i + 1) % rim.size()]
		m.bar("iron", p, q, 0.022, 0.012, Vector3(p.x + q.x, 0.0, p.z + q.z), w)
		m.box("metal", p + Vector3(p.x, 0.0, p.z - Body.HEAD_Z).normalized() * 0.008, Vector3(0.011, 0.011, 0.011), w)
	# the ridge, front to back
	var ridge := [(rings[0] as Array)[6], (rings[1] as Array)[6], (rings[2] as Array)[6], (rings[3] as Array)[6],
			(rings[4] as Array)[6], (rings[4] as Array)[0], (rings[3] as Array)[0], (rings[2] as Array)[0], (rings[0] as Array)[0]]
	for i in ridge.size() - 1:
		m.bar("iron", ridge[i] + Vector3(0, 0.004, 0), ridge[i + 1] + Vector3(0, 0.004, 0), 0.020, 0.012, Vector3.RIGHT, w)
	# the nasal
	var top: Vector3 = (rim[6] as Vector3) + Vector3(0, 0.004, 0.006)
	var low := Vector3(0.0, 1.652, Body.face_z(0.0, 1.652) + 0.042)
	m.bar("iron", top, low, 0.022, 0.010, Vector3.BACK, w)


static func _vest(m, open_front: bool) -> void:
	# [height, extra half width (negative = cut in at the armholes)]
	var rows := [[1.060, 0.0], [1.15, 0.0], [1.24, 0.0], [1.33, -0.004], [1.41, -0.020], [1.47, -0.038], [1.515, -0.030]]
	var n := 15
	var half_gap := GAP if open_front else 0.0015
	var rings := []
	for r in rows:
		var y: float = r[0]
		var hw: float = Shape.lerp_rows(Shape.TORSO, y)[0] + VEST
		var gap := asin(pow(half_gap / hw, Shape.SQUARE / 2.0))
		var ring := []
		for i in n:
			var a := lerpf(gap, TAU - gap, float(i) / (n - 1))
			var p := Shape.torso_point(y, a, VEST)
			p.x *= (hw + r[1]) / hw
			ring.append(p)
		rings.append(ring)
	m.loft("vest", rings, Shape.torso_weights, {"closed": false, "inside": Vector3(0, 1.28, -0.01)})
	# leather edging down both sides of the opening
	if open_front:
		for s in [1.0, -1.0]:
			for i in rows.size() - 2:
				var a := Shape.torso_face((GAP + 0.004) * s, rows[i][0], 1.0, VEST + 0.002)
				var b := Shape.torso_face((GAP + 0.004) * s, rows[i + 1][0], 1.0, VEST + 0.002)
				m.bar("trim", a, b, 0.014, 0.008, Vector3.BACK, Shape.torso_weights)


static func _laces(m) -> void:
	for i in 4:
		var y := 1.105 + i * 0.058
		for s in [1.0, -1.0]:
			var a := Shape.torso_face((GAP + 0.006) * s, y, 1.0, VEST + 0.006)
			var b := Shape.torso_face(-(GAP + 0.006) * s, y + 0.036, 1.0, VEST + 0.006)
			m.bar("lace", a, b, 0.006, 0.005, Vector3.BACK, Shape.torso_weights)


## A strap lying on the torso through the points [x, y], front (side 1) or back (-1).
static func _band(m, path: Array, side: float, margin: float, width: float, style := "strap") -> void:
	var rings := []
	for i in path.size():
		var p: Vector2 = path[i]
		var dir: Vector2 = (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
		var across := Vector2(-dir.y, dir.x) * width * 0.5
		rings.append([Shape.torso_face(p.x + across.x, p.y + across.y, side, margin),
				Shape.torso_face(p.x - across.x, p.y - across.y, side, margin)])
	m.loft(style, rings, Shape.torso_weights, {"closed": false, "inside": Vector3(0, 1.28, -0.01)})


## A leather strap from one shoulder (s = +1 left) to the opposite hip, front and back.
static func _diagonal(m, s: float, skin: float) -> void:
	for side in [1.0, -1.0]:
		var path := []
		for i in 9:
			var t := i / 8.0
			path.append(Vector2(lerpf(0.138, -0.128, t) * s, lerpf(1.455, 1.085, t)))
		_band(m, path, side, skin + 0.009, 0.036)


## The square clasp where the crossed straps meet.
static func _clasp(m, skin: float) -> void:
	var c := Shape.torso_face(0.0, 1.272, 1.0, skin + 0.020)
	var w: Dictionary = Shape.torso_weights(c)
	var k := 0.044
	var pts := [c + Vector3(0, k, 0), c + Vector3(k, 0, 0), c + Vector3(0, -k, 0), c + Vector3(-k, 0, 0)]
	for i in 4:
		m.bar("metal", pts[i], pts[(i + 1) % 4], 0.015, 0.012, Vector3.BACK, w)
	m.poly("belt", [pts[0].lerp(c, 0.2), pts[1].lerp(c, 0.2), pts[2].lerp(c, 0.2), pts[3].lerp(c, 0.2)], w, c - Vector3(0, 0, 0.05))


## Two shoulder straps down to the belt, with a buckle on the left one.
static func _braces(m, skin: float) -> void:
	for s in [1.0, -1.0]:
		for side in [1.0, -1.0]:
			var path := []
			for i in 8:
				var t := i / 7.0
				path.append(Vector2(lerpf(0.112, 0.078, t) * s, lerpf(1.475, 1.082, t)))
			_band(m, path, side, skin + 0.008, 0.032)
	var c := Shape.torso_face(0.098, 1.300, 1.0, skin + 0.018)
	var w: Dictionary = Shape.torso_weights(c)
	for q in [[Vector3(0, 0.024, 0), Vector3(0.052, 0.010, 0.010)], [Vector3(0, -0.024, 0), Vector3(0.052, 0.010, 0.010)],
			[Vector3(0.022, 0, 0), Vector3(0.010, 0.040, 0.010)], [Vector3(-0.022, 0, 0), Vector3(0.010, 0.040, 0.010)]]:
		m.box("metal", c + q[0], q[1], w)


static func _belt(m, skin: float) -> void:
	var rings := []
	for r in [[1.018, skin + 0.004], [1.026, skin + 0.018], [1.082, skin + 0.017], [1.090, skin + 0.003]]:
		rings.append(Shape.torso_ring(r[0], maxf(r[1], 0.012), 16))
	m.loft("belt", rings, Shape.torso_weights, {"inside": Vector3(0, 1.054, -0.01)})
	# square buckle of dull metal
	var c := Shape.torso_face(0.0, 1.054, 1.0, maxf(skin, 0.008) + 0.024)
	var w: Dictionary = Shape.torso_weights(c)
	for q in [[Vector3(0, 0.027, 0), Vector3(0.070, 0.013, 0.013)], [Vector3(0, -0.027, 0), Vector3(0.070, 0.013, 0.013)],
			[Vector3(0.029, 0, 0), Vector3(0.013, 0.042, 0.013)], [Vector3(-0.029, 0, 0), Vector3(0.013, 0.042, 0.013)]]:
		m.box("metal", c + q[0], q[1], w)
	m.box("metal", c + Vector3(-0.010, 0, 0.004), Vector3(0.040, 0.007, 0.006), w)
	# the loose end of the belt hanging past the buckle
	var top := Shape.torso_face(-0.052, 1.044, 1.0, maxf(skin, 0.008) + 0.022)
	var mid := Vector3(-0.058, 0.972, 0.158)
	var end := Vector3(-0.050, 0.902, 0.160)
	m.bar("belt", top, mid, 0.034, 0.009, Vector3.BACK, Clothes.skirt_weights)
	m.bar("belt", mid, end, 0.030, 0.008, Vector3.BACK, Clothes.skirt_weights)


## A reddish leather pouch on the right hip.
static func _pouch(m) -> void:
	var basis := Basis(Vector3.UP, deg_to_rad(-42.0))
	var c := Vector3(-0.150, 0.968, 0.130)
	var w := {"pelvis": 0.78, "thigh_r": 0.22}
	var body := []
	for r in [[-0.062, 0.040, 0.020], [-0.050, 0.052, 0.030], [0.028, 0.050, 0.028], [0.050, 0.040, 0.016]]:
		var ring := []
		for q in Mesh_.ring(Vector3.ZERO, Vector3.RIGHT, Vector3.BACK, r[1], r[2], 8, 4.0, PI / 8.0):
			ring.append(c + basis * (q + Vector3(0, r[0], 0)))
		body.append(ring)
	m.loft("pouch", body, w, {"cap_start": true, "cap_end": true})
	var flap := []
	for q in [Vector3(-0.057, 0.058, 0.010), Vector3(0.057, 0.058, 0.010), Vector3(0.056, 0.010, 0.037), Vector3(0.0, -0.012, 0.040), Vector3(-0.056, 0.010, 0.037)]:
		flap.append(c + basis * q)
	m.poly("pouch_flap", flap, w, c)
	m.box("metal", c + basis * Vector3(0, -0.002, 0.043), Vector3(0.014, 0.016, 0.006), w, basis)
	# two loops over the belt
	for x in [-0.032, 0.032]:
		m.bar("belt", c + basis * Vector3(x, 0.044, 0.008), c + basis * Vector3(x, 0.112, -0.004), 0.016, 0.010, basis * Vector3.BACK, w)


## Two overlapping leather plates over a shoulder (s = +1 left), laced on and riveted.
static func _shoulder(m, s: float, style := "pauldron", grow := 0.0) -> void:
	var upper: String = Shape.sided("upperarm", s)
	var clavicle: String = Shape.sided("clavicle", s)
	var plates := [
		# [[|x|, radius, centre y]], arc half angle
		[[[0.166, 0.092, 1.452], [0.205, 0.118, 1.446], [0.252, 0.112, 1.442], [0.292, 0.096, 1.440]], 1.85],
		[[[0.262, 0.088, 1.441], [0.300, 0.096, 1.440], [0.348, 0.086, 1.440]], 1.65],
	]
	for plate in plates:
		var rings := []
		var ws := []
		for r in plate[0]:
			var ring := []
			for i in 8:
				var a: float = lerpf(-plate[1], plate[1], i / 7.0)
				ring.append(Vector3(r[0] * s, r[2] + cos(a) * (r[1] + grow), -0.062 + sin(a) * (r[1] + grow) * 1.02))
			rings.append(ring)
			if r[0] < 0.19:
				ws.append({clavicle: 0.5, upper: 0.5})
			elif r[0] < 0.23:
				ws.append({clavicle: 0.2, upper: 0.8})
			else:
				ws.append({upper: 1.0})
		m.loft(style, rings, ws,{"closed": false, "inside": Vector3((plate[0][0][0] + plate[0][-1][0]) * 0.5 * s, 1.43, -0.062)})
		# a thick rolled edge along the lower end
		var last: Array = rings[rings.size() - 1]
		for i in last.size() - 1:
			m.bar("trim", last[i], last[i + 1], 0.016, 0.012, last[i] - Vector3(last[i].x, 1.44, -0.062), ws[ws.size() - 1])
	for a in [-0.75, 0.05, 0.85]:
		var p := Vector3(0.262 * s, 1.442 + cos(a) * (0.114 + grow), -0.062 + sin(a) * (0.116 + grow))
		m.box("iron", p, Vector3(0.012, 0.010, 0.012), {upper: 1.0}, Basis(Vector3.RIGHT, a))


## Forearm: dirty cloth wraps; `bracer` adds a leather guard strapped over them.
static func _forearm(m, s: float, bracer: bool) -> void:
	var rows := [[0.536, 0.070, 0.072], [0.570, 0.074, 0.076], [0.640, 0.060, 0.067], [0.700, 0.045, 0.054], [0.728, 0.040, 0.050]]
	var rings := []
	for r in rows:
		rings.append(Shape.arm_ring(s, r[0], 1.441, -0.068, r[1], r[2], 8))
	m.loft("wrap", rings, Shape.arm_weights)
	if bracer:
		var br := []
		for r in [[0.556, 0.084, 0.086], [0.600, 0.079, 0.083], [0.662, 0.063, 0.071], [0.696, 0.056, 0.064]]:
			br.append(Shape.arm_ring(s, r[0], 1.441, -0.068, r[1], r[2], 8))
		m.loft("bracer", br, Shape.arm_weights)
		for q in [[0.578, 0.086], [0.668, 0.067]]:
			var band := []
			for dx in [-0.009, 0.009]:
				band.append(Shape.arm_ring(s, q[0] + dx, 1.441, -0.068, q[1] - dx * 0.2, q[1] + 0.004 - dx * 0.2, 8))
			m.loft("strap", band, Shape.arm_weights)
	else:
		# two raised turns of cloth and a leather tie
		for q in [[0.558, 0.078], [0.690, 0.052]]:
			var turn := []
			for i in 3:
				var dx: float = (i - 1) * 0.014
				var bulge := 0.005 if i == 1 else 0.0
				turn.append(Shape.arm_ring(s, q[0] + dx, 1.441, -0.068, q[1] + bulge - dx * 0.3, q[1] + 0.003 + bulge - dx * 0.3, 8))
			m.loft("wrap_turn", turn, Shape.arm_weights)
		var tie := []
		for dx in [-0.007, 0.007]:
			tie.append(Shape.arm_ring(s, 0.622 + dx, 1.441, -0.068, 0.071 - dx * 0.2, 0.077 - dx * 0.2, 8))
		m.loft("strap", tie, Shape.arm_weights)


## A leather quiver slung across the back, its arrows showing over the right shoulder.
static func _quiver(m) -> void:
	var w := {"spine_02": 0.4, "spine_03": 0.6}
	var low := Vector3(0.055, 1.095, -0.222)
	var high := Vector3(-0.145, 1.500, -0.248)
	var up := (high - low).normalized()
	var side := up.cross(Vector3.BACK).normalized()
	var out := side.cross(up).normalized()
	var rings := []
	for r in [[0.0, 0.040], [0.04, 0.048], [0.96, 0.060], [1.0, 0.064]]:
		rings.append(Mesh_.ring(low.lerp(high, r[0]), side, out, r[1], r[1] * 0.82, 7))
	m.loft("quiver", rings, w, {"cap_start": true})
	for t in [0.18, 0.82]:
		var band := []
		for dt in [-0.035, 0.035]:
			var rad: float = lerpf(0.048, 0.060, t) + 0.006
			band.append(Mesh_.ring(low.lerp(high, t + dt), side, out, rad, rad * 0.82, 7))
		m.loft("strap", band, w)
		m.box("metal", low.lerp(high, t) - Vector3(0, 0, lerpf(0.048, 0.060, t) * 0.82 + 0.008), Vector3(0.018, 0.022, 0.006), w)
	# arrows
	for a in [[-0.028, 0.006, 0.150], [0.004, -0.018, 0.175], [0.030, 0.012, 0.135], [-0.004, 0.022, 0.165]]:
		var root: Vector3 = high + side * a[0] + out * a[1] - up * 0.02
		var end: Vector3 = root + (up + side * a[0] * 1.4 + out * a[1]).normalized() * a[2]
		m.bar("arrow_shaft", root, end, 0.008, 0.008, out, w)
		var dir := (end - root).normalized()
		for fin in [side, out]:
			var f: Vector3 = (fin - dir * dir.dot(fin)).normalized()
			for sgn in [1.0, -1.0]:
				m.poly("fletch", [end, end - dir * 0.018 + f * 0.026 * sgn, end - dir * 0.080 + f * 0.022 * sgn, end - dir * 0.064], w,
						end - dir * 0.04 - f.cross(dir) * 0.05)
