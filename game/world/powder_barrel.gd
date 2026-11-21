class_name PowderBarrel
extends StaticBody3D
## A barrel of blasting powder (GULLET_DESIGN.md section 3). Hit it with a swing or
## an arrow: it hisses for a moment, then blows up, hurting every enemy and every
## player nearby (and setting off other barrels). Comes back when someone rests.
## Learnable, never random: same fuse, same blast, every time.

@export var radius := 4.5
## Damage at the center, to enemies and to players (falls to 40% at the edge).
@export var enemy_damage := 110.0
@export var player_damage := 55.0
@export var poise_damage := 80.0
@export var fuse_time := 0.45

var exploded := false
var _lit := false
var _fuse := 0.0
var _body: MeshInstance3D
var _glow: OmniLight3D
var _shape: CollisionShape3D
var _hitter: Node3D


func _ready() -> void:
	collision_layer = 1
	add_to_group(&"hittable")
	add_to_group(&"respawn_on_rest")
	add_to_group(&"powder_barrels")
	_build()


func _build() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.42
	mesh.bottom_radius = 0.42
	mesh.height = 1.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.22, 0.12)
	mat.roughness = 0.9
	mesh.material = mat
	_body = MeshInstance3D.new()
	_body.mesh = mesh
	_body.position.y = 0.5
	add_child(_body)
	for y in [0.2, 0.8]:
		var band := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.44
		bm.bottom_radius = 0.44
		bm.height = 0.07
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = Color(0.1, 0.09, 0.09)
		bm.material = bmat
		band.mesh = bm
		band.position.y = y
		add_child(band)
	var label := Label3D.new()
	label.text = "POWDER"
	label.font_size = 40
	label.pixel_size = 0.004
	label.position = Vector3(0, 0.55, 0.43)
	label.modulate = Color(0.9, 0.8, 0.6)
	label.outline_size = 6
	add_child(label)
	_shape = CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.44
	cyl.height = 1.0
	_shape.shape = cyl
	_shape.position.y = 0.5
	add_child(_shape)
	_glow = OmniLight3D.new()
	_glow.position.y = 0.9
	_glow.light_color = Color(1.0, 0.35, 0.1)
	_glow.light_energy = 0.0
	_glow.omni_range = 5.0
	add_child(_glow)


# --- What the rest of the game calls ---------------------------------------------------------

func hit_radius() -> float:
	return 0.45


func can_be_locked() -> bool:
	return false


## A swing (or the player's arrow) reached it.
func receive_hit(hit: HitInfo) -> HitInfo.Result:
	if exploded or _lit:
		return HitInfo.Result.IGNORED
	_light_up(hit.attacker)
	return HitInfo.Result.HIT


## An enemy archer's arrow reached it.
func arrow_triggered(_shooter: Node3D) -> void:
	if not exploded and not _lit:
		_light_up(null)


func _light_up(by: Node3D) -> void:
	if Net.is_online() and not multiplayer.is_server():
		_net_light.rpc_id(1)
		_start_fuse()  # show it right away on our screen; the host tells everyone else
	else:
		_start_fuse()
		if Net.is_online():
			_net_lit.rpc()


@rpc("any_peer", "call_remote", "reliable")
func _net_light() -> void:
	if not multiplayer.is_server() or exploded or _lit:
		return
	_start_fuse()
	_net_lit.rpc()


@rpc("authority", "call_remote", "reliable")
func _net_lit() -> void:
	if not exploded and not _lit:
		_start_fuse()


func _start_fuse() -> void:
	_lit = true
	_fuse = fuse_time
	Audio.sfx(&"fire", global_position, -6.0)


func _physics_process(delta: float) -> void:
	if not _lit or exploded:
		return
	_fuse -= delta
	# Flashing, faster as it gets close.
	var rate := lerpf(10.0, 30.0, 1.0 - clampf(_fuse / fuse_time, 0.0, 1.0))
	var on := int(Time.get_ticks_msec() * 0.001 * rate) % 2 == 0
	_glow.light_energy = 3.0 if on else 0.4
	((_body.mesh as CylinderMesh).material as StandardMaterial3D).emission_enabled = on
	((_body.mesh as CylinderMesh).material as StandardMaterial3D).emission = Color(0.8, 0.2, 0.05)
	if _fuse <= 0.0:
		_explode()


func _explode() -> void:
	exploded = true
	_lit = false
	var center := global_position + Vector3.UP * 0.5
	Audio.sfx(&"roar", center, 2.0)
	_flash(center)
	_body.visible = false
	for c in get_children():
		if c is Label3D or (c is MeshInstance3D and c != _body):
			c.visible = false
	_shape.set_deferred(&"disabled", true)
	_glow.light_energy = 0.0
	# Everyone's own player takes the blast on their own machine.
	for n in get_tree().get_nodes_in_group(&"player"):
		var p := n as Player
		if p == null or not p.is_multiplayer_authority() or p.is_dead():
			continue
		var d := p.global_position.distance_to(global_position)
		if d <= radius:
			var hit := _blast_hit(center, player_damage, d)
			p.receive_hit(hit)
			p.camera_rig.add_shake(0.5 * (1.0 - d / radius))
	if not (not Net.is_online() or multiplayer.is_server()):
		return
	# The host hurts enemies and sets off neighbors.
	for n in get_tree().get_nodes_in_group(&"enemies"):
		var e := n as Enemy
		if e == null or e.state == Enemy.State.DEAD:
			continue
		var d := e.global_position.distance_to(global_position)
		if d <= radius + e.hit_radius():
			e.receive_hit(_blast_hit(center, enemy_damage, d))
	for n in get_tree().get_nodes_in_group(&"powder_barrels"):
		var b := n as PowderBarrel
		if b and b != self and not b.exploded and not b._lit and b.global_position.distance_to(global_position) <= radius:
			b._start_fuse()
			if Net.is_online():
				b._net_lit.rpc()


func _blast_hit(center: Vector3, damage: float, dist: float) -> HitInfo:
	var h := HitInfo.new()
	var falloff := lerpf(1.0, 0.4, clampf(dist / radius, 0.0, 1.0))
	h.damage = damage * falloff
	h.poise_damage = poise_damage * falloff
	h.origin = center
	h.parryable = false
	h.unblockable = true
	h.hit_stop = 0.1
	h.attacker_level = 5
	return h


func _flash(center: Vector3) -> void:
	var sphere := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.65, 0.2, 0.8)
	sm.material = mat
	sphere.mesh = sm
	sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(sphere)
	sphere.global_position = center
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.25)
	light.light_energy = 8.0
	light.omni_range = radius * 2.5
	sphere.add_child(light)
	var tween := sphere.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sphere, "scale", Vector3.ONE * radius * 1.6, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tween.tween_property(light, "light_energy", 0.0, 0.4)
	tween.chain().tween_callback(sphere.queue_free)
	CombatFx.sparks(center, Vector3.UP, true)


## Someone rested at a shrine: a new barrel stands there.
func reset_from_rest() -> void:
	if Net.is_online():
		_net_reset.rpc()
	_reset()


@rpc("authority", "call_remote", "reliable")
func _net_reset() -> void:
	_reset()


func _reset() -> void:
	exploded = false
	_lit = false
	_body.visible = true
	for c in get_children():
		if c is Label3D or c is MeshInstance3D:
			c.visible = true
	_shape.set_deferred(&"disabled", false)
	_glow.light_energy = 0.0
	((_body.mesh as CylinderMesh).material as StandardMaterial3D).emission_enabled = false
