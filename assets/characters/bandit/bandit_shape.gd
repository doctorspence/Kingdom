extends RefCounted
## The bandit's measurements, shared by body, hair, clothes and armor, so layers sit on each other
## and bend together: the torso's cross-sections and its skin weights.

## Torso cross-sections: [height, half width, front z, back z] (front is +Z).
const TORSO := [
	[0.96, 0.158, 0.098, -0.118], [1.05, 0.146, 0.106, -0.112], [1.15, 0.146, 0.112, -0.110], [1.24, 0.164, 0.126, -0.122],
	[1.33, 0.190, 0.142, -0.146], [1.41, 0.204, 0.140, -0.160], [1.47, 0.192, 0.112, -0.152], [1.52, 0.128, 0.074, -0.122],
	[1.56, 0.070, 0.048, -0.086],
]
## How boxy the torso's cross-section is (2 = oval).
const SQUARE := 2.7


## "upperarm" + side (+1 = the character's left, +X).
static func sided(bone: String, s: float) -> String:
	return bone + ("_l" if s > 0.0 else "_r")


## Interpolates a table of rows keyed by their first number. Returns the other columns.
static func lerp_rows(rows: Array, key: float) -> Array:
	if key <= rows[0][0]:
		return rows[0].slice(1)
	for i in rows.size() - 1:
		var a: Array = rows[i]
		var b: Array = rows[i + 1]
		if key <= b[0]:
			var t: float = (key - a[0]) / (b[0] - a[0])
			var out := []
			for j in range(1, a.size()):
				out.append(lerpf(a[j], b[j], t))
			return out
	return rows[rows.size() - 1].slice(1)


## A point on the torso at height y, angle a (0 = front, +PI/2 = the character's left), `margin`
## meters out from the tunic.
static func torso_point(y: float, a: float, margin := 0.0) -> Vector3:
	var k := lerp_rows(TORSO, y)
	var hw: float = k[0] + margin
	var front: float = k[1] + margin
	var back: float = k[2] - margin
	var cz := (front + back) * 0.5
	var hd := (front - back) * 0.5
	var e := 2.0 / SQUARE
	var s := sin(a)
	var c := cos(a)
	return Vector3(signf(s) * pow(absf(s), e) * hw, y, cz + signf(c) * pow(absf(c), e) * hd)


## A point on the torso's front (side = 1) or back (side = -1) at (x, y).
static func torso_face(x: float, y: float, side: float, margin := 0.0) -> Vector3:
	var k := lerp_rows(TORSO, y)
	var hw: float = k[0] + margin
	var front: float = k[1] + margin
	var back: float = k[2] - margin
	var cz := (front + back) * 0.5
	var hd := (front - back) * 0.5
	var u := clampf(absf(x) / hw, 0.0, 0.995)
	var d := pow(1.0 - pow(u, SQUARE), 1.0 / SQUARE)
	return Vector3(x, y, cz + side * d * hd)


## A closed torso ring of n points, starting at the back (so the seam is behind).
static func torso_ring(y: float, margin: float, n: int) -> Array:
	var out := []
	for i in n:
		out.append(torso_point(y, PI + TAU * i / n, margin))
	return out


## Skin weights for anything lying on the torso, by position. Everything on the body uses this,
## so the layers (tunic, vest, belt, straps) move as one and never poke through each other.
static func torso_weights(p: Vector3) -> Dictionary:
	var keys := [[0.96, "pelvis"], [1.06, "spine_01"], [1.19, "spine_02"], [1.33, "spine_03"]]
	var w := {}
	if p.y <= keys[0][0]:
		w = {"pelvis": 1.0}
	elif p.y >= keys[3][0]:
		w = {"spine_03": 1.0}
	else:
		for i in 3:
			if p.y <= keys[i + 1][0]:
				var t: float = (p.y - keys[i][0]) / (keys[i + 1][0] - keys[i][0])
				w = {keys[i][1]: 1.0 - t, keys[i + 1][1]: t}
				break
	# the tops of the shoulders follow the shoulder blades and, a little, the arms
	var side := smoothstep(0.10, 0.20, absf(p.x)) * smoothstep(1.34, 1.46, p.y)
	if side > 0.0:
		for bone in w:
			w[bone] *= 1.0 - side * 0.75
		w[sided("clavicle", p.x)] = side * 0.5
		w[sided("upperarm", p.x)] = side * 0.25
	return w


## Blend between two bones.
static func blend(a: String, b: String, t: float) -> Dictionary:
	if t <= 0.0:
		return {a: 1.0}
	if t >= 1.0:
		return {b: 1.0}
	return {a: 1.0 - t, b: t}


## Weights along an arm, by distance from the middle (|x|): shoulder, elbow and wrist bend smoothly.
static func arm_weights(p: Vector3) -> Dictionary:
	var s := signf(p.x)
	var x := absf(p.x)
	var upper := sided("upperarm", s)
	var lower := sided("lowerarm", s)
	if x < 0.145:
		return {"spine_03": 0.65, sided("clavicle", s): 0.35}
	if x < 0.195:
		return {"spine_03": 0.15, sided("clavicle", s): 0.35, upper: 0.5}
	if x < 0.235:
		return {sided("clavicle", s): 0.2, upper: 0.8}
	if x < 0.425:
		return {upper: 1.0}
	if x < 0.51:
		return blend(upper, lower, (x - 0.425) / 0.085)
	if x < 0.70:
		return {lower: 1.0}
	return blend(lower, sided("hand", s), clampf((x - 0.70) / 0.055, 0.0, 1.0))


## A ring around the arm (a circle in the Y-Z plane) at x, centred at (y, z).
static func arm_ring(s: float, x: float, y: float, z: float, ry: float, rz: float, n: int, square := 2.0) -> Array:
	var out := []
	for i in n:
		var a := TAU * i / n + PI * 0.5 / n
		var e := 2.0 / square
		var ca := cos(a)
		var sa := sin(a)
		out.append(Vector3(x * s, y + signf(sa) * pow(absf(sa), e) * ry, z + signf(ca) * pow(absf(ca), e) * rz))
	return out
