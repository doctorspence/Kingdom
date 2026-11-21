extends Node
## Screenshots of each class in action (not a pass/fail check). Windowed.
## Pictures go to user://shots/class_*.png

var player: Player
var enemy: Enemy


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(30)
	player = get_tree().get_first_node_in_group(&"player") as Player
	enemy = scene.get_node("Enemies/Marauder") as Enemy
	(scene.get_node("Enemies/Marauder2") as Node3D).global_position = Vector3(60, 0, 60)

	# Bulwark: Rallying Bellow
	await _setup("class_bulwark", 0, 0)
	player.caster.resource = 100.0
	player.caster.try_use(3)
	await _frames(14)
	await _shot("class_bulwark_bellow")
	# Lamplighter (slender body): Vigil Lantern + Kindle in flight
	await _setup("class_lamplighter", 1, 1)
	player.camera_rig.pitch = deg_to_rad(-25.0)
	player.caster.try_use(1)
	await _frames(70)
	player.caster.try_use(0)
	await _frames(30)
	await _shot("class_lamplighter_vigil")
	# Headsman: Cleave
	await _setup("class_headsman", 0, 3)
	player.caster.try_use(3)
	await _frames(40)
	await _shot("class_headsman_cleave")
	# Talent panel
	player.set_level(12)
	var hud := get_tree().current_scene.get_node("Hud") if get_tree().current_scene else null
	for n in CombatFx.world().get_children():
		if n is Hud:
			hud = n
	if hud:
		(hud as Hud)._talents.toggle()
	await _frames(10)
	await _shot("class_talents")
	get_tree().quit()


func _setup(class_id: String, body: int, color: int) -> void:
	player.net_body = body
	player.net_color = color
	player._set_class(Classes.by_id(StringName(class_id)))
	player.set_level(20)
	player.caster.refill()
	player.respawn()
	await _frames(2)
	player.global_position = Vector3(0, 0.05, 0)
	player.model.face_instantly(Vector3.FORWARD)
	player.camera_rig.yaw = deg_to_rad(-30.0)
	player.reset_physics_interpolation()
	if player.stats.class_data.resource_kind == ClassData.ResourceKind.OIL:
		player.caster.resource = player.stats.resource_max()
	enemy.reset_from_rest()
	enemy.global_position = Vector3(0, 0, -2.4)
	enemy.model.face_instantly(Vector3.BACK)
	enemy.target = player
	enemy._set_state(Enemy.State.CHASE)
	enemy._cooldown = 999.0
	await _frames(20)


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % shot_name)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
