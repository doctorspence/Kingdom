extends Node3D
## Kindle's ember: flies in an arc to where you aimed and bursts there,
## healing friends and singeing enemies within the radius. It can miss.
## Only the caster's copy ("owned") applies healing and damage; everyone
## else's copy is just for show.

const SPEED := 16.0
const ARC_HEIGHT := 0.25  # extra height per meter of distance

var from := Vector3.ZERO
var to := Vector3.ZERO
var owned := false
var caster: AbilityCaster
var heal := 0.0
var damage := 0.0
var radius := 2.5

var _t := 0.0
var _flight := 1.0
var _apex := 1.0


func _ready() -> void:
	var dist := from.distance_to(to)
	_flight = maxf(0.25, dist / SPEED)
	_apex = 0.5 + dist * ARC_HEIGHT
	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.7, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.2)
	mat.emission_energy_multiplier = 8.0
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.65, 0.3)
	light.light_energy = 2.0
	light.omni_range = 4.0
	add_child(light)
	global_position = from


func _physics_process(delta: float) -> void:
	_t += delta
	var u := clampf(_t / _flight, 0.0, 1.0)
	var p := from.lerp(to, u)
	p.y += 4.0 * _apex * u * (1.0 - u)
	global_position = p
	if u >= 1.0:
		_burst()


func _burst() -> void:
	CombatFx.burst_visual(&"ember_burst", to, radius, 0.5)
	if owned and is_instance_valid(caster):
		for ally in caster.allies_in(to, radius):
			caster.heal_player(ally, heal)
		for e in caster.enemies_in(to, radius):
			caster.strike_enemy(e, damage)
	queue_free()
