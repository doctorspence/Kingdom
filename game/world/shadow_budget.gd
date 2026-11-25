class_name ShadowBudget
extends Node
## Point and spot lights that cast shadows multiply the geometry drawn (every
## shadowing campfire or torch re-draws everything around it). Only the nearest
## few get shadows; the rest keep their light but not their shadow. Lights that
## never had shadows on (the player's lantern) are left alone.

## How many lights may cast shadows at once.
@export var budget := 3
## Lights farther from the camera than this never cast shadows (meters).
@export var max_distance := 40.0

var _lights: Array[Light3D] = []
var _rescan := 0.0
var _tick := 0.0


func _process(delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 0.25
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	_rescan -= 0.25
	if _rescan <= 0.0:
		_rescan = 5.0
		_find_lights()
	var ranked: Array = []
	for l in _lights:
		if is_instance_valid(l) and l.is_inside_tree():
			ranked.append([l.global_position.distance_to(cam.global_position), l])
	ranked.sort_custom(func(a, b): return a[0] < b[0])
	var used := 0
	for r in ranked:
		var l: Light3D = r[1]
		# Hysteresis: a light that already has shadows keeps them a little longer, so two
		# lights at similar distance don't swap shadows back and forth as you run past.
		var had: bool = l.shadow_enabled
		var on: bool = used < budget and r[0] <= max_distance + (6.0 if had else 0.0)
		if on:
			used += 1
		if l.shadow_enabled != on:
			l.shadow_enabled = on


func _find_lights() -> void:
	for l in get_parent().find_children("*", "Light3D", true, false):
		if l is DirectionalLight3D or _lights.has(l):
			continue
		# Remember lights that were built to cast shadows.
		if (l as Light3D).shadow_enabled or l.has_meta(&"shadow_wanted"):
			l.set_meta(&"shadow_wanted", true)
			_lights.append(l)
