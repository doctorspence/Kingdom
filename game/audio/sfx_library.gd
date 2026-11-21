class_name SfxLibrary
extends RefCounted
## Every game sound as a named "cue": a short list of files (one is picked at
## random each time), the volume group it plays on, a base volume and a pitch
## range. Gameplay code only says Audio.sfx(&"hit_flesh", where); to change what
## a cue sounds like, edit it here. All files are CC0 (see assets/CREDITS.md).

const SFX := "res://assets/audio/sfx/"

## cue -> {files, bus, db, pitch (min, max)}
static var _cues := {}


static func cue(name: StringName) -> Dictionary:
	if _cues.is_empty():
		_build()
	return _cues.get(name, {})


static func has_cue(name: StringName) -> bool:
	if _cues.is_empty():
		_build()
	return _cues.has(name)


static func names() -> Array:
	if _cues.is_empty():
		_build()
	return _cues.keys()


static func _nums(folder: String, prefix: String, from: int, to: int, ext := ".ogg", pad := 2, sep := "") -> Array:
	var out := []
	for i in range(from, to + 1):
		out.append("%s%s/%s%s%s%s" % [SFX, folder, prefix, sep, str(i).pad_zeros(pad), ext])
	return out


static func _add(name: StringName, files: Array, bus := &"Effects", db := 0.0, pitch_min := 0.94, pitch_max := 1.06) -> void:
	_cues[name] = {"files": files, "bus": bus, "db": db, "pitch": Vector2(pitch_min, pitch_max)}


static func _build() -> void:
	var swish_light := _nums("swishes", "swish-", 1, 6, ".wav", 1)
	var swish_heavy := _nums("swishes", "swish-", 7, 13, ".wav", 1)
	var flesh := _nums("hits", "bfh1_hit_", 1, 13)
	var blades := _nums("rpg80", "blade_", 1, 3)
	var clash := _nums("swords", "sword_clash.", 1, 10, ".ogg", 1)
	var metal := _nums("hits", "bfh1_metal_hit_", 1, 6)
	var cloth := _nums("kenney_rpg", "cloth", 1, 4, ".ogg", 1)
	var steps := _nums("kenney_rpg", "footstep", 0, 9)
	var wood := _nums("hits", "bfh1_wood_hit_", 1, 3)
	var stones := _nums("rpg80", "stones_", 1, 4)
	var roar_big := _nums("creatures", "roar_", 1, 3)
	var spells := _nums("rpg80", "spell_", 1, 2)
	var fire := _nums("rpg80", "spell_fire_", 1, 7)

	# --- Weapons ---
	_add(&"swing_light", swish_light, &"Effects", -7.0, 0.9, 1.1)
	_add(&"swing_heavy", swish_heavy, &"Effects", -3.0, 0.75, 0.9)
	_add(&"swing_dash", swish_heavy, &"Effects", -4.0, 1.0, 1.2)
	_add(&"hit_flesh", flesh + blades, &"Effects", -4.0)
	_add(&"hit_crit", _nums("swords", "sword.", 1, 10, ".ogg", 1) + flesh, &"Effects", 0.0, 0.85, 0.95)
	_add(&"clang_block", metal + clash, &"Effects", -3.0)
	_add(&"clang_parry", clash + _nums("rpg80", "metal_", 1, 3), &"Effects", 2.0, 1.05, 1.2)
	_add(&"shield_bash", wood + stones, &"Effects", 0.0, 0.8, 0.95)
	_add(&"shield_clack", metal, &"Effects", -2.0, 1.1, 1.25)

	# --- Moving ---
	_add(&"footstep", steps, &"Effects", -11.0, 0.9, 1.1)
	_add(&"footstep_heavy", stones, &"Effects", -4.0, 0.6, 0.8)
	_add(&"roll", cloth + [SFX + "kenney_rpg/clothBelt.ogg", SFX + "kenney_rpg/clothBelt2.ogg"], &"Effects", -3.0)
	_add(&"jump", cloth, &"Effects", -9.0, 1.0, 1.2)
	_add(&"land", [SFX + "kenney_rpg/dropLeather.ogg"] + _nums("hits", "bfh1_rock_hit_", 1, 1), &"Effects", -4.0, 0.8, 1.0)
	_add(&"drink", [SFX + "kenney_rpg/handleSmallLeather.ogg", SFX + "kenney_rpg/handleSmallLeather2.ogg", SFX + "kenney_rpg/metalClick.ogg"], &"Effects", -3.0)

	# --- Voices (a person) ---
	_add(&"hurt_human", _nums("rpg80", "creature_hurt_", 1, 2), &"Effects", -3.0, 0.85, 1.05)
	_add(&"die_human", [SFX + "rpg80/creature_die_01.ogg"], &"Effects", 0.0, 0.8, 0.95)
	# --- Voices (a beast) ---
	_add(&"hurt_beast", _nums("creatures", "hurt_", 1, 5), &"Effects", -2.0)
	_add(&"die_beast", [SFX + "creatures/scream_01.ogg", SFX + "creatures/scream_02.ogg"], &"Effects", 0.0, 0.8, 0.95)
	_add(&"attack_beast", _nums("creatures", "barking_", 1, 2) + _nums("creatures", "monster_", 1, 3), &"Effects", -2.0)
	_add(&"howl", [SFX + "creatures/howl.ogg"], &"Effects", 2.0, 0.95, 1.05)
	# --- Voices (a boss) ---
	_add(&"hurt_boss", roar_big, &"Effects", -6.0, 0.6, 0.75)
	_add(&"die_boss", roar_big, &"Effects", 2.0, 0.45, 0.55)
	_add(&"attack_boss", _nums("creatures", "monster_", 4, 7), &"Effects", -3.0, 0.6, 0.75)
	_add(&"roar", _nums("rpg80", "creature_roar_", 1, 3), &"Effects", 0.0, 0.8, 0.95)

	# --- Class abilities ---
	_add(&"cast_simple", spells, &"Effects", -5.0, 0.95, 1.1)
	_add(&"bolt", spells, &"Effects", -6.0, 1.25, 1.4)
	_add(&"mend", spells, &"Effects", -4.0, 1.4, 1.6)
	_add(&"hex", spells, &"Effects", -2.0, 0.6, 0.75)
	_add(&"fury", _nums("rpg80", "creature_roar_", 1, 3), &"Effects", -2.0, 0.7, 0.85)
	_add(&"resolve", metal + stones, &"Effects", -2.0, 0.6, 0.8)
	_add(&"throw", swish_heavy, &"Effects", -2.0, 0.55, 0.7)
	_add(&"fire", fire, &"Effects", -4.0)
