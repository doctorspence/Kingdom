class_name CharacterPreview
extends SubViewportContainer
## Your character on a stone pedestal under an arch, lit by two torches, for the
## inventory screen. Shows the same gear other players see on you. Drag with the
## mouse (or the right stick) to turn it.

const MANNEQUIN := preload("res://assets/characters/mannequin/UAL1_Standard.glb")
const STONE := preload("res://assets/textures/stonewall/color.jpg")
const STONE_N := preload("res://assets/textures/stonewall/normal.jpg")
const COBBLE := preload("res://assets/textures/cobble/color.jpg")
const COBBLE_N := preload("res://assets/textures/cobble/normal.jpg")
## The alcove behind the character: half its width, and the height where the arch starts.
const ARCH_R := 0.68
const ARCH_SPRING := 1.95

var _vp: SubViewport
var _turntable: Node3D
var _model: CharacterModel
var _torches: Array[OmniLight3D] = []
var _yaw := deg_to_rad(18.0)
var _drag := false
var _look_key := ""
var _t := 0.0


func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
	add_child(_vp)
	_build_scene()


func _build_scene() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.018, 0.016)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.27, 0.22)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	env.fog_enabled = true
	env.fog_light_color = Color(0.09, 0.07, 0.055)
	env.fog_density = 0.035
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)

	var cam := Camera3D.new()
	cam.fov = 30.0
	cam.position = Vector3(0, 1.32, 5.7)
	cam.rotation_degrees = Vector3(-3.0, 0, 0)
	_vp.add_child(cam)

	# Back wall with an arched alcove.
	var stone := _mat(STONE, STONE_N, Vector3(2.2, 2.2, 1), Color(0.62, 0.56, 0.5))
	var wall := CSGCombiner3D.new()
	_vp.add_child(wall)
	var slab := CSGBox3D.new()
	slab.size = Vector3(8, 6, 0.6)
	slab.position = Vector3(0, 2.6, -1.6)
	slab.material = stone
	wall.add_child(slab)
	var cut := CSGBox3D.new()
	cut.operation = CSGShape3D.OPERATION_SUBTRACTION
	cut.size = Vector3(ARCH_R * 2.0, ARCH_SPRING, 0.5)
	cut.position = Vector3(0, ARCH_SPRING * 0.5, -1.45)
	cut.material = stone
	wall.add_child(cut)
	var arch := CSGCylinder3D.new()
	arch.operation = CSGShape3D.OPERATION_SUBTRACTION
	arch.radius = ARCH_R
	arch.height = 0.5
	arch.sides = 32
	arch.rotation_degrees = Vector3(90, 0, 0)
	arch.position = Vector3(0, ARCH_SPRING, -1.45)
	arch.material = stone
	wall.add_child(arch)
	# The arch's dressed stones: a ring of blocks standing proud of the wall.
	var trim := _mat(STONE, STONE_N, Vector3(1, 1, 1), Color(0.72, 0.64, 0.55))
	for i in 13:
		var a := PI * float(i) / 12.0
		var block := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.26, 0.34, 0.2)
		block.mesh = bm
		block.material_override = trim
		block.position = Vector3(cos(a) * (ARCH_R + 0.13), ARCH_SPRING + sin(a) * (ARCH_R + 0.13), -1.22)
		block.rotation = Vector3(0, 0, a - PI * 0.5)
		_vp.add_child(block)
	for side in [-1.0, 1.0]:
		var pillar := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.26, ARCH_SPRING, 0.22)
		pillar.mesh = pm
		pillar.material_override = trim
		pillar.position = Vector3(side * (ARCH_R + 0.13), ARCH_SPRING * 0.5, -1.22)
		_vp.add_child(pillar)

	# Floor and the round pedestal.
	var floor_mi := MeshInstance3D.new()
	var fm := PlaneMesh.new()
	fm.size = Vector2(10, 6)
	floor_mi.mesh = fm
	floor_mi.material_override = _mat(COBBLE, COBBLE_N, Vector3(4, 2.4, 1), Color(0.45, 0.4, 0.36))
	floor_mi.position = Vector3(0, 0, 1.0)
	_vp.add_child(floor_mi)
	var ped_mat := _mat(COBBLE, COBBLE_N, Vector3(3, 0.6, 1), Color(0.6, 0.55, 0.5))
	for tier in [[1.05, 0.14, 0.07], [0.92, 0.14, 0.21]]:
		var p := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = tier[0]
		cm.bottom_radius = tier[0] + 0.03
		cm.height = tier[1]
		cm.radial_segments = 48
		p.mesh = cm
		p.material_override = ped_mat
		p.position = Vector3(0, tier[2], 0)
		_vp.add_child(p)

	_turntable = Node3D.new()
	_turntable.position = Vector3(0, 0.28, 0)
	_vp.add_child(_turntable)

	# Light: two warm torches, a soft key from the front, a cool rim from behind.
	for side in [-1.0, 1.0]:
		var torch := OmniLight3D.new()
		torch.light_color = Color(1.0, 0.62, 0.3)
		torch.light_energy = 2.4
		torch.omni_range = 5.5
		torch.omni_attenuation = 1.2
		torch.shadow_enabled = true
		torch.position = Vector3(side * 2.1, 2.5, 0.2)
		_vp.add_child(torch)
		_torches.append(torch)
		var flame := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.07
		sm.height = 0.2
		flame.mesh = sm
		var fmat := StandardMaterial3D.new()
		fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fmat.albedo_color = Color(1.0, 0.7, 0.35)
		fmat.emission_enabled = true
		fmat.emission = Color(1.0, 0.55, 0.2)
		fmat.emission_energy_multiplier = 4.0
		flame.material_override = fmat
		flame.position = torch.position + Vector3(0, -0.05, -0.15)
		_vp.add_child(flame)
	var key := SpotLight3D.new()
	key.light_color = Color(1.0, 0.86, 0.7)
	key.light_energy = 3.2
	key.spot_range = 9.0
	key.spot_angle = 28.0
	key.shadow_enabled = true
	key.position = Vector3(1.2, 3.6, 3.6)
	_vp.add_child(key)
	key.look_at(Vector3(0, 1.1, 0))
	var rim := DirectionalLight3D.new()
	rim.light_color = Color(0.55, 0.62, 0.8)
	rim.light_energy = 0.55
	rim.rotation_degrees = Vector3(-25, 160, 0)
	_vp.add_child(rim)


func _mat(tex: Texture2D, normal: Texture2D, uv: Vector3, tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = tint
	m.normal_enabled = true
	m.normal_texture = normal
	m.roughness = 0.92
	m.uv1_scale = uv
	m.uv1_triplanar = false
	return m


## Dress the model in the player's gear (rebuilds only when something changed).
func show_player(player: Player) -> void:
	if player == null or player.inventory == null:
		return
	var inv := player.inventory
	var main := inv.main_hand()
	var off := inv.off_hand()
	var weapon: WeaponData = main.base.weapon if main and main.base.weapon else null
	var shield: ShieldData = off.base.shield if off and off.base.shield and not (weapon and weapon.two_handed) else null
	var armor := {}
	for s in ["head", "chest", "legs"]:
		var it: ItemInstance = inv.equipped.get(s)
		armor[s] = it.base.model_scene if it and it.base.model_scene else null
	var key := "%d/%d/%s/%s/%s" % [player.net_body, player.net_color, weapon.id if weapon else &"", shield.id if shield else &"", armor]
	if key == _look_key and _model:
		return
	_look_key = key
	if _model == null:
		_model = CharacterModel.new()
		_model.body_tint = Color(0.42, 0.4, 0.37, 1)
		_model.idle_anim = &"Idle"
		var body := MANNEQUIN.instantiate()
		body.name = "Model"
		_model.add_child(body)
		_turntable.add_child(_model)
	_model.clear_hands()
	if weapon and weapon.visual_scene:
		_model.attach_to_hand(weapon.visual_scene.instantiate(), "r")
	if shield and shield.visual_scene:
		_model.attach_to_hand(shield.visual_scene.instantiate(), "l")
	_model.set_body(player.net_body == 1)
	_model.set_outfit(true, player.net_body == 1)
	for s in armor:
		_model.set_armor(s, armor[s])
	_model.set_tint(Classes.LOOK_COLORS[clampi(player.net_color, 0, Classes.LOOK_COLORS.size() - 1)])
	_model.play(&"Idle", 0.2)


func turn(amount: float) -> void:
	_yaw += amount


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	# Right stick turns the character.
	var stick := Input.get_axis("look_left", "look_right")
	if absf(stick) > 0.2:
		_yaw += stick * delta * 2.5
	_turntable.rotation.y = lerp_angle(_turntable.rotation.y, _yaw, minf(1.0, delta * 12.0))
	for i in _torches.size():
		var f := sin(_t * 9.0 + i * 2.1) * 0.12 + sin(_t * 23.0 + i) * 0.08 + sin(_t * 3.1 + i * 4.0) * 0.1
		_torches[i].light_energy = 2.4 * (1.0 + f)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_drag = event.pressed
		accept_event()
	elif event is InputEventMouseMotion and _drag:
		_yaw += event.relative.x * 0.012
		accept_event()
