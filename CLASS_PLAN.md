# CLASS_PLAN: primary classes, subclasses, factions

*Planning notes only. Nothing in this file is built yet. Written 2026-11-21 from your class/subclass/faction brief and a read of the current code.*

> **Update (2026-11-21, later): Priorities 1, 3 and 4 are mostly built** (data types, saves and sync, the level 10 choice screen, faction and subclass lore data, and abilities for Warrior, Guardian and Cleric); the rest is paused by you. **Earlier update: Priority 2 is done in a new form.** The three primary classes (Martial / Vanguard / Mystic, with abilities at levels 2, 4, 6) are built; see DESIGN.md section 6. Subclasses, factions and the level 10 choice are still future work. Decisions so far: the subclass choice can be re-picked in future; the three names are provisional. Talents were rewritten for the new abilities (they stay per class for now).
>
> **Original status (2026-11-21): planned only, nothing built.** Next step is Priority 1 (section 3). The five questions in section 4 are still open, and none of them block Priority 1. The live classes are still Bulwark, Lamplighter and Headsman (DESIGN.md section 6).

## 1. What you asked for (kept so nothing is lost)

### Primary classes (chosen at level 1, creator)
| Primary | Role | Subclasses (unlock at level 10) |
|---|---|---|
| **Martial** | Physical DPS | Warrior/Weaponmaster, Rogue/Assassin, Ranger/Marksman |
| **Vanguard** | Tank / defense | Guardian/Shieldbearer, Paladin, Warden/Spiritbinder |
| **Mystic** | Magic / healing / support | Cleric/Healer, Mage/Arcanist, Warlock/Occultist |

Subclass identities:
- **Warrior / Weaponmaster:** greatswords, axes, longswords, dual weapons. Heavy physical damage, weapon combos, parries, counters.
- **Rogue / Assassin:** daggers, short swords, throwing knives. Crits, stealth, backstabs, poison, bleed, mobility.
- **Ranger / Marksman:** longbows, shortbows, crossbows, spears. Ranged damage, precision, traps, tracking, weak points.
- **Guardian / Shieldbearer:** sword and shield, tower shields, maces. Blocking, taunting, counters, high defense, ally protection.
- **Paladin:** swords, shields, maces, warhammers. Defensive auras, protective abilities, sacred attacks, group support.
- **Warden / Spiritbinder:** staves, axes, spears, ritual charms. Summoned companions, spirit guardians, protective rituals, battlefield control.
- **Cleric / Healer:** healing, cleansing, blessings, recovery. Early healing is herbs, bandages and remedies; powerful magical healing comes later.
- **Mage / Arcanist:** fire, ice, lightning, arcane. Projectiles, area attacks, crowd control. Grows more powerful as the story progresses.
- **Warlock / Occultist:** curses, life drain, damage over time, dark rituals, debuffs. Later blood magic, soul manipulation, demonic summons, forbidden entities.

### Progression rules
- **Levels 1-9:** develop the primary class (basic weapons, techniques, class abilities). **No subclass-exclusive abilities.**
- **Level 10:** choose ONE subclass. It should feel meaningful and permanent. Players can preview each subclass (identity, weapon specialties, progression direction) before choosing.
- **Level 10+:** subclass-specific abilities, passives, weapon specialties and advanced skills. Structure it so more can be added later.
- Martial and Vanguard must stay viable physical fighters all game; not every class becomes magical. Magic starts rare and frightening and grows more accessible.

### Subclass choice as a world event (lore now, quests later)
| Subclass | Initiation |
|---|---|
| Warrior | A trial of arms, or defeat a formidable opponent |
| Rogue | An infiltration or an assassination |
| Ranger | Hunt a dangerous creature |
| Guardian | Defend a settlement or survive an overwhelming assault |
| Paladin | Take an oath and prove your commitment to it |
| Warden | Bond with an ancient spirit or guardian |
| Cleric | A healing or spiritual rite |
| Mage | Find an ancient magical artifact or forgotten knowledge |
| Warlock | Make contact with something forbidden and survive it |

### Factions (lore only, never a class restriction)
- **The White Knights:** claim to preserve order and peace; really want control and their own authority. Publicly condemn forbidden magic while secretly using it. Noble, disciplined, traditionally medieval look. Associated: Guardians, Paladins, Clerics.
- **The Dark Ages:** embrace forbidden magic as "the next evolution"; rituals, blood magic, sacrifice. Oppose the White Knights but are just as corrupt. Darker, unsettling, still medieval. Associated: Warlocks, Corrupted Mages, Spiritbinders.
- **The Outcasts:** mercenaries, wanderers, survivors, exiles, independents. Neither good nor evil; they refuse both powers. **The natural starting point for player characters.** Associated: Warriors, Rogues, Rangers, and independent practitioners of anything.
- **Rule:** any player may pick any class and subclass whatever their faction ties. A Paladin needn't join the White Knights; a Mage needn't join the Dark Ages. Class = how you fight; faction = your political and cultural ties.

## 2. How this fits the game today (what I found)

The current three classes already match the three primaries closely, so this is a **reshape, not a rewrite**:

| Today | Becomes | Notes |
|---|---|---|
| Headsman (melee DPS, Tally, greatsword) | **Martial** | Tally notches fit crits/combos; keep resource |
| Bulwark (tank, Resolve, sword and shield) | **Vanguard** | Taunt/threat/Resolve already built |
| Lamplighter (healer, Oil, lantern-staff) | **Mystic** | Heals and statuses already built; early flavor needs to become herbs and remedies |

Useful facts about the code:
- A class is one data file (`data/classes/*.tres`) holding 6 abilities (levels 1/3/6/10/15/20), 12 talents, a passive, a resource and starting gear. All stat, passive and talent numbers are read through `CharacterStats`, so a **subclass can be a second data file that layers on top** (extra abilities, passive mods, weapon scaling) without changing combat code.
- The existing level 10/15/20 abilities (Rallying Bellow, Hold the Line, Unbroken; Flare, Beacon, Pyre; Cleave, Feint, Red Mist) can become the **first subclass abilities** (Guardian, Cleric, Warrior) so nothing already built is thrown away.
- Characters are saved by class ID. Old saves (`class_bulwark`, `class_lamplighter`, `class_headsman`) need an alias to the new IDs, and the save needs one new field (`subclass`).
- The hotbar is a fixed 6 slots read straight from the class. Slots 4-6 can show "Lv 10: choose a path" until a subclass is picked.
- **Ability "kinds" are code.** Each ability's behaviour lives in `ability_caster.gd`, so new unique mechanics (stealth, traps, companions, curses, auras, new spells) each need real code. That is where most of the effort is, not the data files.
- **Risks to handle:** (1) the 12 talents per class include ones that modify level 10+ abilities, which would show for players who never get those abilities; (2) `class_check` tests every ability of every class by name and level and will need rewriting; (3) other players see your class over the network, so the sync needs the new IDs.

## 3. Priorities (what to build, in order)

### Priority 1: Foundations (small, safe, do first)
- `SubclassData` and `FactionData` resource types, so lore and subclass content are **data files, not code**. Fields: ID, name, primary class, tagline, identity text, weapon specialties, progression direction, abilities (levels 10/15/20), passive and its mods, faction association, initiation title and story, "planned abilities" notes.
- `CharacterStats` gets an optional subclass: layers its abilities and passive on the class; `can_choose_subclass()` is true at level 10 with none chosen.
- Save and load the subclass. Alias the old class IDs. Sync the subclass over the network the same way class is synced.

### Priority 2: Level 1 primary classes (your item 3)
- Rename the three classes to Martial / Vanguard / Mystic with new descriptions, keeping their gear and resources (so the feel you just approved doesn't change).
- Trim each to the three level 1-9 abilities (levels 1/3/6); rewrite their texts. Mystic's early abilities get herb/poultice/bandage flavor (same mechanics, new names).
- Update the character creator text (role, story, all characters begin as Outcasts).
- Rewrite `class_check` for the new structure.

### Priority 3: Level 10 subclass choice (your item 4)
- "Choose your path" at any shrine once you reach level 10, plus a banner at level 10.
- A preview screen showing all three subclasses of your class: identity, weapon specialties, progression direction, abilities (built and planned), the initiation lore, and the faction association. A confirmation that says the choice is permanent.
- Hotbar slots 4-6 unlock with the subclass. First abilities for each subclass reuse existing mechanics where they fit (Guardian, Cleric, Warrior first); the rest are marked "planned".

### Priority 4: Lore and faction framework (your items 5 and 6)
- Faction data files (White Knights, Dark Ages, Outcasts) and each subclass's initiation story written into its data, shown in the preview.
- Update DESIGN.md sections 2 and 6 to match this plan.
- Faction association is **display only**: no gating anywhere.

### Priority 5: Unique subclass abilities (largest; one subclass at a time)
Roughly easiest to hardest, by how much new code each needs:
1. **Guardian, Warrior, Cleric:** mostly reuse existing mechanics.
2. **Paladin:** needs persistent party auras (new "aura" effect).
3. **Mage:** needs damage spells (fire/ice/lightning projectiles and areas) and crowd control.
4. **Rogue:** needs stealth/detection, backstab, throwing knives, a poison buff.
5. **Ranger:** needs ability-driven ranged shots, traps, tracking, weak-point hits.
6. **Warlock:** needs damage over time, life drain, curses (debuffs); later blood magic, soul and summon systems.
7. **Warden:** needs summoned companions and AI allies (the biggest single system).

### Priority 6: Initiation events (needs the quest system, which is on the "Later" list)
- Until quests exist, the shrine choice stands in for every initiation. The data keeps a hook so each subclass can later require its trial.
- Order that suits what already exists: Warrior (defeat a named elite, like Hobb), Ranger (hunt a rare), Guardian (defend a spot, using the spawn director), then the more story-heavy ones (Paladin oath, Warden spirit bond, Cleric rite, Mage artifact, Warlock forbidden contact, Rogue infiltration).

### Priority 7: Rebalancing and polish
- Per-subclass talent trees, weapon proficiencies, subclass visuals, magic growing with the story, tuning for 3 players.

## 4. Decisions I'll need from you (none block Priority 1)
1. **Re-pick later?** The brief says the choice should feel permanent. Should there be any way to change it (a rare item, a New Game+), or never?
2. **Interim gate:** until the quests exist, is "choose at any shrine at level 10" fine, or should it wait for a placeholder trial (such as defeating a named elite) from the start?
3. **Starting weapons:** keep today's (greatsword, sword and shield, lantern-staff) for the three primaries, or give each something more generic?
4. **Talents:** keep the current 12 per class for now (some will point at abilities not yet unlocked), or move talents under the subclasses?
5. **Names:** keep "Martial / Vanguard / Mystic" and the slash names ("Warrior / Weaponmaster") as final, or shorten the display names?
