extends RefCounted
## Hand-painted finish for the cut-out foliage cards drawn in code (tree leaf clumps
## in tree_species.gd, plant cards in plant_kit.gd), DESIGN.md 12.1 (2026-11-28):
## fine pixel speckle is merged into flat brush patches, the tops of leaves catch
## painted light and their undersides fall into shade, and the cut-out edge stays
## hard (alpha is left alone). Same idea as tools/paint_textures.gd for the ground.

## Brush patch radius, in pixels (on a 256 px card).
const BRUSH := 2
## Painted light from above: how much lighter the top of a card is than the bottom.
const TOP_LIGHT := 0.2
## Lit top edges (where a leaf's upper side meets empty space) and shaded lower edges.
const RIM_LIGHT := 0.3
const RIM_SHADE := 0.22


## Repaints `img` in place (RGBA8, cut-out alpha). Rebuilds its mipmaps if it had them.
static func card(img: Image) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var had_mips := img.has_mipmaps()
	if had_mips:
		img.clear_mipmaps()
	var px: Array[Color] = []
	px.resize(w * h)
	var solid := PackedByteArray()
	solid.resize(w * h)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			px[y * w + x] = c
			solid[y * w + x] = 1 if c.a >= 0.5 else 0
	var r := BRUSH
	var n_max := (r + 1) * (r + 1)
	for y in h:
		for x in w:
			var i := y * w + x
			if solid[i] == 0:
				continue
			# Kuwahara over the solid pixels only: the evenest neighbouring square wins.
			var best := INF
			var best_c := px[i]
			for q: Vector2i in [Vector2i(-r, -r), Vector2i(0, -r), Vector2i(-r, 0), Vector2i(0, 0)]:
				var sr := 0.0
				var sg := 0.0
				var sb := 0.0
				var sl := 0.0
				var sl2 := 0.0
				var n := 0
				for dy in r + 1:
					var yy := y + q.y + dy
					if yy < 0 or yy >= h:
						continue
					for dx in r + 1:
						var xx := x + q.x + dx
						if xx < 0 or xx >= w or solid[yy * w + xx] == 0:
							continue
						var c := px[yy * w + xx]
						var l := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
						sr += c.r
						sg += c.g
						sb += c.b
						sl += l
						sl2 += l * l
						n += 1
				if n * 2 < n_max:
					continue
				var variance := sl2 / n - (sl / n) * (sl / n)
				if variance < best:
					best = variance
					best_c = Color(sr / n, sg / n, sb / n)
			var k := 1.0 + TOP_LIGHT * (0.5 - float(y) / h) * 2.0
			# Upper edge (empty just above): painted highlight. Lower edge: painted shade.
			if y >= 2 and solid[(y - 2) * w + x] == 0:
				k += RIM_LIGHT
			elif y + 2 < h and solid[(y + 2) * w + x] == 0:
				k -= RIM_SHADE
			var a := px[i].a
			img.set_pixel(x, y, Color(clampf(best_c.r * k, 0.0, 1.0), clampf(best_c.g * k, 0.0, 1.0), clampf(best_c.b * k, 0.0, 1.0), a))
	if had_mips:
		img.generate_mipmaps()
	return img
