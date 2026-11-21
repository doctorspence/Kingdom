# NEXT STEPS: easy first, complex later

*Made 2026-11-21 from the Gullet design session. This is a working list, separate from `TODO.md`. Tick things off as you go. Who does it: **You** (no code), **CC** (Claude Code in this folder), **Chat** (planning with Claude here).*

Effort: 🟢 easy (an hour or less) · 🟡 medium (a session with Claude Code, then playtest) · 🔴 complex (several sessions, or risky)

---

## 1. Do these first (🟢 easy, no new code)

- [ ] **You:** Play the tests you already owe. Nothing to build, and bugs hide here: the nine new class abilities, the extra attacks and enemy spacing, the Tithelands with sound on, and a death-and-recover run (see the 🧪 lines in `TODO.md`).
- [ ] **CC:** Commit your own editor tuning that was never committed (class files, weapon files, `overcast_env.tres`, `look_test.tscn`; see `HANDOFF.md`). Do this before any new building, so you can roll back.
- [ ] **CC:** Update `DESIGN.md` and `TODO.md` so they describe the new Gullet (`GULLET_DESIGN.md`) and not Brother Tallow. Docs only.
- [ ] **You:** Name the boss's unique weapon and decide what it is (a mining tool changed by the stone, per the design). Also name the named rare Bandit. Names unblock the data files and later the art.
- [ ] **You or Chat:** Write the one-line cryptic descriptions for the new items: pickaxe, Blackstone amulet, the unique weapon, bread, the health potion. Text only, and it is the fun part.
- [ ] **You:** Decide the souls and XP amounts for the Gullet's enemies (small numbers; we can tune later).
- [ ] **You:** Decide the small open questions from `DESIGN.md` section 14 that block nothing but are easy to settle: death lore, flask upgrades, what else souls can buy.
- [ ] **You (with permission):** Let CC download CC0 cave textures (rock, wood, dirt) from Poly Haven and ambientCG, and log them in `assets/CREDITS.md`. Biggest look upgrade for the least risk.
- [ ] **You:** Collect a few reference images for the look (cave mine, bandit outlaws, the black stone) for the AI-art step later. Keep them out of the game folder.

---

## 2. Build the new Gullet (🟡 medium, one step at a time, playtest between steps)

Suggested order. Each step ends with the automated checks passing and you playing it.

- [ ] **CC:** The loot code: confirm it can roll "1 in 128" style odds; adjust if not. Then add the loot tables from `GULLET_DESIGN.md` section 5 as data files.
- [ ] **CC:** The new graybox layout from `GULLET_MAP.svg` (six areas, two two-story rooms, rope bridge, stairs and ladders, the halfway shrine, the fog gate).
- [ ] **CC:** Bandit enemy data (sword and pick versions, reskinned from existing enemies), with the 3+ player extras.
- [ ] **CC:** The caller bandit in the camp, the patrol routes, and the Captain (reuses the existing shield, block, shield bash and unblockable attack).
- [ ] **CC:** Food and potions: small consumables that heal less than a flask.
- [ ] **CC:** New weapon data: iron dagger and steel pickaxe (plus bronze, iron and steel sword and shield tiers) mapped to Common and Uncommon.
- [ ] **CC:** Hidden chest (refills on rest) and the barricade shortcut (reuses the existing shortcut gate).
- [ ] **CC:** The named rare Bandit spawn (about 5%).
- [ ] **CC:** Rename "gold" to **coins** in code, data, saves and docs. Search-and-replace plus a save check; do it as its own step.
- [ ] **You:** Playtest the whole new dungeon with a friend. Tune timing toward about 10 minutes.

---

## 3. Audio finish (🟡 medium, Phase 10 steps 4 to 7)

- [ ] **CC:** Loot sounds (one per rarity), shrine rest sound, death sound.
- [ ] **CC:** Tithelands ambience and music; the Gullet's cave ambience and a boss track.
- [ ] **CC:** Enemy sounds (the bandit shout, bows, barrel explosion) and re-export the friends build.
- [ ] **You:** Walk the zone with sound on and tell CC what is too loud, repetitive or missing.

---

## 4. Harder pieces (🔴 complex, do after the first Gullet playtest)

- [ ] **CC:** Enemy archers: a visible flying arrow and keep-your-distance behavior (first version can reuse the long-reach cone attack like Tallow's wax spit).
- [ ] **CC:** Powder barrels: an object that explodes when hit by a swing or an arrow and damages everyone near it.
- [ ] **CC:** Harl the Delver: the five phase 1 moves, the phase 2 transition and Desperate Assault, Black Shard, and the Corrupted Grip buff (the one mechanic that is new).
- [ ] **CC (optional, after you play him):** The three Souls-style additions: charge-in, sweep-into-backhand, and a pick throw in phase 2.
- [ ] **CC and You:** Check whether the old strafe animation problem (sideways "moonwalk" when locked on) is still there; fix if so.

---

## 5. Bigger projects (🔴 later)

- [ ] **Milestone:** 3 friends clear the Tithelands and the new Gullet.
- [ ] **Chat then CC:** Subclasses and factions (Phase 11, `CLASS_PLAN.md`), starting with the foundations (Priority 1).
- [ ] **You and CC:** Art pipeline test: take one bandit from AI concept to a 3D model fitted to the standard skeleton and running in the game. Then the Gullet art slice (`GULLET_DESIGN.md` section 10).
- [ ] **Later list:** the camp that enemies raid at night, quests, more zones, more races and magic, world bosses, New Game+, a server browser (maybe Steam), PvP, dismemberment, key rebinding.
- [ ] **Much later:** an optional endgame mode built from the Gullet's modular pieces, or rotating dungeon modifiers, for more replay.
