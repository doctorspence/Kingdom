class_name StanceSteps
extends SkeletonModifier3D
## Footwork for a character who moves while holding a standing pose (fighting
## stance, guard up): instead of gliding, the feet step.
##
## Sideways it's a fighter's side-step: the lead foot steps out, the trail foot
## closes in, the feet never cross, and the knee lifts a little on each step.
## Forward and back it's short shuffling steps. The planted foot stays put on the
## ground (it moves back under the body exactly as fast as the body travels), so
## nothing slides.
##
## CharacterModel fills in the fields below every physics frame; this only bends
## the legs, after the animation has posed the rest of the body.

## 0 = off (animation only), 1 = full stepping. Fades in and out.
var weight := 0.0
## Step cycle position. One full cycle = each foot steps once.
var phase := 0.0
## Which way the body travels (world space, flat, length 1).
var move_dir := Vector3.FORWARD
## Which way the body faces (world space, flat, length 1).
var facing := Vector3.BACK
## How far the body travels in one cycle (meters).
var stride := 0.6
## Extra width added to each foot's stance while side-stepping (meters).
var widen := 0.1
## How high the stepping foot lifts (meters).
var lift := 0.09

var _legs: Array = []  # [thigh, calf, foot] bone indices, left then right


func setup(skeleton: Skeleton3D) -> bool:
	for side in ["l", "r"]:
		var bones := [skeleton.find_bone("thigh_" + side), skeleton.find_bone("calf_" + side),
				skeleton.find_bone("foot_" + side)]
		if bones.has(-1):
			return false
		_legs.append(bones)
	return true


func _process_modification_with_delta(_delta: float) -> void:
	if weight < 0.01:
		return
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	var to_skel := skeleton.global_basis.inverse()
	var meters := skeleton.global_basis.get_scale().x  # meters per skeleton unit
	var up := (to_skel * Vector3.UP).normalized()
	var fwd := (to_skel * facing).normalized()
	var right := fwd.cross(up).normalized()  # the character's own right
	var dir := (to_skel * move_dir).normalized()
	var sideways := absf(dir.dot(right))  # 1 = pure side-step, 0 = straight ahead/back
	var reach := stride * 0.25  # each foot swings this far either side of its rest spot

	for leg in 2:
		var bones: Array = _legs[leg]
		var outward := -right if leg == 0 else right
		# Left and right are half a cycle apart: one steps while the other is planted.
		var q := fposmod(phase + (0.0 if leg == 0 else 0.5), 1.0)
		var along: float
		var up_amount := 0.0
		if q < 0.5:
			var s := q / 0.5
			along = lerpf(-reach, reach, s * s * (3.0 - 2.0 * s))  # stepping: eases in and out
			up_amount = sin(PI * s) * lift
		else:
			along = lerpf(reach, -reach, (q - 0.5) / 0.5)  # planted: slides back under the body at its speed
		var offset := (dir * along + outward * widen * sideways) * weight
		_bend_leg(skeleton, bones, up, right, offset / meters, up_amount * weight / meters)


## Two-bone leg IK: put this leg's foot `offset` away (skeleton units, flat) from
## where the animation put it, raised by `raise`, keeping the sole as it was.
func _bend_leg(skeleton: Skeleton3D, bones: Array, up: Vector3, right: Vector3, offset: Vector3, raise: float) -> void:
	var thigh := skeleton.get_bone_global_pose(bones[0])
	var calf := skeleton.get_bone_global_pose(bones[1])
	var foot := skeleton.get_bone_global_pose(bones[2])
	var hip := thigh.origin
	var knee := calf.origin
	var ankle := foot.origin
	var a := hip.distance_to(knee)
	var b := knee.distance_to(ankle)
	if a < 0.0001 or b < 0.0001:
		return
	var target := ankle + offset + up * raise
	var reach := clampf(hip.distance_to(target), absf(a - b) + 0.0001, (a + b) * 0.999)

	# 1. Bend (or straighten) the knee so hip-to-ankle is the distance we need.
	var now := hip.distance_to(ankle)
	var bend_now := acos(clampf((a * a + b * b - now * now) / (2.0 * a * b), -1.0, 1.0))
	var bend_want := acos(clampf((a * a + b * b - reach * reach) / (2.0 * a * b), -1.0, 1.0))
	var hinge := (knee - hip).cross(ankle - knee)
	hinge = right if hinge.length() < 0.0001 else hinge.normalized()
	# Rotating the shin about the hinge by +x opens the knee or closes it; pick
	# whichever gives the right distance.
	var turn := bend_want - bend_now
	var shin := ankle - knee
	var try_a := knee + Basis(hinge, turn) * shin
	var try_b := knee + Basis(hinge, -turn) * shin
	var use := turn if absf(hip.distance_to(try_a) - reach) < absf(hip.distance_to(try_b) - reach) else -turn
	calf.basis = Basis(hinge, use) * calf.basis
	skeleton.set_bone_global_pose(bones[1], calf)
	var new_ankle := knee + Basis(hinge, use) * shin

	# 2. Aim the whole leg from the hip so the ankle lands on the target.
	var from := (new_ankle - hip).normalized()
	var to := (target - hip).normalized()
	if from.cross(to).length() > 0.00001:
		thigh.basis = Basis(Quaternion(from, to)) * thigh.basis
		skeleton.set_bone_global_pose(bones[0], thigh)

	# 3. Keep the sole as the animation had it.
	var sole := foot.basis
	foot = skeleton.get_bone_global_pose(bones[2])
	foot.basis = sole
	skeleton.set_bone_global_pose(bones[2], foot)
