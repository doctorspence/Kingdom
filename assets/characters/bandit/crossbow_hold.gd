extends SkeletonModifier3D
## Holds the crossbow in both hands, on top of whatever the body is playing. The game's archer
## uses the shared animations (there is no crossbow animation in the library), so this only moves
## the arms: carried low across the body while standing and moving, raised to the shoulder while
## shooting, and left alone for hits, the knockdown, the death and the close-range stab. Purely
## visual: attack timings and hits are untouched. It reads the model's current animation, so
## other players' screens show the same.

## Animations during which the crossbow is raised ...
const AIM: Array[StringName] = [&"Spell_Simple_Shoot", &"Spell_Simple_Enter", &"Spell_Simple_Idle"]
## ... and those during which it is carried.
const CARRY: Array[StringName] = [&"Idle", &"Sword_Idle", &"Walk", &"Walk_Formal", &"Jog_Fwd", &"Sprint"]
## [grip: right, up, forward of the upper chest (m)], [aim direction: right, up, forward],
## distance from the grip to the supporting hand, chest turn (degrees, left shoulder forward)
const CARRY_POSE := [Vector3(0.185, -0.285, 0.175), Vector3(-0.46, -0.36, 0.81), 0.225, 0.0]
const AIM_POSE := [Vector3(0.095, 0.045, 0.215), Vector3(0.0, 0.0, 1.0), 0.175, 26.0]
## How quickly the arms take up or let go of a pose (per second).
const BLEND := 7.0

var _model: Node3D
var _bones := {}
var _weight := 0.0
var _aim := 0.0


func setup(skeleton: Skeleton3D, model: Node3D) -> bool:
	_model = model
	for n in ["spine_02", "spine_03", "upperarm_r", "lowerarm_r", "hand_r", "upperarm_l", "lowerarm_l", "hand_l"]:
		_bones[n] = skeleton.find_bone(n)
		if _bones[n] < 0:
			return false
	return true


func _process_modification_with_delta(delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null or _model == null:
		return
	var anim: StringName = _model.current_anim()
	var aiming := AIM.has(anim)
	var want := 1.0 if aiming or CARRY.has(anim) else 0.0
	if _model.has_method(&"is_sheathed") and _model.is_sheathed():
		want = 0.0
	_weight = move_toward(_weight, want, delta * BLEND)
	_aim = move_toward(_aim, 1.0 if aiming else 0.0, delta * BLEND)
	if _weight <= 0.001:
		return

	var to_skel := skeleton.global_basis.inverse()
	var up := (to_skel * Vector3.UP).normalized()
	var forward := to_skel * _model.global_basis.z
	forward = (forward - up * forward.dot(up)).normalized()
	var right := forward.cross(up).normalized()
	var turn := deg_to_rad(lerpf(CARRY_POSE[3], AIM_POSE[3], _aim)) * _weight
	if absf(turn) > 0.001:
		_rotate_bone(skeleton, _bones.spine_02, up, -turn)

	var chest := skeleton.get_bone_global_pose(_bones.spine_03).origin
	var offset: Vector3 = (CARRY_POSE[0] as Vector3).lerp(AIM_POSE[0], _aim)
	var way: Vector3 = (CARRY_POSE[1] as Vector3).lerp(AIM_POSE[1], _aim)
	var grip := chest + right * offset.x + up * offset.y + forward * offset.z
	var along := (right * way.x + up * way.y + forward * way.z).normalized()
	var top := (up - along * up.dot(along)).normalized()
	var reach: float = lerpf(CARRY_POSE[2], AIM_POSE[2], _aim)

	# right hand on the grip: fingers along the stock, thumb up
	var right_basis := Basis(along.cross(top), along, top)
	_arm(skeleton, "r", grip - along * 0.075, (right - up * 0.7 - forward * 0.2).normalized(), right_basis)
	# left hand under the stock: palm up, fingers across it
	var support := grip + along * reach + top * 0.02
	var fingers := (right * 0.75 + along * 0.66).normalized()
	fingers = (fingers - top * fingers.dot(top)).normalized()
	var left_basis := Basis(top, fingers, top.cross(fingers))
	_arm(skeleton, "l", support - fingers * 0.065 - top * 0.030, (-right - up * 0.8).normalized(), left_basis)


## Two-bone reach to `target`, elbow toward `pole`, then turn the hand to `basis`.
func _arm(skeleton: Skeleton3D, side: String, target: Vector3, pole: Vector3, basis: Basis) -> void:
	var shoulder: int = _bones["upperarm_" + side]
	var elbow: int = _bones["lowerarm_" + side]
	var hand: int = _bones["hand_" + side]
	var s := skeleton.get_bone_global_pose(shoulder).origin
	var e := skeleton.get_bone_global_pose(elbow).origin
	var w := skeleton.get_bone_global_pose(hand).origin
	var a := s.distance_to(e)
	var b := e.distance_to(w)
	var to := target - s
	var d := clampf(to.length(), absf(a - b) + 0.01, a + b - 0.005)
	var u := to.normalized()
	var cos_s := clampf((a * a + d * d - b * b) / (2.0 * a * d), -1.0, 1.0)
	var n := pole - u * pole.dot(u)
	n = n.normalized() if n.length() > 0.001 else Vector3.DOWN
	var bend := s + u * a * cos_s + n * a * sqrt(1.0 - cos_s * cos_s)
	_aim_bone(skeleton, shoulder, e - s, bend - s)
	e = skeleton.get_bone_global_pose(elbow).origin
	w = skeleton.get_bone_global_pose(hand).origin
	_aim_bone(skeleton, elbow, w - e, s + u * d - e)
	var pose := skeleton.get_bone_global_pose(hand)
	var now := pose.basis.orthonormalized().get_rotation_quaternion()
	var goal := basis.orthonormalized().get_rotation_quaternion()
	pose.basis = Basis(now.slerp(goal, _weight))
	skeleton.set_bone_global_pose(hand, pose)


func _aim_bone(skeleton: Skeleton3D, bone: int, from: Vector3, to: Vector3) -> void:
	if from.length() < 0.0001 or to.length() < 0.0001:
		return
	var q := Quaternion(from.normalized(), to.normalized())
	var pose := skeleton.get_bone_global_pose(bone)
	pose.basis = Basis(Quaternion.IDENTITY.slerp(q, _weight)) * pose.basis
	skeleton.set_bone_global_pose(bone, pose)


func _rotate_bone(skeleton: Skeleton3D, bone: int, axis: Vector3, angle: float) -> void:
	var pose := skeleton.get_bone_global_pose(bone)
	pose.basis = Basis(axis, angle) * pose.basis
	skeleton.set_bone_global_pose(bone, pose)
