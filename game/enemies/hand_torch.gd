class_name HandTorch
extends Node3D
## A torch carried by a watcher at night (ENEMY_LIFE_PLAN.md stage 7): a wooden
## stick, a pitch-wrapped head, a small flame and a flickering warm light (no
## shadows, so it costs little; see ShadowBudget). Built in code. The stick runs
## along +Y with the grip at the origin. drop() lets it fall and burn out on the ground.

const LIGHT_ENERGY := 1.8
const LIGHT_RANGE := 8.0
const BURN_ON_GROUND := 25.0  # seconds a dropped torch keeps burning

var _light: OmniLight3D
var _flame: MeshInstance3D
var _phase := randf() * TAU
var _dropped := false
var _strength := 1.0  # fades to 0 as a dropped torch burns out


func _ready() -> void:
	var stick := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.022
	sm.bottom_radius = 0.026
	sm.height = 0.6
	sm.radial_segments = 6
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.3, 0.2, 0.12)
	wood.roughness = 0.9
	sm.material = wood
	stick.mesh = sm
	stick.position.y = 0.12
	add_child(stick)

	var head := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.045
	hm.bottom_radius = 0.035
	hm.height = 0.13
	hm.radial_segments = 8
	var pitch := StandardMaterial3D.new()
	pitch.albedo_color = Color(0.09, 0.07, 0.05)
	pitch.roughness = 1.0
	hm.material = pitch
	head.mesh = hm
	head.position.y = 0.44
	add_child(head)

	_flame = MeshInstance3D.new()
	var fm := SphereMesh.new()
	fm.radius = 0.055
	fm.height = 0.2
	fm.radial_segments = 8
	fm.rings = 4
	var fire := StandardMaterial3D.new()
	fire.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fire.albedo_color = Color(1.0, 0.72, 0.32)
	fire.emission_enabled = true
	fire.emission = Color(1.0, 0.5, 0.12)
	fire.emission_energy_multiplier = 3.0
	fm.material = fire
	_flame.mesh = fm
	_flame.position.y = 0.58
	_flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_flame)

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.6, 0.28)
	_light.light_energy = LIGHT_ENERGY
	_light.omni_range = LIGHT_RANGE
	_light.shadow_enabled = false
	_light.position.y = 0.62
	add_child(_light)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001 + _phase
	var flicker := 0.85 + 0.12 * sin(t * 11.0) * sin(t * 5.1) + 0.05 * sin(t * 27.0)
	_light.light_energy = LIGHT_ENERGY * flicker * _strength
	_flame.scale = Vector3(1.0, 0.9 + 0.2 * flicker, 1.0) * maxf(_strength, 0.05)
	# The flame always burns upward, whichever way the stick points.
	_flame.global_basis = Basis.IDENTITY.scaled(_flame.scale)


## Let go of it (its holder is fighting): it falls where it is and burns out.
func drop(world: Node) -> void:
	if _dropped or world == null:
		return
	_dropped = true
	var at := global_position
	reparent(world, true)
	# Lying on its side on the ground, flame end a little raised.
	var yaw := randf() * TAU
	var lie := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, deg_to_rad(80.0))
	var ground := at
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.5, at + Vector3.DOWN * 3.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		ground = hit.position
	var tw := create_tween()
	tw.tween_property(self, "global_transform", Transform3D(lie, ground + Vector3.UP * 0.04), 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_interval(BURN_ON_GROUND)
	tw.tween_property(self, "_strength", 0.0, 2.0)
	tw.tween_callback(queue_free)


func is_dropped() -> bool:
	return _dropped
