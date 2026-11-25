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

### 2026-11-25: White Knights Outpost (north end of the Tithelands, in front of Highcrown's moat)
- **Area:** zone 1 / art direction / factions
- **Decision:** Build a small permanent medieval settlement just outside Highcrown's gate, the last place you pass through before the castle and its moat. The White Knights hold a checkpoint at the drawbridge; around it sit an inn, a civilian blacksmith, stables and a farrier, a market, a carpenter, cottages and a well. Make it as a reusable library of modular assets (about 260 planned: B01-B10, CP01-CP20, WK01-WK12, ST01-ST25, MK01-MK24, BS01-BS22, IN01-IN20, CR01-CR16, CO01-CO18, ENV01-ENV28, FX01-FX13, DT01-DT20) with a manifest that tracks each one's status. Not all at once. The castle itself is not part of this job.
- **Details:** 12th-13th century England. Hand-painted textures, chunky readable shapes, dark restrained colours, not photoreal PBR. White Knights palette: ivory `#E5E0CE`, dark red `#A52F35`, tarnished gold `#C3A45B`, charcoal iron `#292B30`, weathered brown timber, natural stone grey. One emblem on everything: ivory field, dark red cross. The Knights look rich and disciplined; the civilian village poorer, weathered and organic. Targets: main road and drawbridge 12 m wide (two wagons side by side), checkpoint 14 m, market about 28 x 24 m, outpost about 160 x 120 m, one-storey buildings 3.5-5 m tall, two-storey 6-8.5 m; not symmetrical, not a grid. Prefers GLB models (some made by the owner with image-to-3D tools such as Modelado), cleaned up into Godot scenes with shared materials, LODs and simple collision. Full brief: `docs/outpost/OUTPOST_BRIEF.md`. Concept pictures: `docs/outpost/layout_concept.webp`, `docs/outpost/asset_sheet_concept.webp`.
- **Status:** decided (pasted by the owner into Claude Code, 2026-11-25). The paste stops partway through section 9 (file organization).
- **Replaces:** the gold cross on the White Knight banners (`game/world/highcrown_art.gd`, `game/world/tithe_extras.gd`); for this area, DESIGN.md 12.1's "standard PBR materials, real tiling textures"; probably the gray-box checkpoint dressing in Knight's Gap.
- **Clashes Claude Code found (2026-11-25), to settle before filing:**
  1. *Where it fits.* The playable Tithelands ends 74 m north of the Knight's Gap checkpoint (z -108 to the edge at -182). Highcrown is a backdrop wall at z -255 with no moat and no collision. A 120 m deep outpost needs the map extended north up to the wall, and `ZONES_DESIGN.md` plans zone 2's Tithe Causeway and the Mudside shanty in that same strip.
  2. *Scale.* The brief's doors (1.0-1.2 x 2 m) match today's cottages, but DESIGN.md 12.1 says doorways at least 1.6 x 2.6 m for the 1.85 m chunky character; the "scale question" in PRIORITIES P1 is still open. Roads: the Tithe Road is 5.5 m wide today; the brief wants 12 m.
  3. *Look.* DESIGN.md 12.1 says standard PBR with scanned textures (Poly Haven, ambientCG); the brief and ROADMAP.md say hand-painted.
  4. *How models are made.* Every environment asset so far is built in code and baked to scenes (`assets/hideout/`, `game/world/building_kit.gd`, `quarry_kit.gd`, the tree and plant kits). The brief prefers GLBs; no image-to-3D GLBs exist in the project yet.
  5. *Heraldry.* The built banners have a gold cross, and DESIGN.md says "off-white and tarnished gold". The brief and ROADMAP.md M3 say a red cross. (The Dark Ages use rust red.)
  6. *Asset numbering.* The asset-sheet picture uses other IDs (M01-M10, T01-T15, S01-S12, F01-F08, E01-E14, U01-U17, L01-L10). Claude Code will use the text's IDs and treat the pictures as concept art only.
  7. *Who is there (needed later, not for the asset library).* SPEC.md makes the White Knights enemies of the players. Is the outpost hostile, a safe town with vendors, or mixed?
  8. *Order.* PRIORITIES.md and ROADMAP.md M0 say stabilize and playtest before new content.

### 2026-11-23: KINGDOM inventory and character panel UI standard
- **Area:** UI / loot
- **Decision:** Adopt the approved Champions of Norrath-inspired combined character and spatial inventory screen, with Oblivion-inspired top navigation. The clarified equipment layout is authoritative for the UI: one ring slot, no belt slot, and one Utility slot that also equips the cloak. Keep the existing two weapon sets and their swap behavior; the character panel shows the currently active main-hand and off-hand slots.
- **Details:** Keep the player character visible beside the backpack at all times. Left: spatial backpack grid with real item footprints, stack counts, rarity borders, weight/capacity, sorting, drag-and-drop, and rotation where appropriate. Center: 3D character on a pedestal with equipment slots around the paperdoll. Right: level/XP, attributes, combat stats, health, mana, stamina. Equipment slots: Head, Shoulders (directly beneath Head), Chest, Hands, Legs, Feet, Neck, Ring (exactly one), Utility (cloak uses this slot), active Main Hand, active Off Hand (weapon or shield). There is no Belt slot. Existing two weapon sets remain a gameplay feature; provide a way to inspect/swap the active set without adding four permanent paperdoll slots. Top tabs, in order: Character, Inventory, Map, Talents, Quests, System. Remove Magic and Help. Preserve the dark, ornate, aged-gold medieval fantasy look and controller navigation. Item footprints must be data-driven and prevent overlap/out-of-bounds placement; item selection supports inspect, compare, equip, drop and mark-junk actions.
- **Status:** decided
- **Replaces:** The previous UI mockup slot arrangement (including belt and separate ring/utility assumptions); clarifies DESIGN.md 9.2 for the displayed equipment slots. Does not remove the existing two-weapon-set gameplay system.


## Filed
_(nothing yet)_
