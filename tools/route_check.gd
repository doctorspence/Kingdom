extends Node
## Route and access check for the Tithelands (Greenwood stage 9). Walks every road and
## track centerline every meter and asks the physics world whether a person-sized
## capsule (radius 0.3 m, from 0.5 m to 1.9 m above the ground) hits anything solid,
## and whether the ground is too steep to walk. Then checks a clear circle round each
## shrine, vendor, door, gate and ladder foot. Not a pass/fail check: it prints what
## blocks where, so new blockers can be told from intended ones (barricades, gates).
##   Godot_console.exe --headless --path . --script res://tests/run.gd -- ../tools/route_check

var terrain: SculptedTerrain


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	for i in 40:
		await get_tree().physics_frame
	terrain = scene.get_node("Terrain")
	var space := (scene as Node3D).get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.4
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = capsule
	q.collide_with_areas = false
	q.collision_mask = 1
	var land: Object = terrain.land
	var lines: Array = []
	var names := ["Tithe Road", "Mill Lane", "East Lane"]
	for i in land.roads.size():
		lines.append([names[i] if i < names.size() else "road %d" % i, terrain._densify(land.roads[i].points, 1.0)])
	for i in land.tracks.size():
		lines.append(["track %d" % i, terrain._densify(land.tracks[i].points, 1.0)])
	var total_blocked := 0
	for line: Array in lines:
		var pts: PackedVector2Array = line[1]
		var blocked := {}
		var steep := 0
		var steep_at: PackedStringArray = []
		var water := 0
		for i in pts.size():
			var p := pts[i]
			if absf(p.x) > 180.0 or absf(p.y) > 180.0:
				continue
			var g := terrain.height_at(p.x, p.y)
			if g < terrain.water_level_at(p.x, p.y) - 0.6:
				water += 1  # the river (fords and the bridge are where the road crosses)
			var slope := Vector2(terrain.height_at(p.x + 0.7, p.y) - terrain.height_at(p.x - 0.7, p.y),
					terrain.height_at(p.x, p.y + 0.7) - terrain.height_at(p.x, p.y - 0.7)).length() / 1.4
			if slope > 1.0:
				steep += 1
				if steep_at.size() < 6:
					steep_at.append("(%d, %d) %.0f deg" % [roundi(p.x), roundi(p.y), rad_to_deg(atan(slope))])
			q.transform = Transform3D(Basis(), Vector3(p.x, g + 1.2, p.y))
			for hit in space.intersect_shape(q, 8):
				var c: Object = hit.collider
				if c is CharacterBody3D:
					continue  # players and enemies
				var who := _name_of(c as Node)
				if not blocked.has(who):
					blocked[who] = []
				(blocked[who] as Array).append("(%d, %d)" % [roundi(p.x), roundi(p.y)])
		var line_name: String = line[0]
		print("ROUTE %-12s %4d m  steep %d  under water %d  blocked by: %s" % [line_name, pts.size(), steep, water, _summary(blocked)])
		if steep > 0:
			print("      steep at: ", ", ".join(steep_at))
		total_blocked += blocked.size()
	# Key access points: a 1.2 m circle round each must be free.
	var places := scene.get_node("Places")
	for n in ["CrossroadsShrine", "MillShrine", "QuarryShrine", "Camp", "OldWenna", "SoulBroker", "GulletDoor", "TowerGate", "QuarryLadder"]:
		var node := places.get_node_or_null(n) as Node3D
		if node == null:
			print("ACCESS %-16s missing" % n)
			continue
		var hits := {}
		for k in 8:
			var a := TAU * k / 8.0
			var p := node.global_position + Vector3(cos(a), 0.0, sin(a)) * 1.6
			var g := terrain.height_at(p.x, p.z)
			q.transform = Transform3D(Basis(), Vector3(p.x, g + 1.2, p.z))
			for hit in space.intersect_shape(q, 8):
				var c: Object = hit.collider
				if c is CharacterBody3D or c == node or (node.is_ancestor_of(c as Node)):
					continue
				hits[_name_of(c as Node)] = true
		print("ACCESS %-16s around it: %s" % [n, ", ".join(hits.keys()) if hits.size() > 0 else "clear"])
	print("ROUTES done, %d distinct blockers on routes" % total_blocked)
	get_tree().quit()


## The nearest meaningful name: a Places/StoryProps/QuarryWorks child, or the scatter node.
func _name_of(n: Node) -> String:
	var path := String(n.get_path())
	for root in ["/Places/", "/Woods/", "/Oaks/", "/Rocks/", "/Boulders/", "/Deadwood/", "/StoryProps/", "/QuarryWorks/", "/StoneWalls/", "/Dressing/", "/TitheExtras/", "/Clutter/", "/Terrain/"]:
		var i := path.find(root)
		if i >= 0:
			var rest := path.substr(i + root.length())
			return root.trim_suffix("/").trim_prefix("/") + "/" + rest.split("/")[0]
	return path.get_file()


func _summary(blocked: Dictionary) -> String:
	if blocked.is_empty():
		return "nothing"
	var parts: PackedStringArray = []
	for k in blocked:
		var at: Array = blocked[k]
		parts.append("%s x%d at %s" % [k, at.size(), at[0]])
	return "; ".join(parts)
