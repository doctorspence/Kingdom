extends RefCounted
## Hand-paints the bandit's low-resolution textures. Every texel knows where it sits on the model
## (3D position and facet direction) and on its own shape (u, v in meters), and is painted the way
## a classic MMORPG texture is: a flat base colour, blocky brush mottling, painted light from
## above, shadow where layers meet, then the details: folds, stitches, wear, mud, rust, planks.
## The whole look is changed here; run tools/build_bandit.gd afterwards.

const EQ := preload("res://assets/equipment/eq_paint.gd")   # its occlusion grid and edge padding

## Brush stroke size: paint noise is sampled in blocks this big (meters).
const BRUSH := 0.007

## style: [family, base colour]
const STYLES := {
	"skin": ["skin", Color(0.63, 0.465, 0.325)],
	"hand": ["skin", Color(0.57, 0.41, 0.285)],
	"finger": ["skin", Color(0.58, 0.42, 0.29)],
	"face": ["face", Color(0.67, 0.495, 0.35)],
	"nose": ["face", Color(0.66, 0.465, 0.325)],
	"ear": ["skin", Color(0.59, 0.40, 0.29)],
	"eye": ["eye", Color(0.62, 0.56, 0.47)],
	"lip": ["flat", Color(0.30, 0.14, 0.11)],
	"hair": ["hair", Color(0.165, 0.112, 0.072)],
	"brow": ["hair", Color(0.115, 0.076, 0.050)],
	"beard": ["hair", Color(0.178, 0.122, 0.080)],
	"tunic": ["cloth", Color(0.275, 0.230, 0.140)],
	"tunic_skirt": ["cloth", Color(0.290, 0.240, 0.145)],
	"sleeve": ["cloth", Color(0.425, 0.415, 0.345)],
	"trousers": ["cloth", Color(0.265, 0.250, 0.190)],
	"cowl": ["cloth", Color(0.250, 0.168, 0.108)],
	"hood": ["cloth", Color(0.228, 0.153, 0.100)],
	"wrap": ["wrap", Color(0.435, 0.380, 0.275)],
	"wrap_turn": ["wrap", Color(0.485, 0.425, 0.310)],
	"vest": ["leather", Color(0.215, 0.145, 0.088)],
	"trim": ["leather", Color(0.150, 0.100, 0.062)],
	"lace": ["leather", Color(0.420, 0.340, 0.215)],
	"strap": ["leather", Color(0.160, 0.103, 0.062)],
	"belt": ["leather", Color(0.150, 0.092, 0.055)],
	"pouch": ["leather", Color(0.305, 0.168, 0.108)],
	"pouch_flap": ["leather", Color(0.355, 0.195, 0.122)],
	"pauldron": ["leather", Color(0.250, 0.165, 0.095)],
	"bracer": ["leather", Color(0.210, 0.138, 0.080)],
	"boot": ["boot", Color(0.300, 0.208, 0.112)],
	"boot_cuff": ["boot", Color(0.350, 0.245, 0.132)],
	"boot_foot": ["boot", Color(0.320, 0.222, 0.118)],
	"metal": ["metal", Color(0.545, 0.530, 0.495)],
	"iron": ["metal", Color(0.320, 0.305, 0.292)],
	"blade": ["blade", Color(0.470, 0.458, 0.440)],
	"grip": ["leather", Color(0.185, 0.118, 0.070)],
	"wood": ["wood", Color(0.375, 0.255, 0.140)],
	"wood_back": ["wood", Color(0.260, 0.178, 0.100)],
	"wood_rim": ["rim", Color(0.320, 0.250, 0.148)],
	"iron_rim": ["metal", Color(0.305, 0.296, 0.286)],
	"timber": ["timber", Color(0.320, 0.200, 0.105)],
	"string": ["flat", Color(0.420, 0.370, 0.270)],
	"hood_up": ["cloth", Color(0.290, 0.272, 0.178)],
	"hood_edge": ["cloth", Color(0.215, 0.200, 0.132)],
	"hood_lining": ["flat", Color(0.075, 0.064, 0.044)],
	"mask": ["cloth", Color(0.188, 0.118, 0.078)],
	"cloak": ["cloth", Color(0.250, 0.238, 0.158)],
	"quiver": ["leather", Color(0.330, 0.200, 0.105)],
	"arrow_shaft": ["flat", Color(0.390, 0.280, 0.160)],
	"fletch": ["flat", Color(0.610, 0.600, 0.555)],
	"fur": ["hair", Color(0.270, 0.205, 0.140)],
	"rope": ["rope", Color(0.560, 0.455, 0.270)],
	"plate": ["metal", Color(0.262, 0.255, 0.250)],
	"haft": ["haft", Color(0.300, 0.188, 0.100)],
	"axe_edge": ["metal", Color(0.600, 0.585, 0.545)],
	"pick_iron": ["metal", Color(0.140, 0.132, 0.130)],
	"pick_edge": ["metal", Color(0.360, 0.345, 0.325)],
	"coat": ["leather", Color(0.165, 0.120, 0.088)],
	"coat_trim": ["leather", Color(0.245, 0.175, 0.115)],
	"mail": ["mail", Color(0.300, 0.295, 0.290)],
	"mail_skirt": ["mail", Color(0.270, 0.262, 0.255)],
	"blackstone": ["blackstone", Color(0.042, 0.036, 0.052)],
	"wax": ["flat", Color(0.720, 0.650, 0.470)],
	"flame": ["flame", Color(1.000, 0.720, 0.260)],
}

## What the black stone gives off.
const STONE_LIGHT := Color(0.52, 0.20, 0.86)
## Skin that Harl's marks can run through.
const SKIN_STYLES := ["skin", "hand", "finger", "face", "nose", "ear"]

const DIRT := Color(0.165, 0.122, 0.072)
const RUST := Color(0.400, 0.190, 0.080)


## Paints the atlas for a packed builder (bandit_mesh.gd). `separate` = each mesh group is its own
## object (the held gear), so they don't shade each other. `colors` replaces the base colours of
## some styles (an outfit's palette); `patches` = sewn-on patches on the skirt and knee.
## `opts` (Harl): "dust" = hands black with mineral dust, "scars" = a scarred face, "marks" =
## how far the black marks have run up his left arm (1 = forearm, 2 = to the face), and
## "glow" = true to also paint what gives off light, returned in opts["glow_image"].
static func bake(m, size: int, separate := false, colors := {}, patches := true, opts := {}) -> Image:
	var occluders := {}
	var points := {}
	for c in m.charts:
		var key: String = c.group if separate else "all"
		if not points.has(key):
			points[key] = PackedVector3Array()
		for t in c.tris:
			for v in t:
				points[key].append(v.p)
	for key in points:
		var ao = EQ._AO.new()
		ao.build(points[key], points[key].size() / 3)
		occluders[key] = ao

	var paint := PackedByteArray()
	paint.resize(size * size * 4)
	var mask := PackedByteArray()
	mask.resize(size * size * 4)
	var covered := PackedByteArray()
	covered.resize(size * size)
	var glows: bool = opts.get("glow", false)
	var light := PackedByteArray()
	if glows:
		light.resize(size * size * 4)
	var nz := _Noise.new()
	for c in m.charts:
		var ao = occluders[c.group if separate else "all"]
		var style: Array = STYLES[c.style].duplicate()
		if colors.has(c.style):
			style[1] = colors[c.style]
		for t in c.tris:
			var ua: Vector2 = c.org + t[0].uv * c.k
			var ub: Vector2 = c.org + t[1].uv * c.k
			var uc: Vector2 = c.org + t[2].uv * c.k
			var area2 := (ub - ua).cross(uc - ua)
			if absf(area2) < 1e-5:
				continue
			var nrm: Vector3 = (t[2].p - t[0].p).cross(t[1].p - t[0].p).normalized()
			var x0 := maxi(int(floorf(minf(ua.x, minf(ub.x, uc.x))) - 2), 0)
			var x1 := mini(int(ceilf(maxf(ua.x, maxf(ub.x, uc.x))) + 2), size - 1)
			var y0 := maxi(int(floorf(minf(ua.y, minf(ub.y, uc.y))) - 2), 0)
			var y1 := mini(int(ceilf(maxf(ua.y, maxf(ub.y, uc.y))) + 2), size - 1)
			var h0 := absf(area2) / maxf((ub - uc).length(), 1e-5)
			var h1 := absf(area2) / maxf((uc - ua).length(), 1e-5)
			var h2 := absf(area2) / maxf((ua - ub).length(), 1e-5)
			for y in range(y0, y1 + 1):
				for x in range(x0, x1 + 1):
					var q := Vector2(x + 0.5, y + 0.5)
					var w0 := (ub - q).cross(uc - q) / area2
					var w1 := (uc - q).cross(ua - q) / area2
					var w2 := 1.0 - w0 - w1
					var inside := w0 >= -0.0001 and w1 >= -0.0001 and w2 >= -0.0001
					# paint a little past the edges so nothing bleeds in when filtered
					if not inside and (w0 * h0 < -1.5 or w1 * h1 < -1.5 or w2 * h2 < -1.5):
						continue
					var idx := y * size + x
					if covered[idx] == 2 or (covered[idx] == 1 and not inside):
						continue
					if not inside:
						w0 = clampf(w0, 0.0, 1.0)
						w1 = clampf(w1, 0.0, 1.0)
						w2 = clampf(w2, 0.0, 1.0)
						var s := w0 + w1 + w2
						w0 /= s
						w1 /= s
						w2 /= s
					var p: Vector3 = t[0].p * w0 + t[1].p * w1 + t[2].p * w2
					var uv: Vector2 = t[0].uv * w0 + t[1].uv * w1 + t[2].uv * w2
					var col := _paint(c.style, style, p, nrm, uv, c.size, ao.occlusion(p, nrm), nz, patches, opts)
					var o := idx * 4
					if glows:
						var g := _glow(c.style, p, nz, opts)
						light[o] = int(clampf(g.r, 0.0, 1.0) * 255.0)
						light[o + 1] = int(clampf(g.g, 0.0, 1.0) * 255.0)
						light[o + 2] = int(clampf(g.b, 0.0, 1.0) * 255.0)
						light[o + 3] = 255
					paint[o] = int(clampf(col.r, 0.0, 1.0) * 255.0)
					paint[o + 1] = int(clampf(col.g, 0.0, 1.0) * 255.0)
					paint[o + 2] = int(clampf(col.b, 0.0, 1.0) * 255.0)
					paint[o + 3] = 255
					covered[idx] = 2 if inside else 1
	var filled := covered.duplicate()   # the padding marks what it fills, so keep a clean copy
	EQ._dilate(paint, mask, covered, size)
	if glows:
		EQ._dilate(light, mask.duplicate(), filled, size)
		opts["glow_image"] = Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, light)
	return Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, paint)


class _Noise:
	var broad := FastNoiseLite.new()
	var fine := FastNoiseLite.new()

	func _init() -> void:
		broad.seed = 71
		broad.frequency = 1.0
		fine.seed = 113
		fine.frequency = 1.0

	## -1..1, blobs about `size` meters across.
	func blob(p: Vector3, size: float, offset := 0.0) -> float:
		var q := p / size + Vector3(offset, offset * 1.7, -offset)
		return clampf(broad.get_noise_3dv(q) * 1.8, -1.0, 1.0)

	## -1..1, one flat value per brush block.
	func brush(p: Vector3, size: float) -> float:
		var q := (p / size).floor()
		return clampf(fine.get_noise_3dv(q * 0.83) * 1.9, -1.0, 1.0)


static func _mix(a: Color, b: Color, t: float) -> Color:
	return a.lerp(b, clampf(t, 0.0, 1.0))


## 1 on a dashed stitch line `at` meters from either end of v.
static func _stitch(uv: Vector2, line: float) -> float:
	if absf(uv.y - line) < 0.0021 and fposmod(uv.x, 0.015) < 0.008:
		return 1.0
	return 0.0


## 1 close to the line from a to b (front-view x, y).
static func _line(p: Vector3, a: Vector2, b: Vector2, width: float) -> float:
	var q := Vector2(p.x, p.y)
	var ab := b - a
	var t := clampf((q - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return smoothstep(width, width * 0.35, q.distance_to(a + ab * t))


## 0..1: how strongly one of the black veins under Harl's skin runs through the point p.
static func _vein(name_: String, p: Vector3, nz: _Noise, opts: Dictionary) -> float:
	var spread: int = opts.get("marks", 0)
	if spread == 0 or p.x <= 0.0 or not name_ in SKIN_STYLES:
		return 0.0
	# first the forearm and hand; later up the arm, the neck and the side of the face
	var reach := smoothstep(0.43, 0.52, p.x)
	if spread > 1:
		reach = maxf(smoothstep(0.10, 0.17, p.x), smoothstep(0.0, 0.045, p.x) * smoothstep(1.73, 1.66, p.y))
	var q := Vector3(p.x * 0.40, p.y, p.z)   # drawn out along the arm, like vessels
	var wide := 1.0 - smoothstep(0.015, 0.135 if spread > 1 else 0.125, absf(nz.blob(q, 0.030, 131.0)))
	var fine := 1.0 - smoothstep(0.0, 0.060, absf(nz.blob(q, 0.015, 137.0)))
	return clampf(maxf(wide, fine * 0.55) * reach, 0.0, 1.0)


## 0..1: the thin bright cracks in a shard of black stone.
static func _crack(p: Vector3, nz: _Noise) -> float:
	return 1.0 - smoothstep(0.01, 0.12, absf(nz.blob(p, 0.022, 151.0)))


## What the point gives off by itself (black = nothing).
static func _glow(name_: String, p: Vector3, nz: _Noise, opts: Dictionary) -> Color:
	var strong: float = 1.0 if int(opts.get("marks", 1)) > 1 else 0.5
	if name_ == "blackstone":
		return STONE_LIGHT * (_crack(p, nz) * 0.16 if strong < 0.9 else 0.07 + _crack(p, nz) * 0.68)
	if name_ == "flame":
		return Color(1.0, 0.62, 0.20)
	var v := _vein(name_, p, nz, opts)
	if v > 0.0:
		return STONE_LIGHT * (smoothstep(0.60, 1.0, v) * 0.55 if strong > 0.9 else 0.0)
	return Color.BLACK


static func _paint(name_: String, style: Array, p: Vector3, n: Vector3, uv: Vector2, size: Vector2, ao: float, nz: _Noise, patches: bool, opts := {}) -> Color:
	var family: String = style[0]
	var col: Color = style[1]
	var soft := nz.blob(p, 0.075)
	var stroke := nz.brush(p, BRUSH)
	var dab := nz.brush(p + Vector3(3.1, 1.3, 7.9), BRUSH * 2.4)

	match family:
		"skin", "face":
			col = col * (1.0 + 0.05 * soft + 0.025 * stroke)
			col = _mix(col, Color(0.56, 0.29, 0.20), smoothstep(0.25, 0.8, nz.blob(p, 0.045, 4.0)) * 0.35)
			var grime := smoothstep(0.35, 0.75, nz.blob(p, 0.03, 9.0))
			col = _mix(col, Color(0.34, 0.25, 0.16), grime * 0.35)
			if name_ == "finger" or name_ == "hand":
				# knuckles and dirty nails
				var x := absf(p.x)
				if n.y > 0.4 and (absf(x - 0.855) < 0.008 or absf(x - 0.901) < 0.006):
					col = _mix(col, Color(0.82, 0.55, 0.38), 0.5)
				col = _mix(col, DIRT, smoothstep(0.935, 0.965, x) * 0.5)
			# (the head's one style covers the back of the skull too: features only in front)
			if family == "face" and p.z > -0.01:
				var ax := absf(p.x)
				# deep-set eyes
				var socket := Vector2((ax - 0.033) / 0.030, (p.y - 1.690) / 0.017).length()
				col = _mix(col, Color(0.33, 0.18, 0.13), (1.0 - smoothstep(0.55, 1.15, socket)) * 0.7)
				# cheekbone light and hollow cheeks
				var bone := Vector2((ax - 0.060) / 0.028, (p.y - 1.664) / 0.011).length()
				col = _mix(col, Color(0.86, 0.62, 0.42), (1.0 - smoothstep(0.4, 1.0, bone)) * 0.45)
				var hollow := Vector2((ax - 0.062) / 0.026, (p.y - 1.634) / 0.016).length()
				col = _mix(col, Color(0.45, 0.29, 0.19), (1.0 - smoothstep(0.4, 1.0, hollow)) * 0.55)
				# frown lines
				col = _mix(col, Color(0.40, 0.24, 0.16), _line(Vector3(ax, p.y, p.z), Vector2(0.011, 1.718), Vector2(0.015, 1.732), 0.0028) * 0.4)
				col = _mix(col, Color(0.42, 0.25, 0.17), _line(Vector3(ax, p.y, p.z), Vector2(0.026, 1.647), Vector2(0.042, 1.622), 0.004) * 0.6)
				# an old scar through the left brow and cheek
				if p.z > 0.02:
					var scar := maxf(_line(p, Vector2(0.060, 1.742), Vector2(0.047, 1.712), 0.0034), _line(p, Vector2(0.043, 1.678), Vector2(0.058, 1.643), 0.0034))
					col = _mix(col, Color(0.80, 0.55, 0.46), scar * 0.65)
				# stubble
				if p.y < 1.655:
					var s := smoothstep(1.655, 1.625, p.y)
					col = _mix(col, Color(0.26, 0.18, 0.12), s * (0.55 + 0.3 * stroke))
				# shadow under the hair
				col = _mix(col, col * 0.55, smoothstep(1.742, 1.775, p.y))
				if name_ == "nose":
					col = _mix(col, Color(0.72, 0.38, 0.27), smoothstep(1.668, 1.648, p.y) * 0.4)
				if opts.get("scars", false) and p.z > 0.02:
					var cut := maxf(_line(p, Vector2(-0.070, 1.702), Vector2(-0.012, 1.658), 0.0042),
							_line(p, Vector2(-0.012, 1.658), Vector2(0.024, 1.650), 0.0034))
					cut = maxf(cut, _line(p, Vector2(-0.080, 1.668), Vector2(-0.048, 1.630), 0.0036))
					cut = maxf(cut, _line(p, Vector2(-0.030, 1.752), Vector2(-0.058, 1.722), 0.0034))
					col = _mix(col, Color(0.82, 0.50, 0.44), cut * 0.8)
			if opts.get("dust", false):
				# hands black with mineral dust, thinning up the wrists
				var dusty := smoothstep(0.62, 0.77, absf(p.x)) * (0.78 + 0.22 * nz.blob(p, 0.02, 121.0))
				col = _mix(col, Color(0.058, 0.050, 0.052) * (1.0 + 0.30 * stroke), dusty * 0.97)
			var vein := _vein(name_, p, nz, opts)
			if vein > 0.0:
				col = _mix(col, col * Color(0.70, 0.60, 0.86), smoothstep(0.0, 0.5, vein) * 0.8)
				col = _mix(col, Color(0.085, 0.030, 0.140), smoothstep(0.30, 0.85, vein))
		"eye":
			var d := absf(absf(p.x) - 0.031)
			if d < 0.0085:
				col = Color(0.085, 0.055, 0.040)
			elif p.y > 1.691:
				col = col * 0.5
		"flat":
			col = col * (1.0 + 0.12 * stroke)
		"hair":
			# strands: streaks running down
			var q := Vector3(p.x, p.y * 0.07, p.z)
			var strand := nz.blob(q, 0.010)
			var wide := nz.blob(q, 0.026, 2.0)
			col = col * (1.0 + 0.20 * strand + 0.08 * wide)
			col = _mix(col, Color(0.31, 0.22, 0.13), smoothstep(0.35, 0.95, strand) * smoothstep(0.0, 0.8, n.y + 0.2) * 0.65)
			if name_ == "beard":
				col = _mix(col, Color(0.45, 0.39, 0.32), smoothstep(0.55, 0.9, nz.brush(p, 0.0045)) * 0.35)
		"cloth":
			var fold := sin(uv.x * 78.0 + nz.blob(p, 0.11, 1.0) * 3.4 + uv.y * 9.0)
			var fold_k := 0.11 if name_ in ["tunic_skirt", "cowl", "cloak"] else 0.065
			col = col * (1.0 + 0.09 * soft + 0.045 * stroke + fold_k * fold)
			col = _mix(col, col * Color(1.30, 1.24, 1.10), smoothstep(0.78, 1.0, fold) * 0.35)
			col = _mix(col, col * Color(0.72, 0.74, 0.72), smoothstep(0.35, 0.8, nz.blob(p, 0.14, 6.0)) * 0.6)
			# coarse weave
			if fposmod(p.y, 0.010) < 0.0035:
				col = col * 0.955
			# mud and grease, heavier toward the ground
			var low := smoothstep(1.0, 0.35, p.y)
			var mud := smoothstep(0.62 - low * 0.5, 0.95 - low * 0.35, nz.blob(p, 0.055, 12.0) * 0.6 + dab * 0.4 + 0.1)
			col = _mix(col, DIRT, mud * 0.6)
			if name_ == "tunic_skirt":
				col = _mix(col, DIRT, smoothstep(size.y - 0.085, size.y, uv.y) * 0.45)
				col = _mix(col, col * 1.35, _stitch(uv, 0.028) * 0.8)
				# a sewn-on patch, front left
				var pa := Vector2(p.x - 0.112, p.y - 0.868).rotated(0.18)
				if patches and p.z > 0.06 and absf(pa.x) < 0.040 and absf(pa.y) < 0.034:
					col = Color(0.295, 0.245, 0.180) * (1.0 + 0.1 * stroke)
					var edge := maxf(absf(pa.x) - 0.030, absf(pa.y) - 0.024)
					if edge > 0.0 and fposmod(pa.x + pa.y, 0.013) < 0.006:
						col = Color(0.60, 0.49, 0.30)
			elif name_ == "sleeve":
				col = _mix(col, col * 0.62, smoothstep(size.y - 0.032, size.y, uv.y))
				col = _mix(col, col * 1.35, _stitch(uv, size.y - 0.045) * 0.7)
			elif name_ == "trousers":
				# a leather knee patch on the right leg
				if patches and p.x < 0.0 and p.z > 0.02:
					var kp := Vector2(p.x + 0.094, p.y - 0.548).rotated(-0.14)
					if absf(kp.x) < 0.042 and absf(kp.y) < 0.040:
						col = Color(0.30, 0.205, 0.115) * (1.0 + 0.12 * stroke)
						if maxf(absf(kp.x) - 0.033, absf(kp.y) - 0.031) > 0.0 and fposmod(kp.x - kp.y, 0.012) < 0.0055:
							col = Color(0.62, 0.50, 0.30)
				col = _mix(col, col * 0.72, smoothstep(0.05, 0.02, absf(p.x)) * 0.8)
			elif name_ in ["cowl", "hood", "cloak"]:
				col = _mix(col, col * 0.55, smoothstep(size.y - 0.022, size.y, uv.y))
				col = _mix(col, col * 1.42, _stitch(uv, size.y - 0.030) * 0.7)
		"timber":
			var grain := nz.blob(Vector3(p.x, p.y, p.z * 0.14), 0.011, 91.0)
			col = col * (1.0 + 0.22 * grain + 0.06 * stroke)
			col = _mix(col, col * 1.45, smoothstep(0.4, 0.85, nz.blob(p, 0.030, 93.0)) * 0.45)
			col = _mix(col, DIRT, smoothstep(0.2, 0.75, nz.blob(p, 0.045, 95.0)) * 0.5)
		"mail":
			# rows of small rings, each row set between the one above
			var cell := Vector2(uv.x / 0.0155, uv.y / 0.0125)
			if int(floorf(cell.y)) % 2 != 0:
				cell.x += 0.5
			var q := Vector2(fposmod(cell.x, 1.0) - 0.5, fposmod(cell.y, 1.0) - 0.5)
			var d := q.length()
			var ring := smoothstep(0.16, 0.30, d) * smoothstep(0.62, 0.46, d)
			col = col * (1.0 + 0.08 * soft + 0.06 * stroke) * (0.42 + 0.80 * ring)
			col = _mix(col, Color(0.66, 0.65, 0.62), ring * smoothstep(0.0, -0.35, q.y) * 0.55)
			col = _mix(col, RUST * 0.9, smoothstep(0.3, 0.75, nz.blob(p, 0.05, 111.0)) * 0.55)
		"blackstone":
			col = col * (1.0 + 0.18 * soft + 0.10 * stroke)
			col = _mix(col, Color(0.20, 0.19, 0.25), smoothstep(0.35, 0.95, n.y * 0.6 + n.z * 0.5 + n.x * 0.2) * 0.75)
			col = _mix(col, STONE_LIGHT * 0.65, _crack(p, nz) * 0.55)
		"flame":
			col = col * (1.0 + 0.1 * stroke)
		"haft":
			# a long ash handle, grain running along it, darkened by hands
			var grain := nz.blob(Vector3(p.x, p.y * 0.12, p.z), 0.010, 97.0)
			col = col * (1.0 + 0.22 * grain + 0.06 * stroke)
			col = _mix(col, DIRT, smoothstep(0.2, 0.75, nz.blob(p, 0.045, 99.0)) * 0.55)
		"rope":
			# twisted strands
			var twist := fposmod((p.x + p.y * 1.3 + p.z * 0.6) / 0.019, 1.0)
			col = col * (1.0 + 0.08 * soft + 0.05 * stroke) * (0.72 + 0.42 * smoothstep(0.0, 0.55, twist))
			col = _mix(col, DIRT, smoothstep(0.25, 0.75, nz.blob(p, 0.03, 101.0)) * 0.45)
		"wrap":
			var ang := atan2(p.z + 0.068, p.y - 1.441)
			var s := fposmod((absf(p.x) + ang * 0.011) / 0.027, 1.0)
			col = col * (1.0 + 0.10 * soft + 0.07 * stroke)
			col = col * (0.80 + 0.34 * smoothstep(0.0, 0.5, s))
			if s < 0.13:
				col = col * 0.55
			col = _mix(col, DIRT, smoothstep(0.15, 0.75, nz.blob(p, 0.035, 5.0)) * 0.55)
		"leather", "boot":
			col = col * (1.0 + 0.13 * soft + 0.06 * stroke)
			# scuffed through to the tan underneath
			var wear := smoothstep(0.28, 0.72, nz.blob(p, 0.032, 17.0) * 0.75 + stroke * 0.35)
			col = _mix(col, col * Color(1.42, 1.36, 1.22), wear * 0.5)
			col = _mix(col, col * 0.68, smoothstep(0.35, 0.85, nz.blob(p, 0.06, 23.0)) * 0.7)
			var scratch := nz.blob(Vector3(p.x * 4.0 + p.y * 3.0, p.y * 0.5 - p.x * 0.4, p.z * 4.0), 0.022, 31.0)
			if scratch > 0.88:
				col = col * Color(1.32, 1.26, 1.12)
			var thread := Color(0.58, 0.45, 0.25)
			if name_ in ["vest", "pauldron", "bracer", "pouch_flap", "boot_cuff", "coat_trim"]:
				col = _mix(col, thread, maxf(_stitch(uv, 0.010), _stitch(uv, size.y - 0.010)) * 0.75)
				col = _mix(col, col * 0.62, maxf(smoothstep(0.006, 0.0, uv.y), smoothstep(size.y - 0.006, size.y, uv.y)))
			if name_ == "belt" and size.x > 0.3:
				col = _mix(col, thread, maxf(_stitch(uv, 0.014), _stitch(uv, size.y - 0.014)) * 0.55)
			if name_ == "vest":
				# side seams and the back seam, stitched
				for f in [0.27, 0.5, 0.73]:
					var du := absf(uv.x - size.x * f)
					col = _mix(col, col * 0.55, smoothstep(0.005, 0.001, du))
					if absf(du - 0.011) < 0.002 and fposmod(uv.y, 0.016) < 0.008:
						col = _mix(col, thread, 0.65)
				col = _mix(col, thread, 0.7 if (minf(uv.x, size.x - uv.x) > 0.018 and minf(uv.x, size.x - uv.x) < 0.022 and fposmod(uv.y, 0.016) < 0.009) else 0.0)
				col = _mix(col, DIRT, smoothstep(0.30, 0.0, p.y - 1.06) * smoothstep(0.1, 0.7, soft) * 0.6)
			if family == "boot":
				# creases at the ankle and across the toes
				var crease := sin(p.y * 230.0 + soft * 4.0) * smoothstep(0.055, 0.0, absf(p.y - 0.155))
				col = col * (1.0 + 0.16 * crease)
				if name_ == "boot_foot":
					if p.y < 0.027:
						col = Color(0.135, 0.095, 0.062) * (1.0 + 0.18 * stroke)
					else:
						col = col * (1.0 + 0.10 * sin(p.z * 190.0) * smoothstep(0.03, 0.0, absf(p.z - 0.095)))
						col = _mix(col, Color(0.60, 0.47, 0.26), smoothstep(0.0021, 0.0008, absf(p.y - 0.037)) * (0.7 if fposmod(p.z + p.x, 0.014) < 0.008 else 0.0))
				var mud := smoothstep(0.26, 0.02, p.y) * smoothstep(0.0, 0.65, nz.blob(p, 0.028, 41.0) + 0.15)
				col = _mix(col, Color(0.235, 0.180, 0.105), mud * 0.7)
		"metal":
			col = col * (1.0 + 0.10 * soft + 0.08 * stroke)
			col = _mix(col, Color(0.74, 0.72, 0.66), smoothstep(0.55, 1.0, n.y + n.z * 0.25) * 0.32)
			var rust := smoothstep(0.22, 0.62, nz.blob(p, 0.022, 51.0) + dab * 0.25 - n.y * 0.18)
			col = _mix(col, RUST * (1.0 + 0.2 * stroke), rust * (0.75 if name_ == "iron" else 0.4))
		"blade":
			var x := absf(p.x)
			col = col * (1.0 + 0.08 * soft + 0.04 * stroke)
			# a dull dark flat, a bright honed edge, light on the ridge
			col = _mix(col, col * 0.72, smoothstep(0.016, 0.004, x))
			col = _mix(col, Color(0.68, 0.67, 0.63), smoothstep(0.026, 0.037, x) * 0.7)
			col = _mix(col, Color(0.62, 0.61, 0.58), smoothstep(0.004, 0.0005, absf(x - 0.0135)) * 0.55)
			var rust := smoothstep(0.18, 0.60, nz.blob(p, 0.030, 61.0) + dab * 0.2 + smoothstep(0.30, 0.10, p.y) * 0.45 - 0.1)
			col = _mix(col, RUST * (1.1 + 0.25 * stroke), rust * 0.7)
			if nz.blob(Vector3(p.x * 3.0 + p.y * 2.0, p.y * 0.3, p.z), 0.016, 67.0) > 0.86:
				col = col * 1.28
		"wood":
			# planks (they hang upright when the arm does)
			var s := (p.y + 0.047) / 0.094
			var plank := floorf(s)
			var f := s - plank
			col = col * (1.0 + 0.15 * sin(plank * 12.9) + 0.07 * soft + 0.04 * stroke)
			var grain := nz.blob(Vector3(p.x, p.y * 7.0 + plank, p.z * 0.8), 0.034, 73.0)
			col = col * (1.0 + 0.20 * grain)
			if f < 0.055 or f > 0.945:
				col = col * 0.42
			elif f < 0.11:
				col = col * 1.22
			var knot := Vector2((p.y - 0.062) / 0.014, (p.z - 0.205) / 0.026).length()
			knot = minf(knot, Vector2((p.y + 0.128) / 0.012, (p.z + 0.030) / 0.022).length())
			col = _mix(col, Color(0.17, 0.10, 0.05), 1.0 - smoothstep(0.5, 1.0, knot))
			var radius := Vector2(p.y, p.z - 0.085).length()
			col = _mix(col, DIRT, smoothstep(0.17, 0.27, radius) * 0.45)
			# old sword cuts
			for cut in [[Vector2(0.05, 0.22), Vector2(0.17, 0.13)], [Vector2(-0.19, 0.02), Vector2(-0.10, -0.07)], [Vector2(0.11, -0.04), Vector2(0.19, -0.03)]]:
				var d := _line(Vector3(p.y, p.z, 0.0), cut[0], cut[1], 0.0055)
				col = _mix(col, Color(0.74, 0.57, 0.33), d * 0.8)
		"rim":
			col = col * (1.0 + 0.14 * soft + 0.08 * stroke)
			var ang := atan2(p.z - 0.085, p.y)
			if fposmod(ang / (TAU / 7.0), 1.0) < 0.035:
				col = col * 0.45
			col = _mix(col, DIRT, smoothstep(0.1, 0.7, nz.blob(p, 0.045, 81.0)) * 0.55)

	if family == "flame":
		return col
	# painted light: warm from above and in front, cool underneath; shadow where layers meet
	var lit := clampf(n.y * 0.55 + n.z * 0.20 + n.x * 0.08 + 0.52, 0.0, 1.0)
	col = col * _mix(Color(0.70, 0.71, 0.76), Color(1.09, 1.07, 1.02), lit)
	var shadow := smoothstep(0.42, 0.98, ao)
	col = col * _mix(Color(0.50, 0.45, 0.44), Color(1, 1, 1), shadow)
	col.a = 1.0
	return col
