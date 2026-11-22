extends RefCounted
## Procedural armor for the mannequin skeleton (UAL1). Every piece is a skinned mesh built in the
## skeleton's rest (T-pose) space and weighted automatically from the nearest bone segments, so it
## bends with every animation. Pieces are modular: head / chest (with sleeves) / legs, each its own
## item and its own mesh. CharacterModel.set_armor() copies the meshes onto the live skeleton.
##
## Body numbers below were measured from the mannequin (tools/measure_body.gd); each armor type
## adds its own margin so nothing clips through the body.

const Mesh_ := preload("res://assets/equipment/eq_mesh.gd")
const Kit := preload("res://assets/equipment/eq_kit.gd")
const RIG_SCENE := "res://assets/characters/mannequin/UAL1_Standard.glb"

static var _rig := {}

# (y, half width, front z, back z) of the bare torso, measured.
const TORSO := [
	[0.86, 0.165, 0.10, -0.115], [0.95, 0.172, 0.108, -0.122], [1.05, 0.152, 0.122, -0.118], [1.15, 0.132, 0.126, -0.104],
	[1.22, 0.136, 0.112, -0.1], [1.30, 0.165, 0.13, -0.14], [1.38, 0.182, 0.138, -0.162], [1.46, 0.19, 0.118, -0.158],
	[1.52, 0.13, 0.09, -0.135], [1.57, 0.075, 0.075, -0.095],
]


# ------------------------------------------------------------------ rig

## {bone name: {"i": index, "p": rest position, "g": global rest transform}} from the mannequin skeleton.
static func rig() -> Dictionary:
	if not _rig.is_empty():
		return _rig
	var scene: Node = (load(RIG_SCENE) as PackedScene).instantiate()
	var sk: Skeleton3D = scene.find_children("*", "Skeleton3D", true, false)[0]
	var d := {}
	for i in sk.get_bone_count():
		var g := sk.get_bone_global_rest(i)
		d[sk.get_bone_name(i)] = {"i": i, "p": g.origin, "g": g}
	_rig = {"bones": d, "count": sk.get_bone_count()}
	scene.free()
	return _rig


static func bp(name: String) -> Vector3:
	return rig().bones[name].p


## A skin with a bind pose for every bone, in skeleton order.
static func make_skin() -> Skin:
	var skin := Skin.new()
	var names: Array = rig().bones.keys()
	names.sort_custom(func(a, b): return rig().bones[a].i < rig().bones[b].i)
	for n in names:
		skin.add_named_bind(n, (rig().bones[n].g as Transform3D).affine_inverse())
	return skin


## Bone segments [index, from, to] used to weight the vertices of one body part.
static func segs(names: Array) -> Array:
	var out: Array = []
	var chain := {"pelvis": "spine_01", "spine_01": "spine_02", "spine_02": "spine_03", "spine_03": "neck_01", "neck_01": "Head",
			"clavicle_l": "upperarm_l", "upperarm_l": "lowerarm_l", "lowerarm_l": "hand_l", "hand_l": "middle_01_l",
			"clavicle_r": "upperarm_r", "upperarm_r": "lowerarm_r", "lowerarm_r": "hand_r", "hand_r": "middle_01_r",
			"thigh_l": "calf_l", "calf_l": "foot_l", "foot_l": "ball_l", "thigh_r": "calf_r", "calf_r": "foot_r", "foot_r": "ball_r"}
	for n in names:
		var from: Vector3 = bp(n)
		var to: Vector3 = Vector3(0, 1.84, 0.0) if n == "Head" else bp(chain[n])
		out.append([rig().bones[n].i, from, to])
	return out


const TORSO_BONES := ["pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "clavicle_l", "clavicle_r"]
const HEAD_BONES := ["neck_01", "Head", "spine_03"]
const LEG_BONES_L := ["pelvis", "thigh_l", "calf_l", "foot_l"]
const LEG_BONES_R := ["pelvis", "thigh_r", "calf_r", "foot_r"]
const ARM_BONES_L := ["spine_03", "clavicle_l", "upperarm_l", "lowerarm_l", "hand_l"]
const ARM_BONES_R := ["spine_03", "clavicle_r", "upperarm_r", "lowerarm_r", "hand_r"]


static func _new_mesh(bones: Array):
	var m := Mesh_.new()
	var segs_: Array = []
	for group in bones:
		segs_.append_array(segs(group))
	m.skin_bones = segs_
	m.skin_max = 2
	m.skin_power = 4.0
	return m


static func _root(name: String, m) -> Node3D:
	var root := Node3D.new()
	root.name = name
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = m.finish()
	mi.skin = make_skin()
	root.add_child(mi)
	return root


# ------------------------------------------------------------------ shapes

static func _lerp_key(keys: Array, y: float) -> Array:
	if y <= keys[0][0]:
		return keys[0].slice(1)
	for i in keys.size() - 1:
		if y <= keys[i + 1][0]:
			var t: float = (y - keys[i][0]) / (keys[i + 1][0] - keys[i][0])
			var out: Array = []
			for k in range(1, keys[i].size()):
				out.append(lerpf(keys[i][k], keys[i + 1][k], t))
			return out
	return keys[keys.size() - 1].slice(1)


## One torso ring at height y. Superellipse: p = 2 round, higher = boxier. front is +Z.
static func _ring(y: float, hx: float, zf: float, zb: float, n: int, p := 2.4, dz := 0.0) -> PackedVector3Array:
	var ring := PackedVector3Array()
	for i in n:
		var a := TAU * i / n
		var c := cos(a)
		var s := sin(a)
		var x := hx * signf(c) * pow(absf(c), 2.0 / p)
		var z := (zf if s > 0.0 else -zb) * signf(s) * pow(absf(s), 2.0 / p)
		ring.append(Vector3(x, y, z + dz))
	return ring


## Loft a torso-like body between two heights through the measured keyframes.
static func torso_tube(m, mat, y0: float, y1: float, margin: float, steps: int, n := 18, p := 2.4, flare := Callable(), smooth := true, cap_top := false, cap_bottom := false) -> Array:
	var rings: Array = []
	for i in steps + 1:
		var y := lerpf(y0, y1, float(i) / steps)
		var k := _lerp_key(TORSO, y)
		var mg := margin
		if flare.is_valid():
			mg += flare.call(y)
		rings.append(_ring(y, k[0] + mg, k[1] + mg, k[2] - mg, n, p))
	m.loft(mat, rings, smooth, cap_bottom, cap_top)
	return rings


## Round tube along a path with a radius at every point (arms, legs, straps).
static func tube(m, mat, pts: Array, radii: Array, sides := 10, smooth := true, cap_a := false, cap_b := false, squash := Vector2.ONE, ref := Vector3.UP) -> void:
	var rings: Array = []
	for i in pts.size():
		var t: Vector3 = (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var r := ref
		if absf(t.dot(r)) > 0.95:
			r = Vector3.BACK
		var u := t.cross(r).normalized()
		var v := t.cross(u).normalized()
		var ring := PackedVector3Array()
		for k in sides:
			var a := TAU * k / sides
			ring.append(pts[i] + u * cos(a) * radii[i] * squash.x + v * sin(a) * radii[i] * squash.y)
		rings.append(ring)
	m.loft(mat, rings, smooth, cap_a, cap_b)


## Head shell: rings follow the head ellipsoid, and flare out into a cowl over the shoulders below it.
static func head_rings(y0: float, y1: float, margin: float, steps: int, n := 16, cowl := 0.0) -> Array:
	var rings: Array = []
	for i in steps + 1:
		var y := lerpf(y0, y1, float(i) / steps)
		var hx: float
		var zf: float
		var zb: float
		if y >= 1.57:
			var t := clampf((y - 1.70) / 0.15, -1.0, 1.0)
			var sc := sqrt(maxf(1.0 - t * t, 0.0))
			hx = 0.092 * sc + margin
			zf = 0.118 * sc + margin
			zb = -0.13 * sc - margin
			if y > 1.835:
				hx = maxf(hx - 0.01, 0.0)
		else:
			var k := _lerp_key(TORSO, y)
			var neck := _neck_key(y)
			hx = neck[0] + margin + cowl * smoothstep(1.57, 1.44, y)
			zf = neck[1] + margin + cowl * smoothstep(1.57, 1.44, y) * 0.6
			zb = neck[2] - margin - cowl * smoothstep(1.57, 1.44, y) * 0.8
		rings.append(_ring(y, hx, zf, zb, n, 2.2))
	return rings


static func _neck_key(y: float) -> Array:
	return _lerp_key([[1.40, 0.19, 0.13, -0.16], [1.48, 0.15, 0.09, -0.14], [1.52, 0.075, 0.062, -0.075], [1.60, 0.062, 0.07, -0.085], [1.65, 0.085, 0.105, -0.115], [1.70, 0.092, 0.118, -0.13]], y)


# ------------------------------------------------------------------ pieces

static func _belt(m, leather, metal, y: float, margin: float) -> void:
	var rings: Array = []
	for dy in [-0.032, 0.032]:
		var k := _lerp_key(TORSO, y + dy)
		rings.append(_ring(y + dy, k[0] + margin, k[1] + margin, k[2] - margin, 18, 2.4))
	m.loft(leather, rings, false, false, false)
	var kf := _lerp_key(TORSO, y)
	m.box(metal, Vector3(0, y, kf[1] + margin + 0.004), Vector3(0.055, 0.05, 0.014))
	m.box(leather, Vector3(0.09, y - 0.045, kf[1] + margin - 0.02), Vector3(0.02, 0.06, 0.012))


static func _arm_path(side: float, elbow_bend := 0.0) -> Array:
	var sh := bp("upperarm_l")
	var el := bp("lowerarm_l")
	var wr := bp("hand_l")
	return [Vector3(sh.x * side, sh.y, sh.z), Vector3(el.x * side, el.y, el.z), Vector3(wr.x * side, wr.y, wr.z)]


## A sleeve / arm guard: from fraction t0..t1 of the arm (0 = shoulder, 1 = wrist).
static func sleeve(m, mat, side: float, t0: float, t1: float, r_sh: float, r_el: float, r_wr: float, sides := 10, cap_a := false, cap_b := false, flare := 0.0) -> void:
	var path := _arm_path(side)
	var pts: Array = []
	var radii: Array = []
	var steps := 6
	for i in steps + 1:
		var t := lerpf(t0, t1, float(i) / steps)
		var a: Vector3
		var r: float
		if t < 0.5:
			a = path[0].lerp(path[1], t * 2.0)
			r = lerpf(r_sh, r_el, t * 2.0)
		else:
			a = path[1].lerp(path[2], (t - 0.5) * 2.0)
			r = lerpf(r_el, r_wr, (t - 0.5) * 2.0)
		if i == steps:
			r += flare
		pts.append(a)
		radii.append(r)
	tube(m, mat, pts, radii, sides, true, cap_a, cap_b)


static func _leg_path(side: float) -> Array:
	var h := bp("thigh_l")
	var k := bp("calf_l")
	var a := bp("foot_l")
	return [Vector3(h.x * side, h.y, h.z), Vector3(k.x * side, k.y, k.z), Vector3(a.x * side, a.y, a.z)]


## A trouser leg / leg armor: fraction t0..t1 of the leg (0 = hip, 1 = ankle).
static func leg(m, mat, side: float, t0: float, t1: float, r_hip: float, r_knee: float, r_ankle: float, sides := 10, cap_b := false, flare := 0.0) -> void:
	var path := _leg_path(side)
	var pts: Array = []
	var radii: Array = []
	var steps := 8
	for i in steps + 1:
		var t := lerpf(t0, t1, float(i) / steps)
		var a: Vector3
		var r: float
		if t < 0.5:
			a = path[0].lerp(path[1], t * 2.0)
			r = lerpf(r_hip, r_knee, t * 2.0)
		else:
			a = path[1].lerp(path[2], (t - 0.5) * 2.0)
			r = lerpf(r_knee, r_ankle, (t - 0.5) * 2.0)
		if i == steps:
			r += flare
		pts.append(a)
		radii.append(r)
	tube(m, mat, pts, radii, sides, true, false, cap_b, Vector2(1.0, 1.05))


# ------------------------------------------------------------------ the items

static func chainmail_body() -> Node3D:
	var m = _new_mesh([TORSO_BONES, ARM_BONES_L, ARM_BONES_R])
	var mail = Kit.get_mat("chainmail")
	var leather = Kit.get_mat("leather")
	var iron = Kit.get_mat("iron")
	# hauberk: hem at the hips, flaring a little, up over the shoulders to the neck
	torso_tube(m, mail, 0.88, 1.52, 0.024, 12, 18, 2.4, func(y): return 0.02 * smoothstep(1.0, 0.88, y))
	for s in [1.0, -1.0]:
		sleeve(m, mail, s, 0.0, 0.5, 0.086, 0.066, 0.058, 10, false, false, 0.008)
	_belt(m, leather, iron, 1.1, 0.034)
	return _root("Armor_chainmail_body", m)


static func chainmail_legs() -> Node3D:
	var m = _new_mesh([LEG_BONES_L, LEG_BONES_R])
	var mail = Kit.get_mat("chainmail")
	var leather = Kit.get_mat("leather")
	# hip band so the two legs join, then a leg each down to the ankle
	var rings: Array = []
	for y in [0.86, 0.95, 1.02]:
		var k := _lerp_key(TORSO, y)
		rings.append(_ring(y, k[0] + 0.024, k[1] + 0.022, k[2] - 0.022, 18, 2.4))
	m.loft(mail, rings, true, false, false)
	for s in [1.0, -1.0]:
		leg(m, mail, s, 0.0, 0.97, 0.1, 0.076, 0.056, 10, false, 0.004)
	# a thin leather band at each ankle
	for s in [1.0, -1.0]:
		var a := bp("foot_l")
		tube(m, leather, [Vector3(a.x * s, a.y + 0.12, a.z + 0.002), Vector3(a.x * s, a.y + 0.09, a.z)], [0.07, 0.068], 10, true)
	return _root("Armor_chainmail_legs", m)


static func _coif_like(m, mat, hood := false) -> void:
	# lower neck / shoulder cowl (closed)
	var lower := head_rings(1.40 if hood else 1.43, 1.60, 0.02, 6, 16, 0.07 if hood else 0.035)
	m.loft(mat, lower, true, false, false)
	# face opening: drop the front arc between 1.60 and 1.76 (open strip)
	var mid := head_rings(1.60, 1.77, 0.02, 4, 16)
	var open_mid: Array = []
	var cents := PackedVector3Array()
	for r in mid:
		var sub := PackedVector3Array()
		for k in range(7, 18):
			sub.append(r[k % 16])
		open_mid.append(sub)
		cents.append(Vector3(0, r[0].y, -0.005))
	m.loft(mat, open_mid, true, false, false, false, cents)
	# crown (closed dome)
	var top := head_rings(1.77, 1.856, 0.02, 3, 16)
	m.loft(mat, top, true, false, true)


static func chainmail_coif() -> Node3D:
	var m = _new_mesh([HEAD_BONES])
	var mail = Kit.get_mat("chainmail")
	_coif_like(m, mail)
	return _root("Armor_chainmail_coif", m)


static func leather_hood() -> Node3D:
	var m = _new_mesh([HEAD_BONES])
	var leather = Kit.get_mat("leather")
	var dark = Kit.get_mat("leather_dark")
	_coif_like(m, leather, true)
	# pointed cowl at the back of the head and a stitched brim line
	var back := Vector3(0, 1.80, -0.14)
	m.cone(leather, Vector3(0, 1.78, -0.1), back + Vector3(0, -0.07, -0.1), 0.075, 8)
	var rim: Array = []
	for y in [1.74, 1.77]:
		var rg := PackedVector3Array()
		for k in range(7, 18):
			var a := TAU * (k % 16) / 16.0
			rg.append(Vector3(cos(a) * (0.108 + 0.004), y, sin(a) * 0.135 + (-0.005 if sin(a) < 0 else 0.0)))
		rim.append(rg)
	m.loft(dark, rim, false, false, false, false, PackedVector3Array([Vector3(0, 1.74, -0.005), Vector3(0, 1.77, -0.005)]))
	return _root("Armor_leather_hood", m)


static func leather_body() -> Node3D:
	var m = _new_mesh([TORSO_BONES, ARM_BONES_L, ARM_BONES_R])
	var leather = Kit.get_mat("leather")
	var dark = Kit.get_mat("leather_dark")
	var iron = Kit.get_mat("iron")
	var cloth = Kit.get_mat("cloth_coarse")
	# a gambeson-like undershirt (coarse cloth) with a leather jerkin over it and long sleeves
	torso_tube(m, leather, 0.9, 1.5, 0.022, 12, 18, 2.4, func(y): return 0.018 * smoothstep(1.0, 0.9, y))
	for s in [1.0, -1.0]:
		sleeve(m, cloth, s, 0.0, 0.98, 0.084, 0.063, 0.05, 10, false, false, 0.0)
		# leather bracer on the forearm with two straps
		sleeve(m, leather, s, 0.62, 0.95, 0.064, 0.058, 0.053, 10, false, false, 0.0)
		for t in [0.7, 0.85]:
			sleeve(m, dark, s, t, t + 0.045, 0.078, 0.078, 0.072, 10, false, false)
	# crossed chest straps and a belt
	for sgn in [-1.0, 1.0]:
		var p0 := Vector3(sgn * 0.17, 1.46, -0.01)
		var p1 := Vector3(-sgn * 0.12, 1.18, 0.13)
		var mid := (p0 + p1) * 0.5
		var dirv := (p1 - p0)
		m.box(dark, mid + Vector3(0, 0, 0.012), Vector3(0.045, dirv.length(), 0.012), Basis(Vector3.BACK, atan2(-dirv.x, dirv.y)))
	m.box(iron, Vector3(0, 1.32, 0.158), Vector3(0.035, 0.035, 0.012))
	_belt(m, dark, iron, 1.08, 0.04)
	# pauldron-style shoulder flaps
	for s in [1.0, -1.0]:
		var sh := bp("upperarm_l")
		var d := Vector3(sh.x * s + s * 0.04, sh.y + 0.075, sh.z)
		tube(m, leather, [d + Vector3(-s * 0.09, 0.0, 0), d + Vector3(0, 0.01, 0), d + Vector3(s * 0.1, -0.04, 0)], [0.07, 0.09, 0.075], 10, true, false, false, Vector2(1.0, 1.0), Vector3.RIGHT)
	return _root("Armor_leather_body", m)


static func leather_legs() -> Node3D:
	var m = _new_mesh([LEG_BONES_L, LEG_BONES_R])
	var leather = Kit.get_mat("leather")
	var dark = Kit.get_mat("leather_dark")
	var cloth = Kit.get_mat("leather_dark")
	var rings: Array = []
	for y in [0.86, 0.95, 1.04]:
		var k := _lerp_key(TORSO, y)
		rings.append(_ring(y, k[0] + 0.02, k[1] + 0.018, k[2] - 0.018, 18, 2.4))
	m.loft(cloth, rings, true, false, false)
	for s in [1.0, -1.0]:
		leg(m, cloth, s, 0.0, 0.97, 0.108, 0.08, 0.056, 10, false, 0.0)
		# leather knee patch and shin wraps
		var k := bp("calf_l")
		var kn := Vector3(k.x * s, k.y, k.z)
		tube(m, leather, [kn + Vector3(0, 0.07, 0.012), kn + Vector3(0, -0.07, 0.012)], [0.075, 0.07], 10, true, false, false, Vector2(1.0, 1.0))
		for t in [0.63, 0.75, 0.87]:
			leg(m, dark, s, t, t + 0.035, 0.062, 0.062, 0.062, 10)
	_belt(m, dark, Kit.get_mat("iron"), 1.0, 0.0)
	return _root("Armor_leather_legs", m)


static func wizard_robe_top() -> Node3D:
	var m = _new_mesh([TORSO_BONES, ARM_BONES_L, ARM_BONES_R, ["thigh_l", "thigh_r"]])
	var blue = Kit.get_mat("cloth_blue")
	var trim = Kit.get_mat("cloth_trim")
	var leather = Kit.get_mat("leather_dark")
	var iron = Kit.get_mat("dark_steel")
	# loose tunic: torso plus a skirt falling to mid-thigh
	torso_tube(m, blue, 0.72, 1.52, 0.03, 14, 18, 2.2, func(y): return 0.05 * smoothstep(1.05, 0.72, y))
	for s in [1.0, -1.0]:
		sleeve(m, blue, s, 0.0, 0.98, 0.092, 0.075, 0.062, 10, false, false, 0.03)
		sleeve(m, trim, s, 0.93, 1.0, 0.078, 0.078, 0.078, 10, false, false, 0.034)
	# hem trim and a collar band
	var hem: Array = []
	for y in [0.72, 0.755]:
		var k := _lerp_key(TORSO, 1.0)
		var mg := 0.03 + 0.05 * smoothstep(1.05, 0.72, y)
		hem.append(_ring(y, k[0] + mg + 0.004, k[1] + mg + 0.004, k[2] - mg - 0.004, 18, 2.2))
	m.loft(trim, hem, false, false, false)
	var coll: Array = []
	for y in [1.50, 1.53]:
		var k := _lerp_key(TORSO, y)
		coll.append(_ring(y, k[0] + 0.036, k[1] + 0.036, k[2] - 0.036, 18, 2.2))
	m.loft(trim, coll, false, false, false)
	_belt(m, leather, iron, 1.12, 0.062)
	# a diagonal shoulder strap
	m.box(leather, Vector3(0, 1.3, 0.158), Vector3(0.04, 0.36, 0.01), Basis(Vector3.BACK, 0.5))
	return _root("Armor_wizard_robe_top", m)


static func wizard_robe_bottom() -> Node3D:
	var m = _new_mesh([LEG_BONES_L, LEG_BONES_R])
	var blue = Kit.get_mat("cloth_blue")
	var trim = Kit.get_mat("cloth_trim")
	var rings: Array = []
	for y in [0.86, 0.95, 1.04]:
		var k := _lerp_key(TORSO, y)
		rings.append(_ring(y, k[0] + 0.028, k[1] + 0.026, k[2] - 0.026, 18, 2.2))
	m.loft(blue, rings, true, false, false)
	for s in [1.0, -1.0]:
		leg(m, blue, s, 0.0, 1.0, 0.11, 0.09, 0.08, 12, false, 0.03)
		leg(m, trim, s, 0.965, 1.0, 0.1, 0.1, 0.1, 12, false, 0.03)
	return _root("Armor_wizard_robe_bottom", m)


## Wizard hat: a wide brim, a tall cone that bends over at the tip.
static func wizard_hat(kind: String) -> Node3D:
	var m = _new_mesh([["Head"]])
	var cloth = Kit.get_mat("cloth_" + kind)
	var trim = Kit.get_mat("leather_dark")
	var y0 := 1.745
	var xf := Transform3D(Basis.IDENTITY, Vector3(0, y0, -0.005))
	# brim: flat cone, slightly drooping
	m.lathe(cloth, xf, [[0.125, -0.012], [0.2, -0.03], [0.285, -0.052], [0.29, -0.046], [0.2, -0.015], [0.128, 0.0]], 18, true, false)
	# crown: rings that lean back and bend at the tip
	var rings: Array = []
	var levels := [[0.118, 0.0, 0.0], [0.108, 0.06, -0.004], [0.092, 0.14, -0.015], [0.07, 0.23, -0.04], [0.05, 0.31, -0.085], [0.032, 0.37, -0.15], [0.018, 0.4, -0.215], [0.0, 0.415, -0.265]]
	for lv in levels:
		var ring := PackedVector3Array()
		for k in 14:
			var a := TAU * k / 14
			ring.append(Vector3(cos(a) * lv[0], y0 + lv[1], sin(a) * lv[0] * 1.08 + lv[2] - 0.005))
		rings.append(ring)
	m.loft(cloth, rings, true, false, false)
	# band
	m.lathe(trim, xf, [[0.121, 0.012], [0.125, 0.014], [0.125, 0.05], [0.121, 0.052]], 18, true, false)
	m.box(Kit.get_mat("iron"), Vector3(0, y0 + 0.031, 0.128), Vector3(0.035, 0.034, 0.008))
	return _root("Armor_wizard_hat_" + kind, m)


# ---- plate

static func platebody() -> Node3D:
	var m = _new_mesh([TORSO_BONES, ARM_BONES_L, ARM_BONES_R])
	var steel = Kit.get_mat("steel")
	var dark = Kit.get_mat("dark_steel")
	var leather = Kit.get_mat("leather_dark")
	var mail = Kit.get_mat("chainmail")
	# mail shirt underneath showing at the waist and arms, then plate over the chest
	torso_tube(m, mail, 0.92, 1.18, 0.024, 4, 18, 2.4)
	for s in [1.0, -1.0]:
		sleeve(m, mail, s, 0.0, 0.55, 0.078, 0.06, 0.054, 10, false, false, 0.0)
	# breastplate and back plate: boxy, with a raised center ridge on the front
	torso_tube(m, steel, 1.17, 1.52, 0.04, 8, 20, 3.0, Callable(), true, true, false)
	m.box(steel, Vector3(0, 1.32, 0.205), Vector3(0.03, 0.26, 0.03), Basis(Vector3.RIGHT, 0.12))
	# faulds: overlapping plates below the belt
	for i in 3:
		var y := 1.17 - i * 0.075
		var k := _lerp_key(TORSO, y)
		var rg: Array = []
		for dy in [0.0, -0.085]:
			var mg := 0.044 + i * 0.012 + (0.02 if dy < 0 else 0.0)
			rg.append(_ring(y + dy, k[0] + mg, k[1] + mg, k[2] - mg, 20, 3.0))
		m.loft(steel, rg, true, false, false)
	# arms: pauldron (three lames), upper arm, elbow cop, vambrace
	for s in [1.0, -1.0]:
		var sh := bp("upperarm_l")
		var c := Vector3(sh.x * s * 1.05, sh.y + 0.03, sh.z)
		for i in 3:
			var rr := 0.115 - i * 0.012
			m.lathe(steel, Transform3D(Basis(Vector3.BACK, -s * (0.35 + i * 0.12)), c + Vector3(s * (0.015 + i * 0.012), -i * 0.025, 0)), [[0.0, 0.0], [rr, -0.008], [rr * 1.02, -0.05]], 12, true, false)
		sleeve(m, steel, s, 0.06, 0.3, 0.08, 0.068, 0.062, 10, false, false)
		var el := bp("lowerarm_l")
		m.sphere(dark, Vector3(el.x * s, el.y + 0.01, el.z - 0.03), 0.07, 10, 6)
		sleeve(m, steel, s, 0.58, 0.97, 0.064, 0.055, 0.05, 10, false, false, 0.0)
		sleeve(m, leather, s, 0.5, 0.56, 0.08, 0.08, 0.08, 10, false, false)
	# leather straps over the shoulders, belt and buckle
	for s in [1.0, -1.0]:
		m.box(leather, Vector3(s * 0.12, 1.5, 0.0), Vector3(0.04, 0.012, 0.2))
	_belt(m, leather, dark, 1.17, 0.052)
	return _root("Armor_platebody", m)


static func plate_helm() -> Node3D:
	var m = _new_mesh([HEAD_BONES])
	var steel = Kit.get_mat("steel")
	var dark = Kit.get_mat("dark_steel")
	# a rounded bascinet: skull dome down to the brow, cheek plates, a nose bar, a neck guard behind
	var dome := head_rings(1.64, 1.865, 0.026, 6, 16)
	m.loft(steel, dome, true, false, true)
	var guard: Array = []
	var cents := PackedVector3Array()
	for y in [1.50, 1.56, 1.64]:
		var r := _ring(y, 0.1 + 0.04 * smoothstep(1.64, 1.5, y), 0.1, -0.128 - 0.05 * smoothstep(1.64, 1.5, y), 16, 2.2)
		var sub := PackedVector3Array()
		for k in range(8, 17):
			sub.append(r[k % 16])
		guard.append(sub)
		cents.append(Vector3(0, y, -0.005))
	m.loft(steel, guard, true, false, false, false, cents)
	for s in [1.0, -1.0]:
		m.box(steel, Vector3(s * 0.1, 1.62, 0.04), Vector3(0.018, 0.14, 0.1), Basis(Vector3.UP, s * 0.2))
	m.box(dark, Vector3(0, 1.69, 0.145), Vector3(0.024, 0.115, 0.012))
	# brow band
	m.lathe(dark, Transform3D(Basis.IDENTITY, Vector3(0, 1.735, -0.005)), [[0.105, -0.012], [0.12, -0.01], [0.12, 0.012], [0.105, 0.014]], 16, true, false)
	return _root("Armor_plate_helm", m)


static func plate_legs() -> Node3D:
	var m = _new_mesh([LEG_BONES_L, LEG_BONES_R])
	var steel = Kit.get_mat("steel")
	var dark = Kit.get_mat("dark_steel")
	var mail = Kit.get_mat("chainmail")
	var leather = Kit.get_mat("leather_dark")
	var rings: Array = []
	for y in [0.86, 0.95, 1.04]:
		var k := _lerp_key(TORSO, y)
		rings.append(_ring(y, k[0] + 0.026, k[1] + 0.024, k[2] - 0.024, 18, 2.4))
	m.loft(mail, rings, true, false, false)
	for s in [1.0, -1.0]:
		leg(m, mail, s, 0.0, 0.97, 0.098, 0.072, 0.052, 10, false, 0.0)
		leg(m, steel, s, 0.05, 0.43, 0.11, 0.086, 0.078, 12, false, 0.0)    # cuisse
		var k := bp("calf_l")
		m.sphere(steel, Vector3(k.x * s, k.y + 0.01, k.z + 0.04), 0.052, 10, 6)   # poleyn
		leg(m, steel, s, 0.6, 0.95, 0.076, 0.062, 0.055, 12, false, 0.0)    # greave
	_belt(m, leather, dark, 1.0, 0.0)
	return _root("Armor_plate_legs", m)


# ------------------------------------------------------------------ catalog

static func catalog() -> Array:
	var out: Array = []
	var cm := "Chainmail"
	out.append({"id": "item_chainmail_coif", "name": "Chainmail Coif", "cat": cm, "folder": "Armor", "kind": "armor", "slot": 1, "tier": "chainmail", "build": "chainmail_coif",
			"grid": Vector2i(2, 2), "weight": 1.8, "value": 40, "level": 5, "armor": 6.0, "stats": {"vitality": 1}, "flavor": "Rings on rings on rings."})
	out.append({"id": "item_chainmail_body", "name": "Chainmail Body", "cat": cm, "folder": "Armor", "kind": "armor", "slot": 3, "tier": "chainmail", "build": "chainmail_body",
			"grid": Vector2i(2, 3), "weight": 9.0, "value": 110, "level": 5, "armor": 17.0, "stats": {"vitality": 2}, "flavor": "Heavy on the shoulders, light on the blade."})
	out.append({"id": "item_chainmail_legs", "name": "Chainmail Legs", "cat": cm, "folder": "Armor", "kind": "armor", "slot": 5, "tier": "chainmail", "build": "chainmail_legs",
			"grid": Vector2i(2, 3), "weight": 6.0, "value": 80, "level": 5, "armor": 10.0, "stats": {"vitality": 1}, "flavor": "Chausses of dark steel rings."})
	out.append({"id": "item_platebody", "name": "Platebody", "cat": "Plate", "folder": "Armor", "kind": "armor", "slot": 3, "tier": "steel", "build": "platebody",
			"grid": Vector2i(2, 3), "weight": 14.0, "value": 240, "level": 10, "armor": 28.0, "stats": {"strength": 1, "vitality": 2}, "flavor": "Plain steel plate. It will do."})
	out.append({"id": "item_plate_helm", "name": "Plate Helm", "cat": "Plate", "folder": "Armor", "kind": "armor", "slot": 1, "tier": "steel", "build": "plate_helm",
			"grid": Vector2i(2, 2), "weight": 4.2, "value": 90, "level": 10, "armor": 10.0, "stats": {"vitality": 1}, "flavor": "A bascinet, dented from a fall."})
	out.append({"id": "item_plate_legs", "name": "Plate Legs", "cat": "Plate", "folder": "Armor", "kind": "armor", "slot": 5, "tier": "steel", "build": "plate_legs",
			"grid": Vector2i(2, 3), "weight": 9.0, "value": 160, "level": 10, "armor": 15.0, "stats": {"vitality": 1}, "flavor": "Plate over mail, from hip to ankle."})
	# the project already has these three leather items: reuse their ids, give them the new model + icon
	out.append({"id": "item_leather_hood", "name": "Leather Hood", "cat": "Leather", "folder": "Armor", "kind": "armor", "slot": 1, "tier": "leather", "build": "leather_hood",
			"grid": Vector2i(2, 2), "weight": 1.5, "value": 10, "level": 1, "armor": 4.0, "stats": {"agility": 1}, "flavor": ""})
	out.append({"id": "item_leather_body", "name": "Leather Body", "cat": "Leather", "folder": "Armor", "kind": "armor", "slot": 3, "tier": "leather", "build": "leather_body",
			"grid": Vector2i(2, 3), "weight": 5.0, "value": 28, "level": 1, "armor": 9.0, "stats": {}, "flavor": ""})
	out.append({"id": "item_leather_breeches", "name": "Leather Legs", "cat": "Leather", "folder": "Armor", "kind": "armor", "slot": 5, "tier": "leather", "build": "leather_legs",
			"grid": Vector2i(2, 2), "weight": 3.0, "value": 10, "level": 1, "armor": 4.0, "stats": {"agility": 1}, "flavor": ""})
	out.append({"id": "item_wizard_robe_top", "name": "Wizard Robe Top", "cat": "Wizard", "folder": "Armor", "kind": "armor", "slot": 3, "tier": "cloth", "build": "wizard_robe_top",
			"grid": Vector2i(2, 3), "weight": 2.0, "value": 30, "level": 1, "armor": 3.0, "stats": {"intellect": 2}, "flavor": "Blue wool, mended twice."})
	out.append({"id": "item_wizard_robe_bottom", "name": "Wizard Robe Bottom", "cat": "Wizard", "folder": "Armor", "kind": "armor", "slot": 5, "tier": "cloth", "build": "wizard_robe_bottom",
			"grid": Vector2i(2, 3), "weight": 1.6, "value": 22, "level": 1, "armor": 2.0, "stats": {"intellect": 1}, "flavor": "Wide in the leg, for walking and for dignity."})
	for c in [["blue", "Wizard Hat", "item_wizard_hat", 18], ["grey", "Grey Wizard Hat", "item_wizard_hat_grey", 18], ["red", "Red Wizard Hat", "item_wizard_hat_red", 18]]:
		out.append({"id": c[2], "name": c[1], "cat": "Wizard", "folder": "Armor", "kind": "armor", "slot": 1, "tier": "cloth", "build": "wizard_hat_" + c[0],
				"grid": Vector2i(2, 2), "weight": 0.6, "value": c[3], "level": 1, "armor": 1.0, "stats": {"intellect": 1}, "flavor": "Pointed, floppy, and quietly smug."})
	return out


static func build(name: String) -> Node3D:
	match name:
		"chainmail_coif": return chainmail_coif()
		"chainmail_body": return chainmail_body()
		"chainmail_legs": return chainmail_legs()
		"platebody": return platebody()
		"plate_helm": return plate_helm()
		"plate_legs": return plate_legs()
		"leather_hood": return leather_hood()
		"leather_body": return leather_body()
		"leather_legs": return leather_legs()
		"wizard_robe_top": return wizard_robe_top()
		"wizard_robe_bottom": return wizard_robe_bottom()
		"wizard_hat_blue": return wizard_hat("blue")
		"wizard_hat_grey": return wizard_hat("grey")
		"wizard_hat_red": return wizard_hat("red")
	return null


# ------------------------------------------------------------------ preview (icons, gallery)

## The armor on a bare skeleton. Add it to the tree, then call pose_preview() (arms lowered by the
## Idle animation) which also stores meta "icon_aabb" = the posed bounds for framing the icon.
static func preview(_e: Dictionary, scene: PackedScene) -> Node3D:
	var holder: Node = (load(RIG_SCENE) as PackedScene).instantiate()
	var sk: Skeleton3D = holder.find_children("*", "Skeleton3D", true, false)[0]
	for c in sk.get_children():
		c.free()
	var inst: Node = scene.instantiate()
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var src := mi as MeshInstance3D
		var n := MeshInstance3D.new()
		n.mesh = src.mesh
		n.skin = src.skin
		sk.add_child(n)
		n.skeleton = NodePath("..")
	inst.free()
	return holder as Node3D


static func pose_preview(holder: Node3D) -> void:
	var sk: Skeleton3D = holder.find_children("*", "Skeleton3D", true, false)[0]
	var ap: AnimationPlayer = holder.find_children("*", "AnimationPlayer", true, false)[0]
	ap.play("Idle")
	ap.seek(0.0, true)
	ap.pause()
	var pose: Array = []
	for bi in sk.get_bone_count():
		pose.append(sk.get_bone_global_pose(bi) * sk.get_bone_global_rest(bi).affine_inverse())
	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := -lo
	for n in sk.get_children():
		var mi := n as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var bs: PackedInt32Array = arr[Mesh.ARRAY_BONES]
			var ws: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
			for v in vs.size():
				var p := Vector3.ZERO
				for k in 4:
					var w := ws[v * 4 + k]
					if w > 0.0:
						p += (pose[bs[v * 4 + k]] as Transform3D) * vs[v] * w
				lo = lo.min(p)
				hi = hi.max(p)
	holder.set_meta("icon_aabb", AABB(lo, hi - lo))
