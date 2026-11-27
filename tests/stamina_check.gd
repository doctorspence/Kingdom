extends Node
## Stamina, blocking, dodge-roll and sprinting-attack check (2026-11-27 combat pass).
## Loads the combat test map, presses buttons for the player, and measures the
## numbers in PlayerTuning ("Stamina: ..." and "Sprinting attacks" groups).
##
## Run (from the project folder):
##   Godot_console.exe --headless --path . --script res://tests/run.gd -- stamina_check

var player: Player
var enemy: Enemy
var hud: Node
var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(20)
	player = get_tree().get_first_node_in_group(&"player") as Player
	enemy = scene.get_node("Enemies/Marauder") as Enemy
	hud = scene.get_node("Hud")
	(scene.get_node("Enemies/Marauder2") as Node3D).global_position = Vector3(60, 0, 60)
	enemy.data.combo_chance = 0.0
	enemy.data.delay_chance = 0.0
	var t := player.tuning
	var full := player.max_stamina()
	print("max stamina %.0f, class %s, shield %s" % [full, player.stats.class_data.display_name,
			player.shield.display_name if player.shield else "none"])

	await _block_tests(t, full)
	await _roll_tests(t, full)
	await _exhaustion_tests(t, full)
	await _block_movement_tests(t)
	await _sprint_attack_tests(t, full)

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


# --- Blocking ------------------------------------------------------------------------

func _block_tests(t: PlayerTuning, full: float) -> void:
	# Hold guard with nothing hitting it.
	await _setup_duel(false)
	Input.action_press("block")
	await _seconds(0.2)
	var st := player.stamina
	await _seconds(2.0)
	var drained := st - player.stamina
	_check_near("holding guard 2 s with no attacks drains (stamina)", drained, full * t.block_drain_per_second * 2.0, 0.6)
	_check_true("...and nothing regenerates while the guard is up", player._regen_cooldown > 0.0 or drained > 0.0)
	Input.action_release("block")
	await _frames(2)
	st = player.stamina
	await _seconds(t.block_release_regen_delay - 0.15)
	_check_true("after lowering the guard, regen waits %.1f s (%.1f -> %.1f)" % [t.block_release_regen_delay, st, player.stamina],
			player.stamina <= st + 0.01)
	await _seconds(0.5)
	_check_true("...then stamina comes back (%.1f)" % player.stamina, player.stamina > st + 1.0)

	# Impact costs on their own: blows straight into a held guard, no time passing between them.
	await _setup_duel(false)
	var mods: Dictionary = player.stats.class_data.passive_mods
	var class_mult: Variant = mods.get("block_stamina_mult")
	mods.erase("block_stamina_mult")  # the Vanguard's Shield-Born passive, put back below
	var spd := player.shield.stamina_per_damage if player.shield else 0.0
	if player.shield:
		player.shield.stamina_per_damage = t.block_shield_reference
	player.is_blocking = true
	player._block_started = -99.0  # long past the deflect window
	player.stamina = full
	var hit := _light_blow()
	var before := player.stamina
	player.receive_hit(hit)
	var one := before - player.stamina
	_check_near("one blocked light blow costs 12.5%% of max stamina", one, full * t.block_hit_stamina, 0.01)
	before = player.stamina
	player.receive_hit(hit)  # the same swing reported twice
	_check_near("...the same attack is never charged twice", before - player.stamina, 0.0, 0.001)
	for i in 6:
		player._clock += 0.5
		player.is_blocking = true
		player.receive_hit(_light_blow())
	_check_true("after 7 blocked blows some stamina is left (%.1f)" % player.stamina, player.stamina > 0.5)
	player._clock += 0.5
	player.is_blocking = true
	player.receive_hit(_light_blow())
	_check_near("8 blocked blows empty a full bar from impact costs alone", player.stamina, 0.0, 0.01)
	_check_true("...and the 8th breaks the guard (state %s)" % Player.State.keys()[player.state], player.state == Player.State.GUARD_BREAK)
	player._clock += 0.5
	var heavy := _light_blow()
	heavy.hit_stop = 0.12
	player._set_state(Player.State.MOVE)
	player.stamina = full
	player.is_blocking = true
	player.receive_hit(heavy)
	_check_near("a heavy blow on the guard costs more", full - player.stamina, full * t.block_hit_stamina * t.block_heavy_hit_mult, 0.01)
	if class_mult != null:
		mods["block_stamina_mult"] = class_mult
	if player.shield:
		player.shield.stamina_per_damage = spd
	player.is_blocking = false

	# The real thing: the Marauder's swing on a held guard, plus the steady drain on top.
	await _setup_duel(true)
	Input.action_press("block")
	await _seconds(0.6)
	st = player.stamina
	var hp := player.health
	await _force_attack(1)
	await _seconds(1.6)
	var spent := st - player.stamina
	var drain_part := full * t.block_drain_per_second * 1.6
	_check_true("a real blocked swing costs its impact + the hold drain (spent %.1f, drain alone %.1f, impact %.1f)" % [spent, drain_part, spent - drain_part],
			spent > drain_part + 4.0 and player.health >= hp - 1.0)
	Input.action_release("block")
	# A blow that misses (out of reach) costs nothing but the drain.
	await _setup_duel(true)
	enemy.global_position = Vector3(0, 0, -9.0)
	enemy._cooldown = 999.0
	Input.action_press("block")
	await _seconds(0.6)
	st = player.stamina
	await _force_attack(1)
	await _seconds(1.6)
	_check_near("a swing that misses only costs the hold drain", st - player.stamina, full * t.block_drain_per_second * 1.6, 0.6)
	Input.action_release("block")

	# Hold guard until the bar is empty: the guard drops by itself and can't come back up.
	await _setup_duel(false)
	player.stamina = 4.0
	Input.action_press("block")
	await _seconds(1.5)
	_check_true("guard drops on its own at 0 stamina (blocking %s, stamina %.1f)" % [player.is_blocking, player.stamina],
			not player.is_blocking and player.exhausted)
	await _seconds(0.3)
	_check_true("...and can't be held up while exhausted", not player.is_blocking)
	Input.action_release("block")
	await _seconds(1.5)


func _light_blow() -> HitInfo:
	var h := enemy.make_hit(0)
	h.origin = player.global_position + player.model.forward() * 2.0
	h.unblockable = false
	h.parryable = true
	h.hit_stop = 0.05
	return h


# --- Dodge rolls -------------------------------------------------------------------

func _roll_tests(t: PlayerTuning, full: float) -> void:
	await _setup_duel(false)
	enemy.global_position = Vector3(40, 0, 40)
	player.stamina = full
	var after: Array[float] = []
	for i in 5:
		await _roll_once()
		after.append(player.stamina)
	_check_true("five rolls from full: %s" % str(after.map(func(v: float) -> int: return roundi(v))),
			absf(after[0] - (full - t.roll_stamina)) < 0.5 and after[4] <= 0.01)
	_check_true("a roll costs more than a blocked blow (%.1f vs %.1f)" % [t.roll_stamina, full * t.block_hit_stamina],
			t.roll_stamina > full * t.block_hit_stamina)
	var st := player.stamina
	player._buffer(&"roll")
	await _frames(3)
	_check_true("a 6th roll is refused (state %s)" % Player.State.keys()[player.state], player.state != Player.State.ROLL)
	_check_near("...and costs nothing", player.stamina, st, 0.01)
	# Not exhausted, but short of the cost: still refused, still free.
	await _seconds(2.5)
	player.stamina = t.roll_stamina - 3.0
	player.exhausted = false
	await _frames(1)
	st = player.stamina
	player._regen_cooldown = 5.0
	player._buffer(&"roll")
	await _frames(3)
	_check_true("a roll you can't afford doesn't start (%.0f stamina)" % st, player.state != Player.State.ROLL)
	_check_near("...and costs nothing", player.stamina, st, 0.01)
	# Regen pause after a roll.
	player.stamina = full * 0.5
	player._regen_cooldown = 0.0
	await _roll_once()
	st = player.stamina
	await _seconds(maxf(t.roll_regen_delay - t.roll_duration[0] - 0.15, 0.05))
	_check_true("regen waits after a roll (%.1f -> %.1f)" % [st, player.stamina], player.stamina <= st + 0.01)
	await _seconds(0.6)
	_check_true("...then comes back (%.1f)" % player.stamina, player.stamina > st)


func _roll_once() -> void:
	player._buffer(&"roll")
	for i in 30:
		await get_tree().physics_frame
		if player.state == Player.State.ROLL:
			break
	for i in 120:
		await get_tree().physics_frame
		if player.state != Player.State.ROLL:
			break


# --- Exhaustion and the HUD ------------------------------------------------------------

func _exhaustion_tests(t: PlayerTuning, full: float) -> void:
	await _setup_duel(false)
	enemy.global_position = Vector3(40, 0, 40)
	var bar: ResourceBar = hud.get(&"_stamina_bar")
	_check_true("stamina bar normal when stamina is available", not bar.is_exhausted())
	player._spend_stamina(full)
	await _frames(2)
	_check_true("at 0 the player is exhausted and the bar blinks green", player.exhausted and bar.is_exhausted())
	var t0: float = bar.get(&"_exhausted_t")
	await _seconds(0.3)
	_check_true("...the glow animates (pulse clock %.2f -> %.2f)" % [t0, bar.get(&"_exhausted_t")], bar.get(&"_exhausted_t") > t0)
	# Sprinting attacks and guard are refused while exhausted.
	Input.action_press("block")
	await _frames(3)
	_check_true("no guard while exhausted", not player.is_blocking)
	Input.action_release("block")
	var seen_below := -1.0
	var cleared_at := -1.0
	for i in 300:
		await get_tree().physics_frame
		if player.exhausted:
			seen_below = player.stamina
		elif cleared_at < 0.0:
			cleared_at = player.stamina
			break
	_check_true("exhaustion (and the blinking) ends at %.0f%% stamina (still on at %.1f, off at %.1f)" % [t.exhaustion_recover * 100.0, seen_below, cleared_at],
			not bar.is_exhausted() and seen_below < full * t.exhaustion_recover and cleared_at >= full * t.exhaustion_recover)
	await _seconds(3.0)
	_check_true("regeneration refills the bar (%.0f)" % player.stamina, player.stamina >= full - 0.01)


# --- Blocking movement -----------------------------------------------------------------

func _block_movement_tests(t: PlayerTuning) -> void:
	await _setup_duel(false)
	enemy.global_position = Vector3(40, 0, 40)
	player.global_position = Vector3(0, 0.05, 12)
	player.reset_physics_interpolation()
	var ref := t.block_speed_reference
	var speeds := {}
	for case in [["move_forward", t.block_forward_mult], ["move_back", t.block_back_mult], ["move_right", t.block_side_mult], ["move_left", t.block_side_mult]]:
		player.stamina = player.max_stamina()
		Input.action_press("block")
		Input.action_press(case[0])
		await _seconds(1.0)
		speeds[case[0]] = _speed()
		_check_near("guard up, %s speed (m/s)" % case[0], _speed(), ref * case[1], 0.2)
		_check_true("...holds the guard pose (%s)" % player.model.current_anim(), player.model.current_anim() == CharacterModel.ANIM_BLOCK)
		Input.action_release(case[0])
		Input.action_release("block")
		await _seconds(0.6)
	_check_true("strafing is the slowest guarded movement", speeds["move_right"] < speeds["move_back"] and speeds["move_back"] < speeds["move_forward"])
	var run_speed := 0.0
	Input.action_press("move_forward")
	await _seconds(1.0)
	run_speed = _speed()
	_check_true("guarded forward is slower than normal movement (%.2f vs %.2f)" % [speeds["move_forward"], run_speed], speeds["move_forward"] < run_speed - 1.0)
	# Releasing guard: speed climbs back smoothly (no jump in one frame).
	Input.action_press("block")
	await _seconds(1.0)
	Input.action_release("block")
	var worst_jump := 0.0
	var last := _speed()
	for i in 60:
		await get_tree().physics_frame
		worst_jump = maxf(worst_jump, absf(_speed() - last))
		last = _speed()
	var max_step := t.acceleration / Engine.physics_ticks_per_second
	_check_true("letting go of guard speeds back up smoothly (biggest frame step %.2f m/s, limit %.2f) to %.2f m/s" % [worst_jump, max_step * 1.5, last],
			worst_jump <= max_step * 1.5 and last > t.run_speed - 0.5)
	Input.action_release("move_forward")
	await _seconds(0.8)
	# No foot sliding with guard up, any direction: a planted foot stays put.
	for dirn in ["move_right", "move_forward", "move_back"]:
		await _feet_planted(dirn)


func _feet_planted(dirn: String) -> void:
	player.stamina = player.max_stamina()
	Input.action_press("block")
	Input.action_press(dirn)
	await _seconds(0.8)
	var skel: Skeleton3D = player.model.find_children("*", "Skeleton3D", true, false)[0]
	var samples: Array = []
	var record := func() -> void:
		samples.append([player.model._steps.phase,
				skel.global_transform * skel.get_bone_global_pose(skel.find_bone("foot_l")).origin,
				skel.global_transform * skel.get_bone_global_pose(skel.find_bone("foot_r")).origin])
	skel.skeleton_updated.connect(record)
	await _seconds(1.2)
	skel.skeleton_updated.disconnect(record)
	var worst := 0.0
	for leg in 2:
		var anchor := Vector3.INF
		for s in samples:
			var q := fposmod(s[0] + (0.0 if leg == 0 else 0.5), 1.0)
			if q > 0.55 and q < 0.95:
				if anchor == Vector3.INF:
					anchor = s[1 + leg]
				worst = maxf(worst, _flat(s[1 + leg] - anchor).length())
			else:
				anchor = Vector3.INF
	_check_true("guard up %s: feet step (weight %.2f), planted foot drift %.3f m" % [dirn, player.model._steps.weight, worst],
			player.model._steps.weight > 0.9 and worst < 0.03)
	Input.action_release(dirn)
	Input.action_release("block")
	await _seconds(0.6)


# --- Sprinting attacks -----------------------------------------------------------------

func _sprint_attack_tests(t: PlayerTuning, full: float) -> void:
	var w := player.weapon
	var light := w.running_attack
	var heavy := w.move(&"running_heavy")
	var crit := w.crit_chance
	w.crit_chance = -10.0
	# Damage on the same enemy, same conditions.
	await _setup_duel(false)
	var light_dmg := _damage_of(light)
	var heavy_dmg := _damage_of(heavy)
	_check_true("sprinting heavy hits harder than sprinting light (%.0f vs %.0f)" % [heavy_dmg, light_dmg], heavy_dmg > light_dmg * 1.3)
	_check_true("...with more balance damage and a stronger hit-stop (%.2f vs %.2f s)" % [heavy.hit_stop, light.hit_stop],
			heavy.poise_mult > light.poise_mult and heavy.hit_stop > light.hit_stop)
	_check_true("they are separate animations from each other and from the standing attacks (%s / %s)" % [light.anim, heavy.anim],
			light.anim != heavy.anim and light.anim != w.light_combo[0].anim and heavy.anim != w.heavy.anim)
	var light_blow := light.hit_start / (light.anim_speed * t.attack_speed)
	var heavy_blow := heavy.hit_start / (heavy.anim_speed * t.attack_speed)
	var light_rec := (light.end_time - light.hit_end) / (light.anim_speed * t.attack_speed)
	var heavy_rec := (heavy.end_time - heavy.hit_end) / (heavy.anim_speed * t.attack_speed)
	_check_true("light is faster to the blow (%.2f s vs %.2f s) and recovers sooner (%.2f s vs %.2f s)" % [light_blow, heavy_blow, light_rec, heavy_rec],
			light_blow < heavy_blow and light_rec < heavy_rec)

	for kind in ["light", "heavy"]:
		var a := light if kind == "light" else heavy
		await _setup_duel(false)
		enemy.global_position = Vector3(0, 0, -2.0)
		enemy._cooldown = 999.0
		player.global_position = Vector3(0, 0.05, 14.0)
		player.reset_physics_interpolation()
		Input.action_press("move_forward")
		Input.action_press("dodge_sprint")
		var reached := false
		for i in 240:
			await get_tree().physics_frame
			if player.global_position.z - enemy.global_position.z < (4.5 if kind == "light" else 5.0) and _speed() > t.sprint_attack_min_speed:
				reached = true
				break
		_check_true("%s: sprinted up to the Marauder at %.1f m/s" % [kind, _speed()], reached)
		var hp := enemy.health
		var st := player.stamina
		var base := w.heavy if kind == "heavy" else w.light_combo[0]
		var cost := base.stamina_cost * (t.sprint_heavy_stamina_mult if kind == "heavy" else t.sprint_light_stamina_mult)
		await _tap("heavy_attack" if kind == "heavy" else "light_attack")
		await _frames(2)
		_check_true("%s: pressing attack while sprinting starts the sprinting %s (%s)" % [kind, kind, player._attack.attack.display_name if player._attack.attack else "-"],
				player.state == Player.State.ATTACK and player._attack.attack == a and player._sprint_attack)
		_check_near("%s: stamina cost (weapon's basic cost × %.2f)" % [kind, t.sprint_heavy_stamina_mult if kind == "heavy" else t.sprint_light_stamina_mult],
				st - player.stamina, cost, 1.0)
		_check_true("%s: the run carries into the strike (%.1f m/s right after)" % [kind, _speed()], _speed() > 3.0)
		var hits := 0
		var last_hp := enemy.health
		var frames := 0
		while player.state == Player.State.ATTACK and frames < 200:
			await get_tree().physics_frame
			frames += 1
			if enemy.health < last_hp - 0.01:
				hits += 1
			last_hp = enemy.health
			if player._attack.past(a.hit_end + 0.05):
				# Mash attack through the recovery: nothing may cut it short or chain out of it.
				player._buffer(&"heavy" if frames % 2 == 0 else &"light")
		_check_true("%s: one hit lands on the Marauder (%d hit, %.0f damage)" % [kind, hits, hp - enemy.health], hits == 1 and enemy.health < hp)
		var span := frames / float(Engine.physics_ticks_per_second)
		var expect := (a.end_time) / (a.anim_speed * t.attack_speed)
		_check_true("%s: plays its whole recovery despite mashing (%.2f s, expected about %.2f s)" % [kind, span, expect], span >= expect - 0.1)
		# Straight after: still holding sprint, but no momentum and on cooldown, so no second sprinting attack.
		await _frames(1)
		await _tap("light_attack")
		await _frames(2)
		_check_true("%s: an instant second press is not another sprinting attack (%s)" % [kind, player._attack.attack.display_name],
				not player._sprint_attack)
		Input.action_release("dodge_sprint")
		Input.action_release("move_forward")
		await _seconds(1.5)

	# Not enough stamina: no sprinting attack and no cost.
	await _setup_duel(false)
	enemy.global_position = Vector3(40, 0, 40)
	player.global_position = Vector3(0, 0.05, 14.0)
	player.reset_physics_interpolation()
	Input.action_press("move_forward")
	Input.action_press("dodge_sprint")
	await _seconds(1.2)
	player.stamina = 8.0
	var st2 := player.stamina
	await _tap("heavy_attack")
	await _frames(2)
	_check_true("too little stamina: no sprinting heavy (state %s, stamina %.1f -> %.1f)" % [Player.State.keys()[player.state], st2, player.stamina],
			player.state != Player.State.ATTACK and player.stamina > st2 - 1.0)
	Input.action_release("dodge_sprint")
	Input.action_release("move_forward")
	w.crit_chance = crit
	await _seconds(1.0)


func _damage_of(a: AttackData) -> float:
	enemy.global_position = player.global_position + Vector3(0, 0, -1.8)
	enemy.reset_physics_interpolation()
	enemy.model.face_instantly(player.global_position - enemy.global_position)
	enemy.health = enemy.max_health
	enemy._poise = 9999.0
	var before := enemy.health
	player._land_hit(enemy, a, 0.0)
	return before - enemy.health


# --- Helpers ----------------------------------------------------------------------------

## Player and Marauder 2 m apart, both fresh. `enemy_close` false sends it far away.
func _setup_duel(enemy_close: bool) -> void:
	Input.action_release("block")
	player.respawn()
	await _frames(2)
	player.global_position = Vector3(0, 0.05, 0)
	player.model.face_instantly(Vector3.FORWARD)
	player.camera_rig.yaw = 0.0
	player.reset_physics_interpolation()
	player.stamina = player.max_stamina()
	player.health = player.max_health()
	player._regen_cooldown = 0.0
	enemy.reset_from_rest()
	enemy.global_position = Vector3(0, 0, -2.0) if enemy_close else Vector3(0, 0, -30.0)
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


func _speed() -> float:
	return Vector2(player.velocity.x, player.velocity.z).length()


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


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


func _check_near(label: String, value: float, expected: float, tolerance: float) -> void:
	_check_true("%s: %.2f (want %.2f ± %.2f)" % [label, value, expected, tolerance], absf(value - expected) <= tolerance)
