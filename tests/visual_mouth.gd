extends Node

func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var scene: Node = load("res://levels/tithelands/tithelands.tscn").instantiate()
	get_tree().root.add_child(scene)
	for i in 60:
		await get_tree().process_frame
	var p := get_tree().get_first_node_in_group(&"player") as Player
	var door: Node3D = scene.get_node("Places/GulletDoor")
	var mouth: Node3D = scene.get_node("Places/GulletMouth")
	print("door ", door.global_position, " mouth ", mouth.global_position)
	p.global_position = door.global_transform * Vector3(-9, 0.5, 9.0)
	p.velocity = Vector3.ZERO
	p.reset_physics_interpolation()
	p.camera_rig.yaw = door.global_rotation.y - 0.7
	for i in 50:
		await get_tree().process_frame
	print("prompt target: ", p.nearest_interactable())
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shots/mouth.png")
	get_tree().quit()
