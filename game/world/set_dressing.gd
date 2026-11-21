class_name SetDressing
extends Node3D
## Places the props listed in a dressing script (`items`: [scene, x, z, yaw, scale, lift])
## on the ground. Short scene names are hideout library assets
## ("Storage_Containers/sack_grain" = res://assets/hideout/Storage_Containers/sack_grain.scn);
## full res:// paths work too. Keeps the placement in one readable list per zone.

@export var terrain: ZoneTerrain
@export var dressing_script: Script


func _ready() -> void:
	_place.call_deferred()


func _place() -> void:
	if terrain == null or dressing_script == null:
		return
	var data: Object = dressing_script.new()
	var cache := {}
	for it in data.items:
		var path: String = it[0]
		if not path.begins_with("res://"):
			path = "res://assets/hideout/%s.scn" % path
		if not cache.has(path):
			cache[path] = load(path)
		var ps: PackedScene = cache[path]
		if ps == null:
			push_warning("SetDressing: missing %s" % path)
			continue
		var n := ps.instantiate() as Node3D
		n.name = String(path.get_file().get_basename())
		add_child(n)
		var x: float = it[1]
		var z: float = it[2]
		var lift: float = it[5] if it.size() > 5 else 0.0  # for assets whose origin is not at their base
		n.global_position = Vector3(x, terrain.height_at(x, z) - 0.02 + lift, z)
		n.rotation_degrees.y = it[3] if it.size() > 3 else 0.0
		if it.size() > 4:
			n.scale = Vector3.ONE * float(it[4])
