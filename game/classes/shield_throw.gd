extends Node3D
## Shield Throw: the Vanguard's shield flies out in a line, hitting every enemy
## it passes, then spins back to the thrower. Only the thrower's copy
## ("owned") deals damage; everyone else's copy is just for show.

const OUT_SPEED := 26.0
const BACK_SPEED := 30.0
const HIT_RADIUS := 1.1

var caster: AbilityCaster
var follow: Node3D  # whoever it returns to
var owned := false
var direction := Vector3.FORWARD
var max_distance := 14.0
var damage := 0.0
var poise := 0.0
var threat_mult := 1.0

var _start := Vector3.ZERO
var _returning := false
var _hit: Array[Node] = []
var _mesh: MeshInstance3D
var _life := 0.0


func _ready() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = 0.38
	disc.bottom_radius = 0.38
	disc.height = 0.07
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.33, 0.2)
	mat.metallic = 0.4
	mat.roughness = 0.6
	disc.material = mat
	_mesh = MeshInstance3D.new()
	_mesh.mesh = disc
	_mesh.rotation_degrees.x = 90.0  # on edge, like a thrown plate
	add_child(_mesh)
	_start = global_position
	(func() -> void: Audio.sfx(&"throw", global_position)).call_deferred()


func _physics_process(delta: float) -> void:
	_life += delta
	_mesh.rotate_object_local(Vector3.UP, 18.0 * delta)
	if _returning:
		if follow == null or not is_instance_valid(follow):
			queue_free()
			return
		var home := follow.global_position + Vector3.UP * 1.2
		var to := home - global_position
		if to.length() <= BACK_SPEED * delta + 0.6 or _life > 4.0:
			_finish()
			return
		global_position += to.normalized() * BACK_SPEED * delta
	else:
		global_position += direction * OUT_SPEED * delta
		if global_position.distance_to(_start) >= max_distance:
			_returning = true
			_hit.clear()  # it can hit them again on the way back
	_strike_things()


func _strike_things() -> void:
	if not owned or caster == null or not is_instance_valid(caster):
		return
	var feet := global_position - Vector3.UP * 1.2
	for e in caster.enemies_in(feet, HIT_RADIUS):
		if e in _hit:
			continue
		_hit.append(e)
		caster.strike(e, damage, poise, threat_mult)
		CombatFx.sparks(e.global_position + Vector3.UP * 1.3, -direction)


func _finish() -> void:
	Audio.sfx(&"shield_clack", global_position)
	if owned and is_instance_valid(caster):
		caster.shield_returned()
	queue_free()
