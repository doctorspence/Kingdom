extends RefCounted
## Building kit for the Tithelands (meters; door on local +z unless noted).
##
## Stone is laid stone by stone in courses over a dark mortar core; oak frames have sills,
## posts, rails, braces and plates with daub panels set back between them; doors and shutters
## are separate planks with iron straps; thatch is a thick layered sheet with a curled eave,
## a scalloped ridge cap and hazel liggers. Builders add into a Kit.MB mesh builder and record
## plain collision boxes. tools/build_buildings.gd bakes the results into assets/buildings/.

const Kit := preload("res://assets/hideout/Materials/kit.gd")
const MAT_DIR := "res://assets/buildings/materials/"


class Ctx:
	var mb: Kit.MB
	var rng := RandomNumberGenerator.new()
	var m: Dictionary
	var boxes: Array = []  # [Transform3D, Vector3 size]
	var soot := 0.0  # chance a stone comes out blackened (burned buildings)
	var lit := false  # windows hold a glow pane (lit at night by DayNight)

	func _init(seed_: int, mats: Dictionary) -> void:
		mb = Kit.MB.new(seed_)
		rng.seed = seed_ * 7919 + 13
		m = mats

	func stone() -> Material:
		if soot > 0.0 and rng.randf() < soot:
			return m.soot
		var r := rng.randf()
		return m.stone_a if r < 0.4 else (m.stone_b if r < 0.75 else m.stone_c)

	## Collision box in the builder's current frame.
	func col(center: Vector3, size: Vector3, basis := Basis()) -> void:
		boxes.append([mb.xf * Transform3D(basis, center), size])


# ---------------------------------------------------------------- materials

static func _tex(tex: String, tint: Color, uv: float, normal := 1.0, cull_off := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/%s/color.jpg" % tex)
	m.albedo_color = tint
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/%s/normal.jpg" % tex)
	m.normal_scale = normal
	m.roughness_texture = load("res://assets/textures/%s/rough.jpg" % tex)
	m.uv1_scale = Vector3(uv, uv, uv)
	m.metallic_specular = 0.25
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if cull_off:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## Creates (save = true) or loads the kit's shared materials in assets/buildings/materials.
static func materials(save := false) -> Dictionary:
	var defs := {
		"stone_a": _tex("cliff", Color(0.66, 0.63, 0.58), 0.9, 1.3),
		"stone_b": _tex("cliff", Color(0.56, 0.55, 0.52), 0.9, 1.3),
		"stone_c": _tex("cliff", Color(0.7, 0.64, 0.54), 0.9, 1.3),
		"stone_q": _tex("cliff", Color(0.78, 0.74, 0.66), 1.1, 0.9),  # dressed quoins, sills
		"soot": _tex("cliff", Color(0.2, 0.19, 0.18), 0.9, 1.3),
		"mortar": _tex("plaster", Color(0.33, 0.31, 0.28), 0.8, 0.6),
		"daub_cream": _tex("plaster", Color(0.88, 0.82, 0.7), 0.45, 0.9),
		"daub_ochre": _tex("plaster", Color(0.86, 0.7, 0.5), 0.45, 0.9),
		"daub_grey": _tex("plaster", Color(0.72, 0.7, 0.66), 0.45, 0.9),
		"daub_burnt": _tex("plaster", Color(0.36, 0.33, 0.3), 0.45, 0.9),
		"oak": _tex("wood", Color(0.62, 0.5, 0.4), 0.55, 1.2),
		"oak_grey": _tex("wood", Color(1.0, 0.92, 0.84), 0.55, 1.2),
		"planks": _tex("planks", Color(0.78, 0.68, 0.58), 0.6, 1.0),
		"planks_grey": _tex("planks", Color(0.9, 0.86, 0.8), 0.6, 1.0),
		"charred": _tex("wood", Color(0.13, 0.115, 0.105), 0.55, 1.5),
		"ash": _tex("dirt_dark", Color(0.3, 0.29, 0.28), 0.7, 1.0),
		"thatch": _tex("thatch", Color(0.72, 0.62, 0.44), 0.75, 2.0),
		"thatch_old": _tex("thatch", Color(0.52, 0.48, 0.38), 0.75, 2.0),
		"slate": _tex("cliff", Color(0.36, 0.37, 0.4), 1.4, 1.2),
		"slate_b": _tex("cliff", Color(0.44, 0.43, 0.42), 1.4, 1.2),
		"canvas": _tex("plaster", Color(0.62, 0.55, 0.43), 0.9, 0.5, true),
		"canvas_dark": _tex("plaster", Color(0.42, 0.36, 0.29), 0.9, 0.5, true),
		"canvas_red": _tex("plaster", Color(0.45, 0.2, 0.15), 0.9, 0.5, true),
		"hide": _tex("plaster", Color(0.34, 0.25, 0.18), 1.2, 0.8, true),
		"rope": _tex("thatch", Color(0.62, 0.5, 0.33), 2.5, 0.6),
		"water": null,
	}
	var iron := Kit.iron().duplicate() as StandardMaterial3D
	defs["iron"] = iron
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.025, 0.022, 0.02)
	dark.roughness = 1.0
	defs["dark"] = dark
	var glow := StandardMaterial3D.new()  # window panes: emission is driven by DayNight at night
	glow.albedo_color = Color(0.06, 0.045, 0.03)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.6, 0.26)
	glow.emission_energy_multiplier = 0.0
	defs["glow"] = glow
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.1, 0.13, 0.13, 0.82)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.roughness = 0.08
	water.metallic_specular = 0.7
	defs["water"] = water
	var out := {}
	if save:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MAT_DIR))
	for k in defs:
		var p: String = MAT_DIR + k + ".tres"
		if save:
			ResourceSaver.save(defs[k], p, ResourceSaver.FLAG_CHANGE_PATH)
		out[k] = load(p) if ResourceLoader.exists(p) else defs[k]
	return out


# ---------------------------------------------------------------- helpers

## Wall frame: local x along a→b, y up, z out (a rectangle walked counter-clockwise from above).
static func _push_wall(c: Ctx, a: Vector2, b: Vector2, y := 0.0) -> float:
	var d := b - a
	var L := d.length()
	var dir := d / L
	c.mb.push(Transform3D(Basis(Vector3(dir.x, 0, dir.y), Vector3.UP, Vector3(-dir.y, 0, dir.x)), Vector3(a.x, y, a.y)))
	return L


## Parts of [0, L] not blocked by a hole (Vector4 u0, u1, y0, y1) overlapping heights ya..yb.
static func _free(L: float, ya: float, yb: float, holes: Array) -> Array:
	var spans: Array = [Vector2(0, L)]
	for h: Vector4 in holes:
		if h.z >= yb - 0.01 or h.w <= ya + 0.01:
			continue
		var next: Array = []
		for s: Vector2 in spans:
			if h.y <= s.x or h.x >= s.y:
				next.append(s)
				continue
			if h.x > s.x + 0.02:
				next.append(Vector2(s.x, h.x))
			if h.y < s.y - 0.02:
				next.append(Vector2(h.y, s.y))
		spans = next
	return spans


## Box between two points (local x along the run).
static func beam(c: Ctx, mat: Material, p0: Vector3, p1: Vector3, w: float, h: float, jit := 0.012) -> void:
	var d := p1 - p0
	if d.length() < 0.01:
		return
	c.mb.box(mat, (p0 + p1) * 0.5, Vector3(d.length(), h, w), Kit.basis_x(d), jit)


## Flat polygon (in the u/v plane of a frame) extruded thick along n: both faces and the rim.
static func slab(c: Ctx, mat: Material, poly: PackedVector2Array, o: Vector3, u: Vector3, v: Vector3, n: Vector3, thick: float) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	var f := func(p: Vector2, s: float) -> Vector3: return o + u * p.x + v * p.y + n * (thick * 0.5 * s)
	for side: float in [1.0, -1.0]:
		for i in range(0, idx.size(), 3):
			var pa: Vector2 = poly[idx[i]]
			var pb: Vector2 = poly[idx[i + 1]]
			var pc: Vector2 = poly[idx[i + 2]]
			c.mb.tri(mat, f.call(pa, side), f.call(pb, side), f.call(pc, side), n * side, pa, pb, pc)
	for i in poly.size():
		var p0: Vector2 = poly[i]
		var p1: Vector2 = poly[(i + 1) % poly.size()]
		var cen := (o + u * (p0.x + p1.x) * 0.5 + v * (p0.y + p1.y) * 0.5)
		var mid := Vector3.ZERO
		for q in poly:
			mid += o + u * q.x + v * q.y
		mid /= poly.size()
		c.mb.quad(mat, f.call(p0, 1.0), f.call(p1, 1.0), f.call(p1, -1.0), f.call(p0, -1.0), cen - mid)


## Smooth sheet from a point grid (nu per row, nv rows), lit on the side facing `out`.
static func sheet(c: Ctx, mat: Material, pts: PackedVector3Array, uvs: PackedVector2Array, nu: int, nv: int, out: Vector3) -> void:
	var nr := PackedVector3Array()
	nr.resize(pts.size())
	var vote := 0.0
	for j in nv - 1:
		for i in nu - 1:
			var a := j * nu + i
			var g1 := (pts[a + 1] - pts[a]).cross(pts[a + nu + 1] - pts[a])
			var g2 := (pts[a + nu + 1] - pts[a]).cross(pts[a + nu] - pts[a])
			nr[a] += g1 + g2
			nr[a + 1] += g1
			nr[a + nu + 1] += g1 + g2
			nr[a + nu] += g2
			if j == 0:
				vote += (g1 + g2).dot(out)
	var s := -1.0 if vote < 0.0 else 1.0
	for k in nr.size():
		nr[k] = nr[k].normalized() * s
	for j in nv - 1:
		for i in nu - 1:
			var a := j * nu + i
			c.mb.tri_smooth(mat, pts[a], pts[a + 1], pts[a + nu + 1], nr[a], nr[a + 1], nr[a + nu + 1], uvs[a], uvs[a + 1], uvs[a + nu + 1])
			c.mb.tri_smooth(mat, pts[a], pts[a + nu + 1], pts[a + nu], nr[a], nr[a + nu + 1], nr[a + nu], uvs[a], uvs[a + nu + 1], uvs[a + nu])


# ---------------------------------------------------------------- stone

## Stone wall a→b (centerline), courses from y0 to y1, th thick. Courses line up with the
## tops and bottoms of the holes; end stones are big dressed quoins when quoins is set.
static func rubble(c: Ctx, a: Vector2, b: Vector2, y0: float, y1: float, th: float, holes: Array = [], quoins := true, course := Vector2(0.17, 0.3)) -> void:
	var L := _push_wall(c, a, b)
	var y := y0
	var row := 0
	while y < y1 - 0.03:
		var h := c.rng.randf_range(course.x, course.y)
		for hl: Vector4 in holes:
			for e: float in [hl.z, hl.w]:
				if e > y + 0.08 and e < y + h:
					h = e - y
		if y1 - (y + h) < 0.1:
			h = y1 - y
		for sp: Vector2 in _free(L, y, y + h, holes):
			c.mb.box(c.m.mortar, Vector3((sp.x + sp.y) * 0.5, y + h * 0.5, 0), Vector3(sp.y - sp.x, h, th * 0.84))
			var u := sp.x
			var first := true
			while u < sp.y - 0.04:
				var ln := c.rng.randf_range(0.3, 0.72)
				var mat: Material = c.stone()
				var at_end := (first and sp.x < 0.01) or (sp.y > L - 0.01 and sp.y - u < 0.9)
				if first and row % 2 == 1:
					ln *= 0.55
				if quoins and at_end:
					ln = 0.62 if (row % 2 == 0) == first else 0.36
					mat = c.m.stone_q
				ln = minf(ln, sp.y - u)
				if sp.y - (u + ln) < 0.16:
					ln = sp.y - u
				var cen := Vector3(u + ln * 0.5, y + h * 0.5, c.rng.randf_range(-0.012, 0.018))
				var sz := Vector3(ln - 0.03, h - 0.028, th + c.rng.randf_range(-0.02, 0.05))
				var rot := Basis(Vector3.UP, c.rng.randf_range(-0.03, 0.03)) * Basis(Vector3.RIGHT, c.rng.randf_range(-0.025, 0.025))
				c.mb.box(mat, cen, sz, rot, 0.022)
				u += ln
				first = false
		y += h
		row += 1
	for sp: Vector2 in _free(L, y0, y1, holes):
		c.col(Vector3((sp.x + sp.y) * 0.5, (y0 + y1) * 0.5, 0), Vector3(sp.y - sp.x, y1 - y0, th))
	for hl: Vector4 in holes:  # wall over each hole
		if hl.w < y1 - 0.05:
			c.col(Vector3((hl.x + hl.y) * 0.5, (hl.w + y1) * 0.5, 0), Vector3(hl.y - hl.x, y1 - hl.w, th))
	c.mb.pop()


## A stone chimney stack: wide base to `step_y`, narrower flue to `top`, cap course, dark flue.
static func chimney(c: Ctx, cx: float, cz: float, base: float, step_y: float, top: float, w := Vector2(1.05, 1.25), w2 := Vector2(0.72, 0.85)) -> void:
	for part in 2:
		var hw: Vector2 = (w if part == 0 else w2) * 0.5
		var ya := base if part == 0 else step_y
		var yb := step_y if part == 0 else top
		var th := 0.26
		var x0 := cx - hw.x + th * 0.5
		var x1 := cx + hw.x - th * 0.5
		var z0 := cz - hw.y + th * 0.5
		var z1 := cz + hw.y - th * 0.5
		rubble(c, Vector2(x0 - th * 0.5, z1), Vector2(x1 + th * 0.5, z1), ya, yb, th)
		rubble(c, Vector2(x1, z1 - th * 0.5), Vector2(x1, z0 + th * 0.5), ya, yb, th, [], false)
		rubble(c, Vector2(x1 + th * 0.5, z0), Vector2(x0 - th * 0.5, z0), ya, yb, th)
		rubble(c, Vector2(x0, z0 + th * 0.5), Vector2(x0, z1 - th * 0.5), ya, yb, th, [], false)
		c.mb.box(c.m.mortar, Vector3(cx, (ya + yb) * 0.5 - 0.15, cz), Vector3(hw.x * 2 - th * 1.6, yb - ya - 0.3, hw.y * 2 - th * 1.6))
		# weathering / cap: a course of slabs standing proud
		var cap := 0.12
		c.mb.box(c.m.stone_q, Vector3(cx, yb + cap * 0.5, cz), Vector3(hw.x * 2 + 0.12, cap, hw.y * 2 + 0.12), Basis(), 0.02)
	c.mb.box(c.m.dark, Vector3(cx, top + 0.125, cz), Vector3(w2.x - 0.4, 0.02, w2.y - 0.4))
	c.col(Vector3(cx, (base + top) * 0.5, cz), Vector3(w.x, top - base, w.y))


# ---------------------------------------------------------------- timber

const T := 0.26  # timber depth through a framed wall


## Timber-framed wall a→b from sill (y0) to plate top (y1). holes: Vector4(u0, u1, y0, y1)
## for doors (reaching below y0) and windows. ends: corner posts (skip on the walls between).
static func frame_wall(c: Ctx, a: Vector2, b: Vector2, y0: float, y1: float, holes: Array, daub: Material, ends := true, windows := {}) -> void:
	var L := _push_wall(c, a, b)
	var oak: Material = c.m.oak
	var ins := 0.0 if ends else T * 0.5 + 0.005
	# sill and plate
	for sp: Vector2 in _free(L, y0, y0 + 0.24, holes):
		var s0: float = maxf(sp.x, ins)
		var s1: float = minf(sp.y, L - ins)
		c.mb.box(oak, Vector3((s0 + s1) * 0.5, y0 + 0.12, 0), Vector3(s1 - s0, 0.24, T + 0.04), Basis(), 0.012)
	c.mb.box(oak, Vector3(L * 0.5, y1 - 0.12, 0), Vector3(L - ins * 2.0, 0.24, T + 0.05), Basis(), 0.012)
	# posts: corners, jambs, then fill so no panel is wider than 1.5 m
	var us: Array[float] = []
	if ends:
		us.append(0.13)
		us.append(L - 0.13)
	for h: Vector4 in holes:
		us.append(h.x - 0.11)
		us.append(h.y + 0.11)
	var edges: Array[float] = us.duplicate()
	edges.append(0.0)
	edges.append(L)
	edges.sort()
	for i in edges.size() - 1:
		var gap := edges[i + 1] - edges[i]
		var n := int(floor(gap / 1.5))
		for k in n:
			us.append(edges[i] + gap * float(k + 1) / (n + 1))
	us.sort()
	for u in us:
		var wpost := 0.3 if (u < 0.2 or u > L - 0.2) else 0.24
		c.mb.box(oak, Vector3(u, (y0 + y1) * 0.5, 0), Vector3(wpost, y1 - y0 - 0.46, T), Basis(Vector3.FORWARD, c.rng.randf_range(-0.012, 0.012)), 0.012)
	# rail, braces, studs, daub between the posts
	var yr := y0 + (y1 - y0) * 0.42
	var cols: Array[float] = us.duplicate()
	if not ends:
		cols.push_front(0.0)
		cols.push_back(L)
	for i in cols.size() - 1:
		var ua := cols[i] + 0.11
		var ub := cols[i + 1] - 0.11
		if ub - ua < 0.15:
			continue
		var mid := (ua + ub) * 0.5
		var in_hole := false
		for h: Vector4 in holes:
			if mid > h.x and mid < h.y:
				in_hole = true
		if in_hole:
			continue
		c.mb.box(oak, Vector3(mid, yr, 0), Vector3(ub - ua + 0.02, 0.18, T - 0.04), Basis(Vector3.FORWARD, c.rng.randf_range(-0.01, 0.01)), 0.01)
		var first := i == 0
		var last := i == cols.size() - 2
		if (first or last) and ub - ua > 0.6:
			var lo := Vector3(ub if first else ua, y0 + 0.24, 0)
			var hi := Vector3(ua if first else ub, y1 - 0.24, 0)
			beam(c, oak, lo, hi, T - 0.06, 0.17)
		elif ub - ua > 1.05:
			c.mb.box(oak, Vector3(mid, (yr + y1 - 0.24) * 0.5, 0), Vector3(0.17, y1 - 0.24 - yr - 0.18, T - 0.06), Basis(), 0.012)
	# daub: bands between hole edges, minus the holes
	var ys: Array[float] = [y0 + 0.2, y1 - 0.2]
	for h: Vector4 in holes:
		for e: float in [h.z, h.w]:
			if e > y0 + 0.2 and e < y1 - 0.2:
				ys.append(e)
	ys.sort()
	for i in ys.size() - 1:
		if ys[i + 1] - ys[i] < 0.01:
			continue
		for sp: Vector2 in _free(L, ys[i], ys[i + 1], holes):
			var s0: float = maxf(sp.x, ins)
			var s1: float = minf(sp.y, L - ins)
			c.mb.box(daub, Vector3((s0 + s1) * 0.5, (ys[i] + ys[i + 1]) * 0.5, 0), Vector3(s1 - s0, ys[i + 1] - ys[i], 0.15))
			c.col(Vector3((s0 + s1) * 0.5, (ys[i] + ys[i + 1]) * 0.5, 0), Vector3(s1 - s0, ys[i + 1] - ys[i], T))
	c.col(Vector3(L * 0.5, y1 - 0.1, 0), Vector3(L, 0.2, T))
	# openings
	for h: Vector4 in holes:
		if h.z < y0:
			_door(c, h, y1)
		else:
			_window(c, h, windows.get(h, -1))
	c.mb.pop()


## Plank door hung on the left jamb, standing open into the house.
static func _door(c: Ctx, h: Vector4, y1: float) -> void:
	var w := h.y - h.x
	var hh := h.w - h.z
	c.mb.box(c.m.oak, Vector3((h.x + h.y) * 0.5, h.w + 0.1, 0.0), Vector3(w + 0.5, 0.22, T + 0.06), Basis(), 0.012)
	c.mb.push(Transform3D(Basis(Vector3.UP, deg_to_rad(c.rng.randf_range(62, 85))), Vector3(h.x + 0.03, h.z + 0.02, -T * 0.5 + 0.02)))
	var n := maxi(4, roundi(w / 0.24))
	for i in n:
		var pw := (w - 0.04) / n
		c.mb.box(c.m.planks, Vector3(0.02 + pw * (i + 0.5), (hh - 0.04) * 0.5 + c.rng.randf_range(-0.01, 0.01), 0), Vector3(pw - 0.012, hh - 0.04, 0.055), Basis(), 0.006)
	for yy: float in [0.3, hh - 0.35]:
		c.mb.box(c.m.planks, Vector3(w * 0.5, yy, -0.05), Vector3(w - 0.12, 0.15, 0.045))
		c.mb.box(c.m.iron, Vector3(0.36, yy, 0.035), Vector3(0.72, 0.05, 0.012))
	beam(c, c.m.planks, Vector3(0.12, 0.38, -0.05), Vector3(w - 0.12, hh - 0.43, -0.05), 0.04, 0.13, 0.0)
	c.mb.cyl(c.m.iron, Vector3(w - 0.16, hh * 0.48, 0.03), Vector3(w - 0.16, hh * 0.48, 0.06), 0.06, 0.06, 6)
	c.mb.pop()


## Window: oak sill and head, mullions, dark inside, plank shutters (open, closed or one each).
static func _window(c: Ctx, h: Vector4, state: int) -> void:
	var w := h.y - h.x
	var hh := h.w - h.z
	var cx := (h.x + h.y) * 0.5
	c.mb.box(c.m.dark, Vector3(cx, (h.z + h.w) * 0.5, -0.03), Vector3(w + 0.02, hh + 0.02, 0.05))
	c.mb.box(c.m.oak, Vector3(cx, h.z - 0.07, 0.03), Vector3(w + 0.36, 0.14, T + 0.1), Basis(), 0.01)
	c.mb.box(c.m.oak, Vector3(cx, h.w + 0.08, 0.0), Vector3(w + 0.3, 0.16, T + 0.02), Basis(), 0.01)
	if c.lit:
		c.mb.box(c.m.glow, Vector3(cx, (h.z + h.w) * 0.5, -0.012), Vector3(w - 0.02, hh - 0.02, 0.012))
	var nm := 2 if w > 0.7 else 1
	for i in nm:
		c.mb.box(c.m.oak, Vector3(h.x + w * float(i + 1) / (nm + 1), (h.z + h.w) * 0.5, 0.0), Vector3(0.07, hh, 0.09), Basis(), 0.005)
	if state < 0:
		state = c.rng.randi() % 3
	for side in 2:
		var open := state == 0 or (state == 2 and side == 0)
		var lw := w * 0.5 + 0.02
		var hinge := Vector3(h.x - 0.02 if side == 0 else h.y + 0.02, h.z - 0.02, T * 0.5 + 0.04)
		var ang := deg_to_rad(c.rng.randf_range(150, 172)) if open else 0.0
		var dirx := 1.0 if side == 0 else -1.0
		c.mb.push(Transform3D(Basis(Vector3.UP, ang * -dirx), hinge))
		var np := 3
		for i in np:
			c.mb.box(c.m.planks_grey, Vector3(dirx * lw * (i + 0.5) / np, (hh + 0.04) * 0.5, 0), Vector3(lw / np - 0.01, hh + 0.04, 0.045), Basis(), 0.005)
		for yy: float in [0.14, hh - 0.1]:
			c.mb.box(c.m.iron, Vector3(dirx * lw * 0.4, yy, 0.03), Vector3(lw * 0.8, 0.04, 0.012))
		c.mb.pop()


# ---------------------------------------------------------------- roofs

## Thatched roof, ridge along x over walls at z = ±hz, plate at plate_y. Thick layered courses,
## a curled eave, a scalloped ridge cap with liggers and spars, rafter feet and purlin ends.
static func thatch_roof(c: Ctx, hx: float, hz: float, plate_y: float, pitch_deg: float, mat: Material, thick := 0.42, over := 0.6, gable := 0.38, sag := 0.06) -> float:
	var p := deg_to_rad(pitch_deg)
	var yr := plate_y + hz * tan(p)
	var S := (hz + over) / cos(p)
	var gx := hx + gable
	var noise := FastNoiseLite.new()
	noise.seed = c.rng.randi()
	noise.frequency = 0.9
	var nu := int(ceil(gx * 2.0 / 0.32)) + 1
	# profile (s along the slope from the ridge, offset off the underside), closed loop
	var prof: Array[Vector2] = []
	var course := 0.5
	var s := 0.04
	while s < S - 0.05:
		var k := fposmod(s, course) / course
		prof.append(Vector2(s, thick + 0.07 * pow(k, 1.6)))
		s += course * 0.34
	prof.append(Vector2(S, thick * 0.95))
	prof.append(Vector2(S + 0.07, thick * 0.7))
	prof.append(Vector2(S + 0.08, thick * 0.35))
	prof.append(Vector2(S + 0.02, thick * 0.08))
	prof.append(Vector2(S - 0.1, 0.0))
	prof.append(Vector2(S * 0.5, 0.0))
	prof.append(Vector2(0.04, 0.0))
	var top_rows := prof.size() - 3
	for sgn: float in [1.0, -1.0]:
		var down := Vector3(0, -sin(p), sgn * cos(p))
		var n := Vector3(0, cos(p), sgn * sin(p))
		var pts := PackedVector3Array()
		var uvs := PackedVector2Array()
		var nv := prof.size() + 1
		for j in nv:
			var pr: Vector2 = prof[j % prof.size()]
			for i in nu:
				var x := -gx + gx * 2.0 * i / (nu - 1)
				var ss := pr.x
				var off := pr.y
				var sag_k := sin(PI * (x + gx) / (gx * 2.0))
				if j < top_rows:
					off += 0.05 * noise.get_noise_2d(x * 1.2, ss * 1.2 + sgn * 9.0) - sag * sag_k
				if pr.x > S - 0.2:
					ss += 0.07 * noise.get_noise_2d(x * 0.8, 40.0 + sgn * 9.0)
				var q := Vector3(x, yr, 0) + down * ss + n * off
				if j >= prof.size() - 3 and pr.y < 0.01:
					q = Vector3(x, yr, 0) + down * ss
				pts.append(q)
				uvs.append(Vector2(x, ss + off * 0.5))
		sheet(c, mat, pts, uvs, nu, nv, n)
		# gable ends: fill the profile loop
		for end in 2:
			var col := 0 if end == 0 else nu - 1
			var poly := PackedVector2Array()
			for j in prof.size():
				var q := pts[j * nu + col] - Vector3(pts[j * nu + col].x, yr, 0)
				poly.append(Vector2(q.dot(down), q.dot(n)))
			var idx := Geometry2D.triangulate_polygon(poly)
			var xe := pts[col].x
			for t in range(0, idx.size(), 3):
				var pa := pts[idx[t] * nu + col]
				var pb := pts[idx[t + 1] * nu + col]
				var pc := pts[idx[t + 2] * nu + col]
				c.mb.tri(mat, pa, pb, pc, Vector3(signf(xe), 0, 0), Vector2(pa.z, pa.y), Vector2(pb.z, pb.y), Vector2(pc.z, pc.y))
		# rafter feet under the eave, purlins along the slope
		var X := Vector3.RIGHT
		var bas := Basis(X, n, X.cross(n))
		var x := -hx + 0.2
		while x < hx - 0.1:
			var s0 := (hz - 0.2) / cos(p)
			var s1 := S - 0.18
			c.mb.box(c.m.oak, Vector3(x, yr, 0) + down * ((s0 + s1) * 0.5) - n * 0.08, Vector3(0.12, 0.15, s1 - s0), bas, 0.01)
			x += 0.55
		for f: float in [0.36, 0.7]:
			c.mb.box(c.m.oak, Vector3(0, yr, 0) + down * (S * f) - n * 0.11, Vector3(gx * 2.0 - 0.1, 0.22, 0.2), bas, 0.015)
		c.col(Vector3(0, yr, 0) + down * (S * 0.5) + n * (thick * 0.5), Vector3(gx * 2.0, thick, S), bas)
	# ridge beam, roll, cap
	c.mb.box(c.m.oak, Vector3(0, yr - 0.12, 0), Vector3(gx * 2.0 - 0.05, 0.26, 0.22), Basis(), 0.015)
	var ry := yr + thick / cos(p) * 0.72
	c.mb.cyl(mat, Vector3(-gx - 0.06, ry, 0), Vector3(gx + 0.06, ry, 0), thick * 0.55 + 0.08, thick * 0.55 + 0.08, 10, 0.06, true, int(gx * 3.0))
	_ridge_cap(c, gx, yr, p, thick, mat)
	return yr + thick / cos(p) + 0.2


static func _ridge_cap(c: Ctx, gx: float, yr: float, p: float, thick: float, mat: Material) -> void:
	var nu := int(ceil(gx * 2.0 / 0.11)) + 1
	var tooth := 0.55
	for sgn: float in [1.0, -1.0]:
		var down := Vector3(0, -sin(p), sgn * cos(p))
		var n := Vector3(0, cos(p), sgn * sin(p))
		var rows := [[0.0, 0.11], [0.3, 0.1], [0.6, 0.085], [1.0, 0.07], [1.0, 0.0]]
		var pts := PackedVector3Array()
		var uvs := PackedVector2Array()
		for r: Array in rows:
			for i in nu:
				var x := -gx + gx * 2.0 * i / (nu - 1)
				var k := absf(fposmod(x / tooth, 1.0) - 0.5) * 2.0  # 1 at the tooth tips, 0 between
				var edge := 0.5 + 0.28 * k
				var ss: float = r[0] * edge
				var q := Vector3(x, yr, 0) + down * (ss - 0.02) + n * (thick + float(r[1]))
				pts.append(q)
				uvs.append(Vector2(x, ss))
		sheet(c, mat, pts, uvs, nu, rows.size(), n)
		# liggers and the zigzag spars between them
		var la := 0.12
		var lb := 0.42
		for l: float in [la, lb]:
			var q0 := Vector3(-gx, yr, 0) + down * l + n * (thick + 0.13)
			c.mb.cyl(c.m.oak_grey, q0, q0 + Vector3(gx * 2.0, 0, 0), 0.022, 0.022, 5, 0.1, false, int(gx * 2.0))
		var x := -gx + 0.05
		var flip := false
		while x < gx - 0.3:
			var qa := Vector3(x, yr, 0) + down * (lb if flip else la) + n * (thick + 0.125)
			var qb := Vector3(x + 0.3, yr, 0) + down * (la if flip else lb) + n * (thick + 0.125)
			c.mb.cyl(c.m.oak_grey, qa, qb, 0.016, 0.016, 4, 0.0, false)
			x += 0.3
			flip = not flip


## Gable triangle at x = gx between the plate and the roof: daub with a king post and struts.
static func gable(c: Ctx, gx: float, hz: float, plate_y: float, pitch_deg: float, daub: Material) -> void:
	var rise := hz * tan(deg_to_rad(pitch_deg)) - 0.06
	var poly := PackedVector2Array([Vector2(-hz + 0.1, 0), Vector2(hz - 0.1, 0), Vector2(0, rise)])
	slab(c, daub, poly, Vector3(gx, plate_y, 0), Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(1, 0, 0), 0.15)
	var b := Vector3(gx, plate_y, 0)
	beam(c, c.m.oak, b, b + Vector3(0, rise, 0), T, 0.24)
	beam(c, c.m.oak, b + Vector3(0, 0, -hz + 0.12), b + Vector3(0, rise - 0.05, -0.08), T, 0.22)
	beam(c, c.m.oak, b + Vector3(0, 0, hz - 0.12), b + Vector3(0, rise - 0.05, 0.08), T, 0.22)
	beam(c, c.m.oak, b + Vector3(0, 0.1, -0.15), b + Vector3(0, rise * 0.55, -hz * 0.45), T - 0.05, 0.16)
	beam(c, c.m.oak, b + Vector3(0, 0.1, 0.15), b + Vector3(0, rise * 0.55, hz * 0.45), T - 0.05, 0.16)
	beam(c, c.m.oak, b + Vector3(0, rise * 0.5, -hz * 0.5 + 0.1), b + Vector3(0, rise * 0.5, hz * 0.5 - 0.1), T - 0.03, 0.18)


# ---------------------------------------------------------------- small pieces

## Stacked firewood under a plank pentice against a wall (local x along the wall, z out).
static func woodpile(c: Ctx, at: Vector3, yaw: float, length := 1.8, rows := 4) -> void:
	c.mb.push(Transform3D(Basis(Vector3.UP, yaw), at))
	var r := 0.11
	for row in rows:
		var n := int(length / (r * 2.05)) - (row % 2)
		for i in n:
			var x := -length * 0.5 + r + (row % 2) * r + i * r * 2.05
			var y := r + row * r * 1.75
			var l := c.rng.randf_range(0.85, 1.05)
			var rr := r * c.rng.randf_range(0.8, 1.1)
			c.mb.cyl(c.m.oak_grey, Vector3(x, y, 0.15 - l * 0.5 + 0.5), Vector3(x, y, 0.15 + l * 0.5 + 0.5), rr, rr, 7, 0.06)
	var top := rows * r * 1.75 + 0.5
	for x: float in [-length * 0.5 - 0.05, length * 0.5 + 0.05]:
		c.mb.box(c.m.oak_grey, Vector3(x, top * 0.5, 1.05), Vector3(0.12, top, 0.12), Basis(), 0.015)
	for i in 6:
		var x := -length * 0.5 - 0.2 + (length + 0.4) * (i + 0.5) / 6.0
		c.mb.box(c.m.planks_grey, Vector3(x, top + 0.18, 0.55), Vector3((length + 0.4) / 6.0 - 0.02, 0.04, 1.2), Basis(Vector3.RIGHT, 0.32), 0.01)
	c.col(Vector3(0, top * 0.5, 0.6), Vector3(length, top, 1.0))
	c.mb.pop()


## Faint smoke from a chimney top (only lived-in houses).
static func smoke(parent: Node3D, pos: Vector3) -> void:
	var sm := ParticleProcessMaterial.new()
	sm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	sm.emission_sphere_radius = 0.15
	sm.direction = Vector3.UP
	sm.spread = 8.0
	sm.initial_velocity_min = 0.5
	sm.initial_velocity_max = 0.8
	sm.gravity = Vector3(0.18, 0.08, 0.05)
	sm.scale_min = 0.8
	sm.scale_max = 1.4
	sm.scale_curve = Kit._curve([Vector2(0, 0.4), Vector2(1, 2.6)])
	sm.turbulence_enabled = true
	sm.turbulence_noise_strength = 0.25
	sm.color_ramp = Kit._ramp([Color(0.5, 0.5, 0.5, 0.0), Color(0.45, 0.45, 0.46, 0.2), Color(0.5, 0.5, 0.52, 0.0)], [0.0, 0.2, 1.0])
	var p := Kit._emitter(parent, pos, 14, 9.0, sm, Vector2(1.0, 1.0), false)
	p.name = "Smoke"
	p.visibility_aabb = AABB(Vector3(-4, -1, -4), Vector3(10, 12, 10))


# ---------------------------------------------------------------- buildings

## A cottage: stone plinth, oak frame with daub, thatch, stone chimney on one gable.
## burned: plinth and chimney stand, stumps of the frame, charred rafters, ash inside.
static func cottage(mats: Dictionary, seed_: int, burned := false, lived := true) -> Node3D:
	var c := Ctx.new(seed_, mats)
	var r := c.rng
	c.lit = lived and not burned
	var hx := r.randf_range(2.75, 3.05) if burned else r.randf_range(2.85, 3.2)
	var hz := r.randf_range(2.2, 2.45)
	var pitch := r.randf_range(48.0, 54.0)
	var daub: Material = [mats.daub_cream, mats.daub_ochre, mats.daub_grey][r.randi() % 3]
	if burned:
		daub = mats.daub_burnt
		c.soot = 0.45
	var floor_y := 0.1
	var plinth_top := r.randf_range(0.5, 0.62)
	var plate := plinth_top + 2.35
	var th := 0.42
	var door_w := 1.1
	var door_x := r.randf_range(0.2, 0.8) * (1.0 if r.randf() < 0.5 else -1.0)
	var door_top := floor_y + 2.0
	var chim_left := r.randf() < 0.6
	# plinth
	var dh := Vector4(door_x - door_w * 0.5 + hx + th * 0.5, door_x + door_w * 0.5 + hx + th * 0.5, floor_y, 9)
	rubble(c, Vector2(-hx - th * 0.5, hz), Vector2(hx + th * 0.5, hz), -0.45, plinth_top, th, [dh])
	rubble(c, Vector2(hx, hz - th * 0.5), Vector2(hx, -hz + th * 0.5), -0.45, plinth_top, th, [], false)
	rubble(c, Vector2(hx + th * 0.5, -hz), Vector2(-hx - th * 0.5, -hz), -0.45, plinth_top, th)
	rubble(c, Vector2(-hx, -hz + th * 0.5), Vector2(-hx, hz - th * 0.5), -0.45, plinth_top, th, [], false)
	c.mb.box(mats.stone_q, Vector3(door_x, floor_y - 0.06, hz), Vector3(door_w + 0.1, 0.14, th + 0.06), Basis(), 0.015)
	c.mb.box(mats.planks if not burned else mats.ash, Vector3(0, floor_y - 0.1, 0), Vector3(hx * 2 - th, 0.2, hz * 2 - th))
	c.col(Vector3(0, floor_y - 0.3, 0), Vector3(hx * 2 - th, 0.6, hz * 2 - th))
	c.mb.box(mats.stone_q, Vector3(door_x, 0.04, hz + 0.5), Vector3(door_w + 0.2, 0.16, 0.55), Basis(Vector3.UP, r.randf_range(-0.08, 0.08)), 0.03)
	# chimney
	var cx := -(hx + 0.21 + 0.52) if chim_left else (hx + 0.21 + 0.52)
	var ridge_y := plate + hz * tan(deg_to_rad(pitch))
	chimney(c, cx, r.randf_range(-0.4, 0.4), -0.7, plate - 0.2, ridge_y + 0.9)
	if burned:
		_burned_frame(c, hx, hz, plinth_top, plate, door_x, door_w, door_top)
	else:
		var win_y := plinth_top + 0.72
		var front_win := Vector4(0, 0, win_y, win_y + 0.68)
		var wx := hx - signf(door_x) * hx * 0.55
		front_win.x = wx - 0.42
		front_win.y = wx + 0.42
		var L := hx * 2.0
		var back: Array = []
		var nb := 2 if hx > 3.0 else 1
		for i in nb:
			var u := L * (i + 1) / (nb + 1) + r.randf_range(-0.3, 0.3)
			back.append(Vector4(u - 0.38, u + 0.38, win_y + 0.05, win_y + 0.65))
		var side_win := [Vector4(hz - 0.4, hz + 0.4, win_y, win_y + 0.62)]
		frame_wall(c, Vector2(-hx, hz), Vector2(hx, hz), plinth_top, plate, [Vector4(door_x - door_w * 0.5 + hx, door_x + door_w * 0.5 + hx, floor_y - 0.2, door_top), front_win], daub)
		frame_wall(c, Vector2(hx, hz), Vector2(hx, -hz), plinth_top, plate, [] if not chim_left else side_win, daub, false)
		frame_wall(c, Vector2(hx, -hz), Vector2(-hx, -hz), plinth_top, plate, back, daub)
		frame_wall(c, Vector2(-hx, -hz), Vector2(-hx, hz), plinth_top, plate, side_win if not chim_left else [], daub, false)
		gable(c, hx, hz, plate, pitch, daub)
		gable(c, -hx, hz, plate, pitch, daub)
		var thatch: Material = mats.thatch if r.randf() < 0.6 else mats.thatch_old
		thatch_roof(c, hx + 0.02, hz, plate, pitch, thatch)
		if r.randf() < 0.75:
			woodpile(c, Vector3((1.0 if chim_left else -1.0) * r.randf_range(0.2, 1.2), 0.0, -hz - 0.2), PI, r.randf_range(1.5, 2.2), 3)
	var root := finish(c, "Building")
	if lived and not burned:
		smoke(root, Vector3(cx, ridge_y + 1.1, 0))
	return root


static func _burned_frame(c: Ctx, hx: float, hz: float, y0: float, plate: float, door_x: float, door_w: float, door_top: float) -> void:
	var r := c.rng
	var walls := [[Vector2(-hx, hz), Vector2(hx, hz), true], [Vector2(hx, hz), Vector2(hx, -hz), false],
		[Vector2(hx, -hz), Vector2(-hx, -hz), true], [Vector2(-hx, -hz), Vector2(-hx, hz), false]]
	for wi in walls.size():
		var w: Array = walls[wi]
		var L := _push_wall(c, w[0], w[1])
		var ins := 0.0 if w[2] else T * 0.5
		var door := Vector2(door_x - door_w * 0.5 + hx, door_x + door_w * 0.5 + hx) if wi == 0 else Vector2(-1, -1)
		# sill, charred and broken in places
		var u := ins
		while u < L - ins - 0.1:
			var ln := minf(r.randf_range(0.8, 2.2), L - ins - u)
			if not (u + ln * 0.5 > door.x and u + ln * 0.5 < door.y):
				c.mb.box(c.m.charred, Vector3(u + ln * 0.5, y0 + 0.11, 0), Vector3(ln - 0.06, 0.22, T), Basis(Vector3.FORWARD, r.randf_range(-0.03, 0.03)), 0.03)
			u += ln + r.randf_range(0.0, 0.5)
		# post stumps, some still standing tall
		var posts: Array[float] = []
		if w[2]:
			posts.append_array([0.13, L - 0.13])
		var k := 1.4
		while k < L - 1.0:
			posts.append(k + r.randf_range(-0.2, 0.2))
			k += 1.5
		for pu in posts:
			if pu > door.x - 0.1 and pu < door.y + 0.1:
				continue
			var ht := (plate - y0) * (r.randf_range(0.6, 1.0) if r.randf() < 0.35 else r.randf_range(0.15, 0.55))
			c.mb.box(c.m.charred, Vector3(pu, y0 + ht * 0.5, 0), Vector3(0.24, ht, T - 0.02), Basis(Vector3.FORWARD, r.randf_range(-0.06, 0.06)), 0.04)
			c.col(Vector3(pu, y0 + ht * 0.5, 0), Vector3(0.24, ht, T))
		# what is left of the daub panels
		u = ins + 0.2
		while u < L - ins - 0.3:
			var ln := minf(r.randf_range(0.5, 1.3), L - ins - u)
			if r.randf() < 0.6 and not (u + ln > door.x and u < door.y):
				var ht := r.randf_range(0.25, 1.3)
				c.mb.box(c.m.daub_burnt, Vector3(u + ln * 0.5, y0 + 0.2 + ht * 0.5, 0), Vector3(ln, ht, 0.14), Basis(Vector3.FORWARD, r.randf_range(-0.04, 0.04)), 0.05)
			u += ln
		c.mb.pop()
	# fallen rafters and the ridge beam, ash and rubble inside
	for i in r.randi_range(5, 7):
		var sx := r.randf_range(-hx + 0.4, hx - 0.4)
		var sgn := 1.0 if r.randf() < 0.5 else -1.0
		var top := Vector3(sx, r.randf_range(0.9, plate - 0.3), sgn * (hz - 0.1))
		var bot := Vector3(sx + r.randf_range(-0.8, 0.8), 0.15, -sgn * r.randf_range(-0.3, hz * 0.8))
		var rad := r.randf_range(0.07, 0.1)
		c.mb.cyl(c.m.charred, top, bot, rad, rad * 0.8, 6, 0.15)
	c.mb.cyl(c.m.charred, Vector3(-hx + 0.3, 1.6, r.randf_range(-0.5, 0.5)), Vector3(hx - 0.5, 0.2, r.randf_range(-0.8, 0.8)), 0.13, 0.12, 7, 0.12)
	for i in 3:
		var p := Vector3(r.randf_range(-hx + 1.0, hx - 1.0), 0.1, r.randf_range(-hz + 0.9, hz - 0.9))
		c.mb.blob(c.m.ash, p, Vector3(r.randf_range(0.7, 1.2), r.randf_range(0.22, 0.4), r.randf_range(0.6, 1.0)), r.randi() % 997, 0.35, 1.2, 6, 10, Basis(), false, 0.2)
		for j in 5:
			var q := p + Vector3(r.randf_range(-0.8, 0.8), 0.2, r.randf_range(-0.6, 0.6))
			c.mb.box(c.m.charred, q, Vector3(r.randf_range(0.5, 1.4), 0.05, r.randf_range(0.12, 0.22)), Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.FORWARD, r.randf_range(-0.3, 0.3)), 0.02)
		for j in 4:
			var q := p + Vector3(r.randf_range(-1.0, 1.0), 0.1, r.randf_range(-0.8, 0.8))
			c.mb.box(c.stone(), q, Vector3(r.randf_range(0.25, 0.45), r.randf_range(0.15, 0.25), r.randf_range(0.2, 0.35)), Basis(Vector3.UP, r.randf() * TAU), 0.04)


## A ridge tent: poles, sagging canvas pegged at the hem, open front flaps, guy ropes, patches.
static func tent(mats: Dictionary, seed_: int) -> Node3D:
	var c := Ctx.new(seed_, mats)
	var r := c.rng
	var cloth: Material = [mats.canvas, mats.canvas_dark, mats.canvas, mats.hide][r.randi() % 4]
	var W := r.randf_range(1.45, 1.65)
	var H := r.randf_range(2.0, 2.25)
	var hl := r.randf_range(1.45, 1.7)
	var pole: Material = mats.oak_grey
	for z: float in [-hl, hl]:
		c.mb.cyl(pole, Vector3(r.randf_range(-0.03, 0.03), -0.15, z), Vector3(0, H + 0.14, z), 0.05, 0.042, 6, 0.08)
	c.mb.cyl(pole, Vector3(0, H + 0.02, -hl - 0.12), Vector3(0, H + 0.02, hl + 0.12), 0.045, 0.045, 6, 0.06, true, 4)
	var nu := 17
	var nv := 9
	var place := func(sgn: float, t: float, z: float, out: float) -> Vector3:
		var zt := (z + hl) / (hl * 2.0)
		var sag := 0.13 * sin(PI * t) * (0.55 + 0.45 * sin(PI * zt))
		var hem := 0.04 + 0.06 * absf(sin(PI * zt * 4.0))
		var base := Vector3(sgn * W, hem, z)
		var ridge := Vector3(0, H + 0.06, z)
		var q := ridge.lerp(base, t)
		var nrm := Vector3(sgn * H, W, 0).normalized()
		return q - nrm * sag + nrm * out
	for sgn: float in [1.0, -1.0]:
		var pts := PackedVector3Array()
		var uvs := PackedVector2Array()
		for j in nv:
			var t := float(j) / (nv - 1)
			for i in nu:
				var z := -hl + hl * 2.0 * i / (nu - 1)
				pts.append(place.call(sgn, t, z, 0.0))
				uvs.append(Vector2(z, t * 2.6))
		sheet(c, cloth, pts, uvs, nu, nv, Vector3(sgn, 1, 0))
		# patches
		for k in r.randi_range(1, 3):
			var t0 := r.randf_range(0.2, 0.7)
			var z0 := r.randf_range(-hl + 0.3, hl - 0.8)
			var dt := r.randf_range(0.12, 0.22)
			var dz := r.randf_range(0.35, 0.6)
			var patch: Material = mats.canvas_dark if cloth != mats.canvas_dark else mats.canvas
			c.mb.quad(patch, place.call(sgn, t0, z0, 0.012), place.call(sgn, t0, z0 + dz, 0.012), place.call(sgn, t0 + dt, z0 + dz, 0.012), place.call(sgn, t0 + dt, z0, 0.012), Vector3(sgn, 1, 0))
		var mid: Vector3 = place.call(sgn, 0.5, 0.0, 0.0)
		c.col(mid, Vector3(sqrt(W * W + H * H), 0.06, hl * 2.0), Basis(Vector3.BACK, atan2(-H, sgn * W)))
		# pegs along the hem
		for i in 5:
			var z := -hl + hl * 2.0 * i / 4.0
			var q: Vector3 = place.call(sgn, 1.0, z, 0.0) + Vector3(sgn * 0.05, 0.02, 0)
			c.mb.box(pole, q, Vector3(0.04, 0.28, 0.04), Basis(Vector3.FORWARD, sgn * 0.35), 0.008)
	# back wall, front flaps tied open
	var back := PackedVector2Array([Vector2(-W, 0.12), Vector2(W, 0.12), Vector2(0, H + 0.04)])
	slab(c, cloth, back, Vector3(0, 0, -hl + 0.01), Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1), 0.02)
	c.col(Vector3(0, H * 0.4, -hl), Vector3(W * 1.6, H * 0.8, 0.08))
	for sgn: float in [1.0, -1.0]:
		var a := Vector3(0, H + 0.04, hl)
		var b := Vector3(sgn * W, 0.12, hl)
		var fold := Vector3(sgn * (W * 0.55), 0.55, hl + 0.18)
		c.mb.tri(cloth, a, b, fold, Vector3(0, 0, 1))
		c.mb.tri(cloth, a, fold, b, Vector3(0, 0, -1))
		c.mb.cyl(mats.rope, fold + Vector3(0, 0.2, 0), fold + Vector3(-sgn * 0.25, 0.32, -0.02), 0.03, 0.03, 5)
	# guy ropes and their pegs
	for zs: float in [-1.0, 1.0]:
		var top := Vector3(0, H + 0.12, zs * (hl + 0.1))
		var peg := Vector3(r.randf_range(-0.2, 0.2), 0.05, zs * (hl + 1.35))
		c.mb.cyl(mats.rope, top, peg, 0.013, 0.013, 4, 0.0, false)
		c.mb.box(pole, peg, Vector3(0.05, 0.32, 0.05), Basis(Vector3.RIGHT, -zs * 0.4), 0.01)
	return finish(c, "Building")


## Mesh (with LODs) + one static body of boxes.
static func finish(c: Ctx, nm: String) -> Node3D:
	var root := Node3D.new()
	root.name = nm
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = Kit.with_lods(c.mb.build())
	root.add_child(mi)
	var body := StaticBody3D.new()
	body.name = "Collision"
	root.add_child(body)
	for bx: Array in c.boxes:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = (bx[1] as Vector3).abs()
		cs.shape = sh
		cs.transform = bx[0]
		body.add_child(cs)
	return root


static func tri_count(n: Node3D) -> int:
	var tris := 0
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := (mi as MeshInstance3D).mesh
		for s in m.get_surface_count():
			tris += m.surface_get_array_len(s) / 3
	return tris
