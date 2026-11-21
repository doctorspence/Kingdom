extends Node3D
## A circle on the ground made by an ability:
##   vigil  - Vigil Lantern: heals friends inside every second
##   snuff  - Snuff smoke: cures bleed/poison/frost buildup of friends inside
##   beacon - Beacon: after a delay, one big heal for everyone inside
##   pyre   - Pyre: friends inside regenerate and take less damage; enemies burn
## Only the caster's copy ("owned") heals and hurts; everyone else's copy is
## just for show.

const TICK := 1.0

var kind := &"vigil"
var radius := 4.0
var duration := 8.0
var power := 0.0
var extra := 0.0
var owned := false
var caster: AbilityCaster

var _age := 0.0
var _tick := 0.0
var _disc: MeshInstance3D
var _light: OmniLight3D


func _ready() -> void:
	var color := Color(1.0, 0.75, 0.35)
	match kind:
		&"snuff":
			color = Color(0.7, 0.72, 0.75)
		&"beacon":
			color = Color(1.0, 0.95, 0.75)
		&"pyre":
			color = Color(1.0, 0.45, 0.15)
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.04 if kind != &"snuff" else 1.6
	mesh.radial_segments = 32
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(color.r, color.g, color.b, 0.22 if kind != &"snuff" else 0.35)
	mat.emission_enabled = kind != &"snuff"
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material = mat
	_disc = MeshInstance3D.new()
	_disc.mesh = mesh
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_disc.position.y = mesh.height * 0.5 + 0.02
	add_child(_disc)
	if kind != &"snuff":
		_light = OmniLight3D.new()
		_light.light_color = color
		_light.light_energy = 1.5
		_light.omni_range = radius + 2.0
		_light.position.y = 1.0
		add_child(_light)


func _physics_process(delta: float) -> void:
	_age += delta
	_tick -= delta
	if kind == &"beacon":
		# Grows brighter until it fires.
		if _light:
			_light.light_energy = 1.0 + 6.0 * (_age / duration)
		if _age >= duration:
			CombatFx.burst_visual(&"beacon_column", global_position, radius, 0.8)
			if owned and is_instance_valid(caster):
				for ally in caster.allies_in(global_position, radius):
					caster.heal_player(ally, power)
			queue_free()
		return
	if _tick <= 0.0:
		_tick = TICK
		if owned and is_instance_valid(caster):
			_apply()
	if _age >= duration:
		queue_free()
	elif _age > duration - 0.5:
		_disc.transparency = (_age - (duration - 0.5)) / 0.5


func _apply() -> void:
	match kind:
		&"vigil":
			for ally in caster.allies_in(global_position, radius):
				caster.heal_player(ally, power * TICK)
		&"snuff":
			for ally in caster.allies_in(global_position, radius):
				ally.cleanse_from(caster.player.player_name)
				if power > 0.0:
					caster.heal_player(ally, power * TICK)
		&"pyre":
			for ally in caster.allies_in(global_position, radius):
				caster.heal_player(ally, power * TICK)
				ally.apply_effect(&"pyre", TICK + 0.2, {"damage_taken": 1.0 - extra, "label": "Sanctuary"})
			for e in caster.enemies_in(global_position, radius):
				caster.strike_enemy(e, power * 0.8 * TICK)
