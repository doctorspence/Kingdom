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
	_check("main menu builds with a Settings button", menu.find_children("*", "Button", true, false).any(func(b: Node) -> bool: return (b as Button).text == "Settings"))

	Audio.set_volume(&"Music", before)

	# --- Zone ambience and music ---------------------------------------------------
	var dn := DayNight.new()
	dn.process_mode = Node.PROCESS_MODE_DISABLED  # we set the numbers by hand
	add_child(dn)
	var za := ZoneAudio.new()
	za.run_headless = true
	za.day_night = dn
	za.crow_gap = Vector2(999, 999)
	za.fade = 0.4
	za.music_gap = Vector2(0.1, 0.1)
	add_child(za)
	za._music_wait = 0.1
	DayNight.cave = 0.0
	DayNight.night = 0.0
	dn.rain_amount = 0.0
	await get_tree().create_timer(1.6).timeout
	_check("daytime: the forest bed plays, rain and cave do not (%.2f / %.2f / %.2f)" % [za._levels[&"forest"], za._levels[&"rain"], za._levels[&"cave"]],
			za._levels[&"forest"] > 0.9 and za._levels[&"rain"] < 0.01 and za._levels[&"cave"] < 0.01 and za.get_node("forest").playing and za.get_node("wind").playing)
	_check("daytime music: the forest theme (%s)" % za.current_track, za.current_track == "GameMusic_ForestTheme_24.mp3")
	dn.rain_amount = 1.0
	await get_tree().create_timer(1.6).timeout
	_check("rain showers bring the rain bed in and the forest down (%.2f / %.2f)" % [za._levels[&"rain"], za._levels[&"forest"]],
			za._levels[&"rain"] > 0.9 and za._levels[&"forest"] < 0.5 and za.get_node("rain").playing)
	dn.rain_amount = 0.0
	DayNight.cave = 1.0
	await get_tree().create_timer(1.6).timeout
	_check("underground: cave beds play, forest and music stop (%.2f / %.2f, music %s)" % [za._levels[&"cave"], za._levels[&"forest"], str(za._music.playing)],
			za._levels[&"cave"] > 0.9 and za._levels[&"forest"] < 0.01 and not za._music.playing and za.get_node("cave").playing)
	DayNight.cave = 0.0
	DayNight.night = 1.0
	await get_tree().create_timer(1.6).timeout
	_check("night: quieter forest (%.2f) and the lament plays (%s)" % [za._levels[&"forest"], za.current_track],
			za._levels[&"forest"] < 0.5 and za.current_track == "Lament_for_a_Warriors_Soul.mp3")
	DayNight.night = 0.0
	await get_tree().create_timer(1.6).timeout
	za.force_boss = 1  # a boss starts fighting
	await get_tree().create_timer(2.5).timeout
	_check("boss fight: the boss track plays, ambience ducks, normal music stops (level %.2f, forest %.2f)" % [za.boss_level, za._levels[&"forest"]],
			za._boss.playing and za.boss_level > 0.9 and za._levels[&"forest"] < 0.4 and not za._music.playing)
	var phase1_db := za._boss.volume_db
	za.force_boss = 2  # phase 2
	await get_tree().create_timer(2.0).timeout
	_check("phase 2: louder and faster (%.1f dB -> %.1f dB, pitch %.2f)" % [phase1_db, za._boss.volume_db, za._boss.pitch_scale],
			za._boss.volume_db > phase1_db + 1.0 and za._boss.pitch_scale > 1.0)
	za.force_boss = -1  # the boss dies
	await get_tree().create_timer(1.6).timeout
	_check("boss dead: the track fades out and the forest comes back (boss %.2f, forest %.2f, playing %s)" % [za.boss_level, za._levels[&"forest"], str(za._boss.playing)],
			not za._boss.playing and za._levels[&"forest"] > 0.9)
	za.queue_free()
	dn.queue_free()
	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", label])
	if not ok:
		failures += 1
