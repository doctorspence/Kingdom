class_name LegTwist
extends SkeletonModifier3D
## Sidesteps without strafe animations.
##
## Runs after the animation each frame: turns the hips (and so the legs) toward
## the way the character is stepping, then twists the spine back the same amount
## so the chest and head keep facing forward (at the foe). The walk or jog then
## carries the feet the right way instead of sliding sideways.
##
## CharacterModel sets `yaw` every frame; nothing else needs to touch this.

## How far the legs are turned from the chest, in radians (+ = to the left).
var yaw := 0.0

## How the counter-twist is shared out up the spine (adds up to 1).
const SPINE_SHARE: Array[float] = [0.35, 0.35, 0.3]

var _pelvis := -1
var _spine: Array[int] = []


## Find the bones. Returns false if this skeleton doesn't have them (animals).
func setup(skeleton: Skeleton3D) -> bool:
	_pelvis = skeleton.find_bone("pelvis")
	for bone_name in ["spine_01", "spine_02", "spine_03"]:
		var i := skeleton.find_bone(bone_name)
		if i >= 0:
			_spine.append(i)
	return _pelvis >= 0 and _spine.size() == SPINE_SHARE.size()


func _process_modification_with_delta(_delta: float) -> void:
	if absf(yaw) < 0.002:
		return
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	# "Up" in the skeleton's own space (the imported armature may be rotated or scaled).
	var up := (skeleton.global_basis.inverse() * Vector3.UP).normalized()
	_turn(skeleton, _pelvis, up, yaw)
	for i in _spine.size():
		_turn(skeleton, _spine[i], up, -yaw * SPINE_SHARE[i])


func _turn(skeleton: Skeleton3D, bone: int, up: Vector3, angle: float) -> void:
	var pose := skeleton.get_bone_global_pose(bone)
	pose.basis = Basis(up, angle) * pose.basis
	skeleton.set_bone_global_pose(bone, pose)
