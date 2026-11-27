class_name CharacterAudio
extends Node
## Makes the sounds for one character (a player or an enemy) from what its
## animation is doing: swings, rolls, hurt and death voices, footsteps, casts.
##
## Because every machine plays each character's animations (remote players and
## enemies copy the owner's), this is what lets friends hear each other without
## any extra network messages.
##
## Sounds for hits and blocks come from CombatFx (blood and sparks), and sounds
## for abilities from their effects (bolts, thrown shields, bursts).

## "human" (players), "raider" (knights, raiders, acolytes), "beast" (hounds) or "boss".
var voice := &"human"

var model: CharacterModel
var _step_clock := 0.0
var _dead := false


func _ready() -> void:
	model = get_parent() as CharacterModel
	if model:
		model.anim_started.connect(_on_anim)


func _process(delta: float) -> void:
	if model == null or _dead or not model.is_inside_tree():
		return
	var anim := model.current_anim()
	var interval := 0.0
	match anim:
		CharacterModel.ANIM_WALK:
			interval = 0.62
		CharacterModel.ANIM_RUN:
			interval = 0.4
		CharacterModel.ANIM_SPRINT:
			interval = 0.31
	if interval <= 0.0 or voice == &"beast":
		_step_clock = interval * 0.5  # the first step comes quickly
		return
	_step_clock += delta * maxf(model.get_speed(), 0.0)
	if _step_clock >= interval:
		_step_clock = 0.0
		Audio.sfx(&"footstep_heavy" if voice == &"boss" else &"footstep", model.global_position + Vector3.UP * 0.1)


func _at() -> Vector3:
	return model.global_position + Vector3.UP * 1.2


func _on_anim(anim: StringName) -> void:
	var name := String(anim)
	# Calling for help: a boss roars (its second phase). Knights used to blow a horn, which
	# sounded like a honk, so now they raise the alarm silently (the camp raid horn is separate).
	if name == "ual2/Idle_Rail_Call":
		if voice == &"boss":
			Audio.sfx(&"roar", _at())
		return
	if name.ends_with("_Rec") or "Block" in name or "Idle" in name:
		return
	_dead = false
	match anim:
		CharacterModel.ANIM_ROLL:
			Audio.sfx(&"roll", _at())
		CharacterModel.ANIM_JUMP_START:
			Audio.sfx(&"jump", _at())
		CharacterModel.ANIM_LAND:
			Audio.sfx(&"land", _at())
		CharacterModel.ANIM_DRINK:
			Audio.sfx(&"drink", _at())
		CharacterModel.ANIM_DEATH:
			_dead = true
			Audio.sfx(&"die_%s" % voice, _at())
		CharacterModel.ANIM_HIT, CharacterModel.ANIM_STAGGER, CharacterModel.ANIM_GUARD_BREAK:
			Audio.sfx(&"hurt_%s" % voice, _at())
		&"ual2/Shield_OneShot":
			Audio.sfx(&"shield_bash", _at())
		&"ual2/Sword_Heavy_Combo", &"Sword_Attack":
			_swing_later(&"swing_heavy", 0.25)
		&"cut/Jump_Slam":  # sprinting and jumping heavy slams
			_swing_later(&"swing_heavy", 0.22)
		&"ual2/Sword_Dash":
			Audio.sfx(&"swing_dash", _at())
		&"Spell_Simple_Shoot", &"Spell_Simple_Enter", &"ual2/OverhandThrow":
			Audio.sfx(&"cast_simple", _at())
		&"howl":
			Audio.sfx(&"howl", _at())
		&"bite", &"lunge":
			Audio.sfx(&"attack_beast", _at())
		_:
			if name.begins_with("ual2/Sword_") or name.begins_with("ual2/Melee") or name.begins_with("Punch"):
				if voice == &"boss":
					Audio.sfx(&"attack_boss", _at())
				elif voice == &"raider":
					Audio.sfx(&"attack_raider", _at())
				_swing_later(&"swing_light" if voice != &"boss" else &"swing_heavy", 0.12)


func _swing_later(cue: StringName, delay: float) -> void:
	var at := _at()
	get_tree().create_timer(delay).timeout.connect(func() -> void: Audio.sfx(cue, at))
