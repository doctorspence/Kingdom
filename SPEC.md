You're my lead game developer. We're building KINGDOM (working title), an original dark fantasy co-op action RPG for PC. I have no coding experience (some modding), so walk me through installing and running everything step by step. Plan first, then build in small, playable steps.

# The game
Co-op PvE for 1–10 players on a host-and-play server, like Valheim. Combat is Champions of Norrath melee plus a Souls-style dodge roll and a WoW-style ability hotbar, at Dark Souls pace: fewer enemies, and every fight is deliberate and deadly. The feeling I want is real frustration and real excitement, like Tarkov. Loot should make you want to replay and kill bosses again.

# Theme & lore
- Setting: a grounded medieval land like Oblivion's. It starts low fantasy (humans only) and gets darker and more fantastical deeper in (dwarves, elves and more magic later).
- Tone: bleak but heroic, with dark humor. Try-hard heroes get wiped out; you survive by being cunning and experienced.
- Conflict: two factions at war, both evil and both enemies of the players. The White Knights are zealous, brainwashed try-hards. The Dark Ages are straight evil. Players are a third party caught in between as a new age begins.
- Death lore: TBD. Placeholder: players' souls are bound to old shrines (the checkpoints) that neither faction controls.
- Story is cryptic: no cutscenes, short and vague item descriptions, a few cryptic NPCs.
- Everything is original: no names, lore or assets from other games.

# Art & audio
- Style: Warhammer Online meets Champions of Norrath. Simple proportions early; armor gets bigger and more exaggerated at higher levels (spikes, skulls, chains, tattered banners).
- Washed-out, dark palette. Mostly cloudy and foggy, with a day/night cycle and rain on and off.
- Camera: over-the-shoulder third person with lock-on.
- High gore: blood splatter and decals now, dismemberment later.
- Minimal Souls-style HUD: health, stamina, class resource, flask count, ability hotbar, party frames. WoW-style floating damage numbers. Enemy health bars above heads, toggleable.
- Grid inventory and paperdoll like Champions of Norrath.
- Ambient zone music like Elden Ring or WoW's forest zones. Heavy medieval sound effects.
- Budget is $0: use free CC0 asset packs (Quaternius, KayKit, Kenney, Poly Haven, etc.) plus AI-generated art I'll make. Keep an ART_NEEDS.md list of what we need. Set up lighting, fog and post-processing from day one so it looks dark even with placeholders.

# Characters & combat
- 3 fixed classes at launch: tank, healer, melee DPS. Suggest names and ability kits.
- WoW-style stats on gear (Strength, Agility, Intellect, Stamina, Armor). XP from kills, level cap 30, about 30 hours to max. Small talent tree per class.
- Character creator with presets.
- Combat: light and heavy attacks, block, parry/riposte, poise. Stamina powers attacks, dodging, blocking and sprinting. Dodge roll and jump both have short i-frames. Soft auto-target by default, with a lock-on toggle for elites and bosses.
- Each class has a hotbar of 4–6 abilities on cooldowns, plus one class resource.
- Weapons: swords, axes, maces, greatswords, spears, bows, staves, each with its own moveset.
- Healing: everyone carries limited flasks that refill at checkpoints. Healer heals must be aimed (projectiles or ground zones) and have cooldowns, so bosses stay hard.
- Tanks: threat table plus taunts. Bosses switch targets only on telegraphed attacks.
- Souls difficulty. Enemy HP and poise scale per player, and bigger groups face extra adds.
- Status effects: bleed, poison, frost buildup.
- Movement: weighty. Sprint, jump, roll; heavier gear means a slower roll. Ladders only, no swimming yet, fall damage on.

# Enemies
- Humanoids from both factions plus Warhammer Online-style monsters. Patrols, packs, ambushes, enemies that call for help.
- Enemies respawn when you rest at a checkpoint (Souls style).
- Named rare spawns with unique loot. Bosses with phases, fog gates and telegraphed attacks. World bosses later.

# Loot & economy
- WoW rarity colors (Common to Legendary). Fixed base stats; Rare and above get a random bonus roll. Item level rises with progression.
- Gear slots like Champions of Norrath.
- No upgrades, set bonuses, durability, crafting, gathering or survival needs.
- Group loot uses need/greed rolls. Free trading between players.
- Two currencies, gold and souls, both spent at NPC vendors. Bank at checkpoints.

# Death
- When you die, you drop everything except your 3 most valuable items: gear, inventory, gold and souls. There's no grave marker; it drops as a glowing loot pile.
- Only you and your party can pick it up. It lasts 60 minutes (server setting). If you die again before recovering it, the old pile is gone.
- If you die in a boss room, the pile spawns at the boss door.
- You respawn at the last checkpoint you rested at.

# World
- Small handcrafted zones like Champions of Norrath for now, linked by checkpoints. A more Elden Ring-style open world later. Handcrafted layouts with procedural enemy spawns.
- First zone: low fantasy countryside outside a Camelot-like castle city, 5–10 minutes across on foot. One cave dungeon with a boss.
- Bonfire-style checkpoints: rest to heal, refill flasks and respawn enemies. Use the bank and fast travel between checkpoints.
- Fog-of-war map. Hidden shortcuts that loop back.
- An upgradeable camp that enemies raid at night (after the first milestone).

# Multiplayer
- Host-and-play: the host's game is the server and has authority. Join by direct IP or LAN for now; server browser later.
- Characters are saved locally and can move between worlds. The host saves world progress (like Valheim).
- Party frames and text chat. PvP later.

# Tech
- Godot 4, GDScript.
- Data-driven: items, enemies, classes, abilities and loot tables live in data files, not hardcoded.
- Use git and commit after every working step so we can roll back.

# Build order (each phase must be playable before the next)
1. Setup: install Godot, create the project structure, DESIGN.md and TODO.md.
2. Player controller: camera, movement, sprint, jump, dodge roll, stamina, soft target and lock-on.
3. Combat core: attacks, block, parry, poise, hit-stop, blood, damage numbers, flasks, one enemy with telegraphed attacks.
4. Multiplayer: host/join by IP; players, enemies and combat synced for 3 players.
5. Classes: 3 classes, hotbars, resources, threat/taunt, XP and leveling.
6. Loot: grid inventory, gear slots, rarity, loot tables, need/greed, gold and souls, vendor, bank, character save/load.
7. Death system as described above.
8. First zone: layout, 3 enemy types, a named rare, checkpoints, fast travel, map, day/night, rain, a hidden shortcut, world save/load.
9. Cave dungeon and boss, tuned for 3 players with scaling.

First milestone = 3 friends can clear one zone and one dungeon.

Later: camp and night raids, quests and public quests, more zones and zone unlocks, more races, world bosses, New Game+, server browser, PvP.

# How to work
- Read all of this first, then write DESIGN.md and the project structure. Before writing any code, ask me anything whose answer would change the design.
- One phase at a time. After each phase, tell me exactly how to run it and what to test, then stop and wait for my feedback.
- Explain things in plain language; I'm not a programmer.
- Don't gold-plate. Get it working, then make it good.
