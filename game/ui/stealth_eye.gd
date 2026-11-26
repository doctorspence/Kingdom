extends Control
## The stealth eye (STEALTH_PLAN.md section 4), drawn in code. Shown while you are
## crouched: closed when nobody has noticed you, half open and grey when someone is
## suspicious, wide open and red when someone is fighting you.
## No class_name on purpose: the HUD loads it with preload.

const SIZE := Vector2(64, 34)
const CLOSED := Color(0.62, 0.6, 0.55)
const GREY := Color(0.78, 0.78, 0.74)
const GREY_IRIS := Color(0.36, 0.36, 0.34)  # darker than the lids: the iris must read against the pale eye white
const RED := Color(0.9, 0.14, 0.1)
const OUTLINE := Color(0.03, 0.03, 0.03, 0.9)

## How open the eye is, 0 (closed) to 1 (wide open). Set by the HUD.
var openness := 0.0
## Someone is fighting you: the iris turns red.
var alert := false

var _shown := 0.0  # openness eased toward the target, so it changes smoothly


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## What the eye shows right now, for checks: "closed", "suspicious" or "fighting".
func look() -> String:
	if alert:
		return "fighting"
	return "suspicious" if openness > 0.15 else "closed"


func _process(delta: float) -> void:
	if not visible:
		return
	_shown = lerpf(_shown, openness, 1.0 - exp(-10.0 * delta))
	queue_redraw()


func _draw() -> void:
	var c := SIZE * 0.5
	var half_w := SIZE.x * 0.5 - 3.0
	var lid_h := SIZE.y * 0.5 - 3.0
	var open := clampf(_shown, 0.0, 1.0)
	var color := RED if alert else (GREY if open > 0.15 else CLOSED)
	# The almond: top and bottom lid curves, pinched at the corners.
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	const STEPS := 16
	for i in STEPS + 1:
		var t := float(i) / STEPS
		var x := lerpf(-half_w, half_w, t)
		var curve := sin(t * PI)  # 0 at the corners, 1 in the middle
		var h := lid_h * curve * lerpf(0.05, 1.0, open)
		top.append(c + Vector2(x, -h))
		bottom.append(c + Vector2(x, h))
	var shape := PackedVector2Array(top)
	var rev := PackedVector2Array(bottom)
	rev.reverse()
	shape.append_array(rev)
	if open > 0.12:
		draw_colored_polygon(shape, Color(0.93, 0.92, 0.86, 0.95))
		# Iris and pupil, clipped by how far the lids are open.
		var r := minf(lid_h * lerpf(0.55, 0.95, open), half_w * 0.5)
		var shown_h := lid_h * lerpf(0.05, 1.0, open)
		var iris := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			var p := Vector2(cos(a) * r, sin(a) * r)
			p.y = clampf(p.y, -shown_h * 0.92, shown_h * 0.92)
			iris.append(c + p)
		draw_colored_polygon(iris, RED if alert else GREY_IRIS)
		draw_circle(c, r * 0.4, Color(0.02, 0.02, 0.02))
		draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.15, Color(1, 1, 1, 0.85))
	else:
		# Closed: a dim lid line with a few lashes.
		draw_polyline(top, OUTLINE, 5.0, true)
		draw_polyline(top, CLOSED, 2.5, true)
		for k in 5:
			var x := lerpf(-half_w * 0.6, half_w * 0.6, k / 4.0)
			draw_line(c + Vector2(x, 1.0), c + Vector2(x * 1.08, 7.0), CLOSED, 1.8, true)
		return
	var edge := top.duplicate()
	edge.append_array(rev)
	edge.append(top[0])
	draw_polyline(edge, OUTLINE, 5.0, true)
	draw_polyline(top, color, 2.5, true)
	draw_polyline(bottom, color, 2.5, true)
