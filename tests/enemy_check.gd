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
	await _seconds(2.0)
	_check("a Zealot sees you in front of it", z.state != Enemy.State.IDLE)
	_clear()
	z = await _add("zealot", Vector3(0, 0, -10), 0.0)  # back turned
	await _seconds(1.0)
	_check("...but not from behind", z.state == Enemy.State.IDLE)
	await _go_to(Vector3(0, 0.05, -8.5))  # 1.5 m behind it (a still player is heard within 1.8 m)
	await _seconds(1.0)
	_check("...and hears you up close", z.state != Enemy.State.IDLE)

	# --- Horn call --------------------------------------------------------------------------
	_clear()
	await _go_to(Vector3(0, 0.05, 0))
	var caller := await _add("zealot", Vector3(0, 0, -10), 180.0)
	var friend := await _add("zealot", Vector3(10, 0, -10), 0.0)  # looking away
	var hound := await _add("hound", Vector3(-11, 0, -10), 0.0)  # not its kind
	for i in 240:
		await get_tree().physics_frame
		if caller.state == Enemy.State.CALL:
			break
	_check("the Zealot stops to blow its horn", caller.state == Enemy.State.CALL)
	await _seconds(1.8)
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
	await _seconds(3.0)
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
	for i in 300:
		await get_tree().physics_frame
		if b2.target == player:
			break
	var spotted := b2.target == player
	_check("the one facing you notices you", spotted)
	_check("...and takes a moment to get ready (no instant charge)", b2.state != Enemy.State.CHASE)
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
	_check("hit while calm, it fights at once (drawing its sword)", calm.state != Enemy.State.IDLE and (calm.model.is_drawing() or not calm.model.is_sheathed()))
	# Bosses, hounds and ambushers keep their old ways.
	_clear()
	var h := await _add("hound", Vector3(5, 0, 5), 0.0)
	_check("hounds have no post", not h.post.enabled)

	# --- Patrols: abreast, a pause at each corner to look around (stage 2) ------------
	_clear()
	await _go_to(Vector3(30, 0.05, -30))  # far out of sight
	var route := PackedVector3Array([Vector3(-15, 0, 12), Vector3(-15, 0, 22), Vector3(-22, 0, 22)])
	var walkers: Array[Enemy] = []
	for i in 2:
		var w := (load("res://game/enemies/bandit_sword.tscn") as PackedScene).instantiate() as Enemy
		w.patrol_points = route
		w.patrol_group = &"check/1"
		w.patrol_side = -0.7 if i == 0 else 0.7
		w.position = Vector3(-15 + w.patrol_side * -1.0, 0, 8.0 - i * 0.5)  # a few meters short of the first corner
		_arena.add_child(w, true)
		walkers.append(w)
	await _seconds(1.0)
	var gap := walkers[0].global_position.distance_to(walkers[1].global_position)
	_check("a patrol walks side by side (gap %.1f m)" % gap, gap > 0.9 and gap < 2.2)
	# Wait for them to reach the first corner, then watch the pause.
	var paused_at := -1.0
	for i in 600:
		await get_tree().physics_frame
		if walkers.all(func(w: Enemy) -> bool: return w.post.is_waiting()):
			paused_at = i / 60.0
			break
	_check("both stop at the corner", paused_at >= 0.0)
	var facing0 := walkers[0].model.forward()
	await _seconds(2.0)
	_check("...stand there a while", walkers.all(func(w: Enemy) -> bool: return w.post.is_waiting()))
	_check("...looking around", rad_to_deg(facing0.angle_to(walkers[0].model.forward())) > 25.0)
	_check("...weapons still sheathed", walkers.all(func(w: Enemy) -> bool: return w.model.is_sheathed()))
	for i in 600:
		await get_tree().physics_frame
		if not walkers[0].post.is_waiting():
			break
	await _frames(2)
	_check("...and set off together", walkers.all(func(w: Enemy) -> bool: return not w.post.is_waiting() and w.post.leg == 1))

	# --- Watch posts (stage 3) -----------------------------------------------------------
	_clear()
	await _go_to(Vector3(0, 0.05, 60))  # far out of sight
	var watcher := _watcher(Vector3(0, 0, 20), Vector3.BACK)  # watches toward +z
	var plain := await _add("bandit_sword", Vector3(16, 0, 20), 0.0)  # beyond the 10 m warning range
	plain.model.face_instantly(Vector3.BACK)
	await _seconds(0.8)
	_check("a watcher faces the way its post looks", rad_to_deg(watcher.model.forward().angle_to(Vector3.BACK)) < 50.0)
	_check("...weapon sheathed", watcher.model.is_sheathed())
	var look0 := watcher.model.forward()
	await _seconds(6.0)
	_check("...and scans left and right", rad_to_deg(look0.angle_to(watcher.model.forward())) > 15.0)
	# 27 m in front of both: past a plain bandit's sight (22 m), inside the watcher's (about 30 m).
	await _go_to(Vector3(3, 0.05, 47))
	await _seconds(4.0)
	_check("a watcher sees farther than others", watcher.target == player and plain.target == null)
	# A lookout with no set direction turns its back on its camp.
	_clear()
	await _go_to(Vector3(0, 0.05, 60))
	await _add("bandit_sword", Vector3(-20, 0, 0), 0.0)
	await _add("bandit_sword", Vector3(-20, 0, 2), 0.0)
	var lookout := await _add("bandit_lookout", Vector3(-14, 0, 1), 90.0)
	await _seconds(0.8)
	_check("a lookout faces away from its camp", lookout.post.watching and rad_to_deg(lookout.model.forward().angle_to(Vector3.RIGHT)) < 50.0)

	# --- Stealth: the awareness meter (STEALTH_PLAN.md stage 2) -----------------------
	_clear()
	player.is_crouching = true
	var side := Vector3(12.0 * sin(deg_to_rad(50.0)), 0.05, -20.0 - 12.0 * cos(deg_to_rad(50.0)))
	await _go_to(side)  # 12 m away, 50 degrees off where the bandit faces
	var sentry := await _add("bandit_sword", Vector3(0, 0, -20), 0.0)  # faces -z
	await _seconds(5.0)
	_check("a crouched player 12 m off to the side stays unnoticed for 5 s", sentry.state == Enemy.State.IDLE and sentry.target == null)
	player.is_crouching = false
	await _seconds(3.0)
	_check("...a standing one at the same place is noticed", sentry.state != Enemy.State.IDLE or sentry.target == player)
	# Straight at its face, crouched: noticed before 3 m. Creeping up behind it: reaches 1.5 m unnoticed.
	_clear()
	player.is_crouching = true
	var guard := await _add("bandit_sword", Vector3(0, 0, -30), 0.0)  # faces -z, away from the north start
	await _go_to(Vector3(0, 0.05, -45))  # in front of it (it faces -z)
	var closest := 99.0
	for i in 900:
		var d := player.global_position.distance_to(guard.global_position)
		closest = minf(closest, d)
		if guard.target == player or guard.state != Enemy.State.IDLE and guard.state != Enemy.State.SUSPICIOUS:
			break
		player.global_position.z += 2.2 / 60.0
		await get_tree().physics_frame
	_check("a crouched player walking at its face is noticed before 3 m (at %.1f m)" % closest, closest > 3.0 and (guard.target == player or guard.state != Enemy.State.IDLE))
	_clear()
	guard = await _add("bandit_sword", Vector3(0, 0, -30), 0.0)
	await _go_to(Vector3(0, 0.05, -18))  # 12 m behind it
	closest = 99.0
	for i in 900:
		closest = minf(closest, player.global_position.distance_to(guard.global_position))
		if closest <= 1.5:
			break
		player.global_position.z -= 2.2 / 60.0
		await get_tree().physics_frame
	_check("creeping up behind it reaches %.1f m unnoticed" % closest, closest <= 1.5 and guard.target == null and guard.is_unaware())
	# The meter goes suspicious, then back to idle when the player backs off and waits.
	_clear()
	player.is_crouching = true
	await _go_to(Vector3(0, 0.05, -20))
	var watcher2 := await _add("bandit_sword", Vector3(0, 0, -26), 180.0)  # 6 m away, facing you
	var was_suspicious := false
	for i in 300:
		await get_tree().physics_frame
		if watcher2.state == Enemy.State.SUSPICIOUS:
			was_suspicious = true
			break
		if watcher2.state != Enemy.State.IDLE:
			break
	_check("a half-noticed player makes it suspicious", was_suspicious and watcher2.is_unaware() and not watcher2.is_fighting())
	_check("...drawing its weapon", watcher2.model.is_drawing() or not watcher2.model.is_sheathed())
	await _go_to(Vector3(0, 0.05, 20))  # backs far off
	await _seconds(7.0)
	_check("...and it gives up and goes back to its post", watcher2.state in [Enemy.State.IDLE, Enemy.State.RETURN] and watcher2.target == null)
	# A blow on a suspicious enemy: it fights at once.
	_clear()
	player.is_crouching = true
	await _go_to(Vector3(0, 0.05, -20))
	var wary := await _add("bandit_sword", Vector3(0, 0, -26), 180.0)
	for i in 300:
		await get_tree().physics_frame
		if wary.state == Enemy.State.SUSPICIOUS:
			break
	var poke := HitInfo.new()
	poke.damage = 1.0
	poke.attacker = player
	poke.origin = player.global_position
	wary.receive_hit(poke)
	await _frames(3)
	_check("hit while suspicious, it fights at once", wary.state != Enemy.State.IDLE and wary.state != Enemy.State.SUSPICIOUS)
	_check("...and a fighting enemy is no longer unaware", not wary.is_unaware())
	player.is_crouching = false
	# Ambushers keep the old instant way.
	_clear()
	await _go_to(Vector3(0, 0.05, 0))
	var ambusher := await _add("bandit_archer_ambush", Vector3(0, 0, -4), 0.0)
	await _seconds(0.4)
	_check("an ambusher wakes at once when you are right on top of it", ambusher.state != Enemy.State.IDLE)

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _add(kind: String, at: Vector3, yaw_deg: float) -> Enemy:
	var e := (load("res://game/enemies/%s.tscn" % kind) as PackedScene).instantiate() as Enemy
	e.position = at
	e.rotation_degrees.y = yaw_deg
	_arena.add_child(e, true)
	await _frames(3)
	return e


## A bandit on a watch post looking along `dir` (as a "watch" spawn point makes it).
func _watcher(at: Vector3, dir: Vector3) -> Enemy:
	var e := (load("res://game/enemies/bandit_sword.tscn") as PackedScene).instantiate() as Enemy
	e.position = at
	e.set_meta(&"post_kind", "watch")
	e.set_meta(&"watch_dir", dir)
	_arena.add_child(e, true)
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
