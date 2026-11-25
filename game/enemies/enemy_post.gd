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
	elif not is_patrolling():
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
	if is_patrolling():
		var ahead: Enemy = null
		for m in _patrol_mates():
			if ahead == null or m.post.leg > ahead.post.leg:
				ahead = m
		if ahead:
			leg = ahead.post.leg
			enemy._patrol_i = ahead._patrol_i


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
	if _time_left <= 0.0 or _anim == &"":
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
	for n in enemy.get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Enemy
		if e == null or e == enemy or e.state != Enemy.State.IDLE or e.target != null or e.data.boss:
			continue
		var close := mates.has(e) or e.global_position.distance_to(enemy.global_position) <= ALERT_RANGE
		if close and _clear_between(e):
			e.raise_alarm(p, READY_TIME + _rng.randf_range(READY_STAGGER.x, READY_STAGGER.y), not enemy.data.caller)


func _clear_between(e: Enemy) -> bool:
	var q := PhysicsRayQueryParameters3D.create(enemy.global_position + Vector3.UP * 1.5, e.global_position + Vector3.UP * 1.5, 1)
	return enemy.get_world_3d().direct_space_state.intersect_ray(q).is_empty()
