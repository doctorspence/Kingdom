class_name PlantScatter
extends Node3D
## Scatters parts of scanned models (Poly Haven, CC0, in assets/nature/<id>/)
## by a density map from the zone's land script. Each glTF holds one or more
## parts (a fern, a rock, a shrub); every part becomes a candidate. Drawn in
## batches (one MultiMesh per 48 m patch and part). Optional colliders for
## rocks, stumps and logs. With `cliff` set, parts are placed only on steep
## ground, turned to face down the slope and pushed into it: rock faces that
## break up smooth cliffs.

@export var terrain: SculptedTerrain
## Model ids in assets/nature (each id/id.gltf).
@export var models: PackedStringArray = []
## Density map in the land script: forest, rocks, clutter, undergrowth...
@export var layer := "undergrowth"
@export var spacing := 3.0
@export var density := 1.0
@export var scatter_seed := 1
## Target size: each part is scaled so its largest side is about this (meters), times scale_range.
@export var target_size := 0.0
@export var scale_range := Vector2(0.8, 1.3)
@export var keep_off_roads := 3.5
@export var keep_off_tracks := 1.5
@export var sink := 0.05
@export var max_slope := 0.8
## Only steep ground (rise per meter); 0 = off.
@export var cliff := 0.0
## With `cliff` on: no pieces on ground steeper than this (sheer walls are rock already).
@export var cliff_max := 1.5
## Only this far from a road or track (meters, min..max); (0, 0) = anywhere. For path-edge plants.
@export var road_band := Vector2.ZERO
@export var collide := false
@export var shadows := true
@export var seen_from := 90.0
## Batch size (meters): smaller for short-range plants, so a near batch doesn't also draw plants far away.
@export var patch_size := 48.0
## Multiplies the scanned colors (to match the zone's own rock, for example).
@export var tint := Color(1, 1, 1)

var placed := 0
var _parts: Array = []  # [mesh, Transform3D (part to base-centered), size Vector3]


func _ready() -> void:
	_build.call_deferred()


func _build() -> void:
	if terrain == null:
		return
	if not collide and DisplayServer.get_name() == "headless":
		return  # only looks: keep automated checks fast
	terrain.height_at(0, 0)
	var land: Object = terrain.land
	if land == null or not land.has_method(layer):
		return
	_load_parts()
	if _parts.is_empty():
		return
	# Where everything stands never changes unless the land, the models or these
	# settings do: read it from the disk cache when possible (load time).
	var ck := _placement_key()
	var saved: Variant = BakeCache.fetch(_cache_name(), ck) if ck != "" else null
	if not (saved is Dictionary):
		saved = _place(land)
		BakeCache.store(_cache_name(), ck, saved)
	placed = saved.placed
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("plant_counts"):
		print("PLANTS %-12s %d" % [name, placed])
	if collide:
		var body := StaticBody3D.new()
		body.name = "Colliders"
		add_child(body)
		for c: Array in saved.cols:
			var shape := BoxShape3D.new()
			shape.size = c[0]
			var cs := CollisionShape3D.new()
			cs.shape = shape
			cs.position = c[1]
			cs.rotation.y = c[2]
			body.add_child(cs)
	var groups: Dictionary = saved.groups
	for key in groups:
		var pick := int((key as String).split("|")[0])
		var buf: PackedFloat32Array = groups[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _parts[pick][0]
		mm.instance_count = buf.size() / 12
		mm.buffer = buf
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		if tint != Color(1, 1, 1):
			mmi.material_override = _tinted(_parts[pick][0])
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = seen_from
		mmi.visibility_range_end_margin = 10.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		add_child(mmi)


func _cache_name() -> String:
	return "plants_%s_%s" % [owner.scene_file_path.get_file().get_basename() if owner else "", name]


## Everything the placement depends on; "" when it can't be cached (exported game).
func _placement_key() -> String:
	var tk := terrain._cache_key()
	if tk == "":
		return ""
	var part_info: Array = []
	for pt: Array in _parts:
		part_info.append([pt[1], pt[2]])
	return BakeCache.key(["res://game/world/plant_scatter.gd"], [tk, models, layer, spacing, density, scatter_seed,
		target_size, scale_range, keep_off_roads, keep_off_tracks, sink, max_slope, cliff, cliff_max, road_band,
		collide, patch_size, part_info, global_position])


## Works out where every plant stands: {groups: {"part|patch x|patch z": multimesh
## buffer}, cols: [[box size, position, yaw]] (when collide), placed: count}.
func _place(land: Object) -> Dictionary:
	var keep: PackedVector3Array = land.get("keep_clear") if land.get("keep_clear") != null else PackedVector3Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = scatter_seed
	var half := terrain.size * 0.5 - 2.0
	var patch := patch_size
	var groups := {}
	var dens_cache := {}
	var cols: Array = []
	var count := 0
	var z := -half
	while z < half:
		var x := -half
		while x < half:
			var p := Vector2(x + rng.randf() * spacing, z + rng.randf() * spacing)
			var roll := rng.randf()
			var pick := rng.randi() % _parts.size()
			var rot := rng.randf() * TAU
			var sc := rng.randf_range(scale_range.x, scale_range.y)
			x += spacing
			# Densities change over tens of meters: ask the land once per 4 m cell (load time).
			var ck := Vector2i(floori(p.x / 4.0), floori(p.y / 4.0))
			if not dens_cache.has(ck):
				dens_cache[ck] = float(land.call(layer, ck.x * 4.0 + 2.0, ck.y * 4.0 + 2.0))
			if roll > float(dens_cache[ck]) * density:
				continue
			if terrain._distance_to_lines(terrain.roads, p) < keep_off_roads:
				continue
			if terrain._distance_to_lines(terrain.tracks, p) < keep_off_tracks:
				continue
			if road_band.y > 0.0:
				var rdist := minf(terrain._distance_to_lines(terrain.roads, p), terrain._distance_to_lines(terrain.tracks, p))
				if rdist < road_band.x or rdist > road_band.y:
					continue
			if terrain.in_pad(p.x, p.y) > 0.05 or terrain.in_field(p.x, p.y) > 0.05:
				continue
			var h := terrain.height_at(p.x, p.y)
			if h < terrain.water_level_at(p.x, p.y) + 0.25:
				continue
			var gx := terrain.height_at(p.x + 1.0, p.y) - terrain.height_at(p.x - 1.0, p.y)
			var gz := terrain.height_at(p.x, p.y + 1.0) - terrain.height_at(p.x, p.y - 1.0)
			var slope := Vector2(gx, gz).length() * 0.5
			if cliff > 0.0:
				if slope < cliff or slope > cliff_max:
					continue
				pass  # any turn: chunks of rock bedded into the slope
			elif slope > max_slope:
				continue
			var blocked := false
			for c in keep:
				if Vector2(c.x, c.y).distance_to(p) < c.z:
					blocked = true
					break
			if blocked:
				continue
			var part: Array = _parts[pick]
			var s := sc
			if target_size > 0.0:
				var sz: Vector3 = part[2]
				s *= target_size / maxf(sz.x, maxf(sz.y, sz.z))
			var base := h - sink * s
			if cliff > 0.0:
				var part_h: float = (part[2] as Vector3).y * s
				base = h - part_h * 0.45  # outcrop: bedded about halfway into the slope
			var pos := Vector3(p.x, base, p.y)
			var xf: Transform3D = Transform3D(Basis(Vector3.UP, rot).scaled(Vector3.ONE * s), pos) * (part[1] as Transform3D)
			if cliff > 0.0:
				# Lie along the slope instead of standing out of it: up = the ground's normal, bedded in
				# along that normal, so the rock reads as part of the cliff and never as a floating fin.
				var n := Vector3(-gx * 0.5, 1.0, -gz * 0.5).normalized()
				var part_h2: float = (part[2] as Vector3).y * s
				var tilt := Basis(Quaternion(Vector3.UP, n))
				pos = Vector3(p.x, h, p.y) - n * part_h2 * 0.55
				xf = Transform3D(tilt * Basis(Vector3.UP, rot).scaled(Vector3.ONE * s), pos) * (part[1] as Transform3D)
			var key := "%d|%d|%d" % [pick, floori(p.x / patch), floori(p.y / patch)]
			if not groups.has(key):
				groups[key] = []
			groups[key].append(Transform3D(xf.basis, xf.origin - global_position))
			if collide:
				var sz2: Vector3 = part[2] * s
				cols.append([Vector3(sz2.x * 0.8, sz2.y * 0.85, sz2.z * 0.8), Vector3(p.x, base + sz2.y * 0.4, p.y) - global_position, rot])
			count += 1
		z += spacing
	var bufs := {}
	for key in groups:
		# MultiMesh buffer layout: the 3x4 matrix row by row (basis row, then origin).
		var buf := PackedFloat32Array()
		for t: Transform3D in groups[key]:
			var b := t.basis
			buf.append_array([b.x.x, b.y.x, b.z.x, t.origin.x, b.x.y, b.y.y, b.z.y, t.origin.y, b.x.z, b.y.z, b.z.z, t.origin.z])
		bufs[key] = buf
	return {"groups": bufs, "cols": cols, "placed": count}


## Every mesh part of every model, moved so its base center sits at the origin.
func _load_parts() -> void:
	_parts.clear()
	for id in models:
		if String(id).begins_with("plant:"):
			# Code-built plants from PlantKit ("plant:bracken", ...), four variants each.
			for v in 3:
				var pm := PlantKit.mesh(String(id).substr(6), v)
				_parts.append([pm, Transform3D.IDENTITY, pm.get_aabb().size])
			continue
		if String(id).begins_with("kit:"):
			# Code-built stone from QuarryKit ("kit:rubble", "kit:slab", "kit:block_broken"), four variants each.
			for v in 4:
				var km := QuarryKit.mesh(String(id).substr(4), v)
				var kb := km.get_aabb()
				_parts.append([km, Transform3D(Basis(), -Vector3(kb.get_center().x, kb.position.y, kb.get_center().z)), kb.size])
			continue
		var ps := load("res://assets/nature/%s/%s.gltf" % [id, id]) as PackedScene
		if ps == null:
			push_warning("PlantScatter: missing model %s" % id)
			continue
		var root := ps.instantiate() as Node3D
		for m in root.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			if String(mi.name).contains("LOD") and not String(mi.name).ends_with("LOD0"):
				continue
			var rel := _rel(root, mi)
			var box: AABB = rel * mi.get_aabb()
			var centered := Transform3D(Basis(), -Vector3(box.get_center().x, box.position.y, box.get_center().z)) * rel
			_parts.append([mi.mesh, centered, box.size])
		root.free()


var _tint_cache := {}


func _tinted(mesh: Mesh) -> Material:
	if not _tint_cache.has(mesh):
		var m := mesh.surface_get_material(0)
		var d: Material = m.duplicate() if m else StandardMaterial3D.new()
		if d is BaseMaterial3D:
			(d as BaseMaterial3D).albedo_color = (d as BaseMaterial3D).albedo_color * tint
		_tint_cache[mesh] = d
	return _tint_cache[mesh]


func _rel(root: Node3D, n: Node3D) -> Transform3D:
	var t := n.transform
	var p := n.get_parent() as Node3D
	while p != null and p != root:
		t = p.transform * t
		p = p.get_parent() as Node3D
	return t
