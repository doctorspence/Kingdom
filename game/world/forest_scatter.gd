@tool
class_name ForestScatter
extends Node3D
## Places trees, rocks or clutter by a density map from the zone's land script
## (land.forest / land.rocks / land.clutter), on an even, jittered grid: thick
## woods with thinning edges and real clearings instead of random sprinkling.
## Keeps off roads, tracks, the river, building pads and the land's
## keep_clear circles. Seeded, so every player sees the same woods.

@export var terrain: SculptedTerrain
@export var scenes: Array[PackedScene] = []
## Relative chance of each scene (same order as scenes); empty = equal.
@export var weights := PackedFloat32Array()
## Which density map from the land script: "forest", "rocks" or "clutter".
@export var layer := "forest"
## Grid spacing (meters): the closest two things can stand.
@export var spacing := 6.0
@export var scatter_seed := 1
@export var keep_off_roads := 6.0
@export var keep_off_tracks := 3.0
@export var keep_off_river := 2.0
@export var keep_off_pads := true
@export var scale_range := Vector2(0.8, 1.3)
## Extra density multiplier.
@export var density := 1.0
## Steepest ground allowed (rise per meter).
@export var max_slope := 0.9
## Also fill this far beyond the playable edge (for the horizon).
@export var beyond_edge := 0.0
## Sink into the ground (meters), so rocks and logs look bedded in.
@export var sink := 0.1
## Let leaves and needles cast shadows too (costs more; good for broadleaf trees).
@export var leaf_shadows := false
@export var rebuild := false:
	set(v):
		_scatter()

var placed := 0
var _trees: Array = []
var _kinds: PackedStringArray = []


func _ready() -> void:
	_scatter.call_deferred()


func _scatter() -> void:
	if terrain == null or scenes.is_empty() or not is_inside_tree():
		return
	if terrain.land == null:
		terrain.height_at(0, 0)  # make sure it is baked
	for c in get_children():
		c.queue_free()
	var land: Object = terrain.land
	if land == null or not land.has_method(layer):
		return
	var keep: PackedVector3Array = land.get("keep_clear") if land.get("keep_clear") != null else PackedVector3Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = scatter_seed
	var half := terrain.size * 0.5 + beyond_edge
	var total_w := 0.0
	for i in scenes.size():
		total_w += weights[i] if i < weights.size() else 1.0
	placed = 0
	# Generated trees are batched instead of placed one by one.
	_trees.clear()
	_kinds.clear()
	var as_trees := true
	for s in scenes:
		var probe := s.instantiate()
		if probe is GeneratedTree:
			_kinds.append((probe as GeneratedTree).kind)
		else:
			as_trees = false
		probe.free()
	var z := -half
	while z < half:
		var x := -half
		while x < half:
			var p := Vector2(x + rng.randf() * spacing, z + rng.randf() * spacing)
			var roll := rng.randf()
			var pick := rng.randf() * total_w
			var rot := rng.randf() * TAU
			var sc := rng.randf_range(scale_range.x, scale_range.y)
			x += spacing
			var dens: float = land.call(layer, p.x, p.y) * density
			if roll > dens:
				continue
			var inside := absf(p.x) < terrain.size * 0.5 and absf(p.y) < terrain.size * 0.5
			if inside:
				if terrain._distance_to_lines(terrain.roads, p) < keep_off_roads:
					continue
				if terrain._distance_to_lines(terrain.tracks, p) < keep_off_tracks:
					continue
				var rd := terrain.river_distance(p.x, p.y)
				if rd < keep_off_river + 6.0 and terrain.height_at(p.x, p.y) < terrain.water_level_at(p.x, p.y) + 0.3:
					continue
				if keep_off_pads and terrain.in_pad(p.x, p.y) > 0.05:
					continue
				if terrain.in_field(p.x, p.y) > 0.05:
					continue
			var blocked := false
			for c in keep:
				if Vector2(c.x, c.y).distance_to(p) < c.z:
					blocked = true
					break
			if blocked:
				continue
			var h := terrain.height_at(p.x, p.y)
			var slope := Vector2(terrain.height_at(p.x + 1.0, p.y) - h, terrain.height_at(p.x, p.y + 1.0) - h).length()
			if slope > max_slope:
				continue
			var k := 0
			var acc := weights[0] if weights.size() > 0 else 1.0
			while pick > acc and k < scenes.size() - 1:
				k += 1
				acc += weights[k] if k < weights.size() else 1.0
			if as_trees:
				_trees.append([_kinds[k], Vector3(p.x, h - sink, p.y), rot, sc])
			else:
				var node: Node3D = scenes[k].instantiate()
				add_child(node)
				node.position = Vector3(p.x, h - sink, p.y) - global_position
				node.rotation.y = rot
				node.scale = Vector3.ONE * sc
			placed += 1
		z += spacing
	if as_trees and not Engine.is_editor_hint():
		_build_trees()


## Trees drawn in batches: one MultiMesh per 64 m patch, tree shape and part,
## each hidden beyond GeneratedTree.SEEN_FROM; one body holds all trunk colliders.
func _build_trees() -> void:
	var patch := 64.0
	var groups := {}
	var body := StaticBody3D.new()
	body.name = "Trunks"
	add_child(body)
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 4.5
	for t in _trees:
		var kind: String = t[0]
		var pos: Vector3 = t[1]
		var index := int(absf(pos.x * 31.0 + pos.z * 17.0)) % GeneratedTree.VARIANTS
		var key := "%s|%d|%d|%d" % [kind, index, floori(pos.x / patch), floori(pos.z / patch)]
		if not groups.has(key):
			groups[key] = []
		var xf := Transform3D(Basis(Vector3.UP, t[2]).scaled(Vector3.ONE * float(t[3])), pos - global_position)
		groups[key].append(xf)
		if absf(pos.x) < terrain.size * 0.5 and absf(pos.z) < terrain.size * 0.5:
			var cs := CollisionShape3D.new()
			cs.shape = capsule
			cs.position = pos - global_position + Vector3.UP * 2.25
			body.add_child(cs)
	for key in groups:
		var bits: PackedStringArray = key.split("|")
		var parts: Array = GeneratedTree._variant(bits[0], int(bits[1]))
		var xfs: Array = groups[key]
		for pi in parts.size():
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = parts[pi]
			mm.instance_count = xfs.size()
			for i in xfs.size():
				mm.set_instance_transform(i, xfs[i])
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if (pi == 0 or leaf_shadows) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mmi.visibility_range_end = GeneratedTree.SEEN_FROM + patch * 0.7
			add_child(mmi)
