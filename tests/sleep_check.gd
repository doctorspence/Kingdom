extends Node
## Automated check of sleeping enemies (EnemySleep) in the Tithelands: far-off idle
## enemies sleep, wake as a player comes near and then notice the player; a hit
## wakes a sleeping enemy at once (well, within a quarter second); raiders never sleep.
##   ... --headless --script res://tests/run.gd -- sleep_check

var player: Player
var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	WorldState.reset()
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _seconds(2.0)
	player = get_tree().get_first_node_in_group(&"player") as Player
	var sleeper := scene.get_node("EnemySleep") as EnemySleep
	var enemies: Array = get_tree().get_nodes_in_group(&"enemies")
	var asleep := enemies.filter(func(e: Node) -> bool: return e.get_meta(&"asleep", false))
	print("enemies %d, asleep %d" % [enemies.size(), asleep.size()])
	_check("far-off idle enemies are asleep", asleep.size() >= enemies.size() / 2)
	var near_awake := true
	for e: Enemy in enemies:
		if e.global_position.distance_to(player.global_position) < sleeper.sleep_range and e.get_meta(&"asleep", false):
			near_awake = false
	_check("no enemy within sleep range is asleep", near_awake)

	# Walk up to a sleeping one (teleport to 70 m, then 8 m in front of it): it wakes and notices.
	var e: Enemy = null
	for x: Enemy in asleep:
		if x.data and not x.data.boss and x.data.ambush_range <= 0.0 and x.global_position.y > -5.0:
			e = x
			break
	_check("found a sleeping ordinary enemy", e != null)
	if e:
		var fwd := e.model.forward()
		fwd.y = 0.0
		fwd = fwd.normalized()
		player.global_position = e.global_position + fwd * 70.0 + Vector3.UP * 2.0
		player.velocity = Vector3.ZERO
		await _seconds(0.6)
		_check("it wakes when a player is 70 m away", not e.get_meta(&"asleep", false) and e.process_mode != Node.PROCESS_MODE_DISABLED)
		player.global_position = e.global_position + fwd * 8.0 + Vector3.UP * 1.0
		player.velocity = Vector3.ZERO
		await _seconds(2.5)
		_check("it notices the player in front of it (state %d)" % e.state, e.state != Enemy.State.IDLE)

	# A sleeping enemy hit from afar (its state changed from outside) wakes up.
	player.global_position = Vector3(0, 40, 0)
	await _seconds(1.0)
	var f: Enemy = null
	for x: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if x.get_meta(&"asleep", false) and x.data and not x.data.boss:
			f = x
			break
	if f:
		f.target = player
		f._set_state(Enemy.State.CHASE)
		await _seconds(0.5)
		_check("a sleeping enemy pulled into a fight wakes", f.process_mode != Node.PROCESS_MODE_DISABLED)

	# Raiders are never put to sleep.
	var raider := scene.get_node("Enemies").get_child(0) as Enemy
	if raider:
		raider.add_to_group(&"raiders")
		raider._set_state(Enemy.State.IDLE)
		player.global_position = raider.global_position + Vector3(150, 40, 0)
		await _seconds(1.0)
		_check("raiders never sleep", not raider.get_meta(&"asleep", false))
	print("SLEEP CHECK %s (%d failures)" % ["PASSED" if failures == 0 else "FAILED", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await _frames(ceili(s * Engine.physics_ticks_per_second))


func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", label])
	if not ok:
		failures += 1
