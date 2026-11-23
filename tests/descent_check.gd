extends Node
## The way down from the quarry into the Gullet is one walkable tunnel (no door, no loading).
## Checks the route is clear and continuous, that a walking body gets from the quarry mouth to
## the Gullet's yard, and that the light fades in with depth.
##   ... --headless --script res://tests/run.gd -- descent_check

var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	for i in 60:
		await get_tree().physics_frame
	QuarryDescent.compute()
	var pts := QuarryDescent.pts
	_check("the route starts at the quarry mouth and ends on the Gullet floor",
			absf(pts[0].y - QuarryDescent.MOUTH_Y) < 0.01 and absf(pts[pts.size() - 1].y - QuarryDescent.YARD_Y) < 0.05)
	_check("the incline is walkable (%.0f degrees)" % rad_to_deg(atan(QuarryDescent.slope)), QuarryDescent.slope > 0.3 and QuarryDescent.slope < 0.7)
	var steepest := 0.0
	for k in range(pts.size() - 1):
		var run := Vector2(pts[k + 1].x - pts[k].x, pts[k + 1].z - pts[k].z).length()
		if run > 0.001:
			steepest = maxf(steepest, (pts[k].y - pts[k + 1].y) / run)
	_check("no station steeper than the design slope (%.2f)" % steepest, steepest < QuarryDescent.slope + 0.01)
	_check("route length %.0f m" % QuarryDescent.cum[QuarryDescent.cum.size() - 1], QuarryDescent.cum[QuarryDescent.cum.size() - 1] > 100.0)

	# A person-sized capsule must fit all along the route.
	var g: Node3D = scene.get_node("Gullet")
	var space := g.get_world_3d().direct_space_state
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	var blocked := 0
	var first_block := ""
	for k in pts.size():
		q.transform = Transform3D(Basis(), pts[k] + Vector3(0, 1.4, 0))
		var hit := space.intersect_shape(q, 4)
		if not hit.is_empty():
			blocked += 1
			print("  blocked at ", pts[k], " by ", (hit[0]["collider"] as Node).get_path())
			if first_block == "":
				first_block = "%s" % pts[k]
	_check("a person fits along the whole route (%d blocked stations %s)" % [blocked, first_block], blocked == 0)

	# Walk it with a real character body, as a player would.
	var body := CharacterBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = cap
	cs.position = Vector3(0, 0.9, 0)
	body.add_child(cs)
	body.floor_max_angle = deg_to_rad(45.0)
	body.floor_snap_length = 0.6
	scene.add_child(body)
	body.global_position = pts[0] + Vector3(0, 0.3, 0)
	var goal := pts[pts.size() - 1]
	var next := 1
	var frames := 0
	var lowest_cave := 1.0
	var cave_marks := {}
	while frames < 60 * 90 and next < pts.size():
		var to: Vector3 = pts[next] - body.global_position
		var flat := Vector3(to.x, 0, to.z)
		if flat.length() < 0.5:
			next += 1
			continue
		var v := flat.normalized() * 5.0
		body.velocity.x = v.x
		body.velocity.z = v.z
		body.velocity.y -= 20.0 * get_physics_process_delta_time()
		body.move_and_slide()
		if body.is_on_floor():
			body.velocity.y = 0.0
		frames += 1
		if frames % 120 == 0 and frames < 1200:
			print("  walk t=%.1f pos=%s next=%d floor=%s vel=%s" % [frames / 60.0, body.global_position, next, body.is_on_floor(), body.velocity])
		await get_tree().physics_frame
		var s := QuarryDescent.path_s(body.global_position + Vector3(0, 1.0, 0))
		if s >= 0.0:
			cave_marks[int(s / 10.0)] = QuarryDescent.depth_cave(body.global_position + Vector3(0, 1.0, 0))
	var reached := body.global_position.distance_to(goal) < 2.0
	_check("walking reaches the Gullet's yard from the quarry (%.1f s, ends %.1f m from the goal)" % [frames / 60.0, body.global_position.distance_to(goal)], reached)
	# Light: 0 at the mouth, rising steadily, full before the Gullet.
	var prev := -1.0
	var monotonic := true
	for key in cave_marks.keys():
		if cave_marks[key] < prev - 0.001:
			monotonic = false
		prev = cave_marks[key]
	_check("the light fades in steadily with depth (%s)" % str(cave_marks), monotonic and cave_marks.get(0, 1.0) < 0.5)
	_check("fully dark by the time you reach the yard", QuarryDescent.depth_cave(goal + Vector3(0, 1.0, 0)) > 0.99)
	_check("outside the mouth is daylight", QuarryDescent.depth_cave(Vector3(-160, 13, -98)) < 0.01)
	print("PASS: 0 problem(s)" if failures == 0 else "FAIL: %d problem(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func _check(label: String, ok: bool) -> void:
	print(("ok   " if ok else "FAIL ") + label)
	if not ok:
		failures += 1
