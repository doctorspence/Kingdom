extends Node
## Pictures of the bandits in their inspection room (not a pass/fail check). Windowed:
##   Godot_console --path . --resolution 1600x900 --script res://tests/run.gd -- visual_bandit [out dir] [shots...]
## Shots: "lineup", "lineup_back", or <bandit>:<shot> with bandit = rough brute rogue marksman
## marauder marauder_b captain rook hobb harl and shot = front three_quarter side back face third_person
##        idle walk run combat_idle attack attack2 hit death
## Add "+stone" to a shot for Harl after the stone answers him (harl:face+stone).

const KEYS := ["rough", "brute", "rogue", "marksman", "marauder", "marauder_b", "captain", "rook", "hobb", "harl"]
const PRESETS := {"front": 2, "three_quarter": 3, "side": 4, "back": 5, "face": 6, "third_person": 7}
## shot: [animation, time (s), camera orbit (degrees)]; "attack" / "attack2" use the enemy's own attacks
const POSED := {
	"idle": [&"Idle", 0.5, 28.0],
	"walk": [&"Walk", 0.45, 55.0],
	"run": [&"Jog_Fwd", 0.30, 62.0],
	"combat_idle": [&"Sword_Idle", 0.5, 28.0],
	"attack": [&"", 0.0, 40.0],
	"attack2": [&"", 0.0, -34.0],
	"hit": [&"Hit_Chest", 0.14, 40.0],
	"death": [&"Death01", 2.2, 40.0],
}
## Loaded at run time: the character scripts need the game's autoloads.
const ROOM := "res://levels/sandbox/bandit_showroom.tscn"

var room: Node3D


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := args[1] if args.size() > 1 else "user://shots/bandit"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var shots: Array = ["lineup", "lineup_back"]
	for k: String in KEYS:
		for s: String in PRESETS.keys() + POSED.keys():
			shots.append("%s:%s" % [k, s])
	if args.size() > 2:
		shots = args.slice(2)
	room = (load(ROOM) as PackedScene).instantiate()
	get_tree().root.add_child(room)
	await _frames(20)
	room.set_process_unhandled_key_input(false)
	for shot: String in shots:
		await _take(shot)
		await RenderingServer.frame_post_draw
		get_tree().root.get_texture().get_image().save_png("%s/bandit_%s.png" % [out_dir, shot.replace(":", "_")])
		print("saved ", shot)
	get_tree().quit()


func _take(shot: String) -> void:
	room.get(&"_info").visible = false
	if shot.begins_with("lineup"):
		room.call(&"view", 1)
		room.set(&"_hold", 1e9)
		var line: Array = room.get(&"lineup")
		for i in line.size():
			var b: Node3D = line[i]
			b.rotation_degrees.y = room.call(&"lineup_yaw", i) + (180.0 if shot == "lineup_back" else 0.0)
			_pose(b, &"Idle", 0.5)
		for l in get_tree().get_nodes_in_group(&"showroom_text"):
			(l as Node3D).visible = shot == "lineup"
		await _frames(24)
		return
	var key := shot.get_slice(":", 0)
	var what := shot.get_slice(":", 1).get_slice("+", 0)
	var index := KEYS.find(key)
	room.call(&"view", 2)
	room.call(&"choose", index)
	room.set(&"_hold", 1e9)
	var actor: Node3D = room.get(&"actor")
	if actor.has_method(&"show_stone"):
		actor.call(&"show_stone", shot.ends_with("+stone"))
	var anim := &"Idle"
	var at := 0.5
	if PRESETS.has(what):
		room.call(&"view", PRESETS[what])
		if what == "third_person":
			anim = &"Sword_Idle"
	else:
		var spec: Array = POSED[what]
		anim = spec[0]
		at = spec[1]
		if what.begins_with("attack"):
			var variants: Array = (room.get_script() as Script).get_script_constant_map()["VARIANTS"]
			var data: Resource = load(variants[index][3])
			var a: Resource = data.attacks[0 if what == "attack" else mini(1, data.attacks.size() - 1)]
			anim = a.anim
			at = (a.hit_start + a.hit_end) * 0.5
		room.set(&"_orbit", deg_to_rad(spec[2]))
		if what == "death":
			room.set(&"_focus", Vector3(0, 0.4, -0.5))
			room.set(&"_height", 1.6)
	await _frames(8)
	_pose(actor, anim, at)
	await _frames(24)


func _pose(b: Node3D, anim: StringName, at: float) -> void:
	b.call(&"play", anim, 0.0, 1.0, true)
	b.call(&"seek", at)
	b.call(&"set_speed", 0.0)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
