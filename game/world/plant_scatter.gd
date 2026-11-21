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
@export var collide := false
@export var shadows := true
@export var seen_from := 90.0
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
	var keep: PackedVector3Array = land.get("keep_clear") if land.get("keep_clear") != null else PackedVector3Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = scatter_seed
	var half := terrain.size * 0.5 - 2.0
	var patch := 48.0
	var groups := {}
	var body: StaticBody3D = null
	if collide:
		body = StaticBody3D.new()
		body.name = "Colliders"
		add_child(body)
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
			if roll > float(land.call(layer, p.x, p.y)) * density:
				continue
			if terrain._distance_to_lines(terrain.roads, p) < keep_off_roads:
				continue
			if terrain._distance_to_lines(terrain.tracks, p) < keep_off_tracks:
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
				if slope < cliff:
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
			var key := "%d|%d|%d" % [pick, floori(p.x / patch), floori(p.y / patch)]
			if not groups.has(key):
				groups[key] = []
			groups[key].append(Transform3D(xf.basis, xf.origin - global_position))
			if body:
				var sz2: Vector3 = part[2] * s
				var shape := BoxShape3D.new()
				shape.size = Vector3(sz2.x * 0.8, sz2.y * 0.85, sz2.z * 0.8)
				var cs := CollisionShape3D.new()
				cs.shape = shape
				cs.position = Vector3(p.x, base + sz2.y * 0.4, p.y) - global_position
				cs.rotation.y = rot
				body.add_child(cs)
			placed += 1
		z += spacing
	for key in groups:
		var pick := int((key as String).split("|")[0])
		var xfs: Array = groups[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _parts[pick][0]
		mm.instance_count = xfs.size()
		for i in xfs.size():
			mm.set_instance_transform(i, xfs[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		if tint != Color(1, 1, 1):
			mmi.material_override = _tinted(_parts[pick][0])
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = seen_from
		mmi.visibility_range_end_margin = 10.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		add_child(mmi)


## Every mesh part of every model, moved so its base center sits at the origin.
func _load_parts() -> void:
	_parts.clear()
	for id in models:
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
