class_name SfxLibrary
extends RefCounted
## Every game sound as a named "cue": a short list of files (one is picked at
## random each time), the volume group it plays on, a base volume and a pitch
## range. Gameplay code only says Audio.sfx(&"hit_flesh", where); to change what
## a cue sounds like, edit it here. All files are CC0 (see assets/CREDITS.md).

const SFX := "res://assets/audio/sfx/"
const AMB := "res://assets/audio/ambience/"

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


## `layers` are other cues played together with this one (a Legendary drop is
## several sounds at once).
static func _add(name: StringName, files: Array, bus := &"Effects", db := 0.0, pitch_min := 0.94, pitch_max := 1.06, layers := [], hear_m := 45.0) -> void:
	_cues[name] = {"files": files, "bus": bus, "db": db, "pitch": Vector2(pitch_min, pitch_max), "layers": layers, "range": hear_m}


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
	## Steady (well-timed guard after a swing) and perfect dodges: a soft bright ring.
	_add(&"steady", [SFX + "kenney_rpg/metalClick.ogg"] + _nums("rpg80", "item_gem_", 1, 1), &"Effects", -9.0, 1.5, 1.7)
	## Warnings you can deflect by ear: a thin blade "shing" on every white glint,
	## a low rattle under a red (unblockable) attack.
	_add(&"warn_glint", [SFX + "kenney_rpg/drawKnife1.ogg", SFX + "kenney_rpg/drawKnife2.ogg", SFX + "kenney_rpg/drawKnife3.ogg"], &"Effects", -5.0, 1.35, 1.5, [], 30.0)
	_add(&"warn_danger", _nums("rpg80", "chain_", 1, 3), &"Effects", 0.0, 0.5, 0.58, [], 35.0)
	## An enemy's balance breaks: a heavy crack under the clang.
	_add(&"break_balance", _nums("hits", "bfh1_breaking_", 1, 3), &"Effects", 1.0, 0.75, 0.85, [&"clang_parry"])

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
	# --- Voices (a raider or knight: grunts, lower and rougher than yours) ---
	var grunts := _nums("creatures", "grunt_", 1, 5)
	_add(&"hurt_raider", grunts, &"Effects", -2.0, 0.65, 0.8)
	_add(&"die_raider", [SFX + "rpg80/creature_die_01.ogg"], &"Effects", 0.0, 0.6, 0.75)
	_add(&"attack_raider", grunts, &"Effects", -5.0, 0.6, 0.75)
	# A horn carries a long way: everyone nearby hears the alarm.
	_add(&"horn", [SFX + "horn/theircoming.ogg", SFX + "horn/theircoming3.ogg"], &"Effects", 0.0, 0.95, 1.0, [], 90.0)
	# --- Voices (a boss) ---
	_add(&"hurt_boss", roar_big, &"Effects", -6.0, 0.6, 0.75)
	_add(&"die_boss", roar_big, &"Effects", 2.0, 0.45, 0.55)
	_add(&"attack_boss", _nums("creatures", "monster_", 4, 7), &"Effects", -3.0, 0.6, 0.75)
	_add(&"roar", _nums("rpg80", "creature_roar_", 1, 3), &"Effects", 0.0, 0.8, 0.95)

	# --- Class abilities ---
	_add(&"cast_simple", spells, &"Effects", -5.0, 0.95, 1.1)
	# Arcane Surge: a low gathering hum, a held shimmer, a heavy release and a bright impact.
	_add(&"surge_gather", spells, &"Effects", -7.0, 0.55, 0.65)
	_add(&"surge_channel", spells, &"Effects", -9.0, 0.4, 0.5)
	_add(&"surge_release", swish_heavy, &"Effects", -1.0, 0.5, 0.62, [&"surge_release_zap"])
	_add(&"surge_release_zap", spells, &"Effects", -2.0, 0.85, 0.95)
	_add(&"surge_impact", spells, &"Effects", -5.0, 1.5, 1.7, [&"surge_impact_thud"])
	_add(&"surge_impact_thud", _nums("rpg80", "stones_", 1, 4), &"Effects", -6.0, 0.7, 0.85)
	_add(&"mend", spells, &"Effects", -4.0, 1.4, 1.6)
	_add(&"hex", spells, &"Effects", -2.0, 0.6, 0.75)
	_add(&"fury", _nums("rpg80", "creature_roar_", 1, 3), &"Effects", -2.0, 0.7, 0.85)
	_add(&"resolve", metal + stones, &"Effects", -2.0, 0.6, 0.8)
	_add(&"throw", swish_heavy, &"Effects", -2.0, 0.55, 0.7)
	_add(&"fire", fire, &"Effects", -4.0)

	# --- Loot: one sound per rarity when an item hits the ground (Legendary is a big layered one) ---
	var gems := _nums("rpg80", "item_gem_", 1, 4)
	_add(&"gem_chime", gems.slice(2, 4), &"Effects", -5.0, 0.95, 1.05)
	_add(&"drop_common", _nums("rpg80", "item_wood_", 1, 3), &"Effects", -6.0)
	_add(&"drop_uncommon", _nums("rpg80", "item_misc_", 1, 6), &"Effects", -4.0)
	_add(&"drop_rare", gems.slice(0, 2), &"Effects", -2.0)
	_add(&"drop_epic", gems.slice(2, 4), &"Effects", 0.0, 0.95, 1.05, [&"drop_epic_shimmer"])
	_add(&"drop_epic_shimmer", spells, &"Effects", -6.0, 1.7, 1.9)
	_add(&"drop_legendary", fire.slice(3, 7), &"Effects", 3.0, 0.65, 0.75, [&"drop_legendary_gem", &"drop_legendary_swell"])
	_add(&"drop_legendary_gem", gems, &"Effects", 0.0, 0.8, 0.9)
	_add(&"drop_legendary_swell", roar_big, &"Effects", -7.0, 0.4, 0.5)

	# --- Items, money, shrines, progress (play flat, only for you) ---
	_add(&"pickup", [SFX + "kenney_rpg/handleSmallLeather.ogg", SFX + "kenney_rpg/handleSmallLeather2.ogg",
			SFX + "kenney_rpg/beltHandle1.ogg", SFX + "kenney_rpg/beltHandle2.ogg"], &"Interface", -3.0)
	_add(&"coins", _nums("rpg80", "item_coins_", 1, 4) + [SFX + "kenney_rpg/handleCoins.ogg", SFX + "kenney_rpg/handleCoins2.ogg"], &"Interface", -3.0)
	_add(&"souls", spells, &"Interface", -7.0, 1.5, 1.75, [&"gem_chime"])
	_add(&"equip", [SFX + "kenney_rpg/metalLatch.ogg", SFX + "kenney_rpg/metalClick.ogg", SFX + "kenney_rpg/clothBelt.ogg", SFX + "kenney_rpg/clothBelt2.ogg"], &"Interface", -3.0)
	_add(&"shrine_rest", fire.slice(0, 3), &"Effects", -2.0, 0.7, 0.8, [&"mend"])
	_add(&"shrine_found", spells, &"Effects", -3.0, 0.7, 0.8)
	_add(&"level_up", spells, &"Interface", -3.0, 1.0, 1.05, [&"gem_chime"])
	_add(&"death_sting", [SFX + "rpg80/creature_monster_01.ogg", SFX + "rpg80/creature_monster_02.ogg"], &"Interface", -2.0, 0.4, 0.5)
	_add(&"pile_appear", spells, &"Effects", -5.0, 0.5, 0.6)
	_add(&"pile_recover", gems, &"Interface", -3.0, 0.9, 1.0, [&"pickup"])
	_add(&"roll_offer", gems.slice(0, 1), &"Interface", -8.0, 1.4, 1.5)

	# --- The world ---
	_add(&"crow", [AMB + "crow_caw.wav"], &"Ambience", -6.0, 0.85, 1.1)

	# --- Menus ---
	_add(&"ui_click", [SFX + "kenney_rpg/metalClick.ogg"], &"Interface", -12.0, 0.95, 1.1)
	_add(&"ui_open", [SFX + "kenney_rpg/bookOpen.ogg", SFX + "kenney_rpg/bookFlip1.ogg", SFX + "kenney_rpg/bookFlip2.ogg"], &"Interface", -6.0)
	_add(&"ui_close", [SFX + "kenney_rpg/bookClose.ogg"], &"Interface", -6.0)
