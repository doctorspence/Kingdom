extends Node3D
## An item lying on the ground: a small glowing box, a light beam colored by
## rarity (Uncommon and up), and its name when you're close. Interact to pick
## it up. A won roll reserves it for the winner.

var drop_id := 0
var item: ItemInstance
var rolling := false
var owner_peer := 0
var owner_name := ""

var _label: Label3D
var _bob := 0.0


func _ready() -> void:
	add_to_group(&"interactables")
	var color := item.color()
	var box := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.35, 0.2, 0.35)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = item.base.icon_color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	mesh.material = mat
	box.mesh = mesh
	box.position.y = 0.15
	add_child(box)
	if item.rarity >= ItemInstance.Rarity.UNCOMMON:
		var beam := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.06
		cyl.bottom_radius = 0.12
		cyl.height = 3.0 + item.rarity
		var bmat := StandardMaterial3D.new()
		bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bmat.albedo_color = Color(color.r, color.g, color.b, 0.35)
		bmat.emission_enabled = true
		bmat.emission = color
		bmat.emission_energy_multiplier = 2.0
		cyl.material = bmat
		beam.mesh = cyl
		beam.position.y = cyl.height * 0.5
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(beam)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 0.6 + 0.4 * item.rarity
	light.omni_range = 2.5
	light.position.y = 0.5
	add_child(light)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.pixel_size = 0.004
	_label.font_size = 40
	_label.outline_size = 8
	_label.modulate = color
	_label.position.y = 0.7
	_label.no_depth_test = true
	add_child(_label)


func _process(delta: float) -> void:
	_bob += delta
	get_child(0).position.y = 0.15 + sin(_bob * 2.0) * 0.04
	var me := get_tree().get_first_node_in_group(&"local_player") as Node3D
	_label.visible = me != null and me.global_position.distance_to(global_position) < 8.0
	_label.text = item.display_name() + ("  (rolling...)" if rolling else ("  (%s's)" % owner_name if owner_peer != 0 else ""))


func get_interact_text() -> String:
	if rolling:
		return "%s: waiting for the roll" % item.display_name()
	if owner_peer != 0 and owner_peer != multiplayer.get_unique_id():
		return "%s: won by %s" % [item.display_name(), owner_name]
	return "Pick up %s" % item.display_name()


func interact(player: Node3D) -> void:
	if rolling or (owner_peer != 0 and owner_peer != multiplayer.get_unique_id()):
		return
	Loot.request_pickup(drop_id, player as Player)
