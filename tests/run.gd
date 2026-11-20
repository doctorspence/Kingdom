extends SceneTree
## Starts an automated check after the game's autoloads (InputSetup, CombatFx)
## are ready, so check scripts can use them.
##
## Run (from the project folder), naming the check after "--":
##   Godot_console.exe --headless --path . --script res://tests/run.gd -- movement_check
##   Godot_console.exe --headless --path . --script res://tests/run.gd -- combat_check

func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	# Checks must not change your saved name or join address.
	root.get_node("Net").set(&"save_settings_enabled", false)
	var args := OS.get_cmdline_user_args()
	var check_name := args[0] if args.size() > 0 else "movement_check"
	var script: GDScript = load("res://tests/%s.gd" % check_name)
	if script == null:
		push_error("No check named %s" % check_name)
		quit(2)
		return
	root.add_child(script.new())
