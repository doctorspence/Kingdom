extends Node
## Walks a person-sized body through the Gullet's main routes (yard to camp, camp to the
## Excavation, shrine, hidden chest). It fails if anything, such as an invisible zone-edge
## wall or a stray collider, stops it.
##   ... --headless --script res://tests/run.gd -- gullet_walk_check

var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	for i in 60:
		await get_tree().physics_frame
	var g: Node3D = scene.get_node("Gullet")
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	var body := CharacterBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = cap
	cs.position = Vector3(0, 0.9, 0)
	body.add_child(cs)
	body.floor_max_angle = deg_to_rad(50.0)
	body.floor_snap_length = 0.6
	scene.add_child(body)
	var routes := {
		"yard to camp by the west loop": [[-58, 25], [-44, 25], [-27, 25], [-27, 13], [-39, 13], [-39, -5], [-20, -5], [0, -5], [20, -5]],
		"camp to the Excavation": [[20, -5], [27, -2], [40, 0], [60, 0]],
		"hall to the barricade": [[-27, 13], [-18, 13], [-18, 7]],
		"camp to the shrine": [[0, -5], [14, 2], [17, 14], [20, 16]],
	}
	for rn in routes:
		var wps: Array = routes[rn]
		body.global_position = g.global_transform * Vector3(wps[0][0], 0.3, wps[0][1])
		body.velocity = Vector3.ZERO
		var stuck_at := ""
		for wi in range(1, wps.size()):
			if stuck_at != "":
				break
			var goal: Vector3 = g.global_transform * Vector3(wps[wi][0], 0, wps[wi][1])
			var last := body.global_position
			for f in 60 * 25:
				var to := goal - body.global_position
				to.y = 0
				if to.length() < 0.6:
					break
				var v := to.normalized() * 4.0
				body.velocity.x = v.x
				body.velocity.z = v.z
				body.velocity.y -= 20.0 / 60.0
				body.move_and_slide()
				if body.is_on_floor():
					body.velocity.y = 0.0
				if f % 30 == 29:
					if body.global_position.distance_to(last) < 0.5:
						stuck_at = "%s" % g.to_local(body.global_position).snapped(Vector3(0.1, 0.1, 0.1))
						break
					last = body.global_position
				await get_tree().physics_frame
		_check("walk: %s %s" % [rn, "" if stuck_at == "" else "(stuck at " + stuck_at + ")"], stuck_at == "")
	print("PASS: 0 problem(s)" if failures == 0 else "FAIL: %d problem(s)" % failures)
	get_tree().quit(failures)


func _check(what: String, ok: bool) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		failures += 1
