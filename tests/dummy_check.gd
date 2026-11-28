extends Node
## Automated check for the training dummy damage readout (STU-003, H-001/H-001a/H-002).
## Hits are fed with exact fake times (record_hit / set_clock), so no real waiting is needed.
## Each case uses a fresh dummy. Case numbers match the acceptance criteria in H-001.
##
## Run (from the project folder):
##   Godot_console.exe --headless --path . --script res://tests/run.gd -- dummy_check

const ACTIVE := Color(0.95, 0.95, 0.92)
const FROZEN := Color(0.75, 0.75, 0.72)
const TOL := 0.05

var failures := 0
var scene: Node
var dummy_scene: PackedScene


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	scene = load("res://levels/sandbox/combat_test.tscn").instantiate()
	get_tree().root.add_child(scene)
	await _frames(20)
	dummy_scene = load("res://game/combat/training_dummy.tscn")
	var shown_before: bool = CombatFx.show_damage_numbers
	# The setting comes from the saved preferences (the owner may have numbers off): force it on.
	CombatFx.show_damage_numbers = true

	# Constants are the spec values.
	_check_true("constants: window 5.0, floor 1.0, reset 3.0, hide 20.0",
			is_equal_approx(TrainingDummy.READOUT_WINDOW, 5.0) and is_equal_approx(TrainingDummy.READOUT_SPAN_FLOOR, 1.0)
			and is_equal_approx(TrainingDummy.READOUT_RESET, 3.0) and is_equal_approx(TrainingDummy.READOUT_HIDE_AFTER, 20.0))
	_check_true("constants: colours are the spec colours",
			TrainingDummy.READOUT_COLOR.is_equal_approx(ACTIVE) and TrainingDummy.READOUT_FROZEN_COLOR.is_equal_approx(FROZEN))

	# 1. Hidden before any hit.
	var d := _make()
	await _frames(3)
	var label := d.get_node_or_null("Readout") as Label3D
	_check_true("1. a Label3D named Readout exists", label != null)
	_check_true("1. hidden before any hit (readout_visible)", not d.readout_visible(0.0))
	_check_true("1. hidden before any hit (label.visible)", label != null and not label.visible)
	d.update_readout(0.0)
	_check_true("1. still hidden after update_readout", label != null and not label.visible)
	_check_true("1. label sits %.1f m above the dummy" % TrainingDummy.READOUT_HEIGHT,
			label != null and is_equal_approx(label.position.y, TrainingDummy.READOUT_HEIGHT))
	d.queue_free()

	# 2. Three hits of 10 at 0, 0.5, 1.0.
	d = _make()
	for t in [0.0, 0.5, 1.0]:
		d.record_hit(10.0, t)
	_check_true("2. total 30", is_equal_approx(d.string_total(1.0), 30.0))
	_check_true("2. 3 hits, 0 crits", d.string_hits(1.0) == 3 and d.string_crits(1.0) == 0)
	_check_near("2. DPS 30.0 at t=1.0 (span floored to 1.0)", d.dps(1.0), 30.0)
	_check_true("2. line 2 exactly 'String 30 (3 hits, 0 crits)'", _line(d, 1.0, 1) == "String 30 (3 hits, 0 crits)")

	# 3. Same hits read at t=2.0.
	_check_near("3. DPS 15.0 at t=2.0", d.dps(2.0), 15.0)
	_check_true("3. still active", d.string_active(2.0))
	d.update_readout(2.0)
	_check_true("3. white (active) colour", _lbl(d).modulate.is_equal_approx(ACTIVE) and _lbl(d).visible)
	d.queue_free()

	# 4. One hit of 25.
	d = _make()
	d.record_hit(25.0, 0.0)
	_check_true("4. line 1 exactly 'DPS 25.0'", _line(d, 0.0, 0) == "DPS 25.0")
	_check_true("4. line 2 exactly 'String 25 (1 hit, 0 crits)'", _line(d, 0.0, 1) == "String 25 (1 hit, 0 crits)")
	_check_true("4. full text joined with a newline", d.readout_text(0.0) == "DPS 25.0\nString 25 (1 hit, 0 crits)")
	d.queue_free()

	# 5. Crit 40 + normal 10.
	d = _make()
	d.record_hit(40.0, 0.0, true)
	d.record_hit(10.0, 0.2)
	_check_true("5. total 50, 2 hits, 1 crit", is_equal_approx(d.string_total(0.2), 50.0) and d.string_hits(0.2) == 2 and d.string_crits(0.2) == 1)
	_check_true("5. line 2 'String 50 (2 hits, 1 crit)'", _line(d, 0.2, 1) == "String 50 (2 hits, 1 crit)")
	d.queue_free()

	# 6. Zero and negative damage; through receive_hit with set_clock.
	d = _make()
	d.set_clock(0.0)
	d.receive_hit(_hit(0.0))
	d.set_clock(0.1)
	d.receive_hit(_hit(-5.0))
	_check_true("6. zero/negative damage: counts stay 0", d.string_hits(0.1) == 0 and d.string_crits(0.1) == 0 and is_zero_approx(d.string_total(0.1)))
	_check_true("6. zero/negative damage: still hidden", not d.readout_visible(0.1) and not _lbl(d).visible)
	d.set_clock(1.0)
	d.receive_hit(_hit(10.0))
	_check_true("6. real hit shows the readout", _lbl(d).visible and d.string_hits(1.0) == 1)
	d.set_clock(3.9)
	d.receive_hit(_hit(0.0))
	_check_true("6. a 0-damage hit at 2.9 s after the real hit does not extend the string", d.string_hits(3.9) == 1)
	_check_true("6. string still ends 3.0 s after the real hit (active at 3.9, ended at 4.0)", d.string_active(3.9) and not d.string_active(4.0))
	d.queue_free()

	# 7. Seven hits of 10 at t=0..6, rolling window.
	d = _make()
	for t in 7:
		d.record_hit(10.0, float(t))
	_check_true("7. total 70, 7 hits", is_equal_approx(d.string_total(6.0), 70.0) and d.string_hits(6.0) == 7)
	_check_near("7. DPS 10.0 at t=6.0 (window 50 / span 5.0)", d.dps(6.0), 10.0)
	d.queue_free()

	# 8. String end and freeze.
	d = _make()
	d.record_hit(10.0, 0.0)
	d.record_hit(10.0, 1.0)
	_check_true("8. active at 3.9", d.string_active(3.9))
	d.update_readout(3.9)
	_check_true("8. white at 3.9", _lbl(d).modulate.is_equal_approx(ACTIVE))
	_check_true("8. ended at 4.0", not d.string_active(4.0))
	d.update_readout(4.0)
	_check_true("8. gray (frozen) at 4.0 and still visible", _lbl(d).modulate.is_equal_approx(FROZEN) and _lbl(d).visible)
	_check_true("8. line 1 'DPS 20.0' at 4.0", _line(d, 4.0, 0) == "DPS 20.0")
	_check_true("8. line 2 'String 20 (2 hits, 0 crits)'", _line(d, 4.0, 1) == "String 20 (2 hits, 0 crits)")
	_check_true("8. frozen values are kept later (t=10)", _line(d, 10.0, 0) == "DPS 20.0" and _line(d, 10.0, 1) == "String 20 (2 hits, 0 crits)")

	# 10. New string after criterion 8 ended (same dummy).
	d.record_hit(15.0, 6.0)
	_check_true("10. new string: 'String 15 (1 hit, 0 crits)'", _line(d, 6.0, 1) == "String 15 (1 hit, 0 crits)")
	_check_near("10. DPS 15.0", d.dps(6.0), 15.0)
	d.update_readout(6.0)
	_check_true("10. active colour again", _lbl(d).modulate.is_equal_approx(ACTIVE))
	d.queue_free()

	# 9. Average over a longer string.
	d = _make()
	for t in [0.0, 2.0, 4.0]:
		d.record_hit(10.0, t)
	_check_true("9. active at 6.9, ended at 7.0", d.string_active(6.9) and not d.string_active(7.0))
	_check_true("9. frozen line 1 'DPS 7.5'", _line(d, 7.0, 0) == "DPS 7.5")
	d.queue_free()

	# 11. Hide after 20 s.
	d = _make()
	d.record_hit(10.0, 0.0)
	d.update_readout(19.9)
	_check_true("11. visible (frozen) at 19.9", d.readout_visible(19.9) and _lbl(d).visible and _lbl(d).modulate.is_equal_approx(FROZEN))
	d.update_readout(20.0)
	_check_true("11. hidden at 20.0", not d.readout_visible(20.0) and not _lbl(d).visible)
	d.record_hit(30.0, 25.0)
	d.update_readout(25.0)
	_check_true("11. next hit shows it again as a new string", _lbl(d).visible and _line(d, 25.0, 1) == "String 30 (1 hit, 0 crits)")
	d.queue_free()

	# 12. show_damage_numbers off.
	d = _make()
	CombatFx.show_damage_numbers = false
	d.record_hit(10.0, 0.0)
	d.record_hit(10.0, 0.5)
	d.update_readout(0.5)
	_check_true("12. hidden while show_damage_numbers is off", not _lbl(d).visible and not d.readout_visible(0.5))
	_check_true("12. values still tracked while hidden", d.string_hits(0.5) == 2 and is_equal_approx(d.string_total(0.5), 20.0))
	CombatFx.show_damage_numbers = true
	d.update_readout(0.5)
	_check_true("12. back on: shows the current values", _lbl(d).visible and _line(d, 0.5, 1) == "String 20 (2 hits, 0 crits)" and _lbl(d).text == d.readout_text(0.5))
	d.queue_free()

	# 13. Two dummies are independent.
	var a := _make()
	var b := _make()
	a.record_hit(10.0, 0.0)
	a.update_readout(0.0)
	b.update_readout(0.0)
	_check_true("13. hitting A leaves B hidden and empty", _lbl(a).visible and not _lbl(b).visible and b.string_hits(0.0) == 0)
	a.queue_free()
	b.queue_free()

	# 14. Rounding.
	d = _make()
	d.record_hit(10.4, 0.0)
	d.record_hit(10.4, 0.5)
	_check_true("14. line 2 starts 'String 21'", _line(d, 0.5, 1).begins_with("String 21 ("))
	_check_near("14. DPS uses the unrounded sum (20.8 / 1.0)", d.dps(0.5), 20.8)
	_check_true("14. line 1 'DPS 20.8'", _line(d, 0.5, 0) == "DPS 20.8")
	d.queue_free()

	# 15. Existing behaviour: HIT result, wobble, label stays upright; real receive_hit path.
	d = _make()
	d.set_clock(1.0)
	var res: HitInfo.Result = d.receive_hit(_hit(25.0, true))
	_check_true("15. receive_hit still returns HIT", res == HitInfo.Result.HIT)
	_check_true("15. receive_hit starts the readout (1 hit, 1 crit, 25)", d.string_hits(1.0) == 1 and d.string_crits(1.0) == 1 and is_equal_approx(d.string_total(1.0), 25.0))
	_check_true("15. label visible and text matches readout_text right after the hit", _lbl(d).visible and _lbl(d).text == d.readout_text(1.0))
	_check_true("15. dummy still wobbles", absf(d._wobble_vel) > 0.0)
	await _frames(5)
	_check_true("15. label stays upright (no tilt) while it wobbles", _lbl(d).basis.is_equal_approx(Basis.IDENTITY))
	d.queue_free()

	# 15b. Clock follows physics time; refresh_readout and the refresh loop update the label by themselves.
	d = _make()
	var c0: float = d.clock()
	await _frames(10)
	_check_true("15. clock advances with physics time", d.clock() > c0)
	d.set_clock(5.0)
	d.receive_hit(_hit(10.0))
	await _seconds(0.3)
	_check_true("15. the label refreshes on its own as time passes", _lbl(d).visible and _lbl(d).text == d.readout_text(d.clock()))
	d.queue_free()

	# 16. Memory: 200 hits over 100 s.
	d = _make()
	var max_win := 0
	for i in 200:
		var t := i * 0.5
		d.record_hit(10.0, t)
		max_win = maxi(max_win, d.window_size())
	_check_true("16. 200 hits over 100 s: total 2000, 200 hits kept as plain numbers", is_equal_approx(d.string_total(99.5), 2000.0) and d.string_hits(99.5) == 200)
	_check_true("16. window holds no hits older than 5.0 s (size %d, max %d)" % [d.window_size(), max_win], d.window_size() <= 10 and max_win <= 11)
	d.queue_free()

	CombatFx.show_damage_numbers = shown_before
	print("\n%s: %d problem(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _make() -> TrainingDummy:
	var d := dummy_scene.instantiate() as TrainingDummy
	scene.add_child(d)
	d.global_position = Vector3(0, 0, -40)  # away from the player and the practice dummies
	return d


func _lbl(d: TrainingDummy) -> Label3D:
	return d.get_node("Readout") as Label3D


func _line(d: TrainingDummy, at: float, idx: int) -> String:
	var parts := d.readout_text(at).split("\n")
	return parts[idx] if parts.size() > idx else ""


func _hit(damage: float, crit := false) -> HitInfo:
	var h := HitInfo.new()
	h.damage = damage
	h.is_crit = crit
	h.origin = Vector3(0, 1, -38)
	return h


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await _frames(ceili(s * Engine.physics_ticks_per_second))


func _check_near(label: String, got: float, want: float) -> void:
	_check_true("%s (got %.2f)" % [label, got], absf(got - want) <= TOL)


func _check_true(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", label])
	if not ok:
		failures += 1
