extends Node
## Automated check of ENEMY_LIFE_PLAN.md stage 7: a calm enemy that sets off draws
## its sword from the hip (the hand reaches, the sword is in hand about halfway);
## at night a camp lies down by the fire with one left awake as the night watch,
## the sleepers see little and take about 2 s to get up, and they rise in the morning.
##   ... --headless --script res://tests/run.gd -- draw_rest_check

var player: Player
var failures := 0
var _arena: Node
var _night := 0.0


func _ready() -> void:
	_run.call_deferred()


func _physics_process(_delta: float) -> void:
	DayNight.night = _night  # the test owns the clock


func _run() -> void:
	_arena = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(_arena)
	await _frames(20)
	player = get_tree().get_first_node_in_group(&"player") as Player
	for e in get_tree().get_nodes_in_group(&"enemies"):
		e.remove_from_group(&"enemies")
		e.queue_free()
	await _go_to(Vector3(0, 0.05, 80))

	# --- The draw ---
	var b := await _add("bandit_sword", Vector3(30, 0, 0))
	await _seconds(1.0)
	_check("a calm bandit has its sword on the hip", b.model.is_sheathed())
	await _go_to(Vector3(30, 0.05, 10))
	b._aggro(player, false)
	var drawing := false
	var sheathed_while_drawing := false
	for i in 20:
		await get_tree().physics_frame
		if b.model.is_drawing():
			drawing = true
			sheathed_while_drawing = sheathed_while_drawing or b.model.is_sheathed()
	_check("setting off, it draws from the hip (a reach, sword still at the hip at first)", drawing and sheathed_while_drawing)
	await _seconds(0.6)
	_check("...sword in hand once the draw is done", not b.model.is_sheathed() and not b.model.is_drawing())
	b.remove_from_group(&"enemies")
	b.queue_free()
	await _go_to(Vector3(0, 0.05, 80))

	# --- Night rest ---
	_prop("res://levels/tithelands/props/campfire.tscn", Vector3(-20, 0, 0))
	_prop("res://levels/tithelands/props/log_seat.tscn", Vector3(-20, 0, 2.2))
	_prop("res://levels/tithelands/props/crate.tscn", Vector3(-24, 0, -2))
	await _frames(3)
	var crew: Array[Enemy] = [
		await _add("bandit_sword", Vector3(-20.5, 0, 3.5)),
		await _add("bandit_sword", Vector3(-19.5, 0, 3.5)),
		await _add("bandit_sword", Vector3(-23, 0, -3)),
	]
	await _seconds(2.0)
	_check("by day nobody rests", crew.all(func(e: Enemy) -> bool: return not e.post.resting))
	_night = 1.0
	await _seconds(4.0)
	var asleep := crew.filter(func(e: Enemy) -> bool: return e.post.resting)
	_check("at night the camp lies down (%d of 3)" % asleep.size(), asleep.size() == 2)
	var keeper: Enemy = crew.filter(func(e: Enemy) -> bool: return not e.post.resting)[0] if asleep.size() < 3 else null
	_check("...one stays up as the night watch", keeper != null)
	var s: Enemy = asleep[0] if not asleep.is_empty() else crew[0]
	_check("...lying on the ground (%s)" % s.model.current_anim(), s.model.current_anim() == EnemyPost.LIE and absf(s.model.get_speed()) < 0.01)
	_check("...seeing very little", s.sight_scale < 0.5)
	_check("...close to the fire", s.global_position.distance_to(Vector3(-20, 0, 0)) < EnemyPost.REST_RANGE)

	# The watch spots you; the sleepers take a while to get up.
	if keeper:
		await _go_to(keeper.global_position + keeper.model.forward() * 8.0 + Vector3.UP * 0.05)
	var up_seen := false
	for i in 60 * 4:
		await get_tree().physics_frame
		if s.post.is_getting_up():
			up_seen = true
			break
	_check("woken by the watch, a sleeper gets up off the ground", up_seen and not s.post.resting)
	_check("...not fighting yet while it gets up", not s.is_fighting())
	await _seconds(4.0)
	_check("...then fights", s.is_fighting())

	# Fight over, still night: back to sleep. Then morning: up again.
	await _go_to(Vector3(0, 0.05, 80))
	for e in crew:
		e.target = null
		e._set_state(Enemy.State.RETURN)
	await _seconds(16.0)
	var back := crew.filter(func(e: Enemy) -> bool: return e.post.resting).size()
	_check("after the fight, still night, they lie down again (%d)" % back, back == 2)
	_night = 0.0
	await _seconds(4.0)
	_check("in the morning everyone is up", crew.all(func(e: Enemy) -> bool: return not e.post.resting))
	_check("...and back at the camp (%s)" % s.model.current_anim(), s.model.current_anim() != EnemyPost.LIE and s.sight_scale >= 0.7)

	# A watch post at night: torch up; called to fight, it drops it (still burning).
	_night = 1.0
	await _go_to(Vector3(0, 0.05, 80))
	var look := (load("res://game/enemies/bandit_lookout.tscn") as PackedScene).instantiate() as Enemy
	look.set_meta(&"post_kind", "watch")
	look.position = Vector3(40, 0, 0)
	_arena.add_child(look, true)
	await _seconds(2.0)
	var torch := look.post._torch
	_check("a lookout at night holds up a torch", look.model.current_anim() == EnemyPost.TORCH_ANIM and torch != null and is_instance_valid(torch))
	await _go_to(look.global_position + look.model.forward() * 9.0 + Vector3.UP * 0.05)
	look._aggro(player, false)
	await _seconds(0.6)
	_check("...called to fight, it drops the torch, which burns on the ground", is_instance_valid(torch) and torch.is_dropped() and torch.global_position.y < 0.3)
	look.remove_from_group(&"enemies")
	look.queue_free()
	_night = 0.0

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _prop(path: String, at: Vector3) -> void:
	var n := (load(path) as PackedScene).instantiate() as Node3D
	n.position = at
	_arena.add_child(n)


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
