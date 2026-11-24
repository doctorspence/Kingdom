class_name CaveDoor
extends Node3D
## A way between the surface and the cave below (the Gullet is built under the
## quarry). Interact to go through to the matching door.

@export var door_name := "the Gullet"
@export var verb := "Descend into"
## The door on the other side (NodePath from this node).
@export var other: NodePath
## Where you stand when you arrive here (relative to this door).
@export var arrive_offset := Vector3(0, 0, 2)


## A glowing pillar of light and a lamp, so the entrance can be seen from afar (and shows on the map).
@export var beacon := false

## A door nobody can use any more (the way is now a walkable tunnel); kept so old checks and the map still find it.
@export var disabled := false


func _ready() -> void:
	if not disabled:
		add_to_group(&"interactables")
	if beacon:
		_build_beacon()


func _build_beacon() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.18
	mesh.bottom_radius = 0.35
	mesh.height = 22.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.62, 0.25, 0.55)
	mat.no_depth_test = false
	mesh.material = mat
	var pillar := MeshInstance3D.new()
	pillar.mesh = mesh
	pillar.position = Vector3(0, 11.0, 0)
	pillar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pillar)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.65, 0.3)
	lamp.light_energy = 3.5
	lamp.omni_range = 20.0
	lamp.position = Vector3(0, 3.0, 0.5)
	add_child(lamp)


func get_interact_text() -> String:
	return "%s %s" % [verb, door_name]


## Height doesn't matter for reaching a door (the cave mouth sits on a steep slope).
func interact_position(player: Node3D) -> Vector3:
	return Vector3(global_position.x, player.global_position.y, global_position.z)


## Where you stand when you arrive through this door (on the ground, if it's on the surface).
func arrival_point() -> Vector3:
	var p := global_transform * arrive_offset
	var zone := get_tree().get_first_node_in_group(&"zone_terrain") as ZoneTerrain
	if zone and global_position.y > 0.0:
		p.y = zone.height_at(p.x, p.z) + 0.1
	return p


func interact(player: Node3D) -> void:
	var dest := get_node_or_null(other) as CaveDoor
	if dest == null:
		return
	player.global_position = dest.arrival_point() + Vector3.UP * 0.4
	player.velocity = Vector3.ZERO
	if player.has_method(&"face_toward"):
		player.call(&"face_toward", -dest.global_transform.basis.z)
