extends RefCounted
## The White Knight, built from the owner's character sheet (docs/white_knight/). Nothing here
## comes from the game's other armour: the shapes follow the sheet's FRONT / BACK / SIDE views
## (measured: 1.92 m to the helm's top, belt at the waist, hem 45 cm off the ground), and the
## textures are the sheet itself (tools/white_knight_textures.py):
##  - the tabard, hood and cowl are coloured by projecting the sheet's four views onto them,
##    in the pose the sheet was drawn in (arms down, feet apart), each triangle taking the view
##    that faces it best and can see it (so an arm in front of the cloth never paints onto it);
##    The pauldrons, vambraces, gauntlets, knee cops, belts and boots take their colour the same
##    way, so their brass edges, rivets, buckles and worn leather are the sheet's own;
##  - the great helm takes the three HELMET close-ups;
##  - the mail uses a seamless tile cut from the CHAINMAIL panel.
##
## One skinned mesh on the mannequin's skeleton (UAL1), so every animation in the game works.
## Rest pose (T-pose): +Y up, the body faces +Z, +X is the character's left. The mannequin's own
## body is hidden under it (white_knight_model.gd). Baked by tools/build_white_knight.gd.

const WMesh := preload("res://assets/characters/white_knight/wk_mesh.gd")
const Atlas := preload("res://assets/characters/white_knight/wk_atlas.gd")

const RIG_SCENE := "res://assets/characters/mannequin/UAL1_Standard.glb"
const DIR := "res://assets/characters/white_knight/"
const TEX := DIR + "textures/"
const MAT_DIR := DIR + "materials/"
const NAME := "WK_white_knight"

## The pose the sheet was drawn in: arms hanging this far down from the T-pose, legs apart.
const ARM_DOWN := 76.0
const LEG_OUT := 6.3

# ------------------------------------------------------------------ materials

## name: [albedo, normal map, colour, metallic, roughness, vertex colours, double sided, alpha cut]
const MATS := {
	"wk_cloth": ["wk_views.webp", "", Color(1, 1, 1), 0.0, 0.92, false, true, true],
	"wk_helm": ["wk_views.webp", "", Color(1, 1, 1), 0.45, 0.5, false, true, false],
	"wk_metal": ["wk_views.webp", "", Color(1, 1, 1), 0.4, 0.5, false, true, false],
	"wk_leather": ["wk_views.webp", "", Color(1, 1, 1), 0.0, 0.8, false, true, false],
	"wk_mail": ["wk_chainmail.png", "wk_chainmail_n.png", Color(1, 1, 1), 0.5, 0.55, false, true, false],
}
## Materials coloured by projecting the sheet's views (cloth, armour, leather); the rest tile.
const PROJECTED := ["wk_cloth", "wk_metal", "wk_leather"]
## Size in metres one tile covers (box-mapped materials).
const TILE := {"wk_mail": 0.11}

static var _mats := {}


static func mat(n: String) -> StandardMaterial3D:
	if _mats.has(n):
		return _mats[n]
	var path := MAT_DIR + n + ".tres"
	var m: StandardMaterial3D = load(path) if ResourceLoader.exists(path) else make_mat(n)
	_mats[n] = m
	return m


static func make_mat(n: String) -> StandardMaterial3D:
	var d: Array = MATS[n]
	var m := StandardMaterial3D.new()
	m.resource_name = n
	m.albedo_color = d[2]
	if d[0] != "":
		m.albedo_texture = load(TEX + d[0])
	if d[1] != "":
		m.normal_enabled = true
		m.normal_texture = load(TEX + d[1])
		m.normal_scale = 0.7
	m.metallic = d[3]
	m.roughness = d[4]
	m.metallic_specular = 0.35 if n == "wk_cloth" else 0.5
	m.vertex_color_use_as_albedo = d[5]
	if d[6]:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED   # open hems, shells and cuffs show their inside
	if d[7]:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


# ------------------------------------------------------------------ the skeleton

static var _rig := {}


## {bone name: {"i": index, "p": rest position}} from the mannequin skeleton.
static func rig() -> Dictionary:
	if not _rig.is_empty():
		return _rig
	var scene: Node = (load(RIG_SCENE) as PackedScene).instantiate()
	var sk: Skeleton3D = scene.find_children("*", "Skeleton3D", true, false)[0]
	for i in sk.get_bone_count():
		var g := sk.get_bone_global_rest(i)
		_rig[sk.get_bone_name(i)] = {"i": i, "p": g.origin, "g": g}
	scene.free()
	return _rig


static func bi(n: String) -> int:
	return rig()[n].i


static func bp(n: String) -> Vector3:
	return rig()[n].p


static func sd(n: String, s: float) -> String:
	return n + ("_l" if s > 0.0 else "_r")


static func seg(a: String, b: String) -> Array:
	return [bi(a), bp(a), bp(b)]


static func make_skin() -> Skin:
	var skin := Skin.new()
	var names: Array = rig().keys()
	names.sort_custom(func(a, b): return rig()[a].i < rig()[b].i)
	for n in names:
		skin.add_named_bind(n, (rig()[n].g as Transform3D).affine_inverse())
	return skin


## The sheet's pose, bone index -> skeleton-space transform: arms down, legs a little apart.
static func sheet_pose() -> Dictionary:
	var out := {}
	for s in [1.0, -1.0]:
		var suffix := "_l" if s > 0.0 else "_r"
		var sh := bp(sd("upperarm", s))
		var ra := Basis(Vector3(0, 0, 1), deg_to_rad(-ARM_DOWN * s))
		var ta := Transform3D(ra, sh - ra * sh)
		var hip := bp(sd("thigh", s))
		var rl := Basis(Vector3(0, 0, 1), deg_to_rad(LEG_OUT * s))
		var tl := Transform3D(rl, hip - rl * hip)
		for n: String in rig().keys():
			if not n.ends_with(suffix):
				continue
			for arm in ["upperarm", "lowerarm", "hand", "index", "middle", "ring", "pinky", "thumb"]:
				if n.begins_with(arm):
					out[bi(n)] = ta
			for leg in ["thigh", "calf", "foot", "ball"]:
				if n.begins_with(leg):
					out[bi(n)] = tl
	return out


# ------------------------------------------------------------------ body measurements

## The mannequin's bare torso, measured (tools/measure_body.gd): [y, half width, front z, back z].
const BODY := [
	[0.86, 0.165, 0.10, -0.115], [0.95, 0.172, 0.108, -0.122], [1.05, 0.152, 0.122, -0.118], [1.15, 0.132, 0.126, -0.104],
	[1.22, 0.136, 0.112, -0.1], [1.30, 0.165, 0.13, -0.14], [1.38, 0.182, 0.138, -0.162], [1.46, 0.19, 0.118, -0.158],
	[1.52, 0.13, 0.09, -0.135], [1.57, 0.075, 0.075, -0.095],
]


static func _key(keys: Array, y: float) -> Array:
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


## A superellipse point (x, z) at angle a (0 = +X, PI/2 = front); zf and zb positive.
static func _se(a: float, hx: float, zf: float, zb: float, p: float) -> Vector2:
	var c := cos(a)
	var s := sin(a)
	return Vector2(hx * signf(c) * pow(absf(c), 2.0 / p), (zf if s > 0.0 else zb) * signf(s) * pow(absf(s), 2.0 / p))


static func _ring_at(y: float, d: Array, n: int, p := 2.4, from_i := 0, to_i := -1) -> PackedVector3Array:
	var ring := PackedVector3Array()
	for i in range(from_i, n if to_i < 0 else to_i):
		var q := _se(TAU * (i % n) / n, d[0], d[1], d[2], p)
		ring.append(Vector3(q.x, y, q.y))
	return ring


static func _body(y: float, mg: float) -> Array:
	var k := _key(BODY, y)
	return [k[0] + mg, k[1] + mg, -k[2] + mg]


## A point along an arm (t: 0 shoulder, 0.5 elbow, 1 wrist) or a leg (0 hip, 0.5 knee, 1 ankle).
static func _limb(names: Array, s: float, t: float) -> Vector3:
	var a := bp(sd(names[0], s))
	var b := bp(sd(names[1], s))
	var c := bp(sd(names[2], s))
	return a.lerp(b, t * 2.0) if t < 0.5 else b.lerp(c, (t - 0.5) * 2.0)


const ARM := ["upperarm", "lowerarm", "hand"]
const LEG := ["thigh", "calf", "foot"]


## A tube along a limb from t0 to t1, radius r(t).
static func _limb_tube(m, mat_: Material, names: Array, s: float, t0: float, t1: float, r: Callable, sides := 12, steps := 8, squash := Vector2.ONE) -> void:
	var pts: Array = []
	var radii: Array = []
	for i in steps + 1:
		var t := lerpf(t0, t1, float(i) / steps)
		pts.append(_limb(names, s, t))
		radii.append(r.call(t))
	m.tube(mat_, pts, radii, sides, true, false, false, squash)


# ------------------------------------------------------------------ texturing

const VIEW_DIRS := {"front": Vector3(0, 0, 1), "back": Vector3(0, 0, -1), "side_r": Vector3(-1, 0, 0), "side_l": Vector3(1, 0, 0)}


## (across, depth toward the viewer) of a point in a view.
static func _hv(view: String, p: Vector3) -> Vector2:
	match view:
		"front": return Vector2(p.x, p.z)
		"back": return Vector2(-p.x, -p.z)
		"side_r": return Vector2(p.z, -p.x)
	return Vector2(-p.z, p.x)


## Where a (posed) point falls on one of the sheet's views in the atlas (UV).
static func view_uv(view: String, p: Vector3) -> Vector2:
	var v: Dictionary = Atlas.VIEWS[view]
	var a := _hv(view, p).x
	return Vector2((v.ox + v.cx + a * v.ppm) / Atlas.SIZE.x, (v.oy + v.sole - p.y * v.ppm) / Atlas.SIZE.y)


const DRES := 0.008
const DA0 := -0.7
const DW := 175
const DH := 252


## For every view, the nearest surface's depth on a grid (the posed outfit, all of it), so a
## triangle hidden behind an arm or a pauldron in one view can take its colour from another.
static func _depth_maps(m) -> Dictionary:
	var maps := {}
	for view in VIEW_DIRS:
		var buf := PackedFloat32Array()
		buf.resize(DW * DH)
		buf.fill(-1e9)
		for mat_ in m.materials():
			var pv: PackedVector3Array = m.posed_verts(mat_)
			for i in range(0, pv.size(), 3):
				var p0 := _hv(view, pv[i])
				var p1 := _hv(view, pv[i + 1])
				var p2 := _hv(view, pv[i + 2])
				var x0 := (p0.x - DA0) / DRES
				var x1 := (p1.x - DA0) / DRES
				var x2 := (p2.x - DA0) / DRES
				var y0: float = pv[i].y / DRES
				var y1: float = pv[i + 1].y / DRES
				var y2: float = pv[i + 2].y / DRES
				var den := (y1 - y2) * (x0 - x2) + (x2 - x1) * (y0 - y2)
				if absf(den) < 1e-9:
					continue
				var cx0 := clampi(floori(minf(x0, minf(x1, x2))), 0, DW - 1)
				var cx1 := clampi(ceili(maxf(x0, maxf(x1, x2))), 0, DW - 1)
				var cy0 := clampi(floori(minf(y0, minf(y1, y2))), 0, DH - 1)
				var cy1 := clampi(ceili(maxf(y0, maxf(y1, y2))), 0, DH - 1)
				for cy in range(cy0, cy1 + 1):
					var py := cy + 0.5
					for cx in range(cx0, cx1 + 1):
						var px := cx + 0.5
						var w0 := ((y1 - y2) * (px - x2) + (x2 - x1) * (py - y2)) / den
						var w1 := ((y2 - y0) * (px - x2) + (x0 - x2) * (py - y2)) / den
						var w2 := 1.0 - w0 - w1
						if w0 < -0.02 or w1 < -0.02 or w2 < -0.02:
							continue
						var d := p0.y * w0 + p1.y * w1 + p2.y * w2
						var idx := cy * DW + cx
						if d > buf[idx]:
							buf[idx] = d
		maps[view] = buf
	return maps


static func _seen(maps: Dictionary, view: String, p: Vector3) -> bool:
	var hv := _hv(view, p)
	var cx := clampi(floori((hv.x - DA0) / DRES), 0, DW - 1)
	var cy := clampi(floori(p.y / DRES), 0, DH - 1)
	var best := -1e9
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var x := clampi(cx + dx, 0, DW - 1)
			var y := clampi(cy + dy, 0, DH - 1)
			best = maxf(best, (maps[view] as PackedFloat32Array)[y * DW + x])
	return hv.y >= best - 0.03


## UVs of a projected triangle: the best-facing view that can see it (posed space).
static func _proj_uv(maps: Dictionary, posed: Array, np_: Vector3) -> Array:
	var order: Array = []
	for view in VIEW_DIRS:
		order.append([np_.dot(VIEW_DIRS[view]), view])
	order.sort_custom(func(x, y): return x[0] > y[0])
	var pick: String = order[0][1]
	var cen: Vector3 = (posed[0] + posed[1] + posed[2]) / 3.0
	for o in order:
		if o[0] < 0.1:
			break
		if _seen(maps, o[1], cen):
			pick = o[1]
			break
	return [view_uv(pick, posed[0]), view_uv(pick, posed[1]), view_uv(pick, posed[2])]


## Box-mapped UVs from the rest position (seamless tiles; they stay put when the mesh moves).
static func _box_uv(rest: Array, nr: Vector3, tile: float) -> Array:
	var out: Array = []
	var ax := absf(nr.x)
	var ay := absf(nr.y)
	var az := absf(nr.z)
	for p: Vector3 in rest:
		if ax >= ay and ax >= az:
			out.append(Vector2(p.z, -p.y) / tile)
		elif ay >= az:
			out.append(Vector2(p.x, p.z) / tile)
		else:
			out.append(Vector2(p.x, -p.y) / tile)
	return out


# ------------------------------------------------------------------ cloth shapes

## The tabard over the chest: the mannequin plus mail plus cloth, blousing above the belt.
static func _tab_mg(y: float) -> float:
	return 0.042 + 0.012 * smoothstep(1.21, 1.3, y) - 0.01 * smoothstep(1.42, 1.53, y)


## The skirt below the belt (rest pose), fitted to the sheet: [y, half width, front, back].
const SKIRT := [[0.42, 0.25, 0.215, 0.19], [0.6, 0.24, 0.205, 0.186], [0.7, 0.234, 0.198, 0.184], [0.8, 0.228, 0.19, 0.182],
		[0.9, 0.222, 0.18, 0.18], [1.0, 0.212, 0.17, 0.175], [1.1, 0.195, 0.165, 0.16], [1.2, 0.177, 0.158, 0.143]]


## The cloth's [half width, front, back] at height y: the tabard above the belt, the skirt below.
static func _cloth(y: float) -> Array:
	if y >= 1.2:
		return _body(y, _tab_mg(y))
	return _key(SKIRT, y)


## Weights for cloth below the belt: the spine and pelvis at the belt, sliding onto one thigh
## (side +1 left, -1 right) toward the hem, or both for a centre panel (side 0).
static func _skirt_w(p: Vector3, side: float) -> Array:
	var t := smoothstep(1.02, 0.72, p.y)
	var th := 0.85 * t
	var sp := 0.55 * smoothstep(1.05, 1.2, p.y)
	var pairs: Array = [[bi("pelvis"), (1.0 - th) * (1.0 - sp)], [bi("spine_01"), (1.0 - th) * sp]]
	if side > 0.0:
		pairs.append([bi("thigh_l"), th])
	elif side < 0.0:
		pairs.append([bi("thigh_r"), th])
	else:
		pairs.append([bi("thigh_l"), th * 0.5])
		pairs.append([bi("thigh_r"), th * 0.5])
	return WMesh.pack(pairs)


## One panel of a skirt between angles that may widen toward the hem (radians, 0 = +X,
## PI/2 = front); dims(y) -> [half width, front, back]; grow = metres added all round.
static func _skirt(m, mat_: Material, side: float, y_top: float, hem: Callable, a_top: Array, a_hem: Array, dims: Callable,
		grow: float, ripple: float, rows: int, cols: int) -> void:
	m.set_skin_fn(func(q: Vector3) -> Array: return _skirt_w(q, side))
	var rings: Array = []
	for r in rows + 1:
		var t := float(r) / rows
		var ring := PackedVector3Array()
		for k in cols + 1:
			var a := lerpf(lerpf(a_top[0], a_hem[0], t), lerpf(a_top[1], a_hem[1], t), float(k) / cols)
			var y := lerpf(y_top, hem.call(a, k), t)
			var d: Array = dims.call(y)
			var rp := ripple * t * (sin(a * 9.0 + side * 1.3) * 0.7 + sin(a * 17.0 + 0.5) * 0.3) + grow
			var q := _se(a, d[0] + rp, d[1] + rp, d[2] + rp, 2.4)
			ring.append(Vector3(q.x, y, q.y))
		rings.append(ring)
	m.loft(mat_, rings, true, false, false, false)


# ------------------------------------------------------------------ the parts

## Mail shirt: body, long sleeves, a skirt split front and back to mid-thigh.
static func hauberk(m) -> void:
	var mail := mat("wk_mail")
	var segs: Array = [seg("pelvis", "spine_01"), seg("spine_01", "spine_02"), seg("spine_02", "spine_03"), seg("spine_03", "neck_01")]
	for s in [1.0, -1.0]:
		segs.append(seg(sd("clavicle", s), sd("upperarm", s)))
		segs.append(seg(sd("upperarm", s), sd("lowerarm", s)))
		segs.append(seg(sd("lowerarm", s), sd("hand", s)))
	m.set_bones(segs, 4.0, 2)
	var rings: Array = []
	for i in 12:
		var y := lerpf(0.98, 1.53, i / 11.0)
		rings.append(_ring_at(y, _body(y, 0.02), 22))
	m.loft(mail, rings, true, false, false)
	for s in [1.0, -1.0]:
		_limb_tube(m, mail, ARM, s, 0.0, 0.95, func(t: float) -> float: return lerpf(0.08, 0.064, t * 2.0) if t < 0.5 else lerpf(0.064, 0.055, (t - 0.5) * 2.0), 12, 10)
	var hem := func(a: float, _k: int) -> float: return 0.6 + 0.01 * sin(a * 5.0)
	var dims := func(y: float) -> Array:
		var d := _body(maxf(y, 0.86), 0.03)
		var f := 0.03 * clampf((1.0 - y) / 0.4, 0.0, 1.0)
		return [d[0] + f, d[1] + f, d[2] + f]
	for side in [1.0, -1.0]:
		var c := 0.0 if side > 0.0 else PI
		_skirt(m, mail, side, 1.0, hem, [c - PI / 2 + 0.02, c + PI / 2 - 0.02], [c - PI / 2 + 0.07, c + PI / 2 - 0.07], dims, 0.0, 0.0, 5, 16)


## Mail leggings from the hips into the boots, with steel knee cops.
static func chausses(m) -> void:
	var mail := mat("wk_mail")
	var segs: Array = [seg("pelvis", "spine_01")]
	for s in [1.0, -1.0]:
		segs.append(seg(sd("thigh", s), sd("calf", s)))
		segs.append(seg(sd("calf", s), sd("foot", s)))
	m.set_bones(segs, 4.0, 2)
	var rings: Array = []
	for y in [0.85, 0.92, 1.0]:
		rings.append(_ring_at(y, _body(y, 0.02), 20))
	m.loft(mail, rings, true, false, false)
	for s in [1.0, -1.0]:
		_limb_tube(m, mail, LEG, s, 0.0, 0.64, func(t: float) -> float: return lerpf(0.1, 0.072, t * 2.0) if t < 0.5 else lerpf(0.072, 0.064, (t - 0.5) * 2.0), 12, 8)
	var metal := mat("wk_metal")
	for s in [1.0, -1.0]:
		m.set_bones([seg(sd("thigh", s), sd("calf", s)), seg(sd("calf", s), sd("foot", s))], 2.0, 2)
		var k := bp(sd("calf", s)) + Vector3(0, 0.012, 0.04)
		m.lathe(metal, Transform3D(Basis(Vector3.RIGHT, PI / 2), k), [[0.074, -0.004], [0.07, 0.016], [0.052, 0.034], [0.027, 0.045], [0.0, 0.048]], 14, true, false)
		m.lathe(metal, Transform3D(Basis(Vector3.FORWARD, PI / 2 * s), k + Vector3(0.055 * s, 0, -0.02)), [[0.045, 0.0], [0.04, 0.01], [0.0, 0.016]], 10, true, false)


## Mail coif: the neck, and a short cape under the hood; its top runs up inside the helm.
static func coif(m) -> void:
	var mail := mat("wk_mail")
	m.set_bones([seg("spine_03", "neck_01"), seg("neck_01", "Head"), [bi("Head"), bp("Head"), Vector3(0, 1.84, 0)]], 4.0, 2)
	var levels := [[1.47, 0.2, 0.15, 0.185], [1.51, 0.15, 0.12, 0.15], [1.56, 0.088, 0.09, 0.1], [1.62, 0.078, 0.088, 0.092], [1.7, 0.08, 0.092, 0.096], [1.76, 0.07, 0.085, 0.09]]
	var rings: Array = []
	for lv in levels:
		rings.append(_ring_at(lv[0], [lv[1], lv[2], lv[3]], 18, 2.2))
	m.loft(mail, rings, true, false, true)


# ---- the great helm

const HELM_P := 2.3
const HELM_TOP := 1.905
const HELM_FRONT := 0.136


static func _helm_dims(y: float) -> Array:
	var t := clampf((y - 1.62) / (HELM_TOP - 1.62), 0.0, 1.0)
	return [lerpf(0.104, 0.098, t), lerpf(0.124, 0.118, t), lerpf(0.118, 0.112, t)]


static func helm_point(a: float, y: float, out := 0.0) -> Vector3:
	var d := _helm_dims(y)
	var q := _se(a, d[0] + out, d[1] + out, d[2] + out, HELM_P)
	var z := q.y
	if sin(a) > 0.0:
		z += 0.012 * pow(maxf(0.0, 1.0 - absf(q.x) / 0.085), 2.0)   # a ridge down the face
	return Vector3(q.x, y, z)


## The lower edge: level at the sides and back, dropping to a point under the face.
static func _helm_bottom(a: float) -> float:
	return 1.675 - 0.05 * pow(maxf(0.0, sin(a)), 1.5)


## Sheet pixel of a helm point on one of the HELMET close-ups, then the atlas UV.
static func _helm_uv(panel: String, p: Vector3) -> Vector2:
	var xs: float
	var ys: float
	match panel:
		"helm_front":
			xs = 115.5 + p.x * 650.0
			ys = 547.0 + (HELM_TOP - p.y) * 650.0
		"helm_back":
			xs = 604.5 - p.x * 525.0
			ys = 555.0 + (HELM_TOP - p.y) * 525.0
		"helm_top":
			panel = "helm_back"   # plain steel from the back plate
			xs = 590.0 + p.x * 200.0
			ys = 595.0 + p.z * 120.0
		_:
			xs = 395.0 + (HELM_FRONT - p.z) * 465.0
			ys = 550.0 + (HELM_TOP - p.y) * 522.0
	var v: Dictionary = Atlas.VIEWS[panel]
	return Vector2((v.ox + Atlas.K * (xs - v.x0)) / Atlas.SIZE.x, (v.oy + Atlas.K * (ys - v.y0)) / Atlas.SIZE.y)


static func helm(m) -> void:
	var hm := mat("wk_helm")
	m.set_bones([[bi("Head"), bp("Head"), Vector3(0, 1.84, 0)]], 4.0, 1)
	var n := 40
	var rings: Array = []
	for lv in [-1.0, 1.7, 1.725, 1.75, 1.78, 1.81, 1.84, 1.87, HELM_TOP]:
		var ring := PackedVector3Array()
		for i in n:
			var a := TAU * i / n
			ring.append(helm_point(a, _helm_bottom(a) if lv < 0.0 else lv))
		rings.append(ring)
	# the face plate is taller than the sides: rings between the lower edge and 1.70
	var lower: Array = []
	for f in [0.0, 0.33, 0.66]:
		var ring := PackedVector3Array()
		for i in n:
			var a := TAU * i / n
			ring.append(helm_point(a, lerpf(_helm_bottom(a), 1.7, f)))
		lower.append(ring)
	m.loft(hm, lower + rings.slice(1), true, false, false)
	# the flat top, a low dome, kept as its own patch so the rim stays a crisp edge
	var top: Array = [rings[rings.size() - 1]]
	var cen := Vector3(0, HELM_TOP, 0.0)
	for lv in [[0.94, 0.004], [0.7, 0.009], [0.35, 0.012]]:
		var ring := PackedVector3Array()
		for pt in rings[rings.size() - 1]:
			var q: Vector3 = cen + (pt - cen) * lv[0]
			ring.append(Vector3(q.x, HELM_TOP + lv[1], q.z))
		top.append(ring)
	m.loft(hm, top, true, false, true)
	# a rolled lower edge, so the shell has some thickness
	var lip: Array = []
	for prof in [[0.0, 0.0], [-0.007, 0.0], [-0.007, 0.022]]:
		var ring := PackedVector3Array()
		for i in n:
			var a := TAU * i / n
			ring.append(helm_point(a, _helm_bottom(a) + prof[1], prof[0]))
		lip.append(ring)
	m.loft(hm, lip, false, false, false)


static func _helm_tri_uv(rest: Array, nr: Vector3) -> Array:
	var panel := "helm_side"
	if nr.y > 0.72:
		panel = "helm_top"
	elif nr.z > 0.45:
		panel = "helm_front"
	elif nr.z < -0.5:
		panel = "helm_back"
	return [_helm_uv(panel, rest[0]), _helm_uv(panel, rest[1]), _helm_uv(panel, rest[2])]


# ---- the tabard, hood and cowl

## The ragged hem (the painted edge cuts it finer; see the atlas alpha).
static func _tab_hem(a: float, k: int) -> float:
	return 0.425 + 0.01 * sin(a * 3.0 + 0.7) + (0.01 if k % 2 == 1 else 0.0)


static func tabard(m) -> void:
	var cloth := mat("wk_cloth")
	m.set_bones([seg("spine_01", "spine_02"), seg("spine_02", "spine_03"), seg("spine_03", "neck_01"), seg("clavicle_l", "upperarm_l"), seg("clavicle_r", "upperarm_r")], 4.0, 2)
	var n := 32
	var low: Array = []
	for y in [1.2, 1.235, 1.27]:
		low.append(_ring_at(y, _cloth(y), n))
	m.loft(cloth, low, true, false, false)
	# above the armpits: a front and a back panel, armholes at the sides
	var front: Array = []
	var back: Array = []
	for y in [1.27, 1.32, 1.37, 1.42, 1.47, 1.53]:
		front.append(_ring_at(y, _cloth(y), n, 2.4, 3, 14))
		back.append(_ring_at(y, _cloth(y), n, 2.4, 19, 30))
	m.loft(cloth, front, true, false, false, false)
	m.loft(cloth, back, true, false, false, false)
	# the skirt: two halves split front and back (each follows its thigh), and the
	# underlayer that shows in the splits
	var hem := func(a: float, k: int) -> float: return _tab_hem(a, k)
	var dims := func(y: float) -> Array: return _cloth(y)
	for side in [1.0, -1.0]:
		var c := 0.0 if side > 0.0 else PI
		_skirt(m, cloth, side, 1.2, hem, [c - PI / 2 + 0.015, c + PI / 2 - 0.015], [c - PI / 2 + 0.11, c + PI / 2 - 0.11], dims, 0.0, 0.01, 14, 30)
	var under := func(_a: float, _k: int) -> float: return 0.44
	for c in [PI / 2, -PI / 2]:
		_skirt(m, cloth, 0.0, 1.18, under, [c - 0.3, c + 0.3], [c - 0.32, c + 0.32], dims, -0.012, 0.0, 12, 6)
	# hood round the shoulders: a capelet under the pauldrons, a bunched roll at the neck,
	# and the hood itself hanging down the back
	m.set_bones([seg("spine_03", "neck_01"), seg("neck_01", "Head"), seg("clavicle_l", "upperarm_l"), seg("clavicle_r", "upperarm_r")], 3.0, 2)
	var cape: Array = []
	for lv in [[1.6, 0.118, 0.12, 0.13], [1.56, 0.17, 0.145, 0.16], [1.51, 0.205, 0.16, 0.19], [1.46, 0.218, 0.168, 0.2]]:
		cape.append(_ring_at(lv[0], [lv[1], lv[2], lv[3]], 28, 2.3))
	m.loft(cloth, cape, true, false, false)
	var pts: Array = []
	var radii: Array = []
	for i in 29:
		var th := TAU * i / 28
		var s := sin(th)
		pts.append(Vector3(cos(th) * 0.135, 1.585 - 0.06 * pow(maxf(0.0, s), 1.5), s * (0.12 if s > 0.0 else 0.135) + 0.005))
		radii.append(0.042 + 0.008 * sin(th * 3.0 + 0.4) + 0.005 * sin(th * 7.0 + 1.0))
	m.tube(cloth, pts, radii, 9, true)
	var hood: Array = []
	for i in 8:
		var t := i / 7.0
		var y := lerpf(1.6, 1.34, t)
		var zb: float = _cloth(y)[2]
		var w := lerpf(0.14, 0.012, pow(t, 1.15))
		var dd := lerpf(0.05, 0.01, t)
		var zc := -zb - dd - 0.004
		var ring := PackedVector3Array()
		for k in 14:
			var a := TAU * k / 14
			ring.append(Vector3(cos(a) * w, y + sin(a) * 0.004, zc + sin(a) * dd))
		hood.append(ring)
	m.loft(cloth, hood, true, true, true)


# ---- belts and pouch

static func _band_pt(y: float, a: float, grow: float) -> Vector3:
	var d := _cloth(y)
	var q := _se(a, d[0] + grow, d[1] + grow, d[2] + grow, 2.4)
	return Vector3(q.x, y, q.y)


## A strap round the cloth at height y(a), `grow` over it, thick at its edges.
static func _band(m, mat_: Material, y_fn: Callable, half_h: float, grow: float, n := 32) -> void:
	var rings: Array = []
	for prof in [[-half_h, -0.006], [-half_h, 0.0], [half_h, 0.0], [half_h, -0.006]]:
		var ring := PackedVector3Array()
		for i in n:
			var a := TAU * i / n
			ring.append(_band_pt(y_fn.call(a) + prof[0], a, grow + prof[1]))
		rings.append(ring)
	m.loft(mat_, rings, false, false, false)


static func _out_basis(a: float) -> Basis:
	var out := Vector3(cos(a), 0, sin(a)).normalized()
	return Basis(Vector3.UP.cross(out).normalized(), Vector3.UP, out)


static func _buckle(m, metal: Material, p: Vector3, b: Basis, w: float, h: float, bar := 0.01) -> void:
	m.box(metal, p + b * Vector3(0, h * 0.5, 0), Vector3(w, bar, 0.009), b)
	m.box(metal, p + b * Vector3(0, -h * 0.5, 0), Vector3(w, bar, 0.009), b)
	m.box(metal, p + b * Vector3(w * 0.5, 0, 0), Vector3(bar, h, 0.009), b)
	m.box(metal, p + b * Vector3(-w * 0.5, 0, 0), Vector3(bar, h, 0.009), b)
	m.box(metal, p + b * Vector3(w * 0.1, 0, 0.002), Vector3(w * 0.75, bar * 0.6, 0.007), b)


static func belts(m) -> void:
	var leather := mat("wk_leather")
	var metal := mat("wk_metal")
	# the belt at the waist with a square buckle
	m.set_bones([seg("spine_01", "spine_02"), seg("pelvis", "spine_01")], 4.0, 2)
	var wy := 1.195
	_band(m, leather, func(_a: float) -> float: return wy, 0.03, 0.009)
	var fp := _band_pt(wy, PI / 2, 0.014)
	var fb := _out_basis(PI / 2)
	_buckle(m, metal, fp, fb, 0.078, 0.07, 0.012)
	m.box(leather, fp + fb * Vector3(0.06, -0.06, 0.004), Vector3(0.04, 0.11, 0.008), fb * Basis(Vector3.BACK, -0.1))
	# the sword belt, slung from the right hip down across to the left thigh
	m.set_bones([seg("pelvis", "spine_01")], 4.0, 1)
	var hy := func(a: float) -> float: return 1.085 - 0.07 * cos(a) - 0.015 * maxf(0.0, sin(a))
	_band(m, leather, hy, 0.022, 0.014)
	var ba := PI / 2 + 0.5
	_buckle(m, metal, _band_pt(hy.call(ba), ba, 0.018), _out_basis(ba), 0.05, 0.05, 0.009)
	# the frog and ring on the left hip, where the scabbard hangs
	var la := 0.3
	var lp := _band_pt(hy.call(la), la, 0.02)
	var lb := _out_basis(la)
	m.box(leather, lp + lb * Vector3(0, -0.05, 0.003), Vector3(0.034, 0.09, 0.008), lb)
	var ring_pts: Array = []
	var ring_r: Array = []
	for i in 13:
		var t := TAU * i / 12
		ring_pts.append(lp + lb * Vector3(cos(t) * 0.026, -0.105 + sin(t) * 0.026, 0.008))
		ring_r.append(0.0045)
	m.tube(metal, ring_pts, ring_r, 5, true)
	# the pouch on the right hip, hanging from the sword belt
	var pa := PI / 2 + 1.05
	var pp := _band_pt(hy.call(pa) - 0.07, pa, 0.04)
	var pb := _out_basis(pa) * Basis(Vector3.RIGHT, 0.06)
	m.box(leather, pp, Vector3(0.11, 0.115, 0.05), pb)
	m.box(leather, pp + pb * Vector3(0, 0.034, 0.028), Vector3(0.118, 0.062, 0.012), pb)
	m.box(leather, pp + pb * Vector3(0, -0.002, 0.026), Vector3(0.028, 0.06, 0.009), pb)
	for sx in [-0.034, 0.034]:
		m.box(leather, pp + pb * Vector3(sx, 0.07, -0.004), Vector3(0.018, 0.05, 0.05), pb)


# ---- pauldrons, vambraces, gauntlets

## The sheet's pose of one arm (skeleton space): it hangs ARM_DOWN degrees down from the T-pose.
static func _arm_pose(s: float) -> Transform3D:
	var sh := bp(sd("upperarm", s))
	var ra := Basis(Vector3(0, 0, 1), deg_to_rad(-ARM_DOWN * s))
	return Transform3D(ra, sh - ra * sh)


## A pauldron, shaped as it hangs in the sheet (a rounded cap over the shoulder and two lames
## hugging the upper arm), then turned back into the T-pose. It rides on the upper arm.
static func _pauldron(m, s: float) -> void:
	var metal := mat("wk_metal")
	var ap := _arm_pose(s)
	var back := ap.affine_inverse()
	var sh := bp(sd("upperarm", s))
	var d := ap.basis * Vector3(s, 0, 0)     # down the hanging arm
	var o := ap.basis * Vector3.UP           # out from the arm, away from the body
	var f := Vector3(0, 0, 1)
	m.set_bones([seg(sd("upperarm", s), sd("lowerarm", s))], 4.0, 1)
	# the cap: a dome over the shoulder, tipped outward, a little longer front to back
	var c := sh + o * 0.012 + d * 0.012
	var r := 0.118
	var d0 := (Vector3(0.42 * s, 1.0, 0.0)).normalized()
	var e1 := f
	var e2 := d0.cross(e1).normalized()
	var th_max := deg_to_rad(70.0)
	var rings: Array = []
	for i in 9:
		var th := lerpf(0.06, th_max, i / 8.0)
		var ring := PackedVector3Array()
		for j in 26:
			var ph := TAU * j / 26
			ring.append(back * (c + (d0 * cos(th) + (e1 * cos(ph) * 1.12 + e2 * sin(ph)) * sin(th)) * r))
		rings.append(ring)
	m.loft(metal, rings, true, true, false)
	var edge: Array = []
	var er: Array = []
	for j in 27:
		var ph := TAU * j / 26
		edge.append(back * (c + (d0 * cos(th_max) + (e1 * cos(ph) * 1.12 + e2 * sin(ph)) * sin(th_max)) * (r + 0.002)))
		er.append(0.006)
	m.tube(metal, edge, er, 6, true)
	# two lames down the upper arm, open on the side against the body
	for i in 2:
		var u0 := 0.062 + 0.042 * i
		var u1 := u0 + 0.05
		var r0 := 0.094 - 0.005 * i
		var r1 := r0 + 0.009
		var lame: Array = []
		for pr in [[u0, r0], [u1, r1]]:
			var ring := PackedVector3Array()
			for j in 17:
				var ph := lerpf(-2.0, 2.0, j / 16.0)
				ring.append(back * (sh + d * pr[0] + (o * cos(ph) + f * sin(ph)) * pr[1]))
			lame.append(ring)
		m.loft(metal, lame, true, false, false, false)
		var trim: Array = []
		var tr: Array = []
		for j in 17:
			var ph := lerpf(-2.0, 2.0, j / 16.0)
			trim.append(back * (sh + d * u1 + (o * cos(ph) + f * sin(ph)) * (r1 + 0.002)))
			tr.append(0.0055)
		m.tube(metal, trim, tr, 5, true, true, true)


static func pauldrons(m) -> void:
	for s in [1.0, -1.0]:
		_pauldron(m, s)


static func vambraces(m) -> void:
	var metal := mat("wk_metal")
	var leather := mat("wk_leather")
	for s in [1.0, -1.0]:
		var ua := sd("upperarm", s)
		var la := sd("lowerarm", s)
		var hd := sd("hand", s)
		m.set_bones([seg(la, hd)], 4.0, 1)
		var rv := func(t: float) -> float: return lerpf(0.072, 0.062, (t - 0.55) / 0.38)
		_limb_tube(m, metal, ARM, s, 0.55, 0.93, rv, 14, 6)
		for t in [0.55, 0.915]:
			_limb_tube(m, metal, ARM, s, t, t + 0.016, func(tt: float) -> float: return rv.call(tt) + 0.0035, 14, 1)
		for t in [0.66, 0.83]:
			_limb_tube(m, leather, ARM, s, t, t + 0.024, func(tt: float) -> float: return rv.call(tt) + 0.003, 14, 1)
		# elbow cop on the point of the elbow, a fan on the outside
		m.set_bones([seg(ua, la), seg(la, hd)], 2.0, 2)
		var el := bp(la)
		m.lathe(metal, Transform3D(Basis(Vector3.RIGHT, -PI / 2), el + Vector3(0, 0, -0.036)),
				[[0.07, -0.004], [0.066, 0.013], [0.053, 0.031], [0.03, 0.044], [0.0, 0.048]], 14, true, false)
		m.lathe(metal, Transform3D(Basis(Vector3.RIGHT, -PI / 4), el + Vector3(0, 0.05, -0.045)),
				[[0.046, 0.0], [0.041, 0.008], [0.022, 0.014], [0.0, 0.016]], 10, true, false)


## Gloved hand cross-sections (left hand): [x, centre y, centre z, half height, half depth].
const HAND := [[0.735, 1.436, -0.062, 0.036, 0.051], [0.78, 1.435, -0.066, 0.035, 0.065], [0.83, 1.437, -0.07, 0.03, 0.069], [0.866, 1.44, -0.072, 0.022, 0.067]]


static func _hand_ring(h: Array, s: float, grow := 0.0, from_k := 0, to_k := 14, n := 14) -> PackedVector3Array:
	var ring := PackedVector3Array()
	for k in range(from_k, to_k):
		var a := TAU * k / n
		ring.append(Vector3(h[0] * s, h[1] + (h[3] + grow) * signf(sin(a)) * pow(absf(sin(a)), 2.0 / 2.6), h[2] + (h[4] + grow) * signf(cos(a)) * pow(absf(cos(a)), 2.0 / 2.6)))
	return ring


static func gauntlets(m) -> void:
	var metal := mat("wk_metal")
	for s in [1.0, -1.0]:
		var hand_i := bi(sd("hand", s))
		var low_i := bi(sd("lowerarm", s))
		# bell cuff over the vambrace's end, closing onto the wrist
		m.set_skin_fn(func(p: Vector3) -> Array:
			var w := lerpf(0.35, 1.0, smoothstep(0.665, 0.745, absf(p.x)))
			return WMesh.pack([[hand_i, w], [low_i, 1.0 - w]]))
		var cuff: Array = []
		var cr: Array = []
		for pr in [[0.66, 0.08], [0.69, 0.074], [0.72, 0.066], [0.748, 0.058]]:
			cuff.append(Vector3(pr[0] * s, 1.437, -0.064))
			cr.append(pr[1])
		m.tube(metal, cuff, cr, 14, true, false, false, Vector2(1.1, 0.9))
		# the hand, plates over its back, a knuckle bar
		m.set_bones([seg(sd("hand", s), sd("middle_01", s))], 4.0, 1)
		var hand_rings: Array = []
		for h in HAND:
			hand_rings.append(_hand_ring(h, s))
		m.loft(metal, hand_rings, true, true, true)
		var plate: Array = []
		for i in 4:
			plate.append(_hand_ring(HAND[i], s, 0.006, 1, 7))
		m.loft(metal, plate, true, false, false, false)
		m.box(metal, Vector3(0.858 * s, 1.462, -0.07), Vector3(0.022, 0.013, 0.122))
		# fingers and thumb, each on its own bones, lames over each joint
		for fg in ["index", "middle", "ring", "pinky", "thumb"]:
			var names: Array = []
			for k in ["01", "02", "03", "04_leaf"]:
				names.append(sd("%s_%s" % [fg, k], s))
			var pts: Array = []
			for nme in names:
				pts.append(bp(nme))
			pts[3] = pts[3] + (pts[3] - pts[2]).normalized() * 0.012
			m.set_bones([[bi(names[0]), pts[0], pts[1]], [bi(names[1]), pts[1], pts[2]], [bi(names[2]), pts[2], pts[3]]], 4.0, 2)
			var rr: Array = [0.0145, 0.0138, 0.013, 0.0112] if fg != "thumb" else [0.017, 0.016, 0.0148, 0.0125]
			m.tube(metal, pts, rr, 7, true, true, true)
			for k in 3:
				var a: Vector3 = pts[k]
				var b: Vector3 = pts[k + 1]
				var dd := (b - a).normalized()
				var up := (Vector3.UP - dd * Vector3.UP.dot(dd)).normalized()
				m.box(metal, (a + b) * 0.5 + up * (rr[k] * 0.85), Vector3(a.distance_to(b) * 0.88, 0.007, 0.026), Basis(dd, up, dd.cross(up)))


# ---- boots

## [z, half width, top height, centre x] from heel to toe (left foot).
const FOOT := [[-0.118, 0.034, 0.12, 0.092], [-0.104, 0.05, 0.16, 0.093], [-0.072, 0.058, 0.18, 0.094], [-0.032, 0.06, 0.18, 0.095],
		[0.012, 0.062, 0.148, 0.097], [0.06, 0.065, 0.114, 0.099], [0.108, 0.067, 0.092, 0.1], [0.152, 0.062, 0.079, 0.1],
		[0.188, 0.05, 0.067, 0.099], [0.21, 0.032, 0.055, 0.098], [0.223, 0.011, 0.046, 0.098]]


static func boots(m) -> void:
	var leather := mat("wk_leather")
	var metal := mat("wk_metal")
	for s in [1.0, -1.0]:
		var calf_i := bi(sd("calf", s))
		var foot_i := bi(sd("foot", s))
		var ball_i := bi(sd("ball", s))
		# the shaft to below the knee, a turned-down cuff, straps at the ankle
		m.set_skin_fn(func(p: Vector3) -> Array:
			var wf := 0.55 * smoothstep(0.19, 0.1, p.y)
			return WMesh.pack([[calf_i, 1.0 - wf], [foot_i, wf]]))
		var rb := func(t: float) -> float: return lerpf(0.084, 0.066, (t - 0.55) / 0.435)
		_limb_tube(m, leather, LEG, s, 0.55, 0.985, rb, 14, 8)
		_limb_tube(m, leather, LEG, s, 0.53, 0.615, func(t: float) -> float: return lerpf(0.096, 0.09, (t - 0.53) / 0.085), 14, 2)
		for t in [0.9, 0.95]:
			_limb_tube(m, leather, LEG, s, t, t + 0.025, func(tt: float) -> float: return rb.call(tt) + 0.005, 14, 1)
		var ank := bp(sd("foot", s))
		m.box(metal, ank + Vector3(0.071 * s, 0.03, 0.005), Vector3(0.008, 0.028, 0.026))
		# the foot: a loft from heel to toe, the toes bending on the ball bone
		m.set_skin_fn(func(p: Vector3) -> Array:
			var wb := smoothstep(0.085, 0.14, p.z)
			var wc := 0.4 * smoothstep(0.14, 0.2, p.y) * (1.0 - smoothstep(-0.02, 0.04, p.z))
			return WMesh.pack([[ball_i, wb], [foot_i, (1.0 - wb) * (1.0 - wc)], [calf_i, wc]]))
		var rings: Array = []
		var y_bot := 0.018
		for st in FOOT:
			var ring := PackedVector3Array()
			var yc: float = (st[2] + y_bot) * 0.5
			var hy: float = (st[2] - y_bot) * 0.5
			for k in 14:
				var q := _se(TAU * k / 14, st[1], hy, hy, 2.6)
				ring.append(Vector3(st[3] * s + q.x, yc + q.y, st[0]))
			rings.append(ring)
		m.loft(leather, rings, true, true, true)
		# an instep strap with a buckle
		var strap: Array = []
		var sr: Array = []
		for k in 15:
			var a := lerpf(-0.2, PI + 0.2, k / 14.0)
			strap.append(Vector3(0.096 * s + cos(a) * 0.068, 0.022 + sin(a) * 0.105, 0.03))
			sr.append(0.012)
		m.tube(leather, strap, sr, 6, true, true, true, Vector2(1.0, 0.45), Vector3.BACK)
		m.box(metal, Vector3((0.096 + 0.066) * s, 0.06, 0.03), Vector3(0.008, 0.024, 0.024))
		# the sole: the footprint, a little bigger, 2 cm thick
		var outline := PackedVector3Array()
		for st in FOOT:
			outline.append(Vector3((st[3] + st[1] + 0.004) * s, 0.0, st[0]))
		for i in range(FOOT.size() - 1, -1, -1):
			outline.append(Vector3((FOOT[i][3] - FOOT[i][1] - 0.004) * s, 0.0, FOOT[i][0]))
		var top := PackedVector3Array()
		for p in outline:
			top.append(p + Vector3(0, 0.022, 0))
		m.loft(leather, [outline, top], false, true, true)


# ------------------------------------------------------------------ the whole knight

## The White Knight as one skinned mesh (a scene root holding it).
static func build() -> Node3D:
	var m := WMesh.new()
	m.pose = sheet_pose()
	hauberk(m)
	chausses(m)
	coif(m)
	helm(m)
	tabard(m)
	belts(m)
	pauldrons(m)
	vambraces(m)
	gauntlets(m)
	boots(m)
	m.prepare()
	var maps := _depth_maps(m)
	for n in PROJECTED:
		m.uv_fns[mat(n)] = func(_rest: Array, posed: Array, _nr: Vector3, np_: Vector3) -> Array: return _proj_uv(maps, posed, np_)
	m.uv_fns[mat("wk_helm")] = func(rest: Array, _posed: Array, nr: Vector3, _np: Vector3) -> Array: return _helm_tri_uv(rest, nr)
	for n in TILE:
		var tile: float = TILE[n]
		m.uv_fns[mat(n)] = func(rest: Array, _posed: Array, nr: Vector3, _np: Vector3) -> Array: return _box_uv(rest, nr, tile)
	var root := Node3D.new()
	root.name = NAME
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = m.finish()
	mi.skin = make_skin()
	root.add_child(mi)
	root.set_meta("triangles", m.triangle_count())
	return root


# ------------------------------------------------------------------ the shield

const SHIELD_NAME := "WK_heater_shield"
## Held items are built with the grip at the origin; this turns the shield's design frame
## (x across, y up, z out of the face) into the hand's frame (as every shield in the game).
const SHIELD_BASIS := Basis(Vector3(0, 1, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0))
## Half the heater outline, top centre round to the point.
const SHIELD_HALF := [Vector2(0, 0.3), Vector2(0.13, 0.295), Vector2(0.235, 0.27), Vector2(0.245, 0.18), Vector2(0.238, 0.04),
		Vector2(0.21, -0.09), Vector2(0.16, -0.21), Vector2(0.09, -0.32), Vector2(0, -0.41)]
const SHIELD_DOME := [[1.0, 0.0], [0.86, 0.013], [0.66, 0.025], [0.44, 0.034], [0.22, 0.04], [0.06, 0.042]]


static func _shield_outline() -> PackedVector2Array:
	var pts := PackedVector2Array(SHIELD_HALF)
	for i in range(SHIELD_HALF.size() - 2, 0, -1):
		pts.append(Vector2(-SHIELD_HALF[i].x, SHIELD_HALF[i].y))
	return pts


## The shield's face is the TABARD close-up from the owner's sheet: ivory linen, the red cross.
static func _shield_face_uv(q: Vector2) -> Vector2:
	var v: Dictionary = Atlas.VIEWS["tabard_panel"]
	var xs := 1081.0 + q.x * 285.0
	var ys := 642.0 - (q.y + 0.055) * 285.0
	return Vector2((v.ox + Atlas.K * (xs - v.x0)) / Atlas.SIZE.x, (v.oy + Atlas.K * (ys - v.y0)) / Atlas.SIZE.y)


## The White Knight's heater shield, held in the left hand (WK_heater_shield.scn).
static func shield() -> Node3D:
	var m := WMesh.new()
	m.skinned = false
	var face := mat("wk_cloth")
	var rim := mat("wk_helm")
	var back_m := mat("wk_leather")
	var outline := _shield_outline()
	var cen := Vector2(0, -0.03)
	var xf := Transform3D(SHIELD_BASIS, SHIELD_BASIS * Vector3(0, 0, 0.075))
	# the back and edge (wood under leather), then the painted, domed face
	var core: Array = []
	for z in [-0.03, 0.0]:
		var ring := PackedVector3Array()
		for pt in outline:
			ring.append(xf * Vector3(pt.x, pt.y, z))
		core.append(ring)
	m.loft(back_m, core, false, true, false)
	var dome: Array = []
	for lv in SHIELD_DOME:
		var ring := PackedVector3Array()
		for pt in outline:
			var q: Vector2 = cen + (pt - cen) * lv[0]
			ring.append(xf * Vector3(q.x, q.y, lv[1]))
		dome.append(ring)
	m.loft(face, dome, true, false, true)
	# a steel rim with brass edging, hugging the edge
	var rw := 0.022
	var secs: Array = []
	for pt in outline:
		var inner: Vector2 = pt + (cen - pt).normalized() * rw
		secs.append([xf * Vector3(pt.x, pt.y, -0.038), xf * Vector3(pt.x, pt.y, 0.006), xf * Vector3(inner.x, inner.y, 0.016), xf * Vector3(inner.x, inner.y, -0.038)])
	for i in secs.size():
		var a: Array = secs[i]
		var b: Array = secs[(i + 1) % secs.size()]
		var ins: Vector3 = (a[0] + a[2] + b[0] + b[2]) * 0.25
		for k in 4:
			m.quad(rim, a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k], ins)
	# grip and forearm strap behind
	m.box(back_m, xf * Vector3(0, 0.0, -0.045), Vector3(0.03, 0.18, 0.025), SHIELD_BASIS)
	m.box(back_m, xf * Vector3(0, 0.15, -0.048), Vector3(0.05, 0.035, 0.03), SHIELD_BASIS)
	var to_design := xf.affine_inverse()
	m.uv_fns[face] = func(rest: Array, _p: Array, _nr: Vector3, _np: Vector3) -> Array:
		var out: Array = []
		for p: Vector3 in rest:
			var d := to_design * p
			out.append(_shield_face_uv(Vector2(d.x, d.y)))
		return out
	m.uv_fns[rim] = func(rest: Array, _p: Array, _nr: Vector3, _np: Vector3) -> Array:
		var out: Array = []
		for p: Vector3 in rest:
			var d := to_design * p
			out.append(_helm_uv("helm_front", Vector3(d.x * 0.35, HELM_TOP - 0.012 + d.z * 0.12, 0)))
		return out
	m.uv_fns[back_m] = func(rest: Array, _p: Array, _nr: Vector3, _np: Vector3) -> Array:
		var out: Array = []
		for p: Vector3 in rest:
			var d := to_design * p
			out.append(view_uv("front", Vector3(d.x * 0.25, 1.195 + d.y * 0.02, 0)))
		return out
	var root := Node3D.new()
	root.name = SHIELD_NAME
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = m.finish()
	root.add_child(mi)
	return root
