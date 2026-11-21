extends Node
## Automated audio check: the volume groups exist and route to Master, volume
## changes take effect (and 0 mutes), the slider panel drives them, and the
## main menu still builds with its Volume button.
##   ... --headless --script res://tests/run.gd -- audio_check

var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	for g in Audio.GROUPS:
		var i := AudioServer.get_bus_index(g)
		_check("bus %s exists" % g, i != -1)
		if g != &"Master" and i != -1:
			_check("bus %s sends to Master" % g, AudioServer.get_bus_send(i) == &"Master")
	var before: float = Audio.get_volume(&"Music")
	Audio.set_volume(&"Music", 0.5)
	var mi := AudioServer.get_bus_index(&"Music")
	_check("Music at 0.5 is about -6 dB (%.1f)" % AudioServer.get_bus_volume_db(mi),
			absf(AudioServer.get_bus_volume_db(mi) - linear_to_db(0.5)) < 0.1 and not AudioServer.is_bus_mute(mi))
	Audio.set_volume(&"Music", 0.0)
	_check("Music at 0 is muted", AudioServer.is_bus_mute(mi))
	Audio.set_volume(&"Music", 5.0)
	_check("Volume is clamped to 1", Audio.get_volume(&"Music") == 1.0)

	var panel := AudioSettings.new()
	add_child(panel)
	await get_tree().process_frame
	var slider := panel.find_child("Slider_Effects", true, false) as HSlider
	_check("slider panel has a slider per group", panel.find_children("Slider_*", "HSlider", true, false).size() == Audio.GROUPS.size())
	slider.value = 0.35
	_check("moving the Effects slider changes the Effects volume (%.2f)" % Audio.get_volume(&"Effects"),
			absf(Audio.get_volume(&"Effects") - 0.35) < 0.001)

	var menu: Node = load("res://game/ui/main_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	_check("main menu builds with a Volume button", menu.find_children("*", "Button", true, false).any(func(b: Node) -> bool: return (b as Button).text == "Volume"))

	Audio.set_volume(&"Music", before)
	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", label])
	if not ok:
		failures += 1
