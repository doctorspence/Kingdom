extends "res://tests/class_check.gd"
## Arcane Surge, in one process. Run:
##   ... --headless --path . --script res://tests/run.gd -- surge_check
## A level 1 Mystic (Intellect 15, so ability power 1.15) casts at enemies that are held
## still (or moved by the check) and every damage number is compared with
## base x ability_power x multipliers. Marauders have no shield block, are made to face the
## caster in the CHASE state (so no sneak or from-behind bonus) and cannot attack.
## The two-player version (a CLIENT Mystic) is net_surge_check.

const ENEMY_SCENE := "res://game/enemies/marauder.tscn"

var ap := 1.0
var primary := 0.0
var secondary := 0.0
var ability: AbilityData
var extras: Array[Enemy] = []
var pool: Array[Enemy] = []
var pins := {}  # enemy -> Vector3 (held there every physics frame)
var movers := {}  # enemy -> velocity (m/s), added to its pin every frame
var released := 0
var run_vel := Vector3.ZERO
var ended: Array[bool] = []
var at_release := {}  # what the caster looked like the moment it released
var _scene: Node
var _walls: Array[Node] = []


func _run() -> void:
	_scene = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(_scene)
	await _frames(20)
	player = get_tree().get_first_node_in_group(&"player") as Player
	enemy = _scene.get_node("Enemies/Marauder") as Enemy
	enemy2 = _scene.get_node("Enemies/Marauder2") as Enemy
	pool = [enemy, enemy2]
	for i in 3:
		var e: Enemy = (load(ENEMY_SCENE) as PackedScene).instantiate()
		_scene.get_node("Enemies").add_child(e)
		pool.append(e)
	await _frames(5)
	await _setup("class_lamplighter", 1)
	ability = player.stats.class_data.abilities[0]
	ap = player.stats.ability_power()
	primary = ability.power * ap
	secondary = ability.value * ap
	player.caster.surge_released.connect(_on_released)
	player.caster.surge_charge_ended.connect(func(r: bool) -> void: ended.append(r))
	print("Mystic level 1: ability power %.3f -> Surge primary %.3f, secondary %.3f" % [ap, primary, secondary])
	_check("data: 55 / 35 base, 36 m, 6 m wide +0.2 m per m, 0.333 s cast, 20 Mana, 4 s, 3 targets, +15% Hexed, pays on release",
			ability.power == 55.0 and ability.value == 35.0 and ability.ability_range == 36.0 and ability.cost == 20.0
			and ability.radius == 6.0 and absf(ability.spread - 0.2) < 0.0001 and absf(ability.cast_time - 0.333) < 0.001
			and ability.cooldown == 4.0 and ability.max_targets == 3 and absf(ability.hexed_bonus - 0.15) < 0.0001
			and ability.pay_on_release and ability.unlock_level == 1)

	# --- Damage cases ------------------------------------------------------------------
	var d := await _cast_at([Vector3(0, 0, -6)])
	_dmg("1 enemy: primary", d[0], primary)

	d = await _cast_at([Vector3(0, 0, -4), Vector3(0, 0, -8)])
	_dmg("2 enemies: nearest primary", d[0], primary)
	_dmg("2 enemies: far one secondary", d[1], secondary)

	d = await _cast_at([Vector3(0, 0, -9), Vector3(0, 0, -3), Vector3(0, 0, -6)])
	_dmg("3 enemies (listed far to near): nearest primary", d[1], primary)
	_dmg("3 enemies: middle secondary", d[2], secondary)
	_dmg("3 enemies: farthest secondary", d[0], secondary)

	d = await _cast_at([Vector3(0, 0, -11), Vector3(0, 0, -9), Vector3(0, 0, -7), Vector3(0, 0, -5), Vector3(0, 0, -3)])
	_dmg("5 enemies: nearest (3 m) primary", d[4], primary)
	_dmg("5 enemies: 2nd (5 m) secondary", d[3], secondary)
	_dmg("5 enemies: 3rd (7 m) secondary", d[2], secondary)
	_dmg("5 enemies: 4th (9 m) untouched", d[1], 0.0)
	_dmg("5 enemies: 5th (11 m) untouched", d[0], 0.0)

	await _hexed_case()

	# --- Geometry ----------------------------------------------------------------------
	_add_wall(Vector3(0, 1.5, -5.5), Vector3(8, 3, 0.5))
	d = await _cast_at([Vector3(0, 0, -8)])
	_dmg("behind a wall: not hit", d[0], 0.0)
	await _clear_walls()
	d = await _cast_at([Vector3(0, 0, -8)])
	_dmg("same spot, wall gone: hit", d[0], primary)

	# A straight-ahead decoy keeps the aim dead ahead, so the sideways offsets are the test.
	# Half-width at distance a = (6 + 0.2 a) / 2, plus 0.4 m for the body.
	# At 5 m: 3.5 + 0.4 = 3.9 m. At 25 m: 5.5 + 0.4 = 5.9 m.
	d = await _cast_at([Vector3(0, 0, -4), Vector3(4.3, 0, -5), Vector3(3.5, 0, -5.5)])
	_dmg("width: decoy ahead is primary", d[0], primary)
	_dmg("width: 4.3 m to the side at 5 m (outside 3.9) not hit", d[1], 0.0)
	_dmg("width: 3.5 m to the side at 5.5 m hit (secondary)", d[2], secondary)
	# The far cases need open ground: the arena has a wall about 14 m ahead of its centre.
	var lane := _open_lane()
	_check("found a clear 40 m lane for the far cases (%s)" % lane, lane != Vector3.INF)
	if lane != Vector3.INF:
		d = await _cast_at([Vector3(0, 0, -4), Vector3(-5.5, 0, -25), Vector3(6.5, 0, -25)], Vector3.ZERO, lane)
		_dmg("spread: 5.5 m to the side at 25 m hit (the wave has widened)", d[1], secondary)
		_dmg("spread: 6.5 m to the side at 25 m (outside 5.9) not hit", d[2], 0.0)

		d = await _cast_at([Vector3(0, 0, -35)], Vector3.ZERO, lane)
		_dmg("range: 35 m is hit", d[0], primary)
		d = await _cast_at([Vector3(0, 0, -38)], Vector3.ZERO, lane)
		_dmg("range: 38 m is not hit", d[0], 0.0)
		d = await _cast_at([Vector3(0, 0, -4), Vector3(0, 0, -38)], Vector3.ZERO, lane)
		_dmg("range: 38 m not hit even with a target ahead (primary on the near one)", d[1], 0.0)

	# Same enemy never twice: it runs along with the wave (24 m/s), right in front of it.
	d = await _cast_at([Vector3(0, 0, -1.0)], Vector3(0, 0, -24.0))
	_dmg("an enemy moving with the wave is hit once", d[0], primary)
	movers.clear()
	d = await _cast_at([Vector3(0, 0, -2.0)], Vector3(0, 0, -9.0))
	_dmg("an enemy running ahead slower than the wave is hit once", d[0], primary)

	# --- Cost, cooldown, interruption ----------------------------------------------------
	await _cost_and_cooldown()
	await _mana_cases()
	await _interrupt_cases()
	await _melee_comparison()

	_unhold()
	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


# --- Helpers -----------------------------------------------------------------------------

func _on_released(from: Vector3, dir: Vector3, travel: float, _width: float) -> void:
	print("   (wave from %s toward %s, travels %.1f m)" % [from, dir, travel])
	released += 1
	at_release = {"mana": player.caster.resource, "cd": player.caster.cooldown_left(ability), "t": Time.get_ticks_msec()}
	# Enemies that move with the wave start moving now.
	if run_vel != Vector3.ZERO:
		movers[pool[0]] = run_vel


func _dmg(label: String, got: float, want: float) -> void:
	print("   %s -> %.3f (want %.3f)" % [label, got, want])
	_check("%s (%.2f)" % [label, got], absf(got - want) < 0.01)


func _physics_process(delta: float) -> void:
	for e in pins.keys():
		if not is_instance_valid(e):
			continue
		var v: Vector3 = movers.get(e, Vector3.ZERO)
		pins[e] += v * delta
		e.global_position = pins[e]
		e.velocity = Vector3.ZERO
		e._cooldown = 999.0
		e._spawn.origin = pins[e]
		if e.state == Enemy.State.IDLE or e.state == Enemy.State.RETURN:
			e._set_state(Enemy.State.CHASE)
		e.target = player


func _unhold() -> void:
	pins.clear()
	movers.clear()


## Put the pool's enemies at these spots (the rest far away), cast, and return the health
## each lost. `run` makes the first enemy run with the wave from the moment of release.
## A spot on open ground with nothing solid for 42 m toward -Z across a 16 m wide lane.
func _open_lane() -> Vector3:
	var space := player.get_world_3d().direct_space_state
	for x in [0.0, -40.0, 40.0, -60.0, 60.0, -80.0, 80.0]:
		for z in [0.0, 40.0, 60.0, 80.0, -40.0]:
			var clear := true
			for side in [-8.0, -4.0, 0.0, 4.0, 8.0]:
				var from := Vector3(x + side, 1.3, z + 1.0)
				var q := PhysicsRayQueryParameters3D.create(from, from + Vector3(0, 0, -43.0), 1)
				q.exclude = [player.get_rid()]
				if not space.intersect_ray(q).is_empty():
					clear = false
					break
			# ...and ground under the far end (the enemies need a floor).
			var down := PhysicsRayQueryParameters3D.create(Vector3(x, 3.0, z - 38.0), Vector3(x, -3.0, z - 38.0), 1)
			if clear and not space.intersect_ray(down).is_empty():
				return Vector3(x, 0.0, z)
	return Vector3.INF


func _cast_at(spots: Array, run := Vector3.ZERO, base := Vector3.ZERO) -> Array:
	await _setup("class_lamplighter", 1)
	if base != Vector3.ZERO:
		player.global_position = base + Vector3(0, 0.05, 0)
		player.reset_physics_interpolation()
		var moved: Array = []
		for s in spots:
			moved.append(s + base)
		spots = moved
		await _frames(2)
	run_vel = run
	released = 0
	ended.clear()
	pins.clear()
	movers.clear()
	for i in pool.size():
		var e := pool[i]
		e.reset_from_rest()
		e.effects.clear_all()
		var at: Vector3 = spots[i] if i < spots.size() else Vector3(70 + i * 3, 0, 70)
		e.global_position = at
		e.model.face_instantly(Vector3.BACK)
		e.reset_physics_interpolation()
		e.target = player
		e._set_state(Enemy.State.CHASE)
		pins[e] = at
	await _frames(6)
	var before: Array[float] = []
	for e in pool:
		before.append(e.health)
	player.caster.try_use(0)
	await _seconds(2.6)  # 0.33 s cast + 36 m at 24 m/s
	var out: Array = []
	for i in spots.size():
		out.append(before[i] - pool[i].health)
	movers.clear()
	run_vel = Vector3.ZERO
	return out


func _place_pool(spots: Array) -> void:
	pins.clear()
	movers.clear()
	for i in pool.size():
		var e := pool[i]
		e.reset_from_rest()
		e.effects.clear_all()
		var at: Vector3 = spots[i] if i < spots.size() else Vector3(70 + i * 3, 0, 70)
		e.global_position = at
		e.model.face_instantly(Vector3.BACK)
		e.reset_physics_interpolation()
		e.target = player
		e._set_state(Enemy.State.CHASE)
		pins[e] = at


func _hexed_case() -> void:
	# A Hexed enemy in front and a Hexed one behind it: Hex x1.2, Surge bonus x1.15, once each.
	await _setup("class_lamplighter", 1)
	released = 0
	_place_pool([Vector3(0, 0, -4), Vector3(0, 0, -8)])
	for i in 2:
		pool[i].apply_effect(&"hex", 12.0, {"damage_dealt": 0.75, "damage_taken": 1.2, "label": "Hexed"})
	await _frames(6)
	var h0 := pool[0].health
	var h1 := pool[1].health
	player.caster.try_use(0)
	await _seconds(2.0)
	_dmg("Hexed primary: x1.2 (Hex) x1.15 (Surge)", h0 - pool[0].health, primary * 1.2 * 1.15)
	_dmg("Hexed secondary: x1.2 x1.15", h1 - pool[1].health, secondary * 1.2 * 1.15)
	# The same enemy without Hex takes the plain number (the bonus is Hex-gated).
	var d := await _cast_at([Vector3(0, 0, -6)])
	_dmg("Same kind of enemy, not Hexed: plain primary", d[0], primary)


func _add_wall(at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	_scene.add_child(body)
	body.global_position = at
	_walls.append(body)


func _clear_walls() -> void:
	for w in _walls:
		w.queue_free()
	_walls.clear()
	await _frames(2)


# --- Cost, cooldown ---------------------------------------------------------------------

func _cost_and_cooldown() -> void:
	await _setup("class_lamplighter", 1)
	released = 0
	at_release.clear()
	_place_pool([Vector3(0, 0, -6)])
	await _frames(6)
	var start := player.caster.resource
	_check("channel start: Mana full (%.1f)" % start, absf(start - player.stats.resource_max()) < 0.01)
	player.caster.try_use(0)
	await _seconds(0.2)
	_check("channelling: nothing paid, no cooldown yet (Mana %.1f)" % player.caster.resource,
			absf(player.caster.resource - start) < 0.01 and player.caster.cooldown_left(ability) <= 0.0 and released == 0)
	await _seconds(0.3)
	_check("released once", released == 1)
	_check("success costs exactly 20 Mana (%.3f -> %.3f)" % [start, float(at_release.get("mana", -1.0))],
			absf(float(at_release.get("mana", -1.0)) - (start - 20.0)) < 0.001)
	_check("success sets a 4.0 s cooldown (%.3f)" % float(at_release.get("cd", -1.0)),
			absf(float(at_release.get("cd", -1.0)) - 4.0) < 0.001)
	# While the cooldown runs it is refused and free.
	await _seconds(1.0)
	var mana_now := player.caster.resource
	var cd_now := player.caster.cooldown_left(ability)
	_check("during the cooldown (%.1f s left) it is refused" % cd_now, cd_now > 1.5 and not player.caster.try_use(0))
	_check("a refused use costs nothing and starts nothing", absf(player.caster.resource - mana_now) < 0.01 and player.state == Player.State.MOVE)
	await _seconds(cd_now + 0.1)
	_check("after the cooldown it works again", player.caster.try_use(0))
	await _seconds(0.3)
	player._stagger(0.3)
	await _seconds(1.0)


func _mana_cases() -> void:
	await _setup("class_lamplighter", 1)
	released = 0
	ended.clear()
	player.caster.resource = 19.0
	_check("19 Mana: refused", not player.caster.try_use(0))
	_check("refused: Mana untouched (%.2f), no cooldown, no channel" % player.caster.resource,
			absf(player.caster.resource - 19.0) < 0.01 and player.caster.cooldown_left(ability) <= 0.0 and player.state == Player.State.MOVE and released == 0)
	player.caster.resource = 20.0
	_check("exactly 20 Mana: allowed to start", player.caster.try_use(0))
	await _seconds(1.5)
	_check("exactly 20 Mana: fires and leaves about 0 (%.2f)" % player.caster.resource, released == 1 and player.caster.resource < 8.0)  # 20 - 20 = 0, then about 3 Mana/s regen
	# Mana spent by something else mid-channel: it fizzles, free.
	await _setup("class_lamplighter", 1)
	released = 0
	ended.clear()
	player.caster.try_use(0)
	await _seconds(0.15)
	player.caster.resource = 5.0
	await _seconds(1.6)
	_check("Mana gone before the release: no wave, no cooldown, charge ended unreleased (Mana %.1f)" % player.caster.resource,
			released == 0 and player.caster.resource >= 5.0 and player.caster.resource < 11.0
			and player.caster.cooldown_left(ability) <= 0.0 and ended == [false])


func _interrupt_cases() -> void:
	for kind in ["stagger", "roll", "down"]:
		var d := await _interrupted(kind)
		_check("%s mid-channel: no wave, no damage, Mana and cooldown untouched (%s)" % [kind, d], d.begins_with("ok"))


func _interrupted(kind: String) -> String:
	await _setup("class_lamplighter", 1)
	released = 0
	ended.clear()
	_place_pool([Vector3(0, 0, -6)])
	await _frames(6)
	var e := pool[0]
	var hp := e.health
	var mana := player.caster.resource
	player.caster.try_use(0)
	await _seconds(0.15)
	match kind:
		"stagger":
			player._stagger(0.5)
		"roll":
			player._buffer(&"roll")
		"down":
			player._go_down()
	await _seconds(2.2)
	var waves := 0
	for n in CombatFx.world().get_children():
		if n.get_script() == load("res://game/classes/arcane_surge_wave.gd"):
			waves += 1
	var ok := released == 0 and e.health == hp and absf(player.caster.resource - mana) < 0.01 \
			and player.caster.cooldown_left(ability) <= 0.0 and ended == [false] and waves == 0
	var note := "released %d, hp %.1f/%.1f, Mana %.2f/%.2f, cd %.2f, ended %s, waves %d" % [released, e.health, hp,
			player.caster.resource, mana, player.caster.cooldown_left(ability), str(ended), waves]
	if kind == "down":
		player.respawn()
	return ("ok " if ok else "BAD ") + note


# --- Melee comparison -----------------------------------------------------------------

func _melee_comparison() -> void:
	await _setup("class_lamplighter", 1)
	_place_pool([Vector3(0, 0, -1.6)])
	await _frames(6)
	var crit_was := player.weapon.crit_chance
	player.weapon.crit_chance = -10.0  # a random crit would spoil the comparison
	var e := pool[0]
	var hp := e.health
	await _tap("light_attack")
	await _seconds(1.2)
	player.weapon.crit_chance = crit_was
	var melee := hp - e.health
	print("MELEE COMPARISON (level 1 Mystic, light swing with the starting weapon): swing %.2f | Surge primary %.2f (x%.2f) | secondary %.2f (x%.2f)"
			% [melee, primary, primary / maxf(melee, 0.001), secondary, secondary / maxf(melee, 0.001)])
	_check("melee light swing landed (%.2f)" % melee, melee > 0.0)
	_check("Surge primary is a bigger blow than a staff swing", primary > melee)
