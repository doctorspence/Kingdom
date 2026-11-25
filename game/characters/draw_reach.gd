class_name DrawReach
extends SkeletonModifier3D
## Drawing the sword from the left hip (ENEMY_LIFE_PLAN.md stage 7). The animation
## library has no draw move, so this bends the right arm on top of whatever plays:
## the hand reaches across to the grip, the sword jumps into it halfway, then the
## arm sweeps forward and up out of the scabbard and hands back to the animation.
## Started by CharacterModel.draw_weapon(); every machine runs it from the enemy's
## shared state, so nothing extra goes over the network.

const REACH_END := 0.42   # share of the draw spent reaching to the grip
const SWAP_AT := 0.5      # the sword leaves the hip and is in the hand
const PULL_FROM := 0.58   # then pulled out forward and up
const CHEST_TURN := 18.0  # degrees the chest turns toward the hip while reaching

var _model: CharacterModel
var _spine := -1
var _shoulder := -1
var _elbow := -1
var _hand := -1
var _shoulder_l := -1

var _time := -1.0
var _length := 0.45
var _grip: Node3D        # the hip holder: where the hand goes
var _swapped := false
var _cancelled := false


func setup(skeleton: Skeleton3D, model: CharacterModel) -> bool:
	_model = model
	_spine = skeleton.find_bone("spine_03")
	_shoulder = skeleton.find_bone("upperarm_r")
	_elbow = skeleton.find_bone("lowerarm_r")
	_hand = skeleton.find_bone("hand_r")
	_shoulder_l = skeleton.find_bone("upperarm_l")
	return _spine >= 0 and _shoulder >= 0 and _elbow >= 0 and _hand >= 0 and _shoulder_l >= 0


func begin(duration: float, grip: Node3D) -> void:
	_time = 0.0
	_length = maxf(duration, 0.1)
	_grip = grip
	_swapped = false
	_cancelled = false


func active() -> bool:
	return _time >= 0.0


## Cut short (an attack or a hit): the sword is simply in the hand.
func finish() -> void:
	if not active():
		return
	_time = -1.0
	if not _swapped:
		_swapped = true
		_model.sheathe(false)


## Called back to the hip mid-draw (the fight ended at once): stop, leave it there.
func cancel() -> void:
	_time = -1.0
	_swapped = true
	_cancelled = true


func _process_modification_with_delta(delta: float) -> void:
	if _time < 0.0:
		return
	_time += delta
	var p := _time / _length
	if p >= SWAP_AT and not _swapped:
		_swapped = true
		_swap.call_deferred()  # not mid-pose: it moves nodes
	if p >= 1.0:
		_time = -1.0
		return
	var skeleton := get_skeleton()
	if skeleton == null or not is_instance_valid(_grip):
		return
	var weight := smoothstep(0.0, REACH_END, p) * (1.0 - smoothstep(PULL_FROM, 1.0, p))
	if weight <= 0.001:
		return

	var to_skel := skeleton.global_basis.inverse()
	var up := (to_skel * Vector3.UP).normalized()
	var forward := to_skel * _model.global_basis.z
	forward = (forward - up * forward.dot(up)).normalized()
	var right := forward.cross(up).normalized()
	var shoulders := skeleton.get_bone_global_pose(_shoulder).origin - skeleton.get_bone_global_pose(_shoulder_l).origin
	if shoulders.dot(right) < 0.0:
		right = -right
		forward = up.cross(right).normalized()

	# The chest turns a little toward the left hip, bringing the right shoulder over.
	var turn := deg_to_rad(CHEST_TURN) * weight
	var spine := skeleton.get_bone_global_pose(_spine)
	spine.basis = Basis(up, turn if right.cross(forward).dot(up) > 0.0 else -turn) * spine.basis
	skeleton.set_bone_global_pose(_spine, spine)

	# Hand: at the grip, then out forward and up as the blade clears the scabbard.
	var grip := skeleton.global_transform.affine_inverse() * _grip.global_position
	var s := skeleton.get_bone_global_pose(_shoulder).origin
	var out := s + forward * 0.45 - up * 0.15 + right * 0.1
	var target := grip.lerp(out, smoothstep(SWAP_AT, 1.0, p))
	var pole := (right * 1.0 - forward * 0.4 - up * 0.3).normalized()
	_reach(skeleton, target, pole, weight)


func _swap() -> void:
	if not _cancelled:
		_model.sheathe(false)


## Two-bone reach: bend the elbow toward `pole` so the hand lands on `target`.
func _reach(skeleton: Skeleton3D, target: Vector3, pole: Vector3, weight: float) -> void:
	var s := skeleton.get_bone_global_pose(_shoulder).origin
	var e := skeleton.get_bone_global_pose(_elbow).origin
	var w := skeleton.get_bone_global_pose(_hand).origin
	var a := s.distance_to(e)
	var b := e.distance_to(w)
	var to := target - s
	var d := clampf(to.length(), absf(a - b) + 0.01, a + b - 0.01)
	var u := to.normalized()
	var cos_s := clampf((a * a + d * d - b * b) / (2.0 * a * d), -1.0, 1.0)
	var n := pole - u * pole.dot(u)
	n = n.normalized() if n.length() > 0.001 else Vector3.UP
	var elbow := s + u * a * cos_s + n * a * sqrt(1.0 - cos_s * cos_s)
	var hand := s + u * d
	_aim_bone(skeleton, _shoulder, e - s, elbow - s, weight)
	e = skeleton.get_bone_global_pose(_elbow).origin
	w = skeleton.get_bone_global_pose(_hand).origin
	_aim_bone(skeleton, _elbow, w - e, hand - e, weight)


func _aim_bone(skeleton: Skeleton3D, bone: int, from: Vector3, to: Vector3, weight: float) -> void:
	if from.length() < 0.0001 or to.length() < 0.0001:
		return
	var q := Quaternion(from.normalized(), to.normalized())
	var pose := skeleton.get_bone_global_pose(bone)
	pose.basis = Basis(Quaternion.IDENTITY.slerp(q, weight)) * pose.basis
	skeleton.set_bone_global_pose(bone, pose)
