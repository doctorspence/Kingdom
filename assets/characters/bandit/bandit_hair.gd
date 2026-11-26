extends RefCounted
## Unkempt shoulder-length hair (a cap, a ragged curtain round the sides and back, and loose
## chunky locks) and a short beard with a drooping moustache. All of it follows the head.

const Body := preload("res://assets/characters/bandit/bandit_body.gd")

const W := {"Head": 1.0}


static func build(m, o: Dictionary) -> void:
	m.group = "Hair"
	m.density = 1.2
	match o.hair:
		"long":
			_cap(m)
			_curtain(m)
			_locks(m)
		"crop":
			_crop(m)
		"nape":   # only what shows under a helmet
			_nape(m)
	if o.beard:
		_beard(m)


## Hair hacked short: a close cap down to the nape, with a few stubborn tufts.
static func _crop(m) -> void:
	var rings := []
	for r in [[1.752, 0.007], [1.790, 0.010], [1.822, 0.012]]:
		var ring: Array = Body.head_ring(r[0], r[1])
		if rings.is_empty():
			for i in ring.size():
				ring[i].y += 0.030 * clampf((ring[i].z - 0.02) / 0.08, 0.0, 1.0)
		rings.append(ring)
	var top := []
	for p in Body.head_ring(1.818, 0.0):
		top.append(Vector3(p.x * 0.6, 1.842, (p.z - Body.HEAD_Z) * 0.66 + Body.HEAD_Z - 0.004))
	rings.append(top)
	m.loft("hair", rings, W, {"cap_end": true})
	_nape(m)
	_lock(m, Vector3(0.030, 1.836, 0.050), Vector3(-0.026, 1.838, 0.048), Vector3(-0.010, 1.806, 0.116), Vector3(0, 0.012, 0.008))
	_lock(m, Vector3(0.050, 1.836, -0.010), Vector3(-0.020, 1.846, -0.030), Vector3(0.012, 1.852, -0.096), Vector3(0, 0.014, 0))


## Short hair round the sides and back of the head.
static func _nape(m) -> void:
	var nape := []
	for y: float in [1.652, 1.705, 1.756]:
		var ring: Array = Body.head_ring(y, 0.007)
		var arc := []
		for i: int in [3, 2, 1, 0, 11, 10, 9]:
			var p: Vector3 = ring[i]
			if y < 1.66 and (i == 3 or i == 9):
				p.y += 0.050
				p.z -= 0.020
			arc.append(p)
		nape.append(arc)
	m.loft("hair", nape, W, {"closed": false, "inside": Vector3(0, 1.70, 0.0)})


## The top of the head, down to the hairline.
static func _cap(m) -> void:
	var rings := []
	for r in [[1.752, 0.016], [1.790, 0.020], [1.822, 0.024]]:
		var ring: Array = Body.head_ring(r[0], r[1])
		if rings.is_empty():
			# the hairline lifts over the forehead
			for i in ring.size():
				ring[i].y += 0.027 * clampf((ring[i].z - 0.02) / 0.08, 0.0, 1.0)
		rings.append(ring)
	var top := []
	for p in Body.head_ring(1.818, 0.0):
		top.append(Vector3(p.x * 0.55, 1.862, (p.z - Body.HEAD_Z) * 0.62 + Body.HEAD_Z - 0.006))
	rings.append(top)
	m.loft("hair", rings, W, {"cap_end": true})


## Hair hanging over the ears and down the back of the neck, open at the face.
static func _curtain(m) -> void:
	# [height, half width, back z, front-edge z]
	var rows := [
		[1.760, 0.118, -0.134, 0.074], [1.705, 0.126, -0.150, 0.048], [1.650, 0.130, -0.156, 0.034], [1.600, 0.122, -0.146, 0.026],
	]
	var n := 11
	var rings := []
	for k in rows.size():
		var r: Array = rows[k]
		var ring := []
		for i in n:
			# from the front-left edge, round the back, to the front-right edge
			var t := float(i) / (n - 1)
			var a := lerpf(0.42 * PI, 1.58 * PI, t)
			var x: float = sin(a) * r[1]
			var back_part := clampf(-cos(a), 0.0, 1.0)
			var z: float = lerpf(r[3], r[2], pow(back_part, 0.6)) if cos(a) < 0.0 else r[3]
			var y: float = r[0]
			if k == rows.size() - 1:
				# ragged ends
				y += [0.026, -0.022, 0.014, -0.030, 0.006, -0.018, 0.012, -0.034, 0.020, -0.016, 0.030][i]
			ring.append(Vector3(x, y, z))
		rings.append(ring)
	var ws := [W, W, W, {"Head": 0.75, "neck_01": 0.25}]
	m.loft("hair", rings, ws, {"closed": false, "inside": Vector3(0, 1.68, -0.01)})


## A chunky pointed lock: a flat triangle of hair from a wide root to a tip.
static func _lock(m, a: Vector3, b: Vector3, tip: Vector3, bulge: Vector3, w: Dictionary = W) -> void:
	var mid := (a + b) * 0.5
	var ridge := mid.lerp(tip, 0.42) + bulge
	var inside := mid.lerp(tip, 0.42) - bulge * 1.5
	for tri in [[a, ridge, tip], [ridge, b, tip], [a, b, ridge]]:
		m.poly("hair", tri, w, inside)
	m.poly("hair", [a, tip, b], w, inside + bulge * 3.0)


static func _locks(m) -> void:
	# fringe, parted left of centre and swept to both sides
	_lock(m, Vector3(0.036, 1.815, 0.092), Vector3(-0.030, 1.808, 0.096), Vector3(-0.094, 1.728, 0.100), Vector3(0, 0.004, 0.020))
	_lock(m, Vector3(0.000, 1.832, 0.070), Vector3(-0.066, 1.800, 0.080), Vector3(-0.114, 1.700, 0.062), Vector3(-0.012, 0.004, 0.018))
	_lock(m, Vector3(0.030, 1.816, 0.092), Vector3(0.080, 1.800, 0.068), Vector3(0.108, 1.712, 0.080), Vector3(0.008, 0.004, 0.018))
	for s in [1.0, -1.0]:
		# locks framing the face
		_lock(m, Vector3(0.096 * s, 1.790, 0.058), Vector3(0.122 * s, 1.756, -0.004), Vector3(0.116 * s, 1.612 - 0.010 * s, 0.052), Vector3(0.018 * s, 0, 0.008))
		_lock(m, Vector3(0.122 * s, 1.752, -0.020), Vector3(0.118 * s, 1.740, -0.092), Vector3(0.140 * s, 1.585 + 0.012 * s, -0.062), Vector3(0.018 * s, 0, 0))
		# back
		_lock(m, Vector3(0.110 * s, 1.720, -0.112), Vector3(0.042 * s, 1.722, -0.152), Vector3(0.094 * s, 1.562, -0.140),
				Vector3(0.010 * s, 0, -0.018), {"Head": 0.7, "neck_01": 0.3})
		# tufts breaking the outline on top
		_lock(m, Vector3(0.020 * s, 1.860, 0.020), Vector3(0.060 * s, 1.842, -0.052), Vector3(0.112 * s, 1.826 + 0.008 * s, -0.050), Vector3(0, 0.016, 0))
		_lock(m, Vector3(0.088 * s, 1.806, -0.060), Vector3(0.070 * s, 1.760, -0.128), Vector3(0.134 * s, 1.706 - 0.014 * s, -0.116), Vector3(0.016 * s, 0.004, -0.008))
	_lock(m, Vector3(0.052, 1.745, -0.146), Vector3(-0.050, 1.750, -0.146), Vector3(-0.012, 1.556, -0.148), Vector3(0, 0, -0.022), {"Head": 0.65, "neck_01": 0.35})
	_lock(m, Vector3(0.030, 1.858, -0.040), Vector3(-0.044, 1.846, -0.060), Vector3(-0.030, 1.838, -0.132), Vector3(0, 0.018, -0.004))


static func _beard(m) -> void:
	# [angle round the jaw (degrees), top height, middle height, bottom height]
	var cols := [
		[-84.0, 1.690, 1.650, 1.606], [-62.0, 1.652, 1.614, 1.574], [-38.0, 1.636, 1.590, 1.546],
		[-16.0, 1.642, 1.586, 1.534], [0.0, 1.640, 1.582, 1.512],
		[16.0, 1.642, 1.586, 1.534], [38.0, 1.636, 1.590, 1.546], [62.0, 1.652, 1.614, 1.574], [84.0, 1.690, 1.650, 1.606],
	]
	var top := []
	var upper := []
	var lower := []
	var bottom := []
	for c in cols:
		var a := deg_to_rad(c[0])
		top.append(_jaw(a, c[1], 0.003))
		upper.append(_jaw(a, lerpf(c[1], c[2], 0.5), 0.014))
		lower.append(_jaw(a, c[2], 0.016))
		var b := _jaw(a, maxf(c[3], 1.575), 0.004)
		b.y = c[3]
		bottom.append(b)
	# tuck the underside back toward the throat
	var throat := []
	for p in bottom:
		throat.append(Vector3(p.x * 0.7, p.y + 0.030, lerpf(p.z, 0.0, 0.45)))
	m.loft("beard", [top, upper, lower, bottom, throat], W, {"closed": false, "inside": Vector3(0, 1.62, -0.02)})
	# mouth, showing through the beard
	var z := Body.face_z(0.0, 1.624) + 0.019
	m.poly("lip", [Vector3(-0.030, 1.620, z - 0.007), Vector3(-0.012, 1.628, z), Vector3(0.012, 1.628, z),
			Vector3(0.030, 1.620, z - 0.007), Vector3(0.0, 1.616, z - 0.001)], W, Vector3(0, 1.62, 0.0))
	# drooping moustache
	for s in [1.0, -1.0]:
		var root := Vector3(0.002 * s, 1.646, z + 0.004)
		var under := Vector3(0.006 * s, 1.630, z + 0.006)
		var end := Vector3(0.052 * s, 1.602, z - 0.014)
		_lock_beard(m, root, under, end, Vector3(0.006 * s, 0.006, 0.014))


static func _lock_beard(m, a: Vector3, b: Vector3, tip: Vector3, bulge: Vector3) -> void:
	var ridge := (a + b) * 0.5 + (tip - (a + b) * 0.5) * 0.4 + bulge
	var inside := (a + b + tip) / 3.0 - bulge
	for tri in [[a, ridge, tip], [ridge, b, tip], [a, b, ridge]]:
		m.poly("beard", tri, W, inside)


## A point on the face at an angle round the jaw (0 = chin), `margin` out from the skin.
static func _jaw(a: float, y: float, margin: float) -> Vector3:
	var ring: Array = Body.head_ring(clampf(y, 1.566, 1.75), margin)
	var half: Vector3 = ring[3]
	var front: Vector3 = ring[6]
	var cz := Body.HEAD_Z
	var rx := absf(half.x)
	var rz := front.z - cz
	var s := sin(a)
	var c := cos(a)
	return Vector3(signf(s) * pow(absf(s), 0.8) * rx, y, cz + signf(c) * pow(absf(c), 0.8) * rz)
