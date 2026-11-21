extends RefCounted
## Shared base of the bandit-hideout asset library (units are meters).
##
## Materials: PBR (color / normal / roughness / metallic) built from the project's textures.
## MB: a small mesh builder. Each asset is ONE ArrayMesh with a surface per material, UVs in
## meters (so one texture density fits every asset), generated tangents for normal maps.
## Every asset script returns a Node3D: Mesh (MeshInstance3D) + Collision (StaticBody3D).

const WOOD_TRES := "res://levels/common/materials/wood.tres"
const STONE_TRES := "res://levels/common/materials/dark_stone.tres"
const CLOTH_TRES := "res://levels/common/materials/canvas.tres"
const FLICKER := preload("res://assets/hideout/Materials/flicker.gd")

static var _cache := {}


# ---------------------------------------------------------------- materials

static func wood(kind := "aged") -> StandardMaterial3D:
	var key := "wood_" + kind
	if _cache.has(key):
		return _cache[key]
	var m := (load(WOOD_TRES) as StandardMaterial3D).duplicate() as StandardMaterial3D
	m.uv1_triplanar = false
	m.uv1_scale = Vector3(0.55, 0.55, 0.55)
	match kind:
		"aged": m.albedo_color = Color(1.4, 1.2, 1.02)
		"dark": m.albedo_color = Color(0.9, 0.78, 0.68)
		"grey": m.albedo_color = Color(1.4, 1.34, 1.28)
		"fresh": m.albedo_color = Color(1.95, 1.62, 1.25)
		"burnt": m.albedo_color = Color(0.3, 0.27, 0.25)
	_cache[key] = m
	return m


static func iron() -> StandardMaterial3D:
	if _cache.has("iron"):
		return _cache["iron"]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1, 1, 1)
	m.metallic = 0.8
	m.metallic_specular = 0.5
	m.roughness = 0.62
	# Dark iron blotched with rust.
	var n := FastNoiseLite.new()
	n.frequency = 0.018
	n.fractal_octaves = 4
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.35, 0.7])
	g.colors = PackedColorArray([Color(0.16, 0.15, 0.14), Color(0.3, 0.18, 0.11)])
	var t := NoiseTexture2D.new()
	t.noise = n
	t.seamless = true
	t.width = 256
	t.height = 256
	t.color_ramp = g
	m.albedo_texture = t
	m.uv1_scale = Vector3(1.5, 1.5, 1.5)
	_cache["iron"] = m
	return m


static func stone(kind := "rock") -> StandardMaterial3D:
	var key := "stone_" + kind
	if _cache.has(key):
		return _cache[key]
	var m := (load(STONE_TRES) as StandardMaterial3D).duplicate() as StandardMaterial3D
	match kind:
		"rock": m.albedo_color = Color(0.85, 0.8, 0.75)
		"wet":
			m.albedo_color = Color(0.85, 0.82, 0.78)
			m.roughness = 0.55
			m.metallic_specular = 0.4
		"ore":
			m.albedo_color = Color(0.9, 0.55, 0.42)
		"dark": m.albedo_color = Color(0.7, 0.67, 0.64)
	_cache[key] = m
	return m


static func dirt() -> StandardMaterial3D:
	if _cache.has("dirt"):
		return _cache["dirt"]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/scree/color.jpg")
	m.normal_enabled = true
	m.normal_texture = load("res://assets/textures/scree/normal.jpg")
	m.roughness_texture = load("res://assets/textures/scree/rough.jpg")
	m.albedo_color = Color(0.62, 0.55, 0.5)
	m.uv1_scale = Vector3(0.45, 0.45, 0.45)
	m.uv1_triplanar = true
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache["dirt"] = m
	return m


static func cloth(kind := "burlap") -> StandardMaterial3D:
	var key := "cloth_" + kind
	if _cache.has(key):
		return _cache[key]
	var m := (load(CLOTH_TRES) as StandardMaterial3D).duplicate() as StandardMaterial3D
	m.uv1_scale = Vector3(1.6, 1.6, 1.6)
	m.roughness = 1.0
	match kind:
		"burlap": m.albedo_color = Color(0.55, 0.42, 0.27)
		"grain": m.albedo_color = Color(0.5, 0.44, 0.33)
		"wool": m.albedo_color = Color(0.26, 0.16, 0.12)
		"straw": m.albedo_color = Color(0.42, 0.35, 0.2)
	_cache[key] = m
	return m


static func rope() -> StandardMaterial3D:
	if _cache.has("rope"):
		return _cache["rope"]
	var m := cloth("burlap").duplicate() as StandardMaterial3D
	m.albedo_color = Color(0.62, 0.5, 0.32)
	_cache["rope"] = m
	return m


static func plain(color: Color, rough := 0.9, metal := 0.0) -> StandardMaterial3D:
	var key := "plain_%s_%s_%s" % [color, rough, metal]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	_cache[key] = m
	return m


static func ember() -> StandardMaterial3D:
	if _cache.has("ember"):
		return _cache["ember"]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.25, 0.08, 0.03)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.38, 0.08)
	m.emission_energy_multiplier = 2.2
	_cache["ember"] = m
	return m


static func water() -> StandardMaterial3D:
	if _cache.has("water"):
		return _cache["water"]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.05, 0.08, 0.09)
	m.emission_enabled = true
	m.emission = Color(0.03, 0.06, 0.07)
	m.roughness = 0.04
	m.metallic_specular = 1.0
	_cache["water"] = m
	return m


# ---------------------------------------------------------------- helpers

## A basis whose local X axis points along dir (long boxes between two points).
static func basis_x(dir: Vector3) -> Basis:
	var x := dir.normalized()
	var z := x.cross(Vector3.UP)
	if z.length() < 0.01:
		z = x.cross(Vector3.RIGHT)
	z = z.normalized()
	return Basis(x, z.cross(x), z)


## A basis whose local Y axis points along dir (cylinders between two points).
static func basis_y(dir: Vector3) -> Basis:
	var y := dir.normalized()
	var x := Vector3.UP.cross(y)
	if x.length() < 0.01:
		x = Vector3.RIGHT.cross(y)
	x = x.normalized()
	return Basis(x, y, x.cross(y))


## Wraps a builder into the standard asset node: Mesh + Collision.
## collide: "convex" (props), "trimesh" (walkable / concave), "aabb" (box), "none".
static func asset(nm: String, b: MB, collide := "convex") -> Node3D:
	var root := Node3D.new()
	root.name = nm
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = b.build()
	var tris := 0
	for s in mi.mesh.get_surface_count():
		tris += mi.mesh.surface_get_array_len(s) / 3
	if tris > 2500:
		mi.mesh = with_lods(mi.mesh)
	root.add_child(mi)
	if collide != "none":
		var body := StaticBody3D.new()
		body.name = "Collision"
		var cs := CollisionShape3D.new()
		match collide:
			"trimesh": cs.shape = mi.mesh.create_trimesh_shape()
			"aabb":
				var bs := BoxShape3D.new()
				bs.size = mi.mesh.get_aabb().size
				cs.shape = bs
				cs.position = mi.mesh.get_aabb().get_center()
			_: cs.shape = mi.mesh.create_convex_shape(true, true)
		body.add_child(cs)
		root.add_child(body)
	return root


## Adds automatic LODs (meshoptimizer) to a built mesh; used for assets above ~2500 triangles.
static func with_lods(mesh: ArrayMesh) -> ArrayMesh:
	var im := ImporterMesh.new()
	for s in mesh.get_surface_count():
		im.add_surface(Mesh.PRIMITIVE_TRIANGLES, mesh.surface_get_arrays(s), [], {}, mesh.surface_get_material(s))
	im.generate_lods(25.0, 0.0, [])
	return im.get_mesh()


static func _soft_tex() -> Texture2D:
	if _cache.has("soft"):
		return _cache["soft"]
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	_cache["soft"] = t
	return t


static func _ramp(cols: Array, offs: Array) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offs)
	g.colors = PackedColorArray(cols)
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


static func _curve(pts: Array) -> CurveTexture:
	var c := Curve.new()
	for p in pts:
		c.add_point(p)
	var t := CurveTexture.new()
	t.curve = c
	return t


static func _emitter(parent: Node3D, pos: Vector3, amount: int, life: float, pm: ParticleProcessMaterial,
		quad: Vector2, tint_additive: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.position = pos
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.process_material = pm
	p.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 8, 6))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if tint_additive else BaseMaterial3D.BLEND_MODE_MIX
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _soft_tex()
	mat.disable_receive_shadows = true
	var qm := QuadMesh.new()
	qm.size = quad
	qm.material = mat
	p.draw_pass_1 = qm
	parent.add_child(p)
	return p


## Flame, rising sparks and smoke, plus a flickering warm light. size ~1 = campfire.
static func fire_fx(parent: Node3D, pos: Vector3, size := 1.0, light_energy := 3.0, shadows := true) -> void:
	var fl := ParticleProcessMaterial.new()
	fl.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	fl.emission_sphere_radius = 0.13 * size
	fl.direction = Vector3.UP
	fl.spread = 10.0
	fl.initial_velocity_min = 0.35 * size
	fl.initial_velocity_max = 0.8 * size
	fl.gravity = Vector3(0, 0.5, 0)
	fl.scale_min = 0.7
	fl.scale_max = 1.2
	fl.scale_curve = _curve([Vector2(0, 0.55), Vector2(0.25, 1.0), Vector2(1, 0.0)])
	fl.color_ramp = _ramp([Color(1.0, 0.6, 0.2, 0.0), Color(1.0, 0.5, 0.12, 0.34), Color(0.9, 0.3, 0.05, 0.3), Color(0.4, 0.08, 0.02, 0.0)],
		[0.0, 0.15, 0.6, 1.0])
	fl.turbulence_enabled = true
	fl.turbulence_noise_strength = 0.4
	_emitter(parent, pos, int(12.0 + 22.0 * size), 0.85, fl, Vector2(0.34, 0.55) * size, true)

	var sp := ParticleProcessMaterial.new()
	sp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	sp.emission_sphere_radius = 0.15 * size
	sp.direction = Vector3.UP
	sp.spread = 35.0
	sp.initial_velocity_min = 0.7 * size
	sp.initial_velocity_max = 1.7 * size
	sp.gravity = Vector3(0, -0.15, 0)
	sp.scale_min = 0.5
	sp.scale_max = 1.0
	sp.turbulence_enabled = true
	sp.turbulence_noise_strength = 0.8
	sp.color_ramp = _ramp([Color(1.0, 0.7, 0.25, 1.0), Color(1.0, 0.4, 0.1, 0.8), Color(0.8, 0.2, 0.05, 0.0)], [0.0, 0.5, 1.0])
	_emitter(parent, pos + Vector3(0, 0.15 * size, 0), 18, 2.4, sp, Vector2(0.025, 0.025) * size, true)

	var sm := ParticleProcessMaterial.new()
	sm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	sm.emission_sphere_radius = 0.2 * size
	sm.direction = Vector3.UP
	sm.spread = 12.0
	sm.initial_velocity_min = 0.25 * size
	sm.initial_velocity_max = 0.5 * size
	sm.gravity = Vector3(0.04, 0.12, 0)
	sm.scale_min = 0.8
	sm.scale_max = 1.3
	sm.scale_curve = _curve([Vector2(0, 0.35), Vector2(1, 1.8)])
	sm.turbulence_enabled = true
	sm.turbulence_noise_strength = 0.3
	sm.color_ramp = _ramp([Color(0.2, 0.18, 0.17, 0.0), Color(0.16, 0.15, 0.14, 0.28), Color(0.1, 0.1, 0.1, 0.0)], [0.0, 0.3, 1.0])
	_emitter(parent, pos + Vector3(0, 0.55 * size, 0), 12, 5.0, sm, Vector2(0.6, 0.6) * size, false)

	if light_energy > 0.0:
		var light := OmniLight3D.new()
		light.position = pos + Vector3(0, 0.35 * size, 0)
		light.light_color = Color(1.0, 0.58, 0.26)
		light.light_energy = light_energy
		light.omni_range = 9.0 * maxf(size, 0.6)
		light.omni_attenuation = 1.4
		light.shadow_enabled = shadows
		parent.add_child(light)
		light.set_script(FLICKER)
		light.set("base_energy", light_energy)


# ---------------------------------------------------------------- mesh builder

class Bucket:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()


class MB:
	var rng := RandomNumberGenerator.new()
	var xf := Transform3D.IDENTITY   # applied to everything added (keep it rigid: no scale)
	var _stack: Array[Transform3D] = []
	var _d := {}

	func _init(seed_ := 1) -> void:
		rng.seed = seed_

	func push(t: Transform3D) -> void:
		_stack.append(xf)
		xf = xf * t

	func pop() -> void:
		xf = _stack.pop_back()

	func _b(m: Material) -> Bucket:
		if not _d.has(m):
			_d[m] = Bucket.new()
		return _d[m]

	func _put(m: Material, p: Vector3, n: Vector3, uv: Vector2) -> void:
		var bk := _b(m)
		bk.v.append(xf * p)
		bk.n.append(xf.basis * n)
		bk.uv.append(uv)

	## Flat triangle. (a, b, c) counter-clockwise seen from outside, or pass `out` to fix orientation.
	func tri(m: Material, a: Vector3, b: Vector3, c: Vector3, out := Vector3.ZERO,
			ua := Vector2.ZERO, ub := Vector2.ZERO, uc := Vector2.ZERO) -> void:
		var n := (b - a).cross(c - a)
		if n.length_squared() < 1e-12:
			return
		n = n.normalized()
		if out != Vector3.ZERO and n.dot(out) < 0.0:
			n = -n
			var tp := b
			b = c
			c = tp
			var tu := ub
			ub = uc
			uc = tu
		_put(m, a, n, ua)
		_put(m, c, n, uc)
		_put(m, b, n, ub)

	func tri_smooth(m: Material, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3,
			ua := Vector2.ZERO, ub := Vector2.ZERO, uc := Vector2.ZERO) -> void:
		var g := (b - a).cross(c - a)
		if g.length_squared() < 1e-12:
			return
		if g.dot(na + nb + nc) < 0.0:
			var tp := b
			b = c
			c = tp
			var tn := nb
			nb = nc
			nc = tn
			var tu := ub
			ub = uc
			uc = tu
		_put(m, a, na, ua)
		_put(m, c, nc, uc)
		_put(m, b, nb, ub)

	## Flat quad a-b-c-d with meter UVs (u runs along the longer edge, so grain follows it).
	func quad(m: Material, a: Vector3, b: Vector3, c: Vector3, d: Vector3, out := Vector3.ZERO, uvo := Vector2.ZERO) -> void:
		var lu := a.distance_to(b)
		var lv := a.distance_to(d)
		var ua: Vector2
		var ub: Vector2
		var uc: Vector2
		var ud: Vector2
		if lu >= lv:
			ua = Vector2(0, 0)
			ub = Vector2(lu, 0)
			uc = Vector2(lu, lv)
			ud = Vector2(0, lv)
		else:
			ua = Vector2(0, 0)
			ub = Vector2(0, lu)
			uc = Vector2(lv, lu)
			ud = Vector2(lv, 0)
		tri(m, a, b, c, out, ua + uvo, ub + uvo, uc + uvo)
		tri(m, a, c, d, out, ua + uvo, uc + uvo, ud + uvo)

	## Hewn box. jit moves every corner a little so nothing is perfectly square.
	func box(m: Material, center: Vector3, size: Vector3, rot := Basis(), jit := 0.0) -> void:
		var h := size * 0.5
		var cs: Array[Vector3] = []
		for i in 8:
			var p := Vector3(h.x if (i & 1) else -h.x, h.y if (i & 2) else -h.y, h.z if (i & 4) else -h.z)
			if jit > 0.0:
				p += Vector3(rng.randf_range(-jit, jit), rng.randf_range(-jit, jit), rng.randf_range(-jit, jit))
			cs.append(center + rot * p)
		var uvo := Vector2(rng.randf() * 3.0, rng.randf() * 3.0)
		var corners := [[-1, -1], [1, -1], [1, 1], [-1, 1]]
		for axis in 3:
			for s in [-1, 1]:
				var j := (axis + 1) % 3
				var k := (axis + 2) % 3
				var idx: Array[int] = []
				for c in corners:
					var bits := [0, 0, 0]
					bits[axis] = 1 if s > 0 else 0
					bits[j] = 1 if c[0] > 0 else 0
					bits[k] = 1 if c[1] > 0 else 0
					idx.append(bits[0] | (bits[1] << 1) | (bits[2] << 2))
				var nrm := Vector3.ZERO
				nrm[axis] = float(s)
				quad(m, cs[idx[0]], cs[idx[1]], cs[idx[2]], cs[idx[3]], rot * nrm, uvo)

	## Tapered log / pole / bar between two points (smooth round, optional wobble).
	func cyl(m: Material, a: Vector3, b: Vector3, r0: float, r1: float, sides := 8, wob := 0.0, caps := true, rings := 1) -> void:
		var ax := b - a
		var len := ax.length()
		if len < 1e-5:
			return
		var y := ax / len
		var x := Vector3.UP.cross(y)
		if x.length() < 0.01:
			x = Vector3.RIGHT.cross(y)
		x = x.normalized()
		var z := x.cross(y)
		var uvo := Vector2(rng.randf() * 3.0, rng.randf() * 3.0)
		var w := sides + 1
		var pts := PackedVector3Array()
		var nrm := PackedVector3Array()
		var vv := PackedVector2Array()
		for ri in rings + 1:
			var t := float(ri) / rings
			var r := lerpf(r0, r1, t)
			var first_p := Vector3.ZERO
			for s in w:
				var si := s % sides
				var th := TAU * float(si) / sides
				var dir := x * cos(th) + z * sin(th)
				var rr := r * (1.0 + (rng.randf_range(-wob, wob) if s < sides else 0.0))
				var p := a + y * len * t + dir * rr
				if s == sides:
					p = first_p
				if s == 0:
					first_p = p
				pts.append(p)
				nrm.append((dir - y * (r1 - r0) / len).normalized())
				vv.append(Vector2(t * len, TAU * r * float(s) / sides) + uvo)
		for ri in rings:
			for s in sides:
				var i00 := ri * w + s
				var i01 := i00 + 1
				var i10 := i00 + w
				var i11 := i10 + 1
				tri_smooth(m, pts[i00], pts[i01], pts[i11], nrm[i00], nrm[i01], nrm[i11], vv[i00], vv[i01], vv[i11])
				tri_smooth(m, pts[i00], pts[i11], pts[i10], nrm[i00], nrm[i11], nrm[i10], vv[i00], vv[i11], vv[i10])
		if caps:
			for end in 2:
				var c := a if end == 0 else b
				var base := 0 if end == 0 else rings * w
				var dir_out := -y if end == 0 else y
				for s in sides:
					var pa := pts[base + s]
					var pb := pts[base + s + 1]
					tri(m, c, pa, pb, dir_out, Vector2(0, 0), Vector2(pa.dot(x) - c.dot(x), pa.dot(z) - c.dot(z)),
						Vector2(pb.dot(x) - c.dot(x), pb.dot(z) - c.dot(z)))

	## Surface of revolution around Y. prof = (radius, y) points, bottom to top, outside facing out.
	## Profile corners stay crisp unless smooth_prof; around the axis it is always smooth.
	func lathe(m: Material, prof: PackedVector2Array, sides := 16, smooth_prof := false) -> void:
		var n := prof.size()
		if n < 2:
			return
		var segn: Array[Vector2] = []
		var vs := PackedFloat32Array([0.0])
		for s in n - 1:
			var d := prof[s + 1] - prof[s]
			segn.append(Vector2(d.y, -d.x).normalized())
			vs.append(vs[s] + d.length())
		for s in n - 1:
			var na := segn[s]
			var nb := segn[s]
			if smooth_prof:
				if s > 0:
					na = (segn[s - 1] + segn[s]).normalized()
				if s < n - 2:
					nb = (segn[s] + segn[s + 1]).normalized()
			for j in sides:
				var t0 := TAU * float(j) / sides
				var t1 := TAU * float(j + 1) / sides
				var p00 := Vector3(cos(t0) * prof[s].x, prof[s].y, sin(t0) * prof[s].x)
				var p01 := Vector3(cos(t1) * prof[s].x, prof[s].y, sin(t1) * prof[s].x)
				var p10 := Vector3(cos(t0) * prof[s + 1].x, prof[s + 1].y, sin(t0) * prof[s + 1].x)
				var p11 := Vector3(cos(t1) * prof[s + 1].x, prof[s + 1].y, sin(t1) * prof[s + 1].x)
				var n00 := Vector3(cos(t0) * na.x, na.y, sin(t0) * na.x)
				var n01 := Vector3(cos(t1) * na.x, na.y, sin(t1) * na.x)
				var n10 := Vector3(cos(t0) * nb.x, nb.y, sin(t0) * nb.x)
				var n11 := Vector3(cos(t1) * nb.x, nb.y, sin(t1) * nb.x)
				var u0 := t0 * prof[s].x
				var u1 := t1 * prof[s].x
				var u0b := t0 * prof[s + 1].x
				var u1b := t1 * prof[s + 1].x
				tri_smooth(m, p00, p01, p11, n00, n01, n11, Vector2(u0, vs[s]), Vector2(u1, vs[s]), Vector2(u1b, vs[s + 1]))
				tri_smooth(m, p00, p11, p10, n00, n11, n10, Vector2(u0, vs[s]), Vector2(u1b, vs[s + 1]), Vector2(u0b, vs[s + 1]))

	## Flat disc (fan) at height y.
	func disc(m: Material, y: float, r: float, sides := 16, up := true, cx := 0.0, cz := 0.0) -> void:
		var out := Vector3.UP if up else Vector3.DOWN
		for i in sides:
			var a0 := TAU * float(i) / sides
			var a1 := TAU * float(i + 1) / sides
			var p0 := Vector3(cx + cos(a0) * r, y, cz + sin(a0) * r)
			var p1 := Vector3(cx + cos(a1) * r, y, cz + sin(a1) * r)
			tri(m, Vector3(cx, y, cz), p0, p1, out, Vector2(cx, cz), Vector2(p0.x, p0.z), Vector2(p1.x, p1.z))

	## Lumpy rock / sack / heap: noise-displaced ellipsoid. flat = faceted chunky rock.
	## floor_frac < 1 cuts the underside flat so it sits on the ground.
	func blob(m: Material, c: Vector3, radii: Vector3, seed_ := 0, amp := 0.25, freq := 1.5, rings := 8,
			segs := 12, rot := Basis(), flat := false, floor_frac := 1.0) -> void:
		var nz := FastNoiseLite.new()
		nz.seed = seed_
		nz.frequency = 1.0
		nz.fractal_octaves = 3
		var w := segs + 1
		var pts := PackedVector3Array()
		pts.resize((rings + 1) * w)
		for i in rings + 1:
			var ph := PI * float(i) / rings
			for j in w:
				var th := TAU * float(j % segs) / segs
				var d := Vector3(sin(ph) * cos(th), cos(ph), sin(ph) * sin(th))
				var f := 1.0 + amp * nz.get_noise_3dv(d * freq + Vector3(seed_ * 0.37, 0.0, 0.0))
				var q := d * radii * f
				q.y = maxf(q.y, -floor_frac * radii.y)
				pts[i * w + j] = c + rot * q
		var nr := PackedVector3Array()
		nr.resize(pts.size())
		for i in rings:
			for j in segs:
				var i00 := i * w + j
				var i01 := i00 + 1
				var i10 := i00 + w
				var i11 := i10 + 1
				_acc(nr, pts, w, segs, i00, i10, i11, c)
				_acc(nr, pts, w, segs, i00, i11, i01, c)
		for end in 2:
			var row := 0 if end == 0 else rings
			var sum := Vector3.ZERO
			for j in segs:
				sum += nr[row * w + j]
			for j in segs:
				nr[row * w + j] = sum.normalized()
		for i in rings:
			for j in segs:
				var i00 := i * w + j
				var i01 := i00 + 1
				var i10 := i00 + w
				var i11 := i10 + 1
				var uv00 := Vector2(float(j) / segs * (radii.x + radii.z) * PI, float(i) / rings * radii.y * 3.0)
				var uv01 := uv00 + Vector2(1.0 / segs * (radii.x + radii.z) * PI, 0)
				var uv10 := uv00 + Vector2(0, 1.0 / rings * radii.y * 3.0)
				var uv11 := uv01 + Vector2(0, 1.0 / rings * radii.y * 3.0)
				if flat:
					var cen := (pts[i00] + pts[i10] + pts[i11] + pts[i01]) * 0.25 - c
					tri(m, pts[i00], pts[i10], pts[i11], cen, uv00, uv10, uv11)
					tri(m, pts[i00], pts[i11], pts[i01], cen, uv00, uv11, uv01)
				else:
					var k00 := _canon(i00, w, segs)
					var k01 := _canon(i01, w, segs)
					var k10 := _canon(i10, w, segs)
					var k11 := _canon(i11, w, segs)
					tri_smooth(m, pts[i00], pts[i10], pts[i11], nr[k00], nr[k10], nr[k11], uv00, uv10, uv11)
					tri_smooth(m, pts[i00], pts[i11], pts[i01], nr[k00], nr[k11], nr[k01], uv00, uv11, uv01)

	func _canon(idx: int, w: int, segs: int) -> int:
		return (idx / w) * w + (idx % w) % segs

	func _acc(nr: PackedVector3Array, pts: PackedVector3Array, w: int, segs: int, a: int, b: int, c: int, center: Vector3) -> void:
		var g := (pts[b] - pts[a]).cross(pts[c] - pts[a])
		if g.length_squared() < 1e-14:
			return
		var cen := (pts[a] + pts[b] + pts[c]) / 3.0 - center
		if g.dot(cen) < 0.0:
			g = -g
		nr[_canon(a, w, segs)] += g
		nr[_canon(b, w, segs)] += g
		nr[_canon(c, w, segs)] += g

	## Height-field style sheet: pts is nu*nv points row by row, hint = which side faces out.
	func grid(m: Material, pts: PackedVector3Array, nu: int, nv: int, hint: Vector3, uv_scale := 1.0) -> void:
		var nr := PackedVector3Array()
		nr.resize(pts.size())
		for j in nv - 1:
			for i in nu - 1:
				var a := j * nu + i
				for t in [[a, a + 1, a + nu + 1], [a, a + nu + 1, a + nu]]:
					var g := (pts[t[1]] - pts[t[0]]).cross(pts[t[2]] - pts[t[0]])
					if hint != Vector3.ZERO and g.dot(hint) < 0.0:
						g = -g
					nr[t[0]] += g
					nr[t[1]] += g
					nr[t[2]] += g
		for k in nr.size():
			nr[k] = nr[k].normalized()
		for j in nv - 1:
			for i in nu - 1:
				var a := j * nu + i
				var uv := func(idx: int) -> Vector2:
					return Vector2(pts[idx].x + pts[idx].z * 0.0, pts[idx].z + pts[idx].y) * uv_scale
				tri_smooth(m, pts[a], pts[a + 1], pts[a + nu + 1], nr[a], nr[a + 1], nr[a + nu + 1], uv.call(a), uv.call(a + 1), uv.call(a + nu + 1))
				tri_smooth(m, pts[a], pts[a + nu + 1], pts[a + nu], nr[a], nr[a + nu + 1], nr[a + nu], uv.call(a), uv.call(a + nu + 1), uv.call(a + nu))

	func build() -> ArrayMesh:
		var mesh := ArrayMesh.new()
		for m in _d:
			var bk: Bucket = _d[m]
			if bk.v.is_empty():
				continue
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.set_material(m)
			for i in bk.v.size():
				st.set_normal(bk.n[i])
				st.set_uv(bk.uv[i])
				st.add_vertex(bk.v[i])
			st.generate_tangents()
			st.commit(mesh)
		return mesh

