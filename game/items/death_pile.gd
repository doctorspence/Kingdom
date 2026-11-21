extends Node3D
## What you dropped when you died: a pale, glowing heap where you fell.
## Only you and your party can pick it up; whoever does, it all goes back to
## you. It fades after a while (60 minutes by default), and dying again before
## you recover it destroys it for good. No map marker: remember where you died.

var pile_id := 0
var owner_peer := 0
var owner_name := ""
var item_count := 0
var coins := 0
var souls := 0
## Seconds until it's gone (the host keeps the real timer; this is for the label).
var time_left := 3600.0

var _label: Label3D
var _light: OmniLight3D
var _t := 0.0


func _ready() -> void:
	add_to_group(&"interactables")
	add_to_group(&"death_piles")
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.6, 0.65)
	mat.emission_enabled = true
	mat.emission = Color(0.55, 0.75, 0.95)
	mat.emission_energy_multiplier = 0.8
	var rng := RandomNumberGenerator.new()
	rng.seed = pile_id
	for i in 6:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(rng.randf_range(0.2, 0.45), rng.randf_range(0.08, 0.2), rng.randf_range(0.2, 0.45))
		box.material = mat
		mi.mesh = box
		mi.position = Vector3(rng.randf_range(-0.3, 0.3), 0.06 + i * 0.03, rng.randf_range(-0.3, 0.3))
		mi.rotation.y = rng.randf() * TAU
		add_child(mi)
	_light = OmniLight3D.new()
	_light.light_color = Color(0.6, 0.8, 1.0)
	_light.light_energy = 1.6
	_light.omni_range = 4.0
	_light.position.y = 0.8
	add_child(_light)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.pixel_size = 0.004
	_label.font_size = 40
	_label.outline_size = 8
	_label.modulate = Color(0.7, 0.85, 1.0)
	_label.position.y = 1.0
	_label.no_depth_test = true
	add_child(_label)


func _process(delta: float) -> void:
	_t += delta
	time_left = maxf(0.0, time_left - delta)
	_light.light_energy = 1.4 + 0.4 * sin(_t * 2.0)
	var me := get_tree().get_first_node_in_group(&"local_player") as Node3D
	_label.visible = me != null and me.global_position.distance_to(global_position) < 10.0
	_label.text = "%s's belongings  (%d items, %d coins, %d souls)  %d min" % [
			owner_name, item_count, coins, souls, ceili(time_left / 60.0)]


func get_interact_text() -> String:
	if owner_peer == multiplayer.get_unique_id() or owner_name == Net.player_name:
		return "Recover your belongings"
	return "Recover %s's belongings (they go back to %s)" % [owner_name, owner_name]


func interact(_player: Node3D) -> void:
	Loot.request_recover(pile_id)
