class_name AudioSettings
extends VBoxContainer
## Five volume sliders (Master, Music, Effects, Ambience, Interface).
## Used by the main menu and the Esc menu. Changes apply at once and are saved.

const NAMES := {
	&"Master": "Master", &"Music": "Music", &"Effects": "Effects",
	&"Ambience": "Ambience", &"Interface": "Interface",
}


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	for g in Audio.GROUPS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var label := Label.new()
		label.text = NAMES[g]
		label.custom_minimum_size = Vector2(90, 0)
		row.add_child(label)
		var slider := HSlider.new()
		slider.name = "Slider_%s" % g
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = Audio.get_volume(g)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size = Vector2(180, 24)
		slider.value_changed.connect(func(v: float) -> void: Audio.set_volume(g, v))
		slider.drag_ended.connect(func(_changed: bool) -> void: Audio.save())
		slider.focus_exited.connect(Audio.save)
		row.add_child(slider)
		add_child(row)
