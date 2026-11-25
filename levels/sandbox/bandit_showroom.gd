extends Node3D
## The bandit inspection room. Open levels/sandbox/bandit_showroom.tscn in Godot and press F6.
##
## Keys: 1 all the bandits   2 front   3 three-quarter   4 side   5 back   6 face
##       7 behind-the-player view   V next bandit
##       Space / Right: next animation   Left: previous   A / D: turn the camera   H: hide text

## Every bandit, each as the game wears him: [key, name, character scene, enemy data (gear, attacks)]
const VARIANTS := [
	["rough", "Swordsman", "res://assets/characters/bandit/bandit.tscn", "res://data/enemies/enemy_bandit_sword.tres"],
	["brute", "Mace man", "res://assets/characters/bandit/bandit_brute.tscn", "res://data/enemies/enemy_bandit_pick.tres"],
	["rogue", "Knife lookout", "res://assets/characters/bandit/bandit_rogue.tscn", "res://data/enemies/enemy_bandit_lookout.tres"],
	["marksman", "Crossbowman", "res://assets/characters/bandit/bandit_marksman.tscn", "res://data/enemies/enemy_bandit_archer.tres"],
	["marauder", "Marauder", "res://assets/characters/bandit/bandit_marauder.tscn", "res://data/enemies/enemy_marauder.tres"],
	["marauder_b", "Marauder", "res://assets/characters/bandit/bandit_marauder_b.tscn", "res://data/enemies/enemy_marauder.tres"],
	["captain", "Captain", "res://assets/characters/bandit/bandit_captain.tscn", "res://data/enemies/enemy_bandit_captain.tres"],
	["rook", "Rook", "res://assets/characters/bandit/bandit_rook.tscn", "res://data/enemies/enemy_bandit_rook.tres"],
	["hobb", "Hobb", "res://assets/characters/bandit/bandit_hobb.tscn", "res://data/enemies/enemy_hobb.tres"],
]
## Space between bandits in the line-up (meters).
const SPACING := 1.22
## Camera presets: how the single bandit is turned (degrees).
const YAWS := {2: 0.0, 3: -38.0, 4: -90.0, 5: 180.0, 6: -22.0, 7: 0.0}

var variant := 0
var preset := 1
var actor: Node3D
var lineup: Array[Node3D] = []
var camera: Camera3D
var _anims: Array = []   # [name shown, animation, plays once]
var _anim_index := 0
var _hold := 0.0
var _orbit := 0.0
var _focus := Vector3(0, 0.95, 0)
var _distance := 7.0
var _height := 0.35
var _info: Label


func _ready() -> void:
	_lights()
	_floor()
	for i in VARIANTS.size():
		var b := make_bandit(i)
		add_child(b)
		b.position = Vector3((i - (VARIANTS.size() - 1) * 0.5) * SPACING, 0, 0)
		b.rotation_degrees.y = lineup_yaw(i)
		b.call(&"play", &"Idle", 0.0)
		var l := Label3D.new()
		l.text = VARIANTS[i][1]
		l.font_size = 40
		l.pixel_size = 0.0026
		l.modulate = Color(0.82, 0.76, 0.62)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.position = b.position + Vector3(0, 2.25, 0)
		l.add_to_group(&"showroom_text")
		add_child(l)
		lineup.append(b)
	camera = Camera3D.new()
	camera.fov = 40.0
	add_child(camera)
	camera.make_current()
	var ui := CanvasLayer.new()
	add_child(ui)
	_info = Label.new()
	_info.position = Vector2(24, 20)
	_info.add_theme_font_size_override(&"font_size", 22)
	ui.add_child(_info)
	choose(0)
	view(1)


## Each bandit in the line-up is turned a little toward the middle (degrees).
func lineup_yaw(i: int) -> float:
	return lerpf(16.0, -16.0, float(i) / (VARIANTS.size() - 1))


## A bandit as the game wears him: the character scene plus the gear named in his enemy data.
func make_bandit(i: int) -> Node3D:
	var b: Node3D = (load(VARIANTS[i][2]) as PackedScene).instantiate()
	var data: Resource = load(VARIANTS[i][3])
	b.ready.connect(func() -> void:
		if data.weapon_scene:
			b.call(&"attach_to_hand", data.weapon_scene.instantiate(), "r")
		if data.offhand_scene:
			b.call(&"attach_to_hand", data.offhand_scene.instantiate(), "l"))
	return b


## Puts variant `i` on the single stand used by every close view.
func choose(i: int) -> void:
	variant = i
	if actor:
		actor.queue_free()
	actor = make_bandit(i)
	add_child(actor)
	var data: Resource = load(VARIANTS[i][3])
	_anims = [["Idle", &"Idle", false], ["Walk", &"Walk", false], ["Run", &"Jog_Fwd", false], ["Combat idle", &"Sword_Idle", false]]
	for a in data.attacks:
		_anims.append(["Attack: " + a.display_name, a.anim, true])
	_anims.append_array([["Hit reaction", &"Hit_Chest", true], ["Knocked back", &"ual2/Hit_Knockback", true], ["Death", &"Death01", true]])
	_anim_index = 0
	view(preset)
	_show_anim()


## Camera presets (also used by tests/visual_bandit.gd).
func view(n: int) -> void:
	preset = n
	_orbit = 0.0
	_height = 0.30
	_focus = Vector3(0, 0.93, 0)
	_distance = 3.2
	match n:
		1:
			_focus = Vector3(0, 1.02, 0)
			_distance = 10.4
			_height = 0.9
		6:
			_focus = Vector3(0, 1.58, 0)
			_distance = 1.35
			_height = 0.06
		7:
			# the game camera's place: behind and above a player standing in front of the bandit
			_focus = Vector3(0, 1.1, 0.4)
			_distance = 4.6
			_height = 1.15
	for b in lineup:
		b.visible = n == 1
	if actor:
		actor.visible = n != 1
		actor.rotation_degrees.y = YAWS.get(n, 0.0)
	for l in get_tree().get_nodes_in_group(&"showroom_text"):
		(l as Node3D).visible = n == 1
	_update_text()


func _show_anim() -> void:
	var a: Array = _anims[_anim_index]
	actor.call(&"play", a[1], 0.15, 1.0, true)
	_hold = actor.call(&"anim_length", a[1]) + 0.9
	_update_text()


func _update_text() -> void:
	if _info and not _anims.is_empty():
		_info.text = "%s: %s\n1-7 views   V next bandit   Space / arrows animation   A D turn   H text" % [VARIANTS[variant][1].to_upper(), _anims[_anim_index][0]]


func _lights() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.095, 0.095, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.60, 0.60, 0.62)
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.ssao_intensity = 1.2
	we.environment = env
	add_child(we)
	for l in [[Vector3(-36, 32, 0), Color(1.0, 0.93, 0.83), 1.5, true], [Vector3(-14, -62, 0), Color(0.78, 0.84, 1.0), 0.55, false],
			[Vector3(-28, 172, 0), Color(0.9, 0.92, 1.0), 0.9, false]]:
		var d := DirectionalLight3D.new()
		d.rotation_degrees = l[0]
		d.light_color = l[1]
		d.light_energy = l[2]
		d.shadow_enabled = l[3]
		d.directional_shadow_max_distance = 20.0
		add_child(d)


func _floor() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 9.0
	mesh.bottom_radius = 9.0
	mesh.height = 0.2
	mesh.radial_segments = 48
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.15, 0.14)
	mat.roughness = 1.0
	mat.metallic_specular = 0.0
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position.y = -0.1
	add_child(mi)


func _process(delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_A):
		_orbit -= delta * 1.6
	if Input.is_physical_key_pressed(KEY_D):
		_orbit += delta * 1.6
	camera.position = _focus + Vector3(sin(_orbit) * _distance, _height, cos(_orbit) * _distance)
	camera.look_at(_focus)
	# play the one-shot animations again after a short rest
	_hold -= delta
	if _hold <= 0.0 and _anims[_anim_index][2]:
		_show_anim()


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	var step := 0
	if k.physical_keycode >= KEY_1 and k.physical_keycode <= KEY_7:
		view(k.physical_keycode - KEY_0)
	elif k.physical_keycode == KEY_V:
		if preset == 1:
			view(2)
		choose((variant + 1) % VARIANTS.size())
	elif k.physical_keycode == KEY_SPACE or k.physical_keycode == KEY_RIGHT:
		step = 1
	elif k.physical_keycode == KEY_LEFT:
		step = -1
	elif k.physical_keycode == KEY_H:
		_info.visible = not _info.visible
	if step != 0:
		if preset == 1:
			view(2)
		_anim_index = posmod(_anim_index + step, _anims.size())
		_show_anim()
