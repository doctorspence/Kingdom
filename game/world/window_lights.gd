extends Node
## Lit windows throw a little warm light onto the wall and ground outside at night,
## so a cottage lights whoever stands by it. Finds every window pane (the shared
## glow material) in the zone and puts one small lamp in front of each group.

const GLOW := "res://assets/buildings/materials/glow.tres"
const ENERGY := 2.6
const REACH := 7.5
## Panes closer than this share one light (meters).
const GROUP := 1.8

var _lights: Array[OmniLight3D] = []


func _ready() -> void:
	# Wait until the zone has stood its buildings on the ground.
	get_tree().create_timer(0.5).timeout.connect(_build)


func _process(_delta: float) -> void:
	var on := smoothstep(0.2, 0.9, DayNight.night) * (1.0 - DayNight.cave)
	for l in _lights:
		l.visible = on > 0.01
		l.light_energy = ENERGY * on


func _build() -> void:
	if DisplayServer.get_name() == "headless" or not ResourceLoader.exists(GLOW):
		return
	var glow: Material = load(GLOW)
	var zone := get_parent().get_parent()
	for n in zone.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			if mi.get_active_material(s) != glow:
				continue
			var xf := mi.global_transform
			var middle: Vector3 = xf * mi.get_aabb().get_center()
			var groups: Array = []  # [sum, count]
			for v: Vector3 in mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
				var p: Vector3 = xf * v
				var found := false
				for g: Array in groups:
					if p.distance_to((g[0] as Vector3) / float(g[1])) < GROUP:
						g[0] += p
						g[1] += 1
						found = true
						break
				if not found:
					groups.append([p, 1])
			for g: Array in groups:
				var at: Vector3 = (g[0] as Vector3) / float(g[1])
				var out := Vector3(at.x - middle.x, 0.0, at.z - middle.z).normalized()
				_add_light(at + out * 0.55)


func _add_light(at: Vector3) -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.28)
	l.omni_range = REACH
	l.omni_attenuation = 1.3
	l.light_volumetric_fog_energy = 0.4
	l.distance_fade_enabled = true
	l.distance_fade_begin = 50.0
	l.distance_fade_length = 20.0
	l.visible = false
	add_child(l)
	l.global_position = at
	_lights.append(l)
