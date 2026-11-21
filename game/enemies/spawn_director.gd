class_name SpawnDirector
extends Node
## Host only: fills the zone's spawn points with enemies, and rerolls them when
## anyone rests — except points where a fight is going on or a player is close.
## Enemies go under `enemies_root`, which a MultiplayerSpawner shares with
## everyone.

@export var enemies_root: Node3D
@export var terrain: ZoneTerrain
## Don't reroll points with a player closer than this (meters).
@export var safe_distance := 30.0

var _rng := RandomNumberGenerator.new()
var _counter := 0


func _ready() -> void:
	add_to_group(&"spawn_directors")
	_rng.randomize()
	if multiplayer.is_server():
		populate.call_deferred(true)


## (Re)fill spawn points. `everything` ignores the "fight / nearby" exceptions.
func populate(everything := false) -> void:
	if not multiplayer.is_server():
		return
	var players := get_tree().get_nodes_in_group(&"player")
	for n in get_tree().get_nodes_in_group(&"spawn_points"):
		var sp := n as SpawnPoint
		if sp == null or sp.table == null:
			continue
		var alive: Array[Node] = []
		for e in sp.spawned:
			if is_instance_valid(e) and not e.is_queued_for_deletion():
				alive.append(e)
		sp.spawned = alive
		if not everything and not _can_reset(sp, players):
			continue
		for e in sp.spawned:
			e.queue_free()
		sp.spawned.clear()
		if players.size() < sp.min_players and not everything:
			continue
		if sp.min_players > maxi(players.size(), 1):
			continue
		var scene: PackedScene = null
		var count := 0
		if sp.named_scene and _rng.randf() < sp.named_chance:
			scene = sp.named_scene
			count = 1
		else:
			var r := sp.table.roll(_rng)
			scene = r[0]
			count = r[1]
		if scene == null:
			continue
		for i in count:
			_spawn(sp, scene, i, count)


func _can_reset(sp: SpawnPoint, players: Array) -> bool:
	for e in sp.spawned:
		if is_instance_valid(e) and (e as Enemy).is_fighting():
			return false
	for p in players:
		if (p as Node3D).global_position.distance_to(sp.global_position) < safe_distance:
			return false
	return true


func _spawn(sp: SpawnPoint, scene: PackedScene, index: int, count: int) -> void:
	var e := scene.instantiate() as Enemy
	_counter += 1
	e.name = "%s_%d" % [sp.name, _counter]
	var a := TAU * index / maxf(count, 1)
	var off := Vector3(cos(a), 0, sin(a)) * (sp.radius if count > 1 else 0.0)
	var p := sp.global_position + off
	if terrain:
		p.y = terrain.height_at(p.x, p.z) + 0.05
	e.position = p
	e.rotation = sp.global_rotation
	if not sp.patrol.is_empty():
		var route := PackedVector3Array()
		for q in sp.patrol:
			route.append(sp.global_transform * q)
		e.patrol_points = route
	e.remove_from_group(&"respawn_on_rest")
	enemies_root.add_child(e, true)
	e.remove_from_group(&"respawn_on_rest")  # the director handles these
	e.set_party_size(maxi(get_tree().get_nodes_in_group(&"player").size(), 1))
	sp.spawned.append(e)


## Someone rested: bring the zone back to life.
func on_rest() -> void:
	populate(false)
