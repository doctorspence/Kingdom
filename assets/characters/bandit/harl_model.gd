extends "res://assets/characters/bandit/bandit_model.gd"
## Harl the Delver's look. Everything is the bandits' model, plus the second phase: once Harl
## has pressed his arm to the black stone, the marks spread up it to his face and the shards
## shine (GULLET_DESIGN.md section 6). Every machine works that out from the boss's shared
## phase and state, so nothing extra goes over the network.

var _stone_skin: Material
var _stone_pick: Material
var _spread := false


func _ready() -> void:
	super._ready()
	var inst: Node = outfit.instantiate()
	_stone_skin = inst.get_meta(&"stone_material", null)
	inst.free()


## The boss code tints a stand-in body for its second phase; Harl shows it on his own skin.
func set_tint(_color: Color) -> void:
	pass


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	var boss := get_parent() as Enemy
	if boss:
		show_stone(boss.net_phase == 2 and boss.net_state != Enemy.State.CALL)


## Spread (true) or draw back (false) the marks and the stone's light.
func show_stone(on: bool) -> void:
	if on == _spread:
		return
	_spread = on
	for m in _meshes:
		m.material_override = _stone_skin if on else null
	for item in _hand_items.values():
		if not is_instance_valid(item):
			continue
		if (item as Node).has_meta(&"stone_material"):
			_stone_pick = (item as Node).get_meta(&"stone_material")
			for mesh in (item as Node).find_children("*", "MeshInstance3D", true, false):
				(mesh as MeshInstance3D).material_override = _stone_pick if on else null


func is_stone_shown() -> bool:
	return _spread
