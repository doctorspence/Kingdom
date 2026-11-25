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
var _rescan := 0.3  # first look round a moment after appearing, once its friends are in too
var _anim := &""
var _time_left := 0.0
var _look := Vector3.ZERO  # where it looks while standing (zero = its home facing)
var _rng := RandomNumberGenerator.new()


func _init(e: Enemy) -> void:
	enemy = e
	_rng.randomize()
	_style = e.data.calm_style
	enabled = _wanted()


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
	_rescan -= delta
	if _rescan <= 0.0:
		_find_mates(not _set_up)
		_set_up = true
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
func resume() -> void:
	_anim = &""
	_time_left = 0.0


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
		if e == null or e == enemy or e.post == null or not e.post.enabled or e.post.is_patrolling():
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
