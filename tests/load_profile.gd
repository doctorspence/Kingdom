extends Node
## Load-time breakdown for the Tithelands (not pass/fail): adds the zone's top-level
## nodes one at a time and prints how long each takes, including work it defers.
##   Godot_console.exe --path . --script res://tests/run.gd -- load_profile


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var t := Time.get_ticks_msec()
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	print("LOADPART %-18s %5d ms" % ["scene file", Time.get_ticks_msec() - t])
	var kids := scene.get_children()
	for k in kids:
		scene.remove_child(k)
	get_tree().root.add_child(scene)
	var total := 0
	for k in kids:
		t = Time.get_ticks_msec()
		scene.add_child(k)
		await get_tree().process_frame
		var ms := Time.get_ticks_msec() - t
		total += ms
		if ms > 40:
			print("LOADPART %-18s %5d ms" % [k.name, ms])
	print("LOADPART %-18s %5d ms" % ["all nodes", total])
	get_tree().quit()
