# TODO: Build Plan

Each phase must be playable before the next one starts. After each phase I tell you how to run it and what to test, then wait for your feedback.

Legend: `[x]` done · `[ ]` to do · 🧪 = something for **you** to test

**First milestone: 3 friends can clear one zone and one dungeon.**

> **Where we are (2026-11-21):** Phases 1-9 are built (gray-block pass) and all automated checks pass. Waiting on **your playtest**: the Tithelands, the Gullet and Brother Tallow, and the 3-friends milestone. You said movement and combat now feel good. **Next up:** the class overhaul in [`CLASS_PLAN.md`](CLASS_PLAN.md), starting at Priority 1 (planned only, nothing built). See [`HANDOFF.md`](HANDOFF.md) for how to resume.

---

## Phase 1: Setup ✅
- [x] Install Git 2.56.1 and Godot 4.7.2 (winget); desktop shortcuts
- [x] Project structure and `project.godot` (Forward+ renderer, Jolt physics)
- [x] `DESIGN.md`, `TODO.md`, `ART_NEEDS.md`, `README.md`, `assets/CREDITS.md`
- [x] Dark look test map: overcast sky, volumetric fog, filmic tone mapping, desaturation, ambient occlusion, a warm shrine light
- [x] Git repository and first commit
- [x] 🧪 Open the project, press F5, and check the mood of the test map

## Phase 2: Player controller ✅
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

## Phase 3: Combat core ✅
- [x] Data files: `data/weapons/weapon_rusty_sword.tres`, `data/shields/shield_round_wood.tres`, `data/enemies/enemy_marauder.tres` (every attack's timing, damage and reach is editable)
- [x] Sword moveset: 3-hit light combo, chargeable heavy, running attack, rolling attack
- [x] Hit detection (reach + swing arc), damage, crits, hit-stop, camera shake
- [x] Shield block (stamina drain, guard break), parry (timed block, no mashing), riposte (3× crit, invincible)
- [x] Poise and stagger (players and enemies)
- [x] Blood spurts and fading splatter decals (gore setting ready)
- [x] Floating damage numbers (H/N toggles); enemy health bars when hurt or targeted
- [x] Flasks (4, heal 40%, can be hit mid-drink), refilled at the test shrine
- [x] Enemy: Dark Ages Marauder (stand-in mannequin, rust-red) with sweep (parryable), delayed overhead (parryable), crushing blow (unblockable, red glow); circles you between attacks; gives up and walks home past 30 m
- [x] Resting at the shrine: heal, refill flasks, set respawn point, revive enemies
- [x] Death → respawn at the last shrine
- [x] Automated check `tests/combat_check.gd`: all 18 pass (combo, charge, block, parry→riposte, roll through, unblockable, guard break, stagger, flask, shrine)
- [ ] 🧪 Fight the Marauder: dodge, block, parry, riposte, drink flasks, die and respawn
- [x] Limit enemies to 2 attackers per player (Phase 8)
- [ ] Later: hit-stop is per character already; check it feels right with lag in Phase 4

## Phase 4: Multiplayer ✅
- [x] Main menu: name, Host (or play alone) / Join by address / Quit; shows your LAN address; remembers name and last address
- [x] Host-and-play server (ENet, UDP port 31415, up to 10 players)
- [x] Players spawn at spawn points and sync (position, facing, animations, health, state); name tags over friends
- [x] Enemies run on the host and sync to everyone (position, animation, health, red glow, white glint)
- [x] Combat sync: your hits on enemies show instantly and the host applies them; enemy blows go to the victim's own game, which decides (rolled through, blocked, parried) and reports back
- [x] Downed state (20 → 12 → 6 s bleed-out, crawl) and revive (hold Interact 3 s, costs the reviver a flask, back up at 30%); solo = instant death
- [x] Party frames (name, health, DOWN timer) and text chat (Enter)
- [x] Enemy health ×(1 + 0.6 per extra player), poise ×(1 + 0.25 per extra player)
- [x] Resting: blocked while an enemy is fighting you nearby; brings back enemies that aren't mid-fight
- [x] Esc menu: Resume / Leave game
- [x] Automated 3-player check (`tests/run_net_check.ps1`): 3 copies connect, hit, block, go down, revive and chat. All correct
- [x] Export a Windows build for friends: `build/Kingdom-windows.zip` (39 MB: Kingdom.exe + HOW TO PLAY.txt). Not in git; re-export any time
- [ ] 🧪 3 game windows on one PC, then a real test with friends over the internet
- [ ] Later: show ping in the debug info; a "kick player" option for the host

## Phase 5: Classes ✅
- [x] Character creator in the main menu: name, class (with role, story, passive, abilities), body (broad/slender), color; remembered
- [x] Bulwark (Resolve), Lamplighter (Oil), Headsman (Tally notches): 6 abilities each with cooldowns, costs and unlock levels (1/3/6/10/15/20); hotbar 1-6 or hold LT + face buttons
- [x] New weapons: Executioner's Greatsword, Lantern-Staff (2-handed, own movesets, stat scaling)
- [x] Aimed heals: Kindle lobs an ember to the center dot (can miss), Vigil Lantern / Snuff / Beacon land where you aim, Pyre around you
- [x] Threat table (Bulwark 2.5×), taunts (Challenge, Rallying Bellow), heals make a little threat, Flare/Feint drop threat; enemies switch at +10%
- [x] XP from kills shared in full within 50 m; levels 1–30; stats grow per class (health, stamina, damage, armor)
- [x] Talent trees: 12 per class in 3 rows (row 2 at 3 points, row 3 at 6), 1 point per 3 levels, T to open, free reset at shrines
- [x] Status effects: bleed, poison, frost buildup meters on players and enemies; slows; buffs/debuffs (Unbroken, Red Mist, Rallied, Sanctuary...)
- [x] Damage math from DESIGN.md 5.12: stat bonus, crit from Agility, armor reduction
- [x] Everything works in co-op: heals, buffs, taunts and statuses reach friends and the host's enemies
- [x] Automated `tests/class_check.gd`: all 28 pass (every ability of every class, XP, levels, talents, threat)
- [ ] 🧪 Play each class against a group of enemies, with and without a friend
- [ ] Later: bosses switch targets only at telegraphs (Phase 9, with the boss); characters and levels are saved in Phase 6
- [ ] Later: real ability icons (your AI art), real casting animations

## Phase 6: Loot ✅
- [x] 32 base items in `data/items/` (7 weapons, 3 shields, 15 armor pieces, jewelry, consumables, the legendary Hobb's Noose); rarity colors; item level; Rare+ random bonus rolls (`data/balance/loot.tres`)
- [x] Loot tables (`data/loot/`): drop chance, item count, item level, rarity weights, coins, souls; named-unique and guaranteed-rarity support for Phase 8–9
- [x] Grid backpack (10×6, items take shapes, consumables stack) and equipment: 10 armor/jewelry slots + two weapon sets (X / D-pad right swaps)
- [x] Gear changes stats, armor, poise, speed, stamina regen, status resistance and equip load (roll speed); weapon bonuses add bleed/poison/frost on hit
- [x] New weapons: Woodcutter's Axe (bleeds), Flanged Mace (ignores 30% armor), Boar Spear (long thrusts), Hunting Bow (arrows; hold to draw); Kite Shield, Iron Buckler
- [x] Drops glow on the ground (beam by rarity); pick up with E; drop items for friends from the inventory
- [x] Need / Greed / Pass rolls for Uncommon+ with 2+ players nearby (30 s); winner's drop is reserved; coins, souls and XP shared in full
- [x] Old Wenna (coins: buy consumables and gear, sell, buy back) and the Soul Broker (Rare+ gear for souls; new stock when you rest)
- [x] Shrine menu: Rest / Bank. Bank 12×4, more rows for coins, safe and saved with your character
- [x] Characters saved on your PC (`%APPDATA%Godotpp_userdataKingdomaracters`): class, level, XP, talents, gear, backpack, bank, coins, souls. Autosave every 5 min, on rest, level-up and leaving. Continue a saved character from the main menu
- [x] Automated `tests/loot_check.gd`: all 23 pass; 3-player check now also covers loot rolls and pickup
- [ ] 🧪 Farm the arena, roll for loot with a friend, quit and reload your character
- [ ] Later: move items around inside the backpack by hand; drops don't show for players who join after they fell; real item icons

## Phase 7: Death system ✅ (waiting for your test)
- [x] Keep your 3 most valuable items (by sell value; equipped ones stay equipped); everything else, all coins and all souls drop as a glowing pile where you died (no map marker)
- [x] Only you and your party can recover it; whoever picks it up, it all goes back to you (backpack, then bank, then at your feet)
- [x] Piles last 60 minutes (`Loot.pile_minutes`, a server setting); dying again before you recover it destroys the old pile for good
- [x] Boss-room deaths put the pile at the boss door (`game/world/boss_room.gd`, used in Phase 9); fall deaths at the last safe ground
- [x] Respawn at the last rested shrine; the bank and flasks are never lost; your character saves right after dying (no quitting to dodge it)
- [x] Automated `tests/death_check.gd`: all 11 pass; 3-player check: a friend recovers your pile and it comes back to you
- [ ] 🧪 Die with good gear, run back, recover it; die twice to lose it; have a friend recover your pile

## Phase 8: First zone (the Tithelands) ✅ gray-block pass (waiting for your test)
- [x] Gray-block layout (`levels/tithelands/`): Crossroads start, the old road north with the White Knight checkpoint and tithe barn, farms and the burned hamlet, the river with a broken bridge and a ford, the Mill and Hobb's camp, east woods with the raider camp and watchtower, the quarry down to the Gullet's mouth, Highcrown in the northern fog. Art pass comes later (needs download permission)
- [x] 3 enemy types: Dark Ages Marauder (bleed sweep), White Knight Zealot (sword and shield, blocks, blows a horn, martyr's fury when an ally dies), Gaunt Hound (fast packs, bleeding bites, howls)
- [x] Senses: a sight cone and range (halved at night), hearing (doubled when you sprint, roll or attack); patrols on routes; callers bring the rest of their kind; at most 2 enemies attack you at once
- [x] Spawn points with spawn tables (`data/spawns/`): rerolled when anyone rests, except fights in progress and spots within 30 m of a player; extra spawns for 3+ and 6+ players
- [x] Named rare: Hobb the Unhanged (5% at his camp), name over his health bar, guaranteed Hobb's Noose and better loot
- [x] 3 shrines (Crossroads, Mill, Quarry): rest, **travel**, bank. Walking near a shrine finds it; travel to any shrine you've found (not with enemies on you)
- [x] Fog-of-war map (M): clears as you explore, shows found shrines, your party and you; saved per character, per world; you come back at the last shrine you rested at
- [x] Day/night: 48 minutes (32 day, 16 night), cold moonlit nights where enemies see half as far; your belt lantern lights up at night. Rain showers come and go
- [x] Ladders (watchtower, quarry), a one-way gate that loops back from the watchtower, slow wading through the river
- [x] World save/load (host): pick a world name in the main menu. Saved: time, weather, opened shortcuts, death piles and their timers. Every 5 minutes and when you leave. Friends joining see existing piles
- [x] Automated checks: `tests/zone_check.gd` (34 pass), `tests/enemy_check.gd` (13 pass), all earlier checks and the 3-player check still pass
- [x] Feel pass: faster run/sprint/lock-on, quicker rolls, attacks 20% faster (`attack_speed` in `data/balance` tuning); zone compressed to 364 m, roadside clutter, more trees and rocks, 9 extra encounters
- [ ] Zone music and ambience (needs your OK to download CC0 sounds)
- [ ] 🧪 Explore the whole zone with friends; find the shortcut; hunt Hobb; play through a night (F5 skips 3 hours, F6 toggles rain)

## Phase 9: The Gullet (cave dungeon and boss) ✅ gray-block pass (waiting for your test)
- [x] Entrance moved to flat ground beside the Quarry Shrine with an amber light beam and an always-visible map dot (the first spot was buried on a steep pit wall); the quarry pit is now shallower and gentler so you can walk out
- [x] The Gullet (`levels/tithelands/props/gullet.tscn`, carved by `game/world/gullet.gd`): built underground beneath the quarry. Enter by the **Descend into the Gullet** door at the cave mouth (E); climb back out at the entrance hall. Entrance hall, bone gallery, cistern, shrine alcove, then the fog gate and Brother Tallow's chapel. Dark and candle-lit; your belt lantern lights underground
- [x] Fourth shrine, the **Gullet Shrine** (rest, travel, bank), 38 m from the boss so he comes back when you rest
- [x] Fog gate: walk through the mist (E) to enter; it turns solid while he fights and opens when he dies or the fight ends. He only wakes once you step inside his arena
- [x] Boss: **Brother Tallow, the Candle-Saint** (`data/enemies/enemy_tallow.tres`). Phase 1: flail sweep (parryable), red overhead slam (unblockable), wax spit (blockable, slows). Phase 2 under 50% health: he sets himself alight, moves 25% faster, calls Candle Acolytes, and adds a fire slam and burning ground (`game/enemies/fire_patch.gd`)
- [x] Boss rules: huge poise (breaking it = stance break, he kneels 3 s, open to a riposte); each parry chips 90 poise; switches target only as an attack begins (taunts take effect at his next attack); boss bar at the bottom of the screen with a phase marker
- [x] Candle Acolytes (`data/enemies/enemy_acolyte.tres`): weak fanatics in packs; extra packs spawn for 3+ and 6+ players; boss health x(1 + 0.8 per extra player in the arena), counted when the fight starts, and more acolytes join in phase 2
- [x] Boss loot (`data/loot/loot_tallow.tres`): 2-3 items (one Rare or better, small chance of Legendary) plus the unique Tallow Crown, 300-450 coins, 600-800 souls
- [x] First kill sets the `gullet_boss_killed` world flag (saved with the world) and opens a long shortcut corridor from the chapel back to the entrance hall; he still respawns on rest. Dying in the arena puts your pile at the boss door
- [x] Automated `tests/boss_check.gd`: all 29 pass; zone, enemy, combat, death and the 3-player checks still pass
- [ ] Tune for 3 players (needs real playtesting: boss health, damage, acolyte counts)
- [ ] Later: real cave art, a more winding layout, a boss track, candle-wax visuals on the boss
- [ ] 🧪 **Milestone: 3 friends clear the zone and the dungeon** (use the Descend door at the quarry cave mouth)

## After Phase 9: feel and combat corrections ✅ (you said it feels good)
- [x] Enemies are solid and spread evenly around the player; an enemy with a friend in the way waits instead of swinging
- [x] Nioh 2-style movement: run 6.8, sprint 9.6, lock-on strafe 5.0, much snappier acceleration and stopping; legs cycle faster with longer strides
- [x] Elden Ring-style extra attacks for every weapon: jump light/heavy, plunging attack, guard counter, running heavy, rolling heavy, backstep attack (plus the existing light, heavy, running and rolling)
- [x] A quick sideways mouse flick lets go of the lock-on
- [x] `tests/moves_check.gd` (extra attacks, lock-on flick, enemy spacing) added; every check passes, including the 3-player run
- [ ] 🧪 Try the new attacks and enemy spacing against a group of enemies, with a friend

---

## Phase 10: Audio ✅ (built; waiting for your listening test)
- [x] 1. Sounds downloaded (you approved 2026-11-21): 321 CC0 files in `assets/audio/` (sfx, ambience, music), all logged in `assets/CREDITS.md`. Got from OpenGameArt because Kenney's site blocks scripted downloads. Later also: a CC0 horn and a wind loop.
- [x] 2. Audio setup: buses Master, Music, Effects, Ambience, Interface (`game/audio/audio_manager.gd`, autoload `Audio`); volume sliders under a **Volume** button in the main menu and the Esc menu, saved in `settings.cfg`; `tests/audio_check.gd` passes. 🧪 Open the menu and check the sliders feel right (nothing plays yet, so you can't hear a difference until step 3)
- [x] 3. Combat sounds, first pass: swings (light, heavy, dash), flesh hits and crits, block and parry clangs, rolls, jumps, landings, footsteps, hurt and death voices (human, beast, boss), flask drinking, shield bash, and the nine class abilities (Lunge and Whirlwind swishes, Battle Fury roar, Shield Throw whoosh and clack, Iron Resolve, Arcane Bolt, Mend, Hex). They play from the animations, so **friends hear each other** with no extra network traffic. All cues live in one table, `game/audio/sfx_library.gd`; `tests/sound_check.gd` passes. I could not listen to them: picked by file name, so expect to tune by ear (which cue sounds wrong, too loud, too repetitive)
- [x] 4. Loot and interface sounds: a distinct drop sound per rarity (Legendary is six sounds layered), pickups, coins and souls, equipping, shop, shrine rest and discovery, level-up, death sting, death-pile appear and recover, loot-roll pop-up, and a click on every menu button; menus rustle open and shut
- [x] 5. Tithelands music and ambience (`game/audio/zone_audio.gd`, created by DayNight): a forest bed that gets quieter at night and in rain, a rain bed that follows the showers, crows by day, and slow music with 25-70 s of silence between tracks (dark forest theme by day, the lament at night); everything fades out underground and the cave beds fade in. Still missing: a wind loop and a shrine hum. Checked by `audio_check`
- [x] 6. The Gullet: two cave beds fade in as you go underground (rain, forest and music fade out). Brother Tallow: when he engages, the ambience ducks and a boss track loops for everyone in range; in phase 2 it gets louder and 7% faster, with a roar. The track is a stand-in (stored compressed, 4 MB in the build)
- [x] 7. Enemy sounds: knights blow a horn that carries 90 m (CC0 horn added), hounds howl and bark, raiders and knights grunt in a rougher voice than yours, the boss roars; a wind loop was added to the zone bed. Friends hear each other (tested through the copied-animation path); 3-player check passes. **Build re-exported**: `build/Kingdom-windows.zip` (66 MB) starts cleanly
- [ ] 🧪 Walk the zone and fight with sound on (especially Brother Tallow); tell me what is too loud, repetitive or wrong. Cues are one line each in `game/audio/sfx_library.gd`; beds and music levels are in `game/audio/zone_audio.gd`
- [ ] Later: a shrine hum, monk chanting for the Gullet, real boss and cave music, footsteps per surface (stone vs dirt), per-weapon hit sounds

## Phase 11: Subclasses and factions (paused by you: the first part is built)
- [x] Foundations: `SubclassData` and `FactionData` types, nine subclasses and three factions as data files (`data/subclasses/`, `data/factions/`, full lore text), a subclass on the character that adds abilities (hotbar slots 4-6) and a passive, saved with the character and synced to friends
- [x] The level 10 choice: a banner at level 10, a **Choose your path** button in the shrine menu, a preview screen with all three paths (identity, weapons, direction, abilities, faction tie, initiation story) and a confirmation; `clear_subclass()` is the hook for a future re-pick
- [x] First three paths playable: Warrior (Cleave, Feint, Red Mist), Guardian (Rallying Bellow, Hold the Line, Unbroken), Cleric (Snuff, Beacon, Pyre). The other six show "Coming later" and cannot be chosen. `tests/subclass_check.gd` passes
- [ ] Paused: Paladin (auras), Mage, Rogue, Ranger, Warlock, Warden (summons); initiation trials (need quests); per-subclass talents and visuals

## Phase 12: Settings menu and key rebinding ✅ (built; waiting for your test)
- [x] `Prefs` autoload (`game/core/prefs.gd`): gameplay options, camera, display and your key bindings, all saved in `settings.cfg`
- [x] A **Settings** screen from the main menu and the Esc menu (replaces the Volume button) with four tabs: **Audio** (the five sliders), **Gameplay** (damage numbers, enemy health bars, gore Off/Low/High, camera sensitivity, invert Y), **Display** (fullscreen, vsync), **Controls**
- [x] **Rebinding** for 26 keyboard and mouse actions: click an action, press a key or mouse button (Esc cancels); if another action already used it the two swap, so nothing is left unbound; gamepad buttons stay as designed; Reset button; changed bindings show in blue. The hotbar and the interact prompt show your real keys
- [x] `tests/prefs_check.gd` passes (22 checks); all other checks and the 3-player check still pass
- [ ] 🧪 Open Settings, rebind a few keys, quit and restart to see that they stuck; try fullscreen and sensitivity
- [ ] Later: gamepad rebinding, brightness, resolution scale, accessibility (text size, colorblind-safe rarity), the F1 help text following your bindings

## Phase 13: The camp and night raids ✅ (built; waiting for your test; design in DESIGN.md 11.5)
- [x] 1. The camp: a cold fire pit east of the Crossroads (36, 122) that anyone can claim for 100 coins (`game/world/camp.gd`, a Shrine with a different script, so it also rests, banks, travels and respawns). It goes cold when overrun and is relit for 50 coins. State is world flags, so it is shared and saved with the world
- [x] 2. Upgrades at 150 / 400 / 900 coins per level (Palisade, Watchfires, Stores) from a **Camp upgrades** button in the hearth menu (`game/ui/camp_panel.gd`); the camp visibly grows: solid stake posts, torch poles with lights, crates
- [x] 3. Raids (`game/world/camp_raids.gd`, host only): at dusk (the first night always, then 60%) if a player is within 120 m, 3+ raiders (marauders, zealots, hounds; more with more players and better upgrades) appear 70-90 m out and march to the camp. Raiders near the hearth drain its strength; 0 = overrun (hearth cold); all dead = won; dawn = they leave
- [x] 4. A raid chest of spoils at the hearth (better with Stores; shared coins, souls, XP, need/greed), a strength bar and raider count at the top of the screen, a horn at the start, win and loss sounds, raiders on the map at Watchfires II, the direction named at Watchfires I, shorter raider sight at Watchfires III. **F7** starts a raid now (host)
- [x] 5. `tests/camp_check.gd` (46 checks) passes; the 3-player check now also covers claiming and a raid seen by everyone
- [ ] 🧪 Claim the camp (you need 100 coins; Hobb and the roads give it), upgrade it, press F5 to skip to night or F7 to raid now, and defend it, alone and with a friend; tell me if raids are too easy, too hard or too long
- [ ] Later: raiders that attack the palisade itself, repairable damage, camp NPCs and a camp vendor, camp level shown on the map, more raid types (a captain, a siege), raids on other zones' camps

## Later (after the milestone)
- Camp that enemies raid at night; upgrades
- Quests and public quests
- More zones, zone unlocks, more open world
- More races (dwarves, elves), more magic
- World bosses, New Game+
- Server browser (maybe Steam), PvP
- Dismemberment
- Key rebinding menu, full settings, accessibility options

---

## Primary classes ✅ (2026-11-21)
- [x] Martial / Vanguard / Mystic (names provisional; IDs unchanged), three abilities each, unlocked at levels 2, 4, 6 and kept after level 10
- [x] Martial: Lunge (lock-on aware), Whirlwind (360° strike), Battle Fury (damage and attack speed buff)
- [x] Vanguard: Shield Bash, Shield Throw (pierces a line, returns, no blocking while away), Iron Resolve (damage and poise reduction)
- [x] Mystic: Arcane Bolt (homing on lock-on), Mend (friend in front or self), Hex (enemy curse, synced via the host)
- [x] Talents rewritten for the new abilities; "New ability" text on level-up; `class_check` rewritten (all pass)
- [ ] 🧪 Play each class: Lunge at a locked-on enemy, Whirlwind when surrounded, Shield Throw through a line, Mend a friend, Hex a boss; try them in co-op
- [ ] Later: real casting animations and icons; a Martial resource sink (Tally has nothing to spend on yet); hide your shield while it is thrown

## Planned: subclasses and factions
Full notes and priority order are in [`CLASS_PLAN.md`](CLASS_PLAN.md). Not built yet (the primary classes above are done). Decisions: subclass is re-pickable in future; interim gate and talents still open.
- [ ] P1 Foundations: subclass and faction data types, subclass on the character, save and network, old class ID aliases
- [ ] P2 Level 1 primary classes: Martial / Vanguard / Mystic (reshape of Headsman / Bulwark / Lamplighter), 3 starting abilities each
- [ ] P3 Level 10 subclass choice: shrine button, preview screen, permanent confirmation, hotbar slots 4-6
- [ ] P4 Lore: faction data (White Knights, Dark Ages, Outcasts), initiation stories per subclass, DESIGN.md update
- [ ] P5 Unique subclass abilities, one subclass at a time (Guardian, Warrior, Cleric first; Warden last)
- [ ] P6 Initiation events once quests exist
- [ ] P7 Per-subclass talents, visuals, balance

## Phase 14: The new Gullet (bandit quarry) 🚧 in progress
Design: [`GULLET_DESIGN.md`](GULLET_DESIGN.md) and `GULLET_MAP.svg`. Replaces the candle-monk Gullet (Brother Tallow stays as unused data). Levels 3-6.
- [x] 1. Docs updated and design committed
- [ ] 2. Gold renamed to coins everywhere (saves convert old data)
- [x] 3. Items and loot: food, potions, bronze/iron/steel gear, iron dagger, steel pickaxe, Blackstone amulet, Harl's unique weapon, loot tables with 1-in-N odds
- [ ] 4. Enemies: Bandit (sword, pick), Bandit Captain, Bandit Archer
- [ ] 5. Powder barrels
- [ ] 6. Level layout (six areas, two two-story rooms, a small river through both, rope bridge, barricade, secret wall, fog gate, shortcut)
- [ ] 7. Populate: 19 enemies, patrols, caller, 3+ player extras, spawn tables, named rare, ambush, hidden chest, halfway shrine
- [ ] 8. Boss: Harl the Delver
- [ ] 9. Retire the old Gullet (Tallow kept, saves migrate)
- [ ] 10. Atmosphere and audio
- [ ] 11. Tests, 3-player check, friends build, handoff
