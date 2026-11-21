extends Node
## Zone 1 placement audit (not a pass/fail check): loads the Tithelands and
## measures every placed object against the terrain, roads, river, the other
## buildings and the scattered trees/rocks. Prints a report.
##   Godot_console.exe --headless --path . --script res://tests/run.gd -- ../tools/zone1_audit
## Reused for the final validation pass after the overhaul.

const DOOR_PROPS := ["Cottage", "Mill", "TitheBarn"]  # door on local +z

var terrain: ZoneTerrain
var foot := {}  # name -> PackedVector2Array (world xz footprint)


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	for i in 30:
		await get_tree().process_frame
	terrain = scene.get_node("Terrain")
	var places: Node3D = scene.get_node("Places")
	print("\n=== BUILDINGS / PLACED OBJECTS ===")
	print("name | kind | ground spread | float at low corner | buried at high corner | road dist | river dist | door")
	var placed: Array = places.get_children()
	if scene.has_node("Dressing"):
		placed.append_array(scene.get_node("Dressing").get_children())
	for c in placed:
		var n := c as Node3D
		if n == null:
			continue
		var box := _local_aabb(n)
		if box.size == Vector3.ZERO:
			continue
		var kind := String(n.scene_file_path.get_file().get_basename()) if n.scene_file_path != "" else String(n.get_class())
		var pts := _footprint(n, box)
		foot[n.name] = pts
		var hs := []
		for p in _samples(pts):
			hs.append(terrain.height_at(p.x, p.y))
		var lo: float = hs.min()
		var hi: float = hs.max()
		var bottom := n.global_position.y + box.position.y * n.scale.y
		var floating := bottom - lo
		var buried := hi - bottom
		var road := INF
		var river := INF
		for p in _samples(pts):
			road = minf(road, terrain._distance_to_lines(terrain.roads, p))
			river = minf(river, terrain.river_distance(p.x, p.y))
		var door := ""
		if kind in ["cottage", "mill", "tithe_barn"]:
			door = _door_report(n, box)
		var flags := []
		if floating > 0.35: flags.append("FLOATS")
		if buried > 1.2: flags.append("DIGS-IN")
		if road < 3.0: flags.append("ON-ROAD")
		if river < terrain.river_width * 0.6 and kind != "bridge_broken": flags.append("IN-RIVER")
		print("%-20s | %-14s | %5.2f | %5.2f | %5.2f | %5.1f | %5.1f | %s %s" % [n.name, kind, hi - lo, floating, buried, road, river, door, " ".join(flags)])
	print("\n=== BUILDING OVERLAPS ===")
	var names := foot.keys()
	for i in names.size():
		for j in range(i + 1, names.size()):
			var inter := Geometry2D.intersect_polygons(foot[names[i]], foot[names[j]])
			if not inter.is_empty():
				var area := 0.0
				for poly in inter:
					area += _area(poly)
				if area > 0.5:
					print("%s x %s : %.1f m2" % [names[i], names[j], area])
	print("\n=== SCATTER INSIDE / AGAINST BUILDINGS ===")
	for sname in ["Woods", "Rocks", "Clutter"]:
		var s: Node3D = scene.get_node_or_null(sname)
		if s == null:
			continue
		var hits := {}
		var total := 0
		var items: Array = []
		for t in s.get_children():
			if t.name == "Trunks":
				items.append_array(t.get_children())
			elif not (t is MultiMeshInstance3D):
				items.append(t)
		for t in items:
			var p := Vector2(t.global_position.x, t.global_position.z)
			total += 1
			for k in foot:
				var poly: PackedVector2Array = foot[k]
				if Geometry2D.is_point_in_polygon(p, _grow(poly, 1.5)):
					hits[k] = hits.get(k, 0) + 1
		print("%s (%d placed): %s" % [sname, total, str(hits)])
	print("\n=== ENEMY SPAWNS INSIDE BUILDINGS ===")
	for sp in scene.get_node("EnemySpawns").get_children():
		var p := Vector2(sp.global_position.x, sp.global_position.z)
		for k in foot:
			if Geometry2D.is_point_in_polygon(p, foot[k]):
				print("%s inside %s" % [sp.name, k])
	print("\n=== ROAD PROFILE (main road, every 10 m: ground height, cross-slope) ===")
	for line in terrain.roads:
		var s := ""
		for i in line.size() - 1:
			var a: Vector2 = line[i]
			var b: Vector2 = line[i + 1]
			var steps := int(a.distance_to(b) / 10.0)
			for k in steps:
				var p := a.lerp(b, float(k) / maxf(1.0, steps))
				var side := (b - a).normalized().orthogonal() * 3.0
				# Cut/fill: road surface vs the ground 12 m to either side (outside the flattening).
				var far := (b - a).normalized().orthogonal() * 12.0
				var hl := terrain.height_at(p.x + far.x, p.y + far.y)
				var hr := terrain.height_at(p.x - far.x, p.y - far.y)
				var hc := terrain.height_at(p.x, p.y)
				var cut := maxf(hl, hr) - hc
				var fill := hc - minf(hl, hr)
				s += "[%.0f,%.0f] h%.1f cut%.1f fill%.1f\n" % [p.x, p.y, hc, cut, fill]
		print(s)
	print("\n=== TERRAIN ===")
	var hmin := INF
	var hmax := -INF
	var steep := 0
	var cells := 0
	var half := terrain.size * 0.5
	var x := -half
	while x < half:
		var z := -half
		while z < half:
			var h := terrain.height_at(x, z)
			hmin = minf(hmin, h)
			hmax = maxf(hmax, h)
			var sl := Vector2(terrain.height_at(x + 1, z) - h, terrain.height_at(x, z + 1) - h).length()
			if sl > 0.6:
				steep += 1
			cells += 1
			z += 4.0
		x += 4.0
	print("height %.1f .. %.1f, steep (>31 deg) cells %d of %d" % [hmin, hmax, steep, cells])
	var inner := 0
	var flat := 0
	x = -half + 30
	while x < half - 30:
		var z := -half + 30
		while z < half - 30:
			var h := terrain.height_at(x, z)
			var sl := Vector2(terrain.height_at(x + 4, z) - h, terrain.height_at(x, z + 4) - h).length() / 4.0
			if sl < 0.05:
				flat += 1
			inner += 1
			z += 4.0
		x += 4.0
	print("inner zone: %d%% of cells nearly flat (<3 deg)" % (100 * flat / inner))
	get_tree().quit()


func _local_aabb(root: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for v in root.find_children("*", "VisualInstance3D", true, false):
		var vi := v as VisualInstance3D
		if vi is Light3D or vi is GPUParticles3D or vi is CPUParticles3D or vi is Decal or vi is FogVolume or vi is ReflectionProbe:
			continue
		if not vi.is_visible_in_tree() and not (vi is CSGShape3D):
			continue
		if vi is CSGShape3D and (vi as CSGShape3D).operation == CSGShape3D.OPERATION_SUBTRACTION:
			continue
		var rel: Transform3D = root.global_transform.affine_inverse() * vi.global_transform
		var b: AABB = rel * vi.get_aabb()
		if b.size.length() < 0.01 or b.size.y > 40:
			continue
		out = b if first else out.merge(b)
		first = false
	# Scale is applied in _footprint; undo it here so the box is in unscaled local space.
	return out


func _footprint(n: Node3D, box: AABB) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for c in [Vector3(box.position.x, 0, box.position.z), Vector3(box.end.x, 0, box.position.z), Vector3(box.end.x, 0, box.end.z), Vector3(box.position.x, 0, box.end.z)]:
		var w: Vector3 = n.global_transform * c
		pts.append(Vector2(w.x, w.z))
	return pts


func _samples(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	var center := Vector2.ZERO
	for p in poly:
		center += p
	center /= poly.size()
	out.append(center)
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		for k in 4:
			out.append(a.lerp(b, k / 4.0))
	return out


func _grow(poly: PackedVector2Array, d: float) -> PackedVector2Array:
	var g := Geometry2D.offset_polygon(poly, d)
	return g[0] if not g.is_empty() else poly


func _area(poly: PackedVector2Array) -> float:
	var a := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		a += p.x * q.y - q.x * p.y
	return absf(a) * 0.5


func _door_report(n: Node3D, box: AABB) -> String:
	var fwd := n.global_basis.z.normalized()
	var door_w: Vector3 = n.global_transform * Vector3(0, 0, box.end.z)
	var door := Vector2(door_w.x, door_w.z)
	var facing := Vector2(fwd.x, fwd.z).normalized()
	# Nearest walkable thing: road, track or clearing edge.
	var best := INF
	var target := Vector2.ZERO
	for line in terrain.roads + terrain.tracks:
		for i in line.size() - 1:
			var q := Geometry2D.get_closest_point_to_segment(door, line[i], line[i + 1])
			if q.distance_to(door) < best:
				best = q.distance_to(door)
				target = q
	var ang := rad_to_deg(facing.angle_to((target - door).normalized()))
	var front := door + facing * 2.5
	var step := terrain.height_at(front.x, front.y) - n.global_position.y
	var tag := "door faces %s, nearest road %.0f m at %+.0f deg, ground 2.5 m out %+.2f" % [_compass(facing), best, ang, step]
	if absf(ang) > 100.0 and best > 1.5:
		tag += " BACK-TO-ROAD"
	if absf(step) > 0.6:
		tag += " DOOR-STEP-BAD"
	return tag


func _compass(v: Vector2) -> String:
	var a := fposmod(rad_to_deg(atan2(v.x, -v.y)), 360.0)
	return ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][int(round(a / 45.0)) % 8]
