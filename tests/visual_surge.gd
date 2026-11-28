extends Node
## Pictures of Arcane Surge (not a pass/fail check): gather, channel, release, the wave
## in flight and the impact on an enemy, from the side, the front and behind.
## Run through tests/run.gd WITHOUT --headless:
##   Godot_console.exe --path . --resolution 1280x720 --script res://tests/run.gd -- visual_surge
## Pictures go to user://shots/surge_*.png (%APPDATA%\Godot\app_userdata\Kingdom\shots).

var player: Player
var cam: Camera3D
var enemy: Enemy

## name, frames after the cast starts (60 per second), camera position, look-at (both
## relative to the player), field of view.
const SHOTS := [
	# The cast releases at 0.333 s (frame 20); the wave then moves 0.4 m a frame.
	["1_gather_side", 4, Vector3(3.2, 1.5, -0.3), Vector3(0, 1.3, -0.3), 45.0],
	["1_gather_front", 4, Vector3(1.6, 1.5, -2.6), Vector3(0, 1.3, 0), 45.0],
	["2_channel_side", 16, Vector3(3.2, 1.5, -0.3), Vector3(0, 1.3, -0.3), 45.0],
	["2_channel_front", 16, Vector3(1.6, 1.5, -2.6), Vector3(0, 1.3, 0), 45.0],
	["3_release_side", 22, Vector3(3.4, 1.5, -0.6), Vector3(0, 1.3, -0.6), 50.0],
	["3_release_front", 22, Vector3(1.8, 1.4, -3.0), Vector3(0, 1.2, 0), 50.0],
	["4_wave_side", 28, Vector3(9.0, 2.6, -3.0), Vector3(0, 1.0, -3.0), 60.0],
	["4_wave_back", 30, Vector3(-2.0, 3.2, 5.0), Vector3(0, 1.0, -5.0), 65.0],
	["5_impact_side", 37, Vector3(9.0, 2.4, -6.0), Vector3(0, 1.0, -6.0), 60.0],
	["5_impact_back", 37, Vector3(-3.0, 2.6, 3.0), Vector3(0, 1.0, -6.0), 60.0],
]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	get_tree().root.get_node("Net").set(&"character", {"class": &"class_lamplighter"})
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _physics(40)
	player = get_tree().get_first_node_in_group(&"player") as Player
	for e in get_tree().get_nodes_in_group(&"enemies"):
		(e as Node3D).global_position = Vector3(60, 0, 60)
	enemy = scene.get_node("Enemies/Marauder") as Enemy
	cam = Camera3D.new()
	scene.add_child(cam)
	for s in SHOTS:
		await _reset()
		player.caster.try_use(0)
		await _physics(s[1])
		var at := player.global_position
		cam.fov = s[4]
		cam.global_position = at + s[2]
		cam.look_at(at + s[3])
		cam.make_current()
		await _physics(1)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shots/surge_%s.png" % s[0])
		print("wrote surge_%s.png" % s[0])
	get_tree().quit()


func _reset() -> void:
	player.respawn()
	player.caster.refill()
	player.effects.clear_all()
	await _physics(4)
	player.global_position = Vector3(0, 0.05, 0)
	player.model.face_instantly(Vector3.FORWARD)
	player.camera_rig.yaw = 0.0
	player.reset_physics_interpolation()
	enemy.reset_from_rest()
	enemy.global_position = Vector3(0, 0, -7.0)
	enemy.model.face_instantly(Vector3.BACK)
	enemy.reset_physics_interpolation()
	enemy.target = null
	enemy._set_state(Enemy.State.IDLE)
	await _physics(30)


func _physics(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
