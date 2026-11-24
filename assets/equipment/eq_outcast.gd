extends RefCounted
## The base Outcast outfit (DESIGN.md 12.1): what every player wears under empty gear slots.
## A code-built stand-in until real hand-painted models exist: linen shirt, wool trousers, wrapped
## boots, belt kit (pouch, satchel strap, faded red cloth), olive hooded cloak, hair (and a beard for
## the broad body, a braid for the slender one).
##
## Built the same way as the armor (eq_armor.gd): skinned meshes in the skeleton's rest (T-pose)
## space, weighted automatically from nearby bones. CharacterModel.set_outfit() wears them and hides
## a piece when armor covers that part of the body.

const A := preload("res://assets/equipment/eq_armor.gd")
const Mesh_ := preload("res://assets/equipment/eq_mesh.gd")
const Kit := preload("res://assets/equipment/eq_kit.gd")

## Which armor slot hides which outfit piece (boots always show).
const HIDDEN_BY := {"shirt": "chest", "belt": "chest", "cloak": "chest", "trousers": "legs", "hair": "head", "beard": "head",
		"torso": "chest", "legs": "legs", "feet": "feet", "boots": "feet", "fill_torso": "chest", "fill_legs": "legs"}

# (y, half width, front z, back z) of the bare slender torso (tools/measure_body.gd on Mannequin_F).
const TORSO_F := [
	[0.86, 0.182, 0.097, -0.092], [0.92, 0.174, 0.1, -0.11], [1.0, 0.172, 0.106, -0.125], [1.05, 0.152, 0.117, -0.117],
	[1.10, 0.134, 0.124, -0.085], [1.15, 0.118, 0.128, -0.07], [1.20, 0.106, 0.143, -0.062], [1.25, 0.112, 0.149, -0.068],
	[1.30, 0.12, 0.153, -0.078], [1.35, 0.135, 0.161, -0.098], [1.40, 0.157, 0.154, -0.108], [1.46, 0.168, 0.11, -0.118],
	[1.52, 0.13, 0.075, -0.108], [1.57, 0.072, 0.08, -0.07],
]

# Head ellipsoid: center and half sizes (x, y, z).
const HEAD_M := [Vector3(0, 1.70, -0.006), Vector3(0.092, 0.135, 0.124)]
const HEAD_F := [Vector3(0, 1.685, 0.018), Vector3(0.09, 0.13, 0.118)]

static var _cache := {}


## The real (image-to-3D) model for each body, fitted by tools/fit_outcast.gd. When one exists it
## is worn as a single "body" piece in place of the mannequin and the code-built clothes below.
const MODEL_DIR := "res://assets/characters/outcast/"
const MODELS := {false: "outcast_male", true: "outcast_female"}


static func has_model(female: bool) -> bool:
	return ResourceLoader.exists(MODEL_DIR + MODELS[female] + ".res")


## [region name, ArrayMesh] for each named surface of a fitted model, each with its own textured
## material.
static func _regions(name_: String) -> Array:
	var src: ArrayMesh = load(MODEL_DIR + name_ + ".res")
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(MODEL_DIR + name_ + "_raw_0.png")
	mat.roughness = 0.9
	var out: Array = []
	for s in src.get_surface_count():
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, src.surface_get_arrays(s))
		var cm := mat
		if src.surface_get_name(s) == "cloak":
			cm = mat.duplicate()
			cm.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.surface_set_material(0, cm)
		var region := src.surface_get_name(s)
		out.append([region if region != "" else "torso", m])
	return out


## piece name -> Array of [ArrayMesh, Skin], built once per body type.
static func parts(female: bool) -> Dictionary:
	if _cache.has(female):
		return _cache[female]
	var skin := A.make_skin()
	var out := {}
	if has_model(female):
		# The fitted model is split into named regions (tools/fit_outcast.gd). With a no-cloak body
		# model, the body comes from that and only the cloak from the cloaked one, so chest armor
		# can take the cloak off; without it, the cloak stays part of the torso.
		var name_: String = MODELS[female]
		var bare: String = name_ + "_nocloak"
		var has_bare := ResourceLoader.exists(MODEL_DIR + bare + ".res")
		for region in _regions(bare if has_bare else name_):
			var piece: String = region[0]
			if has_bare and piece == "cloak":
				continue
			out[piece] = out.get(piece, []) + [[region[1], skin]]
		if has_bare:
			for region in _regions(name_):
				if region[0] == "cloak":
					var cm: ArrayMesh = region[1]
					(cm.surface_get_material(0) as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
					out["cloak"] = [[cm, skin]]
		out["fill_torso"] = [[fill_torso(), skin]]
		out["fill_legs"] = [[fill_legs(), skin]]
		_cache[female] = out
		return out
	out["shirt"] = [shirt(female)]
	out["trousers"] = trousers(female)
	out["boots"] = [boots(female)]
	out["belt"] = [belt_kit(female)]
	out["cloak"] = cloak(female)
	out["hair"] = [hair(female)]
	if not female:
		out["beard"] = [beard()]
	for k in out:
		var list: Array = []
		for m in out[k]:
			list.append([m, skin])
		out[k] = list
	_cache[female] = out
	return out


static func triangle_count(female: bool) -> int:
	var t := 0
	var p := parts(female)
	for k in p:
		for pair in p[k]:
			var mesh: ArrayMesh = pair[0]
			for s in mesh.get_surface_count():
				t += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return t


# ------------------------------------------------------------------ helpers

static func _mesh(bones: Array, power := 4.0):
	var m = Mesh_.new()
	var s: Array = []
	for g in bones:
		s.append_array(A.segs(g))
	m.skin_bones = s
	m.skin_max = 2
	m.skin_power = power
	return m


static func _torso(female: bool) -> Array:
	return TORSO_F if female else A.TORSO


## One body ring at height y, `margin` out from the skin, with soft vertical folds.
static func _body_ring(female: bool, y: float, margin: float, n := 20, folds := 0.0, a0 := 0.0, a1 := TAU, closed := true) -> PackedVector3Array:
	var k := A._lerp_key(_torso(female), y)
	var ring := PackedVector3Array()
	var count := n if closed else n + 1
	for i in count:
		var a := lerpf(a0, a1, float(i) / n)
		var c := cos(a)
		var s := sin(a)
		var p := 2.4
		var fold := 1.0 + folds * sin(a * 7.0 + y * 9.0)
		var x: float = (k[0] + margin) * fold * signf(c) * pow(absf(c), 2.0 / p)
		var z: float = ((k[1] + margin) if s > 0.0 else -(k[2] - margin)) * fold * signf(s) * pow(absf(s), 2.0 / p)
		ring.append(Vector3(x, y, z))
	return ring


## A point on the arm: t 0 = shoulder, 0.5 = elbow, 1 = wrist. side +1 = left (+X).
static func _arm(side: float, t: float) -> Vector3:
	var p: Array = A._arm_path(side)
	return p[0].lerp(p[1], t * 2.0) if t < 0.5 else p[1].lerp(p[2], (t - 0.5) * 2.0)


static func _legp(side: float, t: float) -> Vector3:
	var p: Array = A._leg_path(side)
	return p[0].lerp(p[1], t * 2.0) if t < 0.5 else p[1].lerp(p[2], (t - 0.5) * 2.0)


## A flat strap between two points lying on the body (thin box).
static func _strap(m, mat, a: Vector3, b: Vector3, width: float, thick := 0.01, normal := Vector3.BACK) -> void:
	var d := b - a
	var up := d.normalized()
	var fwd := (normal - up * normal.dot(up)).normalized()
	var right := up.cross(fwd).normalized()
	m.box(mat, (a + b) * 0.5, Vector3(width, d.length(), thick), Basis(right, up, fwd))


## A hanging cloth strip (two-sided) from a top edge down, with a ragged bottom.
static func _strip(m, mat, top_l: Vector3, top_r: Vector3, length: float, out: Vector3, seed_ := 0) -> void:
	var rows := 5
	var prev: Array = [top_l, top_r]
	for r in range(1, rows + 1):
		var t := float(r) / rows
		var sway := out * (0.03 * t * t)
		var bl: Vector3 = top_l + Vector3(0.006 * t, -length * t, 0) + sway
		var br: Vector3 = top_r + Vector3(-0.006 * t, -length * t, 0) + sway
		if r == rows:
			bl.y -= 0.03 * float((seed_ * 7) % 3) * 0.5
			br.y += 0.02 * float((seed_ * 5) % 2)
		var inside: Vector3 = (prev[0] + prev[1] + bl + br) * 0.25 - out * 0.01
		m.quad(mat, prev[0], prev[1], br, bl, inside)
		m.quad(mat, prev[0], bl, br, prev[1], inside + out * 0.02)
		prev = [bl, br]


# ------------------------------------------------------------------ shirt

static func shirt(female: bool) -> ArrayMesh:
	var m = _mesh([A.TORSO_BONES, A.ARM_BONES_L, A.ARM_BONES_R])
	var linen = Kit.get_mat("linen")
	var lace = Kit.get_mat("leather_dark")
	var margin := 0.016 if female else 0.022
	# body: hem hangs a little below the belt and flares; loose folds over the belly
	var y_open := 1.30 if female else 1.38   # the laced front opening starts here
	var rings: Array = []
	var steps := 12
	for i in steps + 1:
		var y := lerpf(0.9, y_open, float(i) / steps)
		var flare := 0.03 * smoothstep(1.02, 0.9, y)
		rings.append(_body_ring(female, y, margin + flare, 22, 0.035 * smoothstep(1.3, 0.95, y)))
	m.loft(linen, rings, true, false, false)
	# open laced neckline: rings that skip a front wedge growing toward the collar
	var top := 1.535 if female else 1.53
	var open: Array = []
	var cents := PackedVector3Array()
	var deep := 0.62 if female else 0.42   # half-angle of the opening at the collar (radians)
	for i in 7:
		var y := lerpf(y_open, top, float(i) / 6)
		var w := deep * pow(float(i) / 6, 0.7)
		open.append(_body_ring(female, y, margin, 22, 0.0, PI * 0.5 + w, PI * 2.5 - w, false))
		cents.append(Vector3(0, y, -0.01))
	m.loft(linen, open, true, false, false, false, cents)
	# laces across the opening
	var kf := A._lerp_key(_torso(female), (y_open + top) * 0.5)
	for j in 3:
		var y := lerpf(y_open + 0.03, top - 0.04, j / 2.0)
		var k := A._lerp_key(_torso(female), y)
		var half: float = (k[0] + margin) * sin(deep * pow((y - y_open) / (top - y_open), 0.7)) * 0.9
		var z: float = k[1] + margin + 0.004
		_strap(m, lace, Vector3(-half, y + 0.012, z), Vector3(half, y - 0.012, z), 0.008, 0.006, Vector3.BACK)
		_strap(m, lace, Vector3(-half, y - 0.012, z), Vector3(half, y + 0.012, z), 0.008, 0.006, Vector3.BACK)
	# loose sleeves rolled up just below the elbow, with a thick rolled cuff
	var rs := 0.088 if female else 0.1
	var re := 0.07 if female else 0.08
	for s in [1.0, -1.0]:
		var pts: Array = []
		var radii: Array = []
		for i in 9:
			var t := lerpf(-0.04, 0.6, float(i) / 8)
			pts.append(_arm(s, maxf(t, 0.0)) + Vector3(-s * 0.03 * maxf(-t, 0.0) * 25.0, 0, 0))
			radii.append(lerpf(rs, re, clampf(t / 0.5, 0.0, 1.0)) * (1.0 + 0.06 * sin(t * 30.0)))
		A.tube(m, linen, pts, radii, 12, true)
		var roll: Array = [_arm(s, 0.58), _arm(s, 0.62), _arm(s, 0.66)]
		A.tube(m, linen, roll, [re + 0.004, re + 0.016, re + 0.002], 12, true, true, true)
	return m.finish()


# ------------------------------------------------------------------ trousers

static func trousers(female: bool) -> Array:
	var m = _mesh([["thigh_l", "calf_l", "foot_l"], ["thigh_r", "calf_r", "foot_r"]], 5.0)
	var wool = Kit.get_mat("wool_brown")
	# waistband follows the hips only, so it never stretches between the legs
	var w = _mesh([["pelvis", "spine_01"]], 4.0)
	var rings: Array = []
	for y in [0.9, 0.97, 1.04]:
		rings.append(_body_ring(female, y, 0.034 if female else 0.036, 20))
	w.loft(wool, rings, true, false, false)
	# each leg is its own tube, starting a little above the hip joint so the tops overlap the band
	var r_hip := 0.118 if female else 0.124
	var r_knee := 0.08 if female else 0.088
	for s in [1.0, -1.0]:
		var pts: Array = []
		var radii: Array = []
		var top := _legp(s, 0.0) + Vector3(s * 0.01, 0.07, 0.0)
		pts.append(top)
		radii.append(r_hip * 1.05)
		for i in 11:
			var t := lerpf(0.0, 0.78, float(i) / 10)
			pts.append(_legp(s, t))
			var r := lerpf(r_hip, r_knee, t * 2.0) if t < 0.5 else lerpf(r_knee, 0.076, (t - 0.5) * 2.0)
			radii.append(r * (1.0 + 0.05 * sin(t * 26.0 + s)))
		A.tube(m, wool, pts, radii, 12, true, false, false, Vector2(1.0, 1.06))
	return [w.finish(), m.finish()]


# ------------------------------------------------------------------ boots

## A foot shell: rings across the foot from heel to toe.
static func _foot(m, mat, sole, side: float, female: bool) -> void:
	var fx := 0.099 * side
	var rings: Array = []
	var zs := [-0.115, -0.08, -0.02, 0.05, 0.12, 0.18, 0.215]
	var hs := [0.11, 0.135, 0.13, 0.1, 0.075, 0.06, 0.045]
	var ws := [0.05, 0.06, 0.062, 0.064, 0.064, 0.058, 0.04]
	var sc := 0.94 if female else 1.0
	for i in zs.size():
		var ring := PackedVector3Array()
		for k in 12:
			var a := TAU * k / 12.0
			var c := cos(a)
			var s := sin(a)
			var x: float = fx + ws[i] * sc * signf(c) * pow(absf(c), 0.7)
			var y: float = 0.03 + (hs[i] * 0.5 + 0.005) * (1.0 + signf(s) * pow(absf(s), 0.7)) * 0.95
			ring.append(Vector3(x, y - 0.005, zs[i] * sc))
		rings.append(ring)
	m.loft(mat, rings, true, true, true)
	m.box(sole, Vector3(fx, 0.016, 0.05 * sc), Vector3(0.115 * sc, 0.03, 0.31 * sc))


static func boots(female: bool) -> ArrayMesh:
	var m = _mesh([["calf_l", "foot_l", "thigh_l"], ["calf_r", "foot_r", "thigh_r"]])
	var leather = Kit.get_mat("leather_boot")
	var sole = Kit.get_mat("leather_dark")
	var wrap = Kit.get_mat("cloth_coarse")
	for s in [1.0, -1.0]:
		_foot(m, leather, sole, s, female)
		# shaft from the ankle up to below the knee, with a folded cuff
		var pts: Array = []
		var radii: Array = []
		for i in 7:
			var t := lerpf(0.97, 0.7, float(i) / 6)
			pts.append(_legp(s, t))
			radii.append(lerpf(0.064, 0.074, float(i) / 6) * (0.95 if female else 1.0))
		A.tube(m, leather, pts, radii, 12, true)
		A.tube(m, leather, [_legp(s, 0.72), _legp(s, 0.68), _legp(s, 0.66)], [0.08, 0.088, 0.084], 12, true, false, true)
		# criss-cross leg wraps over the shaft
		# cloth leg wraps: tilted bands around the shaft, alternating direction
		for j in 5:
			var t := 0.75 + j * 0.042
			var c := _legp(s, t)
			var tilt := 0.02 * (1.0 if j % 2 == 0 else -1.0)
			var r := lerpf(0.074, 0.066, (t - 0.7) / 0.27) + 0.006
			var ring_a := PackedVector3Array()
			var ring_b := PackedVector3Array()
			for k in 12:
				var a := TAU * k / 12.0
				var off := Vector3(cos(a) * r, sin(a) * tilt, sin(a) * r)
				ring_a.append(c + off + Vector3(0, 0.011, 0))
				ring_b.append(c + off + Vector3(0, -0.011, 0))
			m.loft(wrap, [ring_a, ring_b], true, false, false)
	return m.finish()


# ------------------------------------------------------------------ belt kit

static func belt_kit(female: bool) -> ArrayMesh:
	var m = _mesh([["pelvis", "spine_01", "spine_02", "spine_03", "clavicle_l", "clavicle_r"]], 3.0)
	var leather = Kit.get_mat("leather")
	var dark = Kit.get_mat("leather_dark")
	var iron = Kit.get_mat("iron")
	var red = Kit.get_mat("cloth_red")
	var y := 1.0 if female else 0.99
	var mg := 0.05
	# belt band
	var rings: Array = [_body_ring(female, y - 0.03, mg, 22), _body_ring(female, y + 0.03, mg, 22)]
	m.loft(leather, rings, false, false, false)
	var k := A._lerp_key(_torso(female), y)
	var zf: float = k[1] + mg
	m.box(iron, Vector3(0, y, zf + 0.008), Vector3(0.06, 0.055, 0.012))
	m.box(dark, Vector3(0, y, zf + 0.012), Vector3(0.036, 0.032, 0.01))
	# faded red cloth hanging from the belt, a little off-center
	var top := y - 0.03
	_strip(m, red, Vector3(-0.02, top, zf + 0.01), Vector3(0.05, top, zf + 0.012), 0.34, Vector3.BACK, 1)
	_strip(m, red, Vector3(0.035, top, zf + 0.016), Vector3(0.075, top, zf + 0.014), 0.26, Vector3.BACK, 2)
	# pouch on the left front hip
	var hx: float = k[0] + mg
	var pc := Vector3(hx * 0.72, y - 0.085, zf - 0.02)
	m.box(leather, pc, Vector3(0.1, 0.11, 0.05), Basis(Vector3.UP, 0.5))
	m.box(dark, pc + Vector3(0.0, 0.035, 0.01), Vector3(0.104, 0.045, 0.054), Basis(Vector3.UP, 0.5))
	# satchel on the right back hip, on a strap across the chest from the left shoulder
	var sc := Vector3(-hx * 0.95, y - 0.1, -0.04)
	m.box(leather, sc, Vector3(0.06, 0.15, 0.17), Basis(Vector3.UP, -0.3))
	m.box(dark, sc + Vector3(-0.004, 0.045, 0.0), Vector3(0.066, 0.065, 0.174), Basis(Vector3.UP, -0.3))
	var kc := A._lerp_key(_torso(female), 1.3)
	var sh := A.bp("clavicle_l") + Vector3(0.05, 0.07, 0)
	var chest_f := Vector3(0.0, 1.28, kc[1] + 0.03)
	var chest_b := Vector3(0.0, 1.28, kc[2] - 0.03)
	_strap(m, dark, sh + Vector3(0, 0, 0.06), chest_f + Vector3(-0.02, 0, 0), 0.04, 0.01, Vector3.BACK)
	_strap(m, dark, chest_f + Vector3(-0.02, 0, 0), sc + Vector3(0.02, 0.07, 0.06), 0.04, 0.01, Vector3.BACK)
	_strap(m, dark, sh + Vector3(0, 0, -0.06), chest_b, 0.04, 0.01, Vector3.FORWARD)
	_strap(m, dark, chest_b, sc + Vector3(0.02, 0.07, -0.06), 0.04, 0.01, Vector3.FORWARD)
	return m.finish()


# ------------------------------------------------------------------ cloak

## Hood-down collar over the shoulders (follows the shoulders) and a long back panel (follows the
## spine and hips only, so the legs never drag it).
static func cloak(female: bool) -> Array:
	var wool = Kit.get_mat("wool_olive")
	var bronze = Kit.get_mat("bronze")
	var sc := 0.93 if female else 1.0
	# collar / draped hood
	var c = _mesh([A.TORSO_BONES, ["clavicle_l", "upperarm_l"], ["clavicle_r", "upperarm_r"]], 4.0)
	var rings: Array = []
	var ys := [1.575, 1.55, 1.515, 1.48, 1.445]
	var hxs := [0.085, 0.13, 0.18, 0.208, 0.218]
	var zfs := [0.1, 0.125, 0.148, 0.162, 0.172] if not female else [0.105, 0.13, 0.152, 0.168, 0.178]
	var zbs := [0.1, 0.13, 0.16, 0.178, 0.188]
	for i in ys.size():
		var ring := PackedVector3Array()
		for k in 24:
			var a := TAU * k / 24.0
			var co := cos(a)
			var si := sin(a)
			var x: float = hxs[i] * sc * signf(co) * pow(absf(co), 2.0 / 2.2)
			var z: float = (zfs[i] if si > 0.0 else zbs[i]) * sc * signf(si) * pow(absf(si), 2.0 / 2.2)
			var yy: float = ys[i] + 0.012 * i * maxf(si, 0.0) * absf(si)
			if i == ys.size() - 1:
				yy -= 0.025 * absf(sin(a * 5.0)) + (0.03 if si < 0.0 else 0.0)
			ring.append(Vector3(x, yy, z + (0.01 if female and si > 0.0 else 0.0)))
		rings.append(ring)
	c.loft(wool, rings, true, false, false)
	# the hood itself, bunched behind the neck
	c.sphere(wool, Vector3(0, 1.52, -0.17 * sc), 0.085, 10, 6)
	# clasp
	c.lathe(bronze, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.47, 0.125 * sc + 0.012)), [Vector2(0.0, 0.0), Vector2(0.028, 0.0), Vector2(0.028, 0.012), Vector2(0.018, 0.016), Vector2(0.0, 0.016)], 12, false, true)
	# long back panel, open at the front, flaring back toward a torn hem
	var b = _mesh([["pelvis", "spine_01", "spine_02", "spine_03"]], 3.0)
	var panel: Array = []
	var cents := PackedVector3Array()
	var steps := 10
	var hem := 0.42
	for i in steps + 1:
		var t := float(i) / steps
		var y := lerpf(1.42, hem, t)
		var hx := lerpf(0.23, 0.3, t) * sc
		var zb := lerpf(0.19, 0.3, t) * sc
		var ring := PackedVector3Array()
		var n := 16
		for k in n + 1:
			var a := lerpf(PI * 1.06, PI * 1.94, float(k) / n)   # back half, wrapping a bit to the sides
			var co := cos(a)
			var si := sin(a)
			var fold := 1.0 + 0.05 * t * sin(k * 1.9)
			var yy := y
			if i == steps:
				yy += 0.07 * absf(sin(k * 2.7)) + 0.03 * absf(sin(k * 5.3))
			ring.append(Vector3(hx * co * fold, yy, -zb * absf(si) * fold - 0.02 * t))
		panel.append(ring)
		cents.append(Vector3(0, y, 0.0))
	b.loft(wool, panel, true, false, false, false, cents)
	return [c.finish(), b.finish()]


# ------------------------------------------------------------------ hair and beard

static func _head(female: bool) -> Array:
	return HEAD_F if female else HEAD_M


## A shell ring over the head ellipsoid at height y (front +Z). Skips a front wedge of
## half-angle `face` (radians) so the face shows.
static func _head_ring(female: bool, y: float, margin: float, face: float, n: int, mess := 0.0) -> PackedVector3Array:
	var h: Array = _head(female)
	var c: Vector3 = h[0]
	var r: Vector3 = h[1]
	var t := clampf((y - c.y) / r.y, -1.0, 1.0)
	var sc := sqrt(maxf(1.0 - t * t, 0.0))
	var ring := PackedVector3Array()
	for i in n + 1:
		var a := lerpf(PI * 0.5 + face, PI * 2.5 - face, float(i) / n)
		var j := 1.0 + mess * (0.5 + 0.5 * sin(a * 9.0 + y * 40.0))
		ring.append(Vector3(c.x + cos(a) * (r.x * sc + margin) * j, y, c.z + sin(a) * (r.z * sc + margin) * j))
	return ring


static func hair(female: bool) -> ArrayMesh:
	var m = _mesh([A.HEAD_BONES], 4.0)
	var mat = Kit.get_mat("hair_auburn" if female else "hair_brown")
	var h: Array = _head(female)
	var c: Vector3 = h[0]
	var r: Vector3 = h[1]
	var top := c.y + r.y + 0.012
	var rings: Array = []
	var cents := PackedVector3Array()
	var ys: Array = []
	var steps := 9
	var bottom := c.y - r.y * (0.62 if female else 0.55)
	for i in steps + 1:
		ys.append(lerpf(top - 0.004, bottom, pow(float(i) / steps, 1.2)))
	for y in ys:
		var hairline := c.y + r.y * 0.5   # above this the hair covers the forehead too
		var face := 0.0 if y > hairline else lerpf(0.75, 1.25, clampf((hairline - y) / (r.y * 0.6), 0.0, 1.0))
		rings.append(_head_ring(female, y, 0.016, face, 22, 0.12 if not female else 0.05))
		cents.append(Vector3(c.x, y, c.z))
	# close the crown with a small cap
	m.loft(mat, rings, true, true, false, false, cents)
	if female:
		# loose locks framing the face, and a long braid down the back
		for s in [1.0, -1.0]:
			var p0 := c + Vector3(s * (r.x + 0.005), r.y * 0.25, r.z * 0.45)
			A.tube(m, mat, [p0, p0 + Vector3(s * 0.01, -0.09, 0.0), p0 + Vector3(s * 0.016, -0.17, -0.01)], [0.011, 0.01, 0.004], 6, true, true, true)
		var start := c + Vector3(0, -r.y * 0.3, -r.z - 0.01)
		for i in 9:
			var p := start + Vector3(0.012 * (1 if i % 2 == 0 else -1), -0.045 * i, -0.012 - 0.004 * i)
			m.sphere(mat, p, 0.028 - i * 0.0018, 7, 5)
		A.tube(m, Kit.get_mat("leather_dark"), [start + Vector3(0, -0.42, -0.05), start + Vector3(0, -0.44, -0.05)], [0.016, 0.016], 8, true, true, true)
	else:
		# messy tufts at the nape
		for i in 6:
			var a := lerpf(PI * 1.15, PI * 1.85, i / 5.0)
			var base := c + Vector3(cos(a) * r.x * 0.95, -r.y * 0.25, sin(a) * r.z * 0.98)
			m.cone(mat, base, base + Vector3(cos(a) * 0.015, -0.07, sin(a) * 0.02), 0.024, 5)
	return m.finish()


static func beard() -> ArrayMesh:
	var m = _mesh([A.HEAD_BONES], 4.0)
	var mat = Kit.get_mat("hair_brown")
	var c: Vector3 = HEAD_M[0]
	var r: Vector3 = HEAD_M[1]
	# short beard: the lower front of the face, from the cheeks down under the chin
	var rings: Array = []
	var cents := PackedVector3Array()
	for i in 6:
		var y := lerpf(c.y - r.y * 0.3, c.y - r.y * 0.85, float(i) / 5)
		var t := clampf((y - c.y) / r.y, -1.0, 1.0)
		var sc := sqrt(maxf(1.0 - t * t, 0.0))
		var ring := PackedVector3Array()
		for k in 13:
			var a := lerpf(PI * 0.08, PI * 0.92, k / 12.0)
			var grow := 0.014 + 0.012 * float(i) / 5
			ring.append(Vector3(c.x + cos(a) * (r.x * sc + grow), y, c.z + sin(a) * (r.z * sc + grow)))
		rings.append(ring)
		cents.append(Vector3(c.x, y, c.z))
	m.loft(mat, rings, true, false, true, false, cents)
	# moustache
	var mz := c.z + r.z * 0.97
	A.tube(m, mat, [Vector3(-0.03, c.y - r.y * 0.2, mz - 0.012), Vector3(0, c.y - r.y * 0.17, mz + 0.004), Vector3(0.03, c.y - r.y * 0.2, mz - 0.012)], [0.008, 0.011, 0.008], 6, true, true, true)
	return m.finish()


## Plain stand-ins for the parts of the body the cloak used to cover (the model has no back to its trousers or
## shirt): shown whenever the cloak is hidden and no armor covers that part, so nothing is see-through.
static func fill_torso() -> ArrayMesh:
	A.use_profile("outcast")
	var m = A._new_mesh([A.TORSO_BONES, A.ARM_BONES_L, A.ARM_BONES_R])
	A._hold_hem(m)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.66, 0.62, 0.54)
	mat.roughness = 0.95
	A.torso_tube(m, mat, 0.9, 1.5, -0.012, 8, 18, 2.4)
	return m.finish()


static func fill_legs() -> ArrayMesh:
	A.use_profile("outcast")
	var m = A._new_mesh([A.LEG_BONES_L, A.LEG_BONES_R])
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.17, 0.17, 0.2)
	mat.roughness = 0.95
	var lr := A._lr([0.0, 0.0, 0.0])
	A._hip_band(m, mat, 0.0, [0.86, 0.95, 1.02])
	for s in [1.0, -1.0]:
		A.leg(m, mat, s, 0.0, 0.96, lr[0], lr[1], lr[2], 10, false, 0.0, -0.01)
	return m.finish()
