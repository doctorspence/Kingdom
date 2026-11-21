# HANDOFF: where we are and how to resume

*Updated 2026-11-21. Read this first in a new session or on a different Claude account. Everything lives in this folder and in git.*

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

## Next up
Playtest the new abilities (🧪 in TODO.md). Then, when you want it, the subclass work in `CLASS_PLAN.md` (Priority 1 onward). Your decisions so far: subclass is re-pickable in future; names Martial / Vanguard / Mystic are for now.

## Things to know
- **Checks:** run any check with `--headless --script res://tests/run.gd -- <name>` (see README.md). Current checks: movement, combat, class, loot, death, enemy, zone, boss, moves, audio, sound; plus the 3-player check `tests/run_net_check.ps1`. All pass as of this update.
- **Godot and git paths:** there are no PATH shortcuts. Godot is in `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\` (use the `_console.exe` for output). Git is `C:\Program Files\Git\cmd\git.exe`.
- **Never run test copies on port 31415** (that is your live game). Checks use 31499.
- **The class and loot checks** depend on `two_handed = true` being present in `data/weapons/weapon_executioner_greatsword.tres` and `weapon_lantern_staff.tres`. The Godot editor dropped that line once when it re-saved them; it was restored by hand. If those checks fail on "two-handed", look there.
- **Your uncommitted edits** (class files, weapon files, `overcast_env.tres`, `look_test.tscn`) are your own tuning from the editor. They are not part of any commit yet.
- **Commits** use the neutral local identity "Kingdom Dev"; the commit history lets you roll back any step.
- **The `build/` zip** for friends is old (before the Gullet and later changes). Re-export before sharing (README.md, "Play with friends").
- `SPEC.md` is your original brief and is left exactly as you wrote it.
