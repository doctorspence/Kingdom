class_name SubclassPanel
extends PanelContainer
## "Choose your path" (level 10, opened from a shrine): the three subclasses of
## your class side by side, each with what it is, its weapons, where it leads,
## its abilities, its faction tie and its initiation story. Choosing asks for
## a confirmation, because the choice is meant to feel permanent.
## Works with mouse, keyboard and gamepad (buttons take focus).

signal chosen(subclass_id: StringName)

var player: Player

var _title: Label
var _cards: HBoxContainer
var _confirm: PanelContainer
var _confirm_text: Label
var _pending: SubclassData
var _first_button: Button


func _ready() -> void:
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	box.add_child(_title)
	var note := Label.new()
	note.text = "Read all three before you choose. Your path stays with you; you keep everything you already have."
	note.add_theme_color_override("font_color", Color(0.75, 0.72, 0.66))
	box.add_child(note)
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 12)
	box.add_child(_cards)
	var close := Button.new()
	close.text = "Not yet"
	close.custom_minimum_size = Vector2(0, 40)
	close.pressed.connect(close_panel)
	box.add_child(close)

	# The "are you sure?" box sits on top of everything.
	_confirm = PanelContainer.new()
	_confirm.visible = false
	_confirm.set_anchors_preset(Control.PRESET_CENTER)
	_confirm.offset_left = -230
	_confirm.offset_right = 230
	_confirm.offset_top = -110
	_confirm.offset_bottom = 110
	var cbox := VBoxContainer.new()
	cbox.add_theme_constant_override("separation", 14)
	_confirm.add_child(cbox)
	_confirm_text = Label.new()
	_confirm_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_text.custom_minimum_size = Vector2(420, 110)
	cbox.add_child(_confirm_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	cbox.add_child(row)
	var yes := Button.new()
	yes.name = "Confirm"
	yes.text = "Follow this path"
	yes.custom_minimum_size = Vector2(0, 40)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(_on_confirm)
	row.add_child(yes)
	var no := Button.new()
	no.text = "Go back"
	no.custom_minimum_size = Vector2(0, 40)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(func() -> void:
		_confirm.visible = false
		if _first_button:
			_first_button.grab_focus())
	row.add_child(no)
	add_child(_confirm)


func open(p: Player) -> void:
	player = p
	_confirm.visible = false
	_rebuild()
	visible = true
	if _first_button:
		_first_button.grab_focus()


func close_panel() -> void:
	visible = false
	_confirm.visible = false


func _rebuild() -> void:
	for c in _cards.get_children():
		c.queue_free()
	_first_button = null
	var cls := player.stats.class_data
	_title.text = "Choose your path: %s" % cls.display_name
	for s in Subclasses.for_class(cls.id):
		_cards.add_child(_make_card(s))


func _make_card(s: SubclassData) -> Control:
	var faction := Subclasses.faction(s.faction)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(350, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	v.add_child(_label(s.display_name, 26, Color(0.9, 0.86, 0.72)))
	v.add_child(_label(s.tagline, 15, Color(0.7, 0.68, 0.62)))
	v.add_child(_label("Tied to: %s (lore only)" % faction.display_name, 14, faction.color))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(340, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.custom_minimum_size = Vector2(325, 0)
	scroll.add_child(body)
	body.add_child(_label(s.identity, 15))
	body.add_child(_heading("Weapons"))
	body.add_child(_label(s.weapon_specialties, 15))
	body.add_child(_heading("Where it leads"))
	body.add_child(_label(s.progression_direction, 15))
	body.add_child(_heading("Abilities"))
	if s.abilities.is_empty():
		body.add_child(_label("None built yet.", 15, Color(0.7, 0.6, 0.5)))
	for a in s.abilities:
		body.add_child(_label("Level %d: %s\n%s" % [a.unlock_level, a.display_name, a.description], 14))
	if s.passive_name != "":
		body.add_child(_label("Passive, %s: %s" % [s.passive_name, s.passive_description], 14, Color(0.8, 0.85, 0.9)))
	if s.planned_abilities != "":
		body.add_child(_label("Coming later: %s" % s.planned_abilities, 14, Color(0.7, 0.6, 0.5)))
	body.add_child(_heading("Initiation: %s" % s.initiation_title))
	body.add_child(_label(s.initiation_story, 14, Color(0.78, 0.74, 0.68)))
	var btn := Button.new()
	btn.name = "Choose_%s" % s.id
	btn.custom_minimum_size = Vector2(0, 44)
	var why := player.stats.why_not_subclass(s)
	if why == "":
		btn.text = "Follow the %s" % s.display_name
		btn.pressed.connect(func() -> void: _ask(s))
		if _first_button == null:
			_first_button = btn
	else:
		btn.text = why
		btn.disabled = true
	v.add_child(btn)
	return card


func _ask(s: SubclassData) -> void:
	_pending = s
	_confirm_text.text = "Follow the path of the %s?\n\nThis choice is permanent for now. You keep your class abilities and gain the %s's: %s.\nThe other two paths close to you." % [
			s.display_name, s.display_name, ", ".join(s.abilities.map(func(a: AbilityData) -> String: return a.display_name))]
	_confirm.visible = true
	(_confirm.find_child("Confirm", true, false) as Button).grab_focus()


func _on_confirm() -> void:
	if _pending == null or player == null:
		return
	var why := player.choose_subclass(_pending.id)
	_confirm.visible = false
	if why != "":
		CombatFx.word(player.global_position + Vector3.UP * 2.0, why)
		_rebuild()
		return
	close_panel()
	chosen.emit(_pending.id)


func _label(text: String, size: int, color := Color(0.88, 0.85, 0.78)) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _heading(text: String) -> Label:
	var l := _label(text, 16, Color(0.85, 0.75, 0.5))
	return l
