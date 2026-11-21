# THE GULLET: Dungeon Design (working draft)

*Started 2026-11-21. Built up one aspect at a time with the designer. This replaces the old Gullet (candle-monk cave, Brother Tallow) described in `DESIGN.md` sections 8.6 and 11.2 once approved. `DESIGN.md` and `TODO.md` are not changed yet.*

The matching floor plan with legend and enemy positions is the "The Gullet: Dungeon Map" page on claude.ai. Enemy numbers (#1 to #19) below match that map.

---

## 1. Decisions so far

| Topic | Decision |
|---|---|
| Role | The first dungeon, in the Tithelands (zone 1). Level 3 to 5. |
| Length | About 10 minutes for a clean run, with fighting and no deaths. |
| Shape | Tight, slightly winding corridors that open into bigger fight rooms, plus two large two-story areas. |
| Shrine | Directly before the boss fight. |
| Story | An abandoned quarry occupied by desperate outlaws, who dug into a sealed passage and found a black stone. Travelers vanish on the forest road. Full text lives in the designer's brief (`THE GULLET` attachment). |
| Factions | The boss is **not** a Dark Ages member. He is an ordinary man changed by the stone, which shows forbidden power existed before either faction claimed it. |
| Boss name | To be decided. The brief's "Quarryman" is being replaced. Suggested: The Foreman (ties to the ledger). |
| Look | Narrow rough rock, wooden supports, carts, ropes, picks. Torches and campfires are the light: warm orange with deep shadow. No glowing crystals. Bandits look like ordinary medieval outlaws. The last chamber is an accidental discovery, not a built arena. |
| Healing | Flasks stay the main heal. Food and potions are small extra heals (start values: bread 10%, cooked meat 20%, health potion 25% of max health; a flask is 40%). Eating takes about 1.5 s and you can be hit mid-bite. |
| Gear tiers | Bronze and iron are Common (white). Steel is Uncommon (green). Chase items are Rare (blue) or Epic (purple). |
| New weapon types | Iron dagger = a fast sword-type weapon. Steel pickaxe = a mace or axe type with mining flavor. |
| Currency | "Gold" is renamed **coins** everywhere. Souls stay as the second currency and drop as a small automatic amount on top of the tables below. The rename touches code, data, saves and docs and is **not done yet**; do it after the dungeon design is finished. |

---

## 2. Layout and pacing

| # | Area | Shape | Target time |
|---|---|---|---|
| 1 | Entrance Yard | Small yard at the quarry mouth: broken barricades, carts, smoke through cracks in the rock | 1:00 |
| 2 | Old Tunnels | Tight winding corridors with wooden supports. Side nook for the ambush. Secret wall to the hidden chest | 2:00 |
| 3 | Bandit Camp | Large **two-story** room: ground floor around a campfire, upper scaffold walkway along the north side. West stairs, east ladder, rope bridge east to the Excavation | 2:00 |
| 4 | The Excavation | Large open **two-story** room: broken-through wall, scaffolding, the strange stone formation, black mineral veins. North gallery and west gallery above, ladder at the gallery's east end | 2:00 |
| 5 | Shrine | Small quiet alcove just before the boss. Rest, bank, travel | 0:30 |
| 6 | Deep Chamber | Larger chamber with unnaturally smooth walls, the exposed black stone, and the boss. Reached through a fog gate | 2:30 |

- **Shortcut:** after the first boss kill, a corridor opens from the Deep Chamber back to the Entrance Yard (closed until then).
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
| | Extra at 3+ players | One more Bandit near the bedrolls | Group scaling |
| 4 The Excavation | #14 to #16 Bandits around the black stone | Dig and talk until they notice you | Handling a group of three |
| | #17 Bandit Captain | Guards the exit toward the shrine. Calls nearby bandits when the fight starts. See section 4 | The mid-dungeon elite |
| | #18, #19 Bandit Archers on the north gallery | Overlook the whole room. Arriving by rope bridge puts you above them | Using the upper route |
| | Extra at 3+ players | One more Bandit near the west wall | Group scaling |
| 5 Shrine | none | Safe | n/a |
| 6 Deep Chamber | The boss, alone | No adds. See section 6 | The final test |

**Totals:** 19 enemies plus the boss: 13 Bandits (#1 to #4, #6 to #11, #14 to #16), 5 Archers (#5, #12, #13, #18, #19) and 1 Captain (#17). With 3 or more players, two extra Bandits appear (one in the camp, one in the Excavation).

---

## 4. Enemy types

All art is placeholder grey skeletons for now, so this is about behavior and numbers. Numbers are first guesses to tune by playing. For reference, the Zealot is 160 health, armor 35, poise 50, and the Marauder is 200 health, armor 20, poise 45.

| Enemy | Role | Health | Armor | Poise | Notes |
|---|---|---|---|---|---|
| Bandit | Melee grunt, sword or mining pick | about 140 | 20 | 40 | Sword version: quick 2-hit combo, parryable. Pick version: slower, one parryable swing and one delayed overhead |
| Bandit Archer | Ranged, reskin of the Bandit with a bow and less armor | about 90 | 5 | 25 | Fires arrows (blockable, not parryable). Keeps 8 to 18 m away and backs off when approached. Switches to a quick melee stab when cornered |
| Bandit Captain | Mid-dungeon elite, sword and shield | about 380 | 40 | 90 | Blocks often when not attacking (about 50%). Moves: 3-hit combo (parryable), shield bash (heavy poise damage), delayed overhead (red, unblockable). Calls nearby bandits at the start of the fight |
| Boss | See section 6 | TBD | TBD | TBD | Name to be decided |

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

Notes: this OSRS-style table replaces the general "boss drops 2 to 3 items with a guaranteed Rare" rule from `DESIGN.md` section 9.1 for the Gullet. Whether the existing loot code can roll "1/128" style odds still needs checking.

---

## 6. Boss (not designed in detail yet)

From the brief, to be reworked in the boss step: a large weathered man in scavenged leather and chainmail with a sharpened mining pick, a primarily melee fight with a few subtle magical moves. Candidate moves: Heavy Strike, Ground Slam (brief stagger), Black Shard (small burst of mineral fragments), Corrupted Grip (next attack hits harder), and a low-health chain of melee attacks (Desperate Assault). Magic stays understated: no fireballs, lightning or teleporting. On death: black mineral fragments, a list of missing workers, an old quarry ledger and a drawing of the black stone. The ledger entry about the sealed lower passage and the three men who refused to leave is the story hook.

---

## 7. What the code already supports (checked 2026-11-21)

- **Callers:** `caller`, `call_range` on enemy data (the White Knight Zealot uses it). Covers the shouting bandit and the Captain's call.
- **Blocking and shield bashes:** `block_chance` and the Zealot's shield-bash attack. Covers the Captain.
- **Unblockable and delayed attacks:** `unblockable`, `windup_until` on attacks (the Marauder's crushing blow). Covers the Captain's overhead.
- **Spawn points** have `min_players` (the 3+ extras), a `patrol` route, and `snap_to_terrain` off for underground. Covers the extras and patrols.
- **Bosses** support two phases, kill flags and adds.
- **Verticality:** `ladder.gd` and `graybox_stairs.gd` exist in `game/world/`.

## 8. What is missing and needs building

- **Enemy archers.** Enemies cannot shoot yet. The arrow code (`arrow.gd`) belongs to the player, and enemy attacks only swing. We need an enemy ranged attack plus keep-distance behavior. `AttackData` already has `projectile_speed` and `projectile_range`.
- **Ambush trigger.** I found no ambush mechanic in the files read, only sight and hearing. The nook archer can use a short sight/hearing range plus idle until then.
- **New level layout.** The cave is carved by `game/world/gullet.gd` and the scene `levels/tithelands/props/gullet.tscn`. The new two-story rooms, rope bridge and shortcut need rebuilding there.
- **New weapon types** (iron dagger, steel pickaxe), the Blackstone amulet and the boss's unique weapon need data files.
- **Food and potion consumables** are new item types with small heals.
- **Gold to coins** rename.

---

## 9. Still to design (in this order)

1. ~~Purpose and fantasy~~ done
2. ~~Layout and flow~~ done
3. ~~Encounters~~ done (this draft)
4. Hazards and set pieces (traps, environmental dangers, secrets)
5. The boss (name, moves, phases, arena)
6. Loot: confirm the tables above against the code, set souls and XP
7. Atmosphere and audio (lighting, ambience, boss track)
