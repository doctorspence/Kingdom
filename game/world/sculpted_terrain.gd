@tool
class_name SculptedTerrain
extends ZoneTerrain
## A hand-designed zone ground. The shape comes from a "land" script (the
## zone's landform, river, roads, tracks, quarry cuts, flat spots), baked once
## into a 1 m height grid:
##   1. the natural land (hills, ridges, cliffs) from land.natural(x, z)
##   2. roads follow the ground: each road's height profile is the smoothed
##      land under it, so it climbs and dips gently instead of being cut flat
##   3. the river is carved with its own width, depth and water level per point
##   4. cuts (quarry floors, benches, ramps)
##   5. building pads: every child of `pad_root` with a "pad" metadata (Vector2
##      width, depth) gets a level pad under its footprint, blended into the
##      slope, so buildings never float or sink
## Beyond the playable square the land keeps going (lower detail, no
## collision), so the horizon is hills and forest instead of a bowl rim.
##
## Same API as ZoneTerrain (height_at, river_distance, water_level...), so
## everything that already places things on the ground keeps working.

## The zone's land description (a script with natural(), river, roads...).
@export var land_script: Script
## Children of this node with a "pad" metadata (Vector2 w, d) get a level pad.
@export var pad_root: NodePath
## How far the backdrop land reaches beyond the playable edge (meters).
@export var backdrop := 150.0

var land: Object
var _n := 0            # grid points per side
var _half := 0.0
var _h := PackedFloat32Array()    # final ground height
var _rd := PackedFloat32Array()   # distance to nearest road centerline
var _rw := PackedFloat32Array()   # half width of that road
var _td := PackedFloat32Array()   # distance to nearest track
var _vd := PackedFloat32Array()   # distance to the river centerline
var _wl := PackedFloat32Array()   # water level of the nearest river point
var _vw := PackedFloat32Array()   # river half width there
var _pm := PackedFloat32Array()   # 1 inside building pads (and their yards), 0 outside
var _rock := PackedFloat32Array() # extra rock painting (quarry floors)
var _fp := PackedFloat32Array()   # ploughed field furrows (0..1)
var _ns := PackedInt32Array()     # scratch: nearest segment per cell
var _nt := PackedFloat32Array()   # scratch: position on that segment
var _nd := PackedFloat32Array()   # scratch: distance to it
var _road_lines: Array = []       # dense polylines with per-point data
var _river_line: Dictionary = {}
var _grid_ready := false
var _water_mid := 5.6


func _ready() -> void:
	add_to_group(&"zone_terrain")
	_rebuild()


## Ground height at a world x, z (bilinear from the baked grid).
func height_at(x: float, z: float) -> float:
	if not _grid_ready:
		_bake()
	var fx := (x + _half) / cell
	var fz := (z + _half) / cell
	if fx < 0.0 or fz < 0.0 or fx > _n - 1 or fz > _n - 1:
		return _backdrop_height(x, z)
	return _sample(_h, fx, fz)


func water_level() -> float:
	return _water_mid


## The river's water surface nearest to a point.
func water_level_at(x: float, z: float) -> float:
	if not _grid_ready:
		_bake()
	var fx := clampf((x + _half) / cell, 0.0, _n - 1.0)
	var fz := clampf((z + _half) / cell, 0.0, _n - 1.0)
	return _sample(_wl, fx, fz)


func river_distance(x: float, z: float) -> float:
	if not _grid_ready:
		_bake()
	var fx := clampf((x + _half) / cell, 0.0, _n - 1.0)
	var fz := clampf((z + _half) / cell, 0.0, _n - 1.0)
	return _sample(_vd, fx, fz)


## True inside a building pad (or its trampled yard): keep trees and grass off.
func in_pad(x: float, z: float) -> float:
	if not _grid_ready:
		_bake()
	var fx := clampf((x + _half) / cell, 0.0, _n - 1.0)
	var fz := clampf((z + _half) / cell, 0.0, _n - 1.0)
	return _sample(_pm, fx, fz)


## How ploughed the ground is here (0 = not a field).
func in_field(x: float, z: float) -> float:
	if not _grid_ready or absf(x) > _half or absf(z) > _half:
		return 0.0
	return _sample(_fp, (x + _half) / cell, (z + _half) / cell)


func _distance_to_lines(lines: Array[PackedVector2Array], p: Vector2) -> float:
	# Road and track distances come from the baked grid (fast); anything else is measured.
	if _grid_ready and absf(p.x) < _half and absf(p.y) < _half:
		var fx := (p.x + _half) / cell
		var fz := (p.y + _half) / cell
		if is_same(lines, roads):
			return _sample(_rd, fx, fz)
		if is_same(lines, tracks):
			return _sample(_td, fx, fz)
	return super._distance_to_lines(lines, p)


func _sample(arr: PackedFloat32Array, fx: float, fz: float) -> float:
	var ix := mini(int(fx), _n - 2)
	var iz := mini(int(fz), _n - 2)
	var tx := fx - ix
	var tz := fz - iz
	var i := iz * _n + ix
	var a := lerpf(arr[i], arr[i + 1], tx)
	var b := lerpf(arr[i + _n], arr[i + _n + 1], tx)
	return lerpf(a, b, tz)


# ---- baking -------------------------------------------------------------------

func _bake() -> void:
	_grid_ready = false
	land = land_script.new() if land_script else null
	if land == null:
		push_error("SculptedTerrain: no land script")
		return
	_noise.seed = noise_seed
	_noise.frequency = 0.006
	_noise.fractal_octaves = 3
	if land.has_method("setup"):
		land.setup(_noise)
	_half = size * 0.5
	_n = int(round(size / cell)) + 1
	var nn := _n * _n
	var cache_key := _cache_key()
	if cache_key != "" and _load_cache(cache_key):
		clearings = land.clearings
		_grid_ready = true
		return
	_h.resize(nn)
	_rd.resize(nn)
	_rw.resize(nn)
	_td.resize(nn)
	_vd.resize(nn)
	_wl.resize(nn)
	_vw.resize(nn)
	_pm.resize(nn)
	_rock.resize(nn)
	_ns.resize(nn)
	_nt.resize(nn)
	_nd.resize(nn)
	_rd.fill(99.0)
	_td.fill(99.0)
	_vd.fill(99.0)
	_rw.fill(3.0)
	_pm.fill(0.0)
	_rock.fill(0.0)
	# 1. Natural land.
	for iz in _n:
		var z := -_half + iz * cell
		for ix in _n:
			_h[iz * _n + ix] = land.natural(-_half + ix * cell, z)
	# 1b. Fields: ridge-and-furrow ripples in ploughland.
	_fp.resize(nn)
	_fp.fill(0.0)
	if land.get("fields") != null:
		for f in land.fields:
			_apply_field(f)
	# 2. Roads: dense lines, height profiles from the land under them, then flatten.
	_road_lines.clear()
	roads.clear()
	for r in land.roads:
		var line := _densify(r.points, 2.0)
		var prof := PackedFloat32Array()
		for p in line:
			prof.append(_raw(p.x, p.y))
		prof = _smooth(prof, int(r.get("smooth", 7)))
		var d := {"pts": line, "h": prof, "w": float(r.width) * 0.5, "shoulder": float(r.get("shoulder", 4.0)), "ditch": float(r.get("ditch", 0.0))}
		_road_lines.append(d)
		roads.append(line)
	var rh := PackedFloat32Array()
	rh.resize(nn)
	var rs := PackedFloat32Array()
	rs.resize(nn)
	var rdt := PackedFloat32Array()
	rdt.resize(nn)
	for d in _road_lines:
		var prof: PackedFloat32Array = d.h
		_nearest(d.pts, d.w + d.shoulder + 3.0)
		for i in nn:
			var s := _ns[i]
			if s >= 0 and _nd[i] < _rd[i]:
				_rd[i] = _nd[i]
				_rw[i] = d.w
				rs[i] = d.shoulder
				rdt[i] = d.ditch
				rh[i] = lerpf(prof[s], prof[s + 1], _nt[i])
	for i in nn:
		var dist := _rd[i]
		var hw := _rw[i]
		var sh := rs[i]
		if dist < hw + sh:
			var crown := 0.07 * maxf(0.0, 1.0 - (dist / maxf(hw, 0.1)) * (dist / maxf(hw, 0.1)))
			var t := smoothstep(hw * 0.85, hw + sh, dist)
			var ditch := 0.0
			if rdt[i] > 0.0:
				ditch = -rdt[i] * clampf(1.0 - absf(dist - hw - 0.9) / 0.9, 0.0, 1.0)
			_h[i] = lerpf(rh[i] + crown, _h[i], t) + ditch
	# Tracks: painted only (they follow the ground as they are).
	tracks.clear()
	for t in land.tracks:
		var line := _densify(t.points, 2.0)
		tracks.append(line)
		_nearest(line, 12.0)
		for i in nn:
			if _ns[i] >= 0 and _nd[i] < _td[i]:
				_td[i] = _nd[i]
	# 3. River.
	_carve_river()
	# 4. Cuts (quarry floors, benches, ramps).
	var pre := _h.duplicate()
	for c in land.cuts:
		_apply_cut(c, pre)
	# 5. Flat spots and building pads.
	for f in land.flats:
		_apply_pad(Vector2(f.x, f.y), Vector2(f.z, f.z), 0.0, f.w, NAN, true)
	if not pad_root.is_empty() and has_node(pad_root):
		for c in get_node(pad_root).get_children():
			var n3 := c as Node3D
			if n3 == null or not n3.has_meta("pad"):
				continue
			var sz: Vector2 = n3.get_meta("pad")
			var y: float = n3.get_meta("pad_y", NAN)
			_apply_pad(Vector2(n3.position.x, n3.position.z), sz * 0.5, n3.rotation.y, float(n3.get_meta("pad_blend", 4.0)), y, false)
	clearings = land.clearings
	_grid_ready = true
	if cache_key != "":
		_save_cache(cache_key)


# ---- bake cache ---------------------------------------------------------------
# The bake is deterministic, so its result is stored in user:// and reused while the
# land script, this script, the grid settings and the building pads are unchanged.
# Exported builds (no script source) simply bake every time.

func _cache_path() -> String:
	return "user://terrain_cache_%s.bin" % name


func _cache_key() -> String:
	var own: Script = get_script()
	if land_script == null or land_script.source_code.is_empty() or own.source_code.is_empty():
		return ""
	var s: String = land_script.source_code + get_script().source_code
	if land.get_script() != land_script:
		return ""
	s += "|%d|%f|%f|%d" % [noise_seed, size, cell, backdrop]
	if not pad_root.is_empty() and has_node(pad_root):
		for c in get_node(pad_root).get_children():
			var n3 := c as Node3D
			if n3 != null and n3.has_meta("pad"):
				s += "|%s %s %f %s %s %s" % [n3.name, n3.position, n3.rotation.y, n3.get_meta("pad"), n3.get_meta("pad_y", NAN), n3.get_meta("pad_blend", 4.0)]
	return s.sha256_text()


func _load_cache(key: String) -> bool:
	var f := FileAccess.open(_cache_path(), FileAccess.READ)
	if f == null:
		return false
	var raw_size := int(f.get_64())
	var d: Variant = bytes_to_var(f.get_buffer(f.get_length() - 8).decompress(raw_size, FileAccess.COMPRESSION_ZSTD))
	if not (d is Dictionary) or d.get("key", "") != key:
		return false
	_h = d.h
	_rd = d.rd
	_rw = d.rw
	_td = d.td
	_vd = d.vd
	_wl = d.wl
	_vw = d.vw
	_pm = d.pm
	_rock = d.rock
	_fp = d.fp
	_road_lines = d.road_lines
	_river_line = d.river_line
	_water_mid = d.water_mid
	roads.clear()
	for p in d.roads:
		roads.append(p)
	tracks.clear()
	for p in d.tracks:
		tracks.append(p)
	return true


func _save_cache(key: String) -> void:
	var f := FileAccess.open(_cache_path(), FileAccess.WRITE)
	if f == null:
		return
	var d := {"key": key, "h": _h, "rd": _rd, "rw": _rw, "td": _td, "vd": _vd, "wl": _wl, "vw": _vw, "pm": _pm,
		"rock": _rock, "fp": _fp, "road_lines": _road_lines, "river_line": _river_line, "water_mid": _water_mid,
		"roads": Array(roads), "tracks": Array(tracks)}
	var raw := var_to_bytes(d)
	f.store_64(raw.size())
	f.store_buffer(raw.compress(FileAccess.COMPRESSION_ZSTD))
	f.close()


## Height before roads, used for road profiles (natural land only).
func _raw(x: float, z: float) -> float:
	var fx := clampf((x + _half) / cell, 0.0, _n - 1.0)
	var fz := clampf((z + _half) / cell, 0.0, _n - 1.0)
	if absf(x) > _half or absf(z) > _half:
		return land.natural(x, z)
	return _sample(_h, fx, fz)


func _densify(pts: PackedVector2Array, step: float) -> PackedVector2Array:
	# Catmull-Rom through the control points, resampled every `step` meters.
	var out := PackedVector2Array()
	if pts.size() < 2:
		return pts
	for i in pts.size() - 1:
		var p0 := pts[maxi(i - 1, 0)]
		var p1 := pts[i]
		var p2 := pts[i + 1]
		var p3 := pts[mini(i + 2, pts.size() - 1)]
		var steps := maxi(1, int(ceil(p1.distance_to(p2) / step)))
		for s in steps:
			var t := float(s) / steps
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(pts[pts.size() - 1])
	return out


func _smooth(a: PackedFloat32Array, r: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(a.size())
	for i in a.size():
		var s := 0.0
		var wsum := 0.0
		for k in range(-r, r + 1):
			var j := clampi(i + k, 0, a.size() - 1)
			var w := exp(-float(k * k) / maxf(1.0, r * r * 0.5))
			s += a[j] * w
			wsum += w
		out[i] = s / wsum
	return out


## For every cell within `radius` of the line: the distance to it (_nd), the
## nearest segment (_ns, -1 = none) and where on that segment (_nt, 0..1).
## With stride > 1 the line is sampled every `stride` points (a coarser, faster
## measure for far cells; segment and position are mapped back to the full line)
## and only cells still unassigned (_ns < 0) are filled in.
func _nearest(full: PackedVector2Array, radius: float, stride := 1) -> void:
	var nn := _n * _n
	var fixed := PackedByteArray()
	var pts := full
	if stride > 1:
		fixed.resize(nn)
		for i in nn:
			fixed[i] = 1 if _ns[i] >= 0 else 0
			if _ns[i] < 0:
				_nd[i] = radius + 1.0
		pts = PackedVector2Array()
		for i in range(0, full.size(), stride):
			pts.append(full[i])
		if (full.size() - 1) % stride != 0:
			pts.append(full[full.size() - 1])
	else:
		_ns.fill(-1)
		_nd.fill(radius + 1.0)
	for si in pts.size() - 1:
		var a := pts[si]
		var b := pts[si + 1]
		var ab := b - a
		var len2 := maxf(ab.length_squared(), 0.0001)
		var x0 := maxi(0, int(floor((minf(a.x, b.x) - radius + _half) / cell)))
		var x1 := mini(_n - 1, int(ceil((maxf(a.x, b.x) + radius + _half) / cell)))
		var z0 := maxi(0, int(floor((minf(a.y, b.y) - radius + _half) / cell)))
		var z1 := mini(_n - 1, int(ceil((maxf(a.y, b.y) + radius + _half) / cell)))
		for iz in range(z0, z1 + 1):
			var pz := -_half + iz * cell
			for ix in range(x0, x1 + 1):
				var i := iz * _n + ix
				if stride > 1 and fixed[i] == 1:
					continue
				var px := -_half + ix * cell
				var t := clampf(((px - a.x) * ab.x + (pz - a.y) * ab.y) / len2, 0.0, 1.0)
				var qx := a.x + ab.x * t - px
				var qz := a.y + ab.y * t - pz
				var d := sqrt(qx * qx + qz * qz)
				if d < _nd[i]:
					_nd[i] = d
					if stride > 1:
						var ft := t * stride
						var k := mini(int(ft), stride - 1)
						_ns[i] = mini(si * stride + k, full.size() - 2)
						_nt[i] = clampf(ft - k, 0.0, 1.0)
					else:
						_ns[i] = si
						_nt[i] = t


func _carve_river() -> void:
	var r: Dictionary = land.river
	var ctrl: PackedVector2Array = r.points
	var line := _densify(ctrl, 2.0)
	# Per-point values follow the control points by arc length.
	var hw := PackedFloat32Array()
	var dep := PackedFloat32Array()
	var lvl := PackedFloat32Array()
	var bank := PackedFloat32Array()
	var ctrl_s := PackedFloat32Array([0.0])
	for i in range(1, ctrl.size()):
		ctrl_s.append(ctrl_s[i - 1] + ctrl[i].distance_to(ctrl[i - 1]))
	var s := 0.0
	for i in line.size():
		if i > 0:
			s += line[i].distance_to(line[i - 1])
		var f := s / maxf(ctrl_s[ctrl_s.size() - 1], 0.001) * ctrl_s[ctrl_s.size() - 1]
		var k := 0
		while k < ctrl_s.size() - 2 and ctrl_s[k + 1] < f:
			k += 1
		var t := clampf((f - ctrl_s[k]) / maxf(ctrl_s[k + 1] - ctrl_s[k], 0.001), 0.0, 1.0)
		var st := smoothstep(0.0, 1.0, t)
		hw.append(lerpf(r.half_widths[k], r.half_widths[k + 1], st))
		dep.append(lerpf(r.depths[k], r.depths[k + 1], st))
		lvl.append(lerpf(r.levels[k], r.levels[k + 1], t))
		bank.append(lerpf(r.banks[k], r.banks[k + 1], st))
	_river_line = {"pts": line, "hw": hw, "lvl": lvl}
	river = line
	river_width = 9.0
	var nn := _n * _n
	var bk := PackedFloat32Array()
	bk.resize(nn)
	var dp := PackedFloat32Array()
	dp.resize(nn)
	_vw.fill(5.0)
	_wl.fill(lvl[0])
	_nearest(line, 20.0)          # exact near the river ...
	_nearest(line, 60.0, 6)       # ... and a coarser measure for the far cells
	for i in nn:
		var si := _ns[i]
		if si < 0:
			continue
		var t := _nt[i]
		_vd[i] = _nd[i]
		_wl[i] = lerpf(lvl[si], lvl[si + 1], t)
		_vw[i] = lerpf(hw[si], hw[si + 1], t)
		bk[i] = lerpf(bank[si], bank[si + 1], t)
		dp[i] = lerpf(dep[si], dep[si + 1], t)
	# Cells farther away keep the water level of the nearest point on their column.
	for ix in _n:
		var last := lvl[0]
		for iz in _n:
			var i := iz * _n + ix
			if _ns[i] >= 0:
				last = _wl[i]
		for iz in _n:
			var i := iz * _n + ix
			if _ns[i] < 0:
				_wl[i] = last
	_water_mid = _sample(_wl, (0.0 + _half) / cell, (0.0 + _half) / cell)
	for i in nn:
		var d := _vd[i]
		var w := _vw[i]
		var b := bk[i]
		if d > w + b:
			continue
		var wl := _wl[i]
		var target: float
		if d <= w:
			var q := d / maxf(w, 0.1)
			target = wl - dp[i] * (1.0 - q * q) - 0.05
		else:
			target = wl - 0.05 + (d - w) * 0.25
		var tt := smoothstep(w, w + b, d)
		var h := _h[i]
		var carved := minf(h, target) if d <= w else lerpf(minf(h, target), h, tt)
		_h[i] = carved


func _rect_sd(p: Vector2, c: Vector2, half: Vector2, yaw: float) -> Vector2:
	# Returns (signed distance to the rectangle, position along its x axis 0..1).
	var q := (p - c).rotated(-yaw)
	var dx := absf(q.x) - half.x
	var dz := absf(q.y) - half.y
	var outside := Vector2(maxf(dx, 0.0), maxf(dz, 0.0)).length()
	var inside := minf(maxf(dx, dz), 0.0)
	return Vector2(outside + inside, (q.x + half.x) / maxf(2.0 * half.x, 0.001))


func _apply_cut(c: Dictionary, pre: PackedFloat32Array) -> void:
	var center: Vector2 = c.center
	var half: Vector2 = c.half
	var yaw := deg_to_rad(float(c.get("yaw", 0.0)))
	var edge := float(c.get("edge", 1.5))
	var fl := float(c.floor)
	var fl_end := float(c.get("floor_end", fl))
	var mode: String = c.get("mode", "carve")
	var rock := float(c.get("rock", 0.6))
	var rough := float(c.get("rough", 0.0))
	var reach := half.length() + edge + 2.0 + rough
	var x0 := maxi(0, int((center.x - reach + _half) / cell))
	var x1 := mini(_n - 1, int((center.x + reach + _half) / cell) + 1)
	var z0 := maxi(0, int((center.y - reach + _half) / cell))
	var z1 := mini(_n - 1, int((center.y + reach + _half) / cell) + 1)
	for iz in range(z0, z1 + 1):
		for ix in range(x0, x1 + 1):
			var p := Vector2(-_half + ix * cell, -_half + iz * cell)
			var sd := _rect_sd(p, center, half, yaw)
			# Ragged, quarried edges instead of a ruler-straight box.
			sd.x += _noise.get_noise_2d(p.x * 9.0 + 300.0, p.y * 9.0) * rough + _noise.get_noise_2d(p.x * 31.0, p.y * 31.0 + 70.0) * rough * 0.35
			var m := 1.0 - smoothstep(-edge, 0.0, sd.x)
			if m <= 0.0:
				continue
			var i := iz * _n + ix
			var f := lerpf(fl, fl_end, clampf(sd.y, 0.0, 1.0))
			if mode == "carve":
				_h[i] = lerpf(_h[i], minf(_h[i], f), m)
			else:  # "fill": raise to the floor, never above the original land
				_h[i] = lerpf(_h[i], minf(pre[i], maxf(_h[i], f)), m)
			_rock[i] = maxf(_rock[i], rock * m)


func _apply_field(f: Dictionary) -> void:
	var poly: PackedVector2Array = f.poly
	if f.get("kind", "plough") != "plough":
		return
	var dir := Vector2.from_angle(deg_to_rad(float(f.get("dir", 0.0))))
	var across := dir.orthogonal()
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in poly:
		lo = lo.min(p)
		hi = hi.max(p)
	for iz in range(maxi(0, int((lo.y + _half) / cell)), mini(_n - 1, int((hi.y + _half) / cell) + 1) + 1):
		for ix in range(maxi(0, int((lo.x + _half) / cell)), mini(_n - 1, int((hi.x + _half) / cell) + 1) + 1):
			var p := Vector2(-_half + ix * cell, -_half + iz * cell)
			if not Geometry2D.is_point_in_polygon(p, poly):
				continue
			# Distance to the field's edge: a 3 m headland of plain ground.
			var e := INF
			for k in poly.size():
				e = minf(e, p.distance_to(Geometry2D.get_closest_point_to_segment(p, poly[k], poly[(k + 1) % poly.size()])))
			var m := smoothstep(1.0, 4.0, e)
			var stripe := 0.5 + 0.5 * sin(p.dot(across) * TAU / 4.5)
			var i := iz * _n + ix
			_h[i] += (stripe - 0.5) * 0.3 * m
			_fp[i] = maxf(_fp[i], m * (0.55 + 0.45 * stripe))


func _apply_pad(center: Vector2, half: Vector2, yaw: float, blend: float, y: float, round_pad: bool) -> void:
	var margin := 0.8
	# Target height: the mean of the ground over the footprint.
	if is_nan(y):
		var sum := 0.0
		var cnt := 0
		for gz in range(-2, 3):
			for gx in range(-2, 3):
				var q := Vector2(gx / 2.0 * half.x, gz / 2.0 * half.y)
				if round_pad and q.length() > half.x:
					continue
				var w := center + q.rotated(yaw)
				sum += _raw(w.x, w.y)
				cnt += 1
		y = sum / maxf(cnt, 1)
	var reach := half.length() + margin + blend + 1.0
	var x0 := maxi(0, int((center.x - reach + _half) / cell))
	var x1 := mini(_n - 1, int((center.x + reach + _half) / cell) + 1)
	var z0 := maxi(0, int((center.y - reach + _half) / cell))
	var z1 := mini(_n - 1, int((center.y + reach + _half) / cell) + 1)
	for iz in range(z0, z1 + 1):
		for ix in range(x0, x1 + 1):
			var p := Vector2(-_half + ix * cell, -_half + iz * cell)
			var sd: float
			if round_pad:
				sd = p.distance_to(center) - half.x
			else:
				sd = _rect_sd(p, center, half, yaw).x
			var m := 1.0 - smoothstep(margin, margin + blend, sd)
			if m <= 0.0:
				continue
			var i := iz * _n + ix
			_h[i] = lerpf(_h[i], y, m)
			if not round_pad:
				_pm[i] = maxf(_pm[i], 1.0 - smoothstep(0.5, 3.5, sd))


func _backdrop_height(x: float, z: float) -> float:
	if land == null:
		return 0.0
	var h: float = land.natural(x, z)
	# Rivers continue beyond the edge.
	if not _river_line.is_empty():
		var p := Vector2(x, z)
		var pts: PackedVector2Array = _river_line.pts
		var best := INF
		var bi := 0
		var a := pts[0]
		var b := pts[pts.size() - 1]
		# The river only leaves the square at its two ends.
		for end_i in [0, pts.size() - 1]:
			var e := pts[end_i]
			var dir := (e - pts[end_i + (4 if end_i == 0 else -4)]).normalized()
			var far := e + dir * 400.0
			var q := Geometry2D.get_closest_point_to_segment(p, e, far)
			var d := q.distance_to(p)
			if d < best:
				best = d
				bi = end_i
		var hw: float = _river_line.hw[bi]
		var lvl: float = _river_line.lvl[bi]
		if best < hw + 10.0:
			var tt := smoothstep(hw, hw + 10.0, best)
			h = lerpf(minf(h, lvl - 0.8), h, tt)
	return h


# ---- meshes -------------------------------------------------------------------

func _rebuild() -> void:
	_rebuild_queued = false
	if not is_inside_tree():
		return
	var t0 := Time.get_ticks_msec()
	_bake()
	if not _grid_ready:
		return
	if _built:
		_built.queue_free()
	_built = Node3D.new()
	_built.name = "Built"
	# Ground mesh in chunks (so off-screen parts are skipped when drawing).
	var chunk := 52
	var c0 := 0
	while c0 < _n - 1:
		var r0 := 0
		while r0 < _n - 1:
			_built.add_child(_chunk_mesh(c0, r0, mini(c0 + chunk, _n - 1), mini(r0 + chunk, _n - 1)))
			r0 += chunk
		c0 += chunk
	# Collision: a height field (fast and exact for this grid).
	var body := StaticBody3D.new()
	var hs := HeightMapShape3D.new()
	hs.map_width = _n
	hs.map_depth = _n
	hs.map_data = _h
	var cs := CollisionShape3D.new()
	cs.shape = hs
	cs.scale = Vector3(cell, 1.0, cell)
	body.add_child(cs)
	_built.add_child(body)
	_built.add_child(_water_mesh())
	if DisplayServer.get_name() != "headless":
		_built.add_child(_backdrop_mesh())
	add_child(_built)
	print("SculptedTerrain: built %dx%d in %d ms" % [_n, _n, Time.get_ticks_msec() - t0])


func _chunk_mesh(cx0: int, cz0: int, cx1: int, cz1: int) -> MeshInstance3D:
	var w := cx1 - cx0 + 1
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	for iz in range(cz0, cz1 + 1):
		for ix in range(cx0, cx1 + 1):
			var i := iz * _n + ix
			var v := Vector3(-_half + ix * cell, _h[i], -_half + iz * cell)
			verts.append(v)
			var hl := _h[i - 1] if ix > 0 else _h[i]
			var hr := _h[i + 1] if ix < _n - 1 else _h[i]
			var hu := _h[i - _n] if iz > 0 else _h[i]
			var hd := _h[i + _n] if iz < _n - 1 else _h[i]
			var nrm := Vector3(hl - hr, 2.0 * cell, hu - hd).normalized()
			norms.append(nrm)
			var slope := Vector2(hr - hl, hd - hu).length() / (2.0 * cell)
			cols.append(_weights_at(i, v, slope))
	var idx := PackedInt32Array()
	var hgt := cz1 - cz0 + 1
	for z in hgt - 1:
		for x in w - 1:
			var a := z * w + x
			var b := a + 1
			var c := a + w
			var d := c + 1
			idx.append_array([a, b, d, a, d, c])
	# Skirt on the outer edges of the whole ground hides cracks against the backdrop.
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	return mi


func _weights_at(i: int, v: Vector3, slope: float) -> Color:
	var mud := clampf(_noise.get_noise_2d(v.x * 4.0, v.z * 4.0) * 0.8 + 0.2, 0.0, 1.0) * 0.45
	var hw := _rw[i]
	var road := 1.0 - smoothstep(hw * 0.55, hw * 1.05 + 0.3, _rd[i])
	road = maxf(road, (1.0 - smoothstep(0.5, 1.25, _td[i])) * 0.85)
	var bank := 1.0 - smoothstep(_vw[i] * 0.9, _vw[i] * 1.6 + 1.5, _vd[i])
	mud = maxf(mud, bank)
	mud = maxf(mud, _pm[i] * 0.85)
	mud = maxf(mud, _fp[i] * 0.95)
	var p := Vector2(v.x, v.z)
	for c in clearings:
		var d := Vector2(c.x, c.y).distance_to(p)
		mud = maxf(mud, (1.0 - smoothstep(c.z * 0.55, c.z, d)) * 0.9)
	var rock := maxf(smoothstep(0.6, 1.0, slope), _rock[i])
	if v.y < _wl[i] - 0.6 and _vd[i] < _vw[i] * 1.2:
		rock = maxf(rock, 0.35)  # stony riverbed
	var grass := maxf(0.0, 1.0 - mud - road)
	return Color(grass * (1.0 - rock), mud * (1.0 - rock), road * (1.0 - rock), rock)


func _ground_weights(v: Vector3, slope: float) -> Color:
	if not _grid_ready or absf(v.x) > _half or absf(v.z) > _half:
		return super._ground_weights(v, slope)
	var ix := clampi(int(round((v.x + _half) / cell)), 0, _n - 1)
	var iz := clampi(int(round((v.z + _half) / cell)), 0, _n - 1)
	return _weights_at(iz * _n + ix, v, slope)


func _water_mesh() -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: PackedVector2Array = _river_line.pts
	var hw: PackedFloat32Array = _river_line.hw
	var lvl: PackedFloat32Array = _river_line.lvl
	# Extend both ends beyond the edge so the river runs off into the backdrop.
	var ext_pts := PackedVector2Array()
	var ext_hw := PackedFloat32Array()
	var ext_lvl := PackedFloat32Array()
	var d0 := (pts[0] - pts[4]).normalized()
	for k in range(6, 0, -1):
		ext_pts.append(pts[0] + d0 * 20.0 * k)
		ext_hw.append(hw[0])
		ext_lvl.append(lvl[0] - 0.8)
	ext_pts.append_array(pts)
	ext_hw.append_array(hw)
	ext_lvl.append_array(lvl)
	var last := pts.size() - 1
	var d1 := (pts[last] - pts[last - 4]).normalized()
	for k in range(1, 7):
		ext_pts.append(pts[last] + d1 * 20.0 * k)
		ext_hw.append(hw[last])
		ext_lvl.append(lvl[last] - 0.8)
	for i in ext_pts.size() - 1:
		var p0 := ext_pts[i]
		var p1 := ext_pts[i + 1]
		var dir0 := (ext_pts[mini(i + 1, ext_pts.size() - 1)] - ext_pts[maxi(i - 1, 0)]).normalized()
		var dir1 := (ext_pts[mini(i + 2, ext_pts.size() - 1)] - ext_pts[i]).normalized()
		var n0 := dir0.orthogonal() * ext_hw[i] * 1.15
		var n1 := dir1.orthogonal() * ext_hw[i + 1] * 1.15
		var v0 := Vector3(p0.x - n0.x, ext_lvl[i], p0.y - n0.y)
		var v1 := Vector3(p0.x + n0.x, ext_lvl[i], p0.y + n0.y)
		var v2 := Vector3(p1.x - n1.x, ext_lvl[i + 1], p1.y - n1.y)
		var v3 := Vector3(p1.x + n1.x, ext_lvl[i + 1], p1.y + n1.y)
		for v in [v0, v2, v1, v1, v2, v3]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	var water := MeshInstance3D.new()
	water.name = "Water"
	water.mesh = st.commit()
	water.material_override = water_material
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return water


## Lower-detail land beyond the playable square: the horizon.
func _backdrop_mesh() -> MeshInstance3D:
	var step := 4.0
	var ring := int(backdrop / step)
	var inner := int(round(size / step))
	var m := inner + 2 * ring + 1
	var start := -_half - ring * step
	var verts := PackedVector3Array()
	var cols := PackedColorArray()
	verts.resize(m * m)
	cols.resize(m * m)
	for iz in m:
		for ix in m:
			var x := start + ix * step
			var z := start + iz * step
			var on_inner := absf(x) <= _half + 0.01 and absf(z) <= _half + 0.01
			var y: float
			if on_inner:
				y = height_at(clampf(x, -_half, _half), clampf(z, -_half, _half)) - 0.15
			else:
				y = _backdrop_height(x, z)
			verts[iz * m + ix] = Vector3(x, y, z)
	for iz in m:
		for ix in m:
			var i := iz * m + ix
			var v := verts[i]
			var hr := verts[i + 1].y if ix < m - 1 else v.y
			var hd := verts[i + m].y if iz < m - 1 else v.y
			var slope := Vector2(hr - v.y, hd - v.y).length() / step
			var road := 0.0
			for d in _road_lines:
				var pts: PackedVector2Array = d.pts
				for e in [pts[0], pts[pts.size() - 1]]:
					if absf(e.x) > _half - 4.0 or absf(e.y) > _half - 4.0:
						if Vector2(v.x, v.z).distance_to(e) < 400.0:
							var dir: Vector2 = (e - (pts[4] if e == pts[0] else pts[pts.size() - 5])).normalized()
							var q := Geometry2D.get_closest_point_to_segment(Vector2(v.x, v.z), e, e + dir * 400.0)
							road = maxf(road, 1.0 - smoothstep(1.5, 4.0, q.distance_to(Vector2(v.x, v.z))))
			var rock := smoothstep(0.6, 1.0, slope)
			var grass := maxf(0.0, 1.0 - road - 0.25)
			cols[i] = Color(grass * (1.0 - rock), 0.25 * (1.0 - rock), road * (1.0 - rock), rock)
	var idx := PackedInt32Array()
	for iz in m - 1:
		for ix in m - 1:
			var x := start + ix * step
			var z := start + iz * step
			# Skip quads inside the playable square (the real ground is there).
			if x >= -_half - 0.01 and x + step <= _half + 0.01 and z >= -_half - 0.01 and z + step <= _half + 0.01:
				continue
			var a := iz * m + ix
			idx.append_array([a, a + 1, a + m + 1, a, a + m + 1, a + m])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var st := SurfaceTool.new()
	st.create_from_arrays(arrays)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Backdrop"
	mi.mesh = st.commit()
	mi.material_override = material
	return mi


# ---- map ----------------------------------------------------------------------

func map_image(px := 256) -> Image:
	var img := Image.create(px, px, false, Image.FORMAT_RGB8)
	var step := size / px
	for j in px:
		for i in px:
			var x := -_half + (i + 0.5) * step
			var z := -_half + (j + 0.5) * step
			var h := height_at(x, z)
			var dx := height_at(x + step, z) - h
			var dz := height_at(x, z + step) - h
			var slope := Vector2(dx, dz).length() / step
			var w := _ground_weights(Vector3(x, h, z), slope)
			var c := Color(0.24, 0.27, 0.16) * w.r + Color(0.24, 0.2, 0.15) * w.g + Color(0.33, 0.28, 0.21) * w.b + Color(0.36, 0.35, 0.33) * w.a
			if river_distance(x, z) < _sample(_vw, (x + _half) / cell, (z + _half) / cell) and h < water_level_at(x, z):
				c = Color(0.2, 0.26, 0.3)
			var shade := clampf(1.0 + (-dx - dz) * 0.35, 0.55, 1.45)
			c = Color(c.r * shade, c.g * shade, c.b * shade).lightened(0.12)
			img.set_pixel(i, j, c)
	return img
