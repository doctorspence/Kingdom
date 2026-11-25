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

### 2026-11-25: White Knights Outpost (north end of the Tithelands, in front of Highcrown's moat)
- **Area:** zone 1 / art direction / factions
- **Decision:** A small permanent medieval settlement just outside Highcrown's gate (inn, civilian blacksmith, stables and farrier, market, carpenter, cottages, well), with a White Knights checkpoint at the drawbridge. It replaces the Knights' checkpoint (banner poles, tents, stalls) in Knight's Gap. Built as a reusable library of 228 modular assets with a manifest. Hand-painted look; 12th-13th century England. The castle itself is not part of this job.
- **Details:** White Knights palette ivory `#E5E0CE`, dark red `#A52F35`, tarnished gold `#C3A45B`, charcoal iron `#292B30`. Emblem (owner, 2026-11-25): white field with a red Templar cross (cross pattee), the same on everything; the gold lion in the in-game concept picture is not used. Size targets: road and drawbridge 12 m, checkpoint 14 m, market about 28 x 24 m, outpost about 160 x 120 m. Brief word for word: `docs/outpost/OUTPOST_BRIEF.md` (the paste stops partway through section 9).
- **Status:** decided (pasted by the owner into Claude Code, 2026-11-25; location and emblem confirmed in chat the same day).
- **Replaces:** the gold cross on the White Knight banners; DESIGN.md 12.1's "off-white and tarnished gold" line for the Knights.
- **Filed (2026-11-25):** `OUTPOST_PLAN.md` (decisions, what exists, layout proposal, stages, asset rules, open questions); `assets/outpost/MANIFEST.md` (all 228 assets); DESIGN.md 12.1 (palette, emblem, hand-painted outpost); ZONES_DESIGN.md section 3; ART_NEEDS.md; PRIORITIES.md P4; TODO.md. Stage 1 (the White Knights set, WK01-WK12) is built. Still open, in OUTPOST_PLAN.md section 7: scale, who lives there, moving the castle closer, GLBs, hand-painted everywhere, the rest of the brief.
