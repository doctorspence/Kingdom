extends RefCounted
## The skin that shows: neck, head and face (nose, brows, eyes, mouth, ears), arms and chunky
## hands with separate fingers that curl around a weapon. Nothing is built under the clothes.

const Shape := preload("res://assets/characters/bandit/bandit_shape.gd")

## Head cross-sections: [height, half width, front, back, half width of the flat face].
## Front and back are measured from HEAD_Z.
const HEAD := [
	[1.566, 0.034, 0.096, 0.006, 0.026], [1.586, 0.066, 0.108, -0.044, 0.044], [1.618, 0.082, 0.108, -0.078, 0.052],
	[1.652, 0.090, 0.108, -0.098, 0.058], [1.690, 0.094, 0.098, -0.110, 0.064], [1.714, 0.098, 0.114, -0.114, 0.068],
	[1.748, 0.096, 0.104, -0.116, 0.062], [1.790, 0.080, 0.080, -0.102, 0.048], [1.818, 0.044, 0.040, -0.062, 0.026],
]
const HEAD_Z := -0.004

## How the face is built (an outfit may override any of these with a "face" entry). The defaults
## are the owner's pick (option 4 of tools/face_options.gd, 2026-11-28): low, thin brow bars, a
## squint with dark eyes and a smaller nose. The original cartoony face is ORIGINAL_FACE.
const FACE_DEFAULTS := {
	"ridge": 1.0,        # brow ridge bulge, 0 = flat forehead
	"jaw": 1.0,          # width of the jaw and chin
	"head_w": 1.0,       # width of the whole head
	"head_d": 1.0,       # depth of the whole head (front to back)
	"nose": "wedge",     # "wedge", "none" (painted only)
	"nose_tip": 0.020,   # how far the nose tip sticks out
	"nose_w": 0.023,     # half width of the nostrils
	"nose_top": 1.704,   # where the nose starts
	"eye": "dark",       # "white" (whites and pupil), "dark" (one dark shape), "none" (painted only)
	"eye_w": 1.0,        # eye size
	"eye_h": 0.6,
	"eye_tilt": 0.0,     # outer corner up (+) or down (-)
	"brow": "bar",       # "bar" (a raised block), "paint" (painted on), "none"
	"brow_in": 1.700,    # height of the inner end
	"brow_out": 1.705,   # height of the outer end
	"brow_w": 0.010,     # bar width (up/down)
	"brow_t": 0.007,     # bar thickness
	"brow_lift": 0.004,  # how far the bar stands off the face
	"brow_len": 0.062,   # where the outer end is
	# paint
	"socket": 0.7,       # dark eye sockets
	"cheek": 0.45,       # cheekbone highlight
	"hollow": 0.55,      # hollow cheeks
	"frown": 1.0,        # frown lines
	"scar": true,
	"stubble": 0.55,
	"brow_paint": 0.9,   # strength of painted brows
	"brow_paint_w": 0.006,
	"mouth": 0.0,        # a painted mouth line
}
## The first face (big angry brow bars, a long wedge nose, white eyes), as a "face" entry.
const ORIGINAL_FACE := {"nose_tip": 0.030, "eye": "white", "eye_h": 1.0, "brow_in": 1.699, "brow_out": 1.716,
		"brow_w": 0.015, "brow_t": 0.016, "brow_lift": 0.008}
## The face being built right now (set by build(); the hair and helmets read the head through it).
static var F := FACE_DEFAULTS.duplicate()


static func set_face(o: Dictionary) -> void:
	F = FACE_DEFAULTS.duplicate()
	F.merge(o.get("face", {}), true)


## One 12-point ring of the head: flat face, cheekbones, rounded skull. `margin` pushes it out.
static func head_ring(y: float, margin := 0.0) -> Array:
	var k: Array = Shape.lerp_rows(HEAD, y)
	var front: float = k[1]
	if y > 1.690 and y < 1.748:
		var plain := lerpf(0.098, 0.104, (y - 1.690) / 0.058)
		front = plain + (front - plain) * float(F.ridge)
	var jaw := lerpf(float(F.jaw), 1.0, smoothstep(1.586, 1.660, y)) * float(F.head_w)
	var hw: float = k[0] * jaw + margin
	var f: float = front * float(F.head_d) + margin
	var b: float = k[2] * float(F.head_d) - margin
	var fw: float = k[3] * jaw + margin * 0.6
	var right := [
		Vector2(0.0, b), Vector2(hw * 0.62, b * 0.88), Vector2(hw * 0.94, b * 0.42), Vector2(hw, f * 0.08),
		Vector2(hw * 0.92, f * 0.56), Vector2(fw, f * 0.93), Vector2(0.0, f),
	]
	var out := []
	for i in 7:
		out.append(Vector3(right[i].x, y, HEAD_Z + right[i].y))
	for i in range(5, 0, -1):
		out.append(Vector3(-right[i].x, y, HEAD_Z + right[i].y))
	return out


## The front surface of the head at (x, y), `margin` out.
static func face_z(x: float, y: float, margin := 0.0) -> float:
	var r := head_ring(y, margin)
	var ax := absf(x)
	var front: Vector3 = r[6]
	var cheek: Vector3 = r[5]
	var side: Vector3 = r[4]
	if ax <= cheek.x:
		return lerpf(front.z, cheek.z, ax / maxf(cheek.x, 0.001))
	return lerpf(cheek.z, side.z, clampf((ax - cheek.x) / maxf(side.x - cheek.x, 0.001), 0.0, 1.0))


static func build(m, o: Dictionary) -> void:
	set_face(o)
	m.group = "Body"
	m.density = 1.0
	_neck(m)
	for s in [1.0, -1.0]:
		_arm(m, s)
		_hand(m, s)
	m.group = "Head"
	_head(m)
	_face(m, o.mask)


static func _neck(m) -> void:
	var rows := [[1.47, 0.074, -0.020], [1.525, 0.060, -0.016], [1.575, 0.056, -0.008], [1.625, 0.060, -0.006]]
	var rings := []
	var ws := [{"spine_03": 1.0}, {"spine_03": 0.35, "neck_01": 0.65}, {"neck_01": 0.45, "Head": 0.55}, {"Head": 1.0}]
	for r in rows:
		var ring := []
		for i in 8:
			var a := PI + TAU * i / 8.0
			ring.append(Vector3(sin(a) * r[1], r[0], r[2] + cos(a) * r[1]))
		rings.append(ring)
	m.loft("skin", rings, ws)


static func _arm(m, s: float) -> void:
	# [|x|, y, z, radius up/down, radius front/back]
	var rows := [
		[0.300, 1.441, -0.068, 0.058, 0.060], [0.375, 1.441, -0.069, 0.060, 0.061], [0.440, 1.441, -0.070, 0.051, 0.051],
		[0.466, 1.441, -0.070, 0.049, 0.049], [0.495, 1.441, -0.070, 0.054, 0.053], [0.560, 1.441, -0.068, 0.063, 0.064],
		[0.640, 1.441, -0.067, 0.050, 0.057], [0.710, 1.442, -0.067, 0.033, 0.044], [0.742, 1.443, -0.067, 0.029, 0.040],
	]
	var rings := []
	for r in rows:
		rings.append(Shape.arm_ring(s, r[0], r[1], r[2], r[3], r[4], 8))
	m.loft("skin", rings, Shape.arm_weights)


static func _hand(m, s: float) -> void:
	var hand: String = Shape.sided("hand", s)
	# palm: [|x|, y, centre z, half thickness, half width]
	var rows := [
		[0.735, 1.443, -0.066, 0.030, 0.040], [0.765, 1.447, -0.068, 0.031, 0.052],
		[0.815, 1.448, -0.070, 0.029, 0.056], [0.862, 1.446, -0.069, 0.022, 0.052],
	]
	var rings := []
	for r in rows:
		rings.append(Shape.arm_ring(s, r[0], r[1], r[2], r[3], r[4], 8, 4.0))
	m.loft("hand", rings, {hand: 1.0}, {"cap_end": true})
	# four chunky fingers, each following its own bones so the fist closes in the animations
	# [bone, z, joint x positions]
	var fingers := [
		["index", -0.033, [0.850, 0.899, 0.934, 0.962]],
		["middle", -0.059, [0.850, 0.903, 0.939, 0.972]],
		["ring", -0.084, [0.848, 0.897, 0.929, 0.958]],
		["pinky", -0.107, [0.842, 0.887, 0.914, 0.938]],
	]
	for f in fingers:
		var name_: String = f[0]
		var z: float = f[1]
		var j: Array = f[2]
		var b1: String = Shape.sided(name_ + "_01", s)
		var b2: String = Shape.sided(name_ + "_02", s)
		var b3: String = Shape.sided(name_ + "_03", s)
		var thick := [0.0170, 0.0155, 0.0135, 0.0100]
		var wide := [0.0135, 0.0130, 0.0118, 0.0090]
		var frings := []
		for i in 4:
			frings.append(Shape.arm_ring(s, j[i], 1.445 - i * 0.002, z, thick[i], wide[i], 4, 3.2))
		var ws := [{hand: 0.5, b1: 0.5}, {b1: 0.45, b2: 0.55}, {b2: 0.45, b3: 0.55}, {b3: 1.0}]
		m.loft("finger", frings, ws, {"cap_end": true})
	# thumb
	var pts := [Vector3(0.764, 1.428, -0.040), Vector3(0.802, 1.405, -0.014), Vector3(0.838, 1.383, 0.004), Vector3(0.866, 1.366, 0.019)]
	var radii := [0.027, 0.021, 0.017, 0.011]
	var t1: String = Shape.sided("thumb_01", s)
	var t2: String = Shape.sided("thumb_02", s)
	var t3: String = Shape.sided("thumb_03", s)
	var tw := [{hand: 0.7, t1: 0.3}, {t1: 0.4, t2: 0.6}, {t2: 0.4, t3: 0.6}, {t3: 1.0}]
	var trings := []
	for i in 4:
		var p: Vector3 = pts[i]
		p.x *= s
		var q: Vector3 = pts[mini(i + 1, 3)]
		var o: Vector3 = pts[maxi(i - 1, 0)]
		q.x *= s
		o.x *= s
		var along := (q - o).normalized()
		var u := along.cross(Vector3.UP).normalized()
		var v := along.cross(u).normalized()
		trings.append(preload("res://assets/characters/bandit/bandit_mesh.gd").ring(p, u, v, radii[i], radii[i], 5))
	m.loft("finger", trings, tw, {"cap_end": true, "cap_start": true})


static func _head(m) -> void:
	m.density = 1.9
	var rings := []
	for r in HEAD:
		rings.append(head_ring(r[0]))
	m.loft("face", rings, {"Head": 1.0}, {"cap_start": true, "cap_end": true, "cap_style": "face"})


static func _face(m, masked: bool) -> void:
	var w := {"Head": 1.0}
	m.density = 1.9
	# nose: a wedge from between the brows to the tip
	var ny: float = F.nose_top
	var bridge := Vector3(0.0, ny, face_z(0.0, ny) - 0.006)
	var tip := Vector3(0.0, 1.650, face_z(0.0, 1.650) + float(F.nose_tip))
	var under := Vector3(0.0, 1.640, face_z(0.0, 1.640) - 0.004)
	var nose_in := Vector3(0.0, 1.665, 0.07)
	var nw: float = F.nose_w
	for s in ([] if masked or F.nose == "none" else [1.0, -1.0]):
		var wing := Vector3(nw * s, 1.648, face_z(nw, 1.648) - 0.004)
		var top := Vector3(0.010 * s, ny, face_z(0.010, ny) - 0.006)
		m.poly("nose", [bridge, tip, wing, top], w, nose_in)
		m.poly("nose", [tip, under, wing], w, nose_in)
	for s in [1.0, -1.0]:
		# eyes, set under the brows (scaled about their middle)
		if F.eye != "none":
			var pts := []
			for q in [[0.016, 1.689], [0.030, 1.695], [0.048, 1.692], [0.032, 1.683]]:
				var x: float = 0.032 + (q[0] - 0.032) * float(F.eye_w)
				var y: float = 1.689 + (q[1] - 1.689) * float(F.eye_h) + (x - 0.032) * float(F.eye_tilt)
				pts.append(Vector3(x * s, y, face_z(x, y) + 0.0025))
			m.poly("eye", pts, w, Vector3(0, 1.69, 0.0))
		# brows
		if F.brow == "bar":
			var bi: float = F.brow_in
			var bo: float = F.brow_out
			var bl: float = F.brow_len
			var lift: float = F.brow_lift
			var inner := Vector3(0.008 * s, bi, face_z(0.008, bi) + lift)
			var outer := Vector3(bl * s, bo, face_z(bl, bo) + lift * 0.62)
			m.bar("brow", inner, outer, float(F.brow_w), float(F.brow_t), Vector3.BACK, w)
		# ears
		var e := Vector3(0.098 * s, 1.668, -0.018)
		var ear := [e + Vector3(0, 0.030, 0.012), e + Vector3(0.016 * s, 0.034, -0.014), e + Vector3(0.014 * s, -0.004, -0.024),
				e + Vector3(0.002 * s, -0.030, -0.002), e + Vector3(0, -0.012, 0.016)]
		m.poly("ear", ear, w, e + Vector3(-0.03 * s, 0, 0))
		for i in ear.size():
			m.poly("ear", [ear[i], ear[(i + 1) % ear.size()], e + Vector3(-0.012 * s, 0, 0)], w, e + Vector3(-0.004 * s, 0.0, -0.004))
