extends Node
## Multiplayer connection, player names and chat. Runs at start-up (autoload "Net").
##
## "Host-and-play": the host's game is the server. Playing alone is the same
## thing with nobody connected. Friends join by IP address on UDP port 31415.

signal names_changed
signal chat_received(sender: String, text: String, is_system: bool)
signal connection_failed(reason: String)

enum Mode { OFFLINE, HOST, JOIN }

const PORT := 31415
const MAX_PLAYERS := 10
const MENU_SCENE := "res://game/ui/main_menu.tscn"
const WORLD_SCENE := "res://levels/sandbox/combat_test.tscn"
const SETTINGS_PATH := "user://settings.cfg"

var mode := Mode.OFFLINE
var player_name := "Wanderer"
var join_address := "127.0.0.1"
## peer id -> display name, kept the same on every machine by the host.
var names := {}
## True while the chat box has the keyboard (the character ignores keys).
var typing := false


func _ready() -> void:
	_load_settings()
	_apply_command_line()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


# --- Starting and stopping ----------------------------------------------------

## Host a game (also used for playing alone).
func host_game() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_PLAYERS - 1)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	mode = Mode.HOST
	names = {1: player_name}
	_save_settings()
	get_tree().change_scene_to_file(WORLD_SCENE)
	return OK


## Join a friend's game. The world loads first, then we connect (see start_connection).
func join_game(address: String) -> void:
	join_address = address.strip_edges()
	mode = Mode.JOIN
	_save_settings()
	get_tree().change_scene_to_file(WORLD_SCENE)


## Called by the world once it has loaded, when joining.
func start_connection() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(join_address, PORT)
	if err != OK:
		_fail("Could not start connecting (%s)." % error_string(err))
		return
	multiplayer.multiplayer_peer = peer


## Leave the game and go back to the main menu.
func leave(reason := "") -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	mode = Mode.OFFLINE
	names = {}
	get_tree().change_scene_to_file(MENU_SCENE)
	if reason != "":
		connection_failed.emit.call_deferred(reason)


func is_online() -> bool:
	return mode != Mode.OFFLINE


func name_of(peer_id: int) -> String:
	return names.get(peer_id, "Player %d" % peer_id)


## Addresses of this computer that friends could use to join.
func local_addresses() -> PackedStringArray:
	var result := PackedStringArray()
	for a in IP.get_local_addresses():
		if a.contains(".") and not a.begins_with("127.") and not a.begins_with("169.254"):
			result.append(a)
	return result


# --- Chat ---------------------------------------------------------------------

func send_chat(text: String) -> void:
	text = text.strip_edges().left(200)
	if text == "":
		return
	_chat.rpc(text)


@rpc("any_peer", "call_local", "reliable")
func _chat(text: String) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender == 0:
		sender = multiplayer.get_unique_id()
	chat_received.emit(name_of(sender), text, false)


func system_message(text: String) -> void:
	chat_received.emit("", text, true)


# --- Names --------------------------------------------------------------------

func _on_connected() -> void:
	_register_name.rpc_id(1, player_name)


@rpc("any_peer", "call_remote", "reliable")
func _register_name(display_name: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	names[id] = display_name.strip_edges().left(20) if display_name.strip_edges() != "" else "Player %d" % id
	_sync_names.rpc(names)
	_announce.rpc("%s joined." % names[id])


@rpc("authority", "call_local", "reliable")
func _sync_names(all_names: Dictionary) -> void:
	names = all_names
	names_changed.emit()


@rpc("authority", "call_local", "reliable")
func _announce(text: String) -> void:
	system_message(text)


func _on_peer_connected(_id: int) -> void:
	pass  # the new player introduces themselves with _register_name


func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		var who := name_of(id)
		names.erase(id)
		_sync_names.rpc(names)
		_announce.rpc("%s left." % who)


func _on_connection_failed() -> void:
	_fail("Could not reach %s. Check the address, and that the host's port %d (UDP) is open." % [join_address, PORT])


func _on_server_disconnected() -> void:
	leave("The host closed the game or the connection dropped.")


func _fail(reason: String) -> void:
	leave(reason)


# --- Settings -----------------------------------------------------------------

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		player_name = cfg.get_value("player", "name", player_name)
		join_address = cfg.get_value("network", "last_address", join_address)


## Automated checks turn this off so they don't overwrite your name and address.
var save_settings_enabled := true


func _save_settings() -> void:
	if not save_settings_enabled:
		return
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("player", "name", player_name)
	cfg.set_value("network", "last_address", join_address)
	cfg.save(SETTINGS_PATH)


## Testing helpers: "--host" / "--join=ADDRESS" / "--name=NAME" after "--".
func _apply_command_line() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--name="):
			player_name = arg.trim_prefix("--name=")
