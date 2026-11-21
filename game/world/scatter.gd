@tool
class_name Scatter
extends Node3D
## Scatters copies of some scenes (trees, rocks) over an area, standing on the
## ground and keeping off roads and the river. Change the numbers in the
## Inspector; it re-scatters. The same seed always gives the same layout, so
## every player sees the same woods.

@export var terrain: ZoneTerrain
@export var scenes: Array[PackedScene] = []
## Area: x and z from, to (meters).
@export var area := Rect2(-50, -50, 100, 100)
@export var count := 60
@export var scatter_seed := 1
@export var min_spacing := 4.0
@export var keep_off_roads := 5.0
@export var keep_off_river := 8.0
@export var scale_range := Vector2(0.8, 1.3)
## Keep clear of these circles: (x, z, radius) each.
@export var avoid := PackedVector3Array()
## Skip spots below this height (pits) or above it (edges).
@export var height_limits := Vector2(-4.0, 14.0)
@export var rebuild := false:
	set(v):
		_scatter()

var _placed: Array[Vector2] = []


func _ready() -> void:
	_scatter.call_deferred()


func _scatter() -> void:
	if terrain == null or scenes.is_empty() or not is_inside_tree():
		return
	for c in get_children():
		c.queue_free()
	_placed.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = scatter_seed
	var tries := 0
	while _placed.size() < count and tries < count * 20:
		tries += 1
		var p := Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		if terrain._distance_to_lines(terrain.roads, p) < keep_off_roads:
			continue
		if terrain.river_distance(p.x, p.y) < keep_off_river:
			continue
		var h := terrain.height_at(p.x, p.y)
		if h < height_limits.x or h > height_limits.y:
			continue
		var blocked := false
		for c in avoid:
			if Vector2(c.x, c.y).distance_to(p) < c.z:
				blocked = true
		if blocked:
			continue
		var crowded := false
		for q in _placed:
			if q.distance_to(p) < min_spacing:
				crowded = true
				break
		if crowded:
			continue
		_placed.append(p)
		var node: Node3D = scenes[rng.randi() % scenes.size()].instantiate()
		add_child(node)
		node.global_position = Vector3(p.x, h - 0.1, p.y)
		node.rotation.y = rng.randf() * TAU
		node.scale = Vector3.ONE * rng.randf_range(scale_range.x, scale_range.y)
