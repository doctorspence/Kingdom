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

### 2026-11-23: KINGDOM inventory and character panel UI standard
- **Area:** UI / loot
- **Decision:** Adopt the approved Champions of Norrath-inspired combined character and spatial inventory screen, with Oblivion-inspired top navigation. The clarified equipment layout is authoritative for the UI: one ring slot, no belt slot, and one Utility slot that also equips the cloak. Keep the existing two weapon sets and their swap behavior; the character panel shows the currently active main-hand and off-hand slots.
- **Details:** Keep the player character visible beside the backpack at all times. Left: spatial backpack grid with real item footprints, stack counts, rarity borders, weight/capacity, sorting, drag-and-drop, and rotation where appropriate. Center: 3D character on a pedestal with equipment slots around the paperdoll. Right: level/XP, attributes, combat stats, health, mana, stamina. Equipment slots: Head, Shoulders (directly beneath Head), Chest, Hands, Legs, Feet, Neck, Ring (exactly one), Utility (cloak uses this slot), active Main Hand, active Off Hand (weapon or shield). There is no Belt slot. Existing two weapon sets remain a gameplay feature; provide a way to inspect/swap the active set without adding four permanent paperdoll slots. Top tabs, in order: Character, Inventory, Map, Talents, Quests, System. Remove Magic and Help. Preserve the dark, ornate, aged-gold medieval fantasy look and controller navigation. Item footprints must be data-driven and prevent overlap/out-of-bounds placement; item selection supports inspect, compare, equip, drop and mark-junk actions.
- **Status:** decided
- **Replaces:** The previous UI mockup slot arrangement (including belt and separate ring/utility assumptions); clarifies DESIGN.md 9.2 for the displayed equipment slots. Does not remove the existing two-weapon-set gameplay system.


## Filed
_(nothing yet)_
