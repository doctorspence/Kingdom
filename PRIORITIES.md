# KINGDOM: priority checklist

*Started 2026-11-22 from a read-through of the project: docs, git history, and the main code files. I didn't run the game or the checks for this.*
*P0 done 2026-11-22: test keys locked to debug builds, tree committed and clean, all 15 checks and the 3-player check pass, to-do docs merged (NEXT_STEPS retired, HANDOFF is now one screen).*

**The short version:** you've built a huge amount in about 48 hours (100+ commits, Phases 1 to 15). But there are **15 open 🧪 playtest items**. The milestone in `SPEC.md` (3 friends clear the zone and the dungeon) has not happened yet. The friends build is several big changes out of date. Most recent sessions went into art passes. The best next move is to **stop adding, stabilize, and play.**

Who does it: **You** (no code) · **CC** (Claude Code in this folder)

---

## P0: Stabilize first (small, do these before anything new)

- [x] **CC: Lock the test shortcuts out of the friends build.** PageUp (level up), PageDown, the reset key and the gear-cycle key work for *any* player in the exported game (`game/player/player.gd`, around line 1138). A friend can jump to max level and skip all progression. Make them work only in the editor (`OS.is_debug_build()`), and do the same for F5/F6/F7 (time, rain, raid).
- [x] **CC: One session per area, and a clean `git status`.** Two Claude sessions have been editing in parallel (HANDOFF warns that "another session owns gullet.gd"). `ZONE1_OVERHAUL.md` and `sculpted_terrain.gd` changed minutes before this list was written. Finish or close one session, commit everything left over, and confirm nothing is loose (for example the `Bandit_Sword.glb` import note in ZONE1_OVERHAUL).
- [x] **CC: Run every check plus the 3-player check.** The last "all pass" note is from before the equipment system, the chapel and barrow, and the terrain cache. Run them one at a time (they share port 31499).
- [x] **CC: Merge the to-do docs into one.** `TODO.md`, `NEXT_STEPS.md`, the "Next up" part of `HANDOFF.md` and the stages in `ZONE1_OVERHAUL.md` overlap and contradict each other. Every new session reads them, so stale lines send it the wrong way. What's stale now:
  - TODO Phase 14 is still marked 🚧, and "Gold renamed to coins" is unticked. Both are done.
  - NEXT_STEPS lists "terrain bake cache" (done today) and says the chapel builder is uncommitted (it was committed 11-21).
  - ZONE1_OVERHAUL's header says "hold the chapel and barrow sites empty". They're built.
  - HANDOFF says "Audio is not started" and also "Phase 10 (audio): built". Its phase table still calls the Tithelands gray-block.

  Suggestion: keep `TODO.md` as the single checklist, make HANDOFF a one-screen "where we are" note, and retire NEXT_STEPS into this file.

## P1: Reach the milestone (this is the real goal)

- [x] **You: Answer the scale question now** ("make doors, corridors and props bigger against the player?"). *Decided 2026-11-25: new buildings are 1.3x real-world size (doors about 1.4 x 2.6 m); props and furniture stay real-world. You compared both sizes of the outpost cottage and left the pick to Claude Code (DESIGN.md 12.1, OUTPOST_PLAN.md). Still open: resize the Tithelands' existing buildings to match (P2).*
- [x] **CC: Get the frame rate playable.** *(Done 2026-11-22: worst of the 10 spots 45 -> 72 FPS at 1920x1080 via terrain LODs, size-based prop draw distance and a shadow budget for point lights; tree LODs not needed, trees already batch and cull at 175 m. Measure again with `tests/perf_zone.gd`.)* Original note: The audit measured 22–28 FPS at the spawn and the farms. Hiding the underground Gullet has helped since then, but trees still have no distance versions (LODs). Trees, shrubs and boulders cost 1.5–4 M primitives in busy views, and the zone takes 8.7 s to load. Target 60 FPS at the spawn. Measure at the 10 fixed spots from ZONE1_OVERHAUL stage 7. Friends' PCs may be slower than yours.
- [x] **CC: Re-export the friends build** *(2026-11-22, 176 MB)* (`build/Kingdom-windows.zip`). The current one is from before the camp, the environment pass, the new Gullet and the equipment system.
- [ ] **You: The playtest round, solo.** In this order:
  1. Gullet from the camp to Harl (aim for about 10 minutes)
  2. A death-and-recover run
  3. The nine class abilities
  4. A camp raid (F5 / F7)
  5. Tithelands with sound on
  6. Settings and rebinding
  7. The new inventory screen (I): drag, turn, sort, junk, tabs (added 2026-11-23)

  Note what's too loud, too hard, too empty or broken. All 15 🧪 lines are in `TODO.md`.
- [ ] **CC: Fix what the playtest finds.** Nothing new until those are fixed.
- [ ] **You + CC: Tune for 3 players.** Harl and Captain health and damage, add counts, raid length. Every number is still a first guess.
- [ ] **You: Milestone run.** 3 friends clear the Tithelands and the Gullet over the internet.

## P2: Decisions only you can make (they block content, not code)

- [x] **Souls for the Gullet enemies** (2026-11-22, still tunable in `data/loot/loot_bandit*.tres`, `loot_harl.tres`): Bandit 8-16, Captain 40-70, Rook 60-90, Harl 250-350 (a Marauder gives 10-20, Hobb 120-200). XP was already set: Bandit 90, Captain 400, Rook 300, Harl 1200.
- [x] **Cryptic descriptions** already exist as drafts and are in the item files (`flavor =`). Change any you don't like: Steel Pickaxe "A miner's tool that learned a second trade." · Blackstone Amulet "A chip of the black stone on a leather cord. It never quite reaches room temperature." · Harl's Black Pick "The head is cut from the stone itself, and it is warm." · Bread "Hard, but it is food." · Health Potion "Tastes of iron and bad decisions."
- [x] Harl's unique weapon stays **Harl's Black Pick** (decided 2026-11-22). [ ] Still open: rename "Rook the Cutthroat" (`data/enemies/enemy_bandit_rook.tres`).
- [ ] The open questions in `DESIGN.md` section 14.
- [ ] Resize the Tithelands' existing buildings (cottages, tithe barn, mill, chapel, watchtower) to 1.3x so they match the outpost? (2026-11-25)
- [x] Chapel and barrow: **used later** (decided 2026-11-22), nothing to build now.
- [x] Brother Tallow and the acolytes: **keep** (decided 2026-11-22; for a later zone).
- [ ] Class abilities: you will change these later (the 🧪 ability lines in `TODO.md` are ticked as played).

## P3: Overhauls under the hood (after the milestone, with the checks as a safety net)

- [ ] **Split `player.gd`.** It's 2,273 lines and 148 functions in one file: movement, combat, abilities, gear, network and debug. Split it into parts (movement, combat, abilities, equipment). Then `enemy.gd` (1,211 lines), `gullet.gd` (1,726) and `hud.gd` (848). Smaller files also stop two sessions from colliding in the same file.
- [x] **Safer saves** *(done 2026-11-22, `tests/save_check.gd`)* (`game/core/save_system.gd`). It deletes the old save *before* renaming the new one into place. A crash between those two steps leaves only a `.tmp` file, which loading ignores, so the character looks gone. Fix: keep a `.bak` copy, or read the `.tmp` as a fallback.
- [x] **Saves for similar names.** *(done 2026-11-22)* "Bob!" and "Bob?" save to the same file and overwrite each other.
- [ ] **Network trust.** There are 24 network messages any player can send. The host accepts item data straight from a player: dropped items and death-pile contents come from the client. That's fine among friends. It must be fixed before any server browser or playing with strangers.
- [ ] **Gamepad.** Not tested at all (TODO Phase 2).
- [ ] **Strafe "moonwalk" when locked on.** Still unchecked.

## P4: Content and art (after the milestone)

- [x] **White Knight character** *(2026-11-25)*: built from the owner's sheet, `assets/characters/white_knight/` (see HANDOFF). The White Knight Zealot wears it, with a red-cross shield. Open: a sword and scabbard, a helmless/hooded variant and the fur-cloak variant from the sheet are not made.
- [ ] **Art pipeline test.** Take one bandit from AI concept to a rigged model on the standard skeleton (`ART_NEEDS.md`, `GULLET_DESIGN.md` section 10). The world now looks detailed, but every character is still a mannequin. That's the biggest visual gap left.
- [ ] Tithelands polish: judge the foliage fade in a dense wood, add a mill race for the wheel, make the weir crossing readable, LODs for distant trees.
- [ ] Gullet look pass 2: only if you're not happy with pass 1.
- [ ] Harl extras: charge-in, sweep-into-backhand, pick throw.
- [ ] **A quest system.** It's in the spec, and subclass initiation (Phase 11 P6) needs it. So does the outpost: its White Knights start hostile, and a quest or storyline can win them over and open the outpost (decided 2026-11-25, OUTPOST_PLAN.md).
- [ ] Subclasses: 6 of 9 are still "coming later" (Paladin, Mage, Rogue, Ranger, Warlock, Warden), plus the factions.
- [ ] **White Knights Outpost** (`OUTPOST_PLAN.md`, started 2026-11-25 at the owner's request; it replaces the Knight's Gap checkpoint). Stages 1-2 done (the White Knights set and the checkpoint: 29 assets, on `main`). Stages 1-3 done: the White Knights set, the checkpoint and all ten buildings. Next: stage 4, the trade and village props. Owner decisions in OUTPOST_PLAN.md section 7 (scale, who lives there, moving the castle closer).
- [ ] Zones 2 and 3 (`ZONES_DESIGN.md`), then a walkable Highcrown.
- [ ] **The long gap:** the spec says level cap 30 and about 30 hours of play. Content now covers about levels 1–6. Plan zones and loot tiers against that.
