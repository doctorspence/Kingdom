extends MeshInstance3D
## Moonlight rays at night: a full-screen pass (shaders/moon_rays.gdshader) that
## spreads light out from the moon on screen, blocked by anything solid in front of
## it, so trees, roofs and the edges of the woods cut dark gaps in the light.
## Made by DayNight, which sets `strength` (night, out of the rain, above ground).
## The rays fade out when the moon is behind you or off the edge of the screen.

## The light the rays come from (DayNight's sun, which is the moon at night).
var moon: DirectionalLight3D
## 0..1, how strong the rays are right now.
var strength := 0.0

var _mat: ShaderMaterial


func _ready() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://game/world/shaders/moon_rays.gdshader")
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	mesh = quad
	material_override = _mat
	extra_cull_margin = 16384.0  # the quad is drawn over the whole screen wherever the camera is
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if moon == null or cam == null or strength <= 0.01:
		visible = false
		return
	var to_moon := moon.global_transform.basis.z
	var vp := get_viewport().get_visible_rect().size
	var facing := clampf(to_moon.dot(-cam.global_transform.basis.z), 0.0, 1.0)
	var far_point := cam.global_position + to_moon * 1000.0
	var uv := Vector2(0.5, 0.5)
	if not cam.is_position_behind(far_point):
		uv = cam.unproject_position(far_point) / vp
	var edge := maxf(absf(uv.x - 0.5), absf(uv.y - 0.5))
	var k := strength * smoothstep(0.3, 0.7, facing) * (1.0 - smoothstep(0.6, 1.1, edge))
	visible = k > 0.005
	_mat.set_shader_parameter("moon_uv", uv)
	_mat.set_shader_parameter("aspect", vp.x / vp.y)
	_mat.set_shader_parameter("visible_k", k)
