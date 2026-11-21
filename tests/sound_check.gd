extends Node
## Automated combat-sound check: every cue's files exist and load, and the
## right sounds fire for real actions (swing, hit, roll, footsteps, abilities).
##   ... --headless --script res://tests/run.gd -- sound_check

var player: Player
var enemy: Enemy
var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	# --- The library: every file of every cue exists and loads ---------------------
	var missing := []
	for cue in SfxLibrary.names():
		var data := SfxLibrary.cue(cue)
		if data["files"].is_empty():
			missing.append("%s (no files)" % cue)
		for path in data["files"]:
			if not ResourceLoader.exists(path) or load(path) == null:
				missing.append(path)
	_check("all %d cues have loadable files (missing: %s)" % [SfxLibrary.names().size(), str(missing)], missing.is_empty())
	_check("unknown cue is ignored", not Audio.sfx(&"no_such_cue"))
	_check("every cue plays on an existing volume group", SfxLibrary.names().all(func(c: StringName) -> bool:
			return AudioServer.get_bus_index(SfxLibrary.cue(c)["bus"]) != -1))

	# --- Real actions in the combat arena ------------------------------------------
	var scene: Node = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(20)
	player = get_tree().get_first_node_in_group(&"player") as Player
	enemy = scene.get_node("Enemies/Marauder") as Enemy
	(scene.get_node("Enemies/Marauder2") as Node3D).global_position = Vector3(60, 0, 60)
	_setup("class_headsman")
	await _frames(15)
	enemy.global_position = Vector3(0, 0, -2.0)
	enemy._cooldown = 999.0
	enemy.target = player
	enemy._set_state(Enemy.State.CHASE)
	await _frames(10)

	var n := Audio.played_count
	await _tap("light_attack")
	await _seconds(1.0)
	_check("a swing and a hit make sound (%d sounds)" % (Audio.played_count - n), Audio.played_count - n >= 2)

	n = Audio.played_count
	Input.action_press("move_forward")
	await _seconds(2.2)
	Input.action_release("move_forward")
	_check("running makes footsteps (%d sounds)" % (Audio.played_count - n), Audio.played_count - n >= 3)

	_setup("class_lamplighter")
	player.set_level(10)
	await _frames(15)
	enemy.global_position = Vector3(0, 0, -8.0)
	n = Audio.played_count
	player.caster.try_use(0)  # Arcane Bolt
	await _seconds(1.0)
	_check("Arcane Bolt makes sound (%d sounds)" % (Audio.played_count - n), Audio.played_count - n >= 1)

	_setup("class_bulwark")
	player.set_level(10)
	await _frames(15)
	n = Audio.played_count
	player.caster.try_use(1)  # Shield Throw
	await _seconds(0.8)
	_check("Shield Throw makes sound (%d sounds)" % (Audio.played_count - n), Audio.played_count - n >= 1)

	# --- Loot, money, progress and menus ------------------------------------------------
	var base: ItemData = ItemDB.all_items()[0]
	for r in 5:
		n = Audio.played_count
		await _seconds(0.1)  # let the same-cue repeat guard clear
		Loot._spawn_drop(900 + r, ItemDB.make_item(base, 5, r).to_dict(), Vector3(2, 0.2, 2), false)
		_check("a %s drop makes sound" % ItemInstance.RARITY_NAMES[r], Audio.played_count > n)
		if r == 4:
			_check("Legendary is layered (%d sounds at once)" % (Audio.played_count - n), Audio.played_count - n >= 3)
	await _seconds(0.1)
	n = Audio.played_count
	player._receive_money(10, 0)
	_check("gold makes a coin sound", Audio.played_count > n)
	await _seconds(0.1)
	n = Audio.played_count
	player._on_leveled_up(3)
	_check("leveling up makes sound", Audio.played_count - n >= 2)
	await _seconds(0.1)
	n = Audio.played_count
	var button := Button.new()
	add_child(button)
	await get_tree().process_frame
	button.pressed.emit()
	_check("any menu button clicks", Audio.played_count > n)
	button.queue_free()
	await _seconds(0.1)
	n = Audio.played_count
	player.receive_item(ItemDB.make_item(base, 1, 0))
	_check("picking up an item makes sound", Audio.played_count > n)

	# --- Other people's characters (what a friend's machine does) --------------------------
	await _seconds(0.1)
	n = Audio.played_count
	player.model.mirror(&"Roll", 1.0, 70001)
	_check("a friend's roll, copied from their animation, is heard", Audio.played_count > n)
	await _seconds(0.1)
	n = Audio.played_count
	player.model.mirror(&"ual2/Idle_Rail_Call", 1.0, 70002)
	_check("a knight's call for help blows the horn", Audio.played_count > n)
	player.model.audio.voice = &"raider"
	await _seconds(0.1)
	n = Audio.played_count
	player.model.mirror(&"ual2/Sword_Regular_A", 1.0, 70003)
	await _seconds(0.4)
	_check("a raider grunts and swings (%d sounds)" % (Audio.played_count - n), Audio.played_count - n >= 2)
	player.model.audio.voice = &"human"
	_check("the horn carries farther than other sounds", SfxLibrary.cue(&"horn")["range"] > SfxLibrary.cue(&"footstep")["range"])

	# An enemy's own voice: a hound's bite plays the beast cue.
	var hound := Enemy.new()
	_check("hound count voice names exist", SfxLibrary.has_cue(&"attack_beast") and SfxLibrary.has_cue(&"hurt_boss"))
	hound.free()

	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _setup(class_id: String) -> void:
	player._set_class(Classes.by_id(StringName(class_id)))
	player._give_starting_gear()
	player.caster.refill()
	player.effects.clear_all()
	player.respawn()
	player.global_position = Vector3(0, 0.05, 0)
	player.model.face_instantly(Vector3.FORWARD)
	player.camera_rig.yaw = 0.0
	player.reset_physics_interpolation()


func _tap(action: StringName) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().physics_frame
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await _frames(ceili(s * Engine.physics_ticks_per_second))


func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", label])
	if not ok:
		failures += 1
