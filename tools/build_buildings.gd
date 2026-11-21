extends SceneTree
## Bakes the building kit (game/world/building_kit.gd) into assets/buildings/*.scn.
##   Godot --headless --path . --script res://tools/build_buildings.gd [-- name ...]
## With names, only those are rebuilt. The zone's prop scenes (levels/tithelands/props)
## instance these through game/world/baked_building.gd.

const BK := preload("res://game/world/building_kit.gd")
const BL := preload("res://game/world/building_landmarks.gd")
const OUT := "res://assets/buildings/"


func _init() -> void:
	var mats := BK.materials(true)
	var jobs := {
		"cottage_0": func() -> Node3D: return BK.cottage(mats, 11),
		"cottage_1": func() -> Node3D: return BK.cottage(mats, 23),
		"cottage_2": func() -> Node3D: return BK.cottage(mats, 37),
		"cottage_3": func() -> Node3D: return BK.cottage(mats, 41, false, false),
		"burned_0": func() -> Node3D: return BK.cottage(mats, 101, true),
		"burned_1": func() -> Node3D: return BK.cottage(mats, 117, true),
		"burned_2": func() -> Node3D: return BK.cottage(mats, 131, true),
		"tent_0": func() -> Node3D: return BK.tent(mats, 5),
		"tent_1": func() -> Node3D: return BK.tent(mats, 6),
		"tent_2": func() -> Node3D: return BK.tent(mats, 9),
		"tent_3": func() -> Node3D: return BK.tent(mats, 14),
		"barn_0": func() -> Node3D: return BL.tithe_barn(mats, 7),
		"mill_0": func() -> Node3D: return BL.mill(mats, 3),
		"tower_0": func() -> Node3D: return BL.watchtower(mats, 2),
	}
	var only := OS.get_cmdline_user_args()
	for nm: String in jobs:
		if not only.is_empty() and not only.has(nm):
			continue
		var t0 := Time.get_ticks_msec()
		var n: Node3D = jobs[nm].call()
		n.name = nm.to_pascal_case()
		_own(n, n)
		var ps := PackedScene.new()
		ps.pack(n)
		var err := ResourceSaver.save(ps, OUT + nm + ".scn")
		print("%s: %d tris, %d collision boxes, %d ms%s" % [nm, BK.tri_count(n), n.get_node("Collision").get_child_count(),
			Time.get_ticks_msec() - t0, "" if err == OK else "  SAVE FAILED %d" % err])
		n.free()
	quit()


func _own(n: Node, root: Node) -> void:
	for ch in n.get_children():
		ch.owner = root
		_own(ch, root)
