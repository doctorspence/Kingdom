extends Node3D
## Swamp look test: a small moonlit swamp built in code to try the "classic online RPG,
## re-lit" style (hand-painted textures, cut-out plants, a low moon behind the scene,
## thick blue-teal fog, a few warm lanterns). Nothing here is used by the game; it is a
## sandbox to compare looks. Run it with F6 in the editor.
##
## Keys: right mouse = look, WASD = move, Q / E = down / up, Shift = fast,
##       T = swap to the Tithelands' current lighting and back, F12 = screenshot
##       (saved to user://shots).

const Paint := preload("res://levels/sandbox/swamp_look/swamp_paint.gd")
const TITHE_ENV := "res://levels/common/tithelands_env.tres"

## Where the camera starts: low, looking down the channel toward the moon.
const START_POS := Vector3(0.0, 1.45, 9.0)
const START_ROT := Vector3(4.0, 0.0, 0.0)

var cam: Camera3D
var world_env: WorldEnvironment
var swamp_env: Environment
var moon: DirectionalLight3D
var lanterns: Array[OmniLight3D] = []
var _noise := FastNoiseLite.new()
var _noise2 := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()
var _yaw := 0.0
var _pitch := 0.0
var _t := 0.0

# One SurfaceTool per material, shared by every tree, so the whole swamp is a handful of meshes.
var _st_bark := SurfaceTool.new()
var _st_twig := SurfaceTool.new()
var _st_moss := SurfaceTool.new()
var _st_glow := SurfaceTool.new()
var _foliage_shader: Shader


func _ready() -> void:
	_rng.seed = 4242
	_noise.seed = 7
	_noise.frequency = 0.035
	_noise.fractal_octaves = 3
	_noise2.seed = 19
	_noise2.frequency = 0.18
	for st in [_st_bark, _st_twig, _st_moss, _st_glow]:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_foliage_shader = Shader.new()
	_foliage_shader.code = FOLIAGE_SHADER
	_build_environment()
	_build_ground()
	_build_water()
	_build_trees()
	_build_lights()
	_build_reeds()
	_build_mist()
	_build_moon_rays()
	_commit_shared_meshes()
	_build_camera()


# ------------------------------------------------------------------ terrain shape

## Ground height in meters. Water sits at y = 0, so anything below is a pool or channel.
func height(x: float, z: float) -> float:
	var h := 0.28 + _noise.get_noise_2d(x, z) * 1.1 + _noise2.get_noise_2d(x, z) * 0.18
	# A slope rising on the left, a gentler one on the right.
	h += smoothstep(-9.0, -26.0, x) * 5.5 + smoothstep(14.0, 30.0, x) * 2.5
	# The channel that leads the eye from the camera toward the moon.
	var cx := channel_x(z)
	var d := absf(x - cx)
	var wide := 2.2 + smoothstep(0.0, -30.0, z) * 4.0
	h = lerpf(h, -0.55, smoothstep(wide + 2.5, wide, d) * smoothstep(14.0, 8.0, z))
	return h


func channel_x(z: float) -> float:
	return 1.2 * sin(z * 0.09) + clampf(-z - 20.0, 0.0, 20.0) * 0.12


# ------------------------------------------------------------------ environment

func _build_environment() -> void:
	var sky_mat := ShaderMaterial.new()
	var sky_shader := Shader.new()
	sky_shader.code = SKY_SHADER
	sky_mat.shader = sky_shader
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.48, 0.52)
	env.ambient_light_energy = 0.26
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	env.ssao_enabled = true
	env.ssao_radius = 1.4
	env.ssao_intensity = 2.2
	env.ssr_enabled = true
	env.ssr_max_steps = 96
	env.ssr_fade_in = 0.1
	env.ssr_fade_out = 2.0
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_strength = 1.0
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.3
	env.fog_enabled = true
	env.fog_light_color = Color(0.13, 0.19, 0.24)
	env.fog_light_energy = 0.7
	env.fog_sun_scatter = 0.25
	env.fog_density = 0.013
	env.fog_height = 1.6
	env.fog_height_density = 0.45
	env.fog_sky_affect = 0.2
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.034
	env.volumetric_fog_albedo = Color(0.3, 0.38, 0.44)
	env.volumetric_fog_emission = Color(0.004, 0.007, 0.01)
	env.volumetric_fog_anisotropy = 0.6
	env.volumetric_fog_length = 80.0
	env.volumetric_fog_ambient_inject = 0.25
	env.volumetric_fog_sky_affect = 0.15
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.12
	env.adjustment_saturation = 1.0
	swamp_env = env
	world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# The moon: low, in front of the camera, so the trees become silhouettes against glowing fog.
	moon = DirectionalLight3D.new()
	moon.light_color = Color(0.78, 0.86, 1.0)
	moon.light_energy = 0.75
	moon.light_volumetric_fog_energy = 1.3
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 90.0
	moon.rotation_degrees = Vector3(-17.0, 172.0, 0.0)
	add_child(moon)


# ------------------------------------------------------------------ ground and water

func _build_ground() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0 := -60
	var x1 := 60
	var z0 := -90
	var z1 := 20
	var nx := x1 - x0 + 1
	var nz := z1 - z0 + 1
	for iz in nz:
		for ix in nx:
			var x := float(x0 + ix)
			var z := float(z0 + iz)
			var h := height(x, z)
			var n := Vector3(height(x - 1, z) - height(x + 1, z), 2.0, height(x, z - 1) - height(x, z + 1)).normalized()
			var wet := lerpf(0.5, 1.0, smoothstep(-0.05, 0.45, h))
			st.set_color(Color(wet, wet, wet))
			st.set_normal(n)
			st.set_uv(Vector2(x, z) / 4.0)
			st.add_vertex(Vector3(x, h, z))
	for iz in nz - 1:
		for ix in nx - 1:
			var a := iz * nx + ix
			var b := a + 1
			var c := a + nx
			var d := c + 1
			st.add_index(a); st.add_index(b); st.add_index(c)
			st.add_index(b); st.add_index(d); st.add_index(c)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = Paint.tex(Paint.mud())
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.name = "Ground"
	add_child(mi)


func _build_water() -> void:
	var nmap := NoiseTexture2D.new()
	nmap.width = 512
	nmap.height = 512
	nmap.seamless = true
	nmap.as_normal_map = true
	nmap.bump_strength = 4.0
	var fn := FastNoiseLite.new()
	fn.frequency = 0.03
	nmap.noise = fn
	var weed := NoiseTexture2D.new()
	weed.width = 256
	weed.height = 256
	weed.seamless = true
	var fw := FastNoiseLite.new()
	fw.frequency = 0.05
	fw.seed = 3
	weed.noise = fw
	var shader := Shader.new()
	shader.code = WATER_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("nmap", nmap)
	mat.set_shader_parameter("weed", weed)
	var plane := PlaneMesh.new()
	plane.size = Vector2(130, 120)
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.material_override = mat
	mi.position = Vector3(0, 0, -35)
	mi.name = "Water"
	add_child(mi)


# ------------------------------------------------------------------ trees

func _build_trees() -> void:
	# The big overhang across the top right of the starting view, dripping with moss.
	_tube(_st_bark, [Vector3(14, height(14, 3) - 0.5, 3), Vector3(13.6, 4, 2.6), Vector3(13.2, 7.5, 2.0), Vector3(12.5, 10, 1.5)], [1.4, 1.1, 0.95, 0.8], 10)
	var limb := [Vector3(13.0, 7.6, 2.0), Vector3(10.5, 6.6, 1.4), Vector3(8.0, 6.9, 0.2), Vector3(5.5, 6.2, -0.8), Vector3(3.2, 6.8, -1.8), Vector3(1.0, 7.4, -2.6), Vector3(-1.5, 8.4, -3.4)]
	_tube(_st_bark, limb, [1.0, 0.85, 0.7, 0.6, 0.45, 0.3, 0.15], 9)
	# Side shoots off the limb so the overhang reads as a gnarled mass, not a plank.
	for i in 7:
		var p0 := _along(limb, _rng.randf_range(0.05, 0.8))
		var d := Vector3(_rng.randf_range(-1.5, 1.5), _rng.randf_range(-0.6, 1.2), _rng.randf_range(-2.5, 1.0))
		_tube(_st_bark, [p0, p0 + d * 0.5 + Vector3(0, 0.2, 0), p0 + d], [0.3, 0.2, 0.06], 6)
	for i in 80:
		var t := _rng.randf()
		var p := _along(limb, t) + Vector3(_rng.randf_range(-0.6, 0.6), -0.3, _rng.randf_range(-1.0, 1.0))
		_moss(p, _rng.randf_range(1.0, 4.4) * lerpf(1.0, 0.6, t), _rng.randf_range(0.6, 1.4))
	# A second limb going back into the fog.
	var limb2 := [Vector3(13.2, 8.6, 1.8), Vector3(11.0, 9.5, -3.0), Vector3(9.0, 10.5, -8.0)]
	_tube(_st_bark, limb2, [0.6, 0.4, 0.2], 8)
	for i in 18:
		_moss(_along(limb2, _rng.randf()) + Vector3(0, -0.2, 0), _rng.randf_range(1.5, 3.5), _rng.randf_range(0.6, 1.1))

	# The dark mass on the left: a big old tree on the slope.
	_bare_tree(Vector3(-12.5, 0, 0.5), 13.0, 1.0, 3, 22)
	_bare_tree(Vector3(-17.0, 0, -6.0), 11.0, 0.8, 3, 14)

	# The feathery dead conifer in the middle distance, and its neighbours.
	_dead_fir(Vector3(-4.5, 0, -14.0), 13.0)
	_dead_fir(Vector3(17.0, 0, -26.0), 10.0)
	_dead_fir(Vector3(-24.0, 0, -38.0), 12.0)

	# Bare swamp trees in the middle distance.
	for p in [Vector3(9.5, 0, -18), Vector3(-1.0, 0, -36), Vector3(12.0, 0, -40), Vector3(-11.0, 0, -28), Vector3(22.0, 0, -12)]:
		_bare_tree(p, _rng.randf_range(7.0, 10.0), _rng.randf_range(0.35, 0.55), 2, 8)

	# Far trees that fade into the fog.
	var placed := 0
	while placed < 38:
		var x := _rng.randf_range(-45.0, 45.0)
		var z := _rng.randf_range(-85.0, -42.0)
		if absf(x - channel_x(z)) < 6.0:
			continue
		if _rng.randf() < 0.25:
			_dead_fir(Vector3(x, 0, z), _rng.randf_range(9.0, 15.0))
		else:
			_bare_tree(Vector3(x, 0, z), _rng.randf_range(7.0, 12.0), _rng.randf_range(0.35, 0.6), 2, 4)
		placed += 1

	# A gnarled root arch in the distance, lit from below (see _build_lights).
	var ax := channel_x(-31.0) + 4.0
	var base := Vector3(ax, 0, -31.0)
	for k in 2:
		var off := Vector3(0, 0, k * 0.5)
		var pts: Array = []
		for i in 9:
			var a := PI * i / 8.0
			pts.append(base + off + Vector3(-cos(a) * 2.6, sin(a) * 3.2 - 0.3, sin(a * 2.0) * 0.4))
		_tube(_st_bark, pts, [0.5, 0.45, 0.38, 0.34, 0.32, 0.34, 0.38, 0.45, 0.5], 8)


## A bare, forked swamp tree: trunk, a few limbs, twig sprays at the ends, moss hanging off.
func _bare_tree(base: Vector3, h: float, r: float, depth: int, moss_count: int) -> void:
	base.y = height(base.x, base.z) - 0.3
	var lean := Vector3(_rng.randf_range(-0.12, 0.12), 0, _rng.randf_range(-0.12, 0.12))
	var fork := base + (Vector3.UP + lean) * h * 0.42
	var mid := base.lerp(fork, 0.5) + Vector3(_rng.randf_range(-0.3, 0.3), 0, _rng.randf_range(-0.3, 0.3))
	_tube(_st_bark, [base - Vector3(0, 0.5, 0), base + Vector3(0, 0.6, 0), mid, fork], [r * 1.5, r, r * 0.85, r * 0.7], 9)
	var tips: Array[Vector3] = []
	_limbs(fork, (Vector3.UP + lean).normalized(), h * 0.4, r * 0.65, depth, tips)
	for t in tips:
		_twig_card(t, Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.2, 0.6), _rng.randf_range(-1, 1)).normalized(), _rng.randf_range(1.2, 2.4))
	for i in moss_count:
		if tips.is_empty():
			break
		var tp: Vector3 = tips[_rng.randi() % tips.size()]
		var p := fork.lerp(tp, _rng.randf_range(0.3, 0.9))
		_moss(p, _rng.randf_range(1.2, 3.2), _rng.randf_range(0.5, 1.0))


func _limbs(from: Vector3, dir: Vector3, length: float, r: float, depth: int, tips: Array[Vector3]) -> void:
	var n := _rng.randi_range(2, 4)
	for i in n:
		var a := TAU * i / n + _rng.randf_range(-0.5, 0.5)
		var out := Vector3(cos(a), 0, sin(a))
		var d := (dir * 0.9 + out * _rng.randf_range(0.5, 1.0)).normalized()
		var l := length * _rng.randf_range(0.7, 1.0)
		var mid := from + d * l * 0.5 + Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(-0.2, 0.3), _rng.randf_range(-0.3, 0.3))
		var end := from + d * l
		_tube(_st_bark, [from, mid, end], [r, r * 0.7, r * 0.35], 6)
		if depth > 1:
			_limbs(end, d, l * 0.6, r * 0.4, depth - 1, tips)
		else:
			tips.append(end)


## Tall dead conifer: a thin trunk with drooping tiers of twig sprays, shorter toward the top.
func _dead_fir(base: Vector3, h: float) -> void:
	base.y = height(base.x, base.z) - 0.3
	var pts: Array = []
	var radii: Array = []
	for i in 8:
		var t := i / 7.0
		pts.append(base + Vector3(sin(t * 5.0) * 0.25, t * h, cos(t * 4.0) * 0.2))
		radii.append(lerpf(0.38, 0.04, t) * h / 12.0)
	_tube(_st_bark, pts, radii, 7)
	var tiers := 13
	for k in tiers:
		var t := 0.28 + 0.7 * k / float(tiers)
		var p := _along(pts, t)
		var count := _rng.randi_range(4, 6)
		for i in count:
			var a := TAU * i / count + _rng.randf_range(-0.4, 0.4) + k
			var out := Vector3(cos(a), 0, sin(a))
			var length := lerpf(3.2, 0.7, (t - 0.28) / 0.7) * _rng.randf_range(0.75, 1.15) * h / 12.0
			_twig_card(p, (out + Vector3(0, -0.25, 0)).normalized(), length)


## One twig-spray card: starts at `p`, reaches along `dir`, its spray hanging below.
func _twig_card(p: Vector3, dir: Vector3, length: float) -> void:
	var side := dir.cross(Vector3.UP).normalized()
	if side.length() < 0.1:
		side = Vector3.RIGHT
	var down := (Vector3.DOWN * 0.6 + side * 0.8).normalized()
	var tall := length * 0.5
	var top := p - down * tall * 0.45
	_card(_st_twig, top, top + dir * length, down * tall, Rect2(0, 0, 1, 1), Vector3.UP)


## One hanging moss card, top edge at `p`.
func _moss(p: Vector3, length: float, width: float) -> void:
	var a := _rng.randf() * TAU
	var right := Vector3(cos(a), 0, sin(a)) * width
	_card(_st_moss, p - right * 0.5, p + right * 0.5, Vector3.DOWN * length, Rect2(0, 0, 1, 1), (Vector3.UP + Vector3(sin(a), 0, -cos(a)) * 0.5).normalized())


## A quad from top-left `a` to top-right `b`, hanging `down` from that edge. UV y = 0 at the top.
func _card(st: SurfaceTool, a: Vector3, b: Vector3, down: Vector3, uv: Rect2, normal: Vector3) -> void:
	var c := b + down
	var d := a + down
	var u0 := uv.position.x
	var u1 := uv.end.x
	var v0 := uv.position.y
	var v1 := uv.end.y
	var verts := [[a, Vector2(u0, v0)], [b, Vector2(u1, v0)], [c, Vector2(u1, v1)], [a, Vector2(u0, v0)], [c, Vector2(u1, v1)], [d, Vector2(u0, v1)]]
	for v in verts:
		st.set_normal(normal)
		st.set_color(Color(1, 1, 1))
		st.set_uv(v[1])
		st.add_vertex(v[0])


## A bendy tube through `pts` with matching `radii`. Normals point outward; UV v in 2 m steps.
func _tube(st: SurfaceTool, pts: Array, radii: Array, sides: int) -> void:
	var n := pts.size()
	var prev: Array = []
	var vlen := 0.0
	for i in n:
		var p: Vector3 = pts[i]
		var dir: Vector3 = (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var ref := Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT
		var s := dir.cross(ref).normalized()
		var u := s.cross(dir).normalized()
		if i > 0:
			vlen += p.distance_to(pts[i - 1])
		var ring: Array = []
		var r: float = radii[i]
		for k in sides + 1:
			var ang := TAU * k / sides
			var off := (s * cos(ang) + u * sin(ang))
			# A little knobbliness so trunks are not perfect cylinders.
			var bump := 1.0 + 0.12 * sin(ang * 3.0 + i * 1.7)
			ring.append([p + off * r * bump, off, Vector2(float(k) / sides, vlen / 2.0)])
		if i > 0:
			for k in sides:
				var q := [prev[k], prev[k + 1], ring[k + 1], prev[k], ring[k + 1], ring[k]]
				for e in q:
					st.set_normal(e[1])
					st.set_color(Color(1, 1, 1))
					st.set_uv(e[2])
					st.add_vertex(e[0])
		prev = ring


func _along(pts: Array, t: float) -> Vector3:
	var f := clampf(t, 0.0, 1.0) * (pts.size() - 1)
	var i := mini(int(f), pts.size() - 2)
	return (pts[i] as Vector3).lerp(pts[i + 1], f - i)


# ------------------------------------------------------------------ warm lights

func _build_lights() -> void:
	# Two lanterns on poles on the left bank.
	for p in [Vector3(-10.0, 0, -13.5), Vector3(-6.0, 0, -15.5)]:
		p.y = maxf(height(p.x, p.z), 0.0)
		_tube(_st_bark, [p - Vector3(0, 0.3, 0), p + Vector3(0, 2.5, 0)], [0.08, 0.06], 5)
		_tube(_st_bark, [p + Vector3(0, 2.45, 0), p + Vector3(0.45, 2.5, 0)], [0.04, 0.04], 4)
		_box(_st_glow, p + Vector3(0.45, 2.15, 0), Vector3(0.28, 0.38, 0.28))
		_lamp(p + Vector3(0.45, 2.15, 0), 5.0, 10.0)
	# Glow under the root arch.
	var ax := channel_x(-31.0) + 4.0
	for p in [Vector3(ax - 2.4, 0.4, -31.0), Vector3(ax + 2.4, 0.4, -31.0), Vector3(ax, 1.2, -31.5)]:
		_box(_st_glow, p, Vector3(0.18, 0.18, 0.18))
		_lamp(p, 2.0, 7.0)


func _lamp(p: Vector3, energy: float, range_m: float) -> void:
	var l := OmniLight3D.new()
	l.position = p
	l.light_color = Color(1.0, 0.55, 0.2)
	l.light_energy = energy
	l.omni_range = range_m
	l.light_volumetric_fog_energy = 7.0
	l.set_meta("base", energy)
	add_child(l)
	lanterns.append(l)


func _box(st: SurfaceTool, c: Vector3, size: Vector3) -> void:
	var h := size * 0.5
	var faces := [
		[Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0)],
		[Vector3(-1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)],
		[Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, 1, 0)],
		[Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 1, 0)],
		[Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)],
		[Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, -1)],
	]
	for f in faces:
		var n: Vector3 = f[0]
		var a: Vector3 = f[1]
		var b: Vector3 = f[2]
		var o := c + n * h
		var ea := a * h
		var eb := b * h
		_card(st, o - ea + eb, o + ea + eb, -eb * 2.0, Rect2(0, 0, 1, 1), n)


# ------------------------------------------------------------------ reeds and grass

func _build_reeds() -> void:
	var tall := _scatter(14000, -0.45, 0.7, 0.9, 2.1, 0.15)
	var short := _scatter(9000, -0.1, 2.5, 0.4, 0.95, -0.1)
	var tex_a := Paint.tex(Paint.reeds(5))
	var tex_b := Paint.tex(Paint.reeds(9))
	_reed_field(tall, tex_a, "Reeds")
	_reed_field(short, tex_b, "Grass")


## Random spots where the ground is between `lo` and `hi` m, in clumps.
## Returns [Transform3D, Color] pairs.
func _scatter(count: int, lo: float, hi: float, smin: float, smax: float, clump: float) -> Array:
	var out: Array = []
	var clumps := FastNoiseLite.new()
	clumps.seed = count
	clumps.frequency = 0.12
	var tries := 0
	while out.size() < count and tries < count * 12:
		tries += 1
		var x := _rng.randf_range(-50.0, 50.0)
		var z := _rng.randf_range(-80.0, 14.0)
		var h := height(x, z)
		if h < lo or h > hi:
			continue
		if clumps.get_noise_2d(x, z) < clump:
			continue
		# Keep a clear line down the channel near the camera.
		if z > -8.0 and absf(x - channel_x(z)) < 1.1:
			continue
		var s := _rng.randf_range(smin, smax)
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s * _rng.randf_range(0.8, 1.3), s, s * _rng.randf_range(0.8, 1.3)))
		basis = Basis(Vector3(1, 0, 0), _rng.randf_range(-0.08, 0.08)) * basis
		var k := _rng.randf_range(0.75, 1.15)
		var tint := Color(k, k * _rng.randf_range(0.95, 1.05), k * 0.95)
		out.append([Transform3D(basis, Vector3(x, h - 0.05, z)), tint])
	return out


func _reed_field(items: Array, texture: Texture2D, node_name: String) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 3:
		var a := PI * i / 3.0
		var r := Vector3(cos(a), 0, sin(a)) * 0.6
		_card(st, Vector3.UP - r, Vector3.UP + r, Vector3.DOWN, Rect2(0, 0, 1, 1), Vector3(0, 1, 0))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = st.commit()
	mm.instance_count = items.size()
	for i in items.size():
		mm.set_instance_transform(i, items[i][0])
		mm.set_instance_color(i, items[i][1])
	var mat := ShaderMaterial.new()
	mat.shader = _foliage_shader
	mat.set_shader_parameter("tex", texture)
	mat.set_shader_parameter("sway", 0.06)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.name = node_name
	add_child(mmi)


func _commit_shared_meshes() -> void:
	var bark_mat := StandardMaterial3D.new()
	bark_mat.albedo_texture = Paint.tex(Paint.bark())
	bark_mat.roughness = 1.0
	bark_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	bark_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_add_mesh(_st_bark, bark_mat, "Bark")
	var twig_mat := ShaderMaterial.new()
	twig_mat.shader = _foliage_shader
	twig_mat.set_shader_parameter("tex", Paint.tex(Paint.twigs()))
	twig_mat.set_shader_parameter("sway", 0.03)
	_add_mesh(_st_twig, twig_mat, "Twigs")
	var moss_mat := ShaderMaterial.new()
	moss_mat.shader = _foliage_shader
	moss_mat.set_shader_parameter("tex", Paint.tex(Paint.moss()))
	moss_mat.set_shader_parameter("sway", 0.12)
	moss_mat.set_shader_parameter("hang", 1.0)
	_add_mesh(_st_moss, moss_mat, "Moss")
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.6, 0.25)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.55, 0.2)
	glow.emission_energy_multiplier = 6.0
	_add_mesh(_st_glow, glow, "LanternGlass")


func _add_mesh(st: SurfaceTool, mat: Material, node_name: String) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.name = node_name
	add_child(mi)


# ------------------------------------------------------------------ camera and keys

func _build_camera() -> void:
	cam = Camera3D.new()
	cam.fov = 68.0
	cam.far = 400.0
	add_child(cam)
	set_view(START_POS, START_ROT)
	cam.make_current()
	var help := Label.new()
	help.text = "Right mouse: look   WASD: move   Q/E: down/up   Shift: fast   T: Tithelands lighting   F12: screenshot"
	help.position = Vector2(16, 12)
	help.modulate = Color(1, 1, 1, 0.6)
	var layer := CanvasLayer.new()
	layer.add_child(help)
	add_child(layer)


## Places the camera (degrees: pitch, yaw, roll).
func set_view(pos: Vector3, rot_deg: Vector3) -> void:
	_pitch = deg_to_rad(rot_deg.x)
	_yaw = deg_to_rad(rot_deg.y)
	cam.position = pos
	cam.rotation = Vector3(_pitch, _yaw, 0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * 0.003
		_pitch = clampf(_pitch - event.relative.y * 0.003, -1.4, 1.4)
		cam.rotation = Vector3(_pitch, _yaw, 0)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T:
			world_env.environment = swamp_env if world_env.environment != swamp_env else load(TITHE_ENV)
		elif event.physical_keycode == KEY_F12:
			DirAccess.make_dir_recursive_absolute("user://shots")
			var path := "user://shots/swamp_look_%d.png" % Time.get_unix_time_from_system()
			get_viewport().get_texture().get_image().save_png(path)
			print("Saved ", ProjectSettings.globalize_path(path))


# ------------------------------------------------------------------ mist banks and light beams

var _mist: Array[FogVolume] = []


## Low banks of thicker, wispy mist lying over the water and the reed beds; they drift slowly.
func _build_mist() -> void:
	# Finer fog grid, so the moon's shadow shafts through the trees come out crisp.
	RenderingServer.environment_set_volumetric_fog_volume_size(160, 128)
	var noise := FastNoiseLite.new()
	noise.frequency = 0.06
	noise.fractal_octaves = 3
	var tex := NoiseTexture3D.new()
	tex.width = 64
	tex.height = 32
	tex.depth = 64
	tex.seamless = true
	tex.noise = noise
	var mat := FogMaterial.new()
	mat.density = 0.22
	mat.albedo = Color(0.4, 0.48, 0.55)
	mat.height_falloff = 0.5
	mat.edge_fade = 0.6
	mat.density_texture = tex
	var spots := [Vector3(0, 0.4, -4), Vector3(-6, 0.6, -14), Vector3(6, 0.5, -16), Vector3(1, 0.6, -26),
		Vector3(-12, 0.8, -24), Vector3(12, 0.7, -30), Vector3(4, 0.8, -40), Vector3(-8, 0.9, -42),
		Vector3(16, 0.8, -8), Vector3(-16, 1.2, -10), Vector3(0, 0.9, -55), Vector3(-20, 1.2, -50)]
	for p in spots:
		var fv := FogVolume.new()
		fv.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
		fv.size = Vector3(_rng.randf_range(14, 22), _rng.randf_range(2.5, 4.0), _rng.randf_range(10, 16))
		fv.material = mat
		fv.position = p
		fv.set_meta("home", p)
		fv.set_meta("phase", _rng.randf() * TAU)
		add_child(fv)
		_mist.append(fv)


## Rays of moonlight that fan out from the moon itself: a screen effect that looks from each
## pixel toward the moon and adds light for every bit of open sky near the moon along the way,
## so moss, branches and trunks in front of the moon cut dark gaps into the rays.
var _rays_mat: ShaderMaterial


func _build_moon_rays() -> void:
	var shader := Shader.new()
	shader.code = RAYS_SHADER
	_rays_mat = ShaderMaterial.new()
	_rays_mat.shader = shader
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = _rays_mat
	mi.extra_cull_margin = 16384.0
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.name = "MoonRays"
	add_child(mi)


func _update_moon_rays() -> void:
	if _rays_mat == null or cam == null:
		return
	var to_moon := moon.global_transform.basis.z
	var far_point := cam.global_position + to_moon * 1000.0
	var vp := get_viewport().get_visible_rect().size
	# Fade the rays out as the moon leaves the screen or goes behind the camera.
	var facing := clampf(to_moon.dot(-cam.global_transform.basis.z), 0.0, 1.0)
	var uv := Vector2(0.5, 0.5)
	if not cam.is_position_behind(far_point):
		uv = cam.unproject_position(far_point) / vp
	var edge := maxf(absf(uv.x - 0.5), absf(uv.y - 0.5))
	_rays_mat.set_shader_parameter("moon_uv", uv)
	_rays_mat.set_shader_parameter("aspect", vp.x / vp.y)
	_rays_mat.set_shader_parameter("visible_k", smoothstep(0.3, 0.7, facing) * (1.0 - smoothstep(0.6, 1.1, edge)))
	_rays_mat.set_shader_parameter("on", 1.0 if world_env.environment == swamp_env else 0.0)


func _process(delta: float) -> void:
	_t += delta
	_update_moon_rays()
	for i in _mist.size():
		var fv := _mist[i]
		var home: Vector3 = fv.get_meta("home")
		var ph: float = fv.get_meta("phase")
		fv.position = home + Vector3(sin(_t * 0.05 + ph) * 4.0, 0, cos(_t * 0.04 + ph) * 3.0)
	for i in lanterns.size():
		var l := lanterns[i]
		var base: float = l.get_meta("base")
		l.light_energy = base * (0.9 + 0.07 * sin(_t * 7.3 + i * 2.1) + 0.05 * sin(_t * 13.1 + i))
	if cam == null:
		return
	var move := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W): move.z -= 1
	if Input.is_physical_key_pressed(KEY_S): move.z += 1
	if Input.is_physical_key_pressed(KEY_A): move.x -= 1
	if Input.is_physical_key_pressed(KEY_D): move.x += 1
	if Input.is_physical_key_pressed(KEY_Q): move.y -= 1
	if Input.is_physical_key_pressed(KEY_E): move.y += 1
	if move != Vector3.ZERO:
		var speed := 12.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 4.0
		cam.position += cam.global_transform.basis * move.normalized() * speed * delta


# ------------------------------------------------------------------ shaders

const RAYS_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec2 moon_uv = vec2(0.5);
uniform float aspect = 1.777;
uniform float visible_k = 1.0;
uniform float on = 1.0;
uniform vec3 ray_col : source_color = vec3(0.55, 0.68, 0.82);
uniform float intensity = 1.3;
uniform float reach = 0.85;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

// Open sky near the moon is the light source; anything solid in front of it blocks it.
float source(vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return 0.0;
	}
	float sky = texture(depth_tex, uv).r <= 0.000001 ? 1.0 : 0.0;
	vec2 d = (uv - moon_uv) * vec2(aspect, 1.0);
	float r = length(d);
	return sky * (1.0 - smoothstep(0.02, 0.45, r));
}

void fragment() {
	const int STEPS = 64;
	vec2 uv = SCREEN_UV;
	vec2 delta = (uv - moon_uv) * reach / float(STEPS);
	// A random start offset per pixel hides the step pattern (no visible stripes).
	float jitter = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453);
	vec2 p = uv + delta * jitter;
	float decay = 1.0;
	float sum = 0.0;
	for (int i = 0; i < STEPS; i++) {
		p -= delta;
		sum += source(p) * decay;
		decay *= 0.965;
	}
	sum /= float(STEPS);
	// Rays fade with distance from the moon on screen, so they reach out but never fill the frame.
	float r = length((uv - moon_uv) * vec2(aspect, 1.0));
	float fall = 1.0 - smoothstep(0.15, 1.1, r);
	ALBEDO = ray_col;
	ALPHA = clamp(sum * intensity * fall * visible_k * on, 0.0, 1.0);
}
"""

const SKY_SHADER := """
shader_type sky;
uniform vec3 top_col : source_color = vec3(0.05, 0.08, 0.12);
uniform vec3 hor_col : source_color = vec3(0.30, 0.42, 0.50);
uniform vec3 moon_col : source_color = vec3(0.85, 0.93, 1.0);

void sky() {
	float y = EYEDIR.y;
	vec3 c = mix(hor_col, top_col, smoothstep(-0.05, 0.65, y));
	float m = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
	c += moon_col * (pow(m, 60.0) * 0.45 + pow(m, 8.0) * 0.1);
	c += moon_col * smoothstep(0.9955, 0.9968, m) * 1.4;
	c = mix(c, hor_col * 0.5, smoothstep(0.0, -0.25, y));
	COLOR = c;
}
"""

const WATER_SHADER := """
shader_type spatial;
uniform sampler2D nmap : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D weed : filter_linear_mipmap, repeat_enable;
varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	vec3 n1 = texture(nmap, p * 0.05 + TIME * vec2(0.004, 0.002)).xyz;
	vec3 n2 = texture(nmap, p * 0.09 - TIME * vec2(0.003, 0.005)).xyz;
	float patch_ = texture(weed, p * 0.02).r;
	float speck = texture(weed, p * 0.4 + vec2(0.37, 0.11)).r;
	float cover = smoothstep(0.6, 0.66, patch_) * smoothstep(0.56, 0.6, speck);
	ALBEDO = mix(vec3(0.012, 0.02, 0.018), vec3(0.2, 0.18, 0.08), cover);
	ROUGHNESS = mix(0.04, 0.9, cover);
	SPECULAR = 0.5;
	NORMAL_MAP = (n1 + n2) * 0.5;
	NORMAL_MAP_DEPTH = mix(0.6, 0.1, cover);
}
"""

const FOLIAGE_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float sway = 0.06;
uniform float hang = 0.0;
varying vec3 col;

void vertex() {
	col = COLOR.rgb;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float f = mix(1.0 - UV.y, UV.y, hang);
	f *= f;
	float s = sin(TIME * 1.1 + wp.x * 0.35 + wp.z * 0.27) + 0.5 * sin(TIME * 2.3 + wp.z * 0.9);
	VERTEX.x += s * sway * f;
	VERTEX.z += s * sway * 0.6 * f;
}

void fragment() {
	vec4 c = texture(tex, UV);
	if (c.a < 0.5) {
		discard;
	}
	ALBEDO = c.rgb * col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
	BACKLIGHT = c.rgb * 0.6;
}
"""
