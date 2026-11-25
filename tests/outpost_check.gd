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
	# 2. Walk into the cottage (built at the buildings' SIZE).
	var k: float = BLD.SIZE
	var house := (load("res://assets/outpost/buildings/B07_small_cottage.scn") as PackedScene).instantiate() as Node3D
	add_child(house)
	for i in 3:
		await get_tree().physics_frame
	var door := Vector2(-1.0, 2.3) * k
	var blocked := _walk([Vector2(door.x, door.y + 2.2), Vector2(door.x, door.y), Vector2(door.x, 0.0), Vector2(0.6 * k, 0.0), Vector2(-2.0 * k, 0.0)], k)
	_ck("B07 cottage: a player walks in through the door to the hearth (blocked at %s)" % [blocked.slice(0, 3)], blocked.is_empty())
	_ck("B07 cottage: the walls block the player", _hits(Vector3(1.5 * k, 1.0, 2.3 * k - 0.05)) and _hits(Vector3(0, 1.0, -2.3 * k)))
	house.queue_free()
	# 3. Step into the guard shelter (also a building, also at SIZE).
	var hut := (load("res://assets/outpost/castle_approach/CP08_guard_inspection_shelter.scn") as PackedScene).instantiate() as Node3D
	add_child(hut)
	for i in 3:
		await get_tree().physics_frame
	blocked = _walk([Vector2(0, 2.6 * k), Vector2(0, 0)], k)
	_ck("CP08 guard shelter: a player walks in at the open front (blocked at %s)" % [blocked.slice(0, 3)], blocked.is_empty())
	_ck("CP08 guard shelter: its back wall blocks the player", _hits(Vector3(0, 1.0, -1.1 * k)))
	hut.queue_free()
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
