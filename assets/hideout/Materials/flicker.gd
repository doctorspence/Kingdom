extends OmniLight3D
## Torch / fire flicker that survives being saved in a scene (no runtime tween needed).

@export var base_energy := 3.0
var _t := 0.0


func _ready() -> void:
	_t = randf() * 20.0


func _process(delta: float) -> void:
	_t += delta
	light_energy = base_energy * (1.0 + 0.14 * sin(_t * 21.0) + 0.09 * sin(_t * 13.7 + 1.0) + 0.05 * sin(_t * 37.0 + 2.0))
