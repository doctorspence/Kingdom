# KINGDOM (working title)

A dark fantasy co-op action RPG for PC, built with **Godot 4.7.2**.

## Open the project
- **Easiest:** double-click **"Kingdom (Godot editor)"** on your desktop.
- **Or:** double-click **"Godot 4.7.2"** on your desktop → in the Project Manager click **Import** → pick `project.godot` in this folder → **Open**.

## Play
Press **F5** (or the ▶ button at the top right of the editor). Close the game window, or press **F8** in the editor, to stop.

**To enter the dungeon:** the **Gullet** is an underground cave. Walk to the Quarry Shrine (northwest of the map) and find the amber light beam beside it, then press **E** at the stone arch ("Descend into the Gullet"). It also shows as an orange dot on the map (**M**). The boss, Harl the Delver, is behind the fog gate at the far end of the old quarry workings, past the bandit camp.

The game starts at the **main menu**. Make your character (name, class, body, color), type a **World** name (each world keeps its own time, opened shortcuts and death piles), then **Host game** (also how you play alone). You start at the Crossroads in the Tithelands. In the game: attack types (all weapons): light, heavy (hold to charge), **running** attacks (while sprinting), **rolling** attacks (right after a roll), **jump** light/heavy (attack in the air), **plunging** attack (attack while falling from high up), **guard counter** (attack with your guard up) and **backstep** attack. A quick sideways mouse flick lets go of a lock-on. **I** opens your inventory, **M** the map, **E** at a shrine opens Rest / Travel / Bank, **E** at Old Wenna or the Soul Broker opens their shop. Your character and world save automatically. Testing shortcuts: **Page Up** = gain a level, **Page Down** = back to level 1, **T** = talents, **F5** = skip 3 hours, **F6** = rain on/off. Press **F1** in the game to see all controls, **Esc** for the menu.

## Play with friends
- **Same house (same Wi-Fi/router):** you click **Host game**. The menu shows your address (like `192.168.1.20`). Friends type it under *Host's address* and click **Join game**.
- **Over the internet:** either
  - **easiest:** everyone installs the same free virtual-LAN app (Tailscale, ZeroTier or Radmin VPN) and joins the same network; friends use the host's address from that app; or
  - the host forwards **UDP port 31415** on their router to their PC, and friends use the host's public IP.
- Friends need their own copy of the game: send them `build/Kingdom-windows.zip` (they unzip it and run Kingdom.exe; no Godot needed). Everyone must have the **same build**.
- To make a fresh build after changes: in the editor, **Project → Export... → Windows → Export Project** (save as `build/windows/Kingdom.exe`), then zip that folder. Or ask me.

## Test 3 players on one PC
In the editor: **Debug → Customize Run Instances...** → tick **Enable Multiple Instances**, set it to **3**. Give instance 1 the arguments `-- --host` and instances 2 and 3 `-- --join=127.0.0.1` (optionally add `--name=Bob`). Press F5: three windows open and connect by themselves. (Or start them by hand from the menus, using address `127.0.0.1`.)
- Other test maps: in the editor's **FileSystem** panel (bottom left), open one and press **F6** ("run this scene"):
  - `levels/sandbox/movement_test.tscn`: slopes, stairs, fall heights
  - `levels/sandbox/look_test.tscn`: the Phase 1 mood map

## Automated checks
I run these before handing you a build. You can too (PowerShell, in this folder):
```
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/run.gd -- combat_check
```
(Swap `combat_check` for `movement_check`, `class_check`, `loot_check`, `death_check`, `enemy_check`, `zone_check`, `boss_check` (the Gullet and the boss) `moves_check` (extra attacks, lock-on flick, enemy spacing), `audio_check` (volume groups and sliders), `sound_check` (combat sounds), `subclass_check` (subclasses), `prefs_check` (settings and key rebinding) or `camp_check` (the camp and raids) to run the others.) Each ends with PASS or FAIL.

The 3-player network check starts three copies of the game and prints what each one saw:
```
powershell -ExecutionPolicy Bypass -File tests\run_net_check.ps1
```

## Change the numbers
Weapons, shields and enemies are in `data/weapons/`, `data/shields/` and `data/enemies/` (open an attack inside them to change its damage, speed or reach). All the movement and stamina numbers are in `data/balance/player_tuning.tres`. Double-click it in the FileSystem panel; the numbers show up in the **Inspector** on the right, each with a short description. Change one, press F5, feel the difference. (git remembers the old values.)

## What's where
**AI helpers (Claude Code, ChatGPT) reading this repo:** start with `HANDOFF.md`, then `PRIORITIES.md`, then `SPEC.md`. Claude Code's working rules are in `CLAUDE.md`.

| Folder / file | What it is |
|---|---|
| `SPEC.md` | Your original brief: the game's vision. Never edited |
| `HANDOFF.md` | Where we are right now, and how to resume in a new session or account |
| `PRIORITIES.md` | What to do next, in order |
| `CLAUDE.md` | Rules Claude Code reads at the start of every session |
| `DESIGN_INBOX.md` | Design and art-direction decisions from ChatGPT, waiting for Claude Code to file and build them |
| `DESIGN.md` | The full game design + technical plan (art direction and palette: section 12.1) |
| `TODO.md` | Phase-by-phase checklist (what's done, what's next, what to test) |
| `ZONES_DESIGN.md` | Layout and story for zones 1-3: the Tithelands, Highcrown, the Barrow Fells (maps: `ZONE*_MAP.png`, `ZONES_OVERVIEW.png`) |
| `ZONE1_OVERHAUL.md` | Zone 1 rebuild and performance plan |
| `GREENWOOD_OVERHAUL.md` | Zone 1 Greenwood look: trees, limestone, plants, light |
| `GULLET_DESIGN.md` | The Gullet dungeon and Harl the Delver (map: `GULLET_MAP.svg`) |
| `CLASS_PLAN.md` | Plan for the Martial / Vanguard / Mystic classes, nine subclasses and the three factions (not built yet) |
| `ART_NEEDS.md` | Art & audio shopping list |
| `assets/` | Art and sound. Every file is logged in `assets/CREDITS.md` |
| `data/` | Game numbers you can edit: classes, items, enemies, loot tables |
| `game/` | Code and scenes, grouped by feature |
| `levels/` | Maps. `levels/sandbox/` holds test maps |
| `tests/` | Automated checks |

## Safety net
The project uses **git**: every working step is saved as a snapshot (a "commit"). If something breaks, we can roll back to any earlier step.
