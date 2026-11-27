extends Node
## Automated check of the extra melee moves (jump light/heavy, plunge, guard
## counter, running/rolling heavy, backstep attack), the mouse-flick lock-on
## release, and enemies keeping their distance from each other.
##   ... --headless --script res://tests/run.gd -- moves_check

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
	player.flasks = 4

	# --- The moves exist for the starting weapon -----------------------------------------
	var w := player.weapon
	for k in [&"jump_light", &"jump_heavy", &"plunge", &"guard_counter", &"running_heavy", &"rolling_heavy", &"backstep_attack"]:
		_check("weapon has a %s move" % k, w.move(k) != null)
	_check("plunge hits all around, harder than a heavy", w.move(&"plunge").arc_degrees == 360.0 and w.move(&"plunge").damage_mult > w.heavy.damage_mult)

	# --- Jump light attack -----------------------------------------------------------------
	var e := await _dummy_enemy(Vector3(0, 0, -2.0))
	await _go_to(Vector3(0, 0.05, 0))
	await _tap("jump")
	await _seconds(0.12)
	var hp := e.health
	await _tap("light_attack")
	await _frames(2)
	_check("light attack in the air is a jump attack", player.state == Player.State.ATTACK and player._attack.attack == w.move(&"jump_light"))
	_check("...a downward chop, not the ground swing (playing %s)" % player.model.current_anim(), player.model.current_anim() == &"cut/Jump_Chop")
	await _seconds(0.9)
	var jump_light := hp - e.health
	_check("...and it hurts (%.0f)" % jump_light, jump_light > 0.0)
	await _seconds(0.8)

	# --- Jump heavy attack -------------------------------------------------------------------
	e.health = e.max_health
	await _go_to(Vector3(0, 0.05, 0))
	await _tap("jump")
	await _seconds(0.12)
	hp = e.health
	await _tap("heavy_attack")
	await _frames(2)
	_check("heavy attack in the air is a jump heavy", player.state == Player.State.ATTACK and player._attack.attack == w.move(&"jump_heavy"))
	_check("...an overhead slam (playing %s)" % player.model.current_anim(), player.model.current_anim() == &"cut/Jump_Slam")
	await _seconds(1.1)
	var jump_heavy := hp - e.health
	_check("...and hits harder than the jump light (%.0f vs %.0f)" % [jump_heavy, jump_light], jump_heavy > jump_light)
	await _seconds(0.8)

	# --- Plunging attack -----------------------------------------------------------------------
	e.health = e.max_health
	e._set_state(Enemy.State.IDLE)
	await _go_to(Vector3(0, 6.5, -0.6))
	player._enter_air(false)
	player.velocity = Vector3.ZERO
	await _frames(3)
	var health_before := player.health
	hp = e.health
	await _tap("light_attack")
	await _frames(2)
	_check("attacking from high up is a plunge", player._plunging and player._attack.attack == w.move(&"plunge"))
	await _seconds(1.6)
	_check("the plunge lands a heavy blow (%.0f)" % (hp - e.health), hp - e.health > jump_heavy * 0.9)
	_check("...and the landing doesn't hurt you", player.health >= health_before - 0.5)
	await _seconds(0.8)

	# --- Guard counter -----------------------------------------------------------------------------
	_calm(e)
	await _go_to(Vector3(0, 0.05, 0))
	await _settle()
	_send("block", true)
	await _seconds(0.3)
	await _tap("light_attack")
	await _frames(2)
	_check("light attack out of a raised guard is a guard counter", player.state == Player.State.ATTACK and player._attack.attack == w.move(&"guard_counter"))
	_send("block", false)
	await _seconds(1.2)

	# --- Running heavy, rolling heavy, backstep attack -------------------------------------------------
	await _go_to(Vector3(0, 0.05, 0))
	# Sprint flag but standing still: no sprinting attack (it needs real momentum).
	player.is_sprinting = true
	player.velocity = Vector3.ZERO
	player._start_heavy_attack(Vector3(0, 0, -1))
	_check("sprint held but not moving: no sprinting heavy", player._attack.attack != w.move(&"running_heavy"))
	await _seconds(1.6)
	await _go_to(Vector3(0, 0.05, 0))
	player.stamina = player.max_stamina()
	player.is_sprinting = true
	player.velocity = Vector3(0, 0, -player.tuning.sprint_speed)
	player._start_heavy_attack(Vector3(0, 0, -1))
	_check("heavy while sprinting is a running heavy", player._attack.attack == w.move(&"running_heavy"))
	await _seconds(1.3)
	await _go_to(Vector3(0, 0.05, 0))
	player._since_roll = 0.1
	player._roll_backward = false
	player._start_heavy_attack(Vector3(0, 0, -1))
	_check("heavy right after a roll is a rolling heavy", player._attack.attack == w.move(&"rolling_heavy"))
	await _seconds(1.3)
	await _go_to(Vector3(0, 0.05, 0))
	player._since_roll = 0.1
	player._roll_backward = true
	player._start_light_attack(Vector3(0, 0, -1))
	_check("light right after a backstep is a backstep attack", player._attack.attack == w.move(&"backstep_attack"))
	await _seconds(1.2)
	player._roll_backward = false
	player._since_roll = 99.0

	# --- Mouse flick lets go of the lock ------------------------------------------------------------------
	await _go_to(Vector3(0, 0.05, 0))
	player.targeting.camera = player.camera_rig.camera
	player.targeting._set_target(e)
	player.targeting.mouse_moved(-20.0)
	player.targeting.mouse_moved(15.0)
	_check("small mouse movements keep the lock", player.targeting.has_target())
	var gone := player.targeting.mouse_moved(-150.0)
	gone = player.targeting.mouse_moved(-150.0) or gone
	_check("a quick flick to the left lets go of the lock", gone and not player.targeting.has_target())
	player.targeting._set_target(e)
	player.targeting.mouse_moved(140.0)
	player.targeting.mouse_moved(140.0)
	_check("a flick to the right does too", not player.targeting.has_target())

	# --- Enemies don't stack, they spread around you --------------------------------------------------------
	_clear()
	await _go_to(Vector3(0, 0.05, 0))
	var pack: Array[Enemy] = []
	for i in 5:
		var m := await _add("marauder", Vector3(0.25 * i, 0, -9.0 + 0.2 * i), 180.0)
		m._cooldown = 1.0e9  # they close in and surround, but don't swing
		pack.append(m)
	await _seconds(7.0)
	var closest := INF
	var near_you := 0
	for i in pack.size():
		if pack[i].global_position.distance_to(player.global_position) < 4.5:
			near_you += 1
		for j in range(i + 1, pack.size()):
			closest = minf(closest, pack[i].global_position.distance_to(pack[j].global_position))
	_check("all five close in on you (%d near)" % near_you, near_you == 5)
	_check("no two overlap (closest %.2f m)" % closest, closest > 0.8)
	var angles: Array[float] = []
	for m in pack:
		var d := m.global_position - player.global_position
		angles.append(atan2(d.z, d.x))
	angles.sort()
	var biggest_gap := 0.0
	for i in angles.size():
		var gap := (angles[(i + 1) % angles.size()] - angles[i]) if i < angles.size() - 1 else (angles[0] + TAU - angles[i])
		biggest_gap = maxf(biggest_gap, gap)
	_check("...spread around you, not in a clump (biggest gap %.0f degrees)" % rad_to_deg(biggest_gap), rad_to_deg(biggest_gap) < 200.0)

	# Two in a narrow corridor: the one behind can't attack past the one in front.
	_clear()
	await _go_to(Vector3(0, 0.05, 0))
	var front := await _add("marauder", Vector3(0, 0, -2.2), 0.0)
	var back := await _add("marauder", Vector3(0, 0, -3.1), 0.0)
	front._cooldown = 1.0e9
	await _seconds(0.5)
	back._cooldown = 0.0
	back.target = player
	_check("an enemy with a friend standing in the way doesn't swing", back._ally_in_the_way(player.global_position - back.global_position))

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _dummy_enemy(at: Vector3) -> Enemy:
	var e := await _add("marauder", at, 0.0)
	e._cooldown = 1.0e9  # it stands and takes it
	e.data = e.data.duplicate()
	e.data.sight_range = 0.0
	e.data.hearing_range = 0.0
	e.data.guard_after_hits = 0  # never raises its guard (and so never strikes back out of it)
	return e


func _add(kind: String, at: Vector3, yaw_deg: float) -> Enemy:
	var e := (load("res://game/enemies/%s.tscn" % kind) as PackedScene).instantiate() as Enemy
	e.position = at
	e.rotation_degrees.y = yaw_deg
	_arena.add_child(e, true)
	await _frames(3)
	return e


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


func _send(action: StringName, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _tap(action: StringName) -> void:
	_send(action, true)
	await get_tree().physics_frame
	_send(action, false)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s, true, true).timeout


func _check(label: String, ok: bool) -> void:
	print("%s %s" % ["ok   " if ok else "FAIL ", label])
	if not ok:
		failures += 1


## Wait until the player is standing idle with full stamina (landings and
## attack recoveries can still be running from the previous step).
func _settle() -> void:
	for i in 180:
		if player.state == Player.State.MOVE and player.is_on_floor():
			break
		await get_tree().physics_frame
	player.stamina = player.max_stamina()
	await _frames(10)


## The dummy got knocked about by the jump attacks and the plunge: recovering from a
## stagger resets its attack cooldown, so put it back to standing still and harmless.
func _calm(e: Enemy) -> void:
	e._set_state(Enemy.State.IDLE)
	e.target = null
	e._cooldown = 1.0e9
	e._poise = e.max_poise
