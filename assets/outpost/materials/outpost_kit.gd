extends RefCounted
## Shared base of the White Knights Outpost asset library (meters, +Y up).
##
## Builds on the bandit-hideout kit (assets/hideout/Materials/kit.gd): the same mesh builder
## (HK.MB: one ArrayMesh per asset, a surface per material, UVs in meters) and the same asset
## layout (a Node3D root with a "Mesh" and a "Collision" child). What is new here:
##   - hand-painted materials: the texture carries the light, shade and wear (painter.gd ->
##     textures/*.png), high roughness, little specular, no photo detail or normal maps;
##   - the White Knights emblem (one cross shape, see painter.gd arm_width) for cloth, paint,
##     carving and wax;
##   - simple collision shapes (boxes and cylinders) instead of hulls, so a banner's cloth
##     never becomes an invisible wall.
## Loaded with preload constants, not class_name, so it works from the command line.

const HK := preload("res://assets/hideout/Materials/kit.gd")
const Painter := preload("res://assets/outpost/materials/painter.gd")
const TEX := "res://assets/outpost/materials/textures/%s.png"

static var _cache := {}


# ---------------------------------------------------------------- materials

## A hand-painted surface. meters = how much of the surface one texture tile covers
## (0 = the texture is mapped 0..1 across the face, as for heraldry).
static func painted(key: String, tex_name: String, meters: float, opts := {}) -> StandardMaterial3D:
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.resource_name = key
	m.albedo_texture = load(TEX % tex_name)
	m.roughness = opts.get("rough", 0.95)
	m.metallic = opts.get("metal", 0.0)
	m.metallic_specular = opts.get("spec", 0.25)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if meters > 0.0:
		var sc: Vector2 = opts.get("uv", Vector2(1.0 / meters, 1.0 / meters))
		m.uv1_scale = Vector3(sc.x, sc.y, 1.0)
	if opts.has("tint"):
		m.albedo_color = opts["tint"]
	if opts.get("scissor", false):
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
		m.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
	if opts.get("clamp", false):
		m.texture_repeat = false
	_cache[key] = m
	return m


## Ivory banner cloth with the cross; frayed hem (alpha).
static func banner_cloth() -> StandardMaterial3D:
	return painted("wk_banner_cloth", "heraldry_banner", 0.0, {"rough": 1.0, "spec": 0.15, "scissor": true})


## Pennant cloth: the cross by the hoist (heraldry_pennant).
static func pennant_cloth() -> StandardMaterial3D:
	return painted("wk_pennant_cloth", "heraldry_pennant", 0.0, {"rough": 1.0, "spec": 0.15})


## The square emblem painted on wood (shields, signboards, plaques).
static func emblem_paint() -> StandardMaterial3D:
	return painted("wk_emblem_paint", "heraldry_square", 0.0, {"rough": 0.85, "spec": 0.3})


## kind: "stained" (the Knights' dark, cared-for oak) or "weathered" (civilian, grey-brown).
static func oak(kind := "stained") -> StandardMaterial3D:
	return painted("oak_" + kind, "oak_" + kind, 2.0, {"rough": 0.9})


static func iron() -> StandardMaterial3D:
	return painted("iron_charcoal", "iron", 0.5, {"rough": 0.7, "metal": 0.35, "spec": 0.4})


static func gold() -> StandardMaterial3D:
	return painted("gold_tarnished", "gold", 0.5, {"rough": 0.5, "metal": 0.55, "spec": 0.5})


static func linen() -> StandardMaterial3D:
	return painted("linen", "linen", 1.0, {"rough": 1.0, "spec": 0.15})


static func stripes() -> StandardMaterial3D:
	return painted("linen_stripes", "stripes", 1.0, {"rough": 1.0, "spec": 0.15})


static func rope() -> StandardMaterial3D:
	return painted("rope", "rope", 1.0, {"rough": 1.0, "spec": 0.1, "uv": Vector2(4.0, 1.0)})


static func limestone() -> StandardMaterial3D:
	return painted("limestone", "limestone", 1.0, {"rough": 0.95, "spec": 0.2})


## Limestone painted red (carved emblems): the stone shows through the paint.
static func red_stone() -> StandardMaterial3D:
	return painted("limestone_red", "limestone", 1.0, {"rough": 0.9, "spec": 0.2, "tint": Color(1.05, 0.42, 0.42)})


static func parchment() -> StandardMaterial3D:
	return painted("parchment", "parchment", 0.0, {"rough": 1.0, "spec": 0.1})


static func daub() -> StandardMaterial3D:
	return painted("daub", "daub", 2.0, {"rough": 1.0, "spec": 0.15})


static func thatch() -> StandardMaterial3D:
	return painted("thatch", "thatch", 1.0, {"rough": 1.0, "spec": 0.1})


static func earth_floor() -> StandardMaterial3D:
	return painted("earth_floor", "earth_floor", 2.0, {"rough": 1.0, "spec": 0.1})


static func rubble() -> StandardMaterial3D:
	return painted("rubble", "rubble", 1.0, {"rough": 0.95, "spec": 0.2})


static func inn_sign() -> StandardMaterial3D:
	return painted("inn_sign", "inn_sign", 0.0, {"rough": 0.85, "spec": 0.25})


static func wicker() -> StandardMaterial3D:
	return painted("wicker", "wicker", 1.0, {"rough": 1.0, "spec": 0.15})


static func clay() -> StandardMaterial3D:
	return painted("clay", "clay", 1.0, {"rough": 0.85, "spec": 0.3})


## Undyed linen dyed a colour (cloth bolts, folded fabric, sacks).
static func cloth(name: String, tint: Color) -> StandardMaterial3D:
	return painted("cloth_" + name, "linen", 1.0, {"rough": 1.0, "spec": 0.15, "tint": tint})


## A flat painted colour for small goods (fruit, bread, meat, coal), cached by name.
static func goods(name: String, c: Color, rough := 0.85) -> StandardMaterial3D:
	if _cache.has("goods_" + name):
		return _cache["goods_" + name]
	var m := StandardMaterial3D.new()
	m.resource_name = "goods_" + name
	m.albedo_color = c
	m.roughness = rough
	m.metallic_specular = 0.3
	_cache["goods_" + name] = m
	return m


## Straw and hay: the thatch strands, golden and fresh.
static func straw() -> StandardMaterial3D:
	return painted("straw", "thatch", 0.5, {"rough": 1.0, "spec": 0.1, "tint": Color(1.35, 1.2, 0.85)})


## A Decal node (projects down its -Y) with a painted texture; size in meters.
static func decal(nm: String, tex_name: String, size: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = nm
	var d := Decal.new()
	d.name = "Decal"
	d.size = size
	d.texture_albedo = load(TEX % tex_name)
	d.position = Vector3(0, size.y * 0.5 - 0.05, 0)
	d.cull_mask = 1
	root.add_child(d)
	return root


static func shingles() -> StandardMaterial3D:
	return painted("shingles", "shingles", 1.0, {"rough": 0.95, "spec": 0.2})


## The cross stencilled on barrels, crates and chests (alpha cut-out, laid 3 mm off a surface).
static func stencil() -> StandardMaterial3D:
	return painted("wk_stencil", "stencil", 0.0, {"rough": 0.9, "spec": 0.2, "scissor": true})


static func warning_board() -> StandardMaterial3D:
	return painted("warning_board", "warning_board", 0.0, {"rough": 0.85, "spec": 0.25})


## Warm horn panes of a lit lantern.
static func lantern_glow() -> StandardMaterial3D:
	if _cache.has("lantern_glow"):
		return _cache["lantern_glow"]
	var m := StandardMaterial3D.new()
	m.resource_name = "lantern_glow"
	m.albedo_color = Color(0.85, 0.62, 0.32)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.62, 0.26)
	m.emission_energy_multiplier = 1.6
	m.roughness = 0.6
	_cache["lantern_glow"] = m
	return m


## Brown leather (ledger covers, straps).
static func leather() -> StandardMaterial3D:
	return painted("leather", "oak_stained", 0.33, {"rough": 0.8, "spec": 0.3, "tint": Color(0.9, 0.62, 0.5)})


## A flickering warm light (lanterns, candles), saved with the scene.
static func flicker_light(parent: Node3D, pos: Vector3, energy: float, range_: float, shadows := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = "Light"
	l.position = pos
	l.light_color = Color(1.0, 0.62, 0.3)
	l.light_energy = energy
	l.omni_range = range_
	l.omni_attenuation = 1.4
	l.shadow_enabled = shadows
	parent.add_child(l)
	l.set_script(HK.FLICKER)
	l.set("base_energy", energy)
	return l


static func wax() -> StandardMaterial3D:
	if _cache.has("wax"):
		return _cache["wax"]
	var m := StandardMaterial3D.new()
	m.resource_name = "wax"
	m.albedo_color = Color(0.5, 0.1, 0.1)
	m.roughness = 0.45
	m.metallic_specular = 0.5
	_cache["wax"] = m
	return m


# ---------------------------------------------------------------- asset node

## The standard asset node: Mesh + Collision. cols: simple shapes, each
##   ["box", center, size] or ["box", center, size, basis] or ["cyl", center, radius, height].
## An empty list means no collision (overhead or flat things).
## k: build the asset k times bigger (geometry, its textures and collision together), for
## comparing sizes. Lights and particles the builder adds itself must be placed with k too.
static func asset(nm: String, b: HK.MB, cols: Array, k := 1.0) -> Node3D:
	var root := Node3D.new()
	root.name = nm
	if k != 1.0:
		for m in b._d:
			var bk = b._d[m]
			var vv: PackedVector3Array = bk.v
			for i in vv.size():
				vv[i] *= k
			bk.v = vv
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = b.build()
	if tris(mi.mesh) > 2500:
		mi.mesh = HK.with_lods(mi.mesh)
	root.add_child(mi)
	if not cols.is_empty():
		var body := StaticBody3D.new()
		body.name = "Collision"
		for c in cols:
			var cs := CollisionShape3D.new()
			cs.position = c[1] * k
			match c[0]:
				"box":
					var bs := BoxShape3D.new()
					bs.size = c[2] * k
					cs.shape = bs
					if c.size() > 3:
						cs.basis = c[3]
				"cyl":
					var cy := CylinderShape3D.new()
					cy.radius = c[2] * k
					cy.height = c[3] * k
					cs.shape = cy
			body.add_child(cs)
		root.add_child(body)
	return root


static func tris(mesh: Mesh) -> int:
	var t := 0
	for s in mesh.get_surface_count():
		var idx = mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX]
		if idx is PackedInt32Array and idx.size() > 0:
			t += idx.size() / 3
		else:
			t += mesh.surface_get_array_len(s) / 3
	return t


# ---------------------------------------------------------------- geometry helpers

## A smooth sheet from a grid of nu x nv points (row by row) with explicit UVs.
## hint: which side the sheet faces.
static func sheet(b: HK.MB, m: Material, pts: PackedVector3Array, uvs: PackedVector2Array, nu: int, nv: int, hint: Vector3) -> void:
	var nr := PackedVector3Array()
	nr.resize(pts.size())
	for j in nv - 1:
		for i in nu - 1:
			var a := j * nu + i
			for t in [[a, a + 1, a + nu + 1], [a, a + nu + 1, a + nu]]:
				var g := (pts[t[1]] - pts[t[0]]).cross(pts[t[2]] - pts[t[0]])
				if g.dot(hint) < 0.0:
					g = -g
				nr[t[0]] += g
				nr[t[1]] += g
				nr[t[2]] += g
	for k in nr.size():
		nr[k] = nr[k].normalized() if nr[k].length_squared() > 0.0 else hint
	for j in nv - 1:
		for i in nu - 1:
			var a := j * nu + i
			var q := [a, a + 1, a + nu + 1, a + nu]
			b.tri_smooth(m, pts[q[0]], pts[q[1]], pts[q[2]], nr[q[0]], nr[q[1]], nr[q[2]], uvs[q[0]], uvs[q[1]], uvs[q[2]])
			b.tri_smooth(m, pts[q[0]], pts[q[2]], pts[q[3]], nr[q[0]], nr[q[2]], nr[q[3]], uvs[q[0]], uvs[q[2]], uvs[q[3]])


## Both sides of a thin sheet (cloth, paper): the front facing hint, a back 5 mm behind it.
static func sheet2(b: HK.MB, m: Material, pts: PackedVector3Array, uvs: PackedVector2Array, nu: int, nv: int, hint: Vector3) -> void:
	sheet(b, m, pts, uvs, nu, nv, hint)
	var back := PackedVector3Array()
	for p in pts:
		back.append(p - hint * 0.005)
	sheet(b, m, back, uvs, nu, nv, -hint)


## Depth of a banner's hem across its width (xn 0..1), as a fraction of its length.
static func hem(shape: String, xn: float) -> float:
	var mid := 1.0 - absf(2.0 * xn - 1.0)  # 0 at the sides, 1 in the middle
	match shape:
		"point": return 0.8 + 0.2 * mid
		"swallow": return 1.0 - 0.24 * mid
		"dagged": return 0.9 + 0.1 * absf(sin(xn * 3.0 * PI))
	return 1.0


## A banner hanging from y = 0 (its top edge) down to -length, centred on x, facing +Z.
## Soft vertical folds and a slight billow; both sides; heraldry UVs 0..1.
## nu, nv: grid resolution (fewer for small cloths).
static func banner(b: HK.MB, m: Material, width: float, length: float, shape := "straight", seed_ := 0, folds := 3.0, nu := 13, nv := 14) -> void:
	var ph := float(seed_) * 1.7
	var pts := PackedVector3Array()
	var uvs := PackedVector2Array()
	for j in nv:
		for i in nu:
			var xn := float(i) / (nu - 1)
			var d := hem(shape, xn) * float(j) / (nv - 1)
			var z := 0.035 * sin(xn * TAU * folds * 0.5 + ph) * (0.35 + 0.65 * d) + 0.05 * d * d
			pts.append(Vector3((xn - 0.5) * width, -d * length, z))
			uvs.append(Vector2(xn, d))
	sheet2(b, m, pts, uvs, nu, nv, Vector3(0, 0, 1))


## A triangular pennant flying along +X from its hoist edge (x = 0, y = 0 down to -hoist),
## drooping toward the tip. UVs: u 0..1 along the length, v 0..1 across the hoist.
static func pennant(b: HK.MB, m: Material, length: float, hoist: float, seed_ := 0) -> void:
	var nu := 10
	var nv := 5
	var pts := PackedVector3Array()
	var uvs := PackedVector2Array()
	for j in nv:
		for i in nu:
			var xn := float(i) / (nu - 1)
			var half := 0.5 * hoist * (1.0 - xn)
			var cy := -0.5 * hoist - 0.12 * length * xn * xn
			var y := cy - half + 2.0 * half * (1.0 - float(j) / (nv - 1))
			var z := 0.06 * sin(xn * PI * 1.6 + float(seed_)) * xn
			pts.append(Vector3(xn * length, y, z))
			uvs.append(Vector2(xn, -(y - cy) / hoist + 0.5))
	sheet2(b, m, pts, uvs, nu, nv, Vector3(0, 0, 1))


## A flat polygon (in the XY plane) extruded along +Z from z0 by depth: front face with UVs
## mapped from rect (0..1, v down), side walls in meters. Used for carved and embossed shapes.
static func extrude(b: HK.MB, m_front: Material, m_side: Material, poly: PackedVector2Array, z0: float, depth: float, rect: Rect2, back := false) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	var zf := z0 + depth
	for t in range(0, idx.size(), 3):
		var p := [poly[idx[t]], poly[idx[t + 1]], poly[idx[t + 2]]]
		var uv := []
		for q in p:
			uv.append(Vector2((q.x - rect.position.x) / rect.size.x, 1.0 - (q.y - rect.position.y) / rect.size.y))
		b.tri(m_front, Vector3(p[0].x, p[0].y, zf), Vector3(p[1].x, p[1].y, zf), Vector3(p[2].x, p[2].y, zf), Vector3(0, 0, 1), uv[0], uv[1], uv[2])
		if back:
			b.tri(m_side, Vector3(p[0].x, p[0].y, z0), Vector3(p[1].x, p[1].y, z0), Vector3(p[2].x, p[2].y, z0), Vector3(0, 0, -1), uv[0], uv[1], uv[2])
	var cen := Vector2.ZERO
	for q in poly:
		cen += q
	cen /= poly.size()
	for i in poly.size():
		var a := poly[i]
		var c := poly[(i + 1) % poly.size()]
		var mid := (a + c) * 0.5
		var out := Vector3(mid.x - cen.x, mid.y - cen.y, 0)
		var e := (c - a)
		var nrm := Vector3(e.y, -e.x, 0)
		if nrm.dot(out) < 0.0:
			nrm = -nrm
		b.quad(m_side, Vector3(a.x, a.y, z0), Vector3(c.x, c.y, z0), Vector3(c.x, c.y, zf), Vector3(a.x, a.y, zf), nrm)


## The emblem's cross as a polygon, arm length = size, centred at c.
static func cross_poly(size: float, c := Vector2.ZERO) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in Painter.cross_polygon():
		out.append(c + p * size)
	return out


## A rectangle face a-b-c-d (top-left, top-right, bottom-right, bottom-left) with UVs 0..1.
static func face(b: HK.MB, m: Material, a: Vector3, bb: Vector3, c: Vector3, d: Vector3, out: Vector3) -> void:
	b.tri(m, a, bb, c, out, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1))
	b.tri(m, a, c, d, out, Vector2(0, 0), Vector2(1, 1), Vector2(0, 1))


## Round knob (finials, nail heads, rosettes) centred at pos.
static func knob(b: HK.MB, m: Material, pos: Vector3, r: float, sides := 10) -> void:
	var prof := PackedVector2Array()
	for i in 7:
		var a := -PI * 0.5 + PI * float(i) / 6.0
		prof.append(Vector2(maxf(cos(a) * r, 0.0005), sin(a) * r))
	b.push(Transform3D(Basis(), pos))
	b.lathe(m, prof, sides, true)
	b.pop()


## A ring (torus) of radius rr made of short bars, around axis (its plane's normal).
static func ring(b: HK.MB, m: Material, center: Vector3, axis: Vector3, rr: float, thick: float, segs := 10, sides := 5) -> void:
	var u := HK.basis_y(axis).x
	var v := axis.normalized().cross(u)
	for i in segs:
		var a0 := TAU * float(i) / segs
		var a1 := TAU * float(i + 1) / segs
		b.cyl(m, center + (u * cos(a0) + v * sin(a0)) * rr, center + (u * cos(a1) + v * sin(a1)) * rr, thick, thick, sides, 0.0, false)


## Bottom edge of a heater shield at |x| (hw = half width, y0 = where the sides start to curve):
## two arcs whose centres sit on the opposite side meet in a point at the bottom.
static func heater_bottom(ax: float, hw: float, y0: float) -> float:
	var k := 0.6
	var r := hw * (1.0 + k)
	var c := clampf((ax + hw * k) / r, -1.0, 1.0)
	return y0 - r * sqrt(1.0 - c * c)


## The heater shield outline (y up, top edge at +h/2), clockwise.
static func heater_outline(w: float, h: float, n := 10) -> PackedVector2Array:
	var hw := w * 0.5
	var top := h * 0.5
	var y0 := heater_bottom(0.0, hw, 0.0)  # how far the point drops below y0
	y0 = -h * 0.5 - y0
	var pts := PackedVector2Array([Vector2(-hw, top), Vector2(hw, top)])
	for i in n + 1:
		var x := hw * (1.0 - float(i) / n)
		pts.append(Vector2(x, heater_bottom(x, hw, y0)))
	for i in range(1, n + 1):
		var x := -hw * float(i) / n
		pts.append(Vector2(x, heater_bottom(-x, hw, y0)))
	return pts


## A heater shield: back at z = 0, face bulging forward, painted with the emblem, iron rim,
## oak back. Centred on x and y (top edge at +h/2).
static func heater(b: HK.MB, w: float, h: float, thick := 0.035, bulge := 0.03) -> void:
	var hw := w * 0.5
	var top := h * 0.5
	var y0 := -h * 0.5 - heater_bottom(0.0, hw, 0.0)
	var face_z := func(x: float) -> float: return thick + bulge * (1.0 - pow(x / hw, 2.0))
	# Painted face: columns across, each from the top edge down to the outline.
	var nu := 11
	var nv := 9
	var pts := PackedVector3Array()
	var uvs := PackedVector2Array()
	for j in nv:
		for i in nu:
			var x := lerpf(-hw, hw, float(i) / (nu - 1))
			var yb := heater_bottom(absf(x), hw, y0)
			var y := lerpf(top, yb, float(j) / (nv - 1))
			pts.append(Vector3(x, y, face_z.call(x)))
			uvs.append(Vector2((x + hw) / w, (top - y) / h))
	sheet(b, emblem_paint(), pts, uvs, nu, nv, Vector3(0, 0, 1))
	# Iron rim round the edge and a raised lip on the face.
	var ol := heater_outline(w, h)
	var cen := Vector2(0, top - h * 0.42)
	for i in ol.size():
		var a := ol[i]
		var c := ol[(i + 1) % ol.size()]
		var za: float = face_z.call(a.x)
		var zc: float = face_z.call(c.x)
		var mid := (a + c) * 0.5 - cen
		b.quad(iron(), Vector3(a.x, a.y, 0), Vector3(c.x, c.y, 0), Vector3(c.x, c.y, zc + 0.006), Vector3(a.x, a.y, za + 0.006), Vector3(mid.x, mid.y, 0))
		var ia := a + (cen - a).normalized() * 0.022
		var ic := c + (cen - c).normalized() * 0.022
		b.quad(iron(), Vector3(a.x, a.y, za + 0.006), Vector3(c.x, c.y, zc + 0.006), Vector3(ic.x, ic.y, face_z.call(ic.x) + 0.004), Vector3(ia.x, ia.y, face_z.call(ia.x) + 0.004), Vector3(0, 0, 1))
	# Oak back.
	var idx := Geometry2D.triangulate_polygon(ol)
	for t in range(0, idx.size(), 3):
		var p0 := ol[idx[t]]
		var p1 := ol[idx[t + 1]]
		var p2 := ol[idx[t + 2]]
		b.tri(oak(), Vector3(p0.x, p0.y, 0), Vector3(p1.x, p1.y, 0), Vector3(p2.x, p2.y, 0), Vector3(0, 0, -1), Vector2(p0.y, p0.x), Vector2(p1.y, p1.x), Vector2(p2.y, p2.x))
