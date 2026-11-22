class_name TreeSpecies
extends RefCounted
## The Greenwood's tree library, built in code: English oak (ordinary, ancient
## landmark, dead and stag-headed), European beech, European ash, silver birch
## and English yew. Each species has its own trunk and branch pattern, crown
## shape, bark and leaf texture (both drawn in code, painterly and matched to
## the zone palette), and several variants picked by where a tree stands.
##
## build(kind, index) returns a Dictionary:
##   near:   [bark mesh, leaf mesh or null]   full detail
##   far:    one mesh (main limbs + a few big leaf cards) for distance
##   radius: trunk radius at chest height (for the collider)
##   height: rough height in meters
## Results are cached; every tree of a kind and index shares the same meshes.

const KINDS := {
	"oak": 8, "oak_ancient": 3, "oak_dead": 4, "beech": 5, "ash": 5, "birch": 6, "yew": 4,
}

const BARK_TEX := "res://assets/textures/bark/color.jpg"
const BARK_NRM := "res://assets/textures/bark/normal.jpg"
const BARK_RGH := "res://assets/textures/bark/rough.jpg"

static var _cache := {}
static var _mats := {}


static func count(kind: String) -> int:
	return KINDS.get(kind, 1)


static func build(kind: String, index: int) -> Dictionary:
	var key := "%s%d" % [kind, index]
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key) + 4711
	var p := _params(kind, index, rng)
	var b := _Builder.new()
	b.p = p
	b.rng = rng
	b.grow()
	var out := {
		"near": [b.bark_mesh(_bark_mat(p.bark)), b.leaf_mesh(_leaf_mat(p.leaf), false)],
		"far": b.far_mesh(_bark_mat(p.bark), _leaf_mat(p.leaf)),
		"radius": float(p.trunk_r) * 0.85,
		"height": b.top,
	}
	if out.near[1] == null:
		out.near = [out.near[0]]
	_cache[key] = out
	return out


# ---- Species ------------------------------------------------------------------

static func _params(kind: String, index: int, rng: RandomNumberGenerator) -> Dictionary:
	var p := {
		"bark": "oak", "leaf": "oak", "trunk_h": 3.2, "trunk_r": 0.55, "flare": 1.6, "gnarl": 0.25,
		"lean": 0.25, "stems": 1, "leader": false, "roots": 5, "root_len": 1.6,
		"limbs": 5, "limb_from": 0.85, "limb_to": 1.0, "limb_up": Vector2(0.3, 0.6), "limb_len": Vector2(4.0, 5.5),
		"limb_r": 0.55, "depth": 2, "children": Vector2i(2, 3), "len_falloff": Vector2(0.55, 0.75),
		"bend_up": 0.0, "droop": 0.0, "cluster_r": Vector2(1.7, 2.4), "mid_clusters": true,
		"card_size": Vector2(1.3, 1.9), "card_density": 5.0, "flat": 0.75, "hang": 0.0,
		"leaves": 1.0, "broken": 0.12, "top_cluster": 2.4, "scale": 1.0, "sides": 9,
	}
	match kind:
		"oak":
			# 0-1 young, 2-6 mature, 7 old with a broken limb.
			var age := 0.8 if index < 2 else (1.0 if index < 7 else 1.2)
			p.trunk_h = rng.randf_range(2.6, 3.8) * lerpf(0.9, 1.0, age)
			p.trunk_r = rng.randf_range(0.5, 0.62) * age
			p.limbs = rng.randi_range(4, 6)
			p.limb_len = Vector2(3.8, 5.6) * age
			p.limb_r = 0.55 * age
			p.cluster_r = Vector2(1.7, 2.4) * lerpf(0.85, 1.05, age)
			p.broken = 0.35 if index == 7 else 0.1
			p.scale = age
		"oak_ancient":
			p.trunk_h = rng.randf_range(2.8, 3.4)
			p.trunk_r = rng.randf_range(1.15, 1.35)
			p.flare = 1.5
			p.gnarl = 0.4
			p.roots = 8
			p.root_len = 3.2
			p.limbs = rng.randi_range(5, 7)
			p.limb_from = 0.7
			p.limb_up = Vector2(0.2, 0.55)
			p.limb_len = Vector2(6.5, 8.5)
			p.limb_r = 0.62
			p.cluster_r = Vector2(2.8, 3.6)
			p.children = Vector2i(3, 4)
			p.card_density = 6.5
			p.card_size = Vector2(1.6, 2.2)
			# Old but in full leaf: at most a short snapped stub, never a bare dead limb.
			p.broken = 0.06
			p.top_cluster = 4.2
			p.sides = 12
		"oak_dead":
			p.trunk_h = rng.randf_range(2.8, 3.8)
			p.trunk_r = rng.randf_range(0.5, 0.65)
			p.limbs = rng.randi_range(4, 6)
			p.bark = "oak_dead"
			p.broken = 0.6
			# 0-1 stag-headed (a few living lower clusters), 2-3 quite dead.
			p.leaves = 0.35 if index < 2 else 0.0
			p.top_cluster = 0.0
		"beech":
			p.bark = "beech"
			p.leaf = "beech"
			p.trunk_h = rng.randf_range(7.5, 10.0)
			p.trunk_r = rng.randf_range(0.42, 0.52)
			p.flare = 1.45
			p.gnarl = 0.08
			p.lean = 0.08
			p.roots = 6
			p.root_len = 1.3
			p.leader = true
			p.limbs = rng.randi_range(5, 7)
			p.limb_from = 0.5
			p.limb_to = 1.0
			p.limb_up = Vector2(0.38, 0.68)
			p.limb_len = Vector2(4.8, 6.6)
			p.limb_r = 0.45
			p.cluster_r = Vector2(1.9, 2.5)
			p.card_density = 4.2
			p.flat = 0.55
			p.broken = 0.04
			p.top_cluster = 2.8
			if index == 4:
				p.stems = 2  # a twin-stemmed beech
		"ash":
			p.bark = "ash"
			p.leaf = "ash"
			p.trunk_h = rng.randf_range(6.0, 8.0)
			p.trunk_r = rng.randf_range(0.36, 0.45)
			p.flare = 1.3
			p.gnarl = 0.12
			p.roots = 3
			p.leader = true
			p.limbs = rng.randi_range(5, 7)
			p.limb_from = 0.45
			p.limb_up = Vector2(0.42, 0.72)
			p.limb_len = Vector2(4.6, 6.4)
			p.limb_r = 0.42
			p.bend_up = 0.12
			p.cluster_r = Vector2(1.3, 1.8)
			p.card_density = 3.2  # light, airy crown: sky shows through
			p.card_size = Vector2(1.2, 1.7)
			p.broken = 0.06
			p.top_cluster = 1.8
			if index < 2:
				p.scale = 0.8
		"birch":
			p.bark = "birch"
			p.leaf = "birch"
			p.trunk_h = rng.randf_range(7.5, 10.0)
			p.trunk_r = rng.randf_range(0.16, 0.22)
			p.flare = 1.25
			p.gnarl = 0.1
			p.lean = 0.5 if index == 2 else 0.2
			p.roots = 0
			p.leader = true
			p.limbs = rng.randi_range(7, 10)
			p.limb_from = 0.35
			p.limb_up = Vector2(0.35, 0.7)
			p.limb_len = Vector2(1.8, 3.0)
			p.limb_r = 0.4
			p.depth = 1
			p.children = Vector2i(2, 2)
			p.droop = 0.18
			p.cluster_r = Vector2(1.0, 1.4)
			p.card_size = Vector2(1.0, 1.4)
			p.card_density = 4.0
			p.hang = 0.7
			p.broken = 0.0
			p.top_cluster = 1.3
			p.sides = 7
			if index >= 4:
				p.stems = 3  # a clump of three from one root
			if index == 5:
				p.scale = 0.7
		"yew":
			p.bark = "yew"
			p.leaf = "yew"
			p.trunk_h = rng.randf_range(1.6, 2.4)
			p.trunk_r = rng.randf_range(0.5, 0.7) * (1.4 if index == 3 else 1.0)
			p.flare = 1.5
			p.gnarl = 0.35
			p.stems = 3 if index != 1 else 2
			p.roots = 4
			p.limbs = rng.randi_range(5, 7)
			p.limb_from = 0.3
			p.limb_up = Vector2(0.25, 0.6)
			p.limb_len = Vector2(2.6, 3.6) * (1.3 if index == 3 else 1.0)
			p.limb_r = 0.5
			p.cluster_r = Vector2(1.9, 2.5)
			p.card_size = Vector2(1.7, 2.3)
			p.card_density = 2.8  # dark and dense: you can't see through a yew
			p.depth = 1
			p.flat = 0.6
			p.broken = 0.0
			p.top_cluster = 2.6
	return p


# ---- The builder ----------------------------------------------------------------

class _Builder:
	var p: Dictionary
	var rng: RandomNumberGenerator
	var bark := SurfaceTool.new()
	var far_bark := SurfaceTool.new()
	var clusters: Array = []  # [center, radius, living]
	var top := 0.0

	func grow() -> void:
		bark.begin(Mesh.PRIMITIVE_TRIANGLES)
		far_bark.begin(Mesh.PRIMITIVE_TRIANGLES)
		var s: float = p.scale
		var stems: int = p.stems
		for k in stems:
			var base := Vector3.ZERO
			var tilt := Vector3.ZERO
			if stems > 1:
				var a := TAU * k / stems + rng.randf_range(-0.3, 0.3)
				base = Vector3(cos(a), 0.0, sin(a)) * float(p.trunk_r) * s * 0.7
				tilt = Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.12, 0.22)
			_trunk(base, tilt, s * (1.0 if k == 0 else rng.randf_range(0.75, 0.9)), stems > 1)
		if int(p.roots) > 0:
			_roots(s)

	func _trunk(base: Vector3, tilt: Vector3, s: float, multi: bool) -> void:
		var h: float = float(p.trunk_h) * s
		var r0: float = float(p.trunk_r) * s * (0.7 if multi else 1.0)
		var lean := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * float(p.lean) + Vector2(tilt.x, tilt.z) * h
		var steps := 7
		var pts := PackedVector3Array()
		var rad := PackedFloat32Array()
		var wander := Vector2.ZERO
		for i in steps + 1:
			var t := float(i) / steps
			wander += Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * float(p.gnarl) * 0.18
			var off := lean * t * t + wander * t
			pts.append(base + Vector3(off.x, t * h, off.y))
			var r := lerpf(r0, r0 * (0.62 if p.leader else 0.72), sqrt(t))
			if i == 0:
				r = r0 * float(p.flare)
			elif i == 1:
				r = r0 * lerpf(1.0, float(p.flare), 0.35)
			rad.append(r)
		var leader_end := pts[steps]
		if p.leader:
			# The stem keeps going up through the crown, thinning.
			var lp := PackedVector3Array([pts[steps]])
			var lr := PackedFloat32Array([rad[steps]])
			var d := (pts[steps] - pts[steps - 1]).normalized()
			var pos := pts[steps]
			var extra := h * 0.55
			for i in 4:
				d = (d + Vector3(rng.randf_range(-0.1, 0.1), 0.15, rng.randf_range(-0.1, 0.1))).normalized()
				pos += d * extra / 4.0
				lp.append(pos)
				lr.append(lerpf(rad[steps], 0.04, float(i + 1) / 4.0))
			_tube(lp, lr, int(p.sides) - 2, 0)
			leader_end = pos
		_tube(pts, rad, int(p.sides), 0)
		top = maxf(top, leader_end.y)
		# Limbs from the upper trunk (and the leader).
		var limbs: int = p.limbs
		var off_a := rng.randf() * TAU
		for l in limbs:
			var t := lerpf(float(p.limb_from), float(p.limb_to), (float(l) + rng.randf()) / limbs)
			var start := _along(pts, t)
			var r_at := r0 * 0.7
			if p.leader:
				# Spread up the stem and its continuation through the crown.
				r_at = r0 * 0.6
				if t < 0.85:
					start = _along(pts, t / 0.85)
				else:
					start = pts[steps].lerp(leader_end, minf((t - 0.85) / 0.15, 1.0) * 0.8)
			var a := off_a + TAU * l / limbs * 1.618 + rng.randf_range(-0.4, 0.4)
			var up := rng.randf_range(float(p.limb_up.x), float(p.limb_up.y))
			var dir := Vector3(cos(a) * (1.0 - up), up, sin(a) * (1.0 - up)).normalized()
			var length := rng.randf_range(float(p.limb_len.x), float(p.limb_len.y)) * s
			_branch(start, dir, length, r_at * float(p.limb_r) * 1.6, 0)
		if float(p.top_cluster) > 0.0 and float(p.leaves) > 0.99:
			clusters.append([leader_end + Vector3.UP * float(p.top_cluster) * 0.7 * s, float(p.top_cluster) * s, true])

	func _along(pts: PackedVector3Array, t: float) -> Vector3:
		var f := clampf(t, 0.0, 1.0) * (pts.size() - 1)
		var i := mini(int(f), pts.size() - 2)
		return pts[i].lerp(pts[i + 1], f - i)

	func _branch(start: Vector3, dir: Vector3, length: float, radius: float, depth: int) -> void:
		var segs := 5 if depth == 0 else 4
		var pts := PackedVector3Array()
		var rad := PackedFloat32Array()
		var pos := start
		var d := dir
		var broken: bool = rng.randf() < float(p.broken) and depth <= 1
		var use_len := length * (rng.randf_range(0.35, 0.6) if broken else 1.0)
		for sgi in segs + 1:
			pts.append(pos)
			rad.append(lerpf(radius, radius * (0.55 if broken else 0.4), float(sgi) / segs))
			d = (d + Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.5, 0.4), rng.randf_range(-1, 1)) * float(p.gnarl)).normalized()
			d.y += float(p.bend_up) - float(p.droop) * depth
			if pos.y < 1.2:
				d.y = maxf(d.y, 0.35)  # limbs never dive into the ground
			d = d.normalized()
			pos += d * use_len / segs
		_tube(pts, rad, maxi(4, int(p.sides) - 3 - depth * 2), depth)
		top = maxf(top, pos.y)
		var end := pts[segs]
		var sz: float = p.scale
		if broken:
			# A snapped-off limb: no leaves at the end, maybe a few lower down.
			if float(p.leaves) > 0.0 and p.mid_clusters and rng.randf() < 0.5:
				_cluster(pts[2] + Vector3.UP * 0.5, rng.randf_range(1.1, 1.5) * sz)
			return
		if depth >= int(p.depth):
			_cluster(end + Vector3.UP * 0.35, rng.randf_range(float(p.cluster_r.x), float(p.cluster_r.y)) * sz)
			return
		var kids := rng.randi_range(int(p.children.x), int(p.children.y))
		for k in kids:
			var nd := (d + Vector3(rng.randf_range(-0.8, 0.8), rng.randf_range(-0.1, 0.5), rng.randf_range(-0.8, 0.8))).normalized()
			var from := end if k == 0 else pts[rng.randi_range(2, segs - 1)]
			_branch(from, nd, use_len * rng.randf_range(float(p.len_falloff.x), float(p.len_falloff.y)), radius * 0.5, depth + 1)
		if p.mid_clusters:
			_cluster(pts[2] + Vector3.UP * 0.7, rng.randf_range(float(p.cluster_r.x), float(p.cluster_r.y)) * 0.75 * sz)

	func _cluster(c: Vector3, r: float) -> void:
		var living := rng.randf() < float(p.leaves)
		if float(p.leaves) < 0.99 and c.y > top * 0.7:
			living = false  # stag-headed: the crown top is dead
		if living:
			clusters.append([c, r, true])

	func _roots(s: float) -> void:
		var n: int = p.roots
		var r0: float = float(p.trunk_r) * s
		for i in n:
			var a := TAU * i / n + rng.randf_range(-0.3, 0.3)
			var out := Vector3(cos(a), 0.0, sin(a))
			var length := float(p.root_len) * s * rng.randf_range(0.7, 1.2)
			var pts := PackedVector3Array([out * r0 * 0.5 + Vector3.UP * r0 * 0.9, out * (r0 + length * 0.35) + Vector3.UP * 0.15,
					out * (r0 + length * 0.7) + Vector3.DOWN * 0.05, out * (r0 + length) + Vector3.DOWN * 0.3])
			var rad := PackedFloat32Array([r0 * 0.45, r0 * 0.3, r0 * 0.18, r0 * 0.06])
			_tube(pts, rad, 6, 1)

	## A tube along a path, thick to thin. Depth-0 tubes also go into the far mesh.
	func _tube(points: PackedVector3Array, radii: PackedFloat32Array, sides: int, depth: int) -> void:
		_tube_into(bark, points, radii, sides)
		if depth == 0:
			_tube_into(far_bark, points, radii, 5)

	func _tube_into(st: SurfaceTool, points: PackedVector3Array, radii: PackedFloat32Array, sides: int) -> void:
		var rings: Array = []
		for i in points.size():
			var dir := (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
			var side := dir.cross(Vector3.RIGHT if absf(dir.x) < 0.9 else Vector3.FORWARD).normalized()
			var up := dir.cross(side).normalized()
			var ring: Array[Vector3] = []
			for sd in sides:
				var a := TAU * sd / sides
				# A little irregular: real trunks are never round.
				var bump := 1.0 + 0.08 * sin(a * 3.0 + i * 1.7)
				ring.append(points[i] + (side * cos(a) + up * sin(a)) * radii[i] * bump)
			rings.append(ring)
		for i in points.size() - 1:
			for sd in sides:
				var s2 := (sd + 1) % sides
				var axis := points[i].lerp(points[i + 1], 0.5)
				_tri(st, rings[i][sd], rings[i][s2], rings[i + 1][s2], axis)
				_tri(st, rings[i][sd], rings[i + 1][s2], rings[i + 1][sd], axis)

	func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
		var n := (b - a).cross(c - a)
		if n.dot((a + b + c) / 3.0 - inside) > 0.0:
			var t := b
			b = c
			c = t
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)

	func bark_mesh(mat: Material) -> ArrayMesh:
		bark.generate_normals()
		bark.set_material(mat)
		return bark.commit()

	## Leaf cards: each cluster is a squashed ball of crossed cards. Cards deep in
	## the crown are darker (light can't reach them), the top is lighter, and the
	## normals bend out from the crown so it shades as one soft mass.
	func leaf_mesh(mat: Material, far: bool) -> ArrayMesh:
		if clusters.is_empty():
			return null
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var crown := Vector3.ZERO
		var lo := INF
		var hi := -INF
		for c in clusters:
			crown += c[0]
			lo = minf(lo, (c[0] as Vector3).y - float(c[1]))
			hi = maxf(hi, (c[0] as Vector3).y + float(c[1]))
		crown /= clusters.size()
		var reach := 0.0
		for c in clusters:
			reach = maxf(reach, Vector2((c[0] as Vector3).x - crown.x, (c[0] as Vector3).z - crown.z).length() + float(c[1]))
		var lrng := RandomNumberGenerator.new()
		lrng.seed = rng.seed + (99 if far else 7)
		for c in clusters:
			var center: Vector3 = c[0]
			var r: float = c[1]
			var cards := int(r * r * float(p.card_density) * (0.22 if far else 1.0)) + (2 if far else 5)
			for k in cards:
				var u := Vector3(lrng.randf_range(-1, 1), lrng.randf_range(-0.8, 1), lrng.randf_range(-1, 1)).normalized()
				var pos := center + Vector3(u.x, u.y * float(p.flat), u.z) * r * lrng.randf_range(0.35, 1.0)
				var size := lrng.randf_range(float(p.card_size.x), float(p.card_size.y)) * (1.9 if far else 1.0) * float(p.scale) * 0.5 + 0.35
				var n := Vector3(lrng.randf_range(-1, 1), lrng.randf_range(-1, 1), lrng.randf_range(-1, 1)).normalized()
				var s1 := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
				var s2 := n.cross(s1).normalized()
				var h1 := s1 * size * 0.5
				var h2 := s2 * size * 0.5
				if float(p.hang) > 0.0 and lrng.randf() < float(p.hang):
					# Hanging twigs (birch): tall narrow cards with their top at the cluster.
					s1 = Vector3(lrng.randf_range(-1, 1), 0.0, lrng.randf_range(-1, 1)).normalized()
					h1 = s1 * size * 0.32
					h2 = Vector3.DOWN * size * 0.75
					pos += Vector3.DOWN * size * 0.35
				var out := Vector3(pos.x - crown.x, (pos.y - crown.y) * 0.6, pos.z - crown.z)
				var light_n := (out.normalized() + Vector3.UP * 0.7).normalized()
				# Self-shadowing: inner and lower cards darker, top and outer lighter.
				var outer := clampf(Vector2(out.x, out.z).length() / maxf(reach, 0.1), 0.0, 1.0)
				var height := clampf((pos.y - lo) / maxf(hi - lo, 0.1), 0.0, 1.0)
				var ao := clampf(0.62 + 0.25 * outer + 0.3 * height, 0.6, 1.15)
				var tint := Color(1, 1, 1).lerp(Color(0.85, 0.9, 0.72), lrng.randf()) * ao
				tint.a = 1.0
				var corners := [pos - h1 - h2, pos + h1 - h2, pos + h1 + h2, pos - h1 + h2]
				var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
				for idx in [0, 1, 2, 0, 2, 3]:
					st.set_normal(light_n)
					st.set_color(tint)
					st.set_uv(uvs[idx])
					st.add_vertex(corners[idx])
		st.set_material(mat)
		return st.commit()

	func far_mesh(bark_mat: Material, leaf_mat: Material) -> ArrayMesh:
		far_bark.generate_normals()
		far_bark.set_material(bark_mat)
		var m := far_bark.commit()
		var leaves := leaf_mesh(leaf_mat, true)
		if leaves:
			m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, leaves.surface_get_arrays(0))
			m.surface_set_material(m.get_surface_count() - 1, leaf_mat)
		return m


# ---- Materials ----------------------------------------------------------------------

static func _bark_mat(kind: String) -> StandardMaterial3D:
	var key := "bark_" + kind
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.7, 0.7, 0.7)
	m.metallic_specular = 0.15
	m.roughness = 0.95
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.normal_enabled = true
	m.normal_texture = load(BARK_NRM)
	match kind:
		"oak":  # deep fissured brown-grey
			m.albedo_texture = load(BARK_TEX)
			m.roughness_texture = load(BARK_RGH)
			m.albedo_color = Color(0.5, 0.46, 0.4)
			m.normal_scale = 1.4
		"oak_dead":  # weathered silver-grey wood
			m.albedo_texture = load(BARK_TEX)
			m.albedo_color = Color(0.62, 0.6, 0.56)
			m.normal_scale = 1.6
		"ash":  # pale grey, finer
			m.albedo_texture = load(BARK_TEX)
			m.albedo_color = Color(0.62, 0.62, 0.58)
			m.uv1_scale = Vector3(1.1, 0.9, 1.1)
			m.normal_scale = 0.9
		"yew":  # reddish, flaky
			m.albedo_texture = load(BARK_TEX)
			m.albedo_color = Color(0.62, 0.42, 0.33)
			m.normal_scale = 1.2
		"beech":  # smooth grey with lichen mottling
			m.albedo_texture = _beech_tex()
			m.albedo_color = Color(1, 1, 1)
			m.uv1_scale = Vector3(0.35, 0.35, 0.35)
			m.normal_scale = 0.4
		"birch":  # white with dark marks
			m.albedo_texture = _birch_tex()
			m.albedo_color = Color(1, 1, 1)
			m.uv1_scale = Vector3(0.5, 0.5, 0.5)
			m.normal_scale = 0.3
	_mats[key] = m
	return m


static func _beech_tex() -> ImageTexture:
	var w := 256
	var img := Image.create(w, w, true, Image.FORMAT_RGBA8)
	var n := FastNoiseLite.new()
	n.seed = 31
	n.frequency = 0.03
	var n2 := FastNoiseLite.new()
	n2.seed = 32
	n2.frequency = 0.12
	for y in w:
		for x in w:
			var v := n.get_noise_2d(x, y * 0.6) * 0.5 + 0.5
			var f := n2.get_noise_2d(x, y) * 0.5 + 0.5
			var c := Color(0.26, 0.27, 0.25).lerp(Color(0.38, 0.38, 0.35), v)
			if f > 0.68:
				c = c.lerp(Color(0.45, 0.52, 0.38), (f - 0.68) * 2.0)  # green lichen
			if f < 0.22:
				c = c.lerp(Color(0.3, 0.31, 0.3), (0.22 - f) * 2.5)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _birch_tex() -> ImageTexture:
	var w := 256
	var img := Image.create(w, w, true, Image.FORMAT_RGBA8)
	var n := FastNoiseLite.new()
	n.seed = 41
	n.frequency = 0.02
	for y in w:
		for x in w:
			var v := n.get_noise_2d(x * 0.5, y * 2.0) * 0.5 + 0.5
			img.set_pixel(x, y, Color(0.8, 0.78, 0.72).lerp(Color(0.92, 0.9, 0.85), v))
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	# Dark horizontal lenticel dashes.
	for i in 260:
		var cx := rng.randi() % w
		var cy := rng.randi() % w
		var length := rng.randi_range(4, 18)
		var col := Color(0.2, 0.18, 0.16).lerp(Color(0.45, 0.42, 0.38), rng.randf())
		for dx in length:
			for dy in rng.randi_range(1, 2):
				img.set_pixel((cx + dx) % w, (cy + dy) % w, col)
	# Black diamond scars and patches.
	for i in 14:
		var cx := rng.randi() % w
		var cy := rng.randi() % w
		var rx := rng.randi_range(5, 16)
		var ry := rng.randi_range(4, 10)
		for dy in range(-ry, ry + 1):
			for dx in range(-rx, rx + 1):
				if absf(float(dx) / rx) + absf(float(dy) / ry) <= 1.0 + rng.randf_range(-0.15, 0.1):
					img.set_pixel((cx + dx + w) % w, (cy + dy + w) % w, Color(0.1, 0.09, 0.09))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _leaf_mat(kind: String) -> StandardMaterial3D:
	var key := "leaf_" + kind
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = _leaf_tex(kind)
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.45
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.85 if kind != "beech" else 0.65
	m.metallic_specular = 0.2
	# Sun through the leaves: the lit side glows a little from behind.
	m.backlight_enabled = kind != "yew"
	m.backlight = Color(0.22, 0.26, 0.1)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
	# Low, dense yews fade out sooner so the camera never sits inside a black ball of needles.
	m.distance_fade_min_distance = 1.4 if kind == "yew" else 0.7
	m.distance_fade_max_distance = 3.6 if kind == "yew" else 2.4
	_mats[key] = m
	return m


## A cluster of leaves on a see-through card, drawn once per species.
## Colors from the brief: forest green #465A40, oak green #64734D, moss #89916A,
## deep woodland #354536, with selective saturation (beech and birch a touch fresher).
static func _leaf_tex(kind: String) -> ImageTexture:
	var w := 256
	var img := Image.create(w, w, true, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	var dark := Color(0.2, 0.27, 0.17)
	var light := Color(0.42, 0.48, 0.29)
	var count := 200
	var length := Vector2(12, 18)
	match kind:
		"beech":
			dark = Color(0.22, 0.31, 0.14)
			light = Color(0.46, 0.55, 0.26)
			count = 230
			length = Vector2(10, 15)
		"ash":
			dark = Color(0.25, 0.32, 0.18)
			light = Color(0.45, 0.52, 0.3)
			count = 34
		"birch":
			dark = Color(0.3, 0.37, 0.16)
			light = Color(0.55, 0.6, 0.3)
			count = 260
			length = Vector2(6, 9)
		"yew":
			dark = Color(0.08, 0.13, 0.08)
			light = Color(0.18, 0.26, 0.15)
			count = 26
		"oak":
			pass
	for i in count:
		var ang := rng.randf() * TAU
		var dist := pow(rng.randf(), 0.7) * w * 0.4
		var cx := w * 0.5 + cos(ang) * dist
		var cy := w * 0.5 + sin(ang) * dist
		var rot := rng.randf() * TAU
		var col := dark.lerp(light, rng.randf())
		if kind == "oak" and rng.randf() < 0.1:
			col = col.lerp(Color(0.45, 0.4, 0.18), 0.4)  # an odd yellowing leaf
		match kind:
			"ash":
				_pinnate(img, Vector2(cx, cy), rot, rng.randf_range(40, 60), col, rng, 7.0, 2.2, false)
			"yew":
				_pinnate(img, Vector2(cx, cy), rot, rng.randf_range(45, 70), col, rng, 5.0, 1.1, true)
			_:
				_leaf(img, Vector2(cx, cy), rot, rng.randf_range(length.x, length.y), col, kind)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## One leaf. t runs from -1 (stalk) to 1 (tip); the half-width at t gives the outline.
static func _leaf(img: Image, c: Vector2, rot: float, length: float, col: Color, kind: String) -> void:
	var w := img.get_width()
	var cr := cos(rot)
	var sr := sin(rot)
	var width := length * (0.55 if kind == "oak" else (0.5 if kind == "beech" else 0.62))
	for py in range(int(c.y - length), int(c.y + length) + 1):
		for px in range(int(c.x - length), int(c.x + length) + 1):
			if px < 0 or py < 0 or px >= w or py >= w:
				continue
			var dx := px - c.x
			var dy := py - c.y
			var t := (dx * cr + dy * sr) / length
			var s := absf(-dx * sr + dy * cr) / width
			if absf(t) > 1.0:
				continue
			var hw := 0.0
			match kind:
				"oak":  # rounded lobes, narrow at the stalk
					hw = sqrt(maxf(0.0, 1.0 - t * t)) * (0.55 + 0.45 * absf(sin((t + 1.0) * PI * 2.2))) * (0.6 + 0.4 * smoothstep(-1.0, -0.4, t))
				"beech":  # oval with a point, a wavy edge
					hw = sqrt(maxf(0.0, 1.0 - t * t)) * (1.0 - 0.35 * maxf(0.0, t)) * (0.94 + 0.06 * sin(t * 18.0))
				_:  # birch: small, triangular, toothed
					hw = (1.0 - absf(t + 0.25) / 1.25) * (0.9 + 0.1 * sin(t * 30.0))
			if s <= hw:
				var shade := 1.0 - (s / maxf(hw, 0.01)) * 0.3 + (0.1 if s < 0.06 else 0.0)  # lighter middle vein
				img.set_pixel(px, py, Color(col.r * shade, col.g * shade, col.b * shade, 1.0))


## A stalk with paired leaflets (ash) or flat needles (yew).
static func _pinnate(img: Image, c: Vector2, rot: float, length: float, col: Color, rng: RandomNumberGenerator, leaflet: float, thin: float, needles: bool) -> void:
	var dir := Vector2(cos(rot), sin(rot))
	var side := dir.orthogonal()
	var w := img.get_width()
	var steps := int(length)
	var stem := col.darkened(0.35)
	for i in steps:
		var p := c + dir * (i - length * 0.5)
		if p.x >= 0 and p.y >= 0 and p.x < w and p.y < w:
			img.set_pixel(int(p.x), int(p.y), stem)
	var gap := 2.5 if needles else 9.0
	var k := 0.0
	while k < length:
		var base := c + dir * (k - length * 0.5)
		var ll := leaflet * (1.0 - 0.4 * absf(k / length - 0.5)) * (1.5 if not needles else 1.0)
		for sgn: float in [-1.0, 1.0]:
			var ld := (side * sgn + dir * (0.35 if not needles else 0.15)).normalized()
			var shade := rng.randf_range(0.85, 1.1)
			for s in int(ll * 1.6):
				var t := float(s) / (ll * 1.6)
				var half := thin * sin(t * PI) * (1.8 if not needles else 1.0)
				var q := base + ld * s
				for o in range(-int(ceil(half)), int(ceil(half)) + 1):
					var qq := q + dir * o
					if qq.x >= 0 and qq.y >= 0 and qq.x < w and qq.y < w:
						img.set_pixel(int(qq.x), int(qq.y), Color(col.r * shade, col.g * shade, col.b * shade, 1.0))
		k += gap
