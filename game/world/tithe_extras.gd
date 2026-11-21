class_name TitheExtras
extends Node3D
## Finishing touches for the Tithelands, all made in code so they cost one node:
## the White Knight checkpoint (banners, market stalls, notice board, braziers),
## ferns in the woods, puddles on the roads, and a slow daytime cloud layer.
## Everything is seeded, so every player sees the same layout.

@export var terrain: ZoneTerrain
@export var sun: DirectionalLight3D
## Moves the checkpoint dressing along the road (it was built for the old checkpoint at z = -78).
@export var checkpoint_shift := 0.0

const CLOTH := preload("res://levels/common/materials/cloth_white.tres")
const WOOD := preload("res://levels/common/materials/dark_wood.tres")
const IRON := preload("res://levels/common/materials/iron.tres")
const PLANKS := preload("res://levels/common/materials/wood.tres")

var _clouds: MeshInstance3D
var _shift := 0.0
var _cloud_mat: ShaderMaterial


func _ready() -> void:
	if terrain == null:
		terrain = get_node_or_null("../Terrain") as ZoneTerrain
	if sun == null:
		sun = get_node_or_null("../Sun") as DirectionalLight3D
	_checkpoint()
	if DisplayServer.get_name() == "headless":
		return  # visuals only: keep automated checks fast
	_ferns()
	_puddles()
	_cloud_layer()


func _process(_delta: float) -> void:
	if _cloud_mat == null or sun == null:
		return
	var cam := get_viewport().get_camera_3d()
	if cam:
		_clouds.global_position = Vector3(cam.global_position.x, 230.0, cam.global_position.z)
	# Brightness follows the sun (dim at night and in rain), so clouds never glow at night.
	var b := clampf(sun.light_energy, 0.0, 1.0)
	_cloud_mat.set_shader_parameter("tint", Color(0.5, 0.52, 0.56) * (0.25 + 0.75 * b))


# ---- checkpoint -------------------------------------------------------------

func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, rot := Vector3.ZERO, solid := false) -> Node3D:
	if solid:
		var b := CSGBox3D.new()
		b.use_collision = true
		b.size = size
		b.material = mat
		b.position = pos
		b.rotation_degrees = rot
		parent.add_child(b)
		return b
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


func _ground(x: float, z: float) -> float:
	return terrain.height_at(x, z + _shift) if terrain else 0.0


func _checkpoint() -> void:
	var root := Node3D.new()
	root.name = "CheckpointDressing"
	root.position.z = checkpoint_shift
	_shift = checkpoint_shift
	add_child(root)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.55, 0.43, 0.2)
	gold.metallic = 0.6
	gold.roughness = 0.5
	# Tall banner poles lining the road south of the barricades, both sides.
	for i in 3:
		for side in [-1.0, 1.0]:
			var x: float = side * 5.6
			var z := -60.0 - i * 6.0
			var y := _ground(x, z)
			_box(root, Vector3(x, y + 3.2, z), Vector3(0.18, 6.4, 0.18), WOOD, Vector3.ZERO, true)
			_box(root, Vector3(x, y + 6.3, z), Vector3(0.4, 0.4, 0.4), gold)
			_box(root, Vector3(x - side * 0.7, y + 5.4, z), Vector3(0.12, 0.1, 1.5), WOOD)
			_box(root, Vector3(x - side * 0.7, y + 3.9, z), Vector3(0.05, 3.0, 1.3), CLOTH)
			_box(root, Vector3(x - side * 0.73, y + 3.9, z), Vector3(0.04, 2.2, 0.2), gold)
			_box(root, Vector3(x - side * 0.73, y + 4.4, z), Vector3(0.04, 0.2, 0.9), gold)
	# Market stalls on the west verge.
	for i in 3:
		var sx := -11.0
		var sz := -64.0 - i * 6.5
		_stall(root, Vector3(sx, _ground(sx, sz), sz), 90.0)
	# A notice board by the road.
	var nb := Vector3(7.5, _ground(7.5, -64.0), -64.0)
	_box(root, nb + Vector3(0, 1.3, 0), Vector3(0.14, 2.6, 0.14), WOOD, Vector3.ZERO, true)
	_box(root, nb + Vector3(0, 2.0, 0.1), Vector3(1.6, 1.0, 0.08), PLANKS)
	_box(root, nb + Vector3(0.3, 2.0, 0.17), Vector3(0.5, 0.7, 0.02), CLOTH)
	# Braziers either side of the barricade.
	for side in [-1.0, 1.0]:
		var p := Vector3(side * 8.5, _ground(side * 8.5, -78.0), -78.0)
		_box(root, p + Vector3(0, 0.6, 0), Vector3(0.7, 1.2, 0.7), IRON, Vector3.ZERO, true)
		var fm := StandardMaterial3D.new()
		fm.albedo_color = Color(1.0, 0.55, 0.2)
		fm.emission_enabled = true
		fm.emission = Color(1.0, 0.5, 0.18)
		fm.emission_energy_multiplier = 4.0
		_box(root, p + Vector3(0, 1.3, 0), Vector3(0.5, 0.35, 0.5), fm)
		var l := OmniLight3D.new()
		l.position = p + Vector3(0, 1.8, 0)
		l.light_color = Color(1.0, 0.6, 0.3)
		l.light_energy = 1.8
		l.omni_range = 11.0
		root.add_child(l)


func _stall(parent: Node3D, pos: Vector3, yaw: float) -> void:
	var s := Node3D.new()
	s.position = pos
	s.rotation_degrees.y = yaw
	parent.add_child(s)
	for sx in [-1.3, 1.3]:
		_box(s, Vector3(sx, 1.25, -0.8), Vector3(0.14, 2.5, 0.14), WOOD, Vector3.ZERO, true)
		_box(s, Vector3(sx, 0.9, 0.9), Vector3(0.14, 1.8, 0.14), WOOD, Vector3.ZERO, true)
	_box(s, Vector3(0, 0.55, 0.0), Vector3(3.0, 0.18, 1.8), PLANKS, Vector3.ZERO, true)
	_box(s, Vector3(0, 0.25, 0.0), Vector3(2.8, 0.5, 1.6), WOOD, Vector3.ZERO, true)
	_box(s, Vector3(0, 2.3, 0.05), Vector3(3.5, 0.08, 2.4), CLOTH, Vector3(-9, 0, 0))
	var goods := StandardMaterial3D.new()
	goods.albedo_color = Color(0.38, 0.28, 0.16)
	for i in 4:
		_box(s, Vector3(-1.0 + i * 0.65, 0.78, 0.0), Vector3(0.4, 0.3, 0.4), goods, Vector3(0, i * 20, 0))


# ---- ferns ------------------------------------------------------------------

func _fern_mesh() -> ArrayMesh:
	# A rosette of eight arching fronds, each a thin tapering strip.
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	for f in 8:
		var a := TAU * f / 8.0
		var dir := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-dir.z, 0, dir.x)
		var pts := []
		for k in 5:
			var t := k / 4.0
			var out := 0.9 * t
			var up := 0.7 * sin(t * PI * 0.9) - 0.25 * t * t
			var w := 0.16 * (1.0 - t) + 0.01
			pts.append([dir * out + Vector3.UP * up, w])
		for k in 4:
			var p0: Vector3 = pts[k][0]
			var p1: Vector3 = pts[k + 1][0]
			var w0: float = pts[k][1]
			var w1: float = pts[k + 1][1]
			var q := [p0 - side * w0, p0 + side * w0, p1 + side * w1, p1 - side * w1]
			var c0 := Color(0.5 + 0.5 * k / 4.0, 1, 1)
			for idx in [0, 1, 2, 0, 2, 3]:
				verts.append(q[idx])
				norms.append(Vector3.UP)
				cols.append(c0)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = cols
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.17, 0.27, 0.12)
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.9
	m.surface_set_material(0, mat)
	return m


func _ferns() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var xforms: Array[Transform3D] = []
	var half := terrain.size * 0.5 - 30.0
	var tries := 0
	while xforms.size() < 700 and tries < 8000:
		tries += 1
		var p := Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))
		# Ferns like the shade: the woods (or, without a forest map, the east and west).
		var sculpted := terrain as SculptedTerrain
		if sculpted and sculpted.land and sculpted.land.has_method("forest"):
			if rng.randf() > 0.15 + 0.85 * float(sculpted.land.forest(p.x, p.y)):
				continue
			if sculpted.in_pad(p.x, p.y) > 0.05:
				continue
		elif absf(p.x) < 30.0 and rng.randf() < 0.8:
			continue
		if minf(terrain._distance_to_lines(terrain.roads, p), terrain._distance_to_lines(terrain.tracks, p) + 2.0) < 4.0:
			continue
		if terrain.river_distance(p.x, p.y) < 5.0:
			continue
		var h := terrain.height_at(p.x, p.y)
		if (terrain is SculptedTerrain and h < terrain.water_level_at(p.x, p.y) + 0.3) or (not (terrain is SculptedTerrain) and (h < -0.5 or h > 10.0)):
			continue
		for j in rng.randi_range(1, 3):
			var q := p + Vector2(rng.randf_range(-1.5, 1.5), rng.randf_range(-1.5, 1.5))
			var s := rng.randf_range(0.7, 1.5)
			var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s))
			xforms.append(Transform3D(b, Vector3(q.x, terrain.height_at(q.x, q.y) - 0.03, q.y)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _fern_mesh()
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Ferns"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 120.0
	add_child(mmi)


# ---- puddles ----------------------------------------------------------------

func _puddles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.03, 0.035, 0.04, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.04
	mat.metallic = 0.2
	mat.metallic_specular = 0.9
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = 0.02
	mesh.radial_segments = 14
	var half := terrain.size * 0.5 - 20.0
	var xforms: Array[Transform3D] = []
	var tries := 0
	while xforms.size() < 60 and tries < 6000:
		tries += 1
		var p := Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))
		var d := minf(terrain._distance_to_lines(terrain.roads, p), terrain._distance_to_lines(terrain.tracks, p) + 1.0)
		if d > 2.2 or d < 0.4:
			continue
		if terrain.river_distance(p.x, p.y) < 6.0:
			continue
		var h0 := terrain.height_at(p.x, p.y)
		if absf(terrain.height_at(p.x + 1.5, p.y) - h0) + absf(terrain.height_at(p.x, p.y + 1.5) - h0) > 0.06:
			continue  # puddles only lie where the road is level
		var r := rng.randf_range(0.5, 1.2)
		var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(r * rng.randf_range(1.0, 1.7), 1.0, r))
		xforms.append(Transform3D(b, Vector3(p.x, h0 + 0.012, p.y)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Puddles"
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


# ---- clouds -----------------------------------------------------------------

const CLOUD_SHADER := "
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec4 tint : source_color = vec4(0.5, 0.52, 0.56, 1.0);
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 uv = wpos.xz / 900.0 + vec2(TIME * 0.0035, TIME * 0.0012);
	float n = texture(noise_tex, uv).r;
	float n2 = texture(noise_tex, uv * 2.3 + 0.37).r;
	float c = smoothstep(0.5, 0.78, n * 0.7 + n2 * 0.3);
	float fade = 1.0 - smoothstep(220.0, 540.0, length(wpos.xz - CAMERA_POSITION_WORLD.xz));
	ALBEDO = tint.rgb;
	ALPHA = c * 0.55 * fade;
}
"


func _cloud_layer() -> void:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.012
	noise.fractal_octaves = 4
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.seamless = true
	tex.width = 512
	tex.height = 512
	var sh := Shader.new()
	sh.code = CLOUD_SHADER
	_cloud_mat = ShaderMaterial.new()
	_cloud_mat.shader = sh
	_cloud_mat.set_shader_parameter("noise_tex", tex)
	var pm := PlaneMesh.new()
	pm.size = Vector2(3000, 3000)
	_clouds = MeshInstance3D.new()
	_clouds.name = "Clouds"
	_clouds.mesh = pm
	_clouds.material_override = _cloud_mat
	_clouds.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_clouds)
