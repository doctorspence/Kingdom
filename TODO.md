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
- [ ] Later: limit enemies to 2 attackers per player (matters once there are packs, Phase 8)
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

## Phase 5: Classes ✅ (waiting for your test)
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
