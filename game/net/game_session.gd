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

## The world (time, weather, opened shortcuts, death piles) is saved this often, and when you leave.
const AUTOSAVE_INTERVAL := 300.0


func _ready() -> void:
	if Net.mode == Net.Mode.JOIN:
		Net.start_connection()
		return
	_load_world()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	var autosave := Timer.new()
	autosave.wait_time = AUTOSAVE_INTERVAL
	autosave.autostart = true
	autosave.timeout.connect(save_world)
	add_child(autosave)
	_spawn_player.call_deferred(1)


func _on_peer_connected(id: int) -> void:
	_net_world_name.rpc_id(id, Net.world_name)
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


# --- The world save (host) ------------------------------------------------------------

## Joiners learn which world this is (their explored map and shrines are kept per world).
@rpc("authority", "call_remote", "reliable")
func _net_world_name(world_name: String) -> void:
	Net.world_name = world_name


func _day_night() -> DayNight:
	return get_tree().get_first_node_in_group(&"day_night") as DayNight


## Start of play: bring back the saved world, or start a fresh one.
func _load_world() -> void:
	WorldState.reset()
	var data := SaveSystem.load_world(Net.world_name) if _saves_world() else {}
	apply_world(data)


func apply_world(data: Dictionary) -> void:
	WorldState.reset()
	for key in data.get("flags", {}):
		WorldState.flags[StringName(key)] = data.flags[key]
		WorldState.flag_changed.emit(StringName(key), data.flags[key])
	var dn := _day_night()
	if dn and data.has("time"):
		dn.load_dict(data.time)
	Loot.restore_piles.call_deferred(data.get("piles", []))


func world_data() -> Dictionary:
	var dn := _day_night()
	var flags := {}
	for key in WorldState.flags:
		flags[String(key)] = WorldState.flags[key]
	return {
		"name": Net.world_name,
		"flags": flags,
		"time": dn.to_dict() if dn else {},
		"piles": Loot.save_piles(),
	}


## Only real zones are saved (not the test arenas), and never by automated checks.
func _saves_world() -> bool:
	return Net.save_settings_enabled and get_tree().get_first_node_in_group(&"zone_terrain") != null


func save_world() -> void:
	if not multiplayer.is_server() or Net.mode == Net.Mode.JOIN or not _saves_world():
		return
	SaveSystem.save_world(world_data())


func _exit_tree() -> void:
	save_world()
	Loot.clear_piles()
