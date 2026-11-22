extends SceneTree
## Renders every equipment item's inventory icon from its own 3D model: 512x512 source plus a
## 256x256 icon, transparent background, same camera angle and lighting for all, a dark outline
## and a soft drop shadow so the shapes read at 40-64 px.
## Needs a real window (not --headless):
##   Godot_console.exe --path . --resolution 320x200 --script res://tools/render_equipment_icons.gd [-- id1,id2]
## Armor is rendered on the mannequin skeleton (see eq_armor.gd preview()).

const Catalog := preload("res://assets/equipment/eq_catalog.gd")
const Builder := preload("res://tools/build_equipment.gd")
const W := preload("res://assets/equipment/eq_weapons.gd")
const A := preload("res://assets/equipment/eq_armor.gd")
const BASE := "res://assets/equipment/InventoryIcons/"
const N := 512

var _vp: SubViewport
var _pivot: Node3D
var _cam: Camera3D


func _initialize() -> void:
	_run.call_deferred()


func _setup() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(N, N)
	_vp.transparent_bg = true
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.5, 0.58, 0.72)
	sm.sky_horizon_color = Color(0.85, 0.78, 0.7)
	sm.ground_horizon_color = Color(0.5, 0.42, 0.34)
	sm.ground_bottom_color = Color(0.16, 0.13, 0.1)
	sky.sky_material = sm
	env.sky = sky
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.7
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.rotation_degrees = Vector3(-42, -32, 0)
	_vp.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.45
	fill.light_color = Color(0.7, 0.78, 1.0)
	fill.rotation_degrees = Vector3(-10, 140, 0)
	_vp.add_child(fill)
	_pivot = Node3D.new()
	_vp.add_child(_pivot)
	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.position = Vector3(0, 0, 5)
	_vp.add_child(_cam)


## How the item is turned for its icon (a slight three-quarter angle).
func _display_basis(e: Dictionary) -> Basis:
	var view := Basis(Vector3.RIGHT, deg_to_rad(-16)) * Basis(Vector3.UP, deg_to_rad(26))
	match e.kind:
		"shield":
			return Basis(Vector3.RIGHT, deg_to_rad(-8)) * Basis(Vector3.UP, deg_to_rad(-24)) * W.SHIELD_BASIS.inverse()
		"armor":
			return Basis(Vector3.RIGHT, deg_to_rad(-6)) * Basis(Vector3.UP, deg_to_rad(18))
		_:
			var roll := -45.0
			if e.build == "bow":
				roll = -30.0
			return view * Basis(Vector3.BACK, deg_to_rad(roll))


func _fit(node: Node3D, b: Basis, kind: String) -> void:
	var lo := Vector3(1e9, 1e9, 1e9)
	var hi := -lo
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m: Mesh = (mi as MeshInstance3D).mesh
		var xf: Transform3D = _local_xf(mi, node)
		var bb := m.get_aabb()
		for i in 8:
			var p: Vector3 = b * (xf * bb.get_endpoint(i))
			lo = lo.min(p)
			hi = hi.max(p)
	if node.has_meta("icon_aabb"):
		var ab: AABB = node.get_meta("icon_aabb")
		lo = ab.position
		hi = ab.end
	var ext := hi - lo
	var size := maxf(ext.x, ext.y) * 1.14
	size = maxf(size, {"dagger": 0.7, "mace": 0.95, "shield": 0.9, "armor": 0.7}.get(kind, 0.0))
	_cam.size = size
	var c := (lo + hi) * 0.5
	_pivot.basis = b
	node.position = Vector3.ZERO
	_cam.position = Vector3(c.x, c.y, 5)


func _local_xf(n: Node3D, root_: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != root_:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf


func _run() -> void:
	_setup()
	var args := OS.get_cmdline_user_args()
	var only := PackedStringArray()
	if args.size() > 0 and args[0] != "all":
		only = args[0].split(",")
	var all: Array = Catalog.entries()
	all.append_array(Catalog.armor_entries())
	var done := 0
	for e in all:
		if not only.is_empty() and not (String(e.id) in only):
			continue
		var spath := Builder.scene_path(e)
		var node: Node3D
		if e.kind == "armor":
			node = A.preview(e, load(spath) as PackedScene)
		else:
			node = (load(spath) as PackedScene).instantiate()
		_pivot.add_child(node)
		if e.kind == "armor":
			await process_frame
			A.pose_preview(node)
		_fit(node, _display_basis(e), e.kind if e.kind != "weapon" else (e.build if e.build in ["dagger", "mace"] else ""))
		for i in 8:
			await RenderingServer.frame_post_draw
		var img := _vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		var folder := "Armor" if e.folder == "Armor" else "Weapons"
		DirAccess.make_dir_recursive_absolute(BASE + folder)
		DirAccess.make_dir_recursive_absolute(BASE + "Source512")
		var fin := _polish(img)
		fin.save_png("%sSource512/%s.png" % [BASE, e.id])
		var small := fin.duplicate() as Image
		small.resize(256, 256, Image.INTERPOLATE_LANCZOS)
		small.save_png("%s%s/%s.png" % [BASE, folder, e.id])
		_pivot.remove_child(node)
		node.free()
		done += 1
		print("icon ", e.id)
	print("icons: ", done)
	quit()


## Dark outline + soft drop shadow around the rendered item.
func _polish(img: Image) -> Image:
	var data := img.get_data()
	var a := PackedByteArray()
	a.resize(N * N)
	for i in N * N:
		a[i] = data[i * 4 + 3]
	# outline: alpha dilated by 3 px (separable max)
	var d1 := _max_filter(a, 3, true)
	var dil := _max_filter(d1, 3, false)
	# shadow: blurred alpha, shifted down-right
	var sh := _blur(a, 7)
	var out := Image.create(N, N, false, Image.FORMAT_RGBA8)
	var ob := PackedByteArray()
	ob.resize(N * N * 4)
	for y in N:
		for x in N:
			var i := y * N + x
			var sx := x - 12
			var sy := y - 14
			var shadow := 0.0
			if sx >= 0 and sy >= 0:
				shadow = sh[sy * N + sx] / 255.0 * 0.38
			var item_a := data[i * 4 + 3] / 255.0
			var ol := (dil[i] / 255.0) * 0.96
			# layers: shadow, outline, item
			var r := 0.0
			var g := 0.0
			var b := 0.0
			var al := shadow
			if ol > 0.0:
				var na := ol + al * (1.0 - ol)
				r = (0.05 * ol) / maxf(na, 0.001)
				g = (0.04 * ol) / maxf(na, 0.001)
				b = (0.035 * ol) / maxf(na, 0.001)
				al = na
			if item_a > 0.0:
				var ir: float = data[i * 4] / 255.0
				var ig: float = data[i * 4 + 1] / 255.0
				var ib: float = data[i * 4 + 2] / 255.0
				var na2 := item_a + al * (1.0 - item_a)
				r = (ir * item_a + r * al * (1.0 - item_a)) / maxf(na2, 0.001)
				g = (ig * item_a + g * al * (1.0 - item_a)) / maxf(na2, 0.001)
				b = (ib * item_a + b * al * (1.0 - item_a)) / maxf(na2, 0.001)
				al = na2
			ob[i * 4] = int(clampf(r, 0.0, 1.0) * 255.0)
			ob[i * 4 + 1] = int(clampf(g, 0.0, 1.0) * 255.0)
			ob[i * 4 + 2] = int(clampf(b, 0.0, 1.0) * 255.0)
			ob[i * 4 + 3] = int(clampf(al, 0.0, 1.0) * 255.0)
	return Image.create_from_data(N, N, false, Image.FORMAT_RGBA8, ob)


func _max_filter(src: PackedByteArray, r: int, horizontal: bool) -> PackedByteArray:
	var dst := PackedByteArray()
	dst.resize(N * N)
	for y in N:
		for x in N:
			var best := 0
			for k in range(-r, r + 1):
				var xx := x + (k if horizontal else 0)
				var yy := y + (0 if horizontal else k)
				if xx < 0 or yy < 0 or xx >= N or yy >= N:
					continue
				var v := src[yy * N + xx]
				if v > best:
					best = v
			dst[y * N + x] = best
	return dst


func _blur(src: PackedByteArray, r: int) -> PackedByteArray:
	var tmp := PackedByteArray()
	tmp.resize(N * N)
	var dst := PackedByteArray()
	dst.resize(N * N)
	var w := float(2 * r + 1)
	for y in N:
		for x in N:
			var s := 0
			for k in range(-r, r + 1):
				var xx := clampi(x + k, 0, N - 1)
				s += src[y * N + xx]
			tmp[y * N + x] = int(s / w)
	for y in N:
		for x in N:
			var s := 0
			for k in range(-r, r + 1):
				var yy := clampi(y + k, 0, N - 1)
				s += tmp[yy * N + x]
			dst[y * N + x] = int(s / w)
	return dst
