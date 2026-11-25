# KINGDOM — Milestone & Progression Roadmap

*Created 2026-11-23 from the current repository state. This roadmap organizes existing work and proposed future milestones; it does not silently approve new game systems or replace the owner's original brief.*

## How to read this roadmap

- **BUILT** = present in the project according to the current `HANDOFF.md`, `TODO.md`, and design files. It may still need hands-on playtesting.
- **NEXT / GATE** = the current work that must happen before expanding content.
- **PLANNED (draft)** = described in a design document but not implemented or finally approved.
- **IDEA — NOT DECIDED YET** = a possible future system, not a commitment.

The execution order remains controlled by `PRIORITIES.md`. The phase checklist remains in `TODO.md`. This file is the long-range milestone and player-progression view.

---

## 1. Current project status

### Built foundation

According to `HANDOFF.md` updated 2026-11-23:

- Godot 4.7.2, GDScript, host-and-play co-op for 1–10 players.
- Phases 1–15 built: movement, combat, multiplayer, classes and talents, loot and death, Tithelands, Gullet, camp and raids, audio, settings/rebinding, equipment, subclasses foundation, and environment work.
- The Tithelands / Greenwood environment overhaul is merged into `main`; automated checks and the 3-player automated check pass.
- Combat has received a deliberate timing pass: deflects, enemy balance, guard punishments, perfect-dodge counters, and clearer audio feedback.
- The shared camp can be claimed and upgraded; night raids and raid rewards exist.
- The Gullet is the first dungeon, designed for levels 3–6 and roughly a 10-minute clean run.

### Current gaps

- The first real owner-led milestone has **not** been completed: three friends clearing the Tithelands and Gullet together over the internet.
- The owner has not yet completed the current solo playtest round.
- Current playable content is estimated in `PRIORITIES.md` at roughly levels 1–6, while the original target is level 30 and about 30 hours.
- Characters are still mannequin placeholders. A production character-art pipeline has not yet been proven.
- Six of the nine planned subclasses are still future work; quest systems and later zones are not built.
- Harl, the Captain, camp raid numbers and Gullet tuning are first guesses pending playtests.
- Gamepad support is specified but has not been manually tested.
- Network trust hardening is required before public servers or play with strangers.

**The immediate objective is not to add more features. It is to prove the current game is enjoyable, stable, readable, and reliable with real players.**

---

## 2. Milestone sequence

### M0 — Playable foundation and first co-op proof
**Status: BUILT SYSTEMS / OWNER PLAYTEST GATE OPEN**

Purpose: prove the existing 1–6 experience before expanding it.

Work:
1. Owner completes the solo playtest sequence in `PRIORITIES.md`: Gullet to Harl, death and recovery, class abilities, camp raid, Tithelands with sound, settings and rebinding.
2. Record each issue as reproducible: location, action, expected result, actual result, severity.
3. Fix blockers and serious balance, readability, audio, performance, save, and multiplayer defects.
4. Tune Harl, Captain, add counts, raid length, and encounter pacing for three players.
5. Re-export the friends build after fixes.
6. Run a real three-friend internet session.

**Exit criteria**
- Three friends can join reliably.
- All three can travel through the Tithelands and complete the Gullet.
- Death, revival, loot rolls, death-pile recovery, shrine rest, and boss progression work correctly in co-op.
- No progression-breaking or save-loss bugs.
- The owner confirms the first-session experience is fun enough to continue.

Do not begin major new content until this gate is passed, unless a small change is necessary to unblock it.

### M1 — Character and visual identity foundation
**Status: PLANNED; HIGH VISUAL PRIORITY AFTER M0**

Purpose: replace mannequin presentation without breaking animation or equipment systems.

Work:
- Prove one complete male Outcast and one female Outcast on the existing UAL1 skeleton standard.
- Preserve the established classic MMORPG look: chunky readable forms, hand-painted textures, muted colors, dark medieval mood.
- Build modular clothing and equipment attachment standards.
- Prove animation retargeting, weapon grip, armor fit, and multiplayer appearance synchronization.
- Complete one bandit model using the same pipeline before scaling to the full roster.
- Establish matching visual standards for White Knights, Dark Ages, Outcasts, enemies, and NPCs.

**Exit criteria**
- One production-quality playable character passes locomotion, combat, hit reactions, death, and equipment tests.
- Modular clothing can be swapped without major clipping.
- The art pipeline is repeatable and documented.
- Character art matches the Tithelands environment rather than looking like a different game.

### M2 — Core character progression and build identity
**Status: PARTLY BUILT / SUBCLASS PLAN NOT COMPLETE**

Purpose: make a character's development meaningful from level 1 to the level-10 specialization choice and beyond.

Current foundation:
- Three primary classes are implemented under the current provisional names Martial, Vanguard, and Mystic.
- Their first abilities unlock at levels 2, 4, and 6.
- Talents, gear, stats, XP, and character saves exist.

Planned direction in `CLASS_PLAN.md`:
- Levels 1–9: develop the primary class; no subclass-exclusive abilities.
- Level 10: choose one of three subclasses for the chosen primary class.
- Level 10+: subclass abilities, passives, weapon specialties, and advanced build options.
- Faction ties remain separate from class choice; factions must not gate class or subclass selection.
- Build unique subclass mechanics one at a time, beginning with Guardian, Warrior, and Cleric where existing mechanics can be reused.

**Progression principles**
- A level should grant a clear, understandable improvement.
- New abilities should change decisions or playstyle, not merely add passive numbers.
- Weapons and equipment should create viable alternatives, not one mandatory best build.
- Keep Martial and Vanguard viable as physical fighters throughout progression.
- Magic should become more present gradually as the world darkens.

**Open design decisions remain in `CLASS_PLAN.md`**. Do not treat the subclass initiation method, final class display names, talent placement, or every subclass ability as finalized.

### M3 — Zone 2: Highcrown
**Status: PLANNED DRAFT — NOT BUILT**

The repository calls the city **Highcrown**. “Camelot” has appeared in concept-art discussion, but is not the current repository location name.

The draft in `ZONES_DESIGN.md` proposes:
- Target levels 6–11; Reliquary dungeon levels 9–12.
- A White Knight-controlled city on a granite spur.
- A hostile Lower Town shaped by the Cleansing, with the Upper Ward and cathedral districts.
- Mudside, the Lees, Sluice and Culverts, Crown Gorge, Lower Town, Bleachery, Charnel Pits, Upper Ward, Crown Crag, Hill of Tabards, Pilgrim Stair, the Cutting, Crownpool, and Upland.
- The Reliquary beneath the cathedral, exposing the White Knights' secret use of blackstone.
- White Knight patrols, Cleansers, Bell-ringers, Inquisitors, and related encounters.

**Design gates before building**
- Decide whether any safe/neutral Upper Ward exists for Outcasts.
- Approve the zone's route, city hostility, and dungeon boss.
- Confirm scale and connection to the Tithelands.
- Keep the White Knights visually consistent: off-white, tarnished gold, red cross, chainmail, disciplined and oppressive.
- Preserve the dark, dangerous, sad tone. This is not a bright heroic capital.

**Exit criteria**
- A complete playable zone with a readable route, optional exploration, shrines, shortcuts, faction encounters, and one complete dungeon.
- Content supports the proposed level band without relying on inflated enemy health.

### M4 — Zone 3: The Barrow Fells
**Status: PLANNED DRAFT — NOT BUILT**

The draft in `ZONES_DESIGN.md` proposes:
- Target levels 11–17; Cinderhold dungeon levels 15–18.
- A wind-scoured high moor, barrows, bog, mountain lake, petrified Ashwood, the Rive chasm, and Cinderhold.
- The first open display of Dark Ages sorcery and the first undead.
- A darker escalation from the human conflicts of the Tithelands and Highcrown toward the older blackstone threat.

**Design gates**
- Confirm the first-undead timing and death/shrine lore.
- Approve Cinderhold and its boss before production.
- Keep the Dark Ages visually distinct from White Knights and Outcasts.
- Make exploration routes and dangerous open terrain support meaningful choices.

**Exit criteria**
- A complete zone and dungeon with a new enemy family, a distinct boss, optional routes, secrets, and a clear narrative escalation.

### M5 — Levels 18–30 and the full first campaign
**Status: IDEA / NOT YET DESIGNED TO THE SAME DETAIL**

The original target is level 30 and approximately 30 hours. The current three-zone draft only maps progression through roughly level 17. The remaining campaign must be designed before promising a 30-hour experience.

Required planning:
- Define the level bands, regions, dungeons, bosses, enemy families, and loot tiers for levels 18–30.
- Decide how many additional zones are needed based on actual playtime and encounter density.
- Create a clear campaign escalation from grounded human conflict to the older supernatural threat.
- Avoid stretching existing content through repetitive enemy scaling.

**Exit criteria**
- Every level band has a meaningful place to explore, a progression purpose, and appropriate equipment rewards.
- The full campaign reaches level 30 through varied play, not repetitive grinding.

### M6 — Quests, factions, and world persistence
**Status: PARTLY PLANNED / QUEST SYSTEM NOT BUILT**

Work:
- Build a quest framework that supports short objectives, multi-step story threads, discovery, and repeatable public events.
- Add subclass initiation events once the quest framework supports them.
- Expand the White Knights, Dark Ages, and Outcasts as world powers with distinct motives, visual language, and consequences.
- Keep faction affiliation separate from class mechanics.
- Expand persistent world and camp progression only where it adds meaningful play.

**Exit criteria**
- Quests can be started, progressed, completed, saved, and synchronized in co-op.
- Players can understand objectives without turning the world into a checklist.
- Faction content adds choices and world context without forcing a faction/class pairing.

### M7 — Endgame, replayability, and long-term legacy
**Status: IDEA — NOT DECIDED YET**

Potential systems, subject to design approval:
- Optional high-difficulty dungeon variants and boss challenges.
- Rare enemy hunts and rotating world encounters.
- Build experimentation and alternate character progression.
- Collection goals: equipment appearances, trophies, titles, and discoveries.
- Expanded shared camp identity and cosmetic development.
- New Game+ or equivalent replay mode.
- World bosses and faction-scale events.

**Principles**
- No mandatory daily chores, food timers, upkeep, or punishment for taking a break.
- Do not rely on an endless vertical gear treadmill.
- Make short sessions rewarding and longer sessions meaningfully productive.
- Keep replayability rooted in different builds, routes, secrets, encounter variations, and challenge—not simply inflated enemy health.

---

## 3. Player progression map

The following is a planning map based on current repository targets. Zone 2 and 3 levels are draft proposals, not approved final balance.

| Character band | Current / proposed content | Player development |
|---|---|---|
| 1–2 | Tithelands opening | Learn movement, basic combat, survival and class identity |
| 3–6 | Gullet and Tithelands | First dungeon, first boss, gear and death-recovery loop |
| 6–9 | Highcrown draft | Stronger encounters, faction pressure, broaden build choices |
| 10 | Subclass choice planned | Commit to a combat specialization |
| 11–14 | Highcrown / Barrow Fells drafts | Develop subclass identity and advanced encounters |
| 15–18 | Cinderhold draft | First major supernatural escalation and dungeon challenge |
| 19–30 | Not designed yet | Further campaign, loot tiers, bosses and mastery progression |

### Gear progression

Existing loot framework:
- Common: white.
- Uncommon: green.
- Rare: blue, one random bonus.
- Epic: purple, two random bonuses.
- Legendary: orange, two bonuses plus a unique effect.

Planning rules:
- Give each new zone a reason to introduce or remix equipment.
- Make rare drops desirable because of identity, effects, and build synergy—not only item level.
- Keep older weapons viable when their moveset or bonuses suit a build.
- Make boss uniques memorable and thematically tied to the encounter.
- Do not finalize future loot tiers until zone and level pacing are playtested.

### Camp progression

Built now:
- Shared world camp claim.
- Palisade, Watchfires, and Stores upgrades.
- Night raids, camp strength, and raid rewards.

Later ideas already listed in `TODO.md`:
- Camp NPCs and a vendor.
- Repairable palisade damage.
- More raid types and siege encounters.
- Camp level on the map.

**IDEA — NOT DECIDED YET:** trophy hall, displayed boss trophies, camp legacy records, cosmetic structures, and additional settlement stages. These should not become mandatory upkeep systems.

---

## 4. Quality gates for every milestone

Every milestone must pass all relevant gates before it is marked complete:

1. **Playable:** a player can experience the feature in the actual game, not only in a test scene.
2. **Co-op safe:** host and clients see consistent outcomes; test with at least three players when multiplayer is affected.
3. **Save safe:** progress survives quit/reload and world/character ownership is correct.
4. **Readable:** animations, telegraphs, UI, environment navigation, and rewards communicate clearly.
5. **Balanced:** numbers are playtested; guesses are labeled as guesses.
6. **Performant:** measure at fixed viewpoints and on a friend-class PC where possible.
7. **Art consistent:** hand-painted classic MMORPG style, bleak medieval mood, original designs.
8. **Documented:** update the owning design/checklist file and `HANDOFF.md`; keep `PRIORITIES.md` as the single next-action list.

---

## 5. Current next actions

Follow `PRIORITIES.md` in this order:

1. ~~Owner decides the outstanding world scale question before more environment art.~~ Decided 2026-11-25: buildings 1.3x real-world size, props real-world (DESIGN.md 12.1).
2. Owner completes the solo playtest round in `PRIORITIES.md` and the 🧪 items in `TODO.md`.
3. Claude Code fixes issues found; do not add unrelated content during stabilization.
4. Tune the Gullet and camp for three players.
5. Complete the real three-friend Tithelands + Gullet milestone.
6. Only then start the character art pipeline test and broader content work.

### Working rule

One active implementation area at a time. Inspect the current repository before editing. Preserve the original `SPEC.md`. Ask before changing established design. Mark unresolved proposals exactly **idea, not decided yet**. Do not claim a milestone is complete until its exit criteria have been tested.
