class_name Shrine
extends Node3D
## A shrine: rest here to heal, refill flasks and set your respawn point.
## Resting also brings dead enemies back.

signal rested(player: Node3D)

@export var shrine_name := "Wayside Shrine"

@onready var _light: OmniLight3D = $FlameLight
@onready var _spawn: Marker3D = $SpawnPoint

var _base_energy := 3.5


func _ready() -> void:
	add_to_group(&"interactables")
	_base_energy = _light.light_energy


func get_interact_text() -> String:
	return "Rest at the %s" % shrine_name


func interact(player: Node3D) -> void:
	player.call(&"rest_at", _spawn.global_transform)
	get_tree().call_group(&"respawn_on_rest", &"reset_from_rest")
	CombatFx.word(global_position + Vector3.UP * 2.6, "Rested")
	rested.emit(player)
	var tween := create_tween()
	tween.tween_property(_light, "light_energy", _base_energy * 3.0, 0.15)
	tween.tween_property(_light, "light_energy", _base_energy, 0.8)


func _process(_delta: float) -> void:
	# Gentle flicker.
	var t := Time.get_ticks_msec() * 0.001
	if not get_tree().paused:
		_light.light_energy = lerpf(_light.light_energy, _base_energy * (0.9 + 0.1 * sin(t * 7.0) * sin(t * 3.1)), 0.1)
