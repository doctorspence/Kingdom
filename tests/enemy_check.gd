extends Node
## Automated check of the Tithelands enemies (DESIGN.md 8.1): senses, the
## Zealot's horn call, hound packs, the 2-attacker limit, martyr's fury,
## night sight and named rares.
##   ... --headless --script res://tests/run.gd -- enemy_check

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
	_clear()
	await _go_to(Vector3(0, 0.05, 0))

	# --- Senses: sees in front, not behind; hears up close --------------------------
	var z := await _add("zealot", Vector3(0, 0, -10), 180.0)  # faces the player
	await _seconds(0.5)
	_check("a Zealot sees you in front of it", z.state != Enemy.State.IDLE)
	_clear()
	z = await _add("zealot", Vector3(0, 0, -10), 0.0)  # back turned
	await _seconds(1.0)
	_check("...but not from behind", z.state == Enemy.State.IDLE)
	await _go_to(Vector3(0, 0.05, -6))  # 4 m behind it
	await _seconds(0.5)
	_check("...and hears you up close", z.state != Enemy.State.IDLE)

	# --- Horn call --------------------------------------------------------------------------
	_clear()
	await _go_to(Vector3(0, 0.05, 0))
	var caller := await _add("zealot", Vector3(0, 0, -10), 180.0)
	var friend := await _add("zealot", Vector3(10, 0, -10), 0.0)  # looking away
	var hound := await _add("hound", Vector3(-11, 0, -10), 0.0)  # not its kind
	await _seconds(0.4)
	_check("the Zealot stops to blow its horn", caller.state == Enemy.State.CALL)
	await _seconds(1.6)
	_check("the horn brings the other Zealot", friend.state == Enemy.State.CHASE and friend.target == player)
	_check("...but not a hound", hound.state == Enemy.State.IDLE)

	# --- Hound pack + attacker limit -----------------------------------------------------
	_clear()
	await _go_to(Vector3(0, 0.05, 0))
	var pack: Array[Enemy] = []
	for i in 4:
		pack.append(await _add("hound", Vector3(-3 + i * 2, 0, -10), 180.0))
	var most := 0
	for i in 240:
		player.health = player.max_health()
		var n := pack.filter(func(e: Enemy) -> bool: return e.state == Enemy.State.ATTACK).size()
		most = maxi(most, n)
		await get_tree().physics_frame
	_check("the hound pack hunts you together", pack.all(func(e: Enemy) -> bool: return e.state != Enemy.State.IDLE))
	_check("no more than 2 attack you at once (most: %d)" % most, most >= 1 and most <= 2)

	# --- Martyr's fury -------------------------------------------------------------------
	_clear()
	var a := await _add("zealot", Vector3(8, 0, 8), 0.0)
	var b := await _add("zealot", Vector3(10, 0, 8), 0.0)
	_kill(a)
	await _frames(5)
	_check("a White Knight flies into a fury when its ally dies", b.get(&"_fury") == true)

	# --- Night halves sight --------------------------------------------------------------
	_clear()
	await _go_to(Vector3(0, 0.05, 0))
	Enemy.sight_mult = 0.5
	z = await _add("zealot", Vector3(0, 0, -13), 180.0)
	await _seconds(0.5)
	_check("at night they don't see as far", z.state == Enemy.State.IDLE)
	Enemy.sight_mult = 1.0
	await _seconds(0.3)
	_check("...but do in daylight", z.state != Enemy.State.IDLE)

	# --- Hobb ------------------------------------------------------------------------------
	_clear()
	var hobb := await _add("hobb", Vector3(5, 0, 5), 0.0)
	_check("Hobb is named, tough, and has his own loot", hobb.data.named and hobb.max_health >= 400.0 and hobb.data.loot_table.always.size() == 1)

	# --- Posts: calm before the fight (ENEMY_LIFE_PLAN.md stage 1) --------------------
	_clear()
	await _go_to(Vector3(0, 0.05, 30))  # far out of sight
	var b1 := await _add("bandit_sword", Vector3(-1, 0, -10), 0.0)
	var b2 := await _add("bandit_sword", Vector3(1, 0, -10), 0.0)
	await _seconds(0.6)
	_check("two bandits on a post turn to face each other", _faces(b1, b2) and _faces(b2, b1))
	_check("...with their swords at the hip", b1.model.is_sheathed() and b2.model.is_sheathed())
	_check("...not in fighting stance", b1.model.current_anim() != &"Sword_Idle" and b2.model.current_anim() != &"Sword_Idle")
	# Walk into one's view only: both join, a moment apart.
	await _go_to(Vector3(-9, 0.05, -10))  # 8 m behind b1 (out of earshot), 10 m in front of b2
	await _seconds(0.15)
	var spotted := b2.target == player
	_check("the one facing you notices you", spotted)
	_check("...and takes a moment to get ready (no instant charge)", b2.state == Enemy.State.IDLE)
	_check("...and warns its friend", b1.target == player)
	await _seconds(1.2)
	_check("both fight together", b1.state != Enemy.State.IDLE and b2.state != Enemy.State.IDLE)
	_check("...with swords drawn", not b1.model.is_sheathed() and not b2.model.is_sheathed())
	# Home again: back on the post, facing the friend, sword away.
	await _go_to(Vector3(0, 0.05, 60))
	for e: Enemy in [b1, b2]:
		e.target = null
		e._set_state(Enemy.State.RETURN)
	await _seconds(3.0)
	_check("after the fight they go back to their post", b1.state == Enemy.State.IDLE and b1.model.is_sheathed() and _faces(b1, b2))
	# A blow on a calm enemy: it fights at once.
	_clear()
	await _go_to(Vector3(0, 0.05, 0))
	var calm := await _add("bandit_sword", Vector3(0, 0, -8), 0.0)  # back turned, out of earshot
	await _seconds(0.2)
	var tap := HitInfo.new()
	tap.damage = 1.0
	tap.attacker = player
	tap.origin = player.global_position
	calm.receive_hit(tap)
	await _frames(3)
	_check("hit while calm, it fights at once", calm.state != Enemy.State.IDLE and not calm.model.is_sheathed())
	# Bosses, hounds and ambushers keep their old ways.
	_clear()
	var h := await _add("hound", Vector3(5, 0, 5), 0.0)
	_check("hounds have no post", not h.post.enabled)

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _add(kind: String, at: Vector3, yaw_deg: float) -> Enemy:
	var e := (load("res://game/enemies/%s.tscn" % kind) as PackedScene).instantiate() as Enemy
	e.position = at
	e.rotation_degrees.y = yaw_deg
	_arena.add_child(e, true)
	await _frames(3)
	return e


## `a` faces `b` (within 25 degrees).
func _faces(a: Enemy, b: Enemy) -> bool:
	var to := b.global_position - a.global_position
	to.y = 0.0
	return rad_to_deg(a.model.forward().angle_to(to)) < 25.0


func _kill(e: Enemy) -> void:
	var hit := HitInfo.new()
	hit.damage = 99999.0
	hit.attacker = player
	hit.unblockable = true
	hit.origin = e.global_position
	e.receive_hit(hit)


func _clear() -> void:
	for e in get_tree().get_nodes_in_group(&"enemies"):
		e.remove_from_group(&"enemies")
		e.queue_free()


func _go_to(where: Vector3) -> void:
	player.global_position = where
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	player.model.face_instantly(Vector3(0, 0, -1))
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
