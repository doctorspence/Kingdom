extends Node3D
## Turns the node about its local x axis (a mill wheel).

@export var speed := -0.35  # radians per second


func _process(delta: float) -> void:
	rotate_object_local(Vector3.RIGHT, speed * delta)
