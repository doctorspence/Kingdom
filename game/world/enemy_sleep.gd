class_name EnemySleep
extends Node
## Lets far-off idle enemies sleep. An enemy standing idle with no player within
## sleep_range (twice the longest sight range) stops thinking and animating; it
## wakes the moment a player comes within range or anything changes its state
## (a hit, an ally's call, a raid). Saves several ms per frame with ~50 enemies
## in the zone. Enemies drawn beyond fade_range dither out (tiny and in the fog
## by then). Runs on the host / single player; friends' machines copy the host.

## No player within this (meters) and idle: the enemy sleeps. Longest sight range is 45 m.
@export var sleep_range := 90.0
## Enemy models fade out beyond this distance from the camera.
@export var fade_range := 130.0
## How often enemies are checked (seconds).
@export var interval := 0.25

var _timer := 0.0


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = interval
	var players: Array[Vector3] = []
	for n in get_tree().get_nodes_in_group(&"player"):
		players.append((n as Node3D).global_position)
	var host := not multiplayer.has_multiplayer_peer() or multiplayer.is_server()
	for n in get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Enemy
		if e == null:
			continue
		if not e.has_meta(&"sleep_fade"):
			_set_fade(e)
		var asleep: bool = e.get_meta(&"asleep", false)
		# Raiders walk to the camp while "idle", whoever is watching: never put them to sleep.
		var want := host and e.state == Enemy.State.IDLE and not players.is_empty() and not e.is_in_group(&"raiders")
		if want:
			for p in players:
				if p.distance_to(e.global_position) < sleep_range:
					want = false
					break
		if want and not asleep:
			e.process_mode = Node.PROCESS_MODE_DISABLED
			e.set_meta(&"asleep", true)
		elif not want and asleep:
			e.process_mode = Node.PROCESS_MODE_INHERIT
			e.set_meta(&"asleep", false)


## Every mesh of the enemy fades out beyond fade_range (set once per enemy).
func _set_fade(e: Node) -> void:
	e.set_meta(&"sleep_fade", true)
	for g in e.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if gi.visibility_range_end <= 0.0:
			gi.visibility_range_end = fade_range
			gi.visibility_range_end_margin = 10.0
			gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
