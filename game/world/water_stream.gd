class_name WaterStream
extends Node3D
## A shallow stream (the Gullet's river). Wading slows anyone in it a little.
## It is one smooth spline ribbon laid over the floor along `points`.

@export var points := PackedVector3Array()
@export var width := 2.0
## Move speed multiplier while wading.
@export var wade_speed := 0.8
@export var shader_material: ShaderMaterial

var _areas: Array[Area3D] = []


func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.3, 0.36, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.1
	mat.metallic = 0.3
	_build_ribbon(mat)
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var seg := b - a
		var length := seg.length()
		var mid := (a + b) * 0.5
		var yaw := atan2(-seg.z, seg.x)
		var area := Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 2 | 4
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(length + width * 0.5, 0.6, width)
		cs.shape = sh
		area.add_child(cs)
		area.position = mid + Vector3(0, 0.3, 0)
		area.rotation.y = yaw
		add_child(area)
		_areas.append(area)


func _spline(i: int, t: float) -> Vector3:
	var n := points.size()
	var p0 := points[maxi(i - 1, 0)]
	var p1 := points[i]
	var p2 := points[mini(i + 1, n - 1)]
	var p3 := points[mini(i + 2, n - 1)]
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
			+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t)


## One smooth ribbon along a spline through the points: width wanders, the edges fade out and
## the ends taper away, so there are no slab corners.
func _build_ribbon(mat: Material) -> void:
	var samples: Array[Vector3] = []
	for i in points.size() - 1:
		for k in 8:
			samples.append(_spline(i, k / 8.0))
	samples.append(points[points.size() - 1])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dist := 0.0
	var total := 0.0
	for i in range(1, samples.size()):
		total += samples[i].distance_to(samples[i - 1])
	var rows: Array = []
	for i in samples.size():
		if i > 0:
			dist += samples[i].distance_to(samples[i - 1])
		var tan_v := (samples[mini(i + 1, samples.size() - 1)] - samples[maxi(i - 1, 0)]).normalized()
		var side := tan_v.cross(Vector3.UP).normalized()
		var f := dist / maxf(total, 0.01)
		var taper := clampf(minf(dist, total - dist) / 3.0, 0.0, 1.0)
		var w := width * (0.9 + 0.2 * sin(dist * 0.35 + 1.3)) * (0.35 + 0.65 * taper) * 1.35
		rows.append([samples[i] + Vector3(0, 0.06, 0) - side * w * 0.5,
				samples[i] + Vector3(0, 0.06, 0) + side * w * 0.5, dist, taper, f])
	for i in rows.size() - 1:
		var r0: Array = rows[i]
		var r1: Array = rows[i + 1]
		var vs := [[r0[0], 0.0, r0[2], r0[3]], [r0[1], 1.0, r0[2], r0[3]],
				[r1[0], 0.0, r1[2], r1[3]], [r1[1], 1.0, r1[2], r1[3]]]
		for idx in [0, 2, 1, 1, 2, 3]:
			var v: Array = vs[idx]
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(v[1], v[2]))
			st.set_color(Color(1, 1, 1, v[3]))
			st.add_vertex(v[0])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if shader_material:
		var sm := shader_material.duplicate() as ShaderMaterial
		sm.set_shader_parameter("ribbon", true)
		mi.material_override = sm
	else:
		mi.material_override = mat
	add_child(mi)


func _physics_process(_delta: float) -> void:
	for area in _areas:
		for body in area.get_overlapping_bodies():
			if body is Player:
				var p := body as Player
				if p.is_multiplayer_authority():
					p.effects.add_mod(&"wading", 0.25, {"move": wade_speed})
			elif body is Enemy and multiplayer.is_server():
				(body as Enemy).effects.add_mod(&"wading", 0.25, {"move": wade_speed})
