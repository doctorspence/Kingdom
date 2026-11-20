class_name AttackRunner
extends RefCounted
## Plays one attack: advances its clock, keeps the animation in sync, switches
## to the follow-through animation, and says when the weapon can hit.
## Shared by players and enemies.

var attack: AttackData
var t := 0.0
var hit_targets: Array[Node] = []

var _model: CharacterModel
var _in_recovery := false


func start(a: AttackData, model: CharacterModel) -> void:
	attack = a
	_model = model
	t = 0.0
	_in_recovery = false
	hit_targets.clear()
	model.play(a.anim, 0.08, a.anim_speed, true)


## Advance by `delta` real seconds. `extra_mult` slows or freezes it (charging, hit-stop).
func step(delta: float, extra_mult := 1.0) -> void:
	var mult := extra_mult
	if t < attack.windup_until:
		mult *= attack.windup_speed_mult
	var speed := attack.anim_speed * mult
	t += delta * speed
	_model.set_speed(speed)
	if not _in_recovery and attack.recovery_anim != &"" and t >= _model.anim_length(attack.anim):
		_in_recovery = true
		_model.play(attack.recovery_anim, 0.06, speed, true)
		_model.seek(t - _model.anim_length(attack.anim))


func in_hit_window() -> bool:
	return t >= attack.hit_start and t <= attack.hit_end


func past(time: float) -> bool:
	return t >= time


func done() -> bool:
	return t >= attack.end_time


## Forward speed (m/s) from the attack's lunge right now.
func lunge_speed() -> float:
	var span := attack.lunge_end - attack.lunge_start
	if span <= 0.0 or t < attack.lunge_start or t > attack.lunge_end:
		return 0.0
	return attack.lunge_distance / (span / attack.anim_speed)


## Who is inside the swing right now (each target only once per attack).
func find_new_targets(attacker: Node3D, forward: Vector3, group: StringName) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for n in attacker.get_tree().get_nodes_in_group(group):
		var target := n as Node3D
		if target == null or target == attacker or hit_targets.has(target):
			continue
		if not target.has_method("receive_hit"):
			continue
		var radius: float = target.call("hit_radius") if target.has_method("hit_radius") else 0.4
		var to := target.global_position - attacker.global_position
		if absf(to.y) > 2.0:
			continue
		to.y = 0.0
		var dist := to.length()
		if dist > attack.reach + radius:
			continue
		if dist > radius and rad_to_deg(forward.angle_to(to)) > attack.arc_degrees * 0.5:
			continue
		hit_targets.append(target)
		result.append(target)
	return result
