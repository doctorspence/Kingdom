extends Node
## Pictures of the sword draw (ENEMY_LIFE_PLAN.md stage 7): a calm bandit and a Knight
## notice you and draw from the hip on the move; a camp asleep at night. Not a pass/fail check.
## Run WITHOUT --headless; pictures go to user://shots/.
##   Godot_console.exe --path . --resolution 1280x720 --script res://tests/run.gd -- visual_draw

var player: Player
var cam: Camera3D
var night := 0.0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var arena: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(arena)
	await _frames(20)
	player = get_tree().get_first_node_in_group(&"player") as Player
	for e in get_tree().get_nodes_in_group(&"enemies"):
		e.remove_from_group(&"enemies")
		e.queue_free()
	player.global_position = Vector3(0, 0.05, 60)
	cam = Camera3D.new()
	cam.fov = 40.0
	arena.add_child(cam)
	cam.make_current()
	for kind in ["bandit_sword", "zealot"]:
		var e := (load("res://game/enemies/%s.tscn" % kind) as PackedScene).instantiate() as Enemy
		e.position = Vector3(0, 0, 0)
		arena.add_child(e, true)
		await _seconds(1.0)
		e.model.face_instantly(Vector3(0, 0, 1))
		player.global_position = Vector3(0, 0.05, 12)
		e._aggro(player, false)
		for i in 600:
			await get_tree().physics_frame
			if e.model.is_drawing():
				break
		var steps := [0.12, 0.22, 0.32, 0.45]
		var done := 0.0
		for t in steps:
			await _seconds(t - done)
			done = t
			cam.global_position = e.global_position + Vector3(-2.2, 1.5, 2.6)
			cam.look_at(e.global_position + Vector3.UP * 1.0)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://shots/d_%s_%02d.png" % [kind, int(t * 100)])
		e.remove_from_group(&"enemies")
		e.queue_free()
		player.global_position = Vector3(0, 0.05, 60)
		await _frames(5)
	# The camp at night: two asleep by the fire, one up as the night watch.
	night = 1.0
	for prop in [["campfire", Vector3(-20, 0, 0)], ["log_seat", Vector3(-20, 0, 2.2)], ["crate", Vector3(-24, 0, -2)]]:
		var n := (load("res://levels/tithelands/props/%s.tscn" % prop[0]) as PackedScene).instantiate() as Node3D
		n.position = prop[1]
		arena.add_child(n)
	for at in [Vector3(-20.5, 0, 3.5), Vector3(-19.5, 0, 3.5), Vector3(-23, 0, -3)]:
		var e := (load("res://game/enemies/bandit_sword.tscn") as PackedScene).instantiate() as Enemy
		e.position = at
		arena.add_child(e, true)
	await _seconds(5.0)
	for v in [["d_camp_night", Vector3(-20, 3.2, 8.5)], ["d_camp_night_side", Vector3(-26, 2.0, 4.0)]]:
		cam.global_position = v[1]
		cam.look_at(Vector3(-20, 0.4, 1.5))
		await _frames(3)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % v[0])
	# A lookout on watch at night: torch up. Then it spots you and drops it.
	var look := (load("res://game/enemies/bandit_lookout.tscn") as PackedScene).instantiate() as Enemy
	look.set_meta(&"post_kind", "watch")
	look.position = Vector3(20, 0, 0)
	arena.add_child(look, true)
	await _seconds(3.0)
	for v in [["d_watch_torch", Vector3(21.6, 1.7, 3.2)], ["d_watch_torch_far", Vector3(26, 3.0, 8.0)]]:
		cam.global_position = v[1]
		cam.look_at(look.global_position + Vector3.UP * 1.1)
		await _frames(3)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % v[0])
	player.global_position = look.global_position + look.model.forward() * 9.0
	look._aggro(player, false)
	await _seconds(1.2)
	cam.global_position = look.global_position + Vector3(2.5, 2.2, 3.5)
	cam.look_at(look.global_position + Vector3.UP * 0.5)
	await _frames(3)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/d_watch_torch_dropped.png")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s, true, true).timeout


func _physics_process(_delta: float) -> void:
	DayNight.night = night
