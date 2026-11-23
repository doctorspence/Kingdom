extends Node
## Automated check of the Gullet and Harl the Delver (GULLET_DESIGN.md): the
## way down, the fog gate, stance break, parry chip, phase 2 (he fights alone), group
## scaling, the kill flag and shortcut, loot, and the boss coming back on rest.
##   ... --headless --script res://tests/run.gd -- boss_check

var player: Player
var zone: Node
var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _boss() -> Enemy:
	for n in get_tree().get_nodes_in_group(&"bosses"):
		var e := n as Enemy
		if e and e.state != Enemy.State.DEAD and not e.is_queued_for_deletion():
			return e
	return null


func _hit(boss: Enemy, damage: float, poise: float) -> void:
	var h := HitInfo.new()
	h.damage = damage
	h.poise_damage = poise
	h.origin = boss.global_position + Vector3(0, 0, 3)
	h.attacker = player
	boss.receive_hit(h)


func _run() -> void:
	zone = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(zone)
	await _frames(40)
	player = get_tree().get_first_node_in_group(&"player") as Player
	await _seconds(0.5)

	# --- The way down ---------------------------------------------------------------------
	var door := zone.get_node("Places/GulletDoor") as CaveDoor
	door.interact(player)
	await _frames(3)
	await _seconds(1.0)
	_check("the quarry door takes you down into the cave (y %.1f)" % player.global_position.y,
			player.global_position.y < -30.0 and player.is_on_floor())
	var shrine := zone.get_node("Gullet/GulletShrine") as Shrine
	_check("the Gullet has its own shrine", shrine != null and shrine.shrine_id == &"gullet")
	var up := zone.get_node("Gullet/WayUp") as CaveDoor
	up.interact(player)
	await _seconds(0.6)
	_check("...and the way up takes you back to the surface", player.global_position.y > -10.0)

	# --- The boss and his gate --------------------------------------------------------------
	var boss := _boss()
	_check("Harl is waiting in the deep chamber", boss != null and boss.data.id == &"enemy_harl"
			and (zone.get_node("Gullet/BossRoom") as BossRoom).contains(boss.global_position))
	var gate := zone.get_node("Gullet/FogGate") as FogGate
	var back := zone.get_node("Gullet/ShortcutGate") as ShortcutGate
	_check("the shortcut is shut until he dies", not back.is_open())
	_check("he has 1100 health alone (boss scaling)", is_equal_approx(boss.max_health, 1100.0))
	var adds := get_tree().get_nodes_in_group(&"enemies").filter(func(n: Node) -> bool: return (n as Enemy).data.id == &"enemy_candle_acolyte")
	_check("he fights alone: no adds (%d acolytes)" % adds.size(), adds.is_empty() and boss.data.adds_scene == null)

	player.global_position = gate.global_position + gate.global_transform.basis.z * 1.5 + Vector3(0, 0.3, 0)
	await _frames(3)
	var side_before := gate.to_local(player.global_position).z
	gate.interact(player)
	_check("the mist lets you through into the chamber", gate.to_local(player.global_position).z < -1.0 and side_before > 0.0)

	# --- The fight: engage, seal ---------------------------------------------------------------
	boss._cooldown = 1.0e9  # no swinging while we test his rules
	player.global_position = boss.global_position + Vector3(14, 0.3, 0)
	await _seconds(1.5)
	_check("he sees you and the fight begins", boss.net_engaged and boss.state != Enemy.State.IDLE)
	await _frames(5)
	_check("the fog gate seals while he fights", gate.is_sealed())

	# --- His moves ---------------------------------------------------------------------------------
	var names := boss.data.attacks.map(func(a: AttackData) -> String: return a.display_name)
	_check("phase 1 moves: sweep, heavy strike, slam, shard, grip, charge, eruption %s" % str(names), boss.data.attacks.size() == 7)
	var shard: AttackData = boss.data.attacks[3]
	_check("Black Shard is blockable, slows, and only used from a distance", not shard.unblockable and shard.slow > 0.0 and shard.min_use_distance > 3.0)
	_check("Ground Slam is red (unblockable)", boss.data.attacks[2].unblockable)
	_check("Heavy Strike is parryable with a long wind-up", boss.data.attacks[1].parryable and boss.data.attacks[1].windup_speed_mult < 0.4)

	# --- The reworked fight: Delver's Charge and Stone Eruption ---------------------------------------
	var charge: AttackData = boss.data.attacks[5]
	var burst: AttackData = boss.data.attacks[6]
	_check("Delver's Charge closes the gap (lunge %.0f m, used from %.0f m+) and can be parried" % [charge.lunge_distance, charge.min_use_distance],
			charge.lunge_distance >= 6.0 and charge.min_use_distance >= 4.0 and charge.parryable)
	_check("Stone Eruption deals no melee damage but marks rings (%d wave, phase 2: %d)" % [burst.burst_waves, boss.data.phase2_attacks[6].burst_waves],
			burst.burst_radius > 1.5 and burst.base_damage == 0.0 and boss.data.phase2_attacks[6].burst_waves >= 3)
	boss._set_state(Enemy.State.CHASE)
	boss.target = player
	player.global_position = boss.global_position + Vector3(6, 0.3, 0)
	await _frames(3)
	var health_before := player.health
	boss.start_attack(6)
	await _seconds(1.0)
	var rings := get_tree().get_nodes_in_group(&"player").size()
	var found_bursts := 0
	for n in get_tree().root.find_children("*", "Node3D", true, false):
		if n is StoneBurst:
			found_bursts += 1
	_check("a ring of black stone is marked under the player (%d ring)" % found_bursts, found_bursts >= rings and player.health == health_before)
	await _seconds(burst.burst_delay + 0.4)
	_check("...and the spikes hurt a player who stays in it (%.0f -> %.0f)" % [health_before, player.health], player.health < health_before)
	boss._set_state(Enemy.State.CHASE)
	boss._cooldown = 1.0e9
	player.health = health_before

	# --- Poise: stance break, parry chip ----------------------------------------------------------
	boss._set_state(Enemy.State.CHASE)
	boss._poise = boss.max_poise
	_hit(boss, 5.0, 100.0)
	_check("ordinary hits don't stagger him", boss.state != Enemy.State.STAGGER and boss.state != Enemy.State.PARRIED)
	_hit(boss, 5.0, 400.0)
	_check("breaking his poise makes him kneel (stance break)", boss.state == Enemy.State.PARRIED and boss.can_be_riposted())
	boss._set_state(Enemy.State.CHASE)
	boss._poise = boss.max_poise
	boss.start_attack(0)
	boss._on_hit_result(HitInfo.Result.PARRIED)
	_check("a parry chips his poise instead of staggering him", boss.state == Enemy.State.ATTACK and boss._poise < boss.max_poise)

	# --- Corrupted Grip -----------------------------------------------------------------------------
	boss._set_state(Enemy.State.CHASE)
	boss._grip_ready = false
	var plain := boss.make_hit(0).damage
	boss._grip_ready = true
	boss.start_attack(0)
	var charged := boss.make_hit(0).damage
	_check("after Corrupted Grip his next attack hits 50%% harder (%.0f -> %.0f)" % [plain, charged], is_equal_approx(charged, plain * 1.5) and not boss._grip_ready)
	boss._set_state(Enemy.State.CHASE)
	boss._grip_active = false
	boss._grip_ready = true
	boss._stance_break()
	_check("breaking his poise cancels the grip", not boss._grip_ready and not boss._grip_active)

	# --- Target switching only at the start of an attack ---------------------------------------------
	boss._set_state(Enemy.State.CHASE)
	boss.target = null
	boss.threat.clear()
	boss.add_threat(player.get_multiplayer_authority(), 100.0)
	boss._boss_retarget()
	_check("he picks the top of the threat table as an attack starts", boss.target == player)

	# --- Phase 2 ------------------------------------------------------------------------------------------
	boss._set_state(Enemy.State.CHASE)
	_hit(boss, boss.max_health * 0.3, 1.0)
	_check("above half health he is still in phase 1", boss._phase == 1)
	_hit(boss, boss.max_health * 0.3, 1.0)
	_check("below half health he kneels to the stone (phase 2)", boss._phase == 2 and boss.state == Enemy.State.CALL)
	await _seconds(boss.data.call_time + 0.5)
	_check("...then fights on with new moves (Desperate Assault, shard spread)", boss._attacks() == boss.data.phase2_attacks
			and boss._attacks().any(func(a: AttackData) -> bool: return a.extra_hits.size() >= 2)
			and boss.data.phase2_attacks[3].arc_degrees > shard.arc_degrees * 1.5)
	_check("...25% faster", boss.effects.move_mult() > 1.2)
	_check("...and still no adds", boss._adds.is_empty())

	# --- Kill: flag, shortcut, loot ----------------------------------------------------------------------------
	var drops_before: int = Loot._host_drops.size()
	_hit(boss, boss.max_health, 1.0)
	await _seconds(1.0)
	_check("his death sets the first-kill flag", WorldState.get_flag(&"gullet_harl_killed") == true)
	_check("...which opens the shortcut for good", back.is_open())
	_check("...and unseals the fog gate", not gate.is_sealed())
	_check("he drops his guaranteed potions", JSON.stringify(Loot._host_drops.values()).contains("item_health_potion") and Loot._host_drops.size() > drops_before)

	# --- Death in the arena puts your pile at the door ----------------------------------------------------------
	var room := zone.get_node("Gullet/BossRoom") as BossRoom
	player.global_position = room.global_position + Vector3(0, 0.3, 0)
	_check("dying in the chamber sends your pile to the door", player._pile_position().distance_to(room.pile_point()) < 0.1
			and room.pile_point().z < gate.global_position.z)

	# --- Back on rest, scaled to the arena ----------------------------------------------------------------------------
	player.global_position = shrine.global_position + Vector3(2, 0.3, 0)
	await _seconds(0.5)
	shrine.rest(player)
	await _seconds(1.0)
	var again := _boss()
	_check("resting at the shrine brings Harl back", again != null and again != boss and again.health == again.max_health)
	_check("...but the shortcut stays open", back.is_open())
	again._scale_to(3)
	_check("three players in the arena: health x2.6 (%.0f)" % again.max_health, is_equal_approx(again.max_health, 2860.0))

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await _frames(ceili(s * Engine.physics_ticks_per_second))


func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", label])
	if not ok:
		failures += 1
