class_name OverheadChop
extends SkeletonModifier3D
## The jumping light attack: a straight overhead chop, seen square from behind.
##
## The animation library has no clean vertical chop (its sword swings all twist the
## body and cut diagonally), so this builds one on top of a plain airborne pose.
## While the clip CLIP plays, it bends the right arm (two-bone IK) so the sword hand
## travels a vertical arc in front of the body: up overhead, a short hold, then
## down and forward. The wrist turns the blade with it (cocked back while raised,
## forward-down at the blow) and the chest leans back then over into the cut.
##
## It reads the animation's own clock, so other players' screens show it too.
## Timings below are in that clip's seconds; WeaponData's jump_light hit window
## matches the blow (KEYS[3]).

const CLIP := &"cut/Jump_Chop"

## [time, hand angle (degrees: 0 = straight ahead of the shoulder, 90 = straight up,
## negative = below), blade cock (degrees the blade is tipped back past the arm)]
const KEYS := [
	[0.00, 25.0, 40.0],
	[0.12, 112.0, 60.0],   # raised overhead, blade cocked back
	[0.17, 115.0, 62.0],   # held a beat at the top
	[0.27, -48.0, 6.0],    # the blow: down past the right leg, blade in line
	[0.55, -42.0, 8.0],
]
const ARC_RADIUS := 0.5       # meters from the shoulder to the hand
const TOWARD_CENTER := 0.13   # hand pulled in toward the body's middle line while raised ...
const END_OUTSIDE := 0.26     # ... and finishing this far out to the right, so the blow shows past the body from behind
const BLEND_IN := 0.05        # seconds to take over the arm
const BLEND_OUT_FROM := 0.55  # then hand it back by the clip's end
const LEAN_BACK := 12.0       # chest leans back as the sword goes up (degrees) ...
const LEAN_INTO := 22.0       # ... and over into the cut

var _anim: AnimationPlayer
var _model: Node3D
var _spine := -1
var _shoulder := -1
var _elbow := -1
var _hand := -1
var _shoulder_l := -1
var _elbow_l := -1
var _hand_l := -1


func setup(skeleton: Skeleton3D, anim: AnimationPlayer, model: Node3D) -> bool:
	_model = model
	_anim = anim
	_spine = skeleton.find_bone("spine_03")
	_shoulder = skeleton.find_bone("upperarm_r")
	_elbow = skeleton.find_bone("lowerarm_r")
	_hand = skeleton.find_bone("hand_r")
	_shoulder_l = skeleton.find_bone("upperarm_l")
	_elbow_l = skeleton.find_bone("lowerarm_l")
	_hand_l = skeleton.find_bone("hand_l")
	return _spine >= 0 and _shoulder >= 0 and _elbow >= 0 and _hand >= 0 and _shoulder_l >= 0 and _elbow_l >= 0 and _hand_l >= 0


func _process_modification_with_delta(_delta: float) -> void:
	if _anim == null or _anim.current_animation != CLIP:
		return
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	var t := _anim.current_animation_position
	var length := _anim.current_animation_length
	var weight := clampf(t / BLEND_IN, 0.0, 1.0) * clampf((length - t) / maxf(length - BLEND_OUT_FROM, 0.01), 0.0, 1.0)
	if weight <= 0.001:
		return
	var key := _sample(t)
	var angle := deg_to_rad(key.x)
	var cock := deg_to_rad(key.y)

	# Directions in the skeleton's own space, from the way the character faces
	# (the model's +Z), not from the pose (this airborne pose has its chest turned).
	var to_skel := skeleton.global_basis.inverse()
	var up := (to_skel * Vector3.UP).normalized()
	var forward := to_skel * _model.global_basis.z
	forward = (forward - up * forward.dot(up)).normalized()
	var right := forward.cross(up).normalized()
	var shoulders := skeleton.get_bone_global_pose(_shoulder).origin - skeleton.get_bone_global_pose(_shoulder_l).origin
	if shoulders.dot(right) < 0.0:
		right = -right  # in case this skeleton is mirrored
		forward = up.cross(right).normalized()

	# Square the chest to the front, so the chop is seen straight on.
	shoulders = (shoulders - up * shoulders.dot(up)).normalized()
	var twist := shoulders.signed_angle_to(right, up)
	_rotate_bone(skeleton, _spine, up, twist * weight)

	# Lean: back while raising, over into the blow.
	var lean := lerpf(-LEAN_BACK, LEAN_INTO, clampf(inverse_lerp(90.0, -45.0, key.x), 0.0, 1.0))
	_rotate_bone(skeleton, _spine, right, -deg_to_rad(lean) * weight)  # + angle about "right" leans back

	# Arm: reach the point on the arc.
	var s := skeleton.get_bone_global_pose(_shoulder).origin
	var down_by := clampf(inverse_lerp(90.0, -45.0, key.x), 0.0, 1.0)
	var side := lerpf(-TOWARD_CENTER, END_OUTSIDE, down_by)
	var target := s + right * side + (forward * cos(angle) + up * sin(angle)) * ARC_RADIUS
	var pole := (right - up * 0.5).normalized()
	_reach(skeleton, target, pole, weight)

	# Off hand (shield): tucked in front of the body instead of flung out.
	var sl := skeleton.get_bone_global_pose(_shoulder_l).origin
	_aim_bone(skeleton, _shoulder_l, skeleton.get_bone_global_pose(_elbow_l).origin - sl, -up * 0.8 + forward * 0.45 - right * 0.2, weight)
	var el := skeleton.get_bone_global_pose(_elbow_l).origin
	_aim_bone(skeleton, _elbow_l, skeleton.get_bone_global_pose(_hand_l).origin - el, forward * 0.85 + right * 0.3 + up * 0.15, weight)

	# Wrist: blade (the hand's +Z) along the arc, tipped back by `cock`.
	var blade_angle := angle + cock
	var blade := forward * cos(blade_angle) + up * sin(blade_angle)
	var hand := skeleton.get_bone_global_pose(_hand)
	var now := hand.basis.z.normalized()
	var turn := Quaternion(now, blade.normalized())
	hand.basis = Basis(Quaternion.IDENTITY.slerp(turn, weight)) * hand.basis
	skeleton.set_bone_global_pose(_hand, hand)


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


## Turn a bone (about its own joint) so `from` points along `to`.
func _aim_bone(skeleton: Skeleton3D, bone: int, from: Vector3, to: Vector3, weight: float) -> void:
	if from.length() < 0.0001 or to.length() < 0.0001:
		return
	var q := Quaternion(from.normalized(), to.normalized())
	var pose := skeleton.get_bone_global_pose(bone)
	pose.basis = Basis(Quaternion.IDENTITY.slerp(q, weight)) * pose.basis
	skeleton.set_bone_global_pose(bone, pose)


func _rotate_bone(skeleton: Skeleton3D, bone: int, axis: Vector3, angle: float) -> void:
	var pose := skeleton.get_bone_global_pose(bone)
	pose.basis = Basis(axis, angle) * pose.basis
	skeleton.set_bone_global_pose(bone, pose)


## Hand angle and blade cock at clip time `t` (degrees), smoothly between the keys.
func _sample(t: float) -> Vector2:
	if t <= float(KEYS[0][0]):
		return Vector2(KEYS[0][1], KEYS[0][2])
	for i in range(1, KEYS.size()):
		if t <= float(KEYS[i][0]):
			var k0: Array = KEYS[i - 1]
			var k1: Array = KEYS[i]
			var f: float = (t - float(k0[0])) / (float(k1[0]) - float(k0[0]))
			# The blow accelerates (ease in); everything else eases in and out.
			f = f * f if i == 3 else smoothstep(0.0, 1.0, f)
			return Vector2(lerpf(float(k0[1]), float(k1[1]), f), lerpf(float(k0[2]), float(k1[2]), f))
	var last: Array = KEYS[KEYS.size() - 1]
	return Vector2(last[1], last[2])
