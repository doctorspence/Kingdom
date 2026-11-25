extends RefCounted
## Paints the White Knights Outpost textures in code (hand-painted look: broad colour shifts,
## painted folds, highlights, dirt and wear; no photo detail). The exporter saves them as PNG
## files in textures/, so any of them can later be painted over by hand or swapped for AI art
## with the same name and size.
##
## Tiling textures cover a fixed size in meters (asset UVs are in meters):
##   oak 2 m, iron 0.5 m, gold 0.5 m, linen 1 m, stripes 1 m (one red + one ivory stripe),
##   rope 0.25 x 1 m, limestone 1 m. Heraldry and parchment are mapped 0..1 across their face.

# The White Knights palette (DESIGN_INBOX 2026-11-25).
const IVORY := Color("#E5E0CE")
const RED := Color("#A52F35")
const GOLD := Color("#C3A45B")
const IRON := Color("#292B30")
const MUD := Color(0.24, 0.19, 0.13)


## name -> [width, height, painter Callable]
static func all() -> Dictionary:
	return {
		"heraldry_banner": [512, 1024, heraldry_banner],
		"heraldry_square": [512, 512, heraldry_square],
		"heraldry_pennant": [640, 256, heraldry_pennant],
		"oak_stained": [256, 256, oak.bind(Color(0.29, 0.19, 0.12), 11)],
		"oak_weathered": [256, 256, oak.bind(Color(0.40, 0.34, 0.28), 12)],
		"iron": [128, 128, iron],
		"gold": [128, 128, gold],
		"linen": [256, 256, linen],
		"stripes": [256, 256, stripes],
		"rope": [64, 256, rope],
		"limestone": [256, 256, limestone],
		"parchment": [256, 320, parchment],
		"shingles": [256, 256, shingles],
		"stencil": [256, 256, stencil],
		"warning_board": [256, 320, warning_board],
		"daub": [256, 256, daub],
		"thatch": [256, 256, thatch],
		"earth_floor": [256, 256, earth_floor],
		"rubble": [256, 256, rubble],
		"inn_sign": [256, 320, inn_sign],
	}


static func paint(name: String) -> Image:
	var e: Array = all()[name]
	var w: int = e[0]
	var h: int = e[1]
	var f: Callable = e[2]
	var data := PackedByteArray()
	data.resize(w * h * 4)
	var i := 0
	for y in h:
		for x in w:
			var c: Color = f.call((x + 0.5) / w, (y + 0.5) / h, x, y, w, h)
			data[i] = clampi(int(c.r * 255.0 + 0.5), 0, 255)
			data[i + 1] = clampi(int(c.g * 255.0 + 0.5), 0, 255)
			data[i + 2] = clampi(int(c.b * 255.0 + 0.5), 0, 255)
			data[i + 3] = clampi(int(c.a * 255.0 + 0.5), 0, 255)
			i += 4
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)


# ---------------------------------------------------------------- noise (tiles seamlessly)

static func _hash(ix: int, iy: int, s: int) -> float:
	var h := (ix * 374761393 + iy * 668265263 + s * 1442695041) & 0xffffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0xffffffff
	h = h ^ (h >> 16)
	return float(h & 0xffff) / 65535.0


## Value noise on a lattice of cx by cy cells that wraps at the tile edge.
static func vnoise(u: float, v: float, cx: int, cy: int, s: int) -> float:
	var x := u * cx
	var y := v * cy
	var x0 := floori(x)
	var y0 := floori(y)
	var fx := x - x0
	var fy := y - y0
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var xa := posmod(x0, cx)
	var xb := posmod(x0 + 1, cx)
	var ya := posmod(y0, cy)
	var yb := posmod(y0 + 1, cy)
	var a := _hash(xa, ya, s)
	var b := _hash(xb, ya, s)
	var c := _hash(xa, yb, s)
	var d := _hash(xb, yb, s)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


static func fbm(u: float, v: float, cx: int, cy: int, s: int, octaves := 4) -> float:
	var sum := 0.0
	var amp := 0.5
	var tot := 0.0
	for o in octaves:
		sum += vnoise(u, v, cx << o, cy << o, s + o * 17) * amp
		tot += amp
		amp *= 0.5
	return sum / tot


static func _shade(c: Color, k: float) -> Color:
	return Color(c.r * k, c.g * k, c.b * k, c.a)


static func _mix(a: Color, b: Color, t: float) -> Color:
	t = clampf(t, 0.0, 1.0)
	return Color(lerpf(a.r, b.r, t), lerpf(a.g, b.g, t), lerpf(a.b, b.b, t), lerpf(a.a, b.a, t))


# ---------------------------------------------------------------- the emblem

## Half-width of a cross arm at distance t (0 = centre, 1 = arm end): narrow at the centre,
## flaring to wide straight ends (a cross pattee). One shape for every White Knights emblem.
static func arm_width(t: float) -> float:
	return 0.12 + 0.34 * t * t


## Signed distance to the cross (negative inside), in units of the arm length.
static func cross_sdf(a: float, b: float) -> float:
	var ta := minf(absf(a), 1.0)
	var tb := minf(absf(b), 1.0)
	var dh := maxf(absf(a) - 1.0, absf(b) - arm_width(ta))
	var dv := maxf(absf(b) - 1.0, absf(a) - arm_width(tb))
	return minf(dh, dv)


## The cross outline as a polygon (arm length 1), for carved and embossed versions.
static func cross_polygon(steps := 6) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for arm in 4:
		var rot := Transform2D(arm * PI * 0.5, Vector2.ZERO)
		# One arm pointing +x: up the lower flank to the end, across, back along the upper flank.
		var side := PackedVector2Array()
		for i in steps + 1:
			var t := lerpf(arm_width(0.0), 1.0, float(i) / steps)
			side.append(Vector2(t, -arm_width(t)))
		for i in range(steps, -1, -1):
			var t := lerpf(arm_width(0.0), 1.0, float(i) / steps)
			side.append(Vector2(t, arm_width(t)))
		for p in side:
			pts.append(rot * p)
	return pts


## Paints the red cross over `base`. (a, b): position in arm lengths; px = one pixel in arm lengths.
static func _emblem(base: Color, a: float, b: float, px: float, u: float, v: float, s: int) -> Color:
	var d := cross_sdf(a, b)
	var cov := clampf(0.5 - d / (px * 1.4), 0.0, 1.0)
	if cov <= 0.0:
		return base
	var red := _shade(RED, 0.9 + 0.2 * fbm(u, v, 6, 6, s + 5))
	# Painted rim: darker toward the edge, a soft highlight on the upper-left flanks.
	red = _shade(red, lerpf(0.72, 1.0, smoothstep(0.0, 0.05, -d)))
	red = _shade(red, 1.0 + 0.12 * clampf((-a - b) * 0.5, 0.0, 1.0) * smoothstep(0.02, 0.12, -d))
	# Worn paint: small flakes where the field shows through.
	red = _mix(red, base, smoothstep(0.7, 0.8, fbm(u, v, 40, 40, s + 9, 3)) * 0.45)
	return _mix(base, red, cov)


# ---------------------------------------------------------------- painters
# Each painter: (u, v, x, y, w, h) -> Color. u, v run 0..1 across the image (v down).

## Tall banner: ivory cloth, painted folds, tarnished gold trim on the sides and the bottom,
## the cross in the upper middle, mud and grime toward the hem, a frayed bottom edge (alpha).
static func heraldry_banner(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var c := _shade(IVORY, 0.88 + 0.12 * fbm(u, v, 3, 6, 101))
	# Folds hang straight down: soft light and dark bands across the width.
	var fold := sin(u * TAU * 3.0 + 1.6 * fbm(u, v, 2, 4, 102) + 0.4)
	c = _shade(c, 1.0 + 0.08 * fold)
	# Shadow just under the hanging bar.
	c = _shade(c, lerpf(0.78, 1.0, smoothstep(0.0, 0.05, v)))
	# Tarnished gold trim, inset from the edge.
	var ex := minf(x, w - 1 - x)
	var ey := h - 1 - y
	var trim := (ex >= 10 and ex < 22 and ey >= 10) or (ey >= 10 and ey < 22 and ex >= 10)
	if trim:
		c = _mix(_shade(GOLD, 0.8 + 0.25 * fbm(u, v, 16, 32, 103)), Color(0.36, 0.3, 0.17), 0.4 * fbm(u, v, 8, 16, 104))
	# The emblem.
	var r := 0.37 * w
	c = _emblem(c, (x - 0.5 * w) / r, (y - 0.36 * h) / r, 1.0 / r, u, v, 105)
	# Grime climbing from the hem, plus a few stains.
	var g := smoothstep(0.55, 1.0, v) * (0.45 + 0.55 * fbm(u, v, 6, 12, 106))
	c = _mix(c, MUD, g * 0.75)
	c = _mix(c, Color(0.5, 0.42, 0.3), smoothstep(0.6, 0.75, fbm(u, v, 5, 10, 107)) * 0.22)
	c = _shade(c, 0.94)
	# Edges darker, like a painted vignette.
	c = _shade(c, lerpf(0.82, 1.0, smoothstep(0.0, 0.06, minf(u, 1.0 - u))))
	# Frayed hem.
	var fray := 0.012 + 0.012 * fbm(u, 0.5, 64, 1, 108, 2)
	c.a = 0.0 if v > 1.0 - fray else 1.0
	return c


## Square emblem for shields, signboards, plaques and pennants: painted ivory field,
## the cross, scratches and grime.
static func heraldry_square(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var c := _shade(IVORY, 0.86 + 0.14 * fbm(u, v, 3, 3, 201))
	# A faint top-left light, painted in.
	c = _shade(c, 1.06 - 0.12 * (u + v) * 0.5)
	var r := 0.43 * w
	c = _emblem(c, (x - 0.5 * w) / r, (y - 0.5 * h) / r, 1.0 / r, u, v, 202)
	# Scratches: thin dark strokes.
	var sc := fbm(u * 0.3 + v * 0.7, u * 0.7 - v * 0.3 + 2.0, 40, 4, 203, 2)
	c = _shade(c, 1.0 - 0.2 * (1.0 - smoothstep(0.0, 0.004, absf(sc - 0.5))) * smoothstep(0.45, 0.6, fbm(u, v, 3, 3, 205)))
	# Grime in the lower corners and edges.
	var edge := minf(minf(u, 1.0 - u), minf(v, 1.0 - v))
	c = _mix(c, MUD, (1.0 - smoothstep(0.0, 0.12, edge)) * 0.45 + smoothstep(0.7, 1.0, v) * 0.2 * fbm(u, v, 5, 5, 204))
	return c


## Pennant (1.4 x 0.55 m, hoist on the left): ivory, the cross near the hoist, a gold hoist
## band, grime and fraying toward the tip. The triangle itself is cut by the geometry.
static func heraldry_pennant(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var c := _shade(IVORY, 0.86 + 0.14 * fbm(u, v, 5, 2, 251))
	c = _shade(c, 1.0 + 0.07 * sin(u * TAU * 2.5 + 2.0 * fbm(u, v, 3, 2, 252)))
	if x < 16:
		c = _shade(GOLD, 0.75 + 0.2 * fbm(u, v, 30, 12, 253))
	var r := 0.34 * h
	c = _emblem(c, (x - 0.17 * w) / r, (y - 0.5 * h) / r, 1.0 / r, u, v, 254)
	c = _mix(c, MUD, smoothstep(0.55, 1.0, u) * 0.35 * (0.5 + fbm(u, v, 8, 3, 255)))
	return c


## Oak: long grain along u, dark grain lines, a few knots, painted lighter streaks.
## (base and s come last because Callable.bind() appends bound arguments.)
static func oak(u: float, v: float, x: int, y: int, w: int, h: int, base: Color, s: int) -> Color:
	var g := fbm(u, v, 2, 24, s)
	var c := _shade(base, 0.72 + 0.55 * g)
	var line := fbm(u, v, 3, 40, s + 1, 3)
	if absf(line - 0.5) < 0.025:
		c = _shade(c, 0.62)
	if fbm(u, v, 3, 30, s + 2, 2) > 0.7:
		c = _shade(c, 1.15)
	# Knots.
	for k in 3:
		var kc := Vector2(_hash(k, 1, s), _hash(k, 2, s))
		var dd := Vector2(wrapf(u - kc.x, -0.5, 0.5) * 2.5, wrapf(v - kc.y, -0.5, 0.5) * 10.0)
		var kd := dd.length()
		if kd < 0.35:
			c = _shade(c, lerpf(0.45, 1.0, smoothstep(0.08, 0.35, kd)))
	return c


## Charcoal iron with lighter painted wear and rust blotches.
static func iron(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var c := _shade(IRON, 1.15 + 0.5 * (fbm(u, v, 4, 4, 301) - 0.5))
	c = _mix(c, Color(0.42, 0.43, 0.45), smoothstep(0.62, 0.72, fbm(u, v, 16, 16, 302, 2)) * 0.35)
	var rust := smoothstep(0.6, 0.78, fbm(u, v, 6, 6, 303)) * smoothstep(0.4, 0.6, fbm(u, v, 24, 24, 304, 2))
	return _mix(c, Color(0.34, 0.2, 0.12), rust * 0.6)


## Tarnished gold: warm gold with darker olive tarnish and bright painted glints.
static func gold(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var c := _shade(GOLD, 0.62 + 0.22 * fbm(u, v, 4, 4, 401))
	c = _mix(c, Color(0.3, 0.26, 0.14), smoothstep(0.35, 0.75, fbm(u, v, 3, 3, 402)) * 0.65)
	return _shade(c, 1.0 + 0.25 * smoothstep(0.7, 0.8, fbm(u, v, 20, 20, 403, 2)))


## Undyed linen canvas: a faint weave, broad stains.
static func linen(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var c := _shade(Color(0.78, 0.74, 0.64), 0.86 + 0.18 * fbm(u, v, 3, 3, 501))
	c = _shade(c, 0.97 + 0.03 * sin(x * PI * 0.5) * sin(y * PI * 0.5))
	return _mix(c, Color(0.52, 0.44, 0.32), smoothstep(0.58, 0.75, fbm(u, v, 4, 4, 502)) * 0.25)


## Red and ivory awning stripes (half a meter each) on linen, sun-faded and stained.
static func stripes(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var base := linen(u, v, x, y, w, h)
	var t := smoothstep(0.0, 0.012, u - 0.02) - smoothstep(0.0, 0.012, u - 0.48)
	var red := _shade(RED, 0.82 + 0.22 * fbm(u, v, 3, 3, 601))
	red = _mix(red, Color(0.62, 0.42, 0.38), 0.2 * fbm(u, v, 2, 2, 602))
	var c := _mix(base, red, t)
	return _mix(c, base, smoothstep(0.76, 0.84, fbm(u, v, 24, 24, 603, 2)) * 0.25)


## Twisted hemp rope: diagonal strands.
static func rope(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var s := fposmod(u * 3.0 + v * 12.0, 1.0)
	var c := _shade(Color(0.55, 0.45, 0.3), 0.7 + 0.45 * sin(s * PI))
	return _shade(c, 0.9 + 0.2 * fbm(u, v, 2, 8, 701))


## Pale limestone: broad warm-grey patches, chisel strokes, pits.
static func limestone(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var c := _shade(Color(0.66, 0.63, 0.56), 0.82 + 0.26 * fbm(u, v, 3, 3, 801))
	c = _mix(c, Color(0.58, 0.55, 0.42), smoothstep(0.55, 0.8, fbm(u, v, 2, 2, 802)) * 0.5)
	var stroke := fbm(u * 0.8 + v * 0.2, v * 0.8 - u * 0.2 + 3.0, 8, 30, 803, 2)
	if absf(stroke - 0.5) < 0.02:
		c = _shade(c, 0.78)
	c = _shade(c, 1.0 - 0.25 * smoothstep(0.74, 0.8, fbm(u, v, 32, 32, 804, 2)))
	return c


## A Knights' notice: aged parchment, darker edges, rows of ink, a small red cross at the top.
static func parchment(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var c := _shade(Color(0.80, 0.72, 0.55), 0.88 + 0.16 * fbm(u, v, 3, 3, 901))
	var edge := minf(minf(u, 1.0 - u), minf(v, 1.0 - v))
	c = _mix(c, Color(0.45, 0.33, 0.2), (1.0 - smoothstep(0.0, 0.1, edge)) * 0.6)
	# The cross at the top.
	var r := 0.07 * w
	c = _emblem(c, (x - 0.5 * w) / r, (y - 0.12 * h) / r, 1.0 / r, u, v, 902)
	# Lines of writing between 22% and 82%: short strokes of different lengths.
	var row_h := 0.045
	var row := floori((v - 0.22) / row_h)
	if v > 0.22 and v < 0.82:
		var rv := fposmod(v - 0.22, row_h) / row_h
		var line_end := 0.86 - 0.3 * _hash(row, 7, 903) if row % 4 == 3 else 0.86
		if rv > 0.38 and rv < 0.6 and u > 0.14 and u < line_end:
			var word := vnoise(u + _hash(row, 3, 906), 0.5, 13, 1, 904 + row)
			var ink := smoothstep(0.32, 0.38, word) * (0.6 + 0.3 * fbm(u, v, 40, 8, 907, 2))
			c = _mix(c, Color(0.16, 0.11, 0.09), ink)
	if fbm(u, v, 5, 5, 905) > 0.7:
		c = _mix(c, Color(0.55, 0.42, 0.26), 0.25)
	return c


## Oak roof shingles, 1 m tile: four staggered rows a meter, five or six shingles a row,
## each a slightly different grey-brown, dark joints and a shadow under the row above.
static func shingles(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var rows := 4
	var row := floori(v * rows)
	var vy := v * rows - row
	var n := 5 + (row % 2)
	var su := u * n + _hash(row, 1, 1101) * n
	var idx := floori(su)
	var fu := su - idx
	var k := posmod(idx, n)
	var tone := 0.8 + 0.35 * _hash(k, row, 1102)
	var c := _shade(Color(0.36, 0.3, 0.25), tone)
	# Grain runs down the shingle.
	c = _shade(c, 0.88 + 0.24 * fbm(u, v, 24, 3, 1103, 3))
	# Light catching the lower half, shadow under the row above, dark joints.
	c = _shade(c, lerpf(0.55, 1.0, smoothstep(0.0, 0.16, vy)) * (1.0 + 0.1 * smoothstep(0.5, 0.95, vy)))
	c = _shade(c, lerpf(0.5, 1.0, smoothstep(0.0, 0.05, minf(fu, 1.0 - fu))))
	# Moss and wet streaks.
	c = _mix(c, Color(0.27, 0.3, 0.17), smoothstep(0.62, 0.78, fbm(u, v, 4, 4, 1104)) * 0.5)
	return c


## The cross as a painted stencil (alpha outside): rough brushed edges, worn patches.
## For barrels, crates and chests: White Knights property.
static func stencil(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var r := 0.42 * w
	var a := (x - 0.5 * w) / r
	var b := (y - 0.5 * h) / r
	var d := cross_sdf(a, b) + 0.03 * (fbm(u, v, 16, 16, 1201, 3) - 0.5)
	var cov := clampf(0.5 - d / (1.6 / r), 0.0, 1.0)
	cov *= 1.0 - smoothstep(0.62, 0.72, fbm(u, v, 10, 10, 1202, 3))
	var c := _shade(Color(0.5, 0.13, 0.13), 0.85 + 0.25 * fbm(u * 0.2, v, 2, 24, 1203, 3))
	c.a = 1.0 if cov > 0.5 else 0.0
	return c


## A Knights' warning board: dark stained planks, a red painted border, the cross at the
## top and three lines of blocky ivory lettering (unreadable from afar, as intended).
static func warning_board(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var plank := floori(v * 4.0)
	var pv := v * 4.0 - plank
	var c := _shade(Color(0.2, 0.14, 0.1), 0.8 + 0.35 * fbm(u, v + plank * 0.3, 2, 20, 1301, 3) + 0.08 * _hash(plank, 0, 1302))
	c = _shade(c, lerpf(0.45, 1.0, smoothstep(0.0, 0.04, minf(pv, 1.0 - pv))))
	var edge := minf(minf(u, 1.0 - u), minf(v, 1.0 - v) * 1.25)
	if edge > 0.04 and edge < 0.085:
		c = _mix(c, _shade(RED, 0.8), 0.85 * (1.0 - smoothstep(0.66, 0.74, fbm(u, v, 20, 20, 1303, 2))))
	var r := 0.11 * w
	c = _emblem(c, (x - 0.5 * w) / r, (y - 0.2 * h) / r, 1.0 / r, u, v, 1304)
	# Lettering: three lines of blocky strokes.
	for line in 3:
		var y0 := 0.42 + line * 0.15
		if v > y0 and v < y0 + 0.08 and u > 0.12 and u < 0.88:
			var gx := floori((u - 0.12) / 0.76 * 9.0)
			var lu := fposmod((u - 0.12) / 0.76 * 9.0, 1.0)
			var lv := (v - y0) / 0.08
			var cell := Vector2i(floori(lu * 3.0), floori(lv * 4.0))
			var on := _hash(gx * 17 + cell.x, line * 13 + cell.y, 1305) > 0.42 and lu < 0.82
			if cell.x == 0 or cell.y == 0:
				on = on or _hash(gx, line, 1306) > 0.3
			if on and fbm(u, v, 30, 30, 1307, 2) < 0.68:
				c = _mix(c, _shade(IVORY, 0.85), 0.9)
	return c


## Limewashed wattle and daub, 2 m tile: uneven hand-laid limewash, hairline cracks,
## flaked patches showing the clay and the woven wattle underneath.
static func daub(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var c := _shade(Color(0.76, 0.71, 0.6), 0.86 + 0.18 * fbm(u, v, 3, 3, 1401))
	c = _mix(c, Color(0.7, 0.58, 0.4), smoothstep(0.5, 0.8, fbm(u, v, 2, 2, 1402)) * 0.35)
	var crack := fbm(u, v, 10, 10, 1403, 3)
	c = _shade(c, 1.0 - 0.35 * (1.0 - smoothstep(0.0, 0.006, absf(crack - 0.5))) * smoothstep(0.45, 0.65, fbm(u, v, 4, 4, 1404)))
	var flake := smoothstep(0.7, 0.76, fbm(u, v, 5, 5, 1405, 4))
	if flake > 0.0:
		var weave := sin((u + v) * TAU * 24.0) * sin((u - v) * TAU * 24.0)
		var clay := _shade(Color(0.48, 0.38, 0.27), 0.85 + 0.25 * fbm(u, v, 16, 16, 1406))
		clay = _shade(clay, 0.85 + 0.2 * clampf(weave, -1.0, 1.0))
		c = _mix(c, clay, flake)
	return c


## Reed thatch, 1 m tile: strands running down the slope (along v), laid in courses,
## weathered grey-gold with darker wet streaks and moss.
static func thatch(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var strand := fbm(u, v, 96, 4, 1501, 3)
	var c := _shade(Color(0.47, 0.39, 0.26), 0.55 + 0.7 * strand)
	# Courses with ragged, tufted lower edges rather than straight lines.
	var course := fposmod(v * 3.0 + 0.22 * (fbm(u, v, 24, 2, 1504, 2) - 0.5), 1.0)
	c = _shade(c, lerpf(0.8, 1.04, smoothstep(0.0, 0.35, course)))
	c = _shade(c, 0.9 + 0.2 * fbm(u, v, 6, 6, 1505, 2))
	c = _mix(c, Color(0.3, 0.29, 0.25), smoothstep(0.5, 0.8, fbm(u, v, 3, 2, 1502)) * 0.45)
	c = _mix(c, Color(0.25, 0.3, 0.16), smoothstep(0.66, 0.82, fbm(u, v, 4, 4, 1503)) * 0.55)
	return c


## Packed earth floor, 2 m tile, scattered with straw.
static func earth_floor(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var c := _shade(Color(0.33, 0.26, 0.19), 0.8 + 0.3 * fbm(u, v, 4, 4, 1601))
	c = _shade(c, 1.0 - 0.2 * smoothstep(0.55, 0.75, fbm(u, v, 3, 3, 1602)))
	var straw := fbm(u * 0.6 + v * 0.4, v * 0.6 - u * 0.4 + 5.0, 30, 6, 1603, 2)
	if absf(straw - 0.5) < 0.012 and fbm(u, v, 8, 8, 1604) > 0.5:
		c = _mix(c, Color(0.62, 0.52, 0.3), 0.8)
	return c


## Limestone rubble walling, 1 m tile: five courses of rough stones, each its own shade,
## lighter faces, darker edges, deep mortar joints.
static func rubble(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var rows := 5
	var jv := v + 0.1 * (fbm(u, v, 5, 5, 1701, 2) - 0.5)
	var row := posmod(floori(jv * rows), rows)
	var fv := fposmod(jv * rows, 1.0)
	var n := 3 + (row % 2)
	var su := u * n + _hash(row, 1, 1702) * n + 0.9 * (fbm(u, v, 7, 7, 1703, 2) - 0.5)
	var idx := posmod(floori(su), n)
	var fu := fposmod(su, 1.0)
	var tone := 0.78 + 0.32 * _hash(idx, row, 1704)
	var c := _shade(Color(0.64, 0.61, 0.54), tone)
	c = _mix(c, Color(0.58, 0.52, 0.4), _hash(idx, row, 1705) * 0.4)
	var edge := minf(minf(fu, 1.0 - fu) * 1.6 / n * rows, minf(fv, 1.0 - fv))
	c = _shade(c, lerpf(0.6, 1.0, smoothstep(0.02, 0.18, edge)) * (1.0 + 0.1 * smoothstep(0.3, 0.0, fv)))
	if edge < 0.035:
		c = _shade(Color(0.3, 0.28, 0.24), 0.8 + 0.3 * fbm(u, v, 20, 20, 1706))
	c = _mix(c, Color(0.32, 0.36, 0.2), smoothstep(0.68, 0.82, fbm(u, v, 3, 3, 1707)) * 0.4)
	return c


## The inn's hanging sign: a dark board with a painted foaming tankard in ivory and ochre.
static func inn_sign(u: float, v: float, x: int, y: int, w: int, h: int) -> Color:
	var c := _shade(Color(0.22, 0.15, 0.1), 0.8 + 0.3 * fbm(u, v, 2, 16, 1801, 3))
	var edge := minf(minf(u, 1.0 - u), minf(v, 1.0 - v))
	if edge < 0.05:
		c = _shade(Color(0.42, 0.34, 0.18), 0.85 + 0.3 * fbm(u, v, 16, 16, 1802))
	var p := Vector2(u, v)
	var body := absf(p.x - 0.45) < 0.2 and p.y > 0.35 and p.y < 0.82
	var foam := Vector2((p.x - 0.45) / 0.24, (p.y - 0.32) / 0.08).length() < 1.0
	var handle_d := Vector2((p.x - 0.68) / 0.1, (p.y - 0.56) / 0.14).length()
	var handle := handle_d > 0.6 and handle_d < 1.0 and p.x > 0.64
	var paint := Color(0.0, 0.0, 0.0, 0.0)
	if body or handle:
		paint = _shade(Color(0.72, 0.52, 0.25), 0.85 + 0.25 * fbm(u, v, 8, 8, 1803))
		if body and absf(p.y - 0.45) < 0.015 or body and absf(p.y - 0.72) < 0.015:
			paint = _shade(IRON, 1.4)
	if foam:
		paint = _shade(IVORY, 0.9 + 0.15 * fbm(u, v, 12, 12, 1804))
	if paint.a == 0.0 and (body or handle or foam):
		paint.a = 1.0
	if body or handle or foam:
		c = _mix(c, Color(paint.r, paint.g, paint.b), 0.9 * (1.0 - smoothstep(0.7, 0.8, fbm(u, v, 20, 20, 1805, 2))))
	return c
