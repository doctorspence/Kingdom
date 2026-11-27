class_name ResourceBar
extends Control
## A thin bar (health, stamina...). When it drops, a pale "chip" shows how much
## you just lost, then catches up after a moment.

@export var fill_color := Color(0.55, 0.08, 0.07)
@export var chip_color := Color(0.85, 0.75, 0.5)
@export var back_color := Color(0.05, 0.05, 0.05, 0.75)
@export var border_color := Color(0.0, 0.0, 0.0, 0.9)
## Pixels of bar width per point of maximum (bars grow as max grows).
@export var pixels_per_point := 3.0
@export var chip_delay := 0.6
@export var chip_speed := 0.8

@export_group("Exhausted (stamina bar)")
## Colour of the blink and glow while exhausted.
@export var exhausted_color := Color(0.4, 1.0, 0.35)
## Blinks per second, and how many pixels the glow spreads round the bar at its brightest.
@export var exhausted_blink_rate := 2.2
@export var exhausted_glow_px := 6.0

var value := 1.0
var max_value := 1.0
var _chip := 1.0
var _chip_wait := 0.0
var _flash := 0.0
var _flash_len := 0.3
var _flash_color := Color.WHITE
var _exhausted := false
var _exhausted_t := 0.0


## Briefly outline the bar (Steady: the moment to tap guard, and the stamina coming back).
func flash(color: Color, seconds := 0.3) -> void:
	_flash_color = color
	_flash_len = maxf(seconds, 0.01)
	_flash = _flash_len
	queue_redraw()


## Exhausted: the bar blinks and a green glow pulses round it, until switched off.
## Only redraws every frame while it's on.
func set_exhausted(on: bool) -> void:
	if on == _exhausted:
		return
	_exhausted = on
	_exhausted_t = 0.0
	queue_redraw()


func is_exhausted() -> bool:
	return _exhausted


func set_values(current: float, maximum: float) -> void:
	if current < value:
		_chip_wait = chip_delay
	else:
		_chip = maxf(_chip, current / maxf(maximum, 0.001))
	value = current
	max_value = maximum
	if pixels_per_point > 0.0:
		custom_minimum_size.x = maximum * pixels_per_point
		size.x = custom_minimum_size.x
	queue_redraw()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		queue_redraw()
	if _exhausted:
		_exhausted_t += delta
		queue_redraw()
	var ratio := value / maxf(max_value, 0.001)
	if _chip > ratio:
		if _chip_wait > 0.0:
			_chip_wait -= delta
		else:
			_chip = maxf(ratio, _chip - chip_speed * delta)
		queue_redraw()
	else:
		_chip = ratio


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if _exhausted:
		_draw_exhausted_glow(r)
	draw_rect(r, back_color)
	var ratio := clampf(value / maxf(max_value, 0.001), 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(_chip, 0.0, 1.0), size.y)), chip_color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * ratio, size.y)), fill_color)
	draw_rect(r, border_color, false, 1.0)
	if _exhausted:
		# Blink: a bright green outline (and a faint tint inside, kept dim so the bar
		# still reads as empty) lights up and fades, over and over.
		var blink := 0.5 + 0.5 * cos(_exhausted_t * TAU * exhausted_blink_rate)
		var tint := exhausted_color
		tint.a = 0.06 + 0.16 * blink
		draw_rect(r, tint)
		var edge := exhausted_color
		edge.a = 0.25 + 0.75 * blink
		draw_rect(r.grow(1.0), edge, false, 2.0)
	if _flash > 0.0:
		var c := _flash_color
		c.a *= clampf(_flash / _flash_len, 0.0, 1.0)
		draw_rect(r.grow(2.0), c, false, 2.0)


## A soft glow: a few rings round the bar, fading outward, breathing in and out.
func _draw_exhausted_glow(r: Rect2) -> void:
	var pulse := 0.5 + 0.5 * cos(_exhausted_t * TAU * exhausted_blink_rate)
	var spread := exhausted_glow_px * (0.55 + 0.45 * pulse)
	const RINGS := 4
	for i in RINGS:
		var k := float(RINGS - i) / RINGS  # 1 = outermost ring
		var c := exhausted_color
		c.a = (0.12 + 0.38 * pulse) * (1.0 - k * 0.75)
		draw_rect(r.grow(spread * k), c)
