# KINGDOM: priority checklist

*Started 2026-11-22 from a read-through of the project: docs, git history, and the main code files. I didn't run the game or the checks for this.*

**The short version:** you've built a huge amount in about 48 hours (100+ commits, Phases 1 to 15). But there are **15 open 🧪 playtest items**. The milestone in `SPEC.md` (3 friends clear the zone and the dungeon) has not happened yet. The friends build is several big changes out of date. Most recent sessions went into art passes. The best next move is to **stop adding, stabilize, and play.**

Who does it: **You** (no code) · **CC** (Claude Code in this folder)

---

## P0: Stabilize first (small, do these before anything new)

- [ ] **CC: Lock the test shortcuts out of the friends build.** PageUp (level up), PageDown, the reset key and the gear-cycle key work for *any* player in the exported game (`game/player/player.gd`, around line 1138). A friend can jump to max level and skip all progression. Make them work only in the editor (`OS.is_debug_build()`), and do the same for F5/F6/F7 (time, rain, raid).
- [ ] **CC: One session per area, and a clean `git status`.** Two Claude sessions have been editing in parallel (HANDOFF warns that "another session owns gullet.gd"). `ZONE1_OVERHAUL.md` and `sculpted_terrain.gd` changed minutes before this list was written. Finish or close one session, commit everything left over, and confirm nothing is loose (for example the `Bandit_Sword.glb` import note in ZONE1_OVERHAUL).
- [ ] **CC: Run every check plus the 3-player check.** The last "all pass" note is from before the equipment system, the chapel and barrow, and the terrain cache. Run them one at a time (they share port 31499).
- [ ] **CC: Merge the to-do docs into one.** `TODO.md`, `NEXT_STEPS.md`, the "Next up" part of `HANDOFF.md` and the stages in `ZONE1_OVERHAUL.md` overlap and contradict each other. Every new session reads them, so stale lines send it the wrong way. What's stale now:
  - TODO Phase 14 is still marked 🚧, and "Gold renamed to coins" is unticked. Both are done.
  - NEXT_STEPS lists "terrain bake cache" (done today) and says the chapel builder is uncommitted (it was committed 11-21).
  - ZONE1_OVERHAUL's header says "hold the chapel and barrow sites empty". They're built.
  - HANDOFF says "Audio is not started" and also "Phase 10 (audio): built". Its phase table still calls the Tithelands gray-block.

  Suggestion: keep `TODO.md` as the single checklist, make HANDOFF a one-screen "where we are" note, and retire NEXT_STEPS into this file.

## P1: Reach the milestone (this is the real goal)

- [ ] **You: Answer the scale question now** ("make doors, corridors and props bigger against the player?"). Every new building and cave pass makes changing scale more expensive. Decide before more art.
- [ ] **CC: Get the frame rate playable.** The audit measured 22–28 FPS at the spawn and the farms. Hiding the underground Gullet has helped since then, but trees still have no distance versions (LODs). Trees, shrubs and boulders cost 1.5–4 M primitives in busy views, and the zone takes 8.7 s to load. Target 60 FPS at the spawn. Measure at the 10 fixed spots from ZONE1_OVERHAUL stage 7. Friends' PCs may be slower than yours.
- [ ] **CC: Re-export the friends build** (`build/Kingdom-windows.zip`). The current one is from before the camp, the environment pass, the new Gullet and the equipment system.
- [ ] **You: The playtest round, solo.** In this order:
  1. Gullet from the camp to Harl (aim for about 10 minutes)
  2. A death-and-recover run
  3. The nine class abilities
  4. A camp raid (F5 / F7)
  5. Tithelands with sound on
  6. Settings and rebinding

  Note what's too loud, too hard, too empty or broken. All 15 🧪 lines are in `TODO.md`.
- [ ] **CC: Fix what the playtest finds.** Nothing new until those are fixed.
- [ ] **You + CC: Tune for 3 players.** Harl and Captain health and damage, add counts, raid length. Every number is still a first guess.
- [ ] **You: Milestone run.** 3 friends clear the Tithelands and the Gullet over the internet.

## P2: Decisions only you can make (they block content, not code)

- [ ] Name Harl's unique weapon and the named rare bandit ("Rook the Cutthroat" is a placeholder).
- [ ] One-line cryptic descriptions for the pickaxe, Blackstone amulet, Black Pick, bread and potion.
- [ ] Souls and XP for the Gullet enemies (rough numbers, tune later).
- [ ] The open questions in `DESIGN.md` section 14.
- [ ] What the chapel and barrow are *for*. They're built but there's nothing to do there.
- [ ] Brother Tallow and the acolytes: keep them for a later zone, or delete them? (They're unused data, spawn tables and tests.)

## P3: Overhauls under the hood (after the milestone, with the checks as a safety net)

- [ ] **Split `player.gd`.** It's 2,273 lines and 148 functions in one file: movement, combat, abilities, gear, network and debug. Split it into parts (movement, combat, abilities, equipment). Then `enemy.gd` (1,211 lines), `gullet.gd` (1,726) and `hud.gd` (848). Smaller files also stop two sessions from colliding in the same file.
- [ ] **Safer saves** (`game/core/save_system.gd`). It deletes the old save *before* renaming the new one into place. A crash between those two steps leaves only a `.tmp` file, which loading ignores, so the character looks gone. Fix: keep a `.bak` copy, or read the `.tmp` as a fallback.
- [ ] **Saves for similar names.** "Bob!" and "Bob?" save to the same file and overwrite each other.
- [ ] **Network trust.** There are 24 network messages any player can send. The host accepts item data straight from a player: dropped items and death-pile contents come from the client. That's fine among friends. It must be fixed before any server browser or playing with strangers.
- [ ] **Gamepad.** Not tested at all (TODO Phase 2).
- [ ] **Strafe "moonwalk" when locked on.** Still unchecked.

## P4: Content and art (after the milestone)

- [ ] **Art pipeline test.** Take one bandit from AI concept to a rigged model on the standard skeleton (`ART_NEEDS.md`, `GULLET_DESIGN.md` section 10). The world now looks detailed, but every character is still a mannequin. That's the biggest visual gap left.
- [ ] Tithelands polish: judge the foliage fade in a dense wood, add a mill race for the wheel, make the weir crossing readable, LODs for distant trees.
- [ ] Gullet look pass 2: only if you're not happy with pass 1.
- [ ] Harl extras: charge-in, sweep-into-backhand, pick throw.
- [ ] **A quest system.** It's in the spec, and subclass initiation (Phase 11 P6) needs it.
- [ ] Subclasses: 6 of 9 are still "coming later" (Paladin, Mage, Rogue, Ranger, Warlock, Warden), plus the factions.
- [ ] Zones 2 and 3 (`ZONES_DESIGN.md`), then a walkable Highcrown.
- [ ] **The long gap:** the spec says level cap 30 and about 30 hours of play. Content now covers about levels 1–6. Plan zones and loot tiers against that.
