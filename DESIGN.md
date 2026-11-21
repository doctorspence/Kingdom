# KINGDOM: Design Document

*Working title. A living document that we update as we build and playtest.*
*Last updated: 2026-11-21 (Phase 9; Nioh 2 movement, extra attacks, enemy spacing).*

> **How to read this.** Sections 1–12 describe the game: what players see and do. Section 13 is the technical plan: how we build it. Numbers marked *(start)* are first guesses. We tune them by playing.

---

## 0. Decisions

### You decided
| Topic | Decision |
|---|---|
| Downed state | In co-op you collapse and bleed out for ~20 s instead of dying outright. A friend can revive you by holding a button, which spends one of **their** flasks. Solo, you die instantly. |
| Boss farming | Bosses respawn when you rest at a shrine. Anything the first kill unlocks (doors, shortcuts) stays unlocked for good. |
| Controls | Built for mouse & keyboard first, with full gamepad support (menus included) added alongside. |
| Tools | Godot 4.7.2 (standard version, GDScript) and Git, installed with winget. |

### I decided (tell me and I'll change any of these)
1. **The gear stat "Stamina" is renamed "Vitality"** (it adds health) so it isn't confused with the stamina bar.
2. **Everyone on a server is one party** (up to 10). Separate parties can come later with PvP.
3. **Any class can use any weapon or armor.** Stats and weight decide what suits you, Souls-style, so more drops matter to everyone. Shield abilities need a shield.
4. **To parry, you raise your block at the last moment** (a tight timing window). There's no separate parry button. Mistime it and you just block.
5. **In co-op, resting respawns the whole zone**, except enemies near a player or already in a fight, so nothing pops in on top of your friends.
6. **Dying does not respawn enemies.** Only resting does.
7. **A friend can recover your loot pile for you**, and the items go straight back to you.
8. **Your loot pile has no map marker.** It glows, but you have to remember where you fell.
9. **The bank belongs to your character.** It travels with you between worlds and is safe from death.
10. **Gold, souls and XP go to everyone nearby in full.** No splitting, so no kill-stealing. Items use need/greed.
11. **Arrows are unlimited.** No ammo management, in line with "no survival needs".
12. **Lock-on works on any enemy.** Soft auto-target handles most small fights; lock-on is for elites and bosses.
13. **The renderer is Forward+**, because it's the only Godot renderer with volumetric fog. Your GTX 1080 Ti handles it easily. The target for friends' PCs is a GTX 1060-class card or better.

---

## 1. Pillars
1. **Every fight is a decision.** Few enemies, readable telegraphs, deadly hits. Mashing buttons gets you killed.
2. **Risk what you carry.** Death strips you down to your three best items. The tension lives in the bank, the run back and the "one more fight?" decision.
3. **Loot worth bleeding for.** Random rolls on Rare and up, named rares, boss uniques, and rarity colors that pop against a gray world.
4. **Friends make it possible, not easy.** Real roles (tank, healer, damage), revives that cost flasks, enemies that scale with your group.
5. **Bleak, heroic, and a little funny.** A cryptic world with gallows humor in item text and NPCs.

---

## 2. World, tone & lore
*All names are placeholders. Rename anything.*

> **Planned lore update (not built yet; see `CLASS_PLAN.md`).** Three major groups: the **White Knights** (claim to keep order, really want control; publicly condemn forbidden magic while secretly using it), the **Dark Ages** (embrace forbidden magic as the next step of civilization; blood, ritual and sacrifice) and the **Outcasts** (mercenaries, exiles, survivors who refuse both; the natural starting point for player characters). Faction ties are lore only and never restrict a class or subclass. The bullets below are the current, shorter version.

- **The land.** A grounded medieval kingdom: mud, stone, rain, plague pits, tithe barns. It starts low fantasy (humans only, magic rare and doubtful) and gets darker and stranger the deeper you go. Dwarves, elves and open sorcery come later.
- **The White Knights.** A zealous holy order of brainwashed try-hards. Bleached tabards, tarnished gold and endless rules. They "cleanse" villages and tax what's left. They hold the castle city of **Highcrown**.
- **The Dark Ages.** Straight evil: raiders, cultists and warlords who burn things because burning is the point. Rust, black iron, trophies.
- **The players.** A third party caught between them as a new age begins. Your souls are bound to **old shrines** that neither faction controls (placeholder death lore), so you keep coming back. Try-hard heroes get wiped out; you survive by being cunning and experienced.
- **Storytelling.** No cutscenes. Item descriptions are one or two lines, cryptic, often darkly funny:
  - *Hobb's Noose:* "They hanged him twice. He kept the rope."
  - *Zealot's Tabard:* "Bleached white. Stays white. Nobody asks how."
  - *Shrine Flask:* "Tastes of candle smoke and somebody else's prayers."
- **A few cryptic NPCs.** The **Soul Broker** trades for souls at shrines and never shows its face. **Old Wenna**, a deserter's widow, sells gear for gold and doesn't ask where you got yours.
- **First places.** The countryside outside Highcrown is **the Tithelands** (zone 1). Its cave dungeon is **the Gullet**, home of **Brother Tallow, the Candle-Saint**. The zone's named rare is **Hobb the Unhanged**.

---

## 3. What a session feels like
You host your world; two friends join by IP. You rest at the Crossroads shrine and the Tithelands fill with enemies rolled fresh from spawn tables. Tonight there's a rumor of Hobb the Unhanged at the mill. The tank pulls a White Knight patrol, a zealot blows a horn and two more come running. The healer lobs embers that have to actually land on people. Someone gets greedy, chases a fleeing hound into the woods and gets downed by the pack. A friend burns one of their last flasks to drag him up. Hobb drops a blue amulet with a great bonus roll; the need/greed roll is tense. In the Gullet, the boss kills you twice. Your gear lies in a glowing pile at the boss door, and you have one shot to get it back before something worse happens. That's the game.

---

## 4. Controls *(start: we tune these in Phase 2, rebinding comes later)*
| Action | Mouse & keyboard | Gamepad (Xbox names) |
|---|---|---|
| Move / camera | WASD / mouse | Left stick / right stick |
| Walk | Ctrl (hold) | Tilt the stick gently |
| Light attack | Left mouse | RB |
| Heavy attack (hold to charge) | Middle mouse | RT |
| Block (tap at the last moment = parry) | Right mouse (hold) | LB |
| Dodge roll | Shift (tap) | B (tap) |
| Sprint | Shift (hold) | B (hold) |
| Jump | Space | A |
| Lock-on / switch target | Q / mouse wheel | R3 / flick right stick |
| Drink flask | R | X |
| Interact (shrines, doors, loot, revive) | E | Y |
| Abilities 1–6 | 1–6 | Hold LT + A / B / X / Y / RB / RT |
| Swap weapon set | X | D-pad right |
| Inventory + character | I | View |
| Map | M | D-pad up |
| Chat | Enter | n/a |
| Menu | Esc | Menu |

---

## 5. Combat
Dark Souls pace: every swing commits you, every hit hurts, and stamina is the clock you fight against.

### 5.1 Stamina
- Powers attacks, rolls, blocks, jumps and sprinting. Max 100 at level 1, +1 per level *(start)*.
- Regenerates 35/s after a 0.6 s pause (half speed while blocking) *(start)*.
- Costs *(start)*: light attack 10–22 (by weapon weight), heavy attack 20–40, roll 18, jump 12, sprint 10/s, block = depends on the hit and your shield.
- If stamina hits 0 while you block, your **guard breaks** (1.2 s stagger).

### 5.2 Movement
- **Weighty**: acceleration and turning take time; no instant 180s while sprinting.
- Speeds *(start)*: walk 2.6 m/s, run 6.8 m/s, sprint 9.6 m/s, moving while locked on 5.0 m/s (Nioh 2-style snappy; see `data/balance`).
- **Jump**: ~1.1 m high, short i-frames at take-off (~0.12 s).
- **Dodge roll** with i-frames. Speed depends on **equip load** (gear weight ÷ capacity; capacity = 60 + 0.5 × Strength *(start)*):

| Load | Roll | Distance | I-frames *(start)* |
|---|---|---|---|
| Light (≤30%) | fast, 0.55 s | 4.0 m | 0.33 s |
| Medium (≤70%) | normal, 0.65 s | 3.5 m | 0.28 s |
| Heavy (≤100%) | slow, 0.85 s | 2.5 m | 0.22 s |
| Overloaded (>100%) | can't roll or sprint | n/a | n/a |

- **Fall damage**: none under 5 m, then rising sharply; over ~15 m kills you.
- **Ladders** only for climbing. **No swimming yet**: water in zone 1 is shallow (wading slows you), and deep water counts as a fatal fall.

### 5.3 Attacks & weapons
Light attacks chain into 2–3 hit combos. Heavy attacks can be charged. Running, rolling and jumping attacks come per weapon. Each weapon type has its own moveset:

| Weapon | Hands | Scales with | Feel |
|---|---|---|---|
| Sword | 1H | Str + Agi | Fast and balanced; slashes, thrusting heavy |
| Axe | 1H | Str | Hooking swings, bleed buildup |
| Mace | 1H | Str | Slow and heavy poise damage; good against armor |
| Greatsword | 2H | Str | Wide slow sweeps; can't be interrupted during heavy swings |
| Spear | 1H | Agi | Long thrusts; can poke while blocking with a shield |
| Bow | 2H | Agi | Hold to draw, release to fire; unlimited arrows |
| Staff | 2H | Int | Sweeping bonks; boosts the Lamplighter's healing |
| Shield | Off-hand | Str | Blocks well; light shields parry easier, heavy ones block more |

#### Extra moves (Elden Ring-style)
Every weapon also has these, made from its light and heavy attacks unless its data file sets its own:

| Move | How |
|---|---|
| Jump light / jump heavy | Attack while in the air |
| Plunging attack | Attack while falling from 2.5 m or more above the ground: you dive and land with a wide heavy blow (no fall damage) |
| Running light / running heavy | Attack while sprinting |
| Rolling light / rolling heavy | Attack right after a roll |
| Backstep attack | Light attack right after a backstep (a roll with no direction held) |
| Guard counter | Attack while your guard is raised |

The weapon data holds these as optional `jump_light`, `jump_heavy`, `plunge`, `guard_counter`, `running_heavy`, `rolling_heavy` and `backstep_attack`.

### 5.4 Block, parry, riposte
- **Block** (hold): covers a 120° arc in front of you. Shields stop nearly all physical damage; weapons stop ~60%. Each blocked hit drains stamina based on the shield's stability.
- **Parry**: the first ~0.18 s after you raise your block (up to ~0.25 s with light shields) *(start)*. A parry negates the hit.
  - Normal enemies: staggered and open to a **riposte** for ~1.5 s.
  - Elites: take heavy poise damage; a few parries stagger them.
  - Bosses: only some attacks can be parried; each parry deals big poise damage.
  - Mashing doesn't work: you only get a parry window if you weren't already blocking a moment ago.
- **Riposte**: press light attack on a staggered enemy in front of you for a critical strike (~3× damage). You can't be hurt during the animation.
- **Telegraph colors**: a white glint means the attack can be parried. A red glow means it's unblockable (a grab or a crushing blow), so dodge it.

### 5.5 Poise & stagger
- Everyone has **poise**. Each hit chips it; at 0 you're staggered and poise resets. It refills after ~3 s without being hit.
- Players: base poise plus armor poise. Heavy weapons add temporary poise during heavy swings.
- Bosses have huge poise. Breaking it causes a **stance break**: they kneel for ~3 s, open to a critical hit.

### 5.6 Hit feel
- **Hit-stop**: a tiny freeze on impact (0.05 s light, 0.09 s heavy, 0.15 s critical) plus camera shake.
- **Blood**: spurts at the hit point and splatter decals on the ground and walls (they fade after a few minutes). A gore option in settings: Off / Low / High (default High). Dismemberment comes later.
- **Floating damage numbers**, WoW-style: white (your damage), big yellow (crits), orange (status bursts), green (heals), gray words ("Blocked", "Parry!"). Toggle in settings.
- **Enemy health bars** above heads appear once an enemy is hurt or targeted. Toggle in settings.

### 5.7 Targeting
- **Soft target (default)**: when you attack, your character turns toward the best enemy within ~4 m in the direction you're pushing (or facing). No camera lock.
- **Lock-on toggle**: the camera and your facing follow one enemy and you strafe around it. Switch targets with the mouse wheel or a stick flick. **A quick sideways mouse flick (about 260 px within 0.2 s) lets go of the lock.** It breaks beyond ~25 m or after ~2 s out of sight. Elites and bosses get a bigger lock marker.

### 5.8 Healing & flasks
- Everyone carries **4 flasks** *(start)*. Each heals 40% of max health. Drinking takes ~1.2 s and slows you to a walk, and you can be hit mid-drink.
- Flasks refill when you rest at a shrine or respawn.
- **Healer heals must be aimed** (projectiles that can miss, and ground zones people must stand in) and have cooldowns, so bosses stay hard.

### 5.9 Downed & revive (co-op only)
- At 0 health you're **downed** if any party member is still alive. You can crawl slowly, and you bleed out in 20 s.
- A friend revives you by holding Interact next to you for 3 s (1.5 s for a Lamplighter). **It costs them one flask**, so a friend with no flasks can't revive you. You get up with 30% health.
- Each time you go down in the same fight, your next bleed-out timer is shorter (20 s → 12 s → 6 s). Resting resets it.
- If the whole party is down, everyone dies.
- Most enemies ignore downed players. A few cruel ones finish them off.
- Solo, there is no downed state: you die.

### 5.10 Status effects (buildup meters, Souls-style)
| Effect | When the meter fills | Cured by |
|---|---|---|
| Bleed | Burst of ~15% max health | Meter resets on its own |
| Poison | ~1.5% max health per second for 20 s | Antidote, Lamplighter's Snuff, resting |
| Frost | Burst of ~10% max health, then 15 s of slower movement, weaker stamina regen and +15% damage taken | Warming draught, Snuff, resting |

Meters drain on their own if you stop taking that kind of hit. Enemies suffer the same effects.

### 5.11 Threat & taunts
- Every enemy keeps a **threat table**. Damage builds threat (1 per point; the Bulwark makes 2.5×). Healing builds a little threat on enemies fighting the person healed.
- **Normal enemies** switch to whoever has the most threat once that player passes the current target by 10% (30% for ranged attackers).
- **Bosses switch targets only at the start of telegraphed attacks**, turning and glaring first, so switches are readable.
- **Taunts** put the tank on top and force the enemy to attack them for a few seconds. On a boss, the switch happens at its next telegraph.

### 5.12 Damage math *(start)*
- **Damage** = weapon damage × attack multiplier × (1 + stat bonus) × crit × (1 − armor reduction).
- **Stat bonus** = Σ(stat × weapon scaling) ÷ 100. Example: a sword scales 0.5 Str + 0.5 Agi, so 40 Str and 40 Agi give +40%.
- **Crit**: 5% + 0.05% per Agility, for 1.5× damage. Ripostes always deal ~3×.
- **Armor reduction** = armor ÷ (armor + 60 + 15 × attacker level), capped at 75%.

---

## 6. Classes
Three fixed classes at launch. **Names and kits are my suggestions; rename freely.** Each class has a hotbar of 6 abilities on cooldowns, unlocked at levels 1, 3, 6, 10, 15 and 20, plus one class resource. Costs and cooldowns are *(start)*.

> **Built (2026-11-21): the three primary classes.** The classes are now **Martial** (was Headsman), **Vanguard** (was Bulwark) and **Mystic** (was Lamplighter). The names are for now and may change. The internal IDs (`class_headsman`, `class_bulwark`, `class_lamplighter`) stay so saves keep working. Each class has **three abilities, unlocked automatically at levels 2, 4 and 6**, with cooldowns only (Mystic spells also cost Oil). You keep them for good. Subclasses (chosen at level 10, re-pickable in future) are **not built yet** (see `CLASS_PLAN.md`); they will add more abilities on top.
>
> | Class | Level 2 | Level 4 | Level 6 |
> |---|---|---|---|
> | Martial | **Lunge**: dash at your target and strike | **Whirlwind**: spin, hit everything around you | **Battle Fury**: 10 s, +25% damage, +25% attack speed (45 s cooldown) |
> | Vanguard | **Shield Bash**: damage and stagger (needs shield) | **Shield Throw**: shield flies through a line of enemies and returns (needs shield) | **Iron Resolve**: 8 s, -40% damage taken, much harder to stagger (40 s cooldown) |
> | Mystic | **Arcane Bolt**: homing bolt at your target | **Mend**: heal the friend you face, else yourself | **Hex**: 12 s, enemy deals -25%, takes +20% (25 s cooldown) |
>
> The old per-class tables below (levels 1/3/6/10/15/20) describe the previous kits. Their abilities (Challenge, Rallying Bellow, Hold the Line, Unbroken, Kindle, Vigil Lantern, Snuff, Flare, Beacon, Pyre, Hamstring, Behead, Cleave, Feint, Red Mist, Shoulder Charge) still exist in the code and are the first candidates for subclass abilities. Talents were rewritten to fit the new abilities.

### 6.1 Bulwark: the tank
*A deserter from three different shield walls who outlived every one of them.* Starts with a sword, a medium shield and chain armor. Wants Strength, Vitality and Armor.
**Resource: Resolve (0–100).** Builds as you block, parry and take hits. Fades out of combat.

| Lvl | Ability | What it does | Cooldown | Cost |
|---|---|---|---|---|
| 1 | Challenge | Taunt one enemy (20 m): it must attack you for 6 s, and you go to the top of its threat table. | 10 s | none |
| 3 | Shield Bash | Short-range bash: heavy poise damage, interrupts, big threat. Needs a shield. | 8 s | 10 |
| 6 | Shoulder Charge | Rush 6 m. Knocks down light enemies and staggers medium ones. | 15 s | 20 |
| 10 | Rallying Bellow | Taunt every enemy within 8 m for 4 s. Nearby allies take 10% less damage for 6 s. | 30 s | 30 |
| 15 | Hold the Line | Plant your shield for up to 5 s: you block from all sides and allies right behind you take 50% less damage. You can't move. | 40 s | 25 |
| 20 | Unbroken | For 8 s you can't drop below 1 health and take 40% less damage. | 120 s | 50 |

**Passive, Shield-Born:** +25% poise, blocking costs 20% less stamina, attacks make 2.5× threat.
**Talent examples:** *Spiked Rim* (Shield Bash causes bleed), *Stubborn* (Unbroken refills 50 stamina), *Bodyguard* (Challenge shields the ally your target was attacking).

### 6.2 Lamplighter: the healer
*Keeper of the old shrine-flames. Carries a lantern-staff full of oil that burns with something that isn't quite fire.* Starts with a staff and a padded robe. Wants Intellect and Vitality.
**Resource: Oil (0–100).** Trickles back on its own and faster when you land melee hits, so healers stay in the fight. Refills at shrines.

| Lvl | Ability | What it does | Cooldown | Cost |
|---|---|---|---|---|
| 1 | Kindle | Lob an ember in an arc (~20 m). It bursts on impact, healing allies within 2.5 m and singeing enemies. **It can miss.** | 3 s | 15 |
| 3 | Vigil Lantern | Throw a lantern: a 4 m circle that heals allies inside it for 8 s. | 20 s | 30 |
| 6 | Snuff | Throw a smoke vial: allies in the cloud are cured of bleed, poison and frost buildup. | 15 s | 20 |
| 10 | Flare | Blinding flash in front of you (6 m): staggers weak enemies and halves your threat. | 25 s | 20 |
| 15 | Beacon | Mark a spot. 1.5 s later a column of light heals everyone within 3 m for a lot. You have to predict where your friends will be. | 30 s | 40 |
| 20 | Pyre | Plant your staff: a 6 m sanctuary for 10 s. Allies inside regenerate and take 20% less damage; enemies inside burn. | 120 s | 60 |

**Passive, Keeper of the Flame:** revives take half as long; healing scales with Intellect; your heals work at 50% on yourself.
**Talent examples:** *Long Wick* (+50% Kindle range), *Tallow Burn* (Kindle sets enemies on fire), *Lantern Hook* (pick up and move your Vigil Lantern once).

### 6.3 Headsman: the melee damage dealer
*Former royal executioner. Out of work since both factions started doing it for free.* Starts with an executioner's greatsword and leather armor. Wants Strength and Agility.
**Resource: Tally (0–5 notches).** Each hit carves a notch (heavy hits and crits carve 2). Notches fade 8 s after you stop hitting things. Finishers spend them.

| Lvl | Ability | What it does | Cooldown | Cost |
|---|---|---|---|---|
| 1 | Hamstring | Quick cut: big bleed buildup, slows the target 30% for 4 s. +1 notch. | 8 s | none |
| 3 | Behead | Finisher: an overhead execution chop. Damage grows with notches spent, doubled against targets under 30% health. | 6 s | all notches (min 1) |
| 6 | Lunge | Dash-stab up to 7 m, briefly invulnerable at the start. | 12 s | none |
| 10 | Cleave | Wide 180° sweep with poise damage. +1 notch per enemy hit. | 10 s | none |
| 15 | Feint | Fake swing and sidestep: drops 50% of your threat, and your next hit within 3 s is a guaranteed crit. | 20 s | none |
| 20 | Red Mist | 12 s: attacks cost 50% less stamina and heal you for 5% of damage dealt, but you take 15% more damage. | 120 s | none |

**Passive, Practiced Hand:** +10% damage to bleeding targets; ripostes grant 3 notches.
**Talent examples:** *Clean Cut* (a Behead under 30% health refunds 2 notches), *Butcher's Bill* (Cleave causes bleed), *Grim Tally* (max 6 notches).

### 6.4 Leveling & talents
- **XP from kills only.** Everyone in the party within ~50 m gets full XP.
- **Level cap 30, about 30 hours to max** *(start: the XP curve is tuned with playtests)*. Each level raises health, stamina and your class's base stats.
- **Talents**: 1 point every 3 levels (10 total). Each class has a small tree of ~12 talents in 3 rows; row 2 opens at 3 points spent, row 3 at 6. Free respec at shrines for now.
- **Character creator** with presets: class, body type, face/hair/skin presets, name.

---

## 7. Stats
| Stat | What it does | Who wants it |
|---|---|---|
| Strength | +damage with swords, axes, maces and greatswords; +shield stability; +carry capacity | Bulwark, Headsman |
| Agility | +damage with swords, spears and bows; +crit chance; +stamina regen | Headsman |
| Intellect | +healing and ability power; +Oil regen | Lamplighter |
| Vitality | +max health (renamed from "Stamina") | Everyone |
| Armor | −physical damage taken | Bulwark most |

Bonus rolls (section 9) can also add: crit chance, poise, stamina regen, bleed/poison/frost buildup on hit, status resistance and small movement speed bonuses.

---

## 8. Enemies

### 8.1 Behavior
- **States**: idle or patrol → suspicious (investigates a noise) → alert (some **call for help**: a horn, a howl) → combat → return home (if pulled ~40 m from home they walk back and fully heal).
- **Senses**: sight cone ~120° out to ~22 m (less at night); hearing ~6 m, doubled by sprinting and fighting.
- **Taking turns**: at most 2 enemies attack the same player at once while the others circle and threaten. Fights stay readable and deliberate.
- **Telegraphs**: wind-ups of 0.4–1.2 s, readable poses, sound cues, and white/red glints (section 5.4). Some attacks are **delayed** to punish panic-rolling.

- **Bodies are solid.** Enemies collide with each other. Everyone chasing the same player takes an evenly spaced spot on a ring around them, and an enemy with a friend in the way waits for a gap instead of swinging.

### 8.2 Encounter types
**Patrols** walk routes. **Packs** hunt together. **Ambushes** wait hidden and trigger when you pass. **Callers** summon nearby groups unless you silence them first.

### 8.3 Spawning & respawning
- Levels are handcrafted. Spawns are procedural: designers place **spawn points** with a tag (road, camp, woods), and each reset rolls a **spawn table** for each point (for example 50% White Knight patrol, 30% hound pack, 20% nothing).
- **Respawn happens when anyone rests at a shrine** (except near players or in fights; see decision 5). Bosses respawn too.
- **Named rares** have a small chance (~5% *(start)*) to replace a normal spawn at specific points on each reset.

### 8.4 Group scaling *(start)*
- Enemy health ×(1 + 0.6 per extra player). Poise ×(1 + 0.25 per extra player). Damage stays the same.
- Boss health ×(1 + 0.8 per extra player).
- **Extra adds**: spawn points can be marked "3+ players" or "6+ players".
- Player count = players in the same zone, or inside the boss arena when the fight starts.

### 8.5 Bosses
- Arenas behind **fog gates**. Bosses have **phases**, **telegraphed** attacks, a boss health bar, a stance-break mechanic and unique loot.
- Bosses respawn on rest. The first kill unlocks shortcuts and doors for good.
- **Built (Phase 9):** a boss waits until you step inside his arena. His poise is huge: breaking it makes him kneel for 3 s, open to a riposte, and each parry chips 90 poise. He picks his target only as an attack begins (taunts take effect at his next attack). Health is x(1 + 0.8 per extra player in the arena), counted when the fight starts. The fog gate turns solid while he fights. His first kill sets the `gullet_boss_killed` world flag.
- World bosses come later.

### 8.6 First roster
| Enemy | Where | Role |
|---|---|---|
| **Dark Ages Marauder** | Zone 1 | Slow two-handed axe, huge telegraphed swings, bleed. Our Phase 3 test enemy: perfect for learning to dodge and parry. |
| **White Knight Zealot** | Zone 1 | Sword and shield; blocks, shield-bashes, 3-hit combos. Blows a horn for help. Gets stronger when an ally dies nearby ("martyr's fury"). |
| **Gaunt Hound** | Zone 1 | Packs of 3–4: fast lunges, circling, howls for the pack. |
| **Hobb the Unhanged** (named rare) | Zone 1, bandit camp near the mill | Elite bandit chief with a rope still around his neck. Unique drops such as *Hobb's Noose*. |
| **Candle Acolytes** | The Gullet | Weak fanatics; extra boss adds in bigger groups. |
| **Brother Tallow, the Candle-Saint** (boss) | The Gullet | A hulking monk crusted in burning candles with a giant censer-flail. **Phase 1**: wide flail sweeps, a red overhead slam, slowing wax spit. **Phase 2 (under 50%)**: he sets himself alight; faster, fire trails, burning ground, acolytes join. |

---

## 9. Loot & economy

### 9.1 Rarity (WoW colors)
| Rarity | Color | Bonus rolls |
|---|---|---|
| Common | White | none |
| Uncommon | Green | none |
| Rare | Blue | 1 random bonus |
| Epic | Purple | 2 random bonuses |
| Legendary | Orange | 2 random bonuses + a unique legendary effect |

- **Fixed base stats** per item; the bonus rolls are random within a range. The same boss drop can roll weak or amazing, which is the reason to farm.
- **Item level** rises with progression. Zone 1 drops item level 1–10; the Gullet's boss 10–12. Item level scales the base stats and bonus ranges.
- **Drop rates** *(start)*: ordinary enemies sometimes drop an item (mostly Common/Uncommon, rarely Rare+); elites always drop something; named rares drop their unique plus a Rare+; bosses drop 2–3 items, at least one Rare+, with a small Legendary chance.

### 9.2 Gear slots (inspired by Champions of Norrath's paperdoll)
Head, Shoulders, Chest, Hands, Legs, Feet, Cloak, Neck, Ring ×2, and **two weapon sets** (main hand + off hand each), swapped with a key.

### 9.3 Grid inventory
- Items take up shapes on a grid: a ring is 1×1, a sword 1×3, a shield 2×2, a chest piece 2×3. Backpack 10×6 *(start)*.
- **Bank** at every shrine: a bigger grid (12×10 *(start)*), per character, safe from death.

### 9.4 Group loot & trading
- Uncommon and better drops open a **Need / Greed / Pass** roll for party members within ~50 m (30 s timer). Need beats Greed; the highest roll wins.
- Common items: first come, first served.
- **Free trading**: drop an item and a friend picks it up. A trade window comes later if we need one.

### 9.5 Currencies & vendors
- **Gold**: from enemies and selling. Spent at ordinary vendors (consumables, basic gear) and on bank space.
- **Souls**: from every kill. Spent at the **Soul Broker**: a rotating stock of rare gear and special consumables that changes when you rest.
- Both drop on death (section 10).
- **Not in the game**: gear upgrades, set bonuses, durability, crafting, gathering, survival needs.

---

## 10. Death
1. **Downed first in co-op** (section 5.9). Solo, you die at 0 health.
2. On death **you keep your 3 most valuable items** (by item value; equipped ones stay equipped).
3. **Everything else** (other gear, the backpack, all gold, all souls) drops as a **glowing loot pile** where you died. No grave marker, no map marker.
   - Died in a boss room? The pile appears at the **boss door**.
   - Fell to your death? It appears at the last safe ground you stood on.
4. You **respawn at the last shrine you rested at** with full health and flasks. Enemies do not respawn.
5. **Only you and your party** can pick up the pile. A friend can recover it for you, and the items go straight back to you.
6. The pile lasts **60 minutes** while the world is running (a server setting). **Die again before you recover it and the old pile is gone for good.**
7. The bank is always safe. Flasks aren't items, so you never lose them.

---

## 11. World

### 11.1 Zone 1: the Tithelands
The countryside outside Highcrown: about 5–10 minutes across on foot.
- **Crossroads** shrine (start), farms and a burned hamlet, the old road north to Highcrown's gates (White Knight checkpoints), woods to the east (Dark Ages raiders, hound packs), a river with a broken bridge, a ruined watchtower, a quarry in the west with the **Gullet**'s cave mouth.
- Highcrown's walls loom in the northern fog. You can't go in yet.
- **3–4 shrines**: Crossroads, Mill, Quarry, and one inside the Gullet.
- **Hidden shortcut example**: a gate in the watchtower that only opens from the far side and drops you back near the Crossroads.

### 11.2 The Gullet (cave dungeon)
A winding cave under the quarry, wet stone and old bones, getting more candle-lit the deeper you go. Ends at Brother Tallow's chapel behind a fog gate. A shortcut opens after the first kill so the next run is faster. Tuned for 3 players, scaled for 1–10.

**Built (Phase 9, graybox):** the cave is built underground beneath the quarry and entered by a door (E, "Descend into the Gullet") beside the Quarry Shrine, marked by an amber light beam and an always-visible map dot. Rooms: entrance hall, bone gallery, cistern, shrine alcove (the Gullet Shrine), fog gate, chapel. Dark and candle-lit; your belt lantern lights underground. Brother Tallow has two phases (phase 2 under 50%: faster, calls Candle Acolytes, burning ground, fire slam). A long corridor from the chapel back to the entrance hall opens after his first kill. He drops 2-3 items plus the unique Tallow Crown.

### 11.3 Shrines (checkpoints)
Rest to heal, refill flasks, respawn enemies and set your respawn point. Also: **bank**, **fast travel** to other shrines you've found, talents and respec, Soul Broker.

### 11.4 Map, time & weather
- **Fog-of-war map**: reveals as you explore (saved per character, per world). Shows found shrines and party members.
- **Day/night cycle**: about 48 real minutes per day (32 day, 16 night) *(start, a server setting)*. Nights are very dark and more dangerous; you carry a belt lantern.
- **Weather**: mostly overcast and foggy, with rain showers on and off.

### 11.5 Later
An upgradeable camp that enemies raid at night (after the first milestone), quests and public quests, more zones and an open world, world bosses, New Game+.

---

## 12. Look, sound & interface

### 12.1 Art direction
- **Detail target: detailed, not low-poly.** We aim for the level of detail of Warhammer Online and Champions of Norrath: chunky readable silhouettes, slightly exaggerated proportions (big shoulders, big hands, big weapons), rich textures. **The designs are all our own**, never their armor, symbols or factions.
- **Gray shapes first, art later.** Gameplay gets built with placeholder shapes and the art is swapped in afterward. These rules keep the swap painless:
  1. **One standard humanoid skeleton** for every human-shaped character: the 65-bone Unreal-style skeleton used by Quaternius's free animation libraries (bones named `pelvis`, `spine_01`, `upperarm_l` ...). Any model or animation built on it drops straight in. Others can be converted with Godot's retargeting.
  2. **Fixed character size:** about 1.85 m tall, chunky build. Camera distance, doorways (at least 1.6 m wide, 2.6 m tall), weapon reach and level spacing are built around it.
  3. **Gear you can see:** every gear slot (head, shoulders, chest, hands, legs, feet, cloak, weapons) is its own swappable piece on the shared skeleton.
  4. **Real materials and lighting:** standard PBR materials (color, roughness, normal maps) under the shared fog and lighting setup, so detailed and placeholder art sit in the same world.
- **Detail goes where eyes go:** your character and gear, enemies, and anything within a few meters of the camera get the most detail. Distant things stay simpler; fog hides the rest.
- **Environments are built for detail too:**
  - Zones sit on **sculpted terrain with painted texture layers** (mud, grass, road, rock), not flat planes.
  - Every ground, stone, wood and bark surface uses **real tiling textures** (ambientCG, Poly Haven). It's the cheapest big visual upgrade.
  - **Trees, grass and rocks are painted on in bulk** (instanced, so thousands cost little), with **wind sway** and **simpler versions at a distance** (LODs).
  - **Buildings and ruins come from modular kits** (wall, corner, arch, floor pieces) so a few detailed pieces build a whole village.
  - **Budget:** scanned models are often millions of triangles and must be simplified before use. Rough limits: hero tree 20–50k triangles, rock 2–10k, player character with gear 30–60k.
- **Armor gets louder with level**: levels 1–10 are grounded (gambesons, leather, rusty mail, kettle helms). Levels 11–20 add real plate and bigger pauldrons. Levels 21–30 go big: spikes, skulls, chains, tattered banners.
- **Palette**: washed-out earth tones (mud brown, moss green, slate gray). White Knights are off-white and tarnished gold; the Dark Ages are rust red and black iron. **Shrines are the only warm, safe light** (amber). Loot rarity colors pop against the gray.
- **Lighting from day one**: overcast sky, volumetric fog, filmic tone mapping, desaturation and ambient occlusion, so even gray boxes look moody. Nights are cold, blue and genuinely dark.
- **Sources**: free CC0 assets plus your AI-generated art. Poly Haven and ambientCG (detailed textures, rocks, scanned plants) are final-quality. Quaternius, KayKit and Kenney are low-poly, so they're **stand-ins only**, except for things like UI and sound. Detailed characters, armor and props come mostly from your AI art (textures, and image-to-3D for armor and props), cleaned up and fitted to the shared skeleton. See `ART_NEEDS.md`. Every asset gets logged in `assets/CREDITS.md`.

### 12.2 Audio
> **Built (Phase 10, 2026-11-21):** five volume groups with sliders (Master, Music, Effects, Ambience, Interface); combat, ability, loot and menu sounds from named cues (`game/audio/sfx_library.gd`); zone ambience that follows weather, time of day and depth; slow forest music with long silences; a boss track for Brother Tallow (louder in phase 2); knights' horns that carry far. Friends hear each other because sounds play from the animations every machine already copies. All sounds are CC0 stand-ins chosen without listening; see `assets/CREDITS.md`.

- **Music**: ambient zone loops (a forest-zone mood); boss tracks.
- **Sound effects**: heavy and medieval: steel on steel, wet impacts, chainmail foley, grunts, horns, crows, rain, wind, shrine hum. A distinct sound per loot rarity (the Legendary drop sound matters).
- Volume groups: Master, Music, Effects, Ambience, Interface.

### 12.3 HUD & menus (minimal, Souls-style)
- **On screen**: health, stamina and class resource bars; flask count; ability hotbar with cooldown sweeps; party frames (name, health, class, downed); boss bar; status buildup meters; floating numbers; enemy health bars (toggle); chat (fades out).
- **Menus**: main menu (Play/Host, Join, Characters, Settings, Quit), character creator, grid inventory + paperdoll + stats, talents, map, shrine menu (rest, travel, bank, vendors), loot roll pop-ups, settings (graphics, audio, controls, gameplay toggles).

---

## 13. Technical plan
*The "how". You don't need to follow all of this. It's here so the code stays consistent.*

### 13.1 Engine & project settings
- **Godot 4.7.2**, standard build, **GDScript** (Godot's own simple scripting language).
- **Forward+ renderer** (volumetric fog, ambient occlusion, glow). **Jolt** physics engine. 60 physics ticks per second.
- Designed for a 1920×1080 interface that scales to other screen sizes.

### 13.2 Folder layout
```
Kingdom/
├─ README.md        How to open, run and test (plain language)
├─ SPEC.md          Your original brief
├─ DESIGN.md        This document
├─ TODO.md          Phase-by-phase checklist
├─ ART_NEEDS.md     Art & audio shopping list
├─ project.godot    Godot's project file
├─ addons/          Third-party Godot plugins (none yet)
├─ assets/          Art and sound (CC0 packs + your AI art), logged in assets/CREDITS.md
├─ data/            Game data you can edit in Godot's Inspector:
│                   classes, abilities, items, enemies, loot tables, balance numbers
├─ game/            Code + scenes, grouped by feature:
│                   core/ player/ combat/ enemies/ classes/ items/ net/ world/ ui/
├─ levels/          Maps: zones, dungeons, test maps
│  ├─ common/       Shared lighting/fog setups
│  └─ sandbox/      Test maps (look_test.tscn is the Phase 1 mood test)
└─ tests/           Automated checks I run before handing you a build
```

### 13.3 Data-driven design
- Items, enemies, classes, abilities, status effects, spawn tables and loot tables are **data files** (Godot "resources", `.tres`) in `data/`, not code.
- You edit them in Godot's **Inspector** with named fields, number boxes and dropdowns. They're also plain text, so git can track every change.
- Each entry has a permanent **ID** (for example `weapon_rusty_sword`). Saves and network messages use IDs, so renaming or moving files never breaks anything.
- Formula constants (XP curve, armor formula, scaling numbers) live in `data/balance/` for easy tuning.

### 13.4 Multiplayer
- **Host-and-play**: the host's game is the server. Built on Godot's built-in multiplayer (ENet, UDP), default **port 31415**.
- **Who decides what** ("trust friends, favor the dodger"):
  - **The host** decides about enemies (AI, health, poise, threat), loot, items, death piles, spawns, time and weather, and damage to enemies.
  - **Each player** decides about their own movement, rolls and i-frames, blocks and parries, and whether an enemy's attack actually hit them. Your dodges feel right on your screen even with lag. This is fine for friends; PvP will need stricter rules later.
- Players' attacks feel instant on their own screen (hit-stop, blood, numbers), then the host applies the real damage and tells everyone.
- **Even single-player runs as "a host with nobody connected"**, so everything we build in Phases 2–3 is multiplayer-ready and Phase 4 doesn't mean a rewrite.
- **Connecting**: same house = LAN IP. Over the internet, the host either forwards UDP port 31415 on their router or everyone joins a free virtual-LAN app (Tailscale, ZeroTier or Radmin VPN) and uses that IP. A Steam version later would remove that step.
- **Testing**: Godot can launch several game windows on one PC, so we can test 3 players without 3 computers.
- Friends get the game as an exported Windows build (a zip with an .exe). No Godot needed on their side.

### 13.5 Saves
- **Characters** are saved on each player's own PC (level, gear, backpack, bank, gold, souls, talents, look; plus per world: explored map, found shrines, last shrine). They can move between worlds, like Valheim.
- **Worlds** are saved by the host: unlocked shortcuts, first boss kills, time of day, weather, death piles and their timers. Autosave every 5 minutes and on quit.
- Files go in `%APPDATA%\Kingdom\` as readable JSON with a version number, so old saves can be upgraded when the game changes.

### 13.6 Testing & version control
- Each phase gets a **test map** in `levels/sandbox/` and a **"what to test"** checklist in `TODO.md`.
- Before handing you anything, I run automated checks: the project loads without errors, data files are valid, and formulas (damage, XP, loot rolls) give the expected numbers.
- **Git** saves a snapshot (a "commit") after every working step, so we can always roll back.

---

## 14. Open questions (not blocking, decide whenever)
- **Death lore**: why are souls bound to the shrines? Who built them?
- **Final names**: classes, places, factions' leaders, the game itself.
- **Flask upgrades**: can players find items that raise their flask count (a common Souls reward), or does that count as an "upgrade" you don't want?
- **Souls**: anything to spend them on besides the Soul Broker (respecs, fast travel)?
- **Steam**: if you plan to release on Steam, it changes how we do joining later (no port forwarding needed).
