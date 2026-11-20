extends Node
## Screenshots of a 2-player game (not a pass/fail check).
##   host:  ... --script res://tests/run.gd -- visual_coop host   (can be headless)
##   guest: ... --script res://tests/run.gd -- visual_coop guest  (windowed; saves user://shots/coop_*.png)

var role := "host"
var t := 0.0
var started := false
var _done := {}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	role = args[1] if args.size() > 1 else "host"
	if role == "host":
		Net.player_name = "Hostia"
		Net.host_game()
	else:
		Net.player_name = "Guestor"
		Net.join_game("127.0.0.1")
	get_tree().create_timer(40.0).timeout.connect(func() -> void: get_tree().quit(3))


func _physics_process(delta: float) -> void:
	if not started:
		if get_tree().get_nodes_in_group(&"player").size() >= 2:
			started = true
		return
	t += delta
	var me := get_tree().get_first_node_in_group(&"local_player") as Player
	if role == "host":
		_at(1.0, func() -> void: Net.send_chat("Welcome to the Tithelands."))
		_at(15.0, func() -> void: get_tree().quit())
		return
	_at(2.5, func() -> void:
		me.global_position = Vector3(2.5, 0.05, 17.5)
		me.camera_rig.yaw = deg_to_rad(150.0)
		me.reset_physics_interpolation())
	_at(3.0, func() -> void: Net.send_chat("Ready when you are."))
	_at(4.5, func() -> void: _shot("coop_guest_view"))
	_at(5.5, func() -> void: get_tree().quit())


func _at(time: float, action: Callable) -> void:
	if t >= time and not _done.has(time):
		_done[time] = true
		action.call()


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % shot_name)
