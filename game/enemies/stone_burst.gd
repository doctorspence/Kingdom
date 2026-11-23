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
var _decal: Decal
var _spikes: Node3D


func _ready() -> void:
	# The warning is a decal, so it wraps onto slopes and ruts instead of being cut by them.
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.78, 0.88, 0.93, 0.985, 1.0])
	g.colors = PackedColorArray([
		Color(1.0, 0.12, 0.05, 0.22), Color(1.0, 0.12, 0.05, 0.4), Color(1.0, 0.2, 0.08, 0.6),
		Color(1.0, 0.3, 0.12, 1.0), Color(1.0, 0.3, 0.12, 1.0), Color(1.0, 0.2, 0.08, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	# Emission ignores alpha, so it gets its own copy of the ring that fades to black instead.
	var ge := Gradient.new()
	ge.offsets = g.offsets
	var ecols := PackedColorArray()
	for c in g.colors:
		ecols.append(Color(c.r * c.a, c.g * c.a, c.b * c.a, 1.0))
	ge.colors = ecols
	var etex := GradientTexture2D.new()
	etex.gradient = ge
	etex.fill = GradientTexture2D.FILL_RADIAL
	etex.fill_from = Vector2(0.5, 0.5)
	etex.fill_to = Vector2(1.0, 0.5)
	etex.width = 256
	etex.height = 256
	_decal = Decal.new()
	_decal.size = Vector3(radius * 2.0, 2.6, radius * 2.0)
	_decal.texture_albedo = tex
	_decal.texture_emission = etex
	_decal.emission_energy = 1.2
	_decal.cull_mask = 1
	_decal.modulate = Color(1, 1, 1, 0.3)
	add_child(_decal)


func _physics_process(delta: float) -> void:
	_age += delta
	if not _burst:
		var t := clampf(_age / delay, 0.0, 1.0)
		_decal.modulate.a = 0.3 + 0.7 * t * t
		var pulse := 1.0 + 0.03 * sin(_age * 22.0) * t
		_decal.size = Vector3(radius * 2.0 * pulse, 2.6, radius * 2.0 * pulse)
		if _age >= delay:
			_erupt()
	elif _age >= delay + 1.4:
		queue_free()
	elif _spikes:
		var s := _age - delay
		_spikes.scale.y = maxf(0.001, 1.0 - smoothstep(0.35, 1.3, s)) * minf(1.0, s * 14.0)
		_decal.modulate.a = 1.0 - smoothstep(0.0, 0.5, s)


func _erupt() -> void:
	_burst = true
	_spikes = Node3D.new()
	add_child(_spikes)
	var rock := StandardMaterial3D.new()
	rock.albedo_color = Color(0.1, 0.095, 0.11)
	rock.roughness = 0.8
	rock.emission_enabled = false
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
		mi.layers = 2  # the ground decal only paints layer 1, so it never tints the spikes
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
