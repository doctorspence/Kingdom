class_name Hotbar
extends Control
## The 6 ability slots: placeholder color icon, key, cooldown sweep, cost,
## grayed out when locked (level) or unaffordable.

const SLOT := 64.0
const GAP := 8.0
const KEYS := ["1", "2", "3", "4", "5", "6"]

var player: Player
var _hover_slot := -1


func _ready() -> void:
	custom_minimum_size = Vector2(6 * SLOT + 5 * GAP, SLOT + 22)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if player == null or not is_instance_valid(player) or player.stats == null:
		return
	var font := get_theme_default_font()
	var abilities := player.stats.abilities()
	for i in 6:
		var r := Rect2(Vector2(i * (SLOT + GAP), 0), Vector2(SLOT, SLOT))
		draw_rect(r.grow(2), Color(0, 0, 0, 0.75))
		if i >= abilities.size():
			# Slots for the subclass: a quiet hint until a path is chosen.
			if i == 3 and player.stats.subclass == null and player.stats.level >= Subclasses.CHOOSE_LEVEL:
				draw_string(font, r.position + Vector2(4, 28), "Rest at a", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.7, 0.45))
				draw_string(font, r.position + Vector2(4, 44), "shrine to", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.7, 0.45))
				draw_string(font, r.position + Vector2(4, 60), "choose a path", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.7, 0.45))
			continue
		var a := abilities[i]
		var unlocked := player.stats.ability_unlocked(a)
		var reason := player.caster.why_not(a)
		var col := a.icon_color
		if not unlocked:
			col = Color(0.15, 0.15, 0.15)
		elif reason != "" and player.caster.cooldown_left(a) <= 0.0:
			col = col.darkened(0.6)
		draw_rect(r, col)
		# First letters as a placeholder icon.
		var initials := a.display_name.substr(0, 2) if unlocked else "Lv%d" % a.unlock_level
		draw_string(font, r.position + Vector2(6, 38), initials, HORIZONTAL_ALIGNMENT_LEFT, -1, 22,
				Color(1, 1, 1, 0.9) if unlocked else Color(0.6, 0.6, 0.6))
		# Cooldown sweep (darkens from the top) and seconds left.
		var cd := player.caster.cooldown_left(a)
		if cd > 0.0:
			var full := a.cooldown
			var frac := clampf(cd / maxf(full, 0.01), 0.0, 1.0)
			draw_rect(Rect2(r.position, Vector2(SLOT, SLOT * frac)), Color(0, 0, 0, 0.65))
			draw_string(font, r.position + Vector2(18, 58), str(ceili(cd)), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1))
		draw_string(font, r.position + Vector2(4, 14), Prefs.binding_text(StringName("ability_%d" % (i + 1))), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.95, 0.9, 0.8))
		if a.cost > 0.0 and unlocked:
			draw_string(font, r.position + Vector2(SLOT - 22, 14), str(roundi(a.cost)), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.9, 0.8, 0.5))
		draw_string(font, r.position + Vector2(0, SLOT + 16), a.display_name, HORIZONTAL_ALIGNMENT_LEFT, SLOT + GAP, 11, Color(0.85, 0.82, 0.75))
