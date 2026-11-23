# DESIGN INBOX: ChatGPT → Claude Code

Design and art-direction decisions made in ChatGPT land here. Claude Code reads this file at the start of every session.

## How ChatGPT (or the owner) adds an entry
Add it at the top of **Waiting**, using this format:

```
### YYYY-MM-DD: short title
- **Area:** art direction / zone 1 / zone 2 / zone 3 / Gullet / classes / factions / UI / combat / loot / other
- **Decision:** what was decided, in plain words
- **Details:** colors (hex), materials, shapes, references, numbers
- **Status:** decided / idea, not decided yet
- **Replaces:** the older decision or doc section this overrides, if any
```

Keep each entry short and concrete. "Idea" entries are for planning only: Claude Code must not build them.

## How Claude Code handles the inbox
1. Read everything under **Waiting**, and tell the owner what's new.
2. For each **decided** entry: write it into the right doc (art direction and palette: `DESIGN.md` 12.1; zones: `ZONES_DESIGN.md`; Zone 1 look: `GREENWOOD_OVERHAUL.md`; the Gullet: `GULLET_DESIGN.md`; classes and factions: `CLASS_PLAN.md`; art needs: `ART_NEEDS.md`). Add any new work to `PRIORITIES.md` or `TODO.md`.
3. If an entry clashes with `SPEC.md`, an existing doc or what's built, ask the owner before filing it.
4. Move the entry to **Filed**, saying where it went. Commit and push.

---

## Waiting

_(nothing waiting)_

## Filed

### 2026-11-23: Inventory and character equipment screen
- **Area:** UI
- **Decision:** One combined screen, laid out like the owner's reference image: spatial backpack grid on the left, the player's 3D character on a pedestal in the middle with equipment slots around it, level, attributes, combat stats and resources on the right. A horizontal tab bar on top (Character, Inventory, Map, Talents, Quests, System) with a gold underline and glow on the current tab; L1/R1 cycle tabs.
- **Details:**
  - Left slots, top to bottom: Helmet, Shoulders (directly under the helmet), Chest, Gloves, Belt, Legs, Boots. Right slots: Necklace, Ring (one slot only), Main hand, Off hand (shields, secondary weapons, other off-hand gear), Utility / accessory. Every slot shows the equipped item's icon.
  - Backpack: items take their real size (potion 1×1, ring 1×1, dagger 1×2, sword 1×4, shield 2×2, helmet 2×2, chest 2×3, boots 2×2), no overlap, nothing outside the grid, rotation where it makes sense, drag and drop, stack counts, weight / carrying capacity, rarity border colors, auto-sort, category filter tabs (L2/R2).
  - Item details: name, rarity, damage or defense, attack speed, weight, value, special bonuses, required level; actions Equip, Compare, Drop, Mark Junk.
  - Right panel: level and XP bar, Strength, Intelligence, Willpower, Agility, Endurance, Personality, Luck, Attack, Defense, Spell Power, Spell Resistance, Health, Mana, Stamina.
  - Look: dark medieval, ornate aged-gold frames, stone and weathered metal, warm torchlight, ivory serif text, subtle gold highlights, detailed readable icons. "A premium early-2000s fantasy RPG, remastered."
  - Tech: functional grid, data-driven item sizes, slot validation, equipping updates the character's look and stats, resolution-independent, mouse/keyboard and controller, data kept separate from the UI.
- **Status:** decided (pasted by the owner into Claude Code chat)
- **Replaces:** the old plain inventory panel (`game/ui/inventory_panel.gd`, removed). Clashes, settled with the owner 2026-11-23: gear slots in `DESIGN.md` 9.2 (cloak, 2 rings, 2 weapon sets, no belt), stats in `DESIGN.md` 7 (Strength, Agility, Intellect, Vitality, Armor; class resources instead of mana), sword size 1×3 in `DESIGN.md` 9.3, and "crafting materials" (SPEC: no crafting or gathering).
- **Owner's answers (2026-11-23):** show the game's real stats (Strength, Agility, Intellect, Vitality; Attack, Defense, Ability Power, Critical; Health, Stamina, class resource) in the reference layout, no new attributes or mana. Cloaks go in the Utility slot; **no belt slot for now**. Keep both weapon sets (the slots show the active set, with a switch). Keep item sizes (one-handed swords 1×3); no crafting materials.
- **Filed:** built (`game/ui/character_screen.gd`, `ui_style.gd`, `character_preview.gd`); `DESIGN.md` 9.2, 9.3, 12.3; `TODO.md` "Inventory and character screen"; `ART_NEEDS.md` Phase 6 rows.

