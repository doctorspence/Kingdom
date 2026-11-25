class_name UiStyle
extends RefCounted
## The look shared by the menu screens: aged-gold frames on dark stone, ivory
## serif text, warm highlights. Everything is drawn in code (no image files),
## so it stays sharp at any resolution.

const IVORY := Color(0.93, 0.89, 0.80)
const IVORY_DIM := Color(0.70, 0.66, 0.58)
const MUTED := Color(0.52, 0.49, 0.44)
const GOLD := Color(0.80, 0.63, 0.34)
const GOLD_BRIGHT := Color(1.0, 0.86, 0.55)
const GOLD_DARK := Color(0.36, 0.25, 0.11)
const PANEL := Color(0.07, 0.062, 0.055, 0.95)
const PANEL_LIGHT := Color(0.12, 0.105, 0.09, 0.95)
const CELL := Color(0.095, 0.085, 0.075)
const CELL_EDGE := Color(0.2, 0.17, 0.13)
const GOOD := Color(0.55, 0.85, 0.45)
const BAD := Color(0.92, 0.38, 0.3)

static var _serif: Font
static var _serif_bold: Font


## An old-style serif from the system (every Windows PC has Palatino or Georgia).
static func serif() -> Font:
	if _serif == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Palatino Linotype", "Book Antiqua", "Palatino", "Georgia", "Times New Roman", "serif"])
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		_serif = f
	return _serif


static func serif_bold() -> Font:
	if _serif_bold == null:
		var f := SystemFont.new()
		f.font_names = (serif() as SystemFont).font_names
		f.font_weight = 700
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		_serif_bold = f
	return _serif_bold


static var _theme: Theme


## A Godot theme in the same look, for the plain panels shown inside the menu book
## (talents, map, the system menu, settings): serif text, dark panels, gold edges.
static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = serif()
	t.default_font_size = 19
	var panel := _box(Color(0.06, 0.055, 0.05, 0.97), GOLD, 2, 22)
	panel.shadow_color = Color(0, 0, 0, 0.55)
	panel.shadow_size = 14
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("normal", "Button", _box(Color(0.12, 0.105, 0.09), GOLD_DARK, 1, 8))
	t.set_stylebox("hover", "Button", _box(Color(0.18, 0.15, 0.11), GOLD, 1, 8))
	t.set_stylebox("pressed", "Button", _box(Color(0.32, 0.25, 0.15), GOLD_BRIGHT, 1, 8))
	t.set_stylebox("disabled", "Button", _box(Color(0.08, 0.075, 0.07), Color(0.2, 0.17, 0.13), 1, 8))
	var focus := _box(Color(0, 0, 0, 0), GOLD_BRIGHT, 2, 8)
	focus.draw_center = false
	t.set_stylebox("focus", "Button", focus)
	for c in ["font_color", "font_focus_color"]:
		t.set_color(c, "Button", IVORY)
	t.set_color("font_hover_color", "Button", GOLD_BRIGHT)
	t.set_color("font_pressed_color", "Button", GOLD_BRIGHT)
	t.set_color("font_disabled_color", "Button", MUTED)
	t.set_color("font_color", "Label", IVORY)
	t.set_color("default_color", "RichTextLabel", IVORY)
	_theme = t
	return t


static func _box(bg: Color, edge: Color, width: int, margin: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(width)
	s.set_content_margin_all(margin)
	s.set_corner_radius_all(2)
	return s


## Text with a soft dark shadow. align: HORIZONTAL_ALIGNMENT_*; width -1 = no box.
static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, color := IVORY,
		align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, font: Font = null) -> void:
	var f := font if font else serif()
	ci.draw_string(f, pos + Vector2(1, 2), s, align, width, size, Color(0, 0, 0, 0.75 * color.a))
	ci.draw_string(f, pos, s, align, width, size, color)


static func text_width(s: String, size: int, font: Font = null) -> float:
	return (font if font else serif()).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## A horizontal gold rule that fades out at both ends.
static func rule(ci: CanvasItem, from: Vector2, to: Vector2, color := GOLD, width := 1.5) -> void:
	var steps := 24
	for i in steps:
		var t0 := float(i) / steps
		var t1 := float(i + 1) / steps
		var a := sin(PI * (t0 + t1) * 0.5)
		ci.draw_line(from.lerp(to, t0), from.lerp(to, t1), Color(color, color.a * a), width)


static func diamond(ci: CanvasItem, c: Vector2, r: float, color := GOLD) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), color)


## The ornate frame: dark panel, double gold border, filigree corners, and an
## optional crest on top.
static func frame(ci: CanvasItem, r: Rect2, crest := true, fill := PANEL) -> void:
	# soft outer shadow
	for i in 4:
		ci.draw_rect(r.grow(4 + i * 3), Color(0, 0, 0, 0.12), false, 3.0)
	ci.draw_rect(r, fill)
	# faint inner light from the top
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.35)), Color(1, 0.85, 0.6, 0.025))
	ci.draw_rect(r, Color(0, 0, 0, 0.9), false, 5.0)
	ci.draw_rect(r.grow(-2), GOLD_DARK, false, 3.0)
	ci.draw_rect(r.grow(-2.5), GOLD, false, 1.6)
	ci.draw_rect(r.grow(-8), Color(0, 0, 0, 0.6), false, 2.0)
	ci.draw_rect(r.grow(-9), Color(GOLD, 0.55), false, 1.0)
	for corner in 4:
		var flip := Vector2(1 if corner % 2 == 0 else -1, 1 if corner < 2 else -1)
		var p := Vector2(r.position.x if flip.x > 0 else r.end.x, r.position.y if flip.y > 0 else r.end.y)
		_corner(ci, p, flip)
	if crest:
		_crest(ci, Vector2(r.get_center().x, r.position.y + 1))
		_crest(ci, Vector2(r.get_center().x, r.end.y - 1), true)


static func _corner(ci: CanvasItem, p: Vector2, f: Vector2) -> void:
	# an L bracket with a curl and a stud
	var dark := Color(0, 0, 0, 0.8)
	var pts := PackedVector2Array([p + Vector2(-3, 30) * f, p + Vector2(-3, -3) * f, p + Vector2(30, -3) * f])
	ci.draw_polyline(pts, dark, 7.0)
	ci.draw_polyline(pts, GOLD, 3.0)
	ci.draw_polyline(pts, GOLD_BRIGHT, 1.0)
	# curls
	_curl(ci, p + Vector2(30, -3) * f, Vector2(1, 0) * f, f)
	_curl(ci, p + Vector2(-3, 30) * f, Vector2(0, 1) * f, Vector2(-f.x, f.y) * Vector2(-1, 1))
	diamond(ci, p + Vector2(7, 7) * f, 6.5, dark)
	diamond(ci, p + Vector2(7, 7) * f, 4.5, GOLD_BRIGHT)


static func _curl(ci: CanvasItem, start: Vector2, dir: Vector2, f: Vector2) -> void:
	var side := Vector2(-dir.y, dir.x)
	if side.dot(f) < 0.0:
		side = -side
	var pts := PackedVector2Array()
	for i in 13:
		var t := float(i) / 12.0
		var ang := t * PI * 1.5
		var rad := 7.0 * (1.0 - t * 0.45)
		pts.append(start + dir * (sin(ang) * rad + t * 6.0) + side * (1.0 - cos(ang)) * rad)
	ci.draw_polyline(pts, Color(0, 0, 0, 0.7), 4.0)
	ci.draw_polyline(pts, GOLD, 1.8)


static func _crest(ci: CanvasItem, c: Vector2, below := false) -> void:
	var s := -1.0 if below else 1.0
	var dark := Color(0, 0, 0, 0.85)
	for side in [-1.0, 1.0]:
		var pts := PackedVector2Array()
		for i in 15:
			var t := float(i) / 14.0
			pts.append(c + Vector2(side * (10.0 + t * 46.0), s * (-sin(t * PI) * 8.0 + 1.0)))
		ci.draw_polyline(pts, dark, 5.0)
		ci.draw_polyline(pts, GOLD, 2.0)
	diamond(ci, c + Vector2(0, -s * 2), 11, dark)
	diamond(ci, c + Vector2(0, -s * 2), 8.5, GOLD)
	diamond(ci, c + Vector2(0, -s * 2), 4, GOLD_BRIGHT)


## A recessed cell: dark well with a thin bronze edge.
static func well(ci: CanvasItem, r: Rect2, tint := CELL) -> void:
	ci.draw_rect(r, tint)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), Color(0, 0, 0, 0.45))
	ci.draw_rect(Rect2(r.position, Vector2(3, r.size.y)), Color(0, 0, 0, 0.3))
	ci.draw_rect(r, CELL_EDGE, false, 1.0)


## An equipment slot: a well with a gold-trimmed edge.
static func slot(ci: CanvasItem, r: Rect2, lit := false) -> void:
	ci.draw_rect(r.grow(3), Color(0, 0, 0, 0.7))
	well(ci, r, Color(0.085, 0.078, 0.07))
	ci.draw_rect(r.grow(1), GOLD_BRIGHT if lit else Color(GOLD, 0.75), false, 2.0 if lit else 1.5)
	if lit:
		for i in 3:
			ci.draw_rect(r.grow(3 + i * 2), Color(GOLD_BRIGHT, 0.18 - i * 0.05), false, 2.0)


## An item icon fitted into a rect. Icons are drawn on the diagonal (blade to the
## top right), so long items turn their icon to run along the rect.
static func item_icon(ci: CanvasItem, tex: Texture2D, r: Rect2, modulate := Color.WHITE) -> void:
	if tex == null:
		return
	var aspect := r.size.y / maxf(r.size.x, 1.0)
	var c := r.get_center()
	if aspect >= 1.5 or aspect <= 0.67:
		var long := maxf(r.size.x, r.size.y)
		var short := minf(r.size.x, r.size.y)
		var s := minf(long * 1.02 / sqrt(2.0), short * 2.4)
		var ang := -PI * 0.25 if aspect >= 1.5 else PI * 0.25
		ci.draw_set_transform(c, ang, Vector2.ONE)
		ci.draw_texture_rect(tex, Rect2(-s * 0.5, -s * 0.5, s, s), false, modulate)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var s2 := minf(r.size.x, r.size.y) * 1.08
		ci.draw_texture_rect(tex, Rect2(c - Vector2(s2, s2) * 0.5, Vector2(s2, s2)), false, modulate)


## A button prompt badge ("LB", "Q", "A"...). Returns its width.
static func badge(ci: CanvasItem, pos: Vector2, label: String, size := 15, round := false) -> float:
	var w := maxf(text_width(label, size, serif_bold()) + 14.0, 26.0)
	var h := size + 10.0
	var r := Rect2(pos, Vector2(w, h))
	if round:
		r = Rect2(pos, Vector2(h, h))
		w = h
		ci.draw_circle(r.get_center(), h * 0.5 + 1, Color(0, 0, 0, 0.6))
		ci.draw_circle(r.get_center(), h * 0.5, Color(0.12, 0.11, 0.1))
		ci.draw_arc(r.get_center(), h * 0.5 - 1, 0, TAU, 24, IVORY_DIM, 1.5, true)
	else:
		ci.draw_rect(r.grow(1), Color(0, 0, 0, 0.6))
		ci.draw_rect(r, Color(0.12, 0.11, 0.1))
		ci.draw_rect(r, IVORY_DIM, false, 1.5)
	var font := serif_bold()
	var fs := size if label.length() <= 2 else size - 3
	ci.draw_string(font, Vector2(r.position.x, r.position.y + h * 0.5 + fs * 0.36), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, IVORY)
	return w


## A small stack of coins.
static func coin_icon(ci: CanvasItem, c: Vector2, s := 1.0) -> void:
	for i in 4:
		var p := c + Vector2(-5 + (i % 2) * 2, 8 - i * 5) * s
		ci.draw_set_transform(p, 0.0, Vector2(1.0, 0.45))
		ci.draw_circle(Vector2.ZERO, 9 * s, Color(0.35, 0.24, 0.08))
		ci.draw_circle(Vector2(0, -2) * s, 9 * s, Color(0.86, 0.66, 0.28))
		ci.draw_arc(Vector2(0, -2) * s, 6 * s, 0, TAU, 16, Color(1, 0.88, 0.5), 1.2)
	ci.draw_set_transform(c + Vector2(8, 6) * s, 0.0, Vector2(1.0, 0.45))
	ci.draw_circle(Vector2.ZERO, 8 * s, Color(0.35, 0.24, 0.08))
	ci.draw_circle(Vector2(0, -2) * s, 8 * s, Color(0.78, 0.58, 0.24))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A blue-white wisp for souls.
static func soul_icon(ci: CanvasItem, c: Vector2, s := 1.0) -> void:
	ci.draw_circle(c, 11 * s, Color(0.5, 0.7, 1.0, 0.12))
	ci.draw_circle(c, 7 * s, Color(0.6, 0.8, 1.0, 0.3))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -12) * s, c + Vector2(5, 0) * s, c + Vector2(0, 6) * s, c + Vector2(-5, 0) * s]), Color(0.82, 0.92, 1.0))


## A weight (a squat iron kettlebell).
static func weight_icon(ci: CanvasItem, c: Vector2, s := 1.0) -> void:
	ci.draw_arc(c + Vector2(0, -6) * s, 5 * s, PI, TAU, 12, IVORY_DIM, 2.5 * s)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -5) * s, c + Vector2(7, -5) * s, c + Vector2(10, 9) * s, c + Vector2(-10, 9) * s]), IVORY_DIM)
	ci.draw_rect(Rect2(c + Vector2(-10, 7) * s, Vector2(20, 2.5) * s), Color(0, 0, 0, 0.3))


## Stat glyphs for the character panel, drawn small and gold.
static func glyph(ci: CanvasItem, kind: String, c: Vector2, col := GOLD) -> void:
	match kind:
		"strength":  # a fist / hammer
			ci.draw_rect(Rect2(c + Vector2(-7, -7), Vector2(14, 7)), col)
			ci.draw_rect(Rect2(c + Vector2(-2, 0), Vector2(4, 9)), col)
		"agility":  # a feather-arrow
			ci.draw_line(c + Vector2(-8, 8), c + Vector2(8, -8), col, 2.0)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(8, -8), c + Vector2(1, -6), c + Vector2(6, -1)]), col)
			ci.draw_line(c + Vector2(-8, 8), c + Vector2(-8, 2), col, 2.0)
			ci.draw_line(c + Vector2(-8, 8), c + Vector2(-2, 8), col, 2.0)
		"intellect":  # an open eye
			var pts := PackedVector2Array()
			for i in 17:
				var t := float(i) / 16.0 * TAU
				pts.append(c + Vector2(cos(t) * 9, sin(t) * 5))
			ci.draw_polyline(pts, col, 1.8)
			ci.draw_circle(c, 3, col)
		"vitality":  # a heart
			ci.draw_circle(c + Vector2(-3.5, -2), 4.5, col)
			ci.draw_circle(c + Vector2(3.5, -2), 4.5, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -1), c + Vector2(8, -1), c + Vector2(0, 8)]), col)
		"attack":  # a sword
			ci.draw_line(c + Vector2(-7, 7), c + Vector2(7, -7), col, 2.5)
			ci.draw_line(c + Vector2(-7, 1), c + Vector2(-1, 7), col, 2.0)
		"defense", "armor":  # a shield
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -8), c + Vector2(7, -8), c + Vector2(7, 0), c + Vector2(0, 9), c + Vector2(-7, 0)]), col)
			ci.draw_line(c + Vector2(0, -6), c + Vector2(0, 6), Color(0, 0, 0, 0.5), 1.5)
		"power":  # a star
			var star := PackedVector2Array()
			for i in 10:
				var a := -PI * 0.5 + i * PI / 5.0
				var rr := 9.0 if i % 2 == 0 else 3.5
				star.append(c + Vector2(cos(a), sin(a)) * rr)
			ci.draw_colored_polygon(star, col)
		"crit":  # a burst
			for i in 8:
				var a2 := i * PI / 4.0
				ci.draw_line(c + Vector2(cos(a2), sin(a2)) * 3, c + Vector2(cos(a2), sin(a2)) * (9 if i % 2 == 0 else 6), col, 2.0)
		"health":
			glyph(ci, "vitality", c, Color(0.85, 0.25, 0.2))
		"stamina":  # a swirl
			ci.draw_arc(c, 7, 0.3, TAU - 0.4, 20, Color(0.45, 0.8, 0.35), 2.5)
			ci.draw_arc(c, 3, 0.0, PI * 1.5, 10, Color(0.45, 0.8, 0.35), 2.0)
		"resource":  # a drop
			ci.draw_circle(c + Vector2(0, 2.5), 5.5, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -9), c + Vector2(5.2, 1), c + Vector2(-5.2, 1)]), col)
		_:
			diamond(ci, c, 5, col)
