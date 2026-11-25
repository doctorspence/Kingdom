extends Node
## Automated check of enemy posts, stage 4 (ENEMY_LIFE_PLAN.md): calm enemies near
## camp props sit on log seats facing the fire or work at crates and carts, see a
## little less, and take longer to get up when alerted. Stages 1-3 are in enemy_check.
##   ... --headless --script res://tests/run.gd -- posts_check

var player: Player
var failures := 0
var _arena: Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_arena = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(_arena)
	await _frames(20)
	player = get_tree().get_first_node_in_group(&"player") as Player
	for e in get_tree().get_nodes_in_group(&"enemies"):
		e.remove_from_group(&"enemies")
		e.queue_free()
	await _go_to(Vector3(0, 0.05, 60))  # far out of sight

	# A small camp: a fire, a log seat beside it (facing it), a crate.
	var fire := _prop("res://levels/tithelands/props/campfire.tscn", Vector3(-20, 0, 0), 0.0)
	_prop("res://levels/tithelands/props/log_seat.tscn", Vector3(-20, 0, 2.2), 0.0)  # log along x, 2.2 m south of the fire
	_prop("res://levels/tithelands/props/crate.tscn", Vector3(-24, 0, -2), 0.0)
	await _frames(3)
	var a := await _add("bandit_sword", Vector3(-20.5, 0, 3.5))
	var b := await _add("bandit_sword", Vector3(-19.5, 0, 3.5))
	var c := await _add("bandit_sword", Vector3(-23, 0, -3))
	await _seconds(2.5)
	var crew: Array[Enemy] = [a, b, c]
	var sitting := crew.filter(func(e: Enemy) -> bool: return e.post.spot_kind == EnemyPost.Spot.SIT)
	var working := crew.filter(func(e: Enemy) -> bool: return e.post.spot_kind == EnemyPost.Spot.WORK)
	_check("calm enemies by the fire use the camp (%d sit, %d work)" % [sitting.size(), working.size()], sitting.size() >= 1 and sitting.size() + working.size() == 3)
	var s: Enemy = sitting[0] if not sitting.is_empty() else a
	_check("...a sitter is on the log", absf(s.global_position.z - 2.2) < 0.5 and absf(s.global_position.x + 20.0) < 1.0)
	_check("...sitting down (%s)" % s.model.current_anim(), String(s.model.current_anim()).begins_with("Sitting"))
	var to_fire := fire.global_position - s.global_position
	to_fire.y = 0.0
	_check("...facing the fire", rad_to_deg(s.model.forward().angle_to(to_fire)) < 30.0)
	_check("...seeing less while seated", s.sight_scale < 1.0)
	_check("...sword at the hip", s.model.is_sheathed())
	if not working.is_empty():
		var w: Enemy = working[0]
		_check("a worker plays a job (%s)" % w.model.current_anim(), w.model.current_anim() in [&"PickUp_Table", &"ual2/Chest_Open", &"Interact", &"Idle", &"ual2/Consume"])
	# Alert: a seated one takes longer than standing (0.35 s) to be ready.
	var seated_pos := s.global_position
	await _go_to(s.global_position + s.model.forward() * 9.0 + Vector3.UP * 0.05)
	var stood := false
	for i in 180:  # it notices you (or grows suspicious) within 3 s
		await get_tree().physics_frame
		if s.model.current_anim() == &"Sitting_Exit":
			stood = true
			break
	_check("a sitter that notices you stands up from the seat first", stood)
	_check("...not fighting yet while it gets up", not s.is_fighting())
	await _seconds(3.0)
	_check("...then fights", s.is_fighting())
	_check("...its body free again", s.collision_mask != 0 and not s.axis_lock_linear_y)
	# Home again: back on the seat.
	await _go_to(Vector3(0, 0.05, 80))
	for e: Enemy in crew:
		e.target = null
		e._set_state(Enemy.State.RETURN)
	await _seconds(14.0)
	_check("after a fight a sitter goes back to its seat", s.state == Enemy.State.IDLE and s.global_position.distance_to(seated_pos) < 0.6 \
			and String(s.model.current_anim()).begins_with("Sitting"))

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _prop(path: String, at: Vector3, yaw: float) -> Node3D:
	var n := (load(path) as PackedScene).instantiate() as Node3D
	n.position = at
	n.rotation.y = yaw
	_arena.add_child(n)
	return n


func _add(kind: String, at: Vector3) -> Enemy:
	var e := (load("res://game/enemies/%s.tscn" % kind) as PackedScene).instantiate() as Enemy
	e.position = at
	_arena.add_child(e, true)
	await _frames(1)
	return e


func _go_to(where: Vector3) -> void:
	player.global_position = where
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	await _frames(5)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("%s %s" % ["ok   " if ok else "FAIL ", label])
	if not ok:
		failures += 1
