class_name CharacterModel
extends Node3D
## The visible body of a character (player or enemy): turns to face where it
## goes, plays animations, holds weapons, and shows effect tints.
##
## Game logic never touches the model's insides, only these functions. When a
## detailed character replaces the mannequin, only this part changes.

## Extra animation libraries on the same skeleton, merged in at start.
const EXTRA_LIBRARIES := {
	&"ual2": "res://assets/characters/mannequin/UAL2_Standard.glb",
}
## Animations that should loop but don't in the source files.
const FORCE_LOOP := [&"Sword_Idle"]

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
const ANIM_STAGGER := &"ual2/Hit_Knockback"
const ANIM_BLOCK := &"ual2/Idle_Shield"
const ANIM_GUARD_BREAK := &"ual2/Idle_Shield_Break"
const ANIM_DRINK := &"ual2/Consume"

static var _library_cache := {}

## Speed (m/s) at which each looping animation's feet match the ground.
@export var walk_anim_speed := 1.6
@export var run_anim_speed := 4.0
@export var sprint_anim_speed := 6.2
## Share of the roll animation that plays during a roll (the rest is the get-up).
@export_range(0.3, 1.0) var roll_anim_portion := 0.8
## Recolor the whole body (alpha 0 = keep the model's own colors).
@export var body_tint := Color(0, 0, 0, 0)
## Idle animation (enemies can use a different one).
@export var idle_anim := ANIM_IDLE

var _anim: AnimationPlayer
var _skeleton: Skeleton3D
var _meshes: Array[MeshInstance3D] = []
var _current: StringName
var _overlay: StandardMaterial3D
var _overlay_kind := ""


func _ready() -> void:
	var players := find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		push_error("CharacterModel: the model has no AnimationPlayer.")
		return
	_anim = players[0]
	_skeleton = find_children("*", "Skeleton3D", true, false)[0]
	for m in find_children("*", "MeshInstance3D", true, false):
		_meshes.append(m)
	_merge_extra_libraries()
	for anim_name in FORCE_LOOP:
		if _anim.has_animation(anim_name):
			_anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	if body_tint.a > 0.0:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(body_tint.r, body_tint.g, body_tint.b)
		mat.roughness = 0.85
		mat.metallic = 0.2
		for m in _meshes:
			m.material_override = mat
	_overlay = StandardMaterial3D.new()
	_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	play(idle_anim, 0.0)


func _merge_extra_libraries() -> void:
	for lib_name: StringName in EXTRA_LIBRARIES:
		if _anim.has_animation_library(lib_name):
			continue
		if not _library_cache.has(lib_name):
			var scene: Node = (load(EXTRA_LIBRARIES[lib_name]) as PackedScene).instantiate()
			var source: AnimationPlayer = scene.find_children("*", "AnimationPlayer", true, false)[0]
			_library_cache[lib_name] = source.get_animation_library(&"")
			scene.free()
		_anim.add_animation_library(lib_name, _library_cache[lib_name])


# --- Facing -------------------------------------------------------------------

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


# --- Animation ----------------------------------------------------------------

## Pick idle / walk / run / sprint from how fast the character is actually moving.
func update_locomotion(ground_speed: float, sprinting: bool, walking: bool) -> void:
	if ground_speed < 0.15:
		play(idle_anim, 0.2)
	elif sprinting:
		play(ANIM_SPRINT, 0.2, clampf(ground_speed / sprint_anim_speed, 0.6, 1.4))
	elif walking or ground_speed < 2.6:
		play(ANIM_WALK, 0.2, clampf(ground_speed / walk_anim_speed, 0.5, 1.6))
	else:
		play(ANIM_RUN, 0.2, clampf(ground_speed / run_anim_speed, 0.6, 1.4))


func play_roll(duration: float) -> void:
	play(ANIM_ROLL, 0.06, anim_length(ANIM_ROLL) * roll_anim_portion / duration, true)


func play_jump() -> void:
	play(ANIM_JUMP_START, 0.08, 1.6, true)


func play_fall() -> void:
	play(ANIM_FALL, 0.25)


func play_land(hard: bool) -> void:
	play(ANIM_LAND, 0.08, 1.0 if hard else 2.2, true)


func play_death() -> void:
	play(ANIM_DEATH, 0.15, 1.0, true)


## Fit an animation into `duration` seconds.
func play_fitted(anim_name: StringName, duration: float, blend := 0.08) -> void:
	play(anim_name, blend, anim_length(anim_name) / maxf(duration, 0.05), true)


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


func set_speed(speed: float) -> void:
	if _anim:
		_anim.speed_scale = speed


var _held_speed := -1.0

## Freeze the animation in place (hit-stop), then resume at the same speed.
func hold(frozen: bool) -> void:
	if _anim == null:
		return
	if frozen and _held_speed < 0.0:
		_held_speed = _anim.speed_scale
		_anim.speed_scale = 0.0
	elif not frozen and _held_speed >= 0.0:
		_anim.speed_scale = _held_speed
		_held_speed = -1.0


func seek(time: float) -> void:
	if _anim:
		_anim.seek(time, true)


func anim_length(anim_name: StringName) -> float:
	return _anim.get_animation(anim_name).length if _anim and _anim.has_animation(anim_name) else 1.0


func current_anim() -> StringName:
	return _current


# --- Weapons ------------------------------------------------------------------

## Put a weapon (or shield) in a hand. Weapons are built with the grip at their
## origin and the blade pointing up (+Y). `side` is "r" or "l".
func attach_to_hand(item: Node3D, side: String) -> void:
	var holder := BoneAttachment3D.new()
	holder.bone_name = "hand_" + side
	_skeleton.add_child(holder)
	holder.add_child(item)
	# In the hand bone, fingers point along +Y and the knuckles along +Z, so a
	# held blade points along +Z. Rotate the item's +Y onto +Z.
	item.position = Vector3(0.0, 0.08, 0.0)
	item.rotation_degrees = Vector3(90.0, 0.0, 0.0)


# --- Tints --------------------------------------------------------------------

## Show a colored see-through tint over the whole body. kind = "" turns it off.
func set_overlay(kind: String, color := Color.WHITE) -> void:
	if kind == _overlay_kind and kind != "":
		_overlay.albedo_color = color
		return
	_overlay_kind = kind
	_overlay.albedo_color = color
	for m in _meshes:
		m.material_overlay = _overlay if kind != "" else null


func overlay_kind() -> String:
	return _overlay_kind
