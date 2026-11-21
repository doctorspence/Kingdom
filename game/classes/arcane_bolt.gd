extends Node3D
## Arcane Bolt: a small, quick bolt of cold light. It homes on the enemy you
## were aiming at (lock-on) or flies straight ahead and hits the first enemy
## in its way. Only the caster's copy ("owned") deals damage.

const SPEED := 30.0
const HIT_RADIUS := 0.6

var caster: AbilityCaster
var owned := false
var target: Node3D  # optional: homes on its lock point
var direction := Vector3.FORWARD
var max_range := 30.0
var damage := 0.0
var poise := 6.0
## For copies on other machines: where it is heading.
var aim_at := Vector3.ZERO

var _travelled := 0.0


func _ready() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.1
	mesh.height = 0.2
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.75, 0.85, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.55, 0.7, 1.0)
	mat.emission_energy_multiplier = 3.0
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var light := OmniLight3D.new()
	light.light_color = Color(0.6, 0.75, 1.0)
	light.light_energy = 0.8
	light.omni_range = 2.5
	add_child(light)
	# Plays on every machine that sees the bolt (after it has been placed).
	(func() -> void: Audio.sfx(&"bolt", global_position)).call_deferred()


func _physics_process(delta: float) -> void:
	if owned and target and is_instance_valid(target) and target.call(&"can_be_locked"):
		direction = (Vector3(target.call(&"get_lock_point")) - global_position).normalized()
	elif not owned and aim_at != Vector3.ZERO:
		direction = (aim_at - global_position).normalized()
	global_position += direction * SPEED * delta
	_travelled += SPEED * delta
	if owned and is_instance_valid(caster):
		var feet := global_position - Vector3.UP * 1.2
		var hits := caster.enemies_in(feet, HIT_RADIUS)
		if not hits.is_empty():
			var e := hits[0]
			caster.strike(e, damage, poise, 1.0)
			CombatFx.burst_visual(&"ember_burst", global_position, 0.6, 0.25)
			queue_free()
			return
	if _travelled >= max_range or (not owned and aim_at != Vector3.ZERO and global_position.distance_to(aim_at) < 0.5):
		queue_free()
