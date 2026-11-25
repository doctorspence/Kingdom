extends Node
## Pictures of enemies on their posts (ENEMY_LIFE_PLAN.md): a bandit huddle, Knights,
## weapons on the hip and back, and the same group after it draws. Not a pass/fail check.
## Run through tests/run.gd WITHOUT --headless; pictures go to user://shots/.
##   Godot_console.exe --path . --resolution 1280x720 --script res://tests/run.gd -- visual_posts

var player: Player
var cam: Camera3D


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
	cam.fov = 50.0
	arena.add_child(cam)
	cam.make_current()

	var huddle: Array[Enemy] = []
	for i in 3:
		var a := TAU * i / 3.0 + 0.3
		huddle.append(_add(arena, "bandit_sword", Vector3(cos(a), 0, sin(a)) * 1.3))
	var knights: Array[Enemy] = [
		_add(arena, "zealot", Vector3(8, 0, -0.8)),
		_add(arena, "zealot", Vector3(8, 0, 0.8)),
	]
	var archer := _add(arena, "bandit_archer", Vector3(-7, 0, 0))
	archer.model.face_instantly(Vector3(0, 0, 1))
	await _seconds(4.0)

	await _shot("p01_huddle", Vector3(0, 2.2, 5.5), Vector3(0, 1.0, 0))
	await _seconds(3.0)
	await _shot("p02_huddle_later", Vector3(3.5, 2.0, 4.0), Vector3(0, 1.0, 0))
	await _shot("p03_knights", Vector3(8, 1.8, 4.5), Vector3(8, 1.1, 0))
	# Close-ups: the hip and the back.
	var b := huddle[0]
	await _shot("p04_hip_side", _beside(b, 1.0, 1.8), b.global_position + Vector3.UP * 0.95)
	await _shot("p05_hip_front", _beside(b, 0.0, 1.8), b.global_position + Vector3.UP * 0.95)
	var k := knights[0]
	await _shot("p06_knight_back", _beside(k, PI, 2.2), k.global_position + Vector3.UP * 1.2)
	await _shot("p07_knight_hip", _beside(k, 1.0, 2.0), k.global_position + Vector3.UP * 0.95)
	await _shot("p08_archer_back", _beside(archer, PI, 2.4), archer.global_position + Vector3.UP * 1.2)
	# The fight starts: everyone draws.
	player.global_position = Vector3(0, 0.05, 9)
	player.model.face_instantly(Vector3(0, 0, -1))
	await _seconds(0.2)
	await _shot("p09_noticed", Vector3(-2.5, 2.4, 9.5), Vector3(0, 1.0, 0))
	await _seconds(0.9)
	await _shot("p10_drawn", Vector3(-2.5, 2.4, 9.5), Vector3(0, 1.0, 2))
	get_tree().quit()


func _add(arena: Node, kind: String, at: Vector3) -> Enemy:
	var e := (load("res://game/enemies/%s.tscn" % kind) as PackedScene).instantiate() as Enemy
	e.position = at
	arena.add_child(e, true)
	return e


## A camera spot around `e`: `angle` 0 = in front of it, PI = behind, at `dist` meters.
func _beside(e: Enemy, angle: float, dist: float) -> Vector3:
	var f := e.model.forward()
	f.y = 0.0
	f = f.normalized().rotated(Vector3.UP, angle)
	return e.global_position + f * dist + Vector3.UP * 1.3


func _shot(shot_name: String, from: Vector3, at: Vector3) -> void:
	cam.global_position = from
	cam.look_at(at)
	await _frames(3)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % shot_name)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
