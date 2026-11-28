extends SceneTree
## Screenshots of the swamp look test scene (levels/sandbox/swamp_look). Windowed, not a check.
##   Godot_console.exe --path . --resolution 1920x1080 --script res://tests/visual_swamp_look.gd -- <out dir> [shot names...]
## Shots: hero reeds lanterns arch wide tithe (hero view under the Tithelands' lighting)

const VIEWS := {
	"hero": [Vector3(0.0, 1.45, 9.0), Vector3(4.0, 0.0, 0.0)],
	"reeds": [Vector3(3.0, 1.0, 2.0), Vector3(-6.0, 20.0, 0.0)],
	"lanterns": [Vector3(-4.0, 1.8, -8.0), Vector3(-4.0, 35.0, 0.0)],
	"arch": [Vector3(3.0, 1.6, -18.0), Vector3(2.0, -8.0, 0.0)],
	"wide": [Vector3(0.0, 6.0, 14.0), Vector3(-6.0, 0.0, 0.0)],
	"tithe": [Vector3(0.0, 1.45, 9.0), Vector3(4.0, 0.0, 0.0)],
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else "user://shots"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var shots: Array = VIEWS.keys()
	if args.size() > 1:
		shots = args.slice(1)
	var t0 := Time.get_ticks_msec()
	var scene: Node3D = load("res://levels/sandbox/swamp_look/swamp_look.tscn").instantiate()
	root.add_child(scene)
	print("Built in %d ms" % (Time.get_ticks_msec() - t0))
	for s in shots:
		var v: Array = VIEWS[s]
		scene.set_view(v[0], v[1])
		scene.world_env.environment = load(scene.TITHE_ENV) if s == "tithe" else scene.swamp_env
		for i in 120:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/swamp_%s.png" % [out_dir, s])
	print("FPS %d" % Engine.get_frames_per_second())
	quit()
