extends SceneTree
## The fitted Outcast has its cloak fused into the "torso" and "legs" regions (and the collar into "head"), so armor
## could never take the cloak off and it clipped through every piece. This cuts the cloak out into its own
## "cloak" region: triangles that are olive-green, or that hang behind/outside the body. CharacterModel hides that
## region whenever armor is worn. Run it once on a freshly fitted model (it does nothing if "cloak" exists).
##   Godot_console.exe --headless --path . --script res://tools/fix_outcast_collar.gd [-- outcast_male]

const DIR := "res://assets/characters/outcast/"
const ATTRS := [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT, Mesh.ARRAY_COLOR, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2, Mesh.ARRAY_BONES, Mesh.ARRAY_WEIGHTS]


func _initialize() -> void:
	var name_ := "outcast_male"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		name_ = args[0]
	var src: ArrayMesh = load(DIR + name_ + ".res")
	var img: Image = (load(DIR + name_ + "_raw_0.png") as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	var surfaces := {}
	var order: Array = []
	for s in src.get_surface_count():
		var nm := src.surface_get_name(s)
		if nm == "cloak":
			print("cloak region already exists, nothing to do")
			quit()
			return
		surfaces[nm] = src.surface_get_arrays(s)
		order.append(nm)
	var cloak: Array = []
	cloak.resize(Mesh.ARRAY_MAX)
	var cloak_idx := PackedInt32Array()
	var remap := {}   # [surface name, vertex] -> cloak vertex
	for nm in ["head", "torso", "legs"]:
		var arr: Array = surfaces[nm]
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var keep := PackedInt32Array()
		for t in range(0, idx.size(), 3):
			var votes := 0
			for k in 3:
				var vi := idx[t + k]
				var p := v[vi]
				var c := img.get_pixelv(Vector2i(clampi(int(uv[vi].x * img.get_width()), 0, img.get_width() - 1), clampi(int(uv[vi].y * img.get_height()), 0, img.get_height() - 1)))
				var green: bool = c.g > c.r * 1.02 and c.g > c.b * 1.2 and c.v < 0.62
				var behind: bool = p.y > 0.85 and p.y < 1.62 and p.z < -0.135 and absf(p.x) < 0.45
				var behind_legs: bool = p.y <= 0.85 and p.z < -0.17
				var outside: bool = p.y < 1.33 and p.y > 0.3 and absf(p.x) > 0.31
				if nm == "head":
					if (green and p.y < 1.68) or (p.y < 1.64 and absf(p.x) > 0.115):
						votes += 1
				elif green or behind or behind_legs or outside:
					votes += 1
			if votes >= 2:
				for k in 3:
					var vi := idx[t + k]
					var key: String = nm + str(vi)
					if not remap.has(key):
						var n := 0
						for a in ATTRS:
							if arr[a] == null:
								continue
							if cloak[a] == null:
								cloak[a] = _empty_like(arr[a])
							var stride: int = int(arr[a].size() / v.size())
							for j in stride:
								cloak[a].append(arr[a][vi * stride + j])
						remap[key] = cloak[Mesh.ARRAY_VERTEX].size() - 1
					cloak_idx.append(remap[key])
			else:
				keep.append_array([idx[t], idx[t + 1], idx[t + 2]])
		print("cloak: %s keeps %d of %d triangles" % [nm, keep.size() / 3, idx.size() / 3])
		arr[Mesh.ARRAY_INDEX] = keep
	cloak[Mesh.ARRAY_INDEX] = cloak_idx
	print("cloak: %d triangles in the new region" % [cloak_idx.size() / 3])
	var out := ArrayMesh.new()
	for nm in order:
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surfaces[nm])
		out.surface_set_name(out.get_surface_count() - 1, nm)
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, cloak)
	out.surface_set_name(out.get_surface_count() - 1, "cloak")
	print("cloak: saved, err ", ResourceSaver.save(out, DIR + name_ + ".res"))
	quit()


## An empty packed array of the same type as a.
func _empty_like(a) -> Variant:
	match typeof(a):
		TYPE_PACKED_VECTOR3_ARRAY: return PackedVector3Array()
		TYPE_PACKED_VECTOR2_ARRAY: return PackedVector2Array()
		TYPE_PACKED_INT32_ARRAY: return PackedInt32Array()
		TYPE_PACKED_FLOAT32_ARRAY: return PackedFloat32Array()
		TYPE_PACKED_COLOR_ARRAY: return PackedColorArray()
	return []
