class_name StoneBurst
extends Node3D
## Harl's Stone Eruption: a ring of black stone glows red on the ground, then spikes burst up through
## it. The warning lasts `delay` seconds. Every machine hurts only its own player (the same rule as
## FirePatch), so rolling out of the ring, or through the burst, works like dodging any other attack.

var radius := 2.2
var delay := 1.3
var damage := 38.0

var _age := 0.0
var _burst := false
var _ring: MeshInstance3D
var _fill: MeshInstance3D
var _fill_mat: StandardMaterial3D
var _spikes: Node3D


func _ready() -> void:
	_fill_mat = StandardMaterial3D.new()
	_fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fill_mat.albedo_color = Color(0.7, 0.08, 0.04, 0.0)
	_fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.03
	disc.radial_segments = 28
	disc.material = _fill_mat
	_fill = MeshInstance3D.new()
	_fill.mesh = disc
	_fill.position.y = 0.06
	_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_fill)
	# The edge ring stays solid so the whole danger area reads at a glance.
	var ring := TorusMesh.new()
	ring.inner_radius = radius - 0.07
	ring.outer_radius = radius + 0.07
	ring.rings = 28
	ring.ring_segments = 4
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(1.0, 0.18, 0.08)
	rm.emission_enabled = true
	rm.emission = Color(1.0, 0.15, 0.05)
	rm.emission_energy_multiplier = 1.4
	ring.material = rm
	_ring = MeshInstance3D.new()
	_ring.mesh = ring
	_ring.scale = Vector3(1, 0.2, 1)
	_ring.position.y = 0.06
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)


func _physics_process(delta: float) -> void:
	_age += delta
	if not _burst:
		var t := clampf(_age / delay, 0.0, 1.0)
		_fill_mat.albedo_color.a = 0.12 + 0.4 * t * t
		var pulse := 1.0 + 0.04 * sin(_age * 22.0) * t
		_ring.scale = Vector3(pulse, 0.2, pulse)
		if _age >= delay:
			_erupt()
	elif _age >= delay + 1.4:
		queue_free()
	elif _spikes:
		var s := _age - delay
		_spikes.scale.y = maxf(0.001, 1.0 - smoothstep(0.35, 1.3, s)) * minf(1.0, s * 14.0)
		_fill_mat.albedo_color.a = 0.5 * (1.0 - smoothstep(0.0, 0.6, s))


func _erupt() -> void:
	_burst = true
	_fill_mat.albedo_color = Color(0.1, 0.07, 0.06, 0.5)
	_spikes = Node3D.new()
	add_child(_spikes)
	var rock := StandardMaterial3D.new()
	rock.albedo_color = Color(0.07, 0.065, 0.075)
	rock.roughness = 0.8
	rock.emission_enabled = true
	rock.emission = Color(0.5, 0.12, 0.05)
	rock.emission_energy_multiplier = 0.25
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 31.0 + global_position.z * 17.0)
	for i in 11:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * radius * 0.9
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = rng.randf_range(0.18, 0.34)
		cone.height = rng.randf_range(1.2, 2.3)
		cone.radial_segments = 5
		cone.material = rock
		var mi := MeshInstance3D.new()
		mi.mesh = cone
		mi.position = Vector3(cos(a) * d, cone.height * 0.5 - 0.1, sin(a) * d)
		mi.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf() * TAU, rng.randf_range(-0.2, 0.2))
		_spikes.add_child(mi)
	Audio.sfx(&"swing_heavy", global_position)
	for n in get_tree().get_nodes_in_group(&"player"):
		var p := n as Player
		if p == null or not p.is_multiplayer_authority() or p.is_dead():
			continue
		var d := p.global_position - global_position
		if Vector2(d.x, d.z).length() > radius or absf(d.y) > 2.2:
			continue
		var hit := HitInfo.new()
		hit.damage = damage
		hit.poise_damage = 30.0
		hit.unblockable = true
		hit.parryable = false
		hit.hit_stop = 0.08
		hit.origin = global_position
		hit.attacker_level = 6
		p.receive_hit(hit)
