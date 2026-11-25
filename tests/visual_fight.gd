extends Node
## Pictures of the fighting animation pass (ENEMY_LIFE_PLAN.md stage 6): bandits
## taunting while they wait their turn, Knights behind their shields, a hurt bandit
## hunched over. Not a pass/fail check. Run WITHOUT --headless; pictures go to user://shots/.
##   Godot_console.exe --path . --resolution 1280x720 --script res://tests/run.gd -- visual_fight

var player: Player
var cam: Camera3D
var _arena: Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	_arena = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(_arena)
	await _frames(20)
	player = get_tree().get_first_node_in_group(&"player") as Player
	for e in get_tree().get_nodes_in_group(&"enemies"):
		e.remove_from_group(&"enemies")
		e.queue_free()
	player.global_position = Vector3(0, 0.05, 0)
	cam = Camera3D.new()
	cam.fov = 50.0
	_arena.add_child(cam)
	cam.make_current()

	var gang: Array[Enemy] = await _gang("bandit_sword")
	await _shot_when(gang, func(e: Enemy) -> bool: return e.fight.is_posing() and e.model.current_anim() == EnemyFight.TAUNT_RAISE, "f01_bandit_taunt_raise")
	await _shot_when(gang, func(e: Enemy) -> bool: return e.fight.is_posing() and e.model.current_anim() == EnemyFight.TAUNT_NO, "f02_bandit_taunt_no")
	for e in gang:
		e.health = e.max_health * 0.2
	await _shot_when(gang, func(e: Enemy) -> bool: return e.model.current_anim() == EnemyFight.STANCE_HURT and e.velocity.length() < 0.2, "f03_bandit_hurt")
	_clear(gang)

	var knights: Array[Enemy] = await _gang("zealot")
	await _seconds(2.5)
	await _shot_when(knights, func(e: Enemy) -> bool: return e.state == Enemy.State.CHASE and e.model.current_anim() == EnemyFight.STANCE_SHIELD, "f04_knights_shields")
	get_tree().quit()


func _gang(kind: String) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for i in 4:
		var a := TAU * i / 4.0 + 0.4
		var e := (load("res://game/enemies/%s.tscn" % kind) as PackedScene).instantiate() as Enemy
		e.position = Vector3(cos(a), 0, sin(a)) * 4.0
		_arena.add_child(e, true)
		out.append(e)
	await _frames(2)
	for e in out:
		e._aggro(player, false)
	return out


func _clear(list: Array[Enemy]) -> void:
	for e in list:
		e.remove_from_group(&"enemies")
		e.queue_free()


## Fight on (the player can't be hurt) until one enemy matches, then photograph it
## from in front, over the player's shoulder.
func _shot_when(list: Array[Enemy], test: Callable, shot_name: String) -> void:
	for i in 60 * 20:
		await get_tree().physics_frame
		player._iframe_timer = 1.0
		player.health = player.max_health()
		for e in list:
			if is_instance_valid(e) and test.call(e):
				for k in 30:  # let it settle into the pose
					await get_tree().physics_frame
					player._iframe_timer = 1.0
				var to := e.global_position - player.global_position
				to.y = 0.0
				var side := to.normalized().cross(Vector3.UP)
				cam.global_position = player.global_position - to.normalized() * 2.5 + side * 1.2 + Vector3.UP * 3.4
				cam.look_at(e.global_position + Vector3.UP * 1.0)
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % shot_name)
				print("shot ", shot_name)
				return
	print("no shot for ", shot_name)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await get_tree().create_timer(s).timeout
