extends RefCounted
## Harl the Delver, the Gullet's boss (GULLET_DESIGN.md section 6): what he wears over the shared
## bandit body. A heavy miner's coat with the left sleeve torn away, a mail shirt, a battered
## brimmed helmet with a candle stub, one big shoulder plate, and shards of the black stone set
## into his gear and his marked left arm. Also his sharpened pick.
## The marks under his skin and the stone's glow are painted (bandit_paint.gd).

const Shape := preload("res://assets/characters/bandit/bandit_shape.gd")
const Mesh_ := preload("res://assets/characters/bandit/bandit_mesh.gd")
const Body := preload("res://assets/characters/bandit/bandit_body.gd")
const Clothes := preload("res://assets/characters/bandit/bandit_clothes.gd")
const Armor := preload("res://assets/characters/bandit/bandit_armor.gd")
const Gear := preload("res://assets/characters/bandit/bandit_gear.gd")

## How far the coat sits out from the mail shirt.
const COAT := 0.030


static func build(m) -> void:
	m.density = 1.0
	m.group = "Body"
	_shoulder_skin(m)
	m.group = "Clothing"
	_coat(m)
	_collar(m)
	_sleeve(m)
	_torn_sleeve(m)
	m.group = "Armor"
	Armor._shoulder(m, -1.0, "plate", 0.020)
	_wrist_strap(m)
	_helmet(m)
	_stones(m)


## The bare left shoulder, where the sleeve was torn off.
static func _shoulder_skin(m) -> void:
	var rings := []
	for r in [[0.165, 0.060, 0.064], [0.215, 0.072, 0.074], [0.265, 0.066, 0.068], [0.315, 0.058, 0.060]]:
		rings.append(Shape.arm_ring(1.0, r[0], 1.441, -0.066, r[1], r[2], 10))
	m.loft("skin", rings, Shape.arm_weights)


static func _coat_weights(p: Vector3) -> Dictionary:
	return Shape.torso_weights(p) if p.y >= 1.03 else Clothes.skirt_weights(p)


## A long coat, open down the front, its hem torn.
static func _coat(m) -> void:
	var n := 23
	var rings := []
	var edges := []   # [left front edge, right front edge] of every row
	# below the belt: [height, half width, front z, back z, half the front opening (radians)]
	var skirt := [
		[0.520, 0.285, 0.196, -0.250, 0.36], [0.640, 0.268, 0.188, -0.235, 0.30], [0.780, 0.243, 0.172, -0.212, 0.23],
		[0.910, 0.216, 0.156, -0.180, 0.17],
	]
	var jag := [0.020, -0.055, 0.015, -0.030, -0.070, 0.025, -0.020, -0.050, 0.030, -0.015, -0.080, 0.010,
			-0.045, 0.028, -0.025, -0.065, 0.018, -0.035, 0.024, -0.060, -0.010, 0.030, -0.040]
	for k in skirt.size():
		var r: Array = skirt[k]
		var cz: float = (r[2] + r[3]) * 0.5
		var hd: float = (r[2] - r[3]) * 0.5
		var ring := []
		for i in n:
			var a := lerpf(r[4], TAU - r[4], float(i) / (n - 1))
			var p := Vector3(signf(sin(a)) * pow(absf(sin(a)), 0.78) * r[1], r[0], cz + signf(cos(a)) * pow(absf(cos(a)), 0.78) * hd)
			if k == 0:
				p.y += jag[i]
			else:
				p.z += (0.010 if i % 2 == 0 else -0.005) * (1.0 - k / 4.0)   # heavy folds
			ring.append(p)
		rings.append(ring)
		edges.append([ring[0], ring[n - 1]])
	# the body of the coat: [height, half width of the front opening]
	for r in [[1.040, 0.040], [1.120, 0.040], [1.210, 0.046], [1.300, 0.060], [1.380, 0.072], [1.445, 0.080], [1.495, 0.066], [1.535, 0.048]]:
		var hw: float = Shape.lerp_rows(Shape.TORSO, r[0])[0] + COAT
		var gap := asin(pow(clampf(r[1] / hw, 0.0, 0.98), Shape.SQUARE / 2.0))
		var ring := []
		for i in n:
			var a := lerpf(gap, TAU - gap, float(i) / (n - 1))
			ring.append(Shape.torso_point(r[0], a, COAT))
		rings.append(ring)
		edges.append([ring[0], ring[n - 1]])
	m.loft("coat", rings, _coat_weights, {"closed": false, "inside": Vector3(0, 1.0, -0.01)})
	# the doubled edge down both fronts
	for side in 2:
		for i in edges.size() - 1:
			var a: Vector3 = edges[i][side]
			var b: Vector3 = edges[i + 1][side]
			m.bar("coat_trim", a + Vector3(0, 0, 0.004), b + Vector3(0, 0, 0.004), 0.026, 0.012, Vector3.BACK, _coat_weights)
	# broad turned-back lapels
	for s in [1.0, -1.0]:
		var pts := [
			Shape.torso_face(0.064 * s, 1.270, 1.0, COAT + 0.012), Shape.torso_face(0.150 * s, 1.405, 1.0, COAT + 0.016),
			Shape.torso_face(0.122 * s, 1.425, 1.0, COAT + 0.016), Shape.torso_face(0.140 * s, 1.480, 1.0, COAT + 0.014),
			Shape.torso_face(0.068 * s, 1.505, 1.0, COAT + 0.014), Shape.torso_face(0.078 * s, 1.420, 1.0, COAT + 0.016),
		]
		m.poly("coat_trim", pts, Shape.torso_weights, Vector3(0, 1.38, -0.05))
	# a sagging coil of rope slung from the belt on the left hip
	var c := Vector3(0.232, 0.915, 0.050)
	var w := {"pelvis": 0.65, "thigh_l": 0.35}
	for turn in 3:
		var radius := 0.070 - turn * 0.006
		var pts := []
		for i in 10:
			var a := TAU * i / 10.0
			pts.append(c + Vector3(0.008 * turn + sin(a) * 0.012, cos(a) * radius, sin(a) * radius * 0.85))
		for i in 10:
			var p: Vector3 = pts[i]
			var q: Vector3 = pts[(i + 1) % 10]
			m.bar("rope", p, q + (q - p) * 0.12, 0.015, 0.015, Vector3.RIGHT, w)
	m.bar("strap", c + Vector3(0.016, 0.052, 0), Vector3(0.200, 1.050, 0.036), 0.022, 0.012, Vector3.RIGHT, w)


## A high standing collar, open at the throat.
static func _collar(m) -> void:
	var w := {"spine_03": 0.75, "neck_01": 0.25}
	var rings := []
	for r in [[1.515, 0.165, 0.098, -0.168, 0.50], [1.560, 0.128, 0.070, -0.142, 0.62], [1.612, 0.132, 0.040, -0.150, 0.95]]:
		var cz: float = (r[2] + r[3]) * 0.5
		var hd: float = (r[2] - r[3]) * 0.5
		var ring := []
		for i in 15:
			var a := lerpf(r[4], TAU - r[4], i / 14.0)
			ring.append(Vector3(sin(a) * r[1], r[0] + maxf(-cos(a), 0.0) * 0.012, cz + cos(a) * hd))
		rings.append(ring)
	m.loft("coat_trim", rings, w, {"closed": false, "inside": Vector3(0, 1.54, -0.02)})


## The right sleeve, with a deep turned cuff.
static func _sleeve(m) -> void:
	# [|x|, y, z, radius up/down, radius front/back]
	var rows := [
		[0.125, 1.420, -0.040, 0.092, 0.100], [0.190, 1.436, -0.058, 0.108, 0.108], [0.260, 1.440, -0.065, 0.097, 0.099],
		[0.360, 1.440, -0.068, 0.084, 0.087], [0.440, 1.441, -0.070, 0.070, 0.073], [0.475, 1.441, -0.070, 0.066, 0.068],
		[0.540, 1.441, -0.069, 0.078, 0.080], [0.610, 1.441, -0.068, 0.068, 0.074],
	]
	var rings := []
	for r in rows:
		rings.append(Shape.arm_ring(-1.0, r[0], r[1], r[2], r[3], r[4], 12))
	m.loft("coat", rings, Shape.arm_weights)
	var cuff := []
	for r in [[0.585, 0.072, 0.077], [0.592, 0.090, 0.094], [0.668, 0.082, 0.088], [0.662, 0.058, 0.064]]:
		cuff.append(Shape.arm_ring(-1.0, r[0], 1.441, -0.068, r[1], r[2], 12))
	m.loft("coat_trim", cuff, Shape.arm_weights, {"inside": Vector3(-0.625, 1.441, -0.068)})
	for i in 3:
		var a := -0.5 + i * 0.6
		m.box("metal", Vector3(-0.628, 1.441 + cos(a) * 0.090, -0.068 + sin(a) * 0.094), Vector3(0.016, 0.012, 0.016),
				{"lowerarm_r": 1.0}, Basis(Vector3.RIGHT, a))


## What is left of the left sleeve: a ragged stump at the shoulder.
static func _torn_sleeve(m) -> void:
	var rows := [[0.125, 1.420, -0.040, 0.092, 0.100], [0.185, 1.436, -0.056, 0.104, 0.104], [0.232, 1.440, -0.062, 0.093, 0.095]]
	var jag := [0.034, -0.018, 0.022, -0.028, 0.044, -0.008, 0.014, -0.022, 0.030, -0.014, 0.008, -0.030]
	var rings := []
	for k in rows.size():
		var r: Array = rows[k]
		var ring := Shape.arm_ring(1.0, r[0], r[1], r[2], r[3], r[4], 12)
		if k == rows.size() - 1:
			for i in ring.size():
				ring[i].x += jag[i]
		rings.append(ring)
	m.loft("coat", rings, Shape.arm_weights)


static func _wrist_strap(m) -> void:
	var rings := []
	for r in [[0.668, 0.049, 0.060], [0.674, 0.056, 0.066], [0.714, 0.048, 0.060], [0.720, 0.039, 0.050]]:
		rings.append(Shape.arm_ring(1.0, r[0], 1.4415, -0.067, r[1], r[2], 10))
	m.loft("strap", rings, Shape.arm_weights)
	m.box("iron", Vector3(0.694, 1.4415, 0.0), Vector3(0.022, 0.026, 0.010), {"lowerarm_l": 0.8, "hand_l": 0.2})


## A dented, wide-brimmed miner's helmet with a candle stub on the front.
static func _helmet(m) -> void:
	var w := {"Head": 1.0}
	var rings := []
	for r in [[1.744, 0.018], [1.780, 0.024], [1.820, 0.026]]:
		rings.append(Body.head_ring(r[0], r[1]))
	for r in [[1.856, 0.82], [1.880, 0.48]]:
		var ring := []
		for p: Vector3 in Body.head_ring(1.820, 0.026):
			ring.append(Vector3(p.x * r[1], r[0], (p.z - Body.HEAD_Z) * r[1] + Body.HEAD_Z - 0.006))
		rings.append(ring)
	# the dent: one side of the crown stove in
	for k in [2, 3]:
		var ring: Array = rings[k]
		ring[3] = (ring[3] as Vector3).lerp(Vector3(0.0, 1.79, Body.HEAD_Z), 0.30)
	m.loft("plate", rings, w, {"cap_end": true})
	# the brim, drooping, lifted over the eyes, bent at one side
	var inner: Array = rings[0]
	var outer := []
	var chip := [0.0, 0.004, -0.010, 0.0, 0.006, 0.0, 0.002, 0.0, 0.005, -0.004, 0.008, 0.0]
	for i in inner.size():
		var p: Vector3 = inner[i]
		var out := Vector3(p.x, 0.0, p.z - Body.HEAD_Z).normalized()
		var q: Vector3 = p + out * (0.066 + chip[i])
		q.y = 1.722 + 0.036 * clampf(out.z, 0.0, 1.0) + chip[i] * 1.4
		outer.append(q)
	m.loft("plate", [inner, outer], w, {"inside": Vector3(0, 1.60, Body.HEAD_Z)})
	for i in outer.size():
		var p: Vector3 = outer[i]
		var q: Vector3 = outer[(i + 1) % outer.size()]
		m.bar("iron", p, q, 0.012, 0.011, Vector3((p.x + q.x), 0.0, (p.z + q.z)), w)
		var base: Vector3 = inner[i]
		m.box("metal", base + Vector3(base.x, 0.0, base.z - Body.HEAD_Z).normalized() * 0.006 + Vector3(0, 0.014, 0),
				Vector3(0.012, 0.012, 0.012), w)
	# a band round the crown
	for i in rings[1].size():
		var p: Vector3 = rings[1][i]
		var q: Vector3 = rings[1][(i + 1) % rings[1].size()]
		m.bar("strap", p * Vector3(1.012, 1.0, 1.012), q * Vector3(1.012, 1.0, 1.012), 0.020, 0.008, Vector3(p.x + q.x, 0.0, p.z + q.z), w)
	# the candle in its iron holder
	var front: float = (rings[1][6] as Vector3).z
	var foot := Vector3(-0.034, 1.790, front + 0.022)
	m.box("iron", foot + Vector3(0, -0.004, -0.014), Vector3(0.044, 0.012, 0.050), w)
	m.loft("wax", [Mesh_.ring(foot, Vector3.RIGHT, Vector3.BACK, 0.014, 0.014, 7),
			Mesh_.ring(foot + Vector3(0, 0.046, 0), Vector3.RIGHT, Vector3.BACK, 0.012, 0.012, 7)], w, {"cap_end": true})
	var wick := foot + Vector3(0, 0.050, 0)
	var flame := Mesh_.ring(wick + Vector3(0, 0.012, 0), Vector3.RIGHT, Vector3.BACK, 0.008, 0.008, 5)
	for i in 5:
		for end: Vector3 in [wick, wick + Vector3(0, 0.040, 0)]:
			m.poly("flame", [flame[i], flame[(i + 1) % 5], end], w, wick + Vector3(0, 0.014, 0))
	# the chin strap
	for s in [1.0, -1.0]:
		var top := Vector3(0.108 * s, 1.742, -0.010)
		var jaw := Vector3(0.100 * s, 1.640, 0.030)
		m.bar("strap", top, jaw, 0.016, 0.008, Vector3(s, 0, 0), w)
		m.bar("strap", jaw, Vector3(0.050 * s, 1.574, 0.082), 0.015, 0.008, Vector3(s, 0, 0.5), w)


## One jagged splinter of black stone growing out of `base` along `dir`.
static func shard(m, base: Vector3, dir: Vector3, length: float, radius: float, w: Variant) -> void:
	var up := dir.normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	var other := up.cross(side).normalized()
	var root := Mesh_.ring(base - up * 0.012, side, other, radius, radius * 0.8, 5)
	var waist := Mesh_.ring(base + up * length * 0.52 + side * radius * 0.18, side, other, radius * 0.74, radius * 0.56, 5, 2.0, 0.5)
	var tip := base + up * length
	m.loft("blackstone", [root, waist], w)
	for i in 5:
		m.poly("blackstone", [waist[i], waist[(i + 1) % 5], tip], w, base + up * length * 0.4)


## Where the stone has been set into him: [base, direction, length, radius]
static func _stones(m) -> void:
	var shoulder := {"upperarm_r": 1.0}
	for q in [[Vector3(-0.232, 1.570, -0.075), Vector3(-0.25, 1.0, -0.15), 0.130, 0.030],
			[Vector3(-0.292, 1.552, -0.040), Vector3(-0.6, 1.0, 0.25), 0.085, 0.022],
			[Vector3(-0.190, 1.560, -0.105), Vector3(0.15, 1.0, -0.5), 0.070, 0.020]]:
		shard(m, q[0], q[1], q[2], q[3], shoulder)
	var left := {"upperarm_l": 1.0}
	for q in [[Vector3(0.232, 1.505, -0.060), Vector3(0.1, 1.0, 0.15), 0.082, 0.022],
			[Vector3(0.275, 1.495, -0.095), Vector3(0.45, 0.8, -0.5), 0.055, 0.016],
			[Vector3(0.200, 1.490, -0.015), Vector3(-0.2, 0.7, 0.7), 0.045, 0.014]]:
		shard(m, q[0], q[1], q[2], q[3], left)
	for q in [[Vector3(0.548, 1.498, -0.062), Vector3(0.35, 1.0, -0.1), 0.062, 0.018],
			[Vector3(0.598, 1.484, -0.040), Vector3(0.45, 0.9, 0.4), 0.042, 0.013],
			[Vector3(0.515, 1.488, -0.095), Vector3(0.1, 0.8, -0.6), 0.038, 0.012]]:
		shard(m, q[0], q[1], q[2], q[3], {"lowerarm_l": 1.0})
	# sewn into the coat over the heart, and wedged in the helmet band
	var chest := Shape.torso_face(0.128, 1.330, 1.0, COAT + 0.008)
	shard(m, chest, Vector3(0.45, 0.35, 0.8), 0.058, 0.018, Shape.torso_weights(chest))
	shard(m, chest + Vector3(-0.026, -0.040, 0.006), Vector3(0.1, -0.15, 1.0), 0.032, 0.012, Shape.torso_weights(chest))
	shard(m, Vector3(0.062, 1.792, 0.100), Vector3(0.45, 0.7, 0.6), 0.058, 0.017, {"Head": 1.0})


## His pick: a long ash haft, a curved sharpened point toward +X, a chisel behind, and black
## stone driven in at the eye. Held like the bandits' axe: grip at the origin, haft along +Y.
static func pick(m) -> void:
	m.group = "Pick"
	m.density = 1.0
	var none := {}
	Gear.haft(m)
	m.box("pick_iron", Vector3(0, 0.920, 0), Vector3(0.092, 0.118, 0.066), none)
	# [x, y, half height, half thickness]
	var point := [[0.040, 0.922, 0.044, 0.030], [0.150, 0.944, 0.031, 0.022], [0.262, 0.930, 0.023, 0.016],
			[0.345, 0.892, 0.014, 0.010], [0.425, 0.826, 0.001, 0.001]]
	var rings := []
	for q in point:
		rings.append([Vector3(q[0], q[1] + q[2], 0), Vector3(q[0], q[1], q[3]), Vector3(q[0], q[1] - q[2], 0), Vector3(q[0], q[1], -q[3])])
	m.loft("pick_iron", rings.slice(0, 4), none)
	m.loft("pick_edge", rings.slice(3), none)
	var chisel := [[-0.040, 0.922, 0.040, 0.028], [-0.140, 0.934, 0.024, 0.022], [-0.215, 0.908, 0.018, 0.030], [-0.262, 0.872, 0.003, 0.034]]
	var back := []
	for q in chisel:
		back.append([Vector3(q[0], q[1] + q[2], q[3]), Vector3(q[0], q[1] + q[2], -q[3]), Vector3(q[0], q[1] - q[2], -q[3]), Vector3(q[0], q[1] - q[2], q[3])])
	m.loft("pick_iron", back.slice(0, 3), none)
	m.loft("pick_edge", back.slice(2), none, {"cap_end": true})
	shard(m, Vector3(0.000, 0.985, 0.0), Vector3(0.12, 1.0, 0.05), 0.150, 0.030, none)
	shard(m, Vector3(-0.036, 0.970, 0.012), Vector3(-0.7, 0.8, 0.2), 0.085, 0.022, none)
	shard(m, Vector3(0.022, 0.920, 0.030), Vector3(0.2, 0.2, 1.0), 0.052, 0.020, none)
	shard(m, Vector3(0.010, 0.905, -0.030), Vector3(-0.15, -0.1, -1.0), 0.046, 0.018, none)
	# strips of rawhide binding the head on
	for y: float in [0.828, 0.848]:
		m.loft("lace", [Mesh_.ring(Vector3(0, y, 0), Vector3.RIGHT, Vector3.BACK, 0.032, 0.029, 7),
				Mesh_.ring(Vector3(0, y + 0.012, 0), Vector3.RIGHT, Vector3.BACK, 0.032, 0.029, 7)], none)
