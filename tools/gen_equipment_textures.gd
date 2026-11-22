extends SceneTree
## Paints the equipment PBR textures (512x512 color / normal / roughness PNGs, tileable).
##   Godot_console.exe --headless --path . --script res://tools/gen_equipment_textures.gd
## Then run an import (--import) so Godot picks the PNGs up, then tools/build_equipment.gd.

const N := 512
const OUT := "res://assets/equipment/Materials/tex/"
var _noise := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_run.call_deferred()


## Tileable noise: blends the four wrapped copies of a plain noise field.
func tn(x: float, y: float, freq: float, seed_off := 0) -> float:
	_noise.seed = 7 + seed_off
	_noise.frequency = freq
	var fx := x / N
	var fy := y / N
	var a := _noise.get_noise_2d(x, y)
	var b := _noise.get_noise_2d(x - N, y)
	var c := _noise.get_noise_2d(x, y - N)
	var d := _noise.get_noise_2d(x - N, y - N)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


func _save(name: String, col: Image, height: PackedFloat32Array, rough: PackedFloat32Array, strength := 2.0) -> void:
	var nrm := Image.create(N, N, false, Image.FORMAT_RGB8)
	var rg := Image.create(N, N, false, Image.FORMAT_L8)
	for y in N:
		for x in N:
			var hl := height[y * N + (x + N - 1) % N]
			var hr := height[y * N + (x + 1) % N]
			var hu := height[((y + N - 1) % N) * N + x]
			var hd := height[((y + 1) % N) * N + x]
			var v := Vector3((hl - hr) * strength, (hu - hd) * strength, 1.0).normalized()
			nrm.set_pixel(x, y, Color(v.x * 0.5 + 0.5, v.y * 0.5 + 0.5, v.z * 0.5 + 0.5))
			rg.set_pixel(x, y, Color(rough[y * N + x], 0, 0))
	col.save_png(OUT + name + "_color.png")
	nrm.save_png(OUT + name + "_normal.png")
	rg.save_png(OUT + name + "_rough.png")
	print("wrote ", name)


## Scratch lines burned into a height field (wraps around the edges).
func _scratches(h: PackedFloat32Array, count: int, depth: float) -> void:
	for i in count:
		var p := Vector2(_rng.randf() * N, _rng.randf() * N)
		var ang := _rng.randf() * TAU
		var d := Vector2(cos(ang), sin(ang))
		var len := _rng.randf_range(20.0, 110.0)
		var dp := _rng.randf_range(0.4, 1.0) * depth
		for s in int(len):
			var q := p + d * s
			var xi := posmod(int(q.x), N)
			var yi := posmod(int(q.y), N)
			h[yi * N + xi] -= dp


func _metal(name: String, base: Color, rust: Color, rust_amount: float, rough_base: float, brushed: float, scratch_n: int) -> void:
	_rng.seed = hash(name)
	var col := Image.create(N, N, false, Image.FORMAT_RGB8)
	var h := PackedFloat32Array()
	h.resize(N * N)
	var r := PackedFloat32Array()
	r.resize(N * N)
	for y in N:
		for x in N:
			var streak := tn(x * 0.06, y * 1.0, 0.04, 1) * brushed + tn(x, y, 0.02, 2) * 0.5
			var fine := tn(x, y, 0.35, 3)
			var blot := tn(x, y, 0.012, 4) * 0.5 + 0.5
			h[y * N + x] = streak * 0.015 + fine * 0.02
			r[y * N + x] = clampf(rough_base + streak * 0.12 + fine * 0.08, 0.08, 0.95)
			var shade := 0.9 + streak * 0.18 + fine * 0.05
			var c := base * shade
			var rt := clampf((blot - (1.0 - rust_amount)) * 4.0, 0.0, 1.0) * rust_amount
			c = c.lerp(rust * (0.8 + fine * 0.3), rt)
			if rt > 0.1:
				r[y * N + x] = clampf(r[y * N + x] + rt * 0.3, 0.0, 0.95)
			col.set_pixel(x, y, Color(c.r, c.g, c.b))
	_scratches(h, scratch_n, 0.05)
	# scratches show as brighter lines too
	_save(name, col, h, r, 2.0)


func _leather(name: String, base: Color) -> void:
	_rng.seed = hash(name)
	var col := Image.create(N, N, false, Image.FORMAT_RGB8)
	var h := PackedFloat32Array()
	h.resize(N * N)
	var r := PackedFloat32Array()
	r.resize(N * N)
	_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	for y in N:
		for x in N:
			var grain := tn(x, y, 0.09, 5)
			var wear := tn(x, y, 0.015, 6) * 0.5 + 0.5
			var crease := tn(x * 1.0, y * 0.35, 0.03, 7)
			h[y * N + x] = grain * 0.06 + crease * 0.04
			r[y * N + x] = clampf(0.72 + wear * 0.18 - grain * 0.05, 0.4, 0.95)
			var shade := 0.82 + wear * 0.3 + grain * 0.08 - maxf(crease, 0.0) * 0.1
			var c := base * shade
			col.set_pixel(x, y, Color(c.r, c.g, c.b))
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_scratches(h, 30, 0.03)
	_save(name, col, h, r, 2.2)


func _cloth(name: String, base: Color, pitch: int, fuzz: float) -> void:
	_rng.seed = hash(name)
	var col := Image.create(N, N, false, Image.FORMAT_RGB8)
	var h := PackedFloat32Array()
	h.resize(N * N)
	var r := PackedFloat32Array()
	r.resize(N * N)
	for y in N:
		for x in N:
			var cx := (x % pitch) / float(pitch)
			var cy := (y % pitch) / float(pitch)
			var over := ((x / pitch) + (y / pitch)) % 2 == 0
			var warp := sin(cx * PI)
			var weft := sin(cy * PI)
			var thread := warp if over else weft
			var slub := tn(x * 0.3, y * 1.0, 0.05, 8) if over else tn(x * 1.0, y * 0.3, 0.05, 9)
			h[y * N + x] = thread * 0.12 + slub * 0.03
			r[y * N + x] = 0.9
			var wear := tn(x, y, 0.012, 10) * 0.5 + 0.5
			var shade := 0.72 + thread * 0.22 + slub * fuzz + wear * 0.1
			var c := base * shade
			col.set_pixel(x, y, Color(c.r, c.g, c.b))
	_save(name, col, h, r, 2.0)


## Interlocking rings. Dark steel, with a dark gap between the links.
func _chainmail(name: String, base: Color) -> void:
	var col := Image.create(N, N, false, Image.FORMAT_RGB8)
	var h := PackedFloat32Array()
	h.resize(N * N)
	var r := PackedFloat32Array()
	r.resize(N * N)
	var s := 16.0
	var rad := s * 0.62
	var wid := s * 0.17
	for y in N:
		for x in N:
			var best := 0.0
			var gx := int(floor(x / s))
			var gy := int(floor(y / (s * 0.5)))
			for dj in range(-2, 3):
				for di in range(-1, 2):
					var j := gy + dj
					var i := gx + di
					var cx := (i + (0.5 if (j % 2 != 0) else 0.0)) * s
					var cy := j * s * 0.5
					var d := Vector2(x - cx, y - cy).length()
					# every other row of rings is stood on edge (squashed in x)
					if j % 2 != 0:
						d = Vector2((x - cx) * 1.0, (y - cy) * 0.82).length()
					var e := (d - rad) / wid
					if absf(e) < 1.0:
						best = maxf(best, sqrt(1.0 - e * e) * (0.85 + 0.15 * float(j % 2)))
			var fine := tn(x, y, 0.4, 11)
			h[y * N + x] = best * 0.8
			r[y * N + x] = clampf(0.5 + (1.0 - best) * 0.3 + fine * 0.05, 0.3, 0.95)
			var shade := 0.18 + best * 0.95 + fine * 0.05
			var c := base * shade
			col.set_pixel(x, y, Color(c.r, c.g, c.b))
	_save(name, col, h, r, 4.0)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	_metal("bronze", Color(0.54, 0.39, 0.21), Color(0.3, 0.46, 0.36), 0.1, 0.42, 0.25, 40)      # dull, a little verdigris
	_metal("iron", Color(0.3, 0.3, 0.32), Color(0.34, 0.2, 0.12), 0.2, 0.66, 0.35, 70)        # dark, rusty blotches
	_metal("steel", Color(0.6, 0.62, 0.66), Color(0.5, 0.5, 0.52), 0.0, 0.3, 0.7, 25)           # clean, brushed, cool
	_leather("leather", Color(0.3, 0.19, 0.11))
	_cloth("cloth", Color(0.9, 0.9, 0.9), 8, 0.35)
	_chainmail("chainmail", Color(0.42, 0.43, 0.47))
	quit()
