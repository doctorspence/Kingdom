class_name Shrine
extends Node3D
## A shrine: rest here to heal, refill flasks and set your respawn point.
## Resting also brings dead enemies back (except ones fighting someone).
## You can't rest while an enemy is fighting you nearby.

signal rested(player: Node3D)

const UNSAFE_RANGE := 15.0

@export var shrine_name := "Wayside Shrine"
## Permanent ID (saves remember which shrines you found). Never change it.
@export var shrine_id := &"shrine"

@onready var _light: OmniLight3D = $FlameLight
@onready var _spawn: Marker3D = $SpawnPoint

var _base_energy := 3.5


func _ready() -> void:
	add_to_group(&"interactables")
	_base_energy = _light.light_energy


func get_interact_text() -> String:
	return "Use the %s (rest, bank)" % shrine_name


func interact(player: Node3D) -> void:
	player.call(&"open_menu", &"shrine", self)


## Rest here: heal, refill flasks, save, bring back enemies, restock merchants.
## Returns "" or why you can't rest.
func rest(player: Node3D) -> String:
	for n in get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Enemy
		if e and e.is_fighting() and e.global_position.distance_to(global_position) < UNSAFE_RANGE:
			CombatFx.word(global_position + Vector3.UP * 2.6, "Can't rest: enemies nearby")
			return "Can't rest: enemies nearby"
	player.call(&"rest_at", _spawn.global_transform)
	if multiplayer.is_server():
		_respawn_enemies()
	else:
		_net_rest.rpc_id(1)
	get_tree().call_group(&"vendors", &"restock")
	CombatFx.word(global_position + Vector3.UP * 2.6, "Rested")
	rested.emit(player)
	var tween := create_tween()
	tween.tween_property(_light, "light_energy", _base_energy * 3.0, 0.15)
	tween.tween_property(_light, "light_energy", _base_energy, 0.8)
	return ""


@rpc("any_peer", "call_remote", "reliable")
func _net_rest() -> void:
	if multiplayer.is_server():
		_respawn_enemies()


## Host only: bring back enemies that aren't busy fighting someone.
func _respawn_enemies() -> void:
	for n in get_tree().get_nodes_in_group(&"respawn_on_rest"):
		if n is Enemy and (n as Enemy).is_fighting():
			continue
		n.call(&"reset_from_rest")


func _process(_delta: float) -> void:
	# Gentle flicker.
	var t := Time.get_ticks_msec() * 0.001
	_light.light_energy = lerpf(_light.light_energy, _base_energy * (0.9 + 0.1 * sin(t * 7.0) * sin(t * 3.1)), 0.1)
