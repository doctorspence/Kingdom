@tool
extends Node3D
## Shows one of the baked building models (assets/buildings, made by tools/build_buildings.gd).
## variant < 0 picks one from the node's name, so copies of the same prop look different.

@export var variants: Array[PackedScene] = []
@export var variant := -1


func _ready() -> void:
	if variants.is_empty() or get_node_or_null("Model") != null:
		return
	var i := variant if variant >= 0 else absi(hash(String(name))) % variants.size()
	var m := variants[i % variants.size()].instantiate()
	m.name = "Model"
	add_child(m)
