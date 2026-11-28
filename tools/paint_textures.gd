extends SceneTree
## Turns the photo-scanned textures in assets/textures/<name>/ into hand-painted ones
## in assets/textures_painted/<name>/ (owner's decision 2026-11-28, DESIGN.md 12.1):
## small (256 px), broad flat brush patches instead of photo grain, light and shade
## painted into the colour from the old normal map, slow warm/cool colour drift,
## a much softer normal map and a flat, matte roughness.
##
## The photo textures stay where they are, so this can be re-run or undone.
## Run (from the project folder):
##   Godot_console.exe --headless --path . --script res://tools/paint_textures.gd
## Optional: name folders after "--" to redo only those.

const P := preload("res://assets/outpost/materials/painter.gd")
const SRC := "res://assets/textures/"
const DST := "res://assets/textures_painted/"
## Longest side of a painted texture, in pixels.
const SIZE := 256
## Brush patch radius for the painterly (Kuwahara) filter.
const BRUSH := 2
## Fine-grained ground textures (blades, leaves, grit) are softened first, then painted.
const BIG_BRUSH := {"grass": 3, "moss": 3, "leaf_litter": 2, "scree": 2, "dirt_dark": 3, "mud": 3, "path": 2}
## How much of the original fine grain those keep, as faint brush texture.
const GRAIN_KEEP := 0.3
## How much of the old bumpiness the new normal map keeps.
const NORMAL_KEEP := 0.4
## Painted light comes from the upper left, as in classic hand-painted textures.
const LIGHT := Vector3(-0.45, 0.55, 0.7)
## Painted materials are matte.
const ROUGHNESS := 0.88


func _initialize() -> void:
	var only := OS.get_cmdline_user_args()
	var dir := DirAccess.open(SRC)
	var seed := 300
	for name in dir.get_directories():
		seed += 1
		if not only.is_empty() and not name in only:
			continue
		var t0 := Time.get_ticks_msec()
		_paint(name, seed)
		print("painted %s (%d ms)" % [name, Time.get_ticks_msec() - t0])
	quit()


func _paint(name: String, seed: int) -> void:
	var col := Image.load_from_file(ProjectSettings.globalize_path(SRC + name + "/color.jpg"))
	var nrm := Image.load_from_file(ProjectSettings.globalize_path(SRC + name + "/normal.jpg"))
	col.convert(Image.FORMAT_RGB8)
	nrm.convert(Image.FORMAT_RGB8)
	var k := float(SIZE) / maxf(col.get_width(), col.get_height())
	var w := maxi(int(col.get_width() * k), 16)
	var h := maxi(int(col.get_height() * k), 16)
	col.resize(w, h, Image.INTERPOLATE_LANCZOS)
	nrm.resize(w, h, Image.INTERPOLATE_LANCZOS)
	var painted: Array[Color]
	var detail := PackedFloat32Array()
	detail.resize(w * h)
	if BIG_BRUSH.has(name):
		# Fine grain (blades, leaves, grit): blur it away to big soft blotches first, paint
		# those, then lay a faint trace of the old grain back on top as brush texture.
		var soft := col.duplicate() as Image
		soft.resize(maxi(w / 4, 8), maxi(h / 4, 8), Image.INTERPOLATE_LANCZOS)
		soft.resize(w, h, Image.INTERPOLATE_CUBIC)
		painted = _kuwahara(soft, BIG_BRUSH[name])
		nrm.resize(maxi(w / 4, 8), maxi(h / 4, 8), Image.INTERPOLATE_LANCZOS)
		nrm.resize(w, h, Image.INTERPOLATE_CUBIC)
		for y in h:
			for x in w:
				var a := col.get_pixel(x, y)
				var b := soft.get_pixel(x, y)
				detail[y * w + x] = (a.get_luminance() - b.get_luminance()) * GRAIN_KEEP
	else:
		painted = _kuwahara(col, BRUSH)
	var light := LIGHT.normalized()
	var out_c := Image.create_empty(w, h, false, Image.FORMAT_RGB8)
	var out_n := Image.create_empty(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		for x in w:
			var u := (x + 0.5) / w
			var v := (y + 0.5) / h
			var nc := nrm.get_pixel(x, y)
			var n := Vector3(nc.r * 2.0 - 1.0, nc.g * 2.0 - 1.0, nc.b * 2.0 - 1.0).normalized()
			# Light and shade painted in: ridges facing the light are lifted, hollows darkened.
			var lit := n.dot(light) - Vector3(0, 0, 1).dot(light)
			var c := painted[y * w + x]
			c = Color(c.r + detail[y * w + x], c.g + detail[y * w + x], c.b + detail[y * w + x])
			c = c * (1.0 + 1.1 * lit)
			if lit > 0.12:
				c = c.lerp(c.lightened(0.25), smoothstep(0.12, 0.3, lit) * 0.5)
			# Broad painted colour drift: big light and dark areas, warmer and cooler patches.
			# (Whole-number periods, so the texture still tiles.)
			var tone := P.fbm(u, v, 3, 3, seed, 3)
			var warm := P.fbm(u, v, 2, 2, seed + 50, 2)
			c = c * (0.84 + 0.32 * tone)
			c = c.lerp(Color(c.r * 1.08, c.g * 1.0, c.b * 0.86), smoothstep(0.45, 0.7, warm))
			c = c.lerp(Color(c.r * 0.96, c.g * 0.99, c.b * 1.03), smoothstep(0.55, 0.3, warm) * 0.6)
			# A touch more colour than a photo: the world grade calms it again.
			var hsv_s := minf(c.s * 1.15, 1.0)
			c = Color.from_hsv(c.h, hsv_s, clampf(c.v, 0.0, 1.0))
			out_c.set_pixel(x, y, c)
			var fn := Vector3(0, 0, 1).lerp(n, NORMAL_KEEP).normalized()
			out_n.set_pixel(x, y, Color(fn.x * 0.5 + 0.5, fn.y * 0.5 + 0.5, fn.z * 0.5 + 0.5))
	var rough := Image.create_empty(8, 8, false, Image.FORMAT_RGB8)
	rough.fill(Color(ROUGHNESS, ROUGHNESS, ROUGHNESS))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DST + name))
	out_c.save_png(DST + name + "/color.png")
	out_n.save_png(DST + name + "/normal.png")
	rough.save_png(DST + name + "/rough.png")


## Kuwahara filter: every pixel takes the average colour of whichever of its four
## neighbouring squares is the most even. Fine grain disappears and edges stay
## sharp, so the photo turns into flat brush patches. Wraps at the edges (tiling).
func _kuwahara(img: Image, r: int) -> Array[Color]:
	var w := img.get_width()
	var h := img.get_height()
	var px: Array[Color] = []
	px.resize(w * h)
	var lum := PackedFloat32Array()
	lum.resize(w * h)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			px[y * w + x] = c
			lum[y * w + x] = c.r * 0.3 + c.g * 0.59 + c.b * 0.11
	var out: Array[Color] = []
	out.resize(w * h)
	var quads := [Vector2i(-r, -r), Vector2i(0, -r), Vector2i(-r, 0), Vector2i(0, 0)]
	var n := float((r + 1) * (r + 1))
	for y in h:
		for x in w:
			var best := INF
			var best_c := Color.BLACK
			for q: Vector2i in quads:
				var sr := 0.0
				var sg := 0.0
				var sb := 0.0
				var sl := 0.0
				var sl2 := 0.0
				for dy in r + 1:
					var yy := posmod(y + q.y + dy, h) * w
					for dx in r + 1:
						var i := yy + posmod(x + q.x + dx, w)
						var c := px[i]
						sr += c.r
						sg += c.g
						sb += c.b
						var l := lum[i]
						sl += l
						sl2 += l * l
				var variance := sl2 / n - (sl / n) * (sl / n)
				if variance < best:
					best = variance
					best_c = Color(sr / n, sg / n, sb / n)
			out[y * w + x] = best_c
	return out
