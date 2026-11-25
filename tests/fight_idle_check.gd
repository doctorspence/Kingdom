extends Node
## Automated check of the fighting animation pass (ENEMY_LIFE_PLAN.md stage 6):
## enemies waiting their turn taunt or raise a guard instead of only circling, Knights
## fight behind their shield and never taunt, badly hurt enemies hunch, slow down and
## step back, and everyone goes back to their old stance once the fight is over.
##   ... --headless --script res://tests/run.gd -- fight_idle_check

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
	await _go_to(Vector3(0, 0.05, 0))

	# Who is left out: bosses and archers keep their own look.
	var archer := await _add("bandit_archer", Vector3(40, 0, 40))
	var boss := await _add("harl", Vector3(-40, 0, 40))
	_check("archers keep their own look", not archer.fight.enabled)
	_check("bosses keep their own look", not boss.fight.enabled)
	for e: Enemy in [archer, boss]:
		e.remove_from_group(&"enemies")
		e.queue_free()

	# Four bandits on one player: two swing, two wait their turn.
	var gang: Array[Enemy] = []
	for i in 4:
		var a := TAU * i / 4.0
		gang.append(await _add("bandit_sword", Vector3(cos(a), 0, sin(a)) * 4.0))
	var base := gang[0].model.idle_anim
	for e in gang:
		e._aggro(player, false)
	var posed := {}
	var most_swinging := 0
	for i in 60 * 14:
		await get_tree().physics_frame
		player._iframe_timer = 1.0
		player.health = player.max_health()
		var swinging := 0
		for e in gang:
			if e.state == Enemy.State.ATTACK:
				swinging += 1
			if e.fight.is_posing():
				posed[e.model.current_anim()] = true
		most_swinging = maxi(most_swinging, swinging)
	_check("bandits waiting their turn taunt now and then (%s)" % ", ".join(posed.keys()),
			posed.has(EnemyFight.TAUNT_RAISE) or posed.has(EnemyFight.TAUNT_NO))
	_check("...still no more than two swing at once (%d)" % most_swinging, most_swinging <= Enemy.MAX_ATTACKERS)
	_check("a fighting bandit keeps its low stance", gang[0].fight.stance() == base)

	# Badly hurt (all four, so some are waiting their turn): hunched, slower, step back.
	for e in gang:
		e.health = e.max_health * 0.2
	var hurt := gang[3]
	var backed := false
	var hunched := false
	var slow := false
	for i in 60 * 12:
		await get_tree().physics_frame
		player._iframe_timer = 1.0
		player.health = player.max_health()
		for e in gang:
			if e.fight.is_stepping_back():
				backed = true
			if e.model.current_anim() == EnemyFight.STANCE_HURT:
				hunched = true
				slow = slow or absf(e.model.get_speed() - 0.7) < 0.01
	_check("a badly hurt bandit takes a hunched stance", hurt.fight.stance() == EnemyFight.STANCE_HURT and hunched)
	_check("...breathes slower and heavier (stance at 0.7 speed)", slow)
	_check("...and steps back now and then", backed)

	# Fight over: back to the old stance.
	await _go_to(Vector3(0, 0.05, 90))
	for e in gang:
		e.target = null
		e._set_state(Enemy.State.RETURN)
	await _seconds(1.0)
	_check("after the fight the stance is back to normal", gang[3].model.idle_anim == base)
	for e in gang:
		e.remove_from_group(&"enemies")
		e.queue_free()
	await _frames(3)

	# Knights: behind the shield, no taunts.
	await _go_to(Vector3(0, 0.05, 0))
	var knights: Array[Enemy] = []
	for i in 4:
		var a := TAU * i / 4.0
		knights.append(await _add("zealot", Vector3(cos(a), 0, sin(a)) * 4.0))
	for e in knights:
		e._aggro(player, false)
	var taunted := false
	var shield_stance := false
	var guard_pose := false
	for i in 60 * 12:
		await get_tree().physics_frame
		player._iframe_timer = 1.0
		player.health = player.max_health()
		for e in knights:
			var anim := e.model.current_anim()
			# (The horn call uses the same raised-sword animation; only count poses.)
			if e.fight.is_posing() and anim in [EnemyFight.TAUNT_RAISE, EnemyFight.TAUNT_NO]:
				taunted = true
			if e.state == Enemy.State.CHASE and anim == EnemyFight.STANCE_SHIELD:
				shield_stance = true
			if e.fight.is_posing():
				guard_pose = true
	_check("Knights stand behind their shield in a fight", knights[0].fight.stance() == EnemyFight.STANCE_SHIELD and shield_stance)
	_check("...hold a guard pose while waiting", guard_pose)
	_check("...and never taunt", not taunted)
	knights[1].health = knights[1].max_health * 0.2
	_check("a hurt Knight keeps its shield up (no hunch)", knights[1].fight.stance() == EnemyFight.STANCE_SHIELD)

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


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
