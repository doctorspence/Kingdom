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

var value := 1.0
var max_value := 1.0
var _chip := 1.0
var _chip_wait := 0.0
var _flash := 0.0
var _flash_len := 0.3
var _flash_color := Color.WHITE


## Briefly outline the bar (Steady: the moment to tap guard, and the stamina coming back).
func flash(color: Color, seconds := 0.3) -> void:
	_flash_color = color
	_flash_len = maxf(seconds, 0.01)
	_flash = _flash_len
	queue_redraw()


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
	draw_rect(r, back_color)
	var ratio := clampf(value / maxf(max_value, 0.001), 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(_chip, 0.0, 1.0), size.y)), chip_color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * ratio, size.y)), fill_color)
	draw_rect(r, border_color, false, 1.0)
	if _flash > 0.0:
		var c := _flash_color
		c.a *= clampf(_flash / _flash_len, 0.0, 1.0)
		draw_rect(r.grow(2.0), c, false, 2.0)
