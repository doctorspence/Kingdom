class_name TrainingDummy
extends AnimatableBody3D
## A straw training dummy. Lock on to it, hit it, read the numbers.
## It never dies. Optionally walks back and forth.

## How far it walks to each side (meters). 0 = stands still.
@export var patrol_distance := 0.0
@export var patrol_speed := 1.5
## Height of the lock-on marker.
@export var lock_height := 1.3

# Damage readout (sandbox debug aid). All numbers (start).
const READOUT_WINDOW := 5.0       # rolling DPS window (s)
const READOUT_SPAN_FLOOR := 1.0   # DPS divides by at least this (s)
const READOUT_RESET := 3.0        # a pause this long ends the string (s)
const READOUT_HIDE_AFTER := 20.0  # label hides this long after the last hit (s)
const READOUT_REFRESH := 0.1      # label refresh while a string is active (s)
const READOUT_HEIGHT := 3.0       # label height above the dummy's origin (m)
const READOUT_COLOR := Color(0.95, 0.95, 0.92)
const READOUT_FROZEN_COLOR := Color(0.75, 0.75, 0.72)

var _start: Vector3
var _time := 0.0
var _wobble := 0.0
var _wobble_vel := 0.0
var _wobble_axis := Vector3.RIGHT

var readout_label: Label3D
var _readout_clock := 0.0
var _readout_tick := 0.0
var _str_total := 0.0
var _str_hits := 0
var _str_crits := 0
var _str_start := 0.0
var _last_hit := 0.0
var _win_times := PackedFloat64Array()
var _win_amounts := PackedFloat64Array()


func _ready() -> void:
	add_to_group(&"lock_targets")
	add_to_group(&"hittable")
	_start = global_position
	readout_label = Label3D.new()
	readout_label.name = "Readout"
	readout_label.position = Vector3.UP * READOUT_HEIGHT
	readout_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	readout_label.no_depth_test = true
	readout_label.render_priority = 9
	readout_label.font_size = 28
	readout_label.outline_size = 8
	readout_label.outline_modulate = Color(0, 0, 0, 0.85)
	readout_label.pixel_size = 0.006
	readout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	readout_label.visible = false
	add_child(readout_label)


func get_lock_point() -> Vector3:
	return global_position + Vector3.UP * lock_height


func can_be_locked() -> bool:
	return true


func hit_radius() -> float:
	return 0.35


func receive_hit(hit: HitInfo) -> HitInfo.Result:
	var top := global_position + Vector3.UP * 1.9
	CombatFx.damage_number(top, hit.damage, CombatFx.NumberKind.CRIT if hit.is_crit else CombatFx.NumberKind.NORMAL)
	CombatFx.sparks(global_position + Vector3.UP * 1.2, hit.origin - global_position)
	var away := global_position - hit.origin
	away.y = 0.0
	_wobble_axis = away.normalized().cross(Vector3.DOWN).normalized() if away.length() > 0.01 else Vector3.RIGHT
	_wobble_vel += 4.0 + hit.damage * 0.05
	if hit.damage > 0.0:
		record_hit(hit.damage, _readout_clock, hit.is_crit)
		refresh_readout()
	return HitInfo.Result.HIT


## The dummy's own clock (advances with physics time, stops when paused).
func clock() -> float:
	return _readout_clock


## Tests only: set the readout clock so real receive_hit calls get an exact time.
func set_clock(t: float) -> void:
	_readout_clock = t


## Count one landed hit at time `at`. Zero or negative damage is ignored.
func record_hit(amount: float, at: float, is_crit := false) -> void:
	if amount <= 0.0:
		return
	if _str_hits == 0 or at - _last_hit >= READOUT_RESET:
		_str_total = 0.0
		_str_hits = 0
		_str_crits = 0
		_win_times.clear()
		_win_amounts.clear()
		_str_start = at
	_str_total += amount
	_str_hits += 1
	if is_crit:
		_str_crits += 1
	_last_hit = at
	_win_times.append(at)
	_win_amounts.append(amount)
	while _win_times.size() > 0 and _win_times[0] <= at - READOUT_WINDOW:
		_win_times.remove_at(0)
		_win_amounts.remove_at(0)


func string_active(at: float) -> bool:
	return _str_hits > 0 and at - _last_hit < READOUT_RESET


## Kept after the string ends (frozen result); reset when the next string starts.
func string_total(_at: float) -> float:
	return _str_total


func string_hits(_at: float) -> int:
	return _str_hits


func string_crits(_at: float) -> int:
	return _str_crits


func dps(at: float) -> float:
	if _str_hits == 0:
		return 0.0
	if string_active(at):
		var sum := 0.0
		for i in _win_times.size():
			if _win_times[i] > at - READOUT_WINDOW:
				sum += _win_amounts[i]
		return sum / clampf(at - _str_start, READOUT_SPAN_FLOOR, READOUT_WINDOW)
	return _str_total / maxf(_last_hit - _str_start, READOUT_SPAN_FLOOR)


func readout_visible(at: float) -> bool:
	return _str_hits > 0 and at - _last_hit < READOUT_HIDE_AFTER and CombatFx.show_damage_numbers


func readout_text(at: float) -> String:
	var hits := string_hits(at)
	var crits := string_crits(at)
	return "DPS %.1f\nString %d (%d %s, %d %s)" % [dps(at), roundi(_str_total), hits, "hit" if hits == 1 else "hits", crits, "crit" if crits == 1 else "crits"]


func readout_color(at: float) -> Color:
	return READOUT_COLOR if string_active(at) else READOUT_FROZEN_COLOR


## Applies the readout state to the label.
func update_readout(at: float) -> void:
	if readout_label == null:
		return
	var show := readout_visible(at)
	readout_label.visible = show
	if not show:
		return
	readout_label.modulate = readout_color(at)
	var t := readout_text(at)
	if readout_label.text != t:
		readout_label.text = t


func window_size() -> int:
	return _win_times.size()


func refresh_readout() -> void:
	update_readout(_readout_clock)


func _physics_process(delta: float) -> void:
	_readout_clock += delta
	if _str_hits > 0 and _readout_clock - _last_hit < READOUT_HIDE_AFTER + 0.5:
		_readout_tick += delta
		if _readout_tick >= READOUT_REFRESH:
			_readout_tick = 0.0
			refresh_readout()
	# Springy wobble when hit.
	_wobble_vel += (-_wobble * 60.0 - _wobble_vel * 6.0) * delta
	_wobble += _wobble_vel * delta
	var tilt := Basis(_wobble_axis, clampf(_wobble, -0.5, 0.5)) if absf(_wobble) > 0.0005 else Basis.IDENTITY
	for c in get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).basis = tilt
	if patrol_distance > 0.0:
		_time += delta
		var omega := patrol_speed / patrol_distance
		global_position = _start + Vector3.RIGHT * sin(_time * omega) * patrol_distance
