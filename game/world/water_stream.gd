class_name WaterStream
extends Node3D
## A shallow stream (the Gullet's river). Wading slows anyone in it a little.
## It is a chain of thin water slabs laid over the floor along `points`.

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
	mat.emission_enabled = true
	mat.emission = Color(0.04, 0.08, 0.1)
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var seg := b - a
		var length := seg.length()
		var mid := (a + b) * 0.5
		var yaw := atan2(-seg.z, seg.x)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(length + width * 0.5, 0.1, width)
		if shader_material:
			var sm := shader_material.duplicate() as ShaderMaterial
			sm.set_shader_parameter("flow", Vector2(seg.x, seg.z).normalized())
			bm.material = sm
		else:
			bm.material = mat
		mi.mesh = bm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = mid + Vector3(0, 0.05, 0)
		mi.rotation.y = yaw
		add_child(mi)
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


func _physics_process(_delta: float) -> void:
	for area in _areas:
		for body in area.get_overlapping_bodies():
			if body is Player:
				var p := body as Player
				if p.is_multiplayer_authority():
					p.effects.add_mod(&"wading", 0.25, {"move": wade_speed})
			elif body is Enemy and multiplayer.is_server():
				(body as Enemy).effects.add_mod(&"wading", 0.25, {"move": wade_speed})
