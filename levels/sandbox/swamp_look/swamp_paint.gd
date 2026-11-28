extends RefCounted
## Hand-painted textures for the swamp look test, drawn in code: small (128-512 px),
## broad painted colour shifts and shading baked into the colour, no photo detail.
## Plant textures (reeds, moss, twigs) are cut-outs: alpha is either 0 or 1, so their
## edges stay hard and a little crunchy, like older online RPGs.

const P := preload("res://assets/outpost/materials/painter.gd")


static func _img(w: int, h: int, f: Callable) -> Image:
	var data := PackedByteArray()
	data.resize(w * h * 4)
	var i := 0
	for y in h:
		for x in w:
			var c: Color = f.call((x + 0.5) / w, (y + 0.5) / h)
			data[i] = clampi(int(c.r * 255.0), 0, 255)
			data[i + 1] = clampi(int(c.g * 255.0), 0, 255)
			data[i + 2] = clampi(int(c.b * 255.0), 0, 255)
			data[i + 3] = clampi(int(c.a * 255.0), 0, 255)
			i += 4
	var img := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)
	img.generate_mipmaps()
	return img


static func tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


## Mud and dead moss: olive and brown blotches, darker wet patches, pale dry straw strokes.
static func mud() -> Image:
	return _img(256, 256, func(u: float, v: float) -> Color:
		var big := P.fbm(u, v, 3, 3, 11)
		var mid := P.fbm(u, v, 8, 8, 12, 3)
		var c := Color(0.20, 0.17, 0.11).lerp(Color(0.27, 0.25, 0.13), smoothstep(0.35, 0.65, big))
		c = c.lerp(Color(0.12, 0.10, 0.07), smoothstep(0.55, 0.72, mid) * 0.7)
		var straw := P.fbm(u, v, 6, 40, 13, 2)
		if straw > 0.66:
			c = c.lerp(Color(0.42, 0.36, 0.2), 0.45)
		return c * (0.85 + 0.3 * P.vnoise(u, v, 32, 32, 14)))


## Bark: long vertical grooves, grey-brown, lighter painted ridges.
static func bark() -> Image:
	return _img(256, 256, func(u: float, v: float) -> Color:
		var g := P.fbm(u, v, 14, 2, 21, 3)
		var c := Color(0.21, 0.17, 0.12).lerp(Color(0.36, 0.31, 0.24), smoothstep(0.3, 0.7, g))
		if absf(P.fbm(u, v, 10, 3, 22, 2) - 0.5) < 0.04:
			c = c * 0.5
		c = c.lerp(Color(0.26, 0.28, 0.17), smoothstep(0.62, 0.75, P.fbm(u, v, 4, 4, 23)) * 0.6)
		return c)


## A clump of reeds and sedge: tapering blades from the bottom edge, dark at the foot,
## straw-coloured at the tips, lit down one edge. A few cattail heads.
static func reeds(seed: int) -> Image:
	var w := 256
	var h := 256
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.27, 0.16, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for b in 30:
		var x0 := rng.randf_range(0.12, 0.88) * w
		var length := rng.randf_range(0.45, 0.98) * h
		var lean := rng.randf_range(-0.35, 0.35)
		var bend := rng.randf_range(-40.0, 40.0)
		var base_w := rng.randf_range(1.4, 3.0)
		var tip_col := Color(0.55, 0.47, 0.27).lerp(Color(0.4, 0.4, 0.22), rng.randf())
		var foot_col := Color(0.13, 0.14, 0.08)
		for r in int(length):
			var t := r / length
			var cx := x0 + lean * r + bend * t * t
			var half := lerpf(base_w, 0.6, t)
			var y := h - 1 - r
			var col := foot_col.lerp(tip_col, smoothstep(0.0, 0.8, t))
			for x in range(int(cx - half), int(cx + half) + 1):
				if x < 0 or x >= w:
					continue
				var side := (x - cx) / maxf(half, 0.5)
				var k := 1.15 if side < -0.2 else (0.75 if side > 0.4 else 1.0)
				img.set_pixel(x, y, Color(col.r * k, col.g * k, col.b * k, 1.0))
		if rng.randf() < 0.2 and length > 0.7 * h:
			# Cattail head near the top.
			var tcx := x0 + lean * length * 0.85 + bend * 0.72
			for r in range(int(length * 0.78), int(length * 0.9)):
				for x in range(int(tcx - 3.5), int(tcx + 4.5)):
					if x >= 0 and x < w:
						img.set_pixel(x, h - 1 - r, Color(0.2, 0.12, 0.07, 1.0))
	img.generate_mipmaps()
	return img


## Hanging moss: ragged strands from the top edge, tan and brown with dark grooves.
static func moss() -> Image:
	var w := 128
	var h := 512
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.35, 0.28, 0.17, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 51
	for s in 9:
		var cx := rng.randf_range(0.1, 0.9) * w
		var length := rng.randf_range(0.35, 1.0) * h
		var top_w := rng.randf_range(7.0, 16.0)
		var col := Color(0.42, 0.33, 0.2).lerp(Color(0.33, 0.3, 0.18), rng.randf())
		for y in int(length):
			var t := y / length
			var wob := sin(y * 0.05 + s) * 3.0
			var half := top_w * (1.0 - t) * (0.75 + 0.5 * P.vnoise(0.5, y / float(h), 1, 40, s + 60))
			for x in range(int(cx + wob - half), int(cx + wob + half) + 1):
				if x < 0 or x >= w:
					continue
				var side := (x - cx - wob) / maxf(half, 0.5)
				var k := 0.55 + 0.6 * (1.0 - absf(side))
				if P.vnoise(x / float(w), y / float(h), 24, 6, s + 70) > 0.72:
					k *= 0.6
				k *= lerpf(1.0, 0.7, t)
				img.set_pixel(x, y, Color(col.r * k, col.g * k, col.b * k, 1.0))
	img.generate_mipmaps()
	return img


## A spray of dead twigs for the feathery dead-conifer tiers: a stem along the middle
## from left to right, side twigs branching off and drooping.
static func twigs() -> Image:
	var w := 256
	var h := 128
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.12, 0.1, 0.08, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	_twig(img, Vector2(0, h * 0.45), 0.08, w * 0.98, 3.0, 2, rng)
	img.generate_mipmaps()
	return img


static func _twig(img: Image, from: Vector2, angle: float, length: float, width: float, depth: int, rng: RandomNumberGenerator) -> void:
	var steps := int(length)
	var p := from
	var a := angle
	for i in steps:
		a += 0.004 + rng.randf_range(-0.03, 0.03)
		p += Vector2(cos(a), sin(a))
		var wd := lerpf(width, 0.6, float(i) / steps)
		for dy in range(-int(wd), int(wd) + 1):
			for dx in range(-int(wd), int(wd) + 1):
				var q := Vector2i(int(p.x) + dx, int(p.y) + dy)
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height():
					img.set_pixelv(q, Color(0.14, 0.11, 0.08, 1.0))
		if depth > 0 and i > 6 and rng.randf() < 0.09:
			var side := 1.0 if rng.randf() < 0.5 else -1.0
			_twig(img, p, a + side * rng.randf_range(0.5, 1.0), (steps - i) * rng.randf_range(0.25, 0.5), wd * 0.6, depth - 1, rng)
