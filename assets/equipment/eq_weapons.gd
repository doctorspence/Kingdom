extends RefCounted
## Procedural weapon models. Same conventions as the placeholders they replace: built with the
## grip at the origin, blade / shaft pointing up (+Y); blade width along X, thickness along Z.
## Bronze, Iron and Steel share one silhouette per weapon type; the tier changes the metal,
## the blade shape and the fittings (bronze = broad leaf blade and plain bars, iron = straight
## and sturdy, steel = fullered, tapered, finer guards).

const Mesh_ := preload("res://assets/equipment/eq_mesh.gd")
const Kit := preload("res://assets/equipment/eq_kit.gd")

const TIERS := ["bronze", "iron", "steel"]
## Shield design frame (x width, y up, z face-normal) -> held-item frame. Tune here if a shield sits wrong.
const SHIELD_BASIS := Basis(Vector3(0, 1, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0))


static func _root(name: String, mesh: ArrayMesh, tip := Vector3.ZERO) -> Node3D:
	var root := Node3D.new()
	root.name = name
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	root.add_child(mi)
	var t := Marker3D.new()
	t.name = "Tip"
	t.position = tip
	root.add_child(t)
	return root


static func _grip(m, y0: float, y1: float, r: float, mat_leather, mat_cap, wraps := 5) -> void:
	var prof: Array = [[r * 0.8, y0], [r, y0 + 0.004]]
	for i in wraps:
		var y := lerpf(y0, y1, (i + 0.5) / wraps)
		prof.append([r * 0.93, y - (y1 - y0) / wraps * 0.2])
		prof.append([r * 1.07, y])
	prof.append([r, y1 - 0.004])
	prof.append([r * 0.8, y1])
	m.lathe(mat_leather, Transform3D.IDENTITY, prof, 8, true, true)


## Blade loft along +Y from y0. Section is a flat diamond, or a diamond with a fuller groove.
static func _blade(m, mat, y0: float, length: float, w_base: float, w_belly: float, belly_t: float, thick: float, tip_len: float, fuller := false) -> void:
	var rings: Array = []
	var stations := [0.0, belly_t * 0.5, belly_t, 1.0 - tip_len, 1.0]
	for i in stations.size():
		var t: float = stations[i]
		var y := y0 + length * t
		var w: float
		if t <= belly_t:
			w = lerpf(w_base, w_belly, t / maxf(belly_t, 0.001))
		else:
			w = lerpf(w_belly, w_belly * 0.55, (t - belly_t) / maxf(1.0 - tip_len - belly_t, 0.001)) if t < 1.0 - tip_len + 0.001 else lerpf(w_belly * 0.55, 0.0, 1.0)
		if i == stations.size() - 1:
			w = 0.0
		var th := thick * (1.0 if i < stations.size() - 1 else 0.0)
		if i == stations.size() - 2:
			th = thick * 0.7
		var ring := PackedVector3Array()
		if fuller:
			ring.append_array([Vector3(-w, y, 0), Vector3(-w * 0.45, y, th), Vector3(0, y, th * 0.55), Vector3(w * 0.45, y, th),
					Vector3(w, y, 0), Vector3(w * 0.45, y, -th), Vector3(0, y, -th * 0.55), Vector3(-w * 0.45, y, -th)])
		else:
			ring.append_array([Vector3(-w, y, 0), Vector3(0, y, th), Vector3(w, y, 0), Vector3(0, y, -th)])
		rings.append(ring)
	m.loft(mat, rings, false, false, false)


static func _guard(m, tier: String, mat, y: float, width: float, thick: float, depth := 0.035) -> void:
	match tier:
		"bronze":
			m.box(mat, Vector3(0, y, 0), Vector3(width, thick, depth))
		"iron":
			m.box(mat, Vector3(0, y, 0), Vector3(width * 0.55, thick * 1.2, depth))
			for s in [-1, 1]:
				m.box(mat, Vector3(s * width * 0.38, y - thick * 0.2, 0), Vector3(width * 0.3, thick, depth * 0.9), Basis(Vector3.BACK, s * 0.2))
		_:
			# steel: slim bar, quillons curving toward the blade, small ball ends
			m.box(mat, Vector3(0, y, 0), Vector3(width * 0.4, thick * 1.2, depth * 0.9))
			for s in [-1, 1]:
				m.box(mat, Vector3(s * width * 0.3, y + thick * 0.4, 0), Vector3(width * 0.26, thick * 0.9, depth * 0.8), Basis(Vector3.BACK, -s * 0.28))
				m.sphere(mat, Vector3(s * width * 0.5, y + thick * 1.1, 0), thick * 0.75, 6, 4)


static func _pommel(m, tier: String, mat, y: float, size: float) -> void:
	match tier:
		"bronze":
			m.sphere(mat, Vector3(0, y, 0), size, 8, 5)
		"iron":
			m.lathe(mat, Transform3D(Basis.IDENTITY, Vector3(0, y, 0)), [[size * 0.5, -size * 0.9], [size * 1.0, -size * 0.4], [size * 1.0, size * 0.4], [size * 0.5, size * 0.9]], 8, false, true)
		_:
			m.lathe(mat, Transform3D(Basis.IDENTITY, Vector3(0, y, 0)), [[size * 0.35, -size * 0.8], [size * 1.15, -size * 0.35], [size * 1.15, size * 0.2], [size * 0.5, size * 0.55], [size * 0.3, size * 1.0]], 10, true, true)


## kind: "dagger", "sword", "sword2h"
static func sword_like(kind: String, tier: String) -> Node3D:
	var m := Mesh_.new()
	var metal = Kit.get_mat(tier)
	var leather = Kit.get_mat("leather")
	var p: Dictionary
	match kind:
		"dagger": p = {"g0": -0.055, "g1": 0.055, "gr": 0.017, "bl": 0.32, "bw": 0.03, "gw": 0.115, "gt": 0.016, "pom": 0.021}
		"sword": p = {"g0": -0.09, "g1": 0.09, "gr": 0.019, "bl": 0.80, "bw": 0.05, "gw": 0.22, "gt": 0.022, "pom": 0.027}
		_: p = {"g0": -0.20, "g1": 0.13, "gr": 0.02, "bl": 1.12, "bw": 0.062, "gw": 0.32, "gt": 0.026, "pom": 0.032}
	var g1: float = p.g1
	var bl: float = p.bl
	var bw: float = p.bw
	var thick := 0.0085 if kind != "dagger" else 0.0075
	_grip(m, p.g0, g1, p.gr, leather, metal, 4 if kind == "dagger" else (6 if kind == "sword" else 9))
	_pommel(m, tier, metal, p.g0 - p.pom * 0.7, p.pom)
	_guard(m, tier, metal, g1 + p.gt * 0.5, p.gw, p.gt)
	var y0: float = g1 + p.gt
	match tier:
		"bronze": _blade(m, metal, y0, bl, bw * 0.9, bw * 1.2, 0.6, thick * 1.15, 0.2, false)
		"iron": _blade(m, metal, y0, bl, bw, bw * 1.0, 0.3, thick, 0.16, false)
		_: _blade(m, metal, y0, bl, bw * 0.95, bw * 1.0, 0.2, thick * 1.2, 0.2, true)
	if kind == "sword2h":
		# a ricasso wrap and a second leather ring under the guard
		m.lathe(metal, Transform3D(Basis.IDENTITY, Vector3(0, g1 - 0.015, 0)), [[0.022, -0.012], [0.026, 0.0], [0.022, 0.012]], 8, true, true)
	return _root("Weapon_" + kind, m.finish(), Vector3(0, y0 + bl, 0))


static func mace(tier: String) -> Node3D:
	var m := Mesh_.new()
	var metal = Kit.get_mat(tier)
	var wood = Kit.get_mat("wood")
	var leather = Kit.get_mat("leather")
	var hy := 0.58
	m.lathe(wood, Transform3D.IDENTITY, [[0.02, -0.14], [0.026, -0.13], [0.022, 0.0], [0.02, 0.3], [0.024, 0.52], [0.022, hy - 0.05]], 8, true, true)
	_grip(m, -0.1, 0.12, 0.024, leather, metal, 5)
	# pommel cap and head collar
	m.lathe(metal, Transform3D(Basis.IDENTITY, Vector3(0, -0.15, 0)), [[0.02, -0.01], [0.032, 0.0], [0.032, 0.02], [0.02, 0.03]], 8, true, true)
	m.lathe(metal, Transform3D(Basis.IDENTITY, Vector3(0, hy - 0.06, 0)), [[0.028, 0.0], [0.04, 0.012], [0.028, 0.03]], 8, true, true)
	var hr := 0.072 if tier != "steel" else 0.066
	var c := Vector3(0, hy + hr * 0.6, 0)
	m.sphere(metal, c, hr, 12, 8)
	if tier != "bronze":
		m.lathe(metal, Transform3D(Basis.IDENTITY, c), [[hr * 1.04, -0.008], [hr * 1.08, 0.0], [hr * 1.04, 0.008]], 12, true, true)
	var dirs: Array[Vector3] = [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
	if tier != "bronze":
		for sx in [-1, 1]:
			for sz in [-1, 1]:
				dirs.append(Vector3(sx, 0.55, sz).normalized())
				dirs.append(Vector3(sx, -0.55, sz).normalized())
	else:
		for sx in [-1, 1]:
			dirs.append(Vector3(sx, 0.6, 0.6).normalized())
			dirs.append(Vector3(sx, 0.6, -0.6).normalized())
	var spike := 0.052 if tier != "steel" else 0.06
	for d in dirs:
		m.cone(metal, c + d * hr * 0.9, c + d * (hr + spike), 0.016 if tier != "bronze" else 0.02, 5)
	return _root("Weapon_mace_" + tier, m.finish(), c + Vector3.UP * (hr + spike))


static func _heater_outline() -> PackedVector2Array:
	var half := [Vector2(0, 0.31), Vector2(0.12, 0.305), Vector2(0.24, 0.28), Vector2(0.25, 0.2), Vector2(0.245, 0.05),
			Vector2(0.22, -0.08), Vector2(0.17, -0.2), Vector2(0.1, -0.32), Vector2(0, -0.42)]
	var pts := PackedVector2Array()
	for p in half:
		pts.append(p)
	for i in range(half.size() - 2, 0, -1):
		pts.append(Vector2(-half[i].x, half[i].y))
	return pts


static func shield(tier: String) -> Node3D:
	var m := Mesh_.new()
	var metal = Kit.get_mat(tier)
	var wood = Kit.get_mat("wood")
	var leather = Kit.get_mat("leather")
	var face = wood if tier == "bronze" else metal
	var outline := _heater_outline()
	var cen := Vector2(0, -0.03)
	var zb := SHIELD_BASIS
	# design frame -> item frame, with the grip (design z = -0.075) at the origin
	var xf := Transform3D(zb, zb * Vector3(0, 0, 0.075))
	var rings: Array = []
	for lv in [[1.0, -0.035], [1.0, 0.0], [0.86, 0.014], [0.5, 0.034], [0.14, 0.05]]:
		var ring := PackedVector3Array()
		for pt in outline:
			var q: Vector2 = cen + (pt - cen) * lv[0]
			ring.append(xf * Vector3(q.x, q.y, lv[1]))
		rings.append(ring)
	# wooden core always, metal plate over it for iron and steel
	m.loft(wood if tier != "bronze" else wood, rings.slice(0, 2), false, true, false)
	m.loft(face, rings.slice(1), false, false, true)
	# rim: a metal band hugging the edge
	var rw := 0.024
	var secs: Array = []
	for pt in outline:
		var dir: Vector2 = (cen - pt).normalized()
		var inner: Vector2 = pt + dir * rw
		secs.append([xf * Vector3(pt.x, pt.y, -0.045), xf * Vector3(pt.x, pt.y, 0.014), xf * Vector3(inner.x, inner.y, 0.02), xf * Vector3(inner.x, inner.y, -0.045)])
	for i in secs.size():
		var a: Array = secs[i]
		var b: Array = secs[(i + 1) % secs.size()]
		var ins: Vector3 = (a[0] + a[2] + b[0] + b[2]) * 0.25
		for k in 4:
			m.quad(metal, a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k], ins)
	# boss
	m.lathe(metal, Transform3D(zb * Basis(Vector3.RIGHT, PI / 2), zb * Vector3(0, cen.y + 0.04, 0.075 + 0.035)), [[0.08, 0.0], [0.07, 0.012], [0.05, 0.03], [0.0, 0.045]], 10, true, false)
	# bronze: a cross strap on the wooden face; steel: a raised spine and rivets
	if tier == "bronze":
		m.box(metal, xf * Vector3(0, cen.y + 0.04, 0.022), Vector3(0.03, 0.62, 0.012), zb)
		m.box(metal, xf * Vector3(0, cen.y + 0.1, 0.022), Vector3(0.38, 0.03, 0.012), zb)
	elif tier == "steel":
		m.box(metal, xf * Vector3(0, cen.y, 0.046), Vector3(0.026, 0.62, 0.02), zb)
		for pt in [Vector2(0.17, 0.2), Vector2(-0.17, 0.2), Vector2(0.12, -0.12), Vector2(-0.12, -0.12)]:
			m.sphere(metal, xf * Vector3(pt.x, pt.y, 0.03), 0.012, 6, 3)
	else:
		for pt in [Vector2(0.17, 0.2), Vector2(-0.17, 0.2), Vector2(0.12, -0.12), Vector2(-0.12, -0.12)]:
			m.sphere(metal, xf * Vector3(pt.x, pt.y, 0.03), 0.014, 6, 3)
	# back: handle bar and forearm strap
	m.box(wood, xf * Vector3(0, 0.0, -0.055), Vector3(0.03, 0.18, 0.025), zb)
	m.box(leather, xf * Vector3(0, 0.15, -0.058), Vector3(0.05, 0.035, 0.03), zb)
	return _root("Weapon_shield_" + tier, m.finish())


static func bow(tier: String) -> Node3D:
	var m := Mesh_.new()
	var metal = Kit.get_mat(tier)
	var wood = Kit.get_mat("wood")
	var leather = Kit.get_mat("leather")
	var string_mat = Kit.get_mat("cloth_coarse")
	var h := 0.74
	var bend := 0.17
	var rings: Array = []
	var n := 14
	var pts: Array[Vector3] = []
	for i in range(n + 1):
		var y := lerpf(-h, h, float(i) / n)
		var x := bend * pow(y / h, 2.0) * 1.0
		pts.append(Vector3(x, y, 0))
	for i in pts.size():
		var t := absf(pts[i].y) / h
		var w := lerpf(0.022, 0.01, t * t)
		var th := lerpf(0.02, 0.009, t * t)
		var tan := (pts[mini(i + 1, n)] - pts[maxi(i - 1, 0)]).normalized()
		var nr := Vector3(tan.y, -tan.x, 0)
		var c := pts[i]
		rings.append(PackedVector3Array([c + nr * w + Vector3(0, 0, th), c - nr * w + Vector3(0, 0, th), c - nr * w - Vector3(0, 0, th), c + nr * w - Vector3(0, 0, th)]))
	m.loft(wood, rings, true, true, true)
	# leather-wrapped grip and a metal riser plate
	_grip_along_y(m, leather, 0.1, 0.022)
	m.box(metal, Vector3(0, 0.12, 0), Vector3(0.04, 0.03, 0.046))
	m.box(metal, Vector3(0, -0.12, 0), Vector3(0.04, 0.03, 0.046))
	# nocks (tip caps) and string
	for s in [-1, 1]:
		var tip: Vector3 = pts[n] if s > 0 else pts[0]
		m.rod(metal, tip - Vector3(0, s * 0.03, 0), tip + Vector3(0.004, s * 0.02, 0), 0.02, 0.014, 6)
		m.sphere(metal, tip + Vector3(0.004, s * 0.026, 0), 0.016, 6, 4)
	var xs := bend + 0.004
	m.rod(string_mat, Vector3(xs, -h - 0.015, 0), Vector3(xs, h + 0.015, 0), 0.0035, 0.0035, 4)
	if tier == "steel":
		for yy in [0.3, -0.3]:
			m.box(metal, Vector3(bend * pow(yy / h, 2.0), yy, 0), Vector3(0.03, 0.012, 0.03))
	return _root("Weapon_bow_" + tier, m.finish(), Vector3(0, h, 0))


static func _grip_along_y(m, mat, half: float, r: float) -> void:
	m.lathe(mat, Transform3D.IDENTITY, [[r * 0.7, -half], [r, -half + 0.01], [r * 0.92, -half * 0.5], [r * 1.05, 0.0], [r * 0.92, half * 0.5], [r, half - 0.01], [r * 0.7, half]], 8, true, true)


static func staff() -> Node3D:
	var m := Mesh_.new()
	var wood = Kit.get_mat("wood")
	var leather = Kit.get_mat("leather")
	var iron = Kit.get_mat("iron")
	m.lathe(wood, Transform3D.IDENTITY, [[0.026, -0.55], [0.03, -0.5], [0.027, 0.3], [0.025, 0.8], [0.03, 1.15], [0.036, 1.2]], 8, true, true)
	_grip(m, -0.2, 0.12, 0.024, leather, iron, 5)
	# iron ferrule and a collar under the head
	m.lathe(iron, Transform3D(Basis.IDENTITY, Vector3(0, -0.57, 0)), [[0.02, 0.0], [0.03, 0.03], [0.027, 0.08], [0.02, 0.09]], 8, true, true)
	m.lathe(iron, Transform3D(Basis.IDENTITY, Vector3(0, 1.15, 0)), [[0.03, 0.0], [0.04, 0.012], [0.04, 0.03], [0.03, 0.04]], 8, true, true)
	m.sphere(wood, Vector3(0, 1.265, 0), 0.07, 10, 6)
	return _root("Weapon_staff", m.finish(), Vector3(0, 1.3, 0))


static func mystic_staff() -> Node3D:
	var m := Mesh_.new()
	var wood = Kit.get_mat("wood_dark")
	var leather = Kit.get_mat("leather_dark")
	var metal = Kit.get_mat("dark_steel")
	var gem = Kit.get_mat("gem_purple")
	m.lathe(wood, Transform3D.IDENTITY, [[0.025, -0.55], [0.029, -0.5], [0.026, 0.3], [0.024, 0.8], [0.028, 1.1], [0.032, 1.16]], 8, true, true)
	_grip(m, -0.2, 0.12, 0.023, leather, metal, 5)
	m.lathe(metal, Transform3D(Basis.IDENTITY, Vector3(0, -0.57, 0)), [[0.018, 0.0], [0.028, 0.03], [0.024, 0.08], [0.018, 0.09]], 8, true, true)
	m.lathe(metal, Transform3D(Basis.IDENTITY, Vector3(0, 1.1, 0)), [[0.028, 0.0], [0.04, 0.014], [0.04, 0.03], [0.028, 0.044]], 8, true, true)
	# three curved prongs cradle the stone
	var cy := 1.31
	for i in 3:
		var a := TAU * i / 3.0
		var d := Vector3(cos(a), 0, sin(a))
		var pts := [Vector3(0, 1.14, 0) + d * 0.014, Vector3(0, 1.2, 0) + d * 0.05, Vector3(0, 1.27, 0) + d * 0.068, Vector3(0, 1.34, 0) + d * 0.06, Vector3(0, 1.39, 0) + d * 0.03]
		for k in pts.size() - 1:
			m.rod(wood, pts[k], pts[k + 1], 0.012 - k * 0.001, 0.011 - k * 0.001, 6)
	m.lathe(metal, Transform3D(Basis.IDENTITY, Vector3(0, cy - 0.05, 0)), [[0.02, 0.0], [0.03, 0.008], [0.02, 0.02]], 8, true, true)
	# the purple stone: a faceted double cone
	m.lathe(gem, Transform3D(Basis.IDENTITY, Vector3(0, cy, 0)), [[0.0, -0.06], [0.042, -0.016], [0.054, 0.026], [0.034, 0.078], [0.0, 0.11]], 6, false, true)
	return _root("Weapon_mystic_staff", m.finish(), Vector3(0, cy + 0.04, 0))
