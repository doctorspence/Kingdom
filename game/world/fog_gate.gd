class_name FogGate
extends StaticBody3D
## The mist in front of a boss arena. Walk through it (Interact) to enter. While
## the boss is fighting it turns solid: nobody gets in or out until the boss
## dies or the fight is over. Its -Z side is the arena.

@export var boss_id := &"enemy_tallow"
@export var width := 6.0
@export var gate_height := 4.0

var _mist: MeshInstance3D
var _shape: CollisionShape3D
var _sealed := false


func _ready() -> void:
	add_to_group(&"interactables")
	_mist = MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = Vector3(width, gate_height, 0.5)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.3, 0.29, 0.25, 0.35)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.75, 0.55)
	mat.emission_energy_multiplier = 0.06
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material = mat
	_mist.mesh = m
	_mist.position.y = gate_height * 0.5
	add_child(_mist)
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, gate_height, 0.5)
	_shape.shape = box
	_shape.position.y = gate_height * 0.5
	_shape.disabled = true
	add_child(_shape)


func is_sealed() -> bool:
	return _sealed


func _physics_process(_delta: float) -> void:
	var sealed := false
	for n in get_tree().get_nodes_in_group(&"bosses"):
		var e := n as Enemy
		if e and e.data.id == boss_id and e.net_engaged and e.state != Enemy.State.DEAD:
			sealed = true
	if sealed != _sealed:
		_sealed = sealed
		_shape.set_deferred(&"disabled", not sealed)
		(_mist.mesh.material as StandardMaterial3D).albedo_color.a = 0.85 if sealed else 0.35


func get_interact_text() -> String:
	return "" if _sealed else "Pass through the mist"


func interact(player: Node3D) -> void:
	if _sealed:
		return
	var side := signf((player.global_position - global_position).dot(global_transform.basis.z))
	# From the +Z side go in (to -Z), and back out the other way.
	var dest := global_position - global_transform.basis.z * 3.0 * (1.0 if side >= 0.0 else -1.0)
	dest.y = player.global_position.y
	player.global_position = dest
	player.velocity = Vector3.ZERO
