extends SceneTree
## Turns a sculpted armor model (one dense static mesh, normalized to about 1 m tall, front toward +Z) into a
## game-size piece fitted to the Outcast's torso: simplifies it (meshoptimizer LODs), scales it onto the body, and
## saves a compact ArrayMesh the armor builder (eq_armor.gd) paints and skins like any other piece.
##   Godot_console.exe --headless --path . --script res://tools/prepare_glb_armor.gd -- <glb> <out.res> [lod] [sx sy sz] [y0] [zc]
## Defaults fit the plate cuirass: LOD 3 (about 1/16 of the triangles), hem at y 0.80, neck at 1.58.

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var glb: String = a[0]
	var out: String = a[1]
	var lod := int(a[2]) if a.size() > 2 else 3
	var sx := float(a[3]) if a.size() > 3 else 0.8
	var sy := float(a[4]) if a.size() > 4 else 0.78
	var sz := float(a[5]) if a.size() > 5 else 0.62
	var y0 := float(a[6]) if a.size() > 6 else 0.80
	var zc := float(a[7]) if a.size() > 7 else -0.03
	var shear_x := float(a[8]) if a.size() > 8 else 0.0   # legs: how far each leg is pushed outward at the ankle
	var shear_z := float(a[9]) if a.size() > 9 else 0.0   # and back (z), fading to nothing at the top
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path(glb), st) != OK:
		push_error("cannot read " + glb)
		quit(1)
		return
	var model := doc.generate_scene(st)
	var mi: MeshInstance3D = model.find_children("*", "MeshInstance3D", true, false)[0]
	var arr := mi.mesh.surface_get_arrays(0)
	var im := ImporterMesh.new()
	im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arr)
	im.generate_lods(25.0, 25.0, [])
	lod = mini(lod, im.get_surface_lod_count(0) - 1)
	var idx: PackedInt32Array = im.get_surface_lod_indices(0, lod) if lod >= 0 else arr[Mesh.ARRAY_INDEX]
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var remap := {}
	var ov := PackedVector3Array()
	var on := PackedVector3Array()
	var oi := PackedInt32Array()
	var sc := Vector3(sx, sy, sz)
	for i in idx:
		if not remap.has(i):
			remap[i] = ov.size()
			var p := v[i]
			var fall := 1.0 - clampf(p.y, 0.0, 1.0)
			ov.append(Vector3(p.x * sx + tanh(p.x / 0.03) * shear_x * fall, y0 + p.y * sy, zc + p.z * sz + shear_z * fall))
			on.append((n[i] / sc).normalized())
		oi.append(remap[i])
	var oa := []
	oa.resize(Mesh.ARRAY_MAX)
	oa[Mesh.ARRAY_VERTEX] = ov
	oa[Mesh.ARRAY_NORMAL] = on
	oa[Mesh.ARRAY_INDEX] = oi
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, oa)
	print("prepared: LOD %d, %d triangles, %d vertices -> %s (err %d)" % [lod, oi.size() / 3, ov.size(), out, ResourceSaver.save(m, out)])
	quit()
