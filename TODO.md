# TODO: Build Plan

Each phase must be playable before the next one starts. After each phase I tell you how to run it and what to test, then wait for your feedback.

Legend: `[x]` done · `[ ]` to do · 🧪 = something for **you** to test

**First milestone: 3 friends can clear one zone and one dungeon.**

---

## Phase 1: Setup ✅
- [x] Install Git 2.56.1 and Godot 4.7.2 (winget); desktop shortcuts
- [x] Project structure and `project.godot` (Forward+ renderer, Jolt physics)
- [x] `DESIGN.md`, `TODO.md`, `ART_NEEDS.md`, `README.md`, `assets/CREDITS.md`
- [x] Dark look test map: overcast sky, volumetric fog, filmic tone mapping, desaturation, ambient occlusion, a warm shrine light
- [x] Git repository and first commit
- [x] 🧪 Open the project, press F5, and check the mood of the test map

## Phase 2: Player controller ✅ (waiting for your test)
- [x] Stand-in player model on the standard humanoid skeleton (Quaternius mannequin, CC0), with idle/walk/run/sprint/jump/roll/death animations, instead of a capsule
- [x] Input map (mouse & keyboard + gamepad), defined in `game/core/input_setup.gd`
- [x] Graybox test level (`levels/sandbox/movement_test.tscn`): slopes, stairs, crates, doorway, low tunnel, a fall-test ramp with 4/6/10/16 m ledges
- [x] Over-the-shoulder camera (mouse and stick) that doesn't clip through walls
- [x] Weighty movement: walk, run, sprint, acceleration and turning (wide turns while sprinting)
- [x] Jump with short i-frames; fall damage; hard landings stumble
- [x] Dodge roll with i-frames; roll speed from equip load (F3 cycles light / medium / heavy / overloaded)
- [x] Stamina: costs, regen delay, sprint lockout after running dry
- [x] Lock-on toggle, target switching (mouse wheel / stick flick), breaks at 25 m or 2 s out of sight; soft-target finder ready for attacks
- [x] Training dummies (static, walking, far away, behind a wall)
- [x] Minimal HUD: health and stamina bars, lock-on marker, F1 controls, F2 debug info
- [x] Placeholder death: falls can kill you, respawn after 3 s
- [x] Automated check `tests/movement_check.gd` (speeds, roll distances, jump height, fall damage, lock-on): all pass
- [ ] 🧪 Run around, roll, jump, sprint until out of stamina, lock onto dummies, jump off the ledges
- [ ] 🧪 Try a gamepad if you have one (not tested yet; I have no controller here)

## Phase 3: Combat core
- [ ] Data files for weapons and enemies in `data/`
- [ ] Sword moveset: light combo, heavy (charge), running/rolling attacks
- [ ] Hitboxes, damage, hit-stop, camera shake
- [ ] Block, parry (timed block), riposte
- [ ] Poise and stagger
- [ ] Blood spurts and splatter decals
- [ ] Floating damage numbers; enemy health bars (toggle)
- [ ] Flasks (4), refilled at a test shrine
- [ ] Enemy: Dark Ages Marauder with telegraphed attacks (idle → chase → attack → recover), death
- [ ] Simple player death → respawn at the test shrine (the full death system is Phase 7)
- [ ] 🧪 Fight the Marauder: dodge, block, parry, riposte, drink flasks, die and respawn

## Phase 4: Multiplayer
- [ ] Main menu: Host / Join by IP / Quit
- [ ] Host-and-play server (ENet, UDP port 31415)
- [ ] Players spawn and sync (movement, animations, attacks)
- [ ] Enemies run on the host and sync to everyone
- [ ] Combat sync: hits on enemies (attacker reports, host applies); hits on players (the victim's game decides)
- [ ] Downed state and revive (costs the reviver a flask)
- [ ] Party frames and text chat
- [ ] Enemy health and poise scale with player count
- [ ] Export a Windows build for friends
- [ ] 🧪 3 game windows on one PC, then a real test with friends over the internet

## Phase 5: Classes
- [ ] Character creator with presets (class, look, name)
- [ ] Bulwark, Lamplighter, Headsman: resources and 6 abilities each, hotbar with cooldowns
- [ ] Aimed heals (lobbed projectiles and ground zones)
- [ ] Threat table and taunts; bosses switch targets only on telegraphs
- [ ] XP from kills, levels 1–30, stat growth
- [ ] Small talent tree per class
- [ ] Status effects: bleed, poison, frost buildup
- [ ] 🧪 Play each class against a group of enemies, with and without a friend

## Phase 6: Loot
- [ ] Item data: weapons by type, armor by slot, jewelry; rarity colors; item level
- [ ] Random bonus rolls (Rare and up)
- [ ] Loot tables (enemies, elites, named rares, bosses)
- [ ] Grid inventory and paperdoll; gear changes stats and equip load
- [ ] Remaining weapon movesets: axe, mace, greatsword, spear, bow, staff
- [ ] Need/Greed rolls; drop items to trade
- [ ] Gold and souls; vendor (buy, sell, buy back); Soul Broker; bank at shrines
- [ ] Character save/load; characters move between worlds
- [ ] 🧪 Farm the test map, roll for loot with a friend, quit and reload your character

## Phase 7: Death system
- [ ] Keep your 3 most valuable items; drop everything else as a glowing pile
- [ ] Only you and your party can recover it; recovered items return to the owner
- [ ] 60-minute timer (server setting); dying again destroys the old pile
- [ ] Boss-room deaths put the pile at the boss door; fall deaths at the last safe ground
- [ ] Respawn at the last rested shrine
- [ ] 🧪 Die with good gear, run back, recover it; die twice to lose it

## Phase 8: First zone (the Tithelands)
- [ ] Graybox layout, then an art pass: road, farms, burned hamlet, woods, river, watchtower, quarry, Highcrown backdrop
- [ ] 3 enemy types: Dark Ages Marauder, White Knight Zealot, Gaunt Hound
- [ ] Patrols, packs, ambushes, callers
- [ ] Spawn points and spawn tables; respawn on rest
- [ ] Named rare: Hobb the Unhanged and his unique loot
- [ ] 3–4 shrines: rest, fast travel, bank
- [ ] Fog-of-war map
- [ ] Day/night cycle and rain
- [ ] Ladders and a hidden shortcut that loops back
- [ ] World save/load (host)
- [ ] Zone music and ambience
- [ ] 🧪 Explore the whole zone with friends; find the shortcut; hunt Hobb

## Phase 9: The Gullet (cave dungeon and boss)
- [ ] Cave layout, fog gate, a shrine near the boss
- [ ] Boss: Brother Tallow, the Candle-Saint (2 phases, telegraphs, stance break)
- [ ] Candle Acolytes; extra adds for 3+ players; health and poise scaling
- [ ] Boss loot table and unique drop; shortcut opens after the first kill
- [ ] Tune for 3 players
- [ ] 🧪 **Milestone: 3 friends clear the zone and the dungeon**

---

## Later (after the milestone)
- Camp that enemies raid at night; upgrades
- Quests and public quests
- More zones, zone unlocks, more open world
- More races (dwarves, elves), more magic
- World bosses, New Game+
- Server browser (maybe Steam), PvP
- Dismemberment
- Key rebinding menu, full settings, accessibility options
