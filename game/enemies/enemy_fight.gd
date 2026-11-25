class_name EnemyFight
extends RefCounted
## How an enemy looks while it fights (ENEMY_LIFE_PLAN.md stage 6): its stance,
## what it does while waiting its turn to attack (taunts, guard poses), and how it
## acts when badly hurt. Looks only: no rule changes. The host decides; clients see
## it through the shared animation (net_anim), like every other animation.

## Below this share of health it is hurt: a hunched stance and more stepping back.
const HURT_AT := 1.0 / 3.0
## Seconds between poses while waiting its turn (hurt: the second pair).
const POSE_GAP := Vector2(2.5, 5.0)
const POSE_GAP_HURT := Vector2(1.4, 3.0)
## While hurt, this share of the breaks is a step back instead of a pose.
const HURT_STEP_BACK := 0.6
const STEP_BACK_TIME := Vector2(0.5, 0.8)

const STANCE_SHIELD := &"ual2/Idle_Shield"   # upright behind the shield (Knights)
const STANCE_HURT := &"ual2/Zombie_Idle"     # hunched, weapon low
const TAUNT_RAISE := &"ual2/Idle_Rail_Call"  # sword raised overhead
const TAUNT_NO := &"ual2/Idle_No"            # shakes its head

var enemy: Enemy
## The stance it was made with (bosses and anyone left out keep it).
var base_idle: StringName
## False: bosses, archers, hounds. They keep their own look.
var enabled := false
var disciplined := false
var has_shield := false

var _next := 0.0
var _pose_left := 0.0
var _pose_anim := &""
var _back_left := 0.0
var _last_frame := -10


func _init(e: Enemy) -> void:
	enemy = e
	base_idle = e.model.idle_anim
	disciplined = e.data.calm_style == "disciplined"
	has_shield = e.data.offhand_scene != null
	enabled = not e.data.boss and e.data.keep_distance <= 0.0 and e.model.has_anim(STANCE_HURT)
	_next = randf_range(POSE_GAP.x, POSE_GAP.y)


func is_hurt() -> bool:
	return enemy.health_ratio() < HURT_AT and enemy.health > 0.0


## In a fight, judged from the state alone (friends' machines don't know the target).
func in_fight() -> bool:
	return enemy.state in [Enemy.State.CHASE, Enemy.State.ATTACK, Enemy.State.STAGGER,
			Enemy.State.PARRIED, Enemy.State.RIPOSTED, Enemy.State.GUARD]


## The stance for now: calm (not fighting) = the one it was made with.
func stance() -> StringName:
	if not enabled or not in_fight():
		return base_idle
	if is_hurt() and not disciplined:
		return STANCE_HURT
	if disciplined and has_shield:
		return STANCE_SHIELD
	return base_idle


## Every frame, on every machine: which pose counts as "standing" (so feet step
## from it). On the host also slows the stance when hurt (heavy, tired breathing).
func update_stance() -> void:
	var s := stance()
	enemy.model.idle_anim = s
	if enabled and enemy._is_host() and in_fight() and enemy.model.current_anim() == s and is_hurt():
		enemy.model.set_speed(0.7)


## Waiting its turn, in range of the target: now and then stop circling for a
## taunt or a guard pose, or (hurt) step back. True = it moved/animated itself.
func wait(delta: float, to: Vector3) -> bool:
	if not enabled:
		return false
	var frame := Engine.get_physics_frames()
	if frame - _last_frame > 2:
		# Just started waiting (or came back from an attack): no half-done pose.
		_pose_left = 0.0
		_back_left = 0.0
	_last_frame = frame
	if _pose_left > 0.0:
		_pose_left -= delta
		enemy._move(Vector3.ZERO, delta)
		enemy.model.play(_pose_anim, 0.2)
		return true
	if _back_left > 0.0:
		_back_left -= delta
		enemy._move(-to.normalized() * enemy.data.walk_speed * 0.8, delta)
		enemy.model.play(enemy.model.idle_anim, 0.2)  # backs off in its stance, the feet stepping
		return true
	_next -= delta
	if _next > 0.0:
		return false
	var hurt := is_hurt()
	var gap := POSE_GAP_HURT if hurt else POSE_GAP
	_next = randf_range(gap.x, gap.y)
	if hurt and randf() < HURT_STEP_BACK:
		_back_left = randf_range(STEP_BACK_TIME.x, STEP_BACK_TIME.y)
		return false
	_pose_anim = _pick_pose(hurt)
	if _pose_anim == &"":
		return false
	_pose_left = minf(enemy.model.anim_length(_pose_anim), 2.2) if _pose_anim != STANCE_SHIELD else randf_range(1.6, 2.6)
	enemy.model.play(_pose_anim, 0.2, 1.0, true)
	return true


func _pick_pose(hurt: bool) -> StringName:
	var poses: Array[StringName] = []
	if disciplined:
		# Knights don't taunt: they stand their ground behind the shield.
		poses.append(STANCE_SHIELD if has_shield else TAUNT_RAISE)
	elif hurt:
		poses = [TAUNT_NO]
	else:
		poses = [TAUNT_RAISE, TAUNT_NO]
		if has_shield:
			poses.append(STANCE_SHIELD)
	var usable := poses.filter(func(a: StringName) -> bool: return enemy.model.has_anim(a))
	return usable.pick_random() if not usable.is_empty() else &""


## Is it in the middle of a pose (for checks and pictures)? An attack cuts it short.
func is_posing() -> bool:
	return _pose_left > 0.0 and Engine.get_physics_frames() - _last_frame <= 1


func is_stepping_back() -> bool:
	return _back_left > 0.0 and Engine.get_physics_frames() - _last_frame <= 1
