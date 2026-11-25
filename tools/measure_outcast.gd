extends SceneTree
## Measures the fitted Outcast model (rest/T-pose space) so armor (eq_armor.gd) can be sized to it.
## Vertices are sampled against the painted texture; olive-green ones are the cloak and are left out, so the
## numbers describe the body and clothes underneath it.
##   Godot_console.exe --headless --path . --script res://tools/measure_outcast.gd [-- outcast_male]
const A := preload("res://assets/equipment/eq_armor.gd")

var pts: Array = []   # [position, region]


func _initialize() -> void:
	var name_ := "outcast_male"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		name_ = args[0]
	var src: ArrayMesh = load("res://assets/characters/outcast/%s.res" % name_)
	var tex: Texture2D = load("res://assets/characters/outcast/%s_raw_0.png" % name_)
	var img: Image = tex.get_image()
	if img.is_compressed():
		img.decompress()
	var cloak := 0
	for s in src.get_surface_count():
		var arr := src.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var region := src.surface_get_name(s)
		for i in v.size():
			var c := img.get_pixelv(Vector2i(clampi(int(uv[i].x * img.get_width()), 0, img.get_width() - 1), clampi(int(uv[i].y * img.get_height()), 0, img.get_height() - 1)))
			var is_cloak: bool = region != "head" and region != "forearms" and region != "feet" and c.g > c.r * 1.04 and c.g > c.b * 1.3 and c.v < 0.55
			if is_cloak:
				cloak += 1
				continue
			pts.append([v[i], region])
	print("points kept ", pts.size(), ", cloak points dropped ", cloak)

	print("-- torso (no cloak, no arms): y: x[min max] z[min max]   (|x| < 0.2 above the shoulders line, 0.33 below)")
	var y := 0.80
	while y < 1.62:
		var r := _box(func(p, reg): return absf(p.y - y) < 0.02 and absf(p.x) < (0.4 if y < 1.36 else 0.2) and reg != "legs" and reg != "feet" and reg != "forearms")
		print("y=%.2f x[%.3f %.3f] z[%.3f %.3f] n=%d" % [y, r[0].x, r[1].x, r[0].z, r[1].z, r[2]])
		y += 0.05
	print("-- torso, first surface seen from the body axis (0, -0.03): front / side / back distances (cloak is outside this)")
	y = 0.90
	while y < 1.62:
		var best := {}
		for e in pts:
			var p: Vector3 = e[0]
			if absf(p.y - y) > 0.02 or e[1] == "legs" or e[1] == "feet" or e[1] == "forearms" or e[1] == "head":
				continue
			if absf(p.x) > (0.36 if y < 1.33 else 0.22):
				continue
			var dx := p.x
			var dz := p.z + 0.03
			var ang := rad_to_deg(atan2(dx, dz))   # 0 = front, 90 = left, 180 = back
			var bin := int(roundf(absf(ang) / 22.5))   # fold left/right together
			var d := Vector2(dx, dz).length()
			if not best.has(bin) or d < best[bin][0]:
				best[bin] = [d, p]
		var line := "y=%.2f" % y
		for bin in range(0, 9):
			if best.has(bin):
				var p: Vector3 = best[bin][1]
				line += "  %3d: (%.3f,%.3f)" % [bin * 22.5, absf(p.x), p.z]
		print(line)
		y += 0.05
	print("-- legs (left leg, x > 0): y: x[min max] z[min max]")
	y = 0.05
	while y < 0.95:
		var r := _box(func(p, reg): return absf(p.y - y) < 0.02 and p.x > 0.0 and p.x < 0.3 and p.z > -0.16 and (reg == "legs" or reg == "feet"))
		print("y=%.2f x[%.3f %.3f] z[%.3f %.3f] n=%d  center (%.3f, %.3f) half (%.3f, %.3f)" % [y, r[0].x, r[1].x, r[0].z, r[1].z, r[2],
				(r[0].x + r[1].x) * 0.5, (r[0].z + r[1].z) * 0.5, (r[1].x - r[0].x) * 0.5, (r[1].z - r[0].z) * 0.5])
		y += 0.05
	print("-- arm (left, x > 0), in x slices: x: y[min max] z[min max]   (T-pose, arm along +x)")
	var x := 0.18
	while x < 0.78:
		var r := _box(func(p, reg): return absf(p.x - x) < 0.015 and p.x > 0 and absf(p.y - 1.44) < 0.2 and reg != "head" and (reg == "forearms" or p.z > -0.25 and (reg == "torso") or x > 0.3))
		print("x=%.2f y[%.3f %.3f] z[%.3f %.3f] n=%d  center (%.3f, %.3f) half (%.3f, %.3f)" % [x, r[0].y, r[1].y, r[0].z, r[1].z, r[2],
				(r[0].y + r[1].y) * 0.5, (r[0].z + r[1].z) * 0.5, (r[1].y - r[0].y) * 0.5, (r[1].z - r[0].z) * 0.5])
		x += 0.04
	print("-- head region: y: x[min max] z[min max]")
	for yy in [1.46, 1.5, 1.55, 1.6, 1.65, 1.7, 1.75, 1.8, 1.84]:
		var r := _box(func(p, reg): return absf(p.y - yy) < 0.012 and reg == "head")
		print("y=%.2f x[%.3f %.3f] z[%.3f %.3f] n=%d  center z %.3f half (%.3f, %.3f)" % [yy, r[0].x, r[1].x, r[0].z, r[1].z, r[2], (r[0].z + r[1].z) * 0.5, (r[1].x - r[0].x) * 0.5, (r[1].z - r[0].z) * 0.5])
	var f := _box(func(p, reg): return reg == "feet" and p.x > 0.0)
	print("foot box ", f[0], f[1])
	quit()


func _box(keep: Callable) -> Array:
	var lo := Vector3(9, 9, 9)
	var hi := Vector3(-9, -9, -9)
	var n := 0
	for e in pts:
		if keep.call(e[0], e[1]):
			lo = lo.min(e[0])
			hi = hi.max(e[0])
			n += 1
	if n == 0:
		return [Vector3.ZERO, Vector3.ZERO, 0]
	return [lo, hi, n]
