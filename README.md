# KINGDOM (working title)

A dark fantasy co-op action RPG for PC, built with **Godot 4.7.2**.

## Open the project
- **Easiest:** double-click **"Kingdom (Godot editor)"** on your desktop.
- **Or:** double-click **"Godot 4.7.2"** on your desktop → in the Project Manager click **Import** → pick `project.godot` in this folder → **Open**.

## Play
Press **F5** (or the ▶ button at the top right of the editor). Close the game window, or press **F8** in the editor, to stop.

The game starts in the **movement test map**. In the game, press **F1** to see the controls.
- To see the Phase 1 mood map instead: in the editor's **FileSystem** panel (bottom left), open `levels/sandbox/look_test.tscn` and press **F6** ("run this scene").

## Change the numbers
All the movement and stamina numbers are in `data/balance/player_tuning.tres`. Double-click it in the FileSystem panel; the numbers show up in the **Inspector** on the right, each with a short description. Change one, press F5, feel the difference. (git remembers the old values.)

## What's where
| Folder / file | What it is |
|---|---|
| `SPEC.md` | Your original brief |
| `DESIGN.md` | The full game design + technical plan |
| `TODO.md` | Phase-by-phase checklist (what's done, what's next, what to test) |
| `ART_NEEDS.md` | Art & audio shopping list |
| `assets/` | Art and sound. Every file is logged in `assets/CREDITS.md` |
| `data/` | Game numbers you can edit: classes, items, enemies, loot tables |
| `game/` | Code and scenes, grouped by feature |
| `levels/` | Maps. `levels/sandbox/` holds test maps |
| `tests/` | Automated checks |

## Safety net
The project uses **git**: every working step is saved as a snapshot (a "commit"). If something breaks, we can roll back to any earlier step.
