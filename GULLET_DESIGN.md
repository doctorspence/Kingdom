# THE GULLET: Dungeon Design (working draft)

*Started 2026-11-21. Built up one aspect at a time with the designer. This replaces the old Gullet (candle-monk cave, Brother Tallow) described in `DESIGN.md` sections 8.6 and 11.2 once approved. `DESIGN.md` and `TODO.md` are not changed yet.*

The matching floor plan with legend and enemy positions is the "The Gullet: Dungeon Map" page on claude.ai. Enemy numbers (#1 to #19) below match that map.

---

## 1. Decisions so far

| Topic | Decision |
|---|---|
| Role | The first dungeon, in the Tithelands (zone 1). Level 3 to 6. |
| Length | About 10 minutes for a clean run, with fighting and no deaths. |
| Shape | Tight, slightly winding corridors that open into bigger fight rooms, plus two large two-story areas. |
| Shrine | **Halfway** through, in a side alcove off the Bandit Camp's south wall (the 5-minute mark). Resting there respawns the dungeon and the boss. |
| Story | An abandoned quarry occupied by desperate outlaws, who dug into a sealed passage and found a black stone. Travelers vanish on the forest road. Full text lives in the designer's brief (`THE GULLET` attachment). |
| Factions | The boss is **not** a Dark Ages member. He is an ordinary man changed by the stone, which shows forbidden power existed before either faction claimed it. |
| Boss name | **Harl the Delver** (working name; the designer doesn't mind it changing). A rough bandit nickname, since these are bandits raiding the quarry for supplies. Not "Foreman" or any job title. |
| Look | Narrow rough rock, wooden supports, carts, ropes, picks. Torches and campfires are the light: warm orange with deep shadow. No glowing crystals. Bandits look like ordinary medieval outlaws. The last chamber is an accidental discovery, not a built arena. |
| Healing | Flasks stay the main heal. Food and potions are small extra heals (start values: bread 10%, cooked meat 20%, health potion 25% of max health; a flask is 40%). Eating takes about 1.5 s and you can be hit mid-bite. |
| Gear tiers | Bronze and iron are Common (white). Steel is Uncommon (green). Chase items are Rare (blue) or Epic (purple). |
| New weapon types | Iron dagger = a fast sword-type weapon. Steel pickaxe = a mace or axe type with mining flavor. |
| River | A small stream runs through both two-story areas (the camp and the Excavation): a shallow wade that slows movement a little. Added 2026-11-21 |
| Old Gullet | Brother Tallow, the acolytes and their files are kept as unused, hidden data (decided 2026-11-21) |
| Group loot | Shared need/greed stays for everything, including the rare drops. No personal rolls. |
| Replay | The dungeon is meant to be run again and again for the rare drops. Hazards are learnable, never random. No bad-luck protection for now. |
| Currency | "Gold" is renamed **coins** everywhere. Souls stay as the second currency and drop as a small automatic amount on top of the tables below. The rename touches code, data, saves and docs and is **not done yet**; do it after the dungeon design is finished. |

---

## 2. Layout and pacing

| # | Area | Shape | Target time |
|---|---|---|---|
| 1 | Entrance Yard | Small yard at the quarry mouth: broken barricades, carts, smoke through cracks in the rock | 1:00 |
| 2 | Old Tunnels | Tight winding corridors with wooden supports. Side nook for the ambush. Secret wall to the hidden chest | 2:00 |
| 3 | Bandit Camp | Large **two-story** room: ground floor around a campfire, upper scaffold walkway along the north side. West stairs, east ladder, rope bridge east to the Excavation | 2:00 |
| 4 | Shrine | Small quiet alcove off the camp's south wall. Rest, bank, travel. A side stop, not on the main route | 0:30 |
| 5 | The Excavation | Large open **two-story** room: broken-through wall, scaffolding, the strange stone formation, black mineral veins. North gallery and west gallery above, ladder at the gallery's east end. The Captain guards the exit | 2:00 |
| 6 | Deep Chamber | Long approach corridor and a fog gate, then a larger chamber with unnaturally smooth walls, the exposed black stone, and the boss | 2:30 |

- **Shortcuts:** after the first boss kill, a corridor opens from the Deep Chamber back to the Entrance Yard (closed until then). A **barricade** in the Old Tunnels is lifted from the far (camp) side and gives a short path from the long hall straight to the camp, skipping the western loop (the second patrol pair and the hidden chest route).
- **Farming loop:** from the halfway shrine, a boss attempt is about 5 minutes (Excavation, approach, boss). A full run from the entrance is about 10.
- **The way in (2026-11-23):** there is no door. The quarry's timber-framed adit leads straight into a hewn incline (`game/world/quarry_descent.gd`): about 130 m of ramp with timber cleats, oak frames and lanterns, three corners with flat landings, 52 m down from the quarry floor to the Entrance Yard, which it enters through a doorway in the yard's west wall. The light fades in with distance along the tunnel (`QuarryDescent.depth_cave`, read by `DayNight.cave`, the cave sounds, the player's lantern and the level-of-detail switch), so daylight, ambient light and sound change gradually instead of at a height. The old teleport doors (`CaveDoor`, "Descend" and "Climb out") are kept but disabled.
- **Route options:** the camp's upper walkway links over the rope bridge to the Excavation's north and west galleries, so players can skip part of the ground fight at the cost of facing archers.

---

## 3. Encounters

Rules from `DESIGN.md` still apply: at most 2 enemies attack one player at a time, enemies sense by sight cone and by hearing (sprinting and fighting double the hearing range), and extra players add health and adds.

| Area | Who | Behavior | What it teaches |
|---|---|---|---|
| 1 Entrance Yard | #1 Bandit (sword), #2 Bandit (pick) | On watch, unaware at the start. Can be pulled one at a time by sound. | Pulling, and the 2-attackers rule |
| 2 Old Tunnels | #3, #4 Bandit patrol pair on the long hall | Patrol the hall and turn at the bends | Fighting in tight corridors |
| | #5 Bandit Archer | Hidden in the nook. Wakes when you pass the ambush zone. In tunnels he is forced to fight close | Ambush and ranged enemies |
| | #6, #7 Bandit patrol pair at the second bend | Short patrol. The secret wall to the hidden chest is just past them | Patrol timing, optional reward |
| 3 Bandit Camp | #8 to #11 Bandits around the fire | **#8 is a caller:** he shouts when he sees you and pulls in the whole camp, archers included | Choosing an approach |
| | #12, #13 Bandit Archers on the upper walkway | Shoot down on the ground floor. Reached by the west stairs or the east ladder | Verticality, archers as the priority target |
| | Powder barrels | By the fire and the east wall: hit one and it explodes, hurting bandits and you | Using the environment |
| | Extra at 3+ players | One more Bandit near the bedrolls | Group scaling |
| 5 The Excavation | #14 to #16 Bandits around the black stone | Dig and talk until they notice you | Handling a group of three |
| | #17 Bandit Captain | Guards the exit toward the shrine. Calls nearby bandits when the fight starts. See section 4 | The mid-dungeon elite |
| | #18, #19 Bandit Archers on the north gallery | Overlook the whole room. Arriving by rope bridge puts you above them | Using the upper route |
| | Powder barrels | By the west wall and the south corner | Using the environment |
| | Extra at 3+ players | One more Bandit near the west wall | Group scaling |
| 4 Shrine | none | Safe | n/a |
| 6 Deep Chamber | The boss, alone | No adds. See section 6 | The final test |

### Replayability and hazards (approved)
- **Powder barrels:** blasting powder barrels in the camp and the Excavation. Hitting one (with a swing or an arrow) makes an area explosion. Learnable and skillful, never random.
- **Barricade shortcut** in the Old Tunnels (see section 2).
- **Run variety through spawn tables:** the camp and the Excavation roll weighted tables each reset, so group sizes shift a little (for example a fifth bandit or an extra archer). Players cannot memorize it.
- **Named rare Bandit:** about 5% chance at a spawn point (uses the existing named-rare setting), carrying a chase item at a better rate than the boss. Marked on the map near the camp's crates. Name and drop TBD.
- **Hidden chest** refills each time you rest.
- **Skipped on purpose:** collapsing floors and rotten planks (they would end runs by luck).

**Totals:** 19 enemies plus the boss: 13 Bandits (#1 to #4, #6 to #11, #14 to #16), 5 Archers (#5, #12, #13, #18, #19) and 1 Captain (#17). With 3 or more players, two extra Bandits appear (one in the camp, one in the Excavation).

---

## 4. Enemy types

All art is placeholder grey skeletons for now, so this is about behavior and numbers. Numbers are first guesses to tune by playing. For reference, the Zealot is 160 health, armor 35, poise 50, and the Marauder is 200 health, armor 20, poise 45.

| Enemy | Role | Health | Armor | Poise | Notes |
|---|---|---|---|---|---|
| Bandit | Melee grunt, sword or mining pick | about 140 | 20 | 40 | Sword version: quick 2-hit combo, parryable. Pick version: slower, one parryable swing and one delayed overhead |
| Bandit Archer | Ranged, reskin of the Bandit with a bow and less armor | about 90 | 5 | 25 | Fires arrows (blockable, not parryable). Keeps 8 to 18 m away and backs off when approached. Switches to a quick melee stab when cornered |
| Bandit Captain | Mid-dungeon elite, sword and shield | about 380 | 40 | 90 | Blocks often when not attacking (about 50%). Moves: 3-hit combo (parryable), shield bash (heavy poise damage), delayed overhead (red, unblockable). Calls nearby bandits at the start of the fight |
| Harl the Delver (boss) | Final fight, see section 6 | about 1,100 at 1 player (x2.6 at 3 players) | about 30 | Boss-level poise, stance break (kneels about 3 s) | Working name |

XP and soul amounts are to be set when loot is finalized.

---

## 5. Loot

OSRS style: a simple table with coins, food, potions, a few gear drops, and one or two chase items. No excessive equipment variations. The Gullet's unique weapon is the item players remember.

### Regular Bandits (also Archers)
| Drop | Chance |
|---|---|
| Coins (5 to 25) | 100% |
| Bread | 20% |
| Cooked meat | 15% |
| Bronze sword | 8% |
| Iron dagger | 5% |
| Leather body | 3% |
| Health potion | 2% |

### Bandit Captain
| Drop | Chance |
|---|---|
| Coins (30 to 75) | 100% |
| Boss's unique weapon | 1/200 |
| Health potion | 40% |
| Cooked meat x2 | 25% |
| Iron sword | 15% |
| Iron shield | 10% |
| Steel sword | 3% |

### Boss
Guaranteed: coins (100 to 200), health potion x2.

| Rare drop | Chance | Rarity |
|---|---|---|
| Steel pickaxe | 1/20 | Uncommon |
| Steel sword | 1/30 | Uncommon |
| Blackstone amulet | 1/100 | Rare |
| Boss's unique weapon | 1/128 | Epic |

### Hidden Chest
| Drop | Chance |
|---|---|
| Coins (50 to 150) | 45% |
| Health potion x2 | 20% |
| Iron sword | 15% |
| Iron shield | 10% |
| Steel sword | 5% |
| Blackstone amulet | 1% |

Notes: the Captain's small unique-weapon chance makes the whole route matter, not just the boss. A named rare Bandit adds another chance (rate TBD). Rare drops are shared through normal need/greed. Expected effort at 1/128 from the boss alone: about 11 hours of 5-minute loops from the halfway shrine, or about 21 hours of full 10-minute runs. This OSRS-style table replaces the general "boss drops 2 to 3 items with a guaranteed Rare" rule from `DESIGN.md` section 9.1 for the Gullet. Whether the existing loot code can roll "1/128" style odds still needs checking.

---

## 6. Boss: Harl the Delver (approved)

**Concept.** A large weathered man in scavenged leather and chainmail, a battered helmet and a heavy miner's coat, carrying a sharpened mining pick. His face is scarred, his hands are black with mineral dust, and dark markings run under the skin of one arm. He doesn't look like a wizard or a monster. He fights like a man swinging a tool, and the stone gives him sudden unnatural bursts of strength. Magic stays understated: no fireballs, lightning or teleporting. He fights alone, with no adds.

**Backstory (short).** A survivor of the original quarry collapse who came back with the bandits promising the richest deposits. He found the black stone could hold and conduct something strange, and began embedding fragments in his gear and skin. The power is limited, unstable and painful. The bandits follow him now because they fear what happens if they refuse.

**Numbers (first guesses).** About 1,100 health at one player, armor about 30, boss-level poise. Boss health already scales by x(1 + 0.8 per extra player in the arena), so about 2,900 with three.

### Phase 1 (above 50% health)
| Move | What it does | Counterplay |
|---|---|---|
| Pick sweep | Wide horizontal swing, about 34 damage | Parryable (white glint), or roll through |
| Heavy Strike | Slow overhead with a long wind-up, about 55 damage | Parryable, the best riposte window |
| Ground Slam | Pick into the floor, a radius around him, about 40 damage and a brief stagger | Red glow, unblockable: roll or jump |
| Black Shard | Narrow cone of dark fragments when you keep your distance, about 14 damage and a short slow | Blockable. Pillars and rubble in the chamber break line of sight |
| Corrupted Grip | He raises the pick, it darkens, and his next attack hits 50% harder | Break his poise during it and the buff is lost |

### Phase 2 (below 50% health)
- He kneels and presses his marked arm to the black stone for about 2 seconds, a window to heal or reposition (uses the existing phase-2 roar slot).
- About 25% faster (the existing phase 2 speed setting).
- **Desperate Assault** replaces the basic swings: a 3-hit pick chain where the second hit is delayed, to punish panic-rolling (about 30 / 30 / 45 damage).
- Black Shard fires a 3-fragment spread.
- The marks on his arm visibly spread.

### Design rules
- Every move has a readable tell, and no single hit is random.
- Parrying and breaking his poise shortens the fight and cancels Corrupted Grip. The stance break leaves him kneeling for about 3 seconds, open to a critical hit.
- Target switching follows the existing boss rule: he picks a target only as an attack begins.
- The fight should last about 2.5 minutes, which fits the 5-minute farming loop from the halfway shrine.
- The arena (the Deep Chamber) has pillars and rubble for cover against Black Shard, and smooth walls.


### Fight rework (2026-11-22): the stone makes everyone move
Two moves were added so the fight is about *movement* and *scaling*, not just trading blows with whoever holds threat:
- **Delver's Charge** (both phases, used from 5 to 8 m): he lowers the pick, a slow tell, then crosses about 8 m in half a second. Parryable (a parry is a big poise chip), or sidestep it. It punishes standing at mid range, where only the shard used to reach you.
- **Stone Eruption** (both phases): he drives the pick into the floor and a red ring of black stone marks the ground **under every player in the arena**, aimed a little ahead of anyone who is running. About 1.4 s later spikes burst through (36 damage, unblockable: roll through it or leave the ring). In phase 2 it is **three rings in a row** that chase each player (1.15 s warning, 0.8 s apart, 40 damage), so a straight sprint or standing still both get hit. Harl is planted for about a second afterward: that is the punish window.
- **Scaling with players:** health still rises 0.8 per extra player, but the eruption now marks every player at once, and from **three players there is one extra wave**. A group can no longer stack behind the tank: everyone has to read their own ring, and the people on the ground take the ring while the person at his feet stays on the pick. Charge and sweep still go to the top of the threat table, so the tank decides where he runs.
- Code: `burst_*` fields in `attack_data.gd`, `_start_bursts` in `enemy.gd`, `game/enemies/stone_burst.gd` (the ring and spikes), `tests/boss_check.gd`.

### After the kill
- The ledger, the list of missing workers and the drawing of the black stone are **readable objects** beside the formation, not loot, so anyone can read them on any run.
- One ledger entry: *We were ordered to seal the lower passage. The foreman said there was nothing beneath the quarry worth retrieving. Three men refused to leave. I have not seen them since.*
- The first kill opens the shortcut corridor back to the entrance.
- He drops the boss loot table in section 5.
- The point: the bandits weren't the first people to find what lies below, and Harl wasn't the first changed by it. It also shows that forbidden power existed before either faction claimed it.

---

## 7. What the code already supports (checked 2026-11-21)

- **Callers:** `caller`, `call_range` on enemy data (the White Knight Zealot uses it). Covers the shouting bandit and the Captain's call.
- **Blocking and shield bashes:** `block_chance` and the Zealot's shield-bash attack. Covers the Captain.
- **Unblockable and delayed attacks:** `unblockable`, `windup_until` on attacks (the Marauder's crushing blow). Covers the Captain's overhead.
- **Spawn points** have `min_players` (the 3+ extras), a `patrol` route, and `snap_to_terrain` off for underground. Covers the extras and patrols.
- **Bosses** support two phases, kill flags and adds.
- **Verticality:** `ladder.gd` and `graybox_stairs.gd` exist in `game/world/`.

## 8. What is missing and needs building

- **Enemy archers.** The player's arrow code (`arrow.gd`) is player-only, but enemies already have long-reach cone attacks (Brother Tallow's wax spit reaches about 8.5 m in a narrow cone). A first version of the archer can reuse that kind of attack. Still new: a visible flying arrow and keep-distance behavior. Harl's Black Shard is the same kind of cone attack, so it is cheap.
- **Powder barrels.** A new object that explodes when hit by a swing or an arrow and damages everyone nearby. Not in the code yet.
- **Ambush trigger.** I found no ambush mechanic in the files read, only sight and hearing. The nook archer can use a short sight/hearing range plus idle until then.
- **New level layout.** The cave is carved by `game/world/gullet.gd` and the scene `levels/tithelands/props/gullet.tscn`. The new two-story rooms, rope bridge and shortcut need rebuilding there.
- **New weapon types** (iron dagger, steel pickaxe), the Blackstone amulet and the boss's unique weapon need data files.
- **Food and potion consumables** are new item types with small heals.
- **Gold to coins** rename.

---

## 9. Still to design (in this order)

1. ~~Purpose and fantasy~~ done
2. ~~Layout and flow~~ done (shrine moved to halfway)
3. ~~Encounters~~ done
4. ~~Hazards and set pieces~~ done in broad strokes (barrels, barricade shortcut, spawn variety, named rare); details at build time
5. ~~The boss~~ done (Harl the Delver)
6. Loot: confirm the tables above against the code, set souls and XP
7. Atmosphere and audio (lighting, ambience, boss track)

---

## 10. Build status (2026-11-21)

Built as a gray-block pass (all art is placeholder), in these commits ("Gullet step N"):
- **Layout** (`game/world/gullet.gd`, `levels/tithelands/props/gullet.tscn`): the six areas from `GULLET_MAP.svg` at 1 map pixel = 0.1 m, both two-story rooms (west stairs and east ladder in the camp, a ladder at the end of the Excavation's north gallery, a rope bridge with rails between the two), the **river** (`game/world/water_stream.gd`: one stream from a seep in the camp, through the east corridor, across the Excavation to a pool in the south-east; wading slows you 20%), the barricade, the secret wall to the hidden chest, the fog gate and the shortcut corridor.
- **Enemies**: Bandit (sword, pick), Bandit Lookout (the caller, #8), Bandit Archer (real flying arrows you can roll or sidestep, keeps 8 m away, backs off, stabs when cornered), nook archer (ambush: sleeps until you are within 6 m), Bandit Captain (shield, 50% block, delayed red overhead, calls the whole camp), and **Rook the Cutthroat** (named rare, 5% at the camp's crates; my placeholder name and loot). A shout pulls in every "bandits" family member, archers included.
- **Barrels** (`game/world/powder_barrel.gd`): 0.45 s hiss, then a 4.5 m blast (110 to enemies, 55 to players, less at the edge), chains to other barrels, set off by swings, player arrows and bandit arrows, back after a rest.
- **Loot**: food (bread 10%, meat 20%, potion 25% of max health, 1.5 s to eat), bronze/iron/steel gear, iron dagger, steel pickaxe, Blackstone amulet, Harl's Black Pick (Epic), all as OSRS-style tables with their own chances (`data/loot/loot_bandit*.tres`, `loot_harl.tres`, `loot_gullet_chest.tres`). The code rolls 1-in-128 odds fine.
- **Boss**: Harl as designed in section 6. Boss health is 1100 (x2.6 at three players = 2860). His Desperate Assault uses one damage number for all three hits (34), not 30/30/45.
- **Old Gullet**: Brother Tallow, the acolytes and their data and scenes stay in the project, unused. Harl sets a new flag (`gullet_harl_killed`), so an old save that had killed Tallow does not skip the new boss.
- **Checks**: `gullet_check` (items, drop rates, eating, enemies, barrels, level, chest) and the rewritten `boss_check`.

Not built yet, by choice: boss music and cave sounds specific to the quarry (the existing cave bed and boss track play), the named rare's final name and drops, souls/XP tuning, and everything in the numbers that needs a playtest.
