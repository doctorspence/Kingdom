extends SceneTree
## Automated movement check. Loads the movement test map, presses buttons for
## the character, and measures speeds, roll distances, jump height, fall damage
## and lock-on against the numbers in DESIGN.md.
##
## Run (from the project folder):
##   Godot_console.exe --headless --path . --script res://tests/movement_check.gd

var player: Player
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: Node = load("res://levels/sandbox/movement_test.tscn").instantiate()
	root.add_child(scene)
	await _frames(20)
	player = get_first_node_in_group(&"player") as Player
	var t := player.tuning
	# Open ground, away from dummies and walls.
	player.global_position = Vector3(30, 0.05, 30)
	player.reset_physics_interpolation()
	await _frames(5)

	# Running speed
	Input.action_press("move_forward")
	await _seconds(1.5)
	_check("run speed", _speed(), t.run_speed, 0.15)
	# Sprinting speed and stamina drain
	Input.action_press("dodge_sprint")
	await _seconds(1.5)
	_check("sprint speed", _speed(), t.sprint_speed, 0.2)
	_check_true("sprint drains stamina", player.stamina < t.max_stamina - 10.0)
	Input.action_release("dodge_sprint")
	Input.action_release("move_forward")
	await _seconds(1.2)
	_check("stops when you let go", _speed(), 0.0, 0.05)
	await _seconds(2.5)
	_check("stamina refills", player.stamina, t.max_stamina, 0.5)

	# Quick direction changes: full reversal back to running speed
	Input.action_press("move_forward")
	await _seconds(1.0)
	Input.action_release("move_forward")
	Input.action_press("move_back")
	var reverse_time := 0.0
	while reverse_time < 2.0:
		await physics_frame
		reverse_time += 1.0 / Engine.physics_ticks_per_second
		if player.velocity.z > t.run_speed * 0.9:
			break
	_check("seconds to reverse direction at full run", reverse_time, 0.15, 0.15)
	# Roll while running: come out still running
	await _tap("dodge_sprint")
	await _seconds(t.roll_duration[0] + 0.05)
	_check("speed right after a roll (holding a direction)", _speed(), t.run_speed, 0.3)
	Input.action_release("move_back")
	await _seconds(2.5)

	# Rolls at each equip load
	for case in [[0.2, 0], [0.5, 1], [0.9, 2]]:
		player.equip_load = case[0]
		await _seconds(0.8)
		var start := player.global_position
		await _tap("dodge_sprint")
		await _frames(2)
		_check_true("invincible during roll (load %.1f)" % case[0], player.is_invulnerable())
		await _seconds(t.roll_duration[case[1]] + 0.05)
		var dist := _flat(player.global_position - start).length()
		_check("roll distance at load %.1f" % case[0], dist, t.roll_distance[case[1]], 0.35)
		_check_true("roll costs stamina", player.stamina < t.max_stamina)
		await _seconds(1.5)
	player.equip_load = 1.2
	var before := player.global_position
	await _tap("dodge_sprint")
	await _seconds(0.6)
	_check("no roll when overloaded", _flat(player.global_position - before).length(), 0.0, 0.05)
	player.equip_load = 0.2
	await _seconds(1.0)

	# Jump height
	var ground_y := player.global_position.y
	var peak := ground_y
	await _tap("jump")
	for i in 60:
		await physics_frame
		peak = maxf(peak, player.global_position.y)
	_check("jump height", peak - ground_y, t.jump_height, 0.12)
	await _seconds(1.0)

	# Fall damage from various heights (dropped onto open ground)
	for case in [[4.0, false, false], [6.0, true, false], [10.0, true, false], [16.0, true, true]]:
		player.respawn()
		await _frames(5)
		player.global_position = Vector3(25, case[0], -25)
		player.reset_physics_interpolation()
		var hp := player.health
		await _seconds(2.2)
		var took := player.health < hp
		var dead := player.state == Player.State.DEAD
		_check_true("fall %d m: damage=%s dead=%s (got damage=%s dead=%s, hp %d)" % [case[0], case[1], case[2], took, dead, player.health],
				took == case[1] and dead == case[2])
	player.respawn()
	await _seconds(0.5)

	# Lock-on: facing the dummies from the start position
	var locked := player.targeting.toggle()
	_check_true("lock-on finds a dummy (%s)" % (player.targeting.target.name if locked else "none"), locked and player.targeting.has_target())
	var first := player.targeting.target
	player.targeting.switch_target(1)
	_check_true("switch target changes it (%s)" % player.targeting.target.name, player.targeting.target != first)
	player.targeting.toggle()
	_check_true("lock-on toggles off", not player.targeting.has_target())

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)


func _speed() -> float:
	return Vector2(player.velocity.x, player.velocity.z).length()


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


func _tap(action: StringName) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	await physics_frame
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _seconds(s: float) -> void:
	await _frames(ceili(s * Engine.physics_ticks_per_second))


func _check(label: String, got: float, want: float, tolerance: float) -> void:
	var ok := absf(got - want) <= tolerance
	print("%s  %s: %.2f (want %.2f ± %.2f)" % ["ok  " if ok else "FAIL", label, got, want, tolerance])
	if not ok:
		failures += 1


func _check_true(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", label])
	if not ok:
		failures += 1
