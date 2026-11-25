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
	# Exact timings below: no surprise follow-up attacks or held wind-ups (tested on their own).
	enemy.data.combo_chance = 0.0
	enemy.data.delay_chance = 0.0

	# --- Player attacks -----------------------------------------------------
	await _setup_duel()
	var hp := enemy.health
	await _tap("light_attack")
	await _seconds(0.5)
	var one_hit := hp - enemy.health
	_check_true("light attack hits the Marauder (%.0f damage)" % one_hit, one_hit >= _expected_hit() * 0.9)
	await _seconds(0.6)

	var guard_after := enemy.data.guard_after_hits
	enemy.data.guard_after_hits = 0
	await _setup_duel()
	hp = enemy.health
	for i in 3:
		await _tap("light_attack")
		await _seconds(0.4 if i < 2 else 1.3)
	var combo_hits := hp - enemy.health
	_check_true("3-hit light combo lands all three (%.0f damage)" % combo_hits, combo_hits >= _expected_hit() * 3.0)
	enemy.data.guard_after_hits = guard_after

	# --- Tempo: mash and it raises its guard, then strikes back ----------------------------
	await _setup_duel()
	enemy.data.counter_chance = 1.0
	var crit_was := player.weapon.crit_chance
	player.weapon.crit_chance = -10.0  # a random crit would spoil the damage total
	hp = enemy.health
	var saw_guard := false
	var saw_counter := false
	var guarded_hit := 0.0
	for i in 4:
		await _tap("light_attack")
		for f in 24:
			await get_tree().physics_frame
			if enemy.state == Enemy.State.GUARD:
				saw_guard = true
			if saw_guard and enemy.state == Enemy.State.ATTACK:
				saw_counter = true
		if saw_guard and guarded_hit == 0.0:
			guarded_hit = hp - enemy.health
	_check_true("after two hits in a row the Marauder raises its guard", saw_guard)
	_check_true("...blows on its guard only chip it (%.0f total after 4 swings)" % (hp - enemy.health), hp - enemy.health < _expected_hit() * 3.0)
	for f in 90:
		if saw_counter:
			break
		await get_tree().physics_frame
		saw_counter = enemy.state == Enemy.State.ATTACK
	_check_true("...and then it strikes back out of its guard", saw_counter)
	enemy.data.counter_chance = 0.65
	player.weapon.crit_chance = crit_was
	await _seconds(2.0)

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

	# Heavy attacks take their time: the blow lands well after a light one would.
	await _setup_duel()
	var frames_to_blow := 0
	await _tap("heavy_attack")
	for i in 120:
		await get_tree().physics_frame
		frames_to_blow += 1
		if player.state == Player.State.ATTACK and player._attack.past(player._attack.attack.hit_start):
			break
	var blow_time := frames_to_blow / float(Engine.physics_ticks_per_second)
	_check_true("a heavy winds up for a while before the blow (%.2f s)" % blow_time, blow_time >= 0.45)
	await _seconds(1.5)

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

	# Deflect: its balance drops and it recoils (the sweep is a single blow)
	await _setup_duel()
	await _force_attack(SWEEP)
	await _wait_until_hit_in(0.08)
	st = player.stamina
	Input.action_press("block")
	await _seconds(0.3)
	Input.action_release("block")
	_check_true("timed block deflects: no damage, it recoils (enemy state: %s)" % Enemy.State.keys()[enemy.state],
			enemy.state == Enemy.State.STAGGER and player.health == player.max_health())
	_check_true("...and its balance takes the blow (%.0f / %.0f)" % [enemy._poise, enemy.max_poise],
			enemy._poise <= enemy.max_poise - enemy.data.parry_poise_damage + 0.5)
	_check_true("...and a deflect gives stamina back instead of costing it (%.0f -> %.0f)" % [st, player.stamina], player.stamina >= st)
	# Balance refills gradually after a pause, not all at once.
	var low_bal := enemy._poise
	await _seconds(enemy.data.poise_regen_delay + 0.5)
	_check_true("balance refills gradually (%.0f -> %.0f of %.0f)" % [low_bal, enemy._poise, enemy.max_poise],
			enemy._poise > low_bal and enemy._poise < enemy.max_poise)

	# Deflect with its balance nearly gone -> off balance -> riposte
	await _setup_duel()
	enemy._poise = 5.0
	enemy._poise_timer = 99.0
	await _force_attack(SWEEP)
	await _wait_until_hit_in(0.08)
	Input.action_press("block")
	await _seconds(0.3)
	Input.action_release("block")
	_check_true("deflect that breaks its balance throws it off balance (enemy state: %s)" % Enemy.State.keys()[enemy.state],
			enemy.state == Enemy.State.PARRIED)
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
	_check_true("holding block early only blocks (no deflect)", enemy.state != Enemy.State.PARRIED and enemy.state != Enemy.State.STAGGER)

	# Mashing guard shrinks the deflect window; a calm press gets it all back.
	await _setup_duel()
	var windows: Array[float] = []
	for i in 3:
		Input.action_press("block")
		await _frames(3)
		windows.append(player._deflect_window)
		Input.action_release("block")
		await _frames(3)
	_check_true("mashing guard shrinks the deflect window (%.3f, %.3f, %.3f)" % windows, windows[1] < windows[0] and windows[2] < windows[1])
	await _seconds(0.6)
	Input.action_press("block")
	await _frames(3)
	_check_true("...a calm press opens it fully again (%.3f)" % player._deflect_window, is_equal_approx(player._deflect_window, windows[0]))
	Input.action_release("block")

	# Steady: guard tapped as an attack's recovery begins gives stamina back.
	await _setup_duel()
	enemy.global_position = Vector3(0, 0, -8.0)
	await _tap("light_attack")
	for i in 10:
		if player.state == Player.State.ATTACK:
			break
		await get_tree().physics_frame
	var a1 := player._attack.attack
	for i in 120:
		await get_tree().physics_frame
		if player._attack.past(a1.cancel_time):
			break
	st = player.stamina
	Input.action_press("block")
	await _frames(4)
	_check_true("Steady: guarding right at the recovery point refunds stamina (%.1f -> %.1f)" % [st, player.stamina], player.stamina > st + 2.0)
	Input.action_release("block")
	await _setup_duel()
	enemy.global_position = Vector3(0, 0, -8.0)
	await _tap("light_attack")
	await _seconds(0.9)
	st = player.stamina
	Input.action_press("block")
	await _frames(4)
	_check_true("...but not when you guard late (%.1f -> %.1f)" % [st, player.stamina], player.stamina <= st + 0.01)
	Input.action_release("block")

	# Perfect dodge: roll just as the blow lands.
	await _setup_duel()
	hp = player.health
	await _force_attack(SWEEP)
	await _wait_until_hit_in(0.08)
	player.stamina = 50.0
	await _tap("dodge_sprint")
	var evaded := false
	for i in 30:
		await get_tree().physics_frame
		evaded = evaded or player._evade_timer > 0.0
	_check_true("a last-moment roll is a perfect dodge (no damage, counter armed, stamina back: %.0f)" % player.stamina,
			player.health == hp and evaded and player.stamina >= 50.0)
	await _seconds(1.5)

	# Step-in: a perfect dodge *toward* a red attack rocks the attacker.
	await _setup_duel()
	hp = player.health
	await _force_attack(CRUSH)
	await _wait_until_hit_in(0.08)
	Input.action_press("move_forward")
	await _tap("dodge_sprint")
	var rocked := false
	for i in 30:
		await get_tree().physics_frame
		rocked = rocked or enemy.state == Enemy.State.STAGGER or enemy.state == Enemy.State.PARRIED
	Input.action_release("move_forward")
	_check_true("Step-in: rolling into the red crushing blow (no damage) rocks the Marauder (state %s, balance %.0f / %.0f)" % [Enemy.State.keys()[enemy.state], enemy._poise, enemy.max_poise],
			player.health == hp and rocked and enemy._poise <= enemy.max_poise * (1.0 - player.tuning.step_in_balance) + 0.5)
	await _seconds(1.5)

	# Counter hit: strike it while it winds up a swing.
	await _setup_duel()
	await _force_attack(OVERHEAD)
	await _tap("light_attack")
	for i in 30:
		await get_tree().physics_frame
		if enemy._poise < enemy.max_poise:
			break
	var lost := enemy.max_poise - enemy._poise
	_check_true("a blow during its wind-up is a counter hit (balance -%.0f, a normal hit is -%.0f)" % [lost, player.weapon.poise_damage],
			lost >= player.weapon.poise_damage * 1.4)
	await _seconds(2.0)

	# Combos: an enemy that strings attacks goes straight into a second one.
	await _setup_duel()
	var cc := enemy.data.combo_chance
	enemy.data.combo_chance = 1.0
	player.global_position = Vector3(0, 0.05, -0.2)
	await _force_attack(SWEEP)
	var chained := false
	for i in 240:
		await get_tree().physics_frame
		if enemy.state == Enemy.State.ATTACK and enemy._chain == 1:
			chained = true
			break
	_check_true("an enemy that strings attacks follows straight up with another", chained)
	enemy.data.combo_chance = cc
	await _seconds(2.0)

	# Delayed swings: some wind-ups are held a beat longer.
	await _setup_duel()
	enemy.data.delay_chance = 1.0
	enemy.start_attack(OVERHEAD)
	var held := enemy._attack.windup_scale
	enemy._set_state(Enemy.State.CHASE)
	enemy.data.delay_chance = 0.0
	enemy.start_attack(OVERHEAD)
	var normal := enemy._attack.windup_scale
	enemy._set_state(Enemy.State.CHASE)
	_check_true("a delayed swing holds its wind-up longer (x%.2f vs x%.2f)" % [held, normal], held < 1.0 and normal == 1.0)
	await _seconds(0.5)

	# Attack reach: a swing aimed at someone a step out of reach closes the gap and lands.
	await _setup_duel()
	enemy.global_position = Vector3(0, 0, -3.3)
	enemy.reset_physics_interpolation()
	await _frames(3)
	hp = enemy.health
	var z0 := player.global_position.z
	await _tap("light_attack")
	await _seconds(0.6)
	_check_true("attack reach: a light swing from 3.3 m steps in and lands (moved %.2f m, %.0f damage)" % [z0 - player.global_position.z, hp - enemy.health],
			enemy.health < hp and z0 - player.global_position.z <= player.tuning.reach_assist + 0.8)
	await _seconds(1.0)

	# Reading a turtle: block two of its blows in a row and its red attack gets far likelier.
	await _setup_duel()
	enemy._blocked_streak = 0
	enemy._on_hit_result(HitInfo.Result.BLOCKED)
	enemy._on_hit_result(HitInfo.Result.BLOCKED)
	var streak := enemy._blocked_streak
	var reds_read := 0
	var reds_plain := 0
	for i in 60:
		enemy._blocked_streak = 2
		enemy._start_attack(1.5)
		if enemy._attack.attack.unblockable:
			reds_read += 1
		enemy._set_state(Enemy.State.CHASE)
		enemy._blocked_streak = 0
		enemy._start_attack(1.5)
		if enemy._attack.attack.unblockable:
			reds_plain += 1
		enemy._set_state(Enemy.State.CHASE)
	enemy.model.set_overlay("")
	_check_true("two blocks in a row are counted (%d), and then it goes for its red attack far more (%d / 60 vs %d / 60)" % [streak, reds_read, reds_plain],
			streak == 2 and reds_read > reds_plain + 15)
	await _seconds(0.5)

	# Warnings you can hear: a white glint rings, a red attack rattles.
	await _setup_duel()
	Audio.recent_cues.clear()
	await _force_attack(SWEEP)
	await _wait_until_hit_in(0.05)
	_check_true("a white glint plays its warning sound", &"warn_glint" in Audio.recent_cues)
	await _seconds(1.5)
	await _setup_duel()
	Audio.recent_cues.clear()
	await _force_attack(CRUSH)
	await _wait_until_hit_in(0.05)
	_check_true("a red attack plays its low warning", &"warn_danger" in Audio.recent_cues)
	await _seconds(1.5)

	# Deflects in a row ring higher.
	await _setup_duel()
	player._last_deflect_at = -99.0
	for i in 2:
		await _force_attack(SWEEP)
		await _wait_until_hit_in(0.08)
		Input.action_press("block")
		await _seconds(0.25)
		Input.action_release("block")
		enemy._poise = enemy.max_poise
		enemy._set_state(Enemy.State.CHASE)
		await _seconds(0.3)
	_check_true("a second deflect in a row rings higher (step %d, pitch x%.2f)" % [player._deflect_chain, 1.0 + player.tuning.deflect_chain_pitch * player._deflect_chain],
			player._deflect_chain == 1)

	# Flawless: deflect every blow of a string and the last one hits its balance twice.
	await _setup_duel()
	var string_attack := (enemy.data.attacks[SWEEP] as AttackData).duplicate() as AttackData
	string_attack.extra_hits = PackedVector2Array([Vector2(string_attack.hit_end + 0.1, string_attack.hit_end + 0.2)])
	enemy._set_state(Enemy.State.ATTACK)
	enemy._attack.start(string_attack, enemy.model)
	enemy._string_parries = 0
	enemy._poise = 100.0  # plenty, so the check sees the drop rather than a break
	enemy._attack.t = string_attack.hit_start + 0.01
	enemy._on_hit_result(HitInfo.Result.PARRIED)
	var after_first := enemy._poise
	enemy._attack.t = string_attack.hit_end + 0.15
	enemy._on_hit_result(HitInfo.Result.PARRIED)
	var last_drop := after_first - enemy._poise
	_check_true("Flawless: deflecting every blow of a string, the last one rocks it twice as hard (-%.0f, a deflect is -%.0f)" % [last_drop, enemy.data.parry_poise_damage],
			last_drop >= enemy.data.parry_poise_damage * 2.0 - 0.5)
	await _seconds(1.0)

	# Breaking balance lands hard: a crack you hear.
	await _setup_duel()
	Audio.recent_cues.clear()
	enemy._poise = 5.0
	enemy._poise_timer = 99.0
	await _force_attack(SWEEP)
	await _wait_until_hit_in(0.08)
	Input.action_press("block")
	await _seconds(0.25)
	Input.action_release("block")
	_check_true("breaking its balance plays the crack (state %s)" % Enemy.State.keys()[enemy.state],
			enemy.state == Enemy.State.PARRIED and &"break_balance" in Audio.recent_cues)
	await _seconds(2.0)

	# Flinch: swing into their blade and your light attack is knocked away.
	await _setup_duel()
	await _tap("light_attack")
	for i in 10:
		if player.state == Player.State.ATTACK:
			break
		await get_tree().physics_frame
	var poke := enemy.make_hit(SWEEP)
	poke.poise_damage = 1.0
	poke.damage = 1.0
	player.receive_hit(poke)
	_check_true("a clean hit during your light attack's wind-up interrupts it (state %s)" % Player.State.keys()[player.state],
			player.state == Player.State.STAGGER)
	await _seconds(0.8)
	await _setup_duel()
	enemy.global_position = Vector3(0, 0, -8.0)
	await _tap("heavy_attack")
	for i in 10:
		if player.state == Player.State.ATTACK:
			break
		await get_tree().physics_frame
	poke = enemy.make_hit(SWEEP)
	poke.poise_damage = 1.0
	poke.damage = 1.0
	player.receive_hit(poke)
	_check_true("...a heavy swing powers through it (state %s)" % Player.State.keys()[player.state],
			player.state == Player.State.ATTACK)
	await _seconds(2.0)

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

	# --- Sneak attack and hits from behind (STEALTH_PLAN.md stage 3) ------------------
	await _setup_duel()
	enemy.global_position = Vector3(40, 0, -40)
	var crit_keep := player.weapon.crit_chance
	var block_keep := enemy.data.block_chance
	player.weapon.crit_chance = -10.0
	enemy.data.block_chance = 0.0
	var sneak_mult := player.weapon.sneak_multiplier
	var flank_mult := player.tuning.flank_damage_mult
	var plain_dmg := _land(Enemy.State.CHASE, false)
	var sneaked := _land(Enemy.State.IDLE, false)
	_check_true("a sneak attack does sneak_multiplier x the normal damage (%.1f vs %.1f)" % [sneaked, plain_dmg], absf(sneaked / plain_dmg - sneak_mult) < 0.05)
	_check_true("...the enemy now fights, so the next blow is plain_dmg", not enemy.is_unaware() and absf(_land(enemy.state, false) / plain_dmg - 1.0) < 0.05)
	var probe := HitInfo.new()
	probe.poise_damage = 10.0
	enemy._set_state(Enemy.State.IDLE)
	var bonus := player.position_bonus(enemy, probe, player.is_sneak_target(enemy))
	_check_true("...always a crit, with double balance damage", probe.is_crit and absf(probe.poise_damage - 10.0 * player.tuning.sneak_poise_mult) < 0.01 and bonus > 1.0)
	_check_true("a suspicious enemy counts as unaware too", _land(Enemy.State.SUSPICIOUS, false) / plain_dmg > sneak_mult - 0.05)
	enemy.data.named = true
	_check_true("named rares take at most x%.1f" % player.tuning.sneak_named_cap, absf(_land(Enemy.State.IDLE, false) / plain_dmg - minf(sneak_mult, player.tuning.sneak_named_cap)) < 0.05)
	enemy.data.named = false
	enemy.data.boss = true
	_check_true("bosses are never unaware", not enemy.is_unaware())
	enemy.data.boss = false
	var behind := _land(Enemy.State.CHASE, true)
	_check_true("a hit from behind does x%.1f in a fight (%.1f vs %.1f)" % [flank_mult, behind, plain_dmg], absf(behind / plain_dmg - flank_mult) < 0.05)
	var both := _land(Enemy.State.IDLE, true)
	_check_true("sneak from behind uses the larger bonus, no stacking", absf(both / plain_dmg - maxf(sneak_mult, flank_mult)) < 0.05)
	player.weapon.crit_chance = crit_keep
	enemy.data.block_chance = block_keep

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
## Land one light attack on the Marauder in `st`, facing the player (or away), and
## return the health it lost.
func _land(st: Enemy.State, away: bool) -> float:
	enemy.global_position = player.global_position + Vector3(0, 0, -1.8)
	enemy.reset_physics_interpolation()
	var to := player.global_position - enemy.global_position
	enemy.model.face_instantly(-to if away else to)
	enemy.health = enemy.max_health
	enemy.target = null
	enemy._poise = enemy.max_poise
	enemy._set_state(st)
	var before := enemy.health
	player._land_hit(enemy, player.weapon.light_combo[0], 0.0)
	return before - enemy.health


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
