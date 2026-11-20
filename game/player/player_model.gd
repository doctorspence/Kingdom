class_name PlayerModel
extends Node3D
## The visible character: turns to face where you go and plays animations.
##
## The game logic (player.gd) never touches the model directly, it only calls
## the functions below. So when a detailed character replaces the mannequin,
## only this part changes.

## Animation names in the model. Swap these if a new model names them differently.
const ANIM_IDLE := &"Idle"
const ANIM_WALK := &"Walk"
const ANIM_RUN := &"Jog_Fwd"
const ANIM_SPRINT := &"Sprint"
const ANIM_JUMP_START := &"Jump_Start"
const ANIM_FALL := &"Jump"
const ANIM_LAND := &"Jump_Land"
const ANIM_ROLL := &"Roll"
const ANIM_DEATH := &"Death01"
const ANIM_HIT := &"Hit_Chest"

## Speed (m/s) at which each looping animation's feet match the ground.
@export var walk_anim_speed := 1.6
@export var run_anim_speed := 4.0
@export var sprint_anim_speed := 6.2
## Share of the roll animation that plays during a roll (the rest is the get-up).
@export_range(0.3, 1.0) var roll_anim_portion := 0.8

var _anim: AnimationPlayer
var _meshes: Array[MeshInstance3D] = []
var _iframe_material: StandardMaterial3D
var _current: StringName


func _ready() -> void:
	var players := find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		push_error("PlayerModel: the model has no AnimationPlayer.")
		return
	_anim = players[0]
	for m in find_children("*", "MeshInstance3D", true, false):
		_meshes.append(m)
	_iframe_material = StandardMaterial3D.new()
	_iframe_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_iframe_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_iframe_material.albedo_color = Color(0.4, 0.8, 1.0, 0.35)
	play(ANIM_IDLE, 0.0)


## Turn the body toward a world direction, at most `max_radians` this frame.
func turn_toward(direction: Vector3, max_radians: float) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return
	var target_yaw := atan2(flat.x, flat.z)
	var diff := wrapf(target_yaw - rotation.y, -PI, PI)
	rotation.y += clampf(diff, -max_radians, max_radians)


func face_instantly(direction: Vector3) -> void:
	turn_toward(direction, TAU)


func forward() -> Vector3:
	return global_transform.basis.z.normalized()


## Pick idle / walk / run / sprint from how fast you're actually moving.
func update_locomotion(ground_speed: float, sprinting: bool, walking: bool) -> void:
	if ground_speed < 0.15:
		play(ANIM_IDLE, 0.2)
	elif sprinting:
		play(ANIM_SPRINT, 0.2, clampf(ground_speed / sprint_anim_speed, 0.6, 1.4))
	elif walking or ground_speed < 2.6:
		play(ANIM_WALK, 0.2, clampf(ground_speed / walk_anim_speed, 0.5, 1.6))
	else:
		play(ANIM_RUN, 0.2, clampf(ground_speed / run_anim_speed, 0.6, 1.4))


func play_roll(duration: float) -> void:
	var length := _anim.get_animation(ANIM_ROLL).length if _anim.has_animation(ANIM_ROLL) else 1.0
	play(ANIM_ROLL, 0.06, length * roll_anim_portion / duration, true)


func play_jump() -> void:
	play(ANIM_JUMP_START, 0.08, 1.6, true)


func play_fall() -> void:
	play(ANIM_FALL, 0.25)


func play_land(hard: bool) -> void:
	play(ANIM_LAND, 0.08, 1.0 if hard else 2.2, true)


func play_death() -> void:
	play(ANIM_DEATH, 0.15, 1.0, true)


func play_hit() -> void:
	play(ANIM_HIT, 0.05, 1.0, true)


func is_playing(anim_name: StringName) -> bool:
	return _current == anim_name and _anim.is_playing()


## Light blue see-through tint while invincible (only shown in debug mode).
func show_iframes(active: bool) -> void:
	for m in _meshes:
		m.material_overlay = _iframe_material if active else null


func play(anim_name: StringName, blend := 0.15, speed := 1.0, restart := false) -> void:
	if _anim == null or not _anim.has_animation(anim_name):
		return
	_anim.speed_scale = speed
	if _current == anim_name:
		if restart:
			_anim.seek(0.0, true)
		return
	_current = anim_name
	_anim.play(anim_name, blend)
