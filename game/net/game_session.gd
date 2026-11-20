class_name GameSession
extends Node
## Lives in each playable world. Creates a character for every player who
## joins (on the host), removes it when they leave, and tells the enemies how
## big the party is so they can scale.
##
## Playing alone (or running a map straight from the editor) counts as hosting
## with nobody connected.

const PLAYER_SCENE := preload("res://game/player/player.tscn")

## Where players appear. Children of this node (Marker3D) are used in turn.
@export var spawn_points: Node3D
@export var players_root: Node3D


func _ready() -> void:
	if Net.mode == Net.Mode.JOIN:
		Net.start_connection()
		return
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_spawn_player.call_deferred(1)


func _on_peer_connected(id: int) -> void:
	_spawn_player(id)


func _on_peer_disconnected(id: int) -> void:
	var p := players_root.get_node_or_null(str(id))
	if p:
		p.queue_free()
	_update_party_size.call_deferred()


func _spawn_player(id: int) -> void:
	if players_root.has_node(str(id)):
		return
	var p := PLAYER_SCENE.instantiate()
	p.name = str(id)  # the name is the owner's network id; see Player._enter_tree
	var points := spawn_points.get_children() if spawn_points else []
	var index := players_root.get_child_count()
	var where: Node3D = points[index % points.size()] if not points.is_empty() else null
	if where:
		# Sent to the new player's machine along with the character.
		p.set(&"net_pos", where.global_position)
		p.set(&"spawn_yaw", where.global_rotation.y)
	players_root.add_child(p, true)
	_update_party_size.call_deferred()


func _update_party_size() -> void:
	var count := 0
	for c in players_root.get_children():
		if not c.is_queued_for_deletion():
			count += 1
	get_tree().call_group(&"enemies", &"set_party_size", maxi(count, 1))
