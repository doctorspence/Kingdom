class_name EnemyPost
extends RefCounted
## What an enemy does while nobody is around (ENEMY_LIFE_PLAN.md, stage 1).
##
## Friends standing idle close together form a huddle: they turn to face each
## other and pass the time with calm animations (one talks while the others
## listen, nod, fold their arms or drink). Patrols walk at ease. Weapons hang at
## the hip and shields on the back until the fight starts.
##
## When one of them notices a player, every calm friend nearby turns to face the
## threat and joins in after a short moment to get ready (a little staggered, so
## they don't move as one).
##
## The calm animations are chosen on the host and shared like any animation.
## Sheathing is worked out on every machine from the enemy's state (Enemy._update_sheath).

## Idle friends within this distance (meters) stand together as one huddle.
const HUDDLE_RANGE := 5.0
## Calm friends within this distance join the fight when one of them does.
const ALERT_RANGE := 10.0
## Seconds between noticing a player and charging (standing; later posts add more).
const READY_TIME := 0.35
## Extra random delay for friends who were alerted by someone else.
const READY_STAGGER := Vector2(0.15, 0.6)
const TALK := &"Idle_Talking"

## Calm animations per style: [animation, weight, min seconds, max seconds].
## Seconds = how long it stays in that animation before choosing again.
const STYLES := {
	"loose": [
		[&"Idle", 3.0, 4.0, 9.0],
		[&"ual2/Idle_FoldArms", 3.0, 5.0, 10.0],
		[TALK, 2.5, 4.0, 8.0],
		[&"ual2/Yes", 1.0, 2.5, 2.5],
		[&"ual2/Idle_No", 0.6, 2.5, 3.5],
		[&"ual2/Consume", 0.8, 2.6, 2.6],
	],
	"disciplined": [
		[&"Idle", 4.0, 6.0, 12.0],
		[&"ual2/Idle_FoldArms", 3.0, 6.0, 12.0],
		[TALK, 0.8, 3.0, 5.0],
		[&"ual2/Yes", 0.5, 2.5, 2.5],
	],
}
const LISTEN := [&"Idle", &"ual2/Idle_FoldArms", &"ual2/Yes"]
const WALK := {"loose": &"Walk", "disciplined": &"Walk_Formal"}

var enemy: Enemy
## False: this enemy keeps the old behavior (bosses, hounds, ambushers, raiders).
var enabled := false
var mates: Array[Enemy] = []
var _style := "loose"
var _set_up := false
var _rescan := 0.0
var _anim := &""
var _time_left := 0.0
var _look := Vector3.ZERO  # where it looks while standing (zero = its home facing)
var _rng := RandomNumberGenerator.new()


func _init(e: Enemy) -> void:
	enemy = e
	_rng.randomize()
	_style = e.data.calm_style
	enabled = _wanted()
	# Keeping watch: set by the spawn point ("watch"), or any lookout on its own.
	var kind: String = e.get_meta(&"post_kind", "")
	watching = enabled and (kind == "watch" or (kind == "" and "lookout" in String(e.data.id)))
	if watching:
		_rail = e.get_meta(&"watch_rail", false)
		e.sight_scale = WATCH_SIGHT
	# First look round a moment after appearing, once its friends are in too. On a
	# timer, so it happens even if the enemy is asleep (EnemySleep) by then.
	if enabled and e.is_inside_tree():
		e.get_tree().create_timer(0.3, false).timeout.connect(_first_look)


func _first_look() -> void:
	if not is_instance_valid(enemy) or enemy.state != Enemy.State.IDLE or _set_up:
		return
	_set_up = true
	_rescan = _rng.randf_range(2.5, 4.0)
	if watching:
		_watch_dir = _choose_watch_dir()
		enemy.set_home_facing(_watch_dir)
		enemy.model.face_instantly(_watch_dir)
	elif not is_patrolling() and not _claim_spot():
		_find_mates(true)


func _wanted() -> bool:
	var d := enemy.data
	if d.boss or d.calm_style == "none" or d.ambush_range > 0.0:
		return false
	# Raiders march on the camp ready to fight (the name is how friends' machines know).
	if enemy.is_in_group(&"raiders") or String(enemy.name).begins_with("Raider_"):
		return false
	# Only bodies with the human animation set (not hounds).
	return enemy.model.has_anim(&"ual2/Idle_FoldArms") and enemy.model.has_anim(TALK)


func is_patrolling() -> bool:
	return enemy.patrol_points.size() >= 2


func is_talking() -> bool:
	return _anim == TALK


## Host, every frame while standing calm on its post.
func tick(delta: float) -> void:
	if watching:
		_keep_watch(delta)
		return
	if is_getting_up():
		return  # still getting up off the ground (morning)
	if _night_tick(delta):
		return
	if spot_kind != Spot.NONE:
		_tick_spot(delta)
		return
	if not _set_up:
		return  # waiting for the first look round (_first_look)
	_rescan -= delta
	if _rescan <= 0.0:
		_find_mates(false)
		_rescan = _rng.randf_range(2.5, 4.0)  # friends may arrive later (spawns, raids)
	_time_left -= delta
	if _time_left <= 0.0 or _anim == &"":
		_choose()
	if _look != Vector3.ZERO:
		var to := _look - enemy.global_position
		to.y = 0.0
		if to.length() > 0.2 and enemy._facing_error(to) > 6.0:
			enemy.model.turn_toward(to, deg_to_rad(70.0) * delta)


## Back on its post (start, after a fight, after a rest): start a fresh calm animation.
## A patroller picks its route up where its friends are.
func resume() -> void:
	_anim = &""
	_time_left = 0.0
	_waiting = false
	_phase = 0  # a seat or a job: walk back to it
	if is_patrolling():
		var ahead: Enemy = null
		for m in _patrol_mates():
			if ahead == null or m.post.leg > ahead.post.leg:
				ahead = m
		if ahead:
			leg = ahead.post.leg
			enemy._patrol_i = ahead._patrol_i


# --- Night rest (stage 7) ----------------------------------------------------------
## Camps sleep at night (DayNight.night above REST_AT; up again below WAKE_AT): the
## calm ones near a camp fire lie down beside it (`LayToIdle` held at its first,
## lying frame) and see very little. One per fire stays up by the fire as the night
## watch; watch posts and patrols keep going. Getting up takes about 2 s.
const REST_AT := 0.6
const WAKE_AT := 0.35
const REST_RANGE := 10.0      # meters from a camp fire
const RESTED_SIGHT := 0.35
const REST_GET_UP := 1.8
const LIE := &"ual2/LayToIdle"

var resting := false
var _rest_phase := 0  # 0 = going to its spot, 1 = lying down, 2 = asleep
var _rest_time := 0.0
var _rest_check := 0.0
static var _fires: Array[Vector3] = []
static var _rest_claims := {}  # "fire:slot" -> Enemy lying there
const REST_SLOTS := 10        # places round a fire (every other one can be used)
const REST_RADIUS := 2.0      # meters from the fire
var _rest_at := Vector3.INF
var _rest_key := ""


## Host, from tick(): true while night rest has this enemy (lying, or on its way).
func _night_tick(delta: float) -> bool:
	if not resting:
		if DayNight.night < REST_AT:
			return false
		_rest_check -= delta
		if _rest_check > 0.0:
			return false
		_rest_check = _rng.randf_range(0.8, 1.5)  # (not every frame: it looks at the whole camp)
		if not _can_rest() or _keeps_night_watch():
			return false
		resting = true
		_rest_phase = 0
		_release_lock()
		_phase = 0  # off the seat or the job
		_anim = &""
		if not _player_within(30.0):
			_rest_phase = 2  # nobody near: simply asleep already
			enemy.global_position = _rest_spot()
			_lie(0.0)
		return true
	if DayNight.night < WAKE_AT:
		_wake()
		return false
	if _rest_phase == 0:
		var to := _rest_spot() - enemy.global_position
		to.y = 0.0
		if to.length() > 0.3:
			enemy.model.turn_toward(to, deg_to_rad(enemy.data.turn_speed) * 0.5 * delta)
			enemy._move(to.normalized() * minf(enemy.data.walk_speed, to.length() * 2.0 + 0.4), delta)
			walk(Vector3(enemy.velocity.x, 0, enemy.velocity.z).length())
			return true
		_rest_phase = 1
		_rest_time = 0.0
		_lie(1.1)
		return true
	enemy._move(Vector3.ZERO, delta)
	if _rest_phase == 1:
		_rest_time += delta
		if _rest_time >= 1.1:
			_rest_phase = 2
	return true


## Down on the ground: the first (lying) frame of LayToIdle, held. `blend` seconds
## from whatever it was doing (a slow blend reads as lying down).
func _lie(blend: float) -> void:
	var to_fire := _nearest_point(_fires, enemy.global_position, REST_RANGE) - enemy.global_position
	to_fire.y = 0.0
	if to_fire.length() > 0.1:
		enemy.model.face_instantly(to_fire.cross(Vector3.UP))  # lying alongside the fire
	enemy.model.play(LIE, blend, 0.0, true)
	enemy.sight_scale = RESTED_SIGHT


## Morning (or the camp is called to arms): stand up and go back to the post.
func _wake() -> void:
	resting = false
	_free_rest_spot()
	enemy.model.play_fitted(LIE, REST_GET_UP, 0.1)
	_up_until = Time.get_ticks_msec() + int(REST_GET_UP * 1000.0)
	enemy.sight_scale = 1.0
	resume()


## Where it lies: a free place on a ring round the fire, nearest its own post. The
## places keep clear of seats and camp props and of each other (bodies lie along
## the ring). No room: where its post is.
func _rest_spot() -> Vector3:
	if _rest_at != Vector3.INF:
		return _rest_at
	var home := enemy._spawn.origin if spot_kind != Spot.NONE else enemy.global_position
	_rest_at = home
	var fire := _nearest_point(_fires, home, REST_RANGE)
	if fire == Vector3.INF:
		return _rest_at
	var base := atan2(home.z - fire.z, home.x - fire.x)
	var order: Array = range(REST_SLOTS)
	order.sort_custom(func(a: int, b: int) -> bool:
		return absf(angle_difference(base, _slot_angle(a))) < absf(angle_difference(base, _slot_angle(b))))
	for i: int in order:
		var key := "%s:%d" % [fire, i]
		var spot := fire + Vector3(cos(_slot_angle(i)), 0.0, sin(_slot_angle(i))) * REST_RADIUS
		spot.y = home.y
		if _slot_taken(fire, i) or _blocked(spot):
			continue
		_rest_claims[key] = enemy
		_rest_key = key
		_rest_at = spot
		break
	return _rest_at


func _slot_angle(i: int) -> float:
	return TAU * i / REST_SLOTS


## This place or either one beside it already has someone lying there.
func _slot_taken(fire: Vector3, i: int) -> bool:
	for d in [-1, 0, 1]:
		var e: Enemy = _rest_claims.get("%s:%d" % [fire, posmod(i + d, REST_SLOTS)])
		if e != null and e != enemy and is_instance_valid(e) and e.post.resting:
			return true
	return false


func _blocked(spot: Vector3) -> bool:
	for p: Dictionary in _props:
		if (p["pos"] as Vector3).distance_to(spot) < 1.4:
			return true
	return false


func _free_rest_spot() -> void:
	if _rest_key != "" and _rest_claims.get(_rest_key) == enemy:
		_rest_claims.erase(_rest_key)
	_rest_key = ""
	_rest_at = Vector3.INF


func _can_rest() -> bool:
	if watching or is_patrolling() or not _set_up:
		return false
	if not enemy.model.has_anim(LIE):
		return false
	return _nearest_point(_fires, enemy.global_position, REST_RANGE) != Vector3.INF


## The night watch: of the calm ones by the same fire, the first (lowest id) stays
## up, sitting or standing by the fire as usual.
func _keeps_night_watch() -> bool:
	var fire := _nearest_point(_fires, enemy.global_position, REST_RANGE)
	for n in enemy.get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Enemy
		if e == null or e == enemy or e.post == null or not e.post.enabled or e.state != Enemy.State.IDLE:
			continue
		if e.post.watching and e.global_position.distance_to(fire) <= CAMP_RANGE:
			return false  # the camp has a lookout: everyone else may sleep
		if e.post.watching or e.post.is_patrolling():
			continue
		if e.global_position.distance_to(fire) <= REST_RANGE and e.get_instance_id() < enemy.get_instance_id():
			return false
	return true


# --- Keeping watch (stage 3) -------------------------------------------------------
## A watcher sees this much farther (Enemy.sight_scale): 22 m becomes about 30 m.
const WATCH_SIGHT := 1.35
## It scans this far either side of its watch direction (degrees)...
const SCAN := 45.0
## ...turning this fast (degrees a second), holding each look this long (seconds).
const SCAN_TURN := 35.0
const SCAN_HOLD := Vector2(2.5, 4.5)
## A lookout with no set direction faces away from the camp friends within this distance.
const CAMP_RANGE := 15.0
const WATCH_ANIMS := {
	"loose": [[&"Idle", 3.0], [&"ual2/Idle_FoldArms", 2.0], [&"ual2/Consume", 0.4]],
	"disciplined": [[&"Idle", 3.0], [&"ual2/Idle_FoldArms", 1.0]],
}
const RAIL_ANIM := &"ual2/Idle_Rail"


## At night a watcher holds up a torch (`Idle_Torch`, the torch in the left hand).
const TORCH_ANIM := &"Idle_Torch"
var _torch: HandTorch


func _torch_time() -> bool:
	return DayNight.night >= REST_AT and enemy.model.has_anim(TORCH_ANIM)


## Every machine, every frame: a torch in hand while the torch animation plays on
## the post. Called to fight, it drops the torch, which burns out on the ground.
func update_torch() -> void:
	var want := enemy.state == Enemy.State.IDLE and enemy.model.current_anim() == TORCH_ANIM
	var has := _torch != null and is_instance_valid(_torch) and not _torch.is_dropped()
	if want == has:
		return
	if want:
		_torch = HandTorch.new()
		enemy.model.carry("l", _torch)
	else:
		if enemy.state != Enemy.State.IDLE and enemy.is_inside_tree():
			_torch.drop(enemy.get_parent())
		else:
			enemy.model.carry("l", null)
		_torch = null

## True: keeps watch instead of standing with friends.
var watching := false
var _rail := false
var _watch_dir := Vector3.ZERO
var _scan_step := 0
var _scan_hold := 0.0


func _keep_watch(delta: float) -> void:
	if _watch_dir == Vector3.ZERO:
		return  # waiting for the first look round (_first_look)
	# Calm animation: leaning on the rail, or standing (now and then a drink).
	_time_left -= delta
	if _torch_time() != (_anim == TORCH_ANIM):
		_time_left = 0.0  # night fell (torch up) or day broke (torch away)
	if _torch_time() and _time_left <= 0.0:
		enemy.model.play(TORCH_ANIM, 0.5, _rng.randf_range(0.9, 1.1))
		_anim = TORCH_ANIM
		_time_left = 10.0
	elif _time_left <= 0.0 or _anim == &"":
		var anim := RAIL_ANIM
		if not (_rail and enemy.model.has_anim(RAIL_ANIM)):
			anim = _pick(WATCH_ANIMS.get(_style, WATCH_ANIMS["loose"]).map(func(o: Array) -> Array: return [o[0], o[1], 5.0, 10.0]))[0]
		if anim == &"ual2/Consume":
			_time_left = 2.6
		else:
			_time_left = _rng.randf_range(5.0, 10.0)
		enemy.model.play(anim, 0.5, _rng.randf_range(0.9, 1.1), anim != _anim)
		_anim = anim
	# Scan: ahead, one side, ahead, the other side. Leaning on a rail it only looks a little.
	_scan_hold -= delta
	if _scan_hold <= 0.0:
		_scan_hold = _rng.randf_range(SCAN_HOLD.x, SCAN_HOLD.y)
		_scan_step += 1
	var angles := [0.0, SCAN, 0.0, -SCAN]
	var amount := 0.4 if _rail else 1.0
	var want := _watch_dir.rotated(Vector3.UP, deg_to_rad(angles[_scan_step % angles.size()] * amount))
	if enemy._facing_error(want) > 3.0:
		enemy.model.turn_toward(want, deg_to_rad(SCAN_TURN) * delta)


## The spawn point's direction, or (a lookout on its own) away from its camp.
func _choose_watch_dir() -> Vector3:
	var given: Variant = enemy.get_meta(&"watch_dir") if enemy.has_meta(&"watch_dir") else null
	if given is Vector3 and (given as Vector3).length() > 0.1:
		var d := given as Vector3
		d.y = 0.0
		return d.normalized()
	var camp := Vector3.ZERO
	var n := 0
	for e in enemy.get_tree().get_nodes_in_group(&"enemies"):
		var f := e as Enemy
		if f and f != enemy and f.global_position.distance_to(enemy.global_position) <= CAMP_RANGE:
			camp += f.global_position
			n += 1
	if n > 0:
		var away := enemy.global_position - camp / n
		away.y = 0.0
		if away.length() > 0.3:
			return away.normalized()
	var fwd := enemy.model.forward()
	fwd.y = 0.0
	return fwd.normalized()


# --- Seats and camp work (stage 4) ---------------------------------------------
## Calm enemies near camp props use them: sit on a log seat (facing the fire, if
## there is one), or work at a crate, barrel or cart. Seated ones see less and take
## longest to get up; workers are a little distracted.

enum Spot { NONE, SIT, WORK }
## Props within this distance (meters) of where it appears can be claimed.
const SPOT_RANGE := 7.0
## A seat near a fire is taken this often (otherwise a job, if there is one free).
const SIT_CHANCE := 0.7
const SEATED_SIGHT := 0.75
const WORK_SIGHT := 0.85
## Seconds added to its "getting ready" when alerted.
const GET_UP := {Spot.NONE: 0.0, Spot.SIT: 1.0, Spot.WORK: 0.45}
## Props by scene file: [kind, ...]. Seats: logs (2 places, along local X).
## Work: [where to stand in the prop's space, the jobs played there].
const PROPS := {
	"log_seat.tscn": ["seat"],
	"crate.tscn": ["work", 0.95, [&"PickUp_Table", &"ual2/Chest_Open", &"Interact"]],
	"barrel.tscn": ["work", 0.85, [&"Interact", &"ual2/Consume", &"PickUp_Table"]],
	"cart.tscn": ["work", 1.35, [&"Fixing_Kneeling"]],
}
const SIT_ANIMS := [[&"Sitting_Idle", 3.0, 5.0, 10.0], [&"Sitting_Talking", 1.5, 4.0, 8.0]]

## What it is using (NONE = standing with friends as before).
var spot_kind := Spot.NONE
var _spot_pos := Vector3.ZERO
var _spot_face := Vector3.FORWARD
var _jobs: Array = []
var _spot_key := ""
var _phase := 0  # 0 = walking there, 1 = sitting down / starting, 2 = settled
var _phase_time := 0.0
var _last_frame := -100
var _lock: Node = null

## Shared by every enemy: which prop places are taken, and the props found in the world.
static var _claims := {}  # place key -> Enemy
static var _props: Array = []  # [{key, kind, pos, face, jobs, fire}]
static var _props_time := -100000


func get_up_time() -> float:
	if resting:
		return REST_GET_UP
	return GET_UP[spot_kind] if _phase > 0 else 0.0


## Still standing up from a seat (other states wait before playing their own animations).
func is_getting_up() -> bool:
	return Time.get_ticks_msec() < _up_until


var _up_until := 0


## Alerted (or hit): stand up from the seat or put the job down.
func get_up() -> void:
	_release_lock()
	if resting:
		var up_in := REST_GET_UP + READY_TIME
		_free_rest_spot()
		resting = false
		_rest_check = 3.0  # don't lie straight back down if it calms again
		_up_until = Time.get_ticks_msec() + int(up_in * 1000.0)
		enemy.model.play_fitted(LIE, up_in, 0.1)
		enemy.sight_scale = 1.0
		_anim = &""
		_phase = 0
		return
	if spot_kind == Spot.NONE or _phase == 0:
		return
	var takes := get_up_time() + READY_TIME
	_up_until = Time.get_ticks_msec() + int(takes * 1000.0)
	if spot_kind == Spot.SIT:
		enemy.model.play_fitted(&"Sitting_Exit", takes, 0.15)
	else:
		enemy.model.play(&"Idle", 0.2)
	_anim = &""
	_phase = 0
	enemy.sight_scale = 1.0


func _claim_spot() -> bool:
	_find_props()
	var here := enemy.global_position
	var seats: Array = []
	var jobs: Array = []
	for p: Dictionary in _props:
		if (p.pos as Vector3).distance_to(here) > SPOT_RANGE or _taken(p.key):
			continue
		(seats if p.kind == "seat" else jobs).append(p)
	if seats.is_empty() and jobs.is_empty():
		return false
	var pick: Dictionary
	var by_fire := seats.filter(func(p: Dictionary) -> bool: return p.fire)
	if not by_fire.is_empty() and (jobs.is_empty() or _rng.randf() < SIT_CHANCE):
		pick = _nearest(by_fire, here)
	elif not jobs.is_empty() and (seats.is_empty() or _rng.randf() < 0.6):
		pick = _nearest(jobs, here)
	else:
		pick = _nearest(seats, here)
	_claims[pick.key] = enemy
	_spot_key = pick.key
	spot_kind = Spot.SIT if pick.kind == "seat" else Spot.WORK
	_spot_pos = pick.pos
	_spot_face = pick.face
	_jobs = pick.jobs
	_phase = 0
	enemy.set_home_facing(_spot_face)
	# Home after a fight: just in front of the seat (the log blocks the seat itself), or the job.
	var home := _spot_pos + _spot_face * (0.75 if spot_kind == Spot.SIT else 0.0)
	enemy._spawn.origin = Vector3(home.x, enemy.global_position.y, home.z)
	# Nobody close enough to see it: just be there already.
	if not _player_within(30.0):
		enemy.global_position = Vector3(_spot_pos.x, enemy.global_position.y, _spot_pos.z)
		enemy.model.face_instantly(_spot_face)
		enemy.reset_physics_interpolation()
	return true


func _taken(key: String) -> bool:
	var e: Variant = _claims.get(key)
	return e != null and is_instance_valid(e) and e != enemy and (e as Enemy).state != Enemy.State.DEAD


func _nearest(options: Array, to: Vector3) -> Dictionary:
	var best: Dictionary = options[0]
	for p: Dictionary in options:
		if (p.pos as Vector3).distance_to(to) < (best.pos as Vector3).distance_to(to):
			best = p
	return best


func _player_within(dist: float) -> bool:
	for n in enemy.get_tree().get_nodes_in_group(&"player"):
		if (n as Node3D).global_position.distance_to(enemy.global_position) < dist:
			return true
	return false


## Every seat and work place in the world (looked up again every few seconds at most).
func _find_props() -> void:
	var now := Time.get_ticks_msec()
	if now - _props_time < 5000 and not _props.is_empty():
		return
	_props_time = now
	_props.clear()
	var fires: Array[Vector3] = []
	var found: Array = []
	for n in enemy.get_tree().root.find_children("*", "Node3D", true, false):
		if n is Campfire:
			fires.append((n as Node3D).global_position)
			continue
		var file := String(n.scene_file_path).get_file()
		if PROPS.has(file):
			found.append([n, PROPS[file]])
	_fires = fires
	for f: Array in found:
		var node := f[0] as Node3D
		var spec: Array = f[1]
		var t := node.global_transform
		var id := node.get_instance_id()
		if spec[0] == "seat":
			var along := t.basis.x.normalized()
			var fire := _nearest_point(fires, t.origin, 7.0)
			# Sit facing the fire, or (no fire) whichever side faces the camp's open side.
			var face := t.basis.z.normalized()
			if fire != Vector3.INF and face.dot(fire - t.origin) < 0.0:
				face = -face
			face.y = 0.0
			for side in [-0.5, 0.5]:
				var pos: Vector3 = t.origin + along * side + face * SEAT_FORWARD
				_props.append({"key": "%d:%s" % [id, side], "kind": "seat", "pos": pos, "face": face.normalized(), "jobs": [], "fire": fire != Vector3.INF})
		else:
			# Stand at the prop's side that faces the camp middle (the nearest fire, or its +Z).
			var dist: float = spec[1]
			var fire := _nearest_point(fires, t.origin, 15.0)
			var out := (fire - t.origin) if fire != Vector3.INF else t.basis.z
			out.y = 0.0
			out = out.normalized() if out.length() > 0.01 else Vector3.BACK
			if file_is_cart(node):
				# A cart is long: kneel at the middle of whichever long side faces the camp.
				var side := t.basis.x.normalized()
				out = side if side.dot(out) >= 0.0 else -side
			_props.append({"key": "%d" % id, "kind": "work", "pos": t.origin + out * dist, "face": -out, "jobs": spec[2], "fire": false})


## How far forward of the log's middle the body stands to sit on it (meters).
const SEAT_FORWARD := 0.12


func file_is_cart(n: Node) -> bool:
	return String(n.scene_file_path).get_file() == "cart.tscn"


func _nearest_point(points: Array[Vector3], to: Vector3, within: float) -> Vector3:
	var best := Vector3.INF
	for p in points:
		if p.distance_to(to) <= within and (best == Vector3.INF or p.distance_to(to) < best.distance_to(to)):
			best = p
	return best


func _tick_spot(delta: float) -> void:
	# Away for a while (a fight, a suspicious look): walk back and start again.
	var frame := Engine.get_physics_frames()
	if frame - _last_frame > 3 and _phase != 0:
		_release_lock()
		_phase = 0
	_last_frame = frame
	if _phase == 0:
		var to := _spot_pos - enemy.global_position
		to.y = 0.0
		# The log itself stops the body short of a seat; the lock sets it in place.
		if to.length() > (0.8 if spot_kind == Spot.SIT else 0.3):
			enemy.model.turn_toward(to, deg_to_rad(enemy.data.turn_speed) * 0.5 * delta)
			enemy._move(to.normalized() * minf(enemy.data.walk_speed, to.length() * 2.0 + 0.4), delta)
			walk(Vector3(enemy.velocity.x, 0, enemy.velocity.z).length())
			return
		_phase = 1
		_phase_time = 0.0
		_anim = &""
		enemy.model.face_instantly(_spot_face)
		_take_lock()
		enemy.sight_scale = SEATED_SIGHT if spot_kind == Spot.SIT else WORK_SIGHT
		if spot_kind == Spot.SIT:
			enemy.model.play(&"Sitting_Enter", 0.2, 1.0, true)
			_time_left = enemy.model.anim_length(&"Sitting_Enter") - 0.1
		else:
			_time_left = 0.0
		return
	_phase_time += delta
	_time_left -= delta
	if _time_left > 0.0:
		return
	_phase = 2
	if spot_kind == Spot.SIT:
		var talker := _seated_talker()
		var pick: Array = SIT_ANIMS[0] if talker else _pick(SIT_ANIMS)
		_time_left = _rng.randf_range(pick[2], pick[3])
		enemy.model.play(pick[0], 0.4, _rng.randf_range(0.9, 1.1))
		_anim = pick[0]
	else:
		# A job, then a short breather now and then.
		var anim: StringName = _jobs[_rng.randi() % _jobs.size()]
		if _anim != &"Idle" and _anim != &"" and _rng.randf() < 0.3:
			anim = &"Crouch_Idle" if _jobs.has(&"Fixing_Kneeling") else &"Idle"
		var length := enemy.model.anim_length(anim)
		if anim == &"Idle" or anim == &"Crouch_Idle":
			length = _rng.randf_range(2.0, 4.0)
		enemy.model.play(anim, 0.3, _rng.randf_range(0.9, 1.05), true)
		_time_left = length * _rng.randf_range(1.0, 1.6)  # holds the last pose a moment
		_anim = anim


## Another enemy sitting close by is talking (then this one listens).
func _seated_talker() -> Enemy:
	for n in enemy.get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Enemy
		if e and e != enemy and e.post and e.post.spot_kind == Spot.SIT and e.post._anim == &"Sitting_Talking" \
				and e.global_position.distance_to(enemy.global_position) < 8.0:
			return e
	return null


## Sitting or kneeling on a prop: its body must not be pushed off it by the prop's
## own collision, or slide when friends sit close. A small helper holds it in place
## and lets go the moment the enemy leaves its post.
func _take_lock() -> void:
	_release_lock()
	var lock := SpotLock.new()
	lock.post = self
	lock.spot = Vector3(_spot_pos.x, enemy.global_position.y, _spot_pos.z)
	enemy.add_child(lock)
	_lock = lock


func _release_lock() -> void:
	if _lock and is_instance_valid(_lock):
		(_lock as SpotLock).release()
	_lock = null


class SpotLock extends Node:
	var post: EnemyPost
	var spot: Vector3
	var _mask := -1

	func _ready() -> void:
		var e := get_parent() as Enemy
		_mask = e.collision_mask
		e.collision_mask = 0  # nothing pushes it off the seat...
		e.axis_lock_linear_y = true  # ...and with nothing under it, it must not fall

	func _physics_process(_delta: float) -> void:
		var e := get_parent() as Enemy
		if e.state != Enemy.State.IDLE or e._alarm_time >= 0.0:
			release()
			return
		e.velocity = Vector3.ZERO
		e.global_position = Vector3(spot.x, e.global_position.y, spot.z)

	func release() -> void:
		if is_queued_for_deletion():
			return
		set_physics_process(false)  # no more snapping back onto the seat this frame
		var e := get_parent() as Enemy
		if e and _mask >= 0:
			e.collision_mask = _mask
			e.axis_lock_linear_y = false
		queue_free()


# --- Patrols (stage 2) -----------------------------------------------------------
## A patrol stops this long at each corner (seconds; the same for the whole group).
const PAUSE := Vector2(3.0, 6.0)
## ...but never waits longer than this for a straggler.
const MAX_WAIT := 12.0
const ARRIVE := 0.6

## Corners walked so far (counts up forever; friends compare it to keep together).
var leg := 0
var _waiting := false
var _wait_left := 0.0
var _waited := 0.0
var _look_timer := 0.0
var _look_step := 0
var _base_dir := Vector3.FORWARD


func is_waiting() -> bool:
	return _waiting


## Host, every frame while calm on a patrol route.
func patrol(delta: float) -> void:
	var count := enemy.patrol_points.size()
	var goal := _patrol_goal(enemy._patrol_i)
	if _waiting:
		enemy._move(Vector3.ZERO, delta)
		_wait_left -= delta
		_waited += delta
		_look_around(delta)
		if (_wait_left <= 0.0 and _mates_caught_up()) or _waited > MAX_WAIT or _mate_set_off():
			_waiting = false
			enemy._patrol_i = (enemy._patrol_i + 1) % count
			leg += 1
		return
	var to := goal - enemy.global_position
	to.y = 0.0
	if to.length() < ARRIVE:
		_waiting = true
		_wait_left = _pause_for(leg)
		_waited = 0.0
		_look_timer = 0.0
		_look_step = 0
		var prev := enemy.patrol_points[(enemy._patrol_i - 1 + count) % count]
		_base_dir = enemy.patrol_points[enemy._patrol_i] - prev
		_base_dir.y = 0.0
		_base_dir = _base_dir.normalized() if _base_dir.length() > 0.1 else enemy.model.forward()
		return
	enemy.model.turn_toward(to, deg_to_rad(enemy.data.turn_speed) * 0.5 * delta)
	var speed := enemy.data.walk_speed
	# Don't run off from friends who are still catching up.
	if _ahead_of_mates():
		speed *= 0.6
	enemy._move(to.normalized() * speed, delta)
	walk(Vector3(enemy.velocity.x, 0, enemy.velocity.z).length())


## The route point, moved to this enemy's side of the path (so a group walks abreast).
func _patrol_goal(i: int) -> Vector3:
	var pts := enemy.patrol_points
	var p := pts[i]
	if enemy.patrol_side == 0.0:
		return p
	var dir := p - pts[(i - 1 + pts.size()) % pts.size()]
	dir.y = 0.0
	if dir.length() < 0.1:
		return p
	return p + dir.normalized().cross(Vector3.UP) * enemy.patrol_side


## Standing at a corner: look one way, then the other, then back down the road.
func _look_around(delta: float) -> void:
	_look_timer -= delta
	if _look_timer <= 0.0:
		_look_timer = _rng.randf_range(1.2, 2.0)
		_look_step += 1
		enemy.model.play(&"Idle", 0.4, _rng.randf_range(0.9, 1.1))
		_anim = &"Idle"
	var angles := [0.0, -65.0, 65.0, 0.0]
	var want := _base_dir.rotated(Vector3.UP, deg_to_rad(angles[_look_step % angles.size()]))
	if enemy._facing_error(want) > 4.0:
		enemy.model.turn_toward(want, deg_to_rad(80.0) * delta)


## The same pause for every member of a group at the same corner.
func _pause_for(at_leg: int) -> float:
	var r := RandomNumberGenerator.new()
	r.seed = hash(str(enemy.patrol_group, "/", at_leg))
	return r.randf_range(PAUSE.x, PAUSE.y)


## Calm friends walking the same route.
func _patrol_mates() -> Array[Enemy]:
	var out: Array[Enemy] = []
	if enemy.patrol_group == &"":
		return out
	for n in enemy.get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Enemy
		if e and e != enemy and e.patrol_group == enemy.patrol_group and e.state == Enemy.State.IDLE \
				and e.post and e.post.enabled and e._alarm_time < 0.0:
			out.append(e)
	return out


## Everyone in the group has reached this corner (or gone on past it).
func _mates_caught_up() -> bool:
	for m in _patrol_mates():
		if m.post.leg < leg or (m.post.leg == leg and not m.post.is_waiting()):
			return false
	return true


## A friend has already left this corner: go with it (whoever arrived first waited longest).
func _mate_set_off() -> bool:
	for m in _patrol_mates():
		if m.post.leg > leg:
			return true
	return false


## This one has got more than a few meters ahead of a friend on the same leg.
func _ahead_of_mates() -> bool:
	var goal := enemy.patrol_points[enemy._patrol_i]
	var mine := enemy.global_position.distance_to(goal)
	for m in _patrol_mates():
		if m.post.leg == leg and not m.post.is_waiting() and m.global_position.distance_to(goal) > mine + 2.5:
			return true
	return false


## The patrol walk at ease.
func walk(speed: float) -> void:
	var anim: StringName = WALK.get(_style, &"Walk")
	if speed < 0.15:
		enemy.model.play(&"Idle", 0.3)
	else:
		enemy.model.play(anim, 0.3, clampf(speed / enemy.model.walk_anim_speed, 0.5, 2.0))
	_anim = &""


## Idle friends close by stand as one group, facing its middle. `snap`: turn at
## once (first look round); otherwise it turns there in its own time (tick).
func _find_mates(snap: bool) -> void:
	var before := mates.duplicate()
	mates.clear()
	if is_patrolling():
		return
	var center := enemy.global_position
	for n in enemy.get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Enemy
		if e == null or e == enemy or e.post == null or not e.post.enabled or e.post.is_patrolling() or e.post.watching:
			continue
		if e.state == Enemy.State.IDLE and e.global_position.distance_to(enemy.global_position) <= HUDDLE_RANGE:
			mates.append(e)
			center += e.global_position
	if mates.is_empty() or mates == before:
		return
	center /= mates.size() + 1
	var face := center - enemy.global_position
	face.y = 0.0
	if face.length() > 0.2:
		# Home now faces the group, so it turns back to them after a fight.
		enemy.set_home_facing(face)
		if snap:
			enemy.model.face_instantly(face)
	_look = center


func _choose() -> void:
	var options: Array = STYLES.get(_style, STYLES["loose"])
	var speaker := _speaker()
	var pick: Array
	if speaker:
		# Someone is talking: listen (and look at them now and then).
		pick = _pick(options.filter(func(o: Array) -> bool: return LISTEN.has(o[0])))
		_look = speaker.global_position if _rng.randf() < 0.6 else _center()
	else:
		var pool := options
		if mates.is_empty():
			pool = options.filter(func(o: Array) -> bool: return o[0] != TALK)  # nobody to talk to
		pick = _pick(pool)
		_look = _center()
	var anim: StringName = pick[0]
	if not enemy.model.has_anim(anim):
		anim = &"Idle"
	_time_left = _rng.randf_range(pick[2], pick[3])
	# Different speeds and start points, so a group never moves in step.
	enemy.model.play(anim, 0.5, _rng.randf_range(0.9, 1.1), anim != _anim)
	if anim != _anim and enemy.model.anim_length(anim) > 2.0:
		enemy.model.seek(_rng.randf() * 0.6)
	_anim = anim


func _pick(options: Array) -> Array:
	var total := 0.0
	for o in options:
		total += o[1]
	var r := _rng.randf() * total
	for o in options:
		r -= o[1]
		if r <= 0.0:
			return o
	return options[0]


func _speaker() -> Enemy:
	for m in mates:
		if is_instance_valid(m) and m.state == Enemy.State.IDLE and m.post.is_talking():
			return m
	return null


func _center() -> Vector3:
	var live := mates.filter(func(m: Enemy) -> bool: return is_instance_valid(m) and m.state != Enemy.State.DEAD)
	if live.is_empty():
		return Vector3.ZERO
	var c := enemy.global_position
	for m: Enemy in live:
		c += m.global_position
	return c / (live.size() + 1)


## This enemy has noticed `p`: every calm friend close by (that can see it) gets
## ready too, a moment apart.
func alert_friends(p: Player) -> void:
	# Its own moment to get up from a seat or a job (still getting ready: add to it).
	if enemy._alarm_time >= 0.0:
		enemy._alarm_time += get_up_time()
	get_up()
	for n in enemy.get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Enemy
		if e == null or e == enemy or e.state != Enemy.State.IDLE or e.target != null or e.data.boss:
			continue
		var close := mates.has(e) or e.global_position.distance_to(enemy.global_position) <= ALERT_RANGE
		if close and _clear_between(e):
			var extra := e.post.get_up_time() if e.post else 0.0
			e.raise_alarm(p, READY_TIME + extra + _rng.randf_range(READY_STAGGER.x, READY_STAGGER.y), not enemy.data.caller)
			if e.post and e._alarm_time >= 0.0:
				e.post.get_up()


func _clear_between(e: Enemy) -> bool:
	var q := PhysicsRayQueryParameters3D.create(enemy.global_position + Vector3.UP * 1.5, e.global_position + Vector3.UP * 1.5, 1)
	return enemy.get_world_3d().direct_space_state.intersect_ray(q).is_empty()
