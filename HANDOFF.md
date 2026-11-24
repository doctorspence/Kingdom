# HANDOFF: where we are

*Updated 2026-11-23. Read this first in a new session. One screen on purpose: the checklists live elsewhere (see "Which file is which").*

## How to resume
1. Open `C:\Users\reals\Documents\Kingdom` in Claude Code. Close the Godot editor or use Project > Reload Current Project, so it doesn't hold old copies of files.
2. Read this file, then `PRIORITIES.md` (what to do next), then `SPEC.md` (the original brief and the "How to work" rules: plain language, one phase at a time, ask before design changes).
3. Do the first unticked item in `PRIORITIES.md`.

## The project in one paragraph
KINGDOM (working title) is a dark fantasy co-op action RPG in Godot 4.7.2 (GDScript), host-and-play for 1-10 players, Souls-style combat plus a WoW-style hotbar. The owner has no coding experience.

## Where we are
Phases 1-15 are built: movement, combat, multiplayer, three classes with talents, loot and death, the Tithelands (terrain, buildings, chapel and barrow, mill race, camp and raids, day/night), the bandit Gullet with Harl the Delver, audio, settings and rebinding, equipment, three subclasses. Art is a detailed environment with mannequin characters. **The milestone (3 friends clear the Tithelands and the Gullet) has not happened.** The next job is to stabilize, play and fix, not to add. All checks, including the 3-player check, passed on 2026-11-22.

**Combat rhythm pass (2026-11-22, now in `main`):** Sekiro / Nioh 2-style timing. Deflect = a timed guard per blow (mashing shrinks the window); enemies have a visible balance bar that hits and deflects drain, and an empty bar opens a riposte; enemies guard after 2 hits in a row and strike back, string attacks together and sometimes delay a swing; "Steady" (tap guard as your swing recovers) refunds stamina; perfect dodges arm a stronger counter, and rolling into a red attack (Step-in) rocks the attacker. Pass 3 added warning sounds (glint "shing", red-attack rattle), rising clangs for deflects in a row, "Flawless" strings, a heavy crack when balance breaks, and "Interrupted" (a hit during your light attack's wind-up knocks it away). Pass 4 added attack reach (swings step in up to 1.2 m to land) and enemies that punish a held guard with their red or heaviest attack. Rules in `DESIGN.md` 5.4-5.5.1, numbers in `data/balance/player_tuning.tres` and the enemy files, tests in `tests/combat_check.gd`. Waiting for the owner's playtest (`TODO.md`).

**Greenwood overhaul (2026-11-22, merged into `main` 2026-11-23):** the owner's Greenwood biome brief was applied to the Tithelands; plan and progress in `GREENWOOD_OVERHAUL.md`. Stages 0-5 done (ground shader, five-species tree library, firs removed, landmark trees, canopy light, terrain shaping with the brook and the chapel lane, worked limestone quarry with a timber-shored Gullet entrance, ground plants, props and story dressing, lighting and atmosphere) and stage 9 validated (all checks and the 3-player check pass; report at the end of the Progress table). Performance pass done (per-tree detail switch, cheaper tree shadows, load cache: load 10.6 s to 6.9 s, triangles in the woods down 35-60%; see "Performance pass" in GREENWOOD_OVERHAUL.md). Clean measurement done: idle far-off enemies now sleep (game/world/enemy_sleep.gd), every spot 100-171 FPS at 1080p, above the original zone. Load cache lives in user://bake_cache (safe to delete; it refills). Merged into `main` on 2026-11-23 (fast-forward, all checks passed); `greenwood` and `main` are the same commit, and work can carry on in either. Not playtested by hand yet.

**The way into the Gullet is a walkable tunnel (2026-11-23, branch `greenwood`):** no door, no button, no loading. `game/world/quarry_descent.gd` builds a 130 m incline from the quarry adit to the Entrance Yard; light, sound, the player lantern and `UndergroundCull` follow `QuarryDescent.path_s()`/`depth_cave()`. It needed: ground "holes" (`holes` in `tithelands_land.gd`, handled in `sculpted_terrain.gd`: dropped from the drawn mesh and the collision) where the doorway passes through the cliff, a flattened apron (late cut), the west zone-edge wall split around the tunnel (`EdgeW`..`EdgeW4`), a new west doorway in the Gullet (last entry of `Gullet.CARVES`, its end wall removed by `_is_descent_cap`), walk-through mine rails, and `QuarryDescent` placed at the zone root (not under `Places`, which snaps children to the ground). `tests/descent_check.gd` walks it with a body; `tests/visual_descent.gd` takes pictures. The `CaveDoor`s still exist, disabled. Not done: music/reverb tweaks inside the tunnel, enemies following you out (they keep their leash).

**Inventory and character screen (2026-11-23, branch `greenwood`):** the owner's brief (`DESIGN_INBOX.md`, Filed) replaced the plain inventory panel with a "menu book": tabs Character / Inventory / Map / Talents / Quests / System on top (Q E, LB RB), backpack grid with drag and drop, turning, stacks, sort, junk and filters on the left, the player's own model on a pedestal under a stone arch in the middle (a SubViewport) with the slots around it, real stats on the right. One ring slot (old saves move the second ring to the backpack), the cloak lives in the Utility slot, no belt slot, both weapon sets kept. Map, Talents and System are the old panels laid over the book, restyled with `UiStyle.theme()`. Code: `game/ui/character_screen.gd` (screen), `ui_style.gd` (frames, fonts, theme), `character_preview.gd` (3D view); rules in `Inventory` / `ItemGrid`. All 71 items now have icons (37 new stand-ins from `tools/render_extra_icons.gd`). Screenshots: `tests/visual_inventory.gd`. Not playtested by hand yet.

**Movement redesign, hybrid (2026-11-23, branch `greenwood`):** grounded "weight" from the owner's brief (`DESIGN_INBOX.md`, Filed). Exploring stays camera-relative; **combat stance** (locked on, or guard up) faces the foe, or where the camera looks if no target, and slows the backpedal (0.7×) and sidestep (0.9×). Walk 2.0, run 5.8, sprint 8.0; acceleration 16, deceleration 20, turning a third of before (all in `player_tuning.gd` / `data/balance/player_tuning.tres`). The backpedal plays the walk or jog in reverse (`CharacterModel.update_locomotion(..., backward)`); sidesteps still slide until strafe animations exist (`ART_NEEDS.md`). **Mouse wheel zooms the camera** (1.6-6 m, `player_camera.gd`) when not locked on, and still switches target when locked. `movement_check` covers stance speeds; combat, moves and zone checks pass. Not playtested by hand yet.

## Which file is which
| File | Use |
|---|---|
| `PRIORITIES.md` | What to do next, in order. The only "next" list. |
| `TODO.md` | The checklist by phase, including every 🧪 playtest item. |
| `SPEC.md` | The owner's original brief. Never edit. |
| `DESIGN.md` | Game design and numbers. |
| `CLASS_PLAN.md`, `GULLET_DESIGN.md`, `ZONES_DESIGN.md`, `ZONE1_OVERHAUL.md`, `ART_NEEDS.md` | Detail for one area. `ZONE1_OVERHAUL.md` also holds the stage 7 performance plan. |

## Things to know
- **Checks:** run one with `--headless --script res://tests/run.gd -- <name>` (README.md). Names: movement, combat, moves, enemy, death, loot, class, subclass, boss, camp, gullet, zone, audio, sound, prefs. Plus the 3-player check `tests/run_net_check.ps1`. Also `save_check`. Run them one at a time (shared port 31499, and timing checks fail under load). If a timing check fails once, rerun it before suspecting a bug.
- **Godot and git paths:** no PATH shortcuts. Godot is in `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\` (use `_console.exe` for output). Git is `C:\Program Files\Git\cmd\git.exe`.
- **Port 31415 is the owner's live game.** Checks use 31499.
- **Test keys** (F3-F7, Page Up/Down) only work in the editor or a debug build; the exported friends build has them unbound. F1 help hides them there too.
- **`two_handed = true`** must stay in `data/weapons/weapon_executioner_greatsword.tres` and `weapon_lantern_staff.tres`; the editor dropped it once when re-saving. If class or loot checks fail on "two-handed", look there.
- **Editor churn:** opening the project in the editor regenerates `.import` files and rebakes `assets/buildings/*.scn`. Commit it as its own commit.
- **Two sessions at once:** another session may own `game/world/gullet.gd` or the terrain files. Check `git status` first and commit only your own files.
- **Friends build:** `build/Kingdom-windows.zip` was re-exported 2026-11-22 (176 MB; test keys unbound). Re-export after later changes: README.md "Play with friends".
- **Performance:** `Godot --path . --resolution 1920x1080 --script res://tests/run.gd -- perf_zone` prints FPS at 10 fixed spots (options: `nogrow`, `noomni`, `hide:Node,Node`, `only:spot`). Terrain LODs are in `sculpted_terrain.gd`, `distance_cull.gd` and `shadow_budget.gd` are nodes in tithelands.tscn.
- **Commits** use the neutral local identity "Kingdom Dev".
- **Brother Tallow and the acolytes** are unused data (the old Gullet). Keep or delete is an open decision in `PRIORITIES.md` P2.
- **Reusing art:** shared materials are in `levels/common/materials/`, textures in `assets/textures/`, camp props in `levels/tithelands/props/`. Do not use height fog in an environment (it buries underground rooms).
- **Seeing a zone without playing:** `Godot --path . --resolution 1280x720 --script res://tests/run.gd -- visual_env` writes PNGs to `%APPDATA%\Godot\app_userdata\Kingdom\shots`.

## Known loose ends
- Quarry-specific Gullet audio and a Harl boss track are not made (the old cave beds and boss track play).
- A death pile in an old world save at the OLD Gullet's coordinates would sit inside rock (it expires after 60 minutes).
- Every number in Harl, the Captain, camp raids and the Gullet is a first guess; tuning needs a playtest.
