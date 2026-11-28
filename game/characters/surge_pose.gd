extends RefCounted
## Builds the Arcane Surge cast clip ("cut/Arcane_Surge", see CharacterModel._add_cut_clips).
##
## There is no two-handed channelling animation in the libraries, so this bakes one:
## a base clip (Idle) is copied, and the spine and both arms are replaced by poses
## solved with a two-bone IK from where the hands should be. The result is an ordinary
## Animation, so it plays (and mirrors over the network) like any other clip.
##
## Timeline (seconds): gather 0-0.35 (hands rise and come together in front of the
## chest), channel 0.35-1.0 (held, a slight tremble that grows), release 1.0-1.2 (both
## palms thrust forward, body leans in), recovery 1.2-1.45 (arms drop back to the idle pose).

const LENGTH := 1.45
const STEP := 1.0 / 30.0

## Hand targets, in metres from the chest (spine_03): x = outward from the body's middle,
## y = up, z = forward.
const HAND_WIDE := Vector3(0.32, -0.22, 0.10)
const HAND_HELD := Vector3(0.075, 0.02, 0.34)
const HAND_THRUST := Vector3(0.20, 0.06, 0.74)
## Twist of each hand about its forearm (radians), so the palms face the way they should.
const HAND_ROLL_HELD := 0.0
const HAND_ROLL_THRUST := 0.0

const SPINE := [&"spine_01", &"spine_02", &"spine_03"]
const SPINE_SHARE := [0.4, 0.35, 0.25]


static func build(sk: Skeleton3D, base: Animation) -> Animation:
	var n := sk.get_bone_count()
	for b in [&"spine_01", &"spine_02", &"spine_03", &"clavicle_l", &"clavicle_r", &"upperarm_l", &"upperarm_r",
			&"lowerarm_l", &"lowerarm_r", &"hand_l", &"hand_r", &"foot_l", &"ball_l"]:
		if sk.find_bone(b) < 0:
			return null

	# --- Track lookup in the base clip -----------------------------------------------
	var rot_track := PackedInt32Array()
	var pos_track := PackedInt32Array()
	rot_track.resize(n)
	pos_track.resize(n)
	rot_track.fill(-1)
	pos_track.fill(-1)
	var prefix := ""
	for t in base.get_track_count():
		var path := String(base.track_get_path(t))
		if not ":" in path:
			continue
		prefix = path.get_slice(":", 0)
		var bone := sk.find_bone(path.get_slice(":", 1))
		if bone < 0:
			continue
		match base.track_get_type(t):
			Animation.TYPE_ROTATION_3D: rot_track[bone] = t
			Animation.TYPE_POSITION_3D: pos_track[bone] = t

	# --- Body axes, from the rest pose -----------------------------------------------
	var rest_g: Array[Transform3D] = []
	rest_g.resize(n)
	for i in n:
		var p := sk.get_bone_parent(i)
		rest_g[i] = (rest_g[p] if p >= 0 else Transform3D.IDENTITY) * sk.get_bone_rest(i)
	var up := Vector3.UP
	var right := rest_g[sk.find_bone(&"clavicle_r")].origin - rest_g[sk.find_bone(&"clavicle_l")].origin
	right = Vector3(right.x, 0.0, right.z).normalized()
	var fwd := rest_g[sk.find_bone(&"ball_l")].origin - rest_g[sk.find_bone(&"foot_l")].origin
	fwd = Vector3(fwd.x, 0.0, fwd.z).normalized()
	if fwd.length() < 0.5:
		fwd = up.cross(right)
	var chest := sk.find_bone(&"spine_03")
	var chest_rest_basis := rest_g[chest].basis

	var out := Animation.new()
	out.length = LENGTH
	var out_rot := {}  # bone -> track index
	var out_pos := {}
	for i in n:
		if rot_track[i] >= 0 or _overridden(sk.get_bone_name(i)):
			var j := out.add_track(Animation.TYPE_ROTATION_3D)
			out.track_set_path(j, NodePath("%s:%s" % [prefix, sk.get_bone_name(i)]))
			out_rot[i] = j
		if pos_track[i] >= 0:
			var j2 := out.add_track(Animation.TYPE_POSITION_3D)
			out.track_set_path(j2, NodePath("%s:%s" % [prefix, sk.get_bone_name(i)]))
			out_pos[i] = j2

	var spine_idx: Array[int] = []
	for s in SPINE:
		spine_idx.append(sk.find_bone(s))
	var sides := [[&"l", -1.0], [&"r", 1.0]]

	var t := 0.0
	while true:
		var at := minf(t, LENGTH)
		var tb := fposmod(at, base.length)
		# 1. Base locals.
		var rot: Array[Quaternion] = []
		var pos: Array[Vector3] = []
		rot.resize(n)
		pos.resize(n)
		for i in n:
			var rest := sk.get_bone_rest(i)
			rot[i] = base.rotation_track_interpolate(rot_track[i], tb) if rot_track[i] >= 0 else rest.basis.get_rotation_quaternion()
			pos[i] = base.position_track_interpolate(pos_track[i], tb) if pos_track[i] >= 0 else rest.origin
		# 2. Forward kinematics with the spine leaning (a pitch about the body's right axis).
		var lean := _lean(at)
		var g: Array[Transform3D] = []
		g.resize(n)
		for i in n:
			var p := sk.get_bone_parent(i)
			var pg := g[p] if p >= 0 else Transform3D.IDENTITY
			var gi := pg * Transform3D(Basis(rot[i]), pos[i])
			var si := spine_idx.find(i)
			if si >= 0:
				gi.basis = Basis(Quaternion(right, -lean * SPINE_SHARE[si])) * gi.basis
				rot[i] = (pg.basis.get_rotation_quaternion().inverse() * gi.basis.get_rotation_quaternion()).normalized()
			g[i] = gi
		# 3. Arms.
		var w := _weight(at)
		for side in sides:
			var sfx: String = side[0]
			var out_sign: float = side[1]
			var c := sk.find_bone("clavicle_" + sfx)
			var u := sk.find_bone("upperarm_" + sfx)
			var l := sk.find_bone("lowerarm_" + sfx)
			var h := sk.find_bone("hand_" + sfx)
			var gu_base := g[c].basis.get_rotation_quaternion() * rot[u]
			var shoulder := g[c] * pos[u]
			var target := _hand_target(at, out_sign, right, up, fwd, chest_rest_basis, g[chest])
			var l1 := sk.get_bone_rest(l).origin.length()
			var l2 := sk.get_bone_rest(h).origin.length()
			var d := target - shoulder
			var dist := clampf(d.length(), absf(l1 - l2) + 0.01, l1 + l2 - 0.005)
			var dhat := d.normalized()
			var x := (dist * dist + l1 * l1 - l2 * l2) / (2.0 * dist)
			var hh := sqrt(maxf(l1 * l1 - x * x, 0.0))
			var hint := -up * 0.9 + right * out_sign * 0.5
			var perp := (hint - dhat * hint.dot(dhat)).normalized()
			var elbow := shoulder + dhat * x + perp * hh
			var tip := shoulder + dhat * dist
			var dir_u := (elbow - shoulder).normalized()
			var dir_l := (tip - elbow).normalized()
			var axis_u := sk.get_bone_rest(l).origin.normalized()
			var axis_l := sk.get_bone_rest(h).origin.normalized()
			var gu := Quaternion(gu_base * axis_u, dir_u) * gu_base
			var gl_base := gu * rot[l]
			var gl := Quaternion(gl_base * axis_l, dir_l) * gl_base
			var gh_base := gl * rot[h]
			var roll := lerpf(HAND_ROLL_HELD, HAND_ROLL_THRUST, _thrust(at))
			var gh := Quaternion(dir_l, roll * out_sign) * gh_base
			var cq := g[c].basis.get_rotation_quaternion()
			rot[u] = rot[u].slerp((cq.inverse() * gu).normalized(), w)
			rot[l] = rot[l].slerp((gu.inverse() * gl).normalized(), w)
			rot[h] = rot[h].slerp((gl.inverse() * gh).normalized(), w)
		# 4. Write the keys.
		for i in out_rot:
			out.rotation_track_insert_key(out_rot[i], at, rot[i])
		for i in out_pos:
			out.position_track_insert_key(out_pos[i], at, pos[i])
		if at >= LENGTH:
			break
		t += STEP
	return out


static func _overridden(bone: String) -> bool:
	return bone.begins_with("spine_0") or bone.begins_with("upperarm_") or bone.begins_with("lowerarm_") or bone.begins_with("hand_")


static func _ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


## How much of the arm pose is the surge pose (0 = the idle clip's arms).
static func _weight(t: float) -> float:
	return _ease(t / 0.3) * (1.0 - _ease((t - 1.18) / 0.27))


## 0 until the release, then 1 as the palms thrust out.
static func _thrust(t: float) -> float:
	return 1.0 - pow(1.0 - clampf((t - 1.0) / 0.12, 0.0, 1.0), 2.0)


## Body lean in radians: back a little while gathering, forward into the release.
static func _lean(t: float) -> float:
	var back := -0.06 * _ease(t / 0.35)
	var shake := 0.012 * sin(t * 41.0) * _ease((t - 0.35) / 0.65) * (1.0 - _thrust(t))
	var into := 0.26 * _thrust(t)
	var recover := 1.0 - _ease((t - 1.2) / 0.25)
	return (back + shake + into) * recover


static func _hand_target(t: float, out_sign: float, right: Vector3, up: Vector3, fwd: Vector3,
		chest_rest_basis: Basis, chest_global: Transform3D) -> Vector3:
	var held := HAND_WIDE.lerp(HAND_HELD, _ease(t / 0.35))
	var tremble := 0.01 * _ease((t - 0.35) / 0.65) * (1.0 - _thrust(t))
	held += Vector3(sin(t * 37.0), sin(t * 29.0 + 1.0), sin(t * 33.0 + 2.0)) * tremble
	held.z += 0.03 * _ease((t - 0.35) / 0.65)  # reaches out a touch as the charge builds
	var spot := held.lerp(HAND_THRUST, _thrust(t))
	var off := right * out_sign * spot.x + up * spot.y + fwd * spot.z
	return chest_global * (chest_rest_basis.inverse() * off)
