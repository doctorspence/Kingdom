extends Node
## Automated combat check on the combat test map. Presses buttons for the
## player and forces the Marauder's attacks at exact moments.
##
## Run (from the project folder):
##   Godot_console.exe --headless --path . --script res://tests/run.gd -- combat_check

const SWEEP := 0
const OVERHEAD := 1
const CRUSH := 2

var player: Player
var enemy: Enemy
var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(20)
	player = get_tree().get_first_node_in_group(&"player") as Player
	enemy = scene.get_node("Enemies/Marauder") as Enemy
	var other := scene.get_node("Enemies/Marauder2") as Enemy
	other.global_position = Vector3(60, 0, 60)

	# --- Player attacks -----------------------------------------------------
	await _setup_duel()
	var hp := enemy.health
	await _tap("light_attack")
	await _seconds(0.5)
	var one_hit := hp - enemy.health
	_check_true("light attack hits the Marauder (%.0f damage)" % one_hit, one_hit >= _expected_hit() * 0.9)
	await _seconds(0.6)

	await _setup_duel()
	hp = enemy.health
	for i in 3:
		await _tap("light_attack")
		await _seconds(0.4 if i < 2 else 1.3)
	var combo_hits := hp - enemy.health
	_check_true("3-hit light combo lands all three (%.0f damage)" % combo_hits, combo_hits >= _expected_hit() * 3.0)

	var crit_before := player.weapon.crit_chance
	player.weapon.crit_chance = -10.0  # no random crits while comparing damage
	await _setup_duel()
	hp = enemy.health
	await _tap("heavy_attack")
	await _seconds(1.2)
	var heavy := hp - enemy.health
	await _setup_duel()
	hp = enemy.health
	_send("heavy_attack", true)
	await _seconds(1.2)
	_send("heavy_attack", false)
	await _seconds(1.0)
	var charged := hp - enemy.health
	player.weapon.crit_chance = crit_before
	_check_true("charged heavy hits harder (%.0f vs %.0f)" % [charged, heavy], heavy > 0.0 and charged > heavy * 1.3)

	await _setup_duel()
	var st := player.stamina
	await _tap("light_attack")
	await _seconds(0.1)
	_check_true("attacks cost stamina", player.stamina < st)

	# --- Enemy attacks ------------------------------------------------------
	await _setup_duel()
	hp = player.health
	await _force_attack(SWEEP)
	await _seconds(2.0)
	_check_true("Marauder sweep hurts an idle player (%.0f)" % (hp - player.health), player.health < hp)

	await _setup_duel()
	Input.action_press("block")
	await _seconds(0.6)
	hp = player.health
	st = player.stamina
	await _force_attack(SWEEP)
	var low := st
	for i in 120:
		await get_tree().physics_frame
		low = minf(low, player.stamina)
	_check_true("shield block: no damage, costs stamina (hp %.0f->%.0f, st %.0f->%.0f)" % [hp, player.health, st, low],
			player.health == hp and low < st)
	Input.action_release("block")

	await _setup_duel()
	hp = player.health
	await _force_attack(CRUSH)
	Input.action_press("block")
	await _seconds(2.0)
	Input.action_release("block")
	_check_true("unblockable crush goes through a block", player.health < hp)

	await _setup_duel()
	hp = player.health
	await _force_attack(SWEEP)
	await _wait_until_hit_in(0.12)
	await _tap("dodge_sprint")
	await _seconds(1.5)
	_check_true("rolling through the sweep avoids damage", player.health == hp)

	# Parry -> riposte
	await _setup_duel()
	await _force_attack(SWEEP)
	await _wait_until_hit_in(0.08)
	Input.action_press("block")
	await _seconds(0.3)
	Input.action_release("block")
	_check_true("timed block parries (enemy state: %s)" % Enemy.State.keys()[enemy.state], enemy.state == Enemy.State.PARRIED)
	hp = enemy.health
	await _seconds(0.2)
	await _tap("light_attack")
	await _seconds(1.6)
	var riposte := hp - enemy.health
	_check_true("riposte deals big damage (%.0f)" % riposte, riposte >= _expected_hit() * 2.5)

	# Holding block early is NOT a parry
	await _setup_duel()
	Input.action_press("block")
	await _seconds(0.5)
	await _force_attack(SWEEP)
	await _seconds(1.5)
	Input.action_release("block")
	_check_true("holding block early only blocks (no parry)", enemy.state != Enemy.State.PARRIED)

	# Guard break when out of stamina
	await _setup_duel()
	Input.action_press("block")
	await _seconds(0.5)
	await _force_attack(SWEEP)
	await _wait_until_hit_in(0.03)
	player.stamina = 4.0
	var broke := false
	for i in 120:
		await get_tree().physics_frame
		if player.state == Player.State.GUARD_BREAK:
			broke = true
			break
	Input.action_release("block")
	_check_true("blocking with no stamina left breaks your guard", broke)
	await _seconds(1.5)

	# Poise: the crushing blow staggers even a Bulwark (overheads don't: +25% poise)
	await _setup_duel()
	await _force_attack(CRUSH)
	var staggered := false
	for i in 180:
		await get_tree().physics_frame
		if player.state == Player.State.STAGGER:
			staggered = true
			break
	_check_true("crushing blow breaks player poise (stagger)", staggered)
	await _seconds(1.0)

	# --- Flasks and shrine ----------------------------------------------------
	await _setup_duel()
	enemy.global_position = Vector3(40, 0, -40)
	player.health = player.max_health() * 0.4
	await _tap("flask")
	await _seconds(1.4)
	_check_true("flask heals 40%% (hp %.0f, flasks %d)" % [player.health, player.flasks],
			absf(player.health - player.max_health() * 0.8) < 0.5 and player.flasks == player.tuning.flask_count - 1)

	enemy.global_position = player.global_position + Vector3(0, 0, -1.8)
	enemy.reset_physics_interpolation()
	enemy.health = 1.0
	enemy._cooldown = 99.0
	await _frames(5)
	await _tap("light_attack")
	await _seconds(0.8)
	_check_true("Marauder dies at 0 health", enemy.state == Enemy.State.DEAD)
	_check_true("dead enemy can't be locked on", not enemy.can_be_locked())

	var shrine := scene.get_node("Shrine") as Node3D
	player.global_position = shrine.global_position + Vector3(0, 0.05, 1.5)
	player.reset_physics_interpolation()
	await _frames(5)
	(shrine as Shrine).rest(player)  # the shrine menu's "Rest" button
	await _seconds(0.3)
	_check_true("resting refills flasks and health", player.flasks == player.tuning.flask_count and player.health == player.max_health())
	_check_true("resting brings the Marauder back", enemy.state != Enemy.State.DEAD and enemy.health == enemy.data.max_health)

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


## A light hit after the class's stat bonus and the Marauder's armor (DESIGN.md 5.12).
func _expected_hit() -> float:
	return player.weapon_damage() * (1.0 - HitInfo.armor_reduction(enemy.armor(), player.level()))


## Player and Marauder face to face, 2 m apart, both fresh; the Marauder won't
## attack on its own.
func _setup_duel() -> void:
	Input.action_release("block")
	player.respawn()
	await _frames(2)
	player.global_position = Vector3(0, 0.05, 0)
	player.model.face_instantly(Vector3.FORWARD)
	player.camera_rig.yaw = 0.0
	player.reset_physics_interpolation()
	player.stamina = player.max_stamina()
	player.health = player.max_health()
	enemy.reset_from_rest()
	enemy.global_position = Vector3(0, 0, -2.0)
	enemy.model.face_instantly(Vector3.BACK)
	enemy.reset_physics_interpolation()
	enemy.target = player
	enemy._set_state(Enemy.State.CHASE)
	enemy._cooldown = 999.0
	await _frames(10)


func _force_attack(index: int) -> void:
	enemy.model.face_instantly(player.global_position - enemy.global_position)
	enemy.target = player
	enemy._telegraphed = false
	enemy._set_state(Enemy.State.ATTACK)
	enemy._attack.start(enemy.data.attacks[index], enemy.model)
	await get_tree().physics_frame


## Wait until the enemy's blow lands in about `seconds` real time.
func _wait_until_hit_in(seconds: float) -> void:
	var a := enemy._attack.attack
	for i in 400:
		var t := enemy._attack.t
		var remaining := (a.hit_start - t) / a.anim_speed
		if t < a.windup_until:
			remaining = (a.windup_until - t) / (a.anim_speed * a.windup_speed_mult) + (a.hit_start - a.windup_until) / a.anim_speed
		if remaining <= seconds:
			return
		await get_tree().physics_frame


## Press (true) or release (false) a button, like a real key press.
func _send(action: StringName, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)


func _tap(action: StringName) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().physics_frame
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await _frames(ceili(s * Engine.physics_ticks_per_second))


func _check_true(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", label])
	if not ok:
		failures += 1
