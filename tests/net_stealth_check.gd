extends Node
## Stealth over the network: one host and one joining player ("a"), both on this PC.
##   ... --script res://tests/run.gd -- net_stealth_check host
##   ... --script res://tests/run.gd -- net_stealth_check a
## (tests/run_net_check.ps1 runs it after the 3-player check.) The host drives a
## list of phases and tells the joiner which one it is in; each machine prints
## "RESULT <role> <name>=PASS|FAIL ..." lines. Cases (STEALTH_PLAN.md, co-op):
##   1. a friend standing still 1.5x the enemy's hearing range behind it: unnoticed
##   2. the same friend SPRINTING: the host's enemy notices (net_stealth reaches the host)
##   3. a crouched friend, still then creeping, 4 m behind it: stays below 0.5
##   4. the friend's own machine shows the enemy SUSPICIOUS and its eye "suspicious"
##   5. ... and "fighting" once the enemy fights it
##   6. the friend's sneak attack deals sneak_multiplier x the normal blow on the host

enum Phase { WAIT, STILL, SPRINT, CROUCH_STILL, CROUCH_CREEP, SUSPICIOUS, FIGHTING, REF_HITS, SNEAK, END }
const LENGTH := {
	Phase.WAIT: 3.0, Phase.STILL: 3.0, Phase.SPRINT: 3.0, Phase.CROUCH_STILL: 3.0,
	Phase.CROUCH_CREEP: 3.0, Phase.SUSPICIOUS: 3.5, Phase.FIGHTING: 3.5,
	Phase.REF_HITS: 6.0, Phase.SNEAK: 4.0, Phase.END: 1.5,
}
const SPOT := Vector3(30, 0, -30)  # open ground, away from the arena's walls

var role := "host"
var me: Player
var enemy: Enemy
var started := false
var phase := Phase.WAIT
var phase_t := 0.0
var _done := {}
var _top := 0.0  # highest awareness of the friend seen this phase (host)
var _refs: Array[float] = []
var _hits: Array[float] = []


func _init() -> void:
	name = "NetStealthCheck"  # the same path on both machines, for the phase rpc


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	role = args[1] if args.size() > 1 else "host"
	Net.player_name = "Host" if role == "host" else "Alda"
	if role == "host":
		Net.host_game()
	else:
		Net.join_game("127.0.0.1")
	get_tree().create_timer(70.0).timeout.connect(func() -> void:
		print("RESULT %s timeout=true" % role)
		get_tree().quit(3))


func _physics_process(delta: float) -> void:
	if not started:
		if get_tree().get_nodes_in_group(&"player").size() >= 2:
			started = true
			me = get_tree().get_first_node_in_group(&"local_player") as Player
			enemy = get_tree().current_scene.get_node("Enemies/Marauder") as Enemy
			print("RESULT %s players=2" % role)
			if role == "host":
				(get_tree().current_scene.get_node("Enemies/Marauder2") as Node3D).global_position = Vector3(-60, 0, -60)
				_enter(Phase.WAIT)
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
	_enter_host(p)


## The distance behind the enemy for the hearing cases: 1.5x its hearing range.
func _far() -> float:
	return enemy.data.hearing_range * 1.5


func _friend() -> Player:
	for x in get_tree().get_nodes_in_group(&"player"):
		if (x as Player).player_name == "Alda":
			return x as Player
	return null


func _res(label: String, ok: bool, detail: String) -> void:
	print("RESULT %s %s=%s %s" % [role, label, "PASS" if ok else "FAIL", detail])


## Run `action` once, the first frame after `time` seconds into the phase.
func _at(time: float, action: Callable) -> void:
	if phase_t >= time and not _done.has(time):
		_done[time] = true
		action.call()


# --- Host: the enemy and the measurements ---------------------------------------------

func _reset_enemy(face := Vector3.FORWARD) -> void:
	enemy._awareness.clear()
	enemy._quiet.clear()
	enemy._alarm_time = -1.0
	enemy.target = null
	enemy.health = enemy.max_health
	enemy._set_state(Enemy.State.IDLE)
	_pin(face)
	_top = 0.0


func _pin(face := Vector3.FORWARD) -> void:
	enemy.global_position = SPOT
	enemy.velocity = Vector3.ZERO
	enemy._spawn.origin = SPOT  # its home is here: no leash, no walking home
	enemy.model.face_instantly(face)
	enemy._cooldown = 999.0


func _enter_host(p: Phase) -> void:
	match p:
		Phase.WAIT, Phase.STILL, Phase.SPRINT, Phase.CROUCH_STILL, Phase.CROUCH_CREEP:
			_reset_enemy()
		Phase.SUSPICIOUS:
			_reset_enemy()
			enemy._awareness[_friend().get_multiplayer_authority()] = 0.6
			enemy._become_suspicious()
		Phase.FIGHTING:
			_reset_enemy()
			var f := _friend()
			if f:
				enemy._awareness[f.get_multiplayer_authority()] = 1.0
				enemy._aggro(f)
		Phase.REF_HITS, Phase.SNEAK:
			_reset_enemy()  # its back to the friend: not seen face to face (point blank), flanked
			enemy.data = enemy.data.duplicate()
			enemy.data.perception = 0.0  # it never notices on its own; the check sets its state
		Phase.END:
			print("RESULT host coop_done=true")


func _host_step() -> void:
	var f := _friend()
	if f == null and phase != Phase.END:
		return
	var peer := f.get_multiplayer_authority() if f else 0
	match phase:
		Phase.WAIT:
			_pin()
		Phase.STILL, Phase.SPRINT, Phase.CROUCH_STILL, Phase.CROUCH_CREEP:
			_pin()
			_top = maxf(_top, enemy.awareness_of(f))
			if enemy.state != Enemy.State.IDLE:
				_top = maxf(_top, 0.5 if enemy.state == Enemy.State.SUSPICIOUS else 1.0)
		Phase.SUSPICIOUS:
			_pin()
			enemy._awareness[peer] = 0.6
			enemy._quiet[peer] = 0.0
		Phase.FIGHTING:
			_pin()
		Phase.REF_HITS:
			_host_hits(f, Enemy.State.CHASE, [0.5, 2.7], [2.4, 4.6])
		Phase.SNEAK:
			_host_hits(f, Enemy.State.IDLE, [0.5], [3.0])
	_at(LENGTH[phase] - 0.1, _host_report)
	if phase_t >= LENGTH[phase]:
		if phase == Phase.END:
			get_tree().quit(0)
		else:
			_enter((phase + 1) as Phase)


func _host_report() -> void:
	match phase:
		Phase.STILL:
			_res("still_far_unnoticed", _top < 0.5, "max awareness %.2f at %.1f m" % [_top, _far()])
		Phase.SPRINT:
			_res("sprint_heard_by_host_enemy", _top >= 0.5, "max awareness %.2f at %.1f m (hearing range %.1f, state %s)" % [_top, _far(), enemy.data.hearing_range, Enemy.State.keys()[enemy.state]])
		Phase.CROUCH_STILL:
			_res("crouch_still_unnoticed", _top < 0.5, "max awareness %.2f at 4 m" % _top)
		Phase.CROUCH_CREEP:
			_res("crouch_creep_unnoticed", _top < 0.5, "max awareness %.2f at 4 m" % _top)
		Phase.SNEAK:
			# Both blows land from behind, so the reference blows carry the flank bonus.
			var flank := me.tuning.flank_damage_mult
			var normal := 999.0
			for r in _refs:
				normal = minf(normal, r / flank)
			var got: float = _hits[0] if not _hits.is_empty() else 0.0
			var want := me.weapon.sneak_multiplier
			_res("sneak_attack_multiplier", normal > 0.0 and normal < 999.0 and absf(got / normal - want) < 0.15,
					"sneak %.1f vs normal %.1f (refs %s) = x%.2f, weapon says x%.2f" % [got, normal, str(_refs), got / maxf(normal, 0.001), want])


## One blow per slot: the enemy is put in `state` at the slot time (health full), and the
## health lost is read at the matching read time. Times are seconds into the phase.
func _host_hits(f: Player, state: Enemy.State, slots: Array, reads: Array) -> void:
	_pin()
	for i in slots.size():
		_at(slots[i], func() -> void:
			enemy.health = enemy.max_health
			enemy._awareness.clear()
			enemy.target = f if state == Enemy.State.CHASE else null
			enemy._set_state(state))
		_at(reads[i], func() -> void:
			var lost: float = enemy.max_health - enemy.health
			if phase == Phase.REF_HITS:
				_refs.append(lost)
			else:
				_hits.append(lost))
		if state == Enemy.State.IDLE and phase_t > slots[i] and phase_t < reads[i]:
			enemy._awareness.clear()


# --- Joiner: the friend's behaviour and what it sees -----------------------------------

func _client_step() -> void:
	var far := SPOT + Vector3(0, 0.05, _far())
	var near := SPOT + Vector3(0, 0.05, 4.0)
	match phase:
		Phase.STILL:
			_hold(far, false, false)
		Phase.SPRINT:
			_hold(far, true, false)
		Phase.CROUCH_STILL:
			_hold(near, false, true)
		Phase.CROUCH_CREEP:
			_hold(near, false, true, true)
		Phase.SUSPICIOUS:
			_hold(near, false, true)
			_at(2.8, func() -> void:
				var look: String = _hud().call(&"eye_look")
				_res("client_sees_suspicious", enemy.state == Enemy.State.SUSPICIOUS and look == "suspicious",
						"enemy shows %s, eye looks %s" % [Enemy.State.keys()[enemy.state], look]))
		Phase.FIGHTING:
			_hold(near, false, true)
			_at(2.8, func() -> void:
				var look: String = _hud().call(&"eye_look")
				_res("client_eye_fighting", enemy.state == Enemy.State.CHASE and look == "fighting",
						"enemy shows %s, eye looks %s" % [Enemy.State.keys()[enemy.state], look]))
		Phase.REF_HITS:
			_release_inputs()
			me.is_crouching = false
			_at(0.1, func() -> void: _place(SPOT + Vector3(0, 0.05, 2.2)))
			_at(1.0, func() -> void: _tap("light_attack"))
			_at(3.2, func() -> void: _tap("light_attack"))
		Phase.SNEAK:
			_at(0.1, func() -> void: _place(SPOT + Vector3(0, 0.05, 2.2)))
			_at(1.5, func() -> void: _tap("light_attack"))
		Phase.END:
			get_tree().quit(0)


func _hud() -> Node:
	return get_tree().current_scene.get_node("Hud")


func _hold(where: Vector3, sprint: bool, crouch: bool, creep := false) -> void:
	_place(where)
	me.stamina = me.tuning.max_stamina
	me.is_crouching = crouch
	_press(&"dodge_sprint", sprint)
	_press(&"move_forward", sprint or creep)


func _press(action: StringName, down: bool) -> void:
	if down and not Input.is_action_pressed(action):
		Input.action_press(action)
	elif not down and Input.is_action_pressed(action):
		Input.action_release(action)


func _release_inputs() -> void:
	_press(&"dodge_sprint", false)
	_press(&"move_forward", false)


func _place(where: Vector3) -> void:
	me.global_position = where
	me.model.face_instantly(Vector3.FORWARD)
	me.camera_rig.yaw = 0.0
	me.reset_physics_interpolation()


func _tap(action: StringName) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event.call_deferred(r)
