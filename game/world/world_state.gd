extends Node
## Facts about the world that everyone shares and the host saves (autoload
## "WorldState"): opened shortcuts, first boss kills, and later time of day and
## weather. The host decides; everyone else gets told.

signal flag_changed(key: StringName, value: Variant)

var flags := {}


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)


func get_flag(key: StringName, default: Variant = false) -> Variant:
	return flags.get(key, default)


## Set a flag (the host's word is final; others ask the host).
func set_flag(key: StringName, value: Variant) -> void:
	if multiplayer.is_server():
		_apply.rpc(key, value)
	else:
		_request.rpc_id(1, key, value)


@rpc("any_peer", "call_remote", "reliable")
func _request(key: StringName, value: Variant) -> void:
	if multiplayer.is_server():
		_apply.rpc(key, value)


@rpc("authority", "call_local", "reliable")
func _apply(key: StringName, value: Variant) -> void:
	flags[key] = value
	flag_changed.emit(key, value)


## A friend joined: tell them everything.
func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		_sync_all.rpc_id(id, flags)


@rpc("authority", "call_remote", "reliable")
func _sync_all(all: Dictionary) -> void:
	flags = all
	for k in flags:
		flag_changed.emit(k, flags[k])


func reset() -> void:
	flags.clear()
