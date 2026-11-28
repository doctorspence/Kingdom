extends Node
## Arcane Surge over the network: a host and a joining player ("a", a Mystic), both on this PC.
##   ... --script res://tests/run.gd -- net_surge_check host
##   ... --script res://tests/run.gd -- net_surge_check a
## (tests/run_net_check.ps1 runs it as part 3.) The CLIENT casts at enemies the HOST owns, with
## the HOST's own player standing in the lane. Cases, each printed as "RESULT <role> <name>=PASS|FAIL":
##   host: the first enemy lost exactly primary damage and the second exactly secondary damage
##         (once each), the host's own player in the lane lost nothing, the host saw the channel
##         begin on the client's player, a non-owned wave spawn, and the channel end as released
##   client: Mana and cooldown changed only at the release (exactly -20 Mana, 4.0 s cooldown)
##   second cast, broken by a stagger mid-channel: no damage, no release, the host sees the
##         channel end unreleased, and the client's Mana and cooldown are untouched.

enum Phase { WAIT, CAST, BROKEN, END }
const LENGTH := {Phase.WAIT: 3.0, Phase.CAST: 5.0, Phase.BROKEN: 5.0, Phase.END: 1.5}
const SPOT := Vector3(30, 0, -30)  # open ground, away from the arena's walls
const WAVE := "res://game/classes/arcane_surge_wave.gd"

var role := "host"
var me: Player
var started := false
var phase := Phase.WAIT
var phase_t := 0.0
var _done := {}
var enemies: Array[Enemy] = []
var _ap := 1.15  # the client's ability power (reported by the client)
var _hp := {}
# Host: what it saw happen to the client's player.
var _begun := 0
var _released := 0
var _ended: Array[bool] = []
var _charge_seen := false
var _wave_copy_seen := false
# Client: what its own caster showed.
var _c_released := 0
var _c_mana_at_release := -1.0
var _c_cd_at_release := -1.0


func _init() -> void:
	name = "NetSurgeCheck"  # the same path on both machines


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	role = args[1] if args.size() > 1 else "host"
	Net.player_name = "Host" if role == "host" else "Alda"
	if role == "host":
		Net.host_game()
	else:
		Net.character = {"class": &"class_lamplighter"}
		Net.join_game("127.0.0.1")
	get_tree().create_timer(70.0).timeout.connect(func() -> void:
		print("RESULT %s timeout=true" % role)
		get_tree().quit(3))


func _physics_process(delta: float) -> void:
	if not started:
		if get_tree().get_nodes_in_group(&"player").size() >= 2:
			started = true
			me = get_tree().get_first_node_in_group(&"local_player") as Player
			print("RESULT %s players=2" % role)
			if role == "host":
				enemies = [get_tree().current_scene.get_node("Enemies/Marauder") as Enemy,
						get_tree().current_scene.get_node("Enemies/Marauder2") as Enemy]
				_enter(Phase.WAIT)
			else:
				me.caster.surge_released.connect(_client_released)
		return
	phase_t += delta
	if role == "host":
		_host_step()
	else:
		_client_step()


@rpc("authority", "call_remote", "reliable")
func _set_phase(p: int) -> void:
	phase = p as Phase
	phase_t = 0.0
	_done.clear()


func _enter(p: Phase) -> void:
	_set_phase(p)
	_set_phase.rpc(p)
	if role == "host":
		_enter_host(p)


@rpc("any_peer", "call_remote", "reliable")
func _client_info(ap: float) -> void:
	_ap = ap


func _res(label: String, ok: bool, detail: String) -> void:
	print("RESULT %s %s=%s %s" % [role, label, "PASS" if ok else "FAIL", detail])


func _at(time: float, action: Callable) -> void:
	if phase_t >= time and not _done.has(time):
		_done[time] = true
		action.call()


func _friend() -> Player:
	for x in get_tree().get_nodes_in_group(&"player"):
		if (x as Player).player_name == "Alda":
			return x as Player
	return null


# --- Host -------------------------------------------------------------------------------

func _spots() -> Array[Vector3]:
	return [SPOT + Vector3(0, 0, -5.0), SPOT + Vector3(0, 0, -9.0)]


func _pin_all() -> void:
	var f := _friend()
	var spots := _spots()
	for i in enemies.size():
		var e := enemies[i]
		e.global_position = spots[i]
		e.velocity = Vector3.ZERO
		e._spawn.origin = spots[i]
		e._cooldown = 999.0
		if e.state == Enemy.State.IDLE or e.state == Enemy.State.RETURN:
			e._set_state(Enemy.State.CHASE)
		if f:
			e.target = f
	# The host's own player stands in the wave's lane (nothing may hurt it).
	me.global_position = SPOT + Vector3(0.8, 0.05, -7.0)
	me.velocity = Vector3.ZERO


func _enter_host(p: Phase) -> void:
	if p == Phase.CAST or p == Phase.BROKEN:
		var f := _friend()
		var spots := _spots()
		for i in enemies.size():
			var e := enemies[i]
			e.reset_from_rest()
			e.global_position = spots[i]
			e.model.face_instantly(Vector3.BACK)
			e.effects.clear_all()
			e._set_state(Enemy.State.CHASE)
			if f:
				e.target = f
			_hp[i] = e.health
		_hp["me"] = me.health
		_begun = 0
		_released = 0
		_ended.clear()
		_charge_seen = false
		_wave_copy_seen = false
		if f:
			if not f.caster.surge_charge_started.is_connected(_host_begin):
				f.caster.surge_charge_started.connect(_host_begin)
				f.caster.surge_charge_ended.connect(func(r: bool) -> void: _ended.append(r))
				f.caster.surge_released.connect(_host_released)
	elif p == Phase.END:
		print("RESULT host surge_done=true")


func _host_begin(_a: AbilityData) -> void:
	_begun += 1
	# The charge node is made by the caster's own handler; check it a moment later.
	get_tree().create_timer(0.1).timeout.connect(func() -> void:  # before the 0.33 s release
		var f := _friend()
		if f and is_instance_valid(f.caster._charge_fx):
			_charge_seen = true)


func _host_released(_from: Vector3, _dir: Vector3, _travel: float, _width: float) -> void:
	_released += 1
	for n in CombatFx.world().get_children():
		if n.get_script() == load(WAVE) and not n.get("owned"):
			_wave_copy_seen = true


func _host_step() -> void:
	var f := _friend()
	if f == null and phase != Phase.END:
		return
	if phase != Phase.END:
		_pin_all()
	_at(LENGTH[phase] - 0.2, _host_report)
	if phase_t >= LENGTH[phase]:
		if phase == Phase.END:
			get_tree().quit(0)
		else:
			_enter((phase + 1) as Phase)


func _host_report() -> void:
	var primary := 55.0 * _ap
	var secondary := 35.0 * _ap
	var d0: float = _hp.get(0, 0.0) - enemies[0].health
	var d1: float = _hp.get(1, 0.0) - enemies[1].health
	var dme: float = _hp.get("me", me.health) - me.health
	match phase:
		Phase.CAST:
			_res("host_first_enemy_exact_primary", absf(d0 - primary) < 0.05, "lost %.3f, want %.3f (ap %.3f)" % [d0, primary, _ap])
			_res("host_second_enemy_exact_secondary", absf(d1 - secondary) < 0.05, "lost %.3f, want %.3f" % [d1, secondary])
			_res("host_player_in_lane_not_hit", dme == 0.0, "host player lost %.2f" % dme)
			_res("host_saw_channel_begin_once", _begun == 1, "begin events %d" % _begun)
			_res("host_saw_hand_charge", _charge_seen, "charge node on the client's player: %s" % str(_charge_seen))
			_res("host_got_visual_wave_copy", _released == 1 and _wave_copy_seen, "release events %d, non-owned wave seen %s" % [_released, str(_wave_copy_seen)])
			_res("host_saw_release_end", _ended == [true], "ended %s" % str(_ended))
		Phase.BROKEN:
			_res("broken_no_damage", d0 == 0.0 and d1 == 0.0, "lost %.2f / %.2f" % [d0, d1])
			_res("broken_no_release_seen_by_host", _released == 0 and not _wave_copy_seen, "release events %d" % _released)
			_res("broken_host_sees_channel_cancel", _begun == 1 and _ended == [false], "begin %d, ended %s" % [_begun, str(_ended)])


# --- Client -----------------------------------------------------------------------------

func _client_released(_from: Vector3, _dir: Vector3, _travel: float, _width: float) -> void:
	_c_released += 1
	_c_mana_at_release = me.caster.resource
	_c_cd_at_release = me.caster.cooldown_left(me.stats.class_data.abilities[0])


func _client_step() -> void:
	var a: AbilityData = me.stats.class_data.abilities[0] if me.stats else null
	match phase:
		Phase.WAIT:
			_place()
		Phase.CAST:
			_at(0.1, func() -> void:
				_place()
				me.caster.refill()
				_c_released = 0
				_client_info.rpc_id(1, me.stats.ability_power()))
			_at(1.0, func() -> void:
				_c_mana_at_release = -1.0
				me.caster.try_use(0))
			_at(1.15, func() -> void:
				var paid := me.caster.resource < me.stats.resource_max() - 0.01 or me.caster.cooldown_left(a) > 0.0
				_res("client_nothing_paid_while_channelling", not paid and _c_released == 0,
						"Mana %.2f, cooldown %.2f" % [me.caster.resource, me.caster.cooldown_left(a)]))
			_at(3.5, func() -> void:
				_res("client_cost_exactly_20_at_release", _c_released == 1 and absf(_c_mana_at_release - (me.stats.resource_max() - 20.0)) < 0.001,
						"Mana at release %.3f" % _c_mana_at_release)
				_res("client_cooldown_4s_at_release", absf(_c_cd_at_release - 4.0) < 0.001, "cooldown %.3f" % _c_cd_at_release))
		Phase.BROKEN:
			_at(0.1, func() -> void:
				me.caster.refill()
				_c_released = 0)
			_at(1.0, func() -> void:
				me.caster.try_use(0))
			_at(1.15, func() -> void: me._stagger(0.5))
			_at(4.3, func() -> void:
				_res("client_broken_cast_free", _c_released == 0 and me.caster.resource >= me.stats.resource_max() - 0.01 and me.caster.cooldown_left(a) <= 0.0,
						"released %d, Mana %.2f, cooldown %.2f" % [_c_released, me.caster.resource, me.caster.cooldown_left(a)]))
		Phase.END:
			get_tree().quit(0)


func _place() -> void:
	me.global_position = SPOT + Vector3(0, 0.05, 0)
	me.model.face_instantly(Vector3.FORWARD)
	me.camera_rig.yaw = 0.0
	me.reset_physics_interpolation()
