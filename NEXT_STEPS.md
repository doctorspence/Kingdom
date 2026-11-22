# NEXT STEPS: easy first, complex later

*Refreshed 2026-11-21 after checking the code. Working list, separate from `TODO.md`. Who does it: **You** (no code), **CC** (Claude Code in this folder), **Chat** (planning).*

## Already done (was on the old list)

New bandit Gullet (layout, enemies, archers, barrels, Captain, Rook, loot tables, food, new weapons, hidden chest, barricade shortcut), Harl the Delver, gold renamed to coins, audio pass (Phase 10), settings and rebinding (Phase 12), equipment system (20 weapons, 14 armor pieces), Tithelands overhaul stages 1-6. `gullet_check`, `boss_check`, `loot_check`, `class_check`, `zone_check` all pass (re-run 2026-11-21).

## 1. You (no code)

- [ ] Playtest: the Tithelands with sound on, the new Gullet from camp to Harl (aim for about 10 minutes), the nine class abilities, a death-and-recover run. Note what is too loud, too hard, too empty.
- [ ] Name Harl's unique weapon and the named rare Bandit (Rook is a placeholder), and write one-line cryptic descriptions for the pickaxe, Blackstone amulet, Black Pick, bread and potion.
- [ ] Decide souls and XP for Gullet enemies (small numbers; tune later), plus the open questions in `DESIGN.md` section 14.
- [ ] Answer the open scale question: make doors, corridors and props bigger against the player?

## 2. CC: Tithelands polish (small, no input needed)

- [ ] Terrain bake cache (about 2.6 s of the zone load).
- [ ] Walk a dense wood and judge the foliage fade near the camera.
- [ ] Mill race (the wheel still stands in the pond edge); make the weir wadeable-but-visible.
- [ ] Fill the two reserved sites (ruined chapel, old barrow) once you say what belongs there. A chapel builder is already in progress, uncommitted, in `game/world/building_landmarks.gd`.
- [ ] Commit the new zone design docs and maps (`ZONES_DESIGN.md`, `ZONE*_MAP.*`, `heightmaps/`).

## 3. Later

- [ ] Gullet art slice and the standard-skeleton art pipeline test (`GULLET_DESIGN.md` section 10, `ART_NEEDS.md`).
- [ ] Harl extras after you fight him: charge-in, sweep-into-backhand, pick throw.
- [ ] Check the old strafe "moonwalk" when locked on.
- [ ] Zones 2 and 3 (`ZONES_DESIGN.md`), subclasses and factions (`CLASS_PLAN.md`, Phase 11).
- [ ] **Milestone:** 3 friends clear the Tithelands and the Gullet.
