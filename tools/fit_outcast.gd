extends SceneTree
## Fits a raw image-to-3D Outcast (one static mesh in a T-pose, e.g. from TRELLIS) onto the UAL1
## skeleton so it plays every animation:
##   1. scales it to the game's character size and lines its arms up with the skeleton's arms,
##   2. weights every vertex to the nearest bones (like the armor, see eq_mesh.gd),
##   3. ties loose cloth below the hips (cloak, hanging sash) to the hips instead of the legs,
##   4. saves <name>.res (skinned mesh) + <name>_albedo.png next to the raw file.
## Run windowed (it reads the texture back from the GPU):
##   Godot_console.exe --path . --script res://tools/fit_outcast.gd -- outcast_male [scale]

const DIR := "res://assets/characters/outcast/"
const A := preload("res://assets/equipment/eq_armor.gd")

const BONES := ["pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "Head",
	"clavicle_l", "upperarm_l", "lowerarm_l", "hand_l", "clavicle_r", "upperarm_r", "lowerarm_r", "hand_r",
	"thigh_l", "calf_l", "foot_l", "thigh_r", "calf_r", "foot_r"]
const LEG := ["thigh_l", "calf_l", "foot_l", "thigh_r", "calf_r", "foot_r"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var name_: String = args[0] if args.size() > 0 else "outcast_male"
	var scale_ := float(args[1]) if args.size() > 1 else 1.83
	var scene: Node = (load(DIR + name_ + "_raw.glb") as PackedScene).instantiate()
	root.add_child(scene)
	var src: MeshInstance3D = scene.find_children("*", "MeshInstance3D", true, false)[0]
	var arr := src.mesh.surface_get_arrays(0)
	var mat := src.mesh.surface_get_material(0) as StandardMaterial3D
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var norms := PackedVector3Array()
	if arr[Mesh.ARRAY_NORMAL] != null:
		norms = arr[Mesh.ARRAY_NORMAL]

	# 1. size and placement: feet on the ground, then the forearms onto the skeleton's forearms
	var lo := Vector3(1e9, 1e9, 1e9)
	for v in verts:
		lo = lo.min(v * scale_)
	var off := Vector3(0, -lo.y, 0)
	var arm_sum := Vector3.ZERO
	var arm_n := 0
	for v in verts:
		var p := v * scale_ + off
		if absf(p.x) > 0.5 and absf(p.x) < 0.65:
			arm_sum += Vector3(0, p.y, p.z)
			arm_n += 1
	var bone_arm := (A.bp("lowerarm_l") + A.bp("hand_l")) * 0.5
	if arm_n > 0:
		var mean := arm_sum / arm_n
		off.z += bone_arm.z - mean.z
		off.y += clampf(bone_arm.y - mean.y, -0.05, 0.05)   # small nudge only: keep the feet near the ground
	print("fit: scale %.3f, offset %s, arm samples %d" % [scale_, off, arm_n])
	var out_v := PackedVector3Array()
	out_v.resize(verts.size())
	for i in verts.size():
		out_v[i] = verts[i] * scale_ + off

	# 2. + 3. weights
	var segs := A.segs(BONES)
	var leg_idx := {}
	for n in LEG:
		leg_idx[A.rig().bones[n].i] = true
	var pelvis_i: int = A.rig().bones["pelvis"].i
	var spine_i: int = A.rig().bones["spine_01"].i
	var hip_y: float = A.bp("thigh_l").y
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	bones.resize(out_v.size() * 4)
	weights.resize(out_v.size() * 4)
	var loose := 0
	for i in out_v.size():
		var p := out_v[i]
		var cand: Array = []
		var leg_d := 1e9
		for s in segs:
			var a: Vector3 = s[1]
			var b: Vector3 = s[2]
			var ab := b - a
			var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
			var d := p.distance_to(a + ab * t)
			if leg_idx.has(s[0]):
				leg_d = minf(leg_d, d)
			cand.append([s[0], 1.0 / (pow(d, 4.0) + 1e-6)])
		cand.sort_custom(func(x, y): return x[1] > y[1])
		var w: Array = []
		var total := 0.0
		for k in 3:
			total += cand[k][1]
		for k in 3:
			w.append([cand[k][0], cand[k][1] / total])
		# loose cloth: below the hips and well away from the legs (cloak, sash) hangs from the hips
		var on_leg := 0.0
		for e in w:
			if leg_idx.has(e[0]):
				on_leg += e[1]
		if p.y < hip_y + 0.05 and on_leg > 0.0 and p.y > 0.2:
			var keep := 1.0 - smoothstep(0.1, 0.17, leg_d)
			if keep < 1.0:
				loose += 1
				var moved := on_leg * (1.0 - keep)
				for e in w:
					if leg_idx.has(e[0]):
						e[1] *= keep
				w.append([pelvis_i, moved * 0.75])
				w.append([spine_i, moved * 0.25])
		# merge duplicates, keep the 4 strongest, normalize
		var merged := {}
		for e in w:
			merged[e[0]] = merged.get(e[0], 0.0) + e[1]
		var list: Array = []
		for k in merged:
			list.append([k, merged[k]])
		list.sort_custom(func(x, y): return x[1] > y[1])
		var tot := 0.0
		for k in mini(4, list.size()):
			tot += list[k][1]
		for k in 4:
			if k < list.size():
				bones[i * 4 + k] = list[k][0]
				weights[i * 4 + k] = list[k][1] / tot
			else:
				bones[i * 4 + k] = 0
				weights[i * 4 + k] = 0.0
	print("fit: %d vertices, %d tied to the hips as loose cloth" % [out_v.size(), loose])

	# 4. save: texture as a PNG, a plain material, and the skinned mesh
	var tex_path := DIR + name_ + "_raw_0.png"
	var new_arr := arr.duplicate()
	new_arr[Mesh.ARRAY_VERTEX] = out_v
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	new_arr[Mesh.ARRAY_NORMAL] = norms if norms.size() == out_v.size() else _normals(out_v, idx)
	new_arr[Mesh.ARRAY_BONES] = bones
	new_arr[Mesh.ARRAY_WEIGHTS] = weights
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, new_arr)
	var m := StandardMaterial3D.new()
	m.resource_name = name_
	m.roughness = 0.9
	m.metallic = 0.0
	if ResourceLoader.exists(tex_path) or FileAccess.file_exists(ProjectSettings.globalize_path(tex_path)):
		m.set_meta("albedo_png", tex_path)
	mesh.surface_set_material(0, m)
	var err := ResourceSaver.save(mesh, DIR + name_ + ".res")
	print("fit: saved %s (err %d), texture %s" % [DIR + name_ + ".res", err, tex_path])
	quit()


## Smooth normals from the triangles (the raw file may carry none).
static func _normals(v: PackedVector3Array, idx: PackedInt32Array) -> PackedVector3Array:
	var n := PackedVector3Array()
	n.resize(v.size())
	var count := idx.size() if not idx.is_empty() else v.size()
	for t in range(0, count, 3):
		var a := idx[t] if not idx.is_empty() else t
		var b := idx[t + 1] if not idx.is_empty() else t + 1
		var c := idx[t + 2] if not idx.is_empty() else t + 2
		var fn := (v[c] - v[a]).cross(v[b] - v[a])   # Godot front faces are clockwise
		n[a] += fn
		n[b] += fn
		n[c] += fn
	for i in n.size():
		n[i] = n[i].normalized() if n[i].length_squared() > 0.0 else Vector3.UP
	return n
