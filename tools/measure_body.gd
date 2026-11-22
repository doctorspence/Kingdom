extends SceneTree
func _initialize() -> void:
	var s: Node = (load("res://assets/characters/mannequin/UAL1_Standard.glb") as PackedScene).instantiate()
	root.add_child(s)
	var mi: MeshInstance3D = s.find_children("*", "MeshInstance3D", true, false)[0]
	var arr := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	print("verts ", verts.size())
	print("-- torso slices (y: xmin xmax zmin zmax)")
	var y := 0.85
	while y < 1.75:
		var lo := Vector3(9, 9, 9)
		var hi := Vector3(-9, -9, -9)
		var xlim := 0.3 if y < 1.36 else 0.17
		for v in verts:
			if absf(v.y - y) < 0.02 and absf(v.x) < xlim:
				lo = lo.min(v)
				hi = hi.max(v)
		print("y=%.2f x[%.3f %.3f] z[%.3f %.3f]" % [y, lo.x, hi.x, lo.z, hi.z])
		y += 0.05
	var segs := {"upperarm": [Vector3(0.192, 1.441, -0.065), Vector3(0.466, 1.441, -0.07)], "forearm": [Vector3(0.466, 1.441, -0.07), Vector3(0.739, 1.441, -0.065)],
		"thigh": [Vector3(0.089, 0.932, 0.001), Vector3(0.089, 0.532, -0.001)], "calf": [Vector3(0.089, 0.532, -0.001), Vector3(0.089, 0.104, -0.036)],
		"neck": [Vector3(0, 1.488, -0.011), Vector3(0, 1.569, 0.005)]}
	for k in segs:
		var a: Vector3 = segs[k][0]
		var b: Vector3 = segs[k][1]
		var ab := b - a
		var line := ""
		for ti in range(0, 11):
			var t := ti / 10.0
			var rmax := 0.0
			for v in verts:
				var tt := (v - a).dot(ab) / ab.length_squared()
				if absf(tt - t) < 0.04:
					var d := v.distance_to(a + ab * tt)
					if d < 0.25:
						rmax = maxf(rmax, d)
			line += " %.3f" % rmax
		print(k, " r(t=0..1):", line)
	# head
	var lo2 := Vector3(9, 9, 9)
	var hi2 := Vector3(-9, -9, -9)
	for v in verts:
		if v.y > 1.55 and absf(v.x) < 0.2:
			lo2 = lo2.min(v)
			hi2 = hi2.max(v)
	print("head box ", lo2, hi2)
	var f := Vector3(9, 9, 9)
	var g := Vector3(-9, -9, -9)
	for v in verts:
		if v.y < 0.12 and v.x > 0.0:
			f = f.min(v)
			g = g.max(v)
	print("foot box ", f, g)
	quit()
