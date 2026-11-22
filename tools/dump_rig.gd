extends SceneTree
func _initialize() -> void:
	var s: Node = (load("res://assets/characters/mannequin/UAL1_Standard.glb") as PackedScene).instantiate()
	root.add_child(s)
	var sk: Skeleton3D = s.find_children("*", "Skeleton3D", true, false)[0]
	print("skeleton scale ", sk.global_transform.basis.get_scale(), " parent ", sk.get_parent().name)
	for i in sk.get_bone_count():
		var g := sk.get_bone_global_rest(i)
		var par := sk.get_bone_parent(i)
		print(i, " ", sk.get_bone_name(i), " par=", sk.get_bone_name(par) if par >= 0 else "-", " pos=", g.origin.snapped(Vector3.ONE*0.001))
	for m in sk.find_children("*", "MeshInstance3D", true, false):
		print("mesh ", m.name, " aabb ", m.get_aabb())
	quit()
