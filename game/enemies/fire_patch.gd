class_name FirePatch
extends Node3D
## Burning ground left by a boss. Every machine hurts only its own player, so
## rolling through it works the same as dodging anything else.

const TICK := 0.5

var radius := 3.0
var time := 8.0
var damage := 7.0

var _age := 0.0
var _tick := 0.0
var _disc: MeshInstance3D
var _light: OmniLight3D


func _ready() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.05
	mesh.radial_segments = 24
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.4, 0.1, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.1)
	mat.emission_energy_multiplier = 1.5
	mesh.material = mat
	_disc = MeshInstance3D.new()
	_disc.mesh = mesh
	_disc.position.y = 0.05
	add_child(_disc)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.5, 0.2)
	_light.light_energy = 1.6
	_light.omni_range = radius * 2.2
	_light.position.y = 0.8
	add_child(_light)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= time:
		queue_free()
		return
	_light.light_energy = 1.6 * (0.85 + 0.15 * sin(_age * 17.0)) * (1.0 - smoothstep(time - 1.5, time, _age))
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = TICK
	for n in get_tree().get_nodes_in_group(&"player"):
		var p := n as Player
		if p == null or not p.is_multiplayer_authority() or p.is_dead():
			continue
		var d := p.global_position - global_position
		if Vector2(d.x, d.z).length() > radius or absf(d.y) > 2.0:
			continue
		var hit := HitInfo.new()
		hit.damage = damage
		hit.unblockable = true
		hit.parryable = false
		hit.hit_stop = 0.0
		hit.origin = global_position
		hit.attacker_level = 6
		p.receive_hit(hit)
