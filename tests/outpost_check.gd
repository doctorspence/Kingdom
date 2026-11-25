extends Node
## Automated check of the White Knights Outpost assets (assets/outpost/):
## every baked asset loads with a mesh, a player-sized capsule can walk in through the cottage's
## door to its hearth while the walls still block it, and into the guard shelter.
##   ... --headless --script res://tests/run.gd -- outpost_check

const Catalog := preload("res://assets/outpost/catalog.gd")
const BLD := preload("res://assets/outpost/buildings/buildings.gd")

## Player capsule (game/player/player.tscn): radius 0.35 m, 1.8 m tall.
const RADIUS := 0.35
const HEIGHT := 1.8

var _bad := 0


func _ready() -> void:
	_run.call_deferred()


func _ck(label: String, ok: bool) -> void:
	print(("ok    " if ok else "FAIL  ") + label)
	if not ok:
		_bad += 1


func _run() -> void:
	# 1. Every catalogued asset is baked and loads.
	var missing := []
	for e in Catalog.entries():
		var path := "res://assets/outpost/%s/%s.scn" % [e[0], e[1]]
		var ps := load(path) as PackedScene
		var n := ps.instantiate() if ps else null
		if n == null or n.get_node_or_null("Mesh") == null:
			missing.append(e[1])
		if n:
			n.free()
	_ck("all %d outpost assets load with a mesh %s" % [Catalog.entries().size(), missing], missing.is_empty())
	# 2. Walk into every building (all built at the buildings' SIZE, k), along paths in drawn meters.
	var k: float = BLD.SIZE
	var walks := [
		["buildings/B07_small_cottage", "B07 cottage: in through the door to the hearth", [Vector2(-1.0, 4.5), Vector2(-1.0, 2.3), Vector2(-1.0, 0.0), Vector2(0.6, 0.0), Vector2(-2.0, 0.0)], [Vector3(1.5, 1.0, 2.25), Vector3(0, 1.0, -2.3)]],
		["buildings/B08_medium_cottage", "B08 cottage: in through the door, to the hearth and the far end", [Vector2(0.6, 4.9), Vector2(0.6, 2.7), Vector2(0.6, 0.0), Vector2(3.2, 0.0), Vector2(-3.6, 0.0)], [Vector3(-1.0, 1.0, 2.65), Vector3(0, 1.0, -2.7)]],
		["buildings/B09_storage_shed", "B09 shed: in through the door", [Vector2(0.0, 3.4), Vector2(0.0, 1.4), Vector2(0.0, 0.0)], [Vector3(1.2, 1.0, 1.4), Vector3(0, 1.0, -1.4)]],
		["buildings/B04_large_market_shelter", "B04 market shelter: walk through between the posts", [Vector2(-2.0, 5.0), Vector2(-2.0, -5.0), Vector2(2.0, -5.0), Vector2(2.0, 5.0)], [Vector3(0, 1.0, 2.6)]],
		["buildings/B01_roadside_inn", "B01 inn: in through the door, to the hearth and the bar", [Vector2(0.4, 5.4), Vector2(0.4, 3.2), Vector2(0.4, 0.0), Vector2(-3.8, 0.0), Vector2(2.8, 0.0)], [Vector3(2.0, 1.0, 3.2), Vector3(0, 1.0, -3.2)]],
		["buildings/B02_civilian_blacksmith_workshop", "B02 blacksmith: in at the open front, beside the forge", [Vector2(-1.5, 4.4), Vector2(-1.5, 0.0), Vector2(-0.6, -0.8)], [Vector3(0, 1.0, -2.2)]],
		["buildings/B03_stable_farrier_shelter", "B03 stable: into each of the three stalls", [Vector2(-3.2, 4.5), Vector2(-3.2, 0.0), Vector2(-3.2, 4.5), Vector2(0.0, 4.5), Vector2(0.0, 0.0), Vector2(0.0, 4.5), Vector2(3.2, 4.5), Vector2(3.2, 0.0)], [Vector3(0, 1.0, -2.5)]],
		["buildings/B06_carpenter_workshop", "B06 carpenter: in at the open front", [Vector2(1.5, 4.3), Vector2(1.5, 0.0)], [Vector3(0, 1.0, -2.3)]],
		["castle_approach/CP08_guard_inspection_shelter", "CP08 guard shelter: in at the open front", [Vector2(0, 2.6), Vector2(0, 0)], [Vector3(0, 1.0, -1.1)]],
	]
	for w in walks:
		var node := (load("res://assets/outpost/%s.scn" % w[0]) as PackedScene).instantiate() as Node3D
		add_child(node)
		for i in 3:
			await get_tree().physics_frame
		var path := []
		for p: Vector2 in w[2]:
			path.append(p * k)
		var blocked := _walk(path, k)
		_ck("%s (blocked at %s)" % [w[1], blocked.slice(0, 3)], blocked.is_empty())
		var walls_ok := true
		for q: Vector3 in w[3]:
			walls_ok = walls_ok and _hits(Vector3(q.x * k, q.y, q.z * k))
		_ck("%s: its walls or posts block the player" % w[0].get_file(), walls_ok)
		node.queue_free()
		await get_tree().physics_frame
	print(("PASS" if _bad == 0 else "FAIL") + ": %d problem(s)" % _bad)
	get_tree().quit(1 if _bad else 0)


func _hits(pos: Vector3) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = RADIUS
	shape.height = HEIGHT
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis(), pos)
	q.collision_mask = 1
	var space := get_viewport().world_3d.direct_space_state
	return not space.intersect_shape(q, 1).is_empty()


## Points every 10 cm along a path (x, z) where a standing player would hit something.
func _walk(path: Array, k: float) -> Array:
	var blocked := []
	for i in path.size() - 1:
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		var steps := int(a.distance_to(b) / 0.1) + 1
		for j in steps + 1:
			var p := a.lerp(b, float(j) / steps)
			if _hits(Vector3(p.x, 0.08 * k + HEIGHT * 0.5 + 0.02, p.y)):
				blocked.append(p)
	return blocked
