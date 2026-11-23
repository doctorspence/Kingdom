class_name PlantKit
extends RefCounted
## The Greenwood's ground plants, built in code in the same painterly style as
## the trees: bracken, bramble, holly, bluebells, foxglove, wild garlic, wood
## sorrel, ivy, and mushrooms / bracket fungus. Each plant is a few cards (or,
## for fungi, small solid shapes) with a texture drawn once in code, colors
## matched to the zone palette with selective saturation (the flowers are the
## only strong color: bluebell violet, foxglove purple, holly berries).
##
## mesh(name, variant) -> ArrayMesh, base at y = 0, centered on x/z. 4 variants.

const NAMES := ["bracken", "bramble", "holly", "bluebell", "foxglove", "garlic", "sorrel", "fungi", "ivy"]

static var _cache := {}
static var _mats := {}


static func mesh(name: String, variant: int) -> ArrayMesh:
	var key := "%s%d" % [name, variant]
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key) + 99
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	match name:
		"bracken":
			# 5-8 fronds: a thin stalk up to waist height, then a broad triangular blade held
			# out almost flat, tipping down at the end. Together they make a layered canopy.
			for i in rng.randi_range(5, 8):
				var a := TAU * i / 7.0 + rng.randf_range(-0.5, 0.5)
				var out := Vector3(cos(a), 0.0, sin(a))
				var h := rng.randf_range(0.55, 0.95)
				var foot := out * rng.randf_range(0.0, 0.25)
				var top := foot + out * 0.15 + Vector3.UP * h
				var side := out.cross(Vector3.UP).normalized()
				_quad(st, [foot - side * 0.02, foot + side * 0.02, top + side * 0.02, top - side * 0.02], Rect2(0.49, 0.0, 0.02, 1.0), Vector3.UP, Color(1, 1, 1))
				var length := rng.randf_range(0.8, 1.15)
				var wide := length * rng.randf_range(0.7, 0.85)
				var tip := top + out * length + Vector3.UP * rng.randf_range(0.1, 0.4)
				var tint := Color(1, 1, 1).lerp(Color(0.88, 0.8, 0.6), rng.randf() * 0.6)
				var tilt := Vector3.UP * rng.randf_range(-0.08, 0.08)
				_quad(st, [top - side * wide * 0.5 + tilt, top + side * wide * 0.5 - tilt, tip + side * 0.05, tip - side * 0.05], Rect2(0, 0, 1, 1), (Vector3.UP * 0.8 + out * 0.2).normalized(), tint)
		"bramble":
			# A low tangled mound of arching canes.
			for i in rng.randi_range(9, 13):
				var a := rng.randf() * TAU
				var out := Vector3(cos(a), 0.0, sin(a))
				_bent_card(st, out * rng.randf_range(0.0, 0.4), out, rng.randf_range(0.6, 1.0), rng.randf_range(0.7, 1.0), rng.randf_range(0.6, 1.0), rng)
		"holly":
			# A dense dark shrub: crossed cards in a squashed ball on a short stem.
			var r := rng.randf_range(0.6, 0.85)
			for i in rng.randi_range(18, 24):
				var u := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 0.75), rng.randf_range(-1, 1)).normalized()
				_card(st, Vector3(0, r * 1.15, 0) + Vector3(u.x * r, u.y * r * 1.2, u.z * r) * rng.randf_range(0.3, 1.0), rng.randf_range(0.8, 1.2), rng, u)
		"bluebell", "garlic", "sorrel":
			# A clump of upright crossed cards (sorrel lies low and flat).
			var n := 3 if name != "sorrel" else 4
			var size := 0.5 if name == "bluebell" else (0.45 if name == "garlic" else 0.5)
			for i in n:
				var p := Vector3(rng.randf_range(-0.25, 0.25), 0.0, rng.randf_range(-0.25, 0.25))
				var yaw := rng.randf() * PI
				if name == "sorrel":
					_card(st, p + Vector3(0, 0.05, 0), size, rng, Vector3(rng.randf_range(-0.3, 0.3), 1.0, rng.randf_range(-0.3, 0.3)).normalized())
				else:
					_upright(st, p, yaw, size * rng.randf_range(0.8, 1.2), size * rng.randf_range(0.9, 1.15))
		"foxglove":
			# One to three tall spikes over a rosette of broad leaves.
			for i in rng.randi_range(1, 3):
				var p := Vector3(rng.randf_range(-0.2, 0.2), 0.0, rng.randf_range(-0.2, 0.2))
				var h := rng.randf_range(1.0, 1.5)
				_upright(st, p, rng.randf() * PI, 0.42, h, Rect2(0.0, 0.0, 0.5, 1.0))
			for i in 3:
				_card(st, Vector3(rng.randf_range(-0.2, 0.2), 0.12, rng.randf_range(-0.2, 0.2)), 0.55, rng, Vector3(rng.randf_range(-0.4, 0.4), 1.0, rng.randf_range(-0.4, 0.4)).normalized(), Rect2(0.5, 0.5, 0.5, 0.5))
		"ivy":
			# A spreading mat of ivy over the ground and up the foot of a trunk or wall.
			for i in rng.randi_range(5, 8):
				var p := Vector3(rng.randf_range(-0.8, 0.8), 0.04, rng.randf_range(-0.8, 0.8))
				_card(st, p, rng.randf_range(0.6, 0.9), rng, Vector3(rng.randf_range(-0.2, 0.2), 1.0, rng.randf_range(-0.2, 0.2)).normalized())
		"fungi":
			_fungi(st, rng, variant)
	st.index()
	st.set_material(fungi_material() if name == "fungi" else _material(name))
	var m := st.commit()
	_cache[key] = m
	return m


# ---- Shapes ---------------------------------------------------------------------------

## One card facing `n`, centered at p. uv: which part of the texture.
static func _card(st: SurfaceTool, p: Vector3, size: float, rng: RandomNumberGenerator, n: Vector3, uv := Rect2(0, 0, 1, 1)) -> void:
	var s1 := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized().rotated(n, rng.randf() * TAU)
	var s2 := n.cross(s1).normalized()
	var h1 := s1 * size * 0.5
	var h2 := s2 * size * 0.5
	var tint := Color(1, 1, 1).lerp(Color(0.82, 0.88, 0.75), rng.randf())
	_quad(st, [p - h1 - h2, p + h1 - h2, p + h1 + h2, p - h1 + h2], uv, (n + Vector3.UP).normalized(), tint)


## Two crossed vertical cards (a clump seen from any side). uv: texture part.
static func _upright(st: SurfaceTool, p: Vector3, yaw: float, w: float, h: float, uv := Rect2(0, 0, 1, 1)) -> void:
	for k in 2:
		var side := Vector3(cos(yaw + k * PI * 0.5), 0.0, sin(yaw + k * PI * 0.5)) * w * 0.5
		_quad(st, [p - side, p + side, p + side + Vector3.UP * h, p - side + Vector3.UP * h], uv, Vector3.UP, Color(1, 1, 1))


## A frond or cane: a card rising from `base` and arching out and over along `out`.
static func _bent_card(st: SurfaceTool, base: Vector3, out: Vector3, h: float, reach: float, w: float, rng: RandomNumberGenerator) -> void:
	var side := out.cross(Vector3.UP).normalized() * w * 0.5
	var mid := base + out * reach * 0.45 + Vector3.UP * h * 0.75
	var tip := base + out * reach + Vector3.UP * h * (0.55 + rng.randf() * 0.2)
	var tint := Color(1, 1, 1).lerp(Color(0.85, 0.82, 0.68), rng.randf() * 0.7)
	_quad(st, [base - side * 0.4, base + side * 0.4, mid + side, mid - side], Rect2(0, 0.5, 1, 0.5), (Vector3.UP + out * 0.3).normalized(), tint)
	_quad(st, [mid - side, mid + side, tip + side * 0.5, tip - side * 0.5], Rect2(0, 0, 1, 0.5), (Vector3.UP + out * 0.5).normalized(), tint)


static func _quad(st: SurfaceTool, c: Array, uv: Rect2, n: Vector3, tint: Color) -> void:
	var uvs := [Vector2(uv.position.x, uv.end.y), Vector2(uv.end.x, uv.end.y), Vector2(uv.end.x, uv.position.y), Vector2(uv.position.x, uv.position.y)]
	for i in [0, 1, 2, 0, 2, 3]:
		st.set_normal(n)
		st.set_color(tint)
		st.set_uv(uvs[i])
		st.add_vertex(c[i])


## Mushrooms (caps on stems, in a ring) or bracket fungus (half-moon shelves).
static func _fungi(st: SurfaceTool, rng: RandomNumberGenerator, variant: int) -> void:
	var cap_col: Color = [Color(0.62, 0.45, 0.3), Color(0.75, 0.68, 0.55), Color(0.55, 0.3, 0.18), Color(0.68, 0.58, 0.42)][variant]
	var stem_col := Color(0.82, 0.78, 0.68)
	if variant == 3:
		# Bracket fungus: shelves stacked on an invisible stump face, open toward +z.
		for i in rng.randi_range(3, 5):
			var y := 0.15 + i * rng.randf_range(0.12, 0.2)
			_disc(st, Vector3(rng.randf_range(-0.15, 0.15), y, 0.0), rng.randf_range(0.12, 0.22), 0.05, cap_col, true)
		return
	for i in rng.randi_range(4, 8):
		var p := Vector3(rng.randf_range(-0.35, 0.35), 0.0, rng.randf_range(-0.35, 0.35))
		var h := rng.randf_range(0.05, 0.16)
		var r := rng.randf_range(0.03, 0.08)
		_disc(st, p + Vector3(0, h * 0.5, 0), r * 0.3, h, stem_col, false)
		_disc(st, p + Vector3(0, h, 0), r, r * 0.6, cap_col, false)


## A little cylinder-ish dome (or a half shelf when `half`).
static func _disc(st: SurfaceTool, c: Vector3, r: float, h: float, col: Color, half: bool) -> void:
	var n := 8
	var arc := PI if half else TAU
	var top := c + Vector3.UP * h * 0.5
	for i in n:
		var a0 := arc * i / n
		var a1 := arc * (i + 1) / n
		var p0 := c + Vector3(cos(a0) * r, 0.0, sin(a0) * r)
		var p1 := c + Vector3(cos(a1) * r, 0.0, sin(a1) * r)
		for v in [[top, Vector3.UP], [p1, (p1 - c).normalized()], [p0, (p0 - c).normalized()]]:
			st.set_normal((v[1] as Vector3 + Vector3.UP * 0.5).normalized())
			st.set_color(col)
			st.add_vertex(v[0])
		var b0 := p0 - Vector3.UP * h * 0.5
		var b1 := p1 - Vector3.UP * h * 0.5
		for v in [p0, p1, b1, p0, b1, b0]:
			st.set_normal((v - c).normalized())
			st.set_color(col.darkened(0.25))
			st.add_vertex(v)


# ---- Materials and textures -----------------------------------------------------------

static func fungi_material() -> StandardMaterial3D:
	if not _mats.has("fungi"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 0.75
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mats.fungi = m
	return _mats.fungi


static func _material(name: String) -> StandardMaterial3D:
	if _mats.has(name):
		return _mats[name]
	var m := StandardMaterial3D.new()
	m.albedo_texture = _texture(name)
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.3 if name == "bracken" else 0.45
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.6 if name == "holly" else 0.9
	m.metallic_specular = 0.35 if name == "holly" else 0.15
	m.backlight_enabled = name != "holly" and name != "bracken"
	m.backlight = Color(0.18, 0.22, 0.08)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
	# Big fronds and shrubs fade out well before they fill the camera; small plants only very close.
	var big := name in ["bracken", "bramble", "holly", "foxglove"]
	m.distance_fade_min_distance = 1.6 if big else 0.4
	m.distance_fade_max_distance = 3.4 if big else 1.2
	_mats[name] = m
	return m


static func _texture(name: String) -> ImageTexture:
	return ImageTexture.create_from_image(BakeCache.image("plant_" + name, ["res://game/world/plant_kit.gd"], func() -> Image: return _image(name)))


static func _image(name: String) -> Image:
	var w := 256
	var img := Image.create(w, w, true, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name) + 5
	match name:
		"bracken":
			# The whole card is one frond: base at the bottom (widest), tip at the top.
			_frond(img, Vector2(128, 252), Vector2(128, 4), 118.0, Color(0.2, 0.3, 0.13), Color(0.32, 0.41, 0.18), rng, 0.08)
		"bramble":
			# A cane with alternate toothed leaves, a few blackberries and white flowers.
			_line(img, Vector2(128, 255), Vector2(128, 2), 2.5, Color(0.3, 0.17, 0.15))
			for i in 9:
				var y := 245.0 - i * 27.0
				var sgn := 1.0 if i % 2 == 0 else -1.0
				for k in 3:
					var a := -PI * 0.5 + sgn * (0.6 + 0.45 * (k - 1))
					_blob(img, Vector2(128 + sgn * 6, y) + Vector2(cos(a), sin(a)) * 22.0, 15.0, 9.0, a, Color(0.17, 0.25, 0.12).lerp(Color(0.3, 0.36, 0.17), rng.randf()), 0.12)
				if rng.randf() < 0.45:
					_blob(img, Vector2(128 - sgn * 14, y - 8), 5.0, 5.0, 0.0, Color(0.08, 0.04, 0.08) if rng.randf() < 0.6 else Color(0.85, 0.82, 0.78), 0.0)
		"holly":
			for i in 70:
				var c := Vector2(128, 128) + Vector2.from_angle(rng.randf() * TAU) * pow(rng.randf(), 0.6) * 105.0
				_holly_leaf(img, c, rng.randf() * TAU, rng.randf_range(14, 20), Color(0.12, 0.22, 0.11).lerp(Color(0.24, 0.36, 0.17), rng.randf()))
			for i in 16:
				var c := Vector2(128, 128) + Vector2.from_angle(rng.randf() * TAU) * rng.randf() * 90.0
				for k in 3:
					_blob(img, c + Vector2(rng.randf_range(-5, 5), rng.randf_range(-5, 5)), 4.0, 4.0, 0.0, Color(0.62, 0.06, 0.05), 0.0)
		"bluebell":
			# Strap leaves at the base; arching stems with drooping violet-blue bells on one side.
			for i in 7:
				var x := 30.0 + i * 32.0 + rng.randf_range(-8, 8)
				_line(img, Vector2(x, 255), Vector2(x + rng.randf_range(-30, 30), 150), 5.0, Color(0.2, 0.32, 0.15))
			for i in 5:
				var x := 45.0 + i * 40.0 + rng.randf_range(-10, 10)
				var top := Vector2(x + 20, 40 + rng.randf_range(0, 40))
				_line(img, Vector2(x, 255), top, 2.0, Color(0.24, 0.34, 0.16))
				for k in 6:
					var t := 0.15 + k * 0.13
					var p := Vector2(x, 255).lerp(top, 1.0 - t * 0.6) + Vector2(8, 10)
					_blob(img, p, 5.0, 8.0, 0.3, Color(0.36, 0.33, 0.68).lerp(Color(0.48, 0.42, 0.78), rng.randf()), 0.15)
		"foxglove":
			# Left half: a spike of purple bells. Bottom-right quarter: a broad rosette leaf.
			_line(img, Vector2(64, 255), Vector2(64, 4), 3.0, Color(0.26, 0.34, 0.18))
			for k in 16:
				var y := 30.0 + k * 13.0
				var s := 1.0 - k / 22.0
				var sgn := 1.0 if k % 2 == 0 else -1.0
				_blob(img, Vector2(64 + sgn * 8 * s, y), 7.0 * s + 2.0, 9.0 * s + 3.0, sgn * 0.5, Color(0.58, 0.3, 0.52).lerp(Color(0.7, 0.4, 0.62), rng.randf()), 0.2)
			_blob(img, Vector2(192, 192), 52.0, 26.0, -0.7, Color(0.26, 0.35, 0.18), 0.1)
		"garlic":
			for i in 8:
				var x := 30.0 + i * 28.0
				_blob(img, Vector2(x, 180), 14.0, 60.0, rng.randf_range(-0.3, 0.3), Color(0.24, 0.38, 0.18).lerp(Color(0.33, 0.46, 0.22), rng.randf()), 0.1)
			for i in 4:
				var c := Vector2(50 + i * 52.0, 50 + rng.randf_range(0, 30))
				_line(img, c, c + Vector2(0, 140), 2.0, Color(0.3, 0.42, 0.2))
				for k in 10:
					_blob(img, c + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0, 14), 4.0, 4.0, 0.0, Color(0.92, 0.92, 0.88), 0.0)
		"sorrel":
			for i in 10:
				var c := Vector2(128, 128) + Vector2.from_angle(rng.randf() * TAU) * rng.randf() * 90.0
				var col := Color(0.34, 0.5, 0.24).lerp(Color(0.46, 0.6, 0.3), rng.randf())
				for k in 3:
					var a := k * TAU / 3.0 + rng.randf() * 0.3
					_blob(img, c + Vector2.from_angle(a) * 9.0, 9.0, 8.0, a, col, 0.1)
		"ivy":
			for i in 60:
				var c := Vector2(128, 128) + Vector2.from_angle(rng.randf() * TAU) * pow(rng.randf(), 0.7) * 108.0
				_ivy_leaf(img, c, rng.randf() * TAU, rng.randf_range(10, 15), Color(0.08, 0.15, 0.08).lerp(Color(0.18, 0.27, 0.12), rng.randf()))
	img.generate_mipmaps()
	return img


static func _line(img: Image, a: Vector2, b: Vector2, width: float, col: Color) -> void:
	var steps := int(a.distance_to(b))
	for i in steps:
		var p := a.lerp(b, float(i) / steps)
		for dx in range(-int(width), int(width) + 1):
			_px(img, int(p.x) + dx, int(p.y), col)


## An oval with a pointed tip (leaf, petal, bell). edge = darker rim share.
static func _blob(img: Image, c: Vector2, length: float, width: float, rot: float, col: Color, edge: float) -> void:
	var cr := cos(rot)
	var sr := sin(rot)
	var r := int(maxf(length, width)) + 1
	for py in range(int(c.y) - r, int(c.y) + r + 1):
		for px in range(int(c.x) - r, int(c.x) + r + 1):
			var dx := px - c.x
			var dy := py - c.y
			var lx := (dx * cr + dy * sr) / length
			var ly := (-dx * sr + dy * cr) / width
			var e := lx * lx + ly * ly
			if e <= 1.0:
				var shade := 1.0 - edge * e
				_px(img, px, py, Color(col.r * shade, col.g * shade, col.b * shade, 1.0))


## A tapering frond: midrib from a to b with paired pinnae, longest near the base.
static func _frond(img: Image, a: Vector2, b: Vector2, spread: float, dark: Color, light: Color, rng: RandomNumberGenerator, brown: float) -> void:
	_line(img, a, b, 1.5, dark.darkened(0.3))
	var length := a.distance_to(b)
	var dir := (b - a).normalized()
	var k := 0.0
	while k < length:
		var t := k / length
		var base := a + dir * k
		var pl := spread * (1.0 - t) * (0.6 + 0.4 * sin(t * PI * 0.9 + 0.3))
		var col := dark.lerp(light, rng.randf())
		if rng.randf() < brown:
			col = col.lerp(Color(0.5, 0.35, 0.16), 0.6)  # a browning pinna
		for sgn: float in [-1.0, 1.0]:
			var pd := (dir.orthogonal() * sgn + dir * 0.25).normalized()
			# Each pinna is a row of small lobes with gaps, so the frond reads lacy, not solid.
			var lobes := maxi(2, int(pl / 7.0))
			for j in lobes:
				var q := base + pd * pl * (float(j) + 0.5) / lobes
				_blob(img, q, maxf(2.5, pl * 0.44 / lobes), maxf(2.0, pl * 0.055), pd.angle() + 0.6 * sgn, col, 0.15)
		k += 9.0


static func _holly_leaf(img: Image, c: Vector2, rot: float, length: float, col: Color) -> void:
	# An oval with wavy, spiny edges and a glossy light midrib.
	var cr := cos(rot)
	var sr := sin(rot)
	var r := int(length) + 1
	for py in range(int(c.y) - r, int(c.y) + r + 1):
		for px in range(int(c.x) - r, int(c.x) + r + 1):
			var dx := px - c.x
			var dy := py - c.y
			var t := (dx * cr + dy * sr) / length
			var s := absf(-dx * sr + dy * cr) / (length * 0.5)
			if absf(t) <= 1.0 and s <= sqrt(1.0 - t * t) * (0.75 + 0.25 * absf(sin(t * 9.0))):
				var gloss := 1.25 if s < 0.12 else (1.0 + 0.2 * (1.0 - s))
				_px(img, px, py, Color(col.r * gloss, col.g * gloss, col.b * gloss, 1.0))


static func _ivy_leaf(img: Image, c: Vector2, rot: float, size: float, col: Color) -> void:
	# Three to five pointed lobes from one point, pale veins.
	for k in 5:
		var a := rot + (k - 2) * 0.55
		var lobe := size * (1.0 if k == 2 else 0.7)
		_blob(img, c + Vector2.from_angle(a) * lobe * 0.5, lobe * 0.55, lobe * 0.32, a, col, 0.15)


static func _px(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, col)
