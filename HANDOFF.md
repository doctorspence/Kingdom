# HANDOFF: where we are and how to resume

*Updated 2026-11-21 (new Gullet built and given a first cave look pass). Read this first in a new session or on a different Claude account. Everything lives in this folder and in git.*

## How to resume
1. Open this folder (`C:\Users\reals\Documents\Kingdom`) in Claude Code.
2. Ask the new session to read, in this order: `HANDOFF.md` (this file), `SPEC.md` (your original brief and the "How to work" rules), `DESIGN.md`, `TODO.md`, `CLASS_PLAN.md`.
3. If the Godot editor is open, reload the project (Project -> Reload Current Project) or close it, so it doesn't hold old copies of files.
4. Tell it to continue from "Next up" below.

## The project in one paragraph
KINGDOM (working title) is a dark fantasy co-op action RPG in Godot 4.7.2 (GDScript), host-and-play for 1-10 players, Souls-style combat plus a WoW-style hotbar. You have no coding experience, so explain things in plain language, build one phase at a time, and ask before design changes.

## What is built
| Phase | State |
|---|---|
| 1 Setup | Done |
| 2 Player controller | Done |
| 3 Combat core | Done |
| 4 Multiplayer (host/join by IP, 3-player tested) | Done |
| 5 Classes (Bulwark, Lamplighter, Headsman, talents, threat, statuses) | Done |
| 6 Loot (grid inventory, rarity, need/greed, vendors, bank, character saves) | Done |
| 7 Death system (loot pile, 60-minute timer) | Done |
| 8 The Tithelands (zone, 3 enemy types, Hobb, shrines, map, day/night, rain, shortcut, world saves) | Done, gray-block |
| 9 The Gullet and Brother Tallow | Done, gray-block |
| After 9: Nioh 2 movement, Elden Ring extra attacks, solid spacing enemies, lock-on flick | Done |

All art is placeholder (gray shapes, mannequin models). Audio is not started (needs your OK to download CC0 sounds).

## Playtests
You have played through the Tithelands, Hobb, the Gullet and Brother Tallow, the new attacks and enemy spacing, and an internet test with friends. Still to try: the nine new class abilities.

## Just done: the three primary classes
Headsman / Bulwark / Lamplighter are now **Martial / Vanguard / Mystic** (names provisional; internal IDs unchanged so saves work). Each has three abilities unlocked at levels 2, 4 and 6 (see DESIGN.md section 6). Subclasses are deferred: you decided they come later, and the choice should be re-pickable in future. `class_check` was rewritten and passes, as do all other checks and the 3-player check.

## Phase 10 (audio): built
All the sounds and music are in (321+ CC0 files in `assets/audio/`, credited in `assets/CREDITS.md`): combat, abilities, loot, menus, zone ambience, music, and Tallow's boss track. Volume sliders are under **Volume** in the main and Esc menus. I could not listen, so cues were chosen by file name: you need to play with sound on and tell me what is wrong (cues are in `game/audio/sfx_library.gd`). The friends build (`build/Kingdom-windows.zip`, 66 MB) was re-exported with sound.

## Phase 12 (settings and key rebinding): built
Menu > Settings (main menu and Esc menu) has Audio, Gameplay, Display and Controls tabs; you can rebind all keyboard and mouse actions. Saved in `settings.cfg`.

## Phase 13 (camp and night raids): built
The Camp Hearth is east of the Crossroads shrine. Claim it (100 coins), upgrade it from the hearth menu, and defend it when raiders come at night. F7 starts a raid now, F5 skips ahead 3 hours. Design in DESIGN.md 11.5 (all numbers are my first guesses).

## Phase 15 (environment pass): built in stages
The Tithelands now looks like a place: photographic ground textures, Kingdom Come style earth and half-timbered buildings under Dark Souls light and fog, camps with fires, trails and clearings that connect the places, a river shader, boulders, firs and dead trees made in code, swaying grass, ground clutter. Checklist in `TODO.md` (Phase 15). To see it without playing: `Godot --path . --resolution 1280x720 --script res://tests/run.gd -- visual_env` (optionally `"x,z,yaw,name"` arguments for your own spots; yaw 0 looks north) writes PNGs to `%APPDATA%\Godot\app_userdata\Kingdom\shots`.
**For anyone building the new Gullet:** reuse the shared materials in `levels/common/materials/` (`dark_stone` = grey cave rock, `rock`, `stone`, `wood`, `dark_wood`, `plaster`, `thatch`, `bark`, `burned`, `iron`) and the textures in `assets/textures/` (cliff, cave_rock, scree, dirt_dark, mud, wood, planks, stonewall); they are triplanar, so CSG boxes and cylinders need no UVs. `props/campfire.tscn`, `crate`, `barrel`, `log_seat`, `trophy_pole`, `lookout`, `hay_bale` are ready-made camp pieces. Do not use height fog in an environment (it buries underground rooms).

## Next up (updated 2026-11-21, end of session)
**Where we are:** Phases 1-15 are built, and the new Gullet (bandit quarry) is built and has had a first "cave look" pass (ceiling holes with blue daylight shafts, noise-roughened walls/floors/ceilings, stalagmites and stalactites, brighter torches, mine timber frames). Your feedback was: the dungeon was too dark and the walls were flat. **Still to judge by eye:** open `visual_gullet` or walk it and say whether it is now bright and rough enough; the reference targets are the tall fractured entrance with a light shaft, and the two-story "The Cave" look (teal-lit, waterfalls, ledges).

**Suggested order for the next sessions (most valuable first):**
1. **Gullet look pass 2** (only if you are not happy yet): waterfalls into the river in the camp and Excavation, wet-rock shader, more rubble and fallen rock, a lighter fill in the tunnels. Another Claude session owns `game/world/gullet.gd`; check `git status` and commit only your own files.
2. **Commit the leftovers:** your editor tuning (`data/classes/*.tres`, `data/enemies/enemy_hound/marauder/zealot.tres`, `data/subclasses/*.tres`, `levels/sandbox/look_test.tscn`) and `NEXT_STEPS.md` were never committed.
3. **Playtest round (you):** all the 🧪 lines in `TODO.md` (audio, settings, camp and raids, environment, nine abilities, the new Gullet). Bugs hide here; send me what feels wrong.
4. **Re-export the friends build** (steps in README.md "Play with friends"); the last zip is from before camp, environment, buildings and the new Gullet.
5. **Highcrown (the checkpoint town)** and the checkpoint banners and market props; Tithelands extras (ferns, puddles, daytime clouds, distant tree LODs).
6. **Art pipeline test:** one bandit from AI concept to a rigged model on the standard skeleton (`ART_NEEDS.md`, `GULLET_DESIGN.md` section 10).
7. **Subclasses (Phase 11)** are paused at your request: framework plus Warrior, Guardian and Cleric exist; Paladin, Mage, Rogue, Ranger, Warlock, Warden are "Coming later".
8. **Milestone:** 3 friends clear the Tithelands and the new Gullet.

**Prompt to paste into a new session:** "Read HANDOFF.md, then TODO.md and NEXT_STEPS.md. Tell me in a few lines where we are, then start on item 1 of 'Next up' in HANDOFF.md. Commit only your own files; another session may be editing game/world/gullet.gd."

## Things to know
- **Checks:** run any check with `--headless --script res://tests/run.gd -- <name>` (see README.md). Current checks: movement, combat, class, loot, death, enemy, zone, boss, moves, audio, sound, subclass, prefs, camp; plus the 3-player check `tests/run_net_check.ps1`. All pass as of this update.
- **Godot and git paths:** there are no PATH shortcuts. Godot is in `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\` (use the `_console.exe` for output). Git is `C:\Program Files\Git\cmd\git.exe`.
- **Never run test copies on port 31415** (that is your live game). Checks use 31499.
- **The class and loot checks** depend on `two_handed = true` being present in `data/weapons/weapon_executioner_greatsword.tres` and `weapon_lantern_staff.tres`. The Godot editor dropped that line once when it re-saved them; it was restored by hand. If those checks fail on "two-handed", look there.
- **Your editor tuning** (class and weapon files, `overcast_env.tres`, `look_test.tscn`) is committed (commit "Editor tuning").
- **Run checks one at a time, never at the same time as the 3-player check** (they share port 31499 and the timing checks fail under load).
- **Flaky checks:** `combat_check` (random crit) and `moves_check` (guard counter timing) were fixed on 2026-11-21; if one fails again, rerun once before suspecting a real bug.
- **Commits** use the neutral local identity "Kingdom Dev"; the commit history lets you roll back any step.
- **The `build/` zip** for friends was re-exported after Phase 10 (audio). Re-export again after later changes (README.md, "Play with friends"); `Godot_console.exe --headless --path . --export-release "Windows" build/windows/Kingdom.exe`, then zip `build/windows`.
- `SPEC.md` is your original brief and is left exactly as you wrote it.

## Phase 14: the new Gullet (bandit quarry): built, gray-block (2026-11-21)
Replaces the candle-monk Gullet. Design in `GULLET_DESIGN.md` (build status in its section 10), floor plan in `GULLET_MAP.svg`, checklist in `TODO.md`. Done in order: gold renamed to **coins** everywhere (old saves convert), food and potions and the new gear and loot tables, Bandit / Archer / Captain / Lookout enemies, powder barrels, the new level with the river through both two-story rooms, population, hidden chest and secret wall, and **Harl the Delver**. Brother Tallow and the acolytes stay in the project, unused.
- New check: `gullet_check` (run it like the others). `boss_check` now tests Harl. All checks should pass; if a timing check fails once, rerun it.
- Things only you can judge (🧪): how the dungeon feels to walk and fight (about 10 minutes?), whether the archers and barrels are fun or annoying, Harl's numbers, the camp-wide alarm, the river slowing you, and the stand-in sounds. Every number is a first guess.
- Known loose ends: the named rare's name and loot (Rook the Cutthroat) are mine; quarry-specific audio and boss music are not made; a death pile left in the OLD Gullet's coordinates in an old world save would sit inside rock (it expires after 60 minutes); the friends build needs re-exporting after you approve.
