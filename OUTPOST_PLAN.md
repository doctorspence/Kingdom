# THE WHITE KNIGHTS OUTPOST: plan and progress

*Started 2026-11-25 from the owner's brief (`docs/outpost/OUTPOST_BRIEF.md`, word for word, with the concept pictures in `docs/outpost/`). The full asset list and what is built: `assets/outpost/MANIFEST.md`. How to bake and use the assets: `assets/outpost/README.md`.*

## 1. What it is

A small permanent medieval settlement at the north end of the Tithelands, the last place you pass through before Highcrown's moat and gate. The White Knights hold a checkpoint at the drawbridge; around it sit an inn, a civilian blacksmith, stables with a farrier, a market, a carpenter, cottages and a well. It **replaces the Knights' checkpoint in Knight's Gap** (the banner poles, tents and stalls you see today). 12th-13th century England; the Knights look rich and disciplined, the village around them poorer and weathered. The castle itself is not part of this job.

## 2. Decisions

**The owner decided (2026-11-25):**
| Topic | Decision |
|---|---|
| Where | It replaces the Knights' checkpoint area in front of the castle (Knight's Gap and the road north of it). |
| Emblem | White (ivory) field with a red Templar cross (a cross pattee: arms narrow at the centre, flaring to wide straight ends). The same cross on every flag, pennant, shield, sign, crate and seal. It replaces the gold cross on today's banners. The gold lion in the in-game concept picture is not used. |
| Palette | Ivory `#E5E0CE`, dark red `#A52F35`, tarnished gold `#C3A45B`, charcoal iron `#292B30`, weathered brown timber, natural stone grey. |
| Look | Hand-painted textures (painted light, shade, dirt and wear), chunky readable shapes, dark restrained colours; not photo-real. |
| Size targets | Main road and drawbridge 12 m wide, checkpoint 14 m, market about 28 x 24 m, outpost about 160 x 120 m, one-storey buildings 3.5-5 m tall, two-storey 6-8.5 m. Not symmetrical, not a grid. |

**Claude Code's defaults (the owner did not answer these yet; each is cheap to change):**
| Topic | Default for now | Why |
|---|---|---|
| How models are made | Built in code (like the bandit-hideout kit, the quarry and the trees). Any asset can later be swapped for a GLB the owner makes with an image-to-3D tool, keeping the same name, origin and size. | Works today, matches every other environment asset, and nothing waits on outside tools. |
| Hand-painted for the whole game? | Only the outpost for now. The rest of the Tithelands keeps its textures until the owner decides. | DESIGN.md 12.1 still says photo-scanned textures for the rest of the game. |
| Scale (doors, rooms) | Not needed yet: the first assets (banners, shields, signs) look the same at any building scale. **Needed before stage 3 (buildings).** | It is the open "scale question" in PRIORITIES P1. |

## 3. What is there today (facts from the project, 2026-11-25)

- **The checkpoint:** a flat yard in Knight's Gap centred at (0, -108), radius 17 m. Barricades at (-3, -113) and (4, -118), tents at (13, -104) and (-13, -102), a gallows at (-12, -97), cobble paving at z -104 and -112, and code-drawn banner poles, three market stalls, a notice board and two braziers along the road from z -94 to -112 (`game/world/tithe_extras.gd`, `checkpoint_shift = -34`). Enemy spawns `Checkpoint` (0, -110) and `CheckpointExtra` (8, -116): White Knight zealots. `tests/zone_check.gd` uses the `Checkpoint` spawn.
- **The land:** Knight's Gap is a ridge across the road at about z -120 with a hill on each side, (-44, -124) and (46, -118). North of z -135 the land falls gently toward the fens. The playable square ends at z -182.
- **Highcrown:** a backdrop at z -255 (wall face at -252): a 140 m wall, 18 m high, a gatehouse with a dark arch, banners with a gold cross, a town and keep behind. No moat, no drawbridge, no collision.
- **The road:** the Tithe Road is 5.5 m wide (plus 4 m shoulders); the brief wants 12 m.
- **Scale:** the player is 1.85 m. Today's cottages have 1.1 x 2.0 m doors (as in the brief); DESIGN.md 12.1 says doorways at least 1.6 x 2.6 m.
- **Things to reuse:** the bandit-hideout library (`assets/hideout/`) has barrels, crates, sacks, buckets, baskets, chests, tables, stools, shelves, bedding, braziers, lanterns, torches, candles, a weapon rack, chains, hooks, wheelbarrows and more. The Greenwood work made oak, beech and birch trees, ferns, brambles, wildflowers, boulders and mist. The manifest marks each one (♻️).

## 4. Layout (proposal; the owner approves before anything is placed in the zone)

- **Footprint:** about 160 x 115 m, from just north of the tithe barn (z about -65) through Knight's Gap to a moat at about z -185, between x -80 and +80.
- **The castle comes closer:** move the Highcrown backdrop south from z -255 to about z -200 so its gatehouse stands right behind the moat, as in the concept pictures, and add a moat and a raised drawbridge (12 m) to it. The alternative, extending the map 70 m north to meet the castle where it is, means new terrain and a bigger zone.
- **Arrangement (from `docs/outpost/layout_concept.webp`):** the road widens to 12 m from the gap to the drawbridge; the White Knights checkpoint (14 m wide, guard shelters, barrier, toll table) at the drawbridge's south end; the blacksmith on the west side by a creek with a small footbridge; the market (about 28 x 24 m) west of the road; stables and farrier east; a well east of the road; cottages to the south-west; the inn to the south-east, facing the road. The Knight's Gap ridge and hills stay; buildings follow the ground instead of a grid.
- **What this changes elsewhere:** the zone 2 join in `ZONES_DESIGN.md` section 6 (Highcrown's wall at -252, the Tithe Causeway and Mudside in front of it) would need redrawing; the checkpoint's banner poles, stalls and tents go; the two enemy spawns move or change; `zone_check` and the `road_checkpoint` performance spot are updated to match.

## 5. Stages (one step at a time; the owner looks at pictures after each)

| Stage | What | State |
|---|---|---|
| 1. Foundations and the White Knights set | Hand-painted texture painter, outpost kit, exporter, preview pictures, the emblem; WK01-WK12. | **Done 2026-11-25.** Pictures: `docs/outpost/wk_*.jpg`. |
| 2. Checkpoint and castle approach | CP01-CP20: banner pole, stone torch holder, iron brazier, red-and-ivory road barrier, spiked timber barricade, guard shelter, toll table, bench, spear rack, weapon chest, shield display, barrels and crates stencilled with the cross, rope and chain, iron lantern, warning sign, boundary marker. | **Done 2026-11-25.** Pictures: `docs/outpost/cp_*.jpg` (a checkpoint laid out across a 12 m road, by day and at dusk). The guard shelter is open-fronted, so the scale question doesn't change it much. |
| 3. Buildings | **Needs the scale decision.** A modular kit (walls, roof sections, doors, windows, shutters, chimneys, beams, foundations), then B01-B10. | Waiting on the owner. Stage 4 can go first if the answer is slow. |
| 4. Trade and village props | Market, blacksmith, stable, inn, carpenter, cottage props. | |
| 5. Ground and plants | Road, path, puddle and rut looks; fences, stumps, stone paths. Trees and plants mostly exist. | |
| 6. Light and effects | Torches, braziers, lanterns, forge fire, smoke, ground fog, rain splash. Most exist in the hideout kit. | |
| 7. Story props | DT01-DT20. | |
| 8. Placement in the Tithelands | **Needs the owner's OK on section 4 and on who lives there.** Terrain, the 12 m road, moat and drawbridge on the backdrop, remove the old checkpoint dressing, place everything, enemy spawns, collision. | |
| 9. Checks | All automated checks, the 3-player check, route and placement audits, FPS at the fixed spots, before-and-after pictures. | |

## 6. Asset rules

- **Where:** `assets/outpost/<folder>/<ID_name>.scn`, folders as in the brief: `buildings`, `castle_approach`, `white_knights`, `market`, `stable`, `blacksmith`, `inn`, `carpenter`, `cottages`, `props`, `environment`, `vfx`, plus `materials`. Names keep the brief's IDs (`WK01_large_white_knights_banner.scn`).
- **Units and origins:** meters, +Y up. Standing props: centre of the base on y = 0. Hanging things: the top attachment point. Wall-mounted things: on the wall, facing +Z.
- **Materials:** shared, hand-painted (`assets/outpost/materials/*.tres`, textures in `materials/textures/*.png`, painted by `painter.gd`). Tiling textures cover a fixed size in meters (oak 2 m, iron and gold 0.5 m, linen, stripes, shingles and limestone 1 m), so the paint has the same density on every asset. Knights' stores carry the cross as a stencil (`stencil.png`, a cut-out laid a few millimetres off the surface). The PNGs can be painted over by hand or replaced by AI art with the same name and size.
- **Triangles:** small props under 2,000; buildings under 8,000; anything over 2,500 gets automatic distance versions (LODs). The 29 assets built so far total 19,987 (the largest, the rope and chain heap, 1,880).
- **Lights:** braziers, torch holders and lanterns carry their own flickering light (and fire particles). Only the brazier casts shadows; the zone's shadow budget node limits how many do at once.
- **Collision:** simple boxes and cylinders (posts, boards, shield fronts); none for cloth, ropes and small fittings above head height.
- **Swapping in a GLB (image-to-3D):** one object per source image (three-quarter view, plain background, no text). Clean up the GLB to the same size, origin and facing as the code-built asset, keep the shared materials where possible, give it the same file name, and check the triangle budget. Never claim a model exists until the GLB is in the project.

## 7. Open questions for the owner

1. **Scale:** keep real-world doors (1.1 x 2 m, as today's cottages) or go MMO-sized (about 1.5 x 2.6 m, roomier inside)? Needed before stage 3.
2. **Who is there:** the White Knights are enemies of the players. Is the outpost hostile (guards attack), a safe town with vendors (an inn, a smith), or mixed (a hostile checkpoint, a neutral village)? Needed before stage 8.
3. **The castle:** bring Highcrown closer (section 4), or extend the map north to it? Needed before stage 8.
4. **Models:** keep building in code, or will you make some GLBs (saddles, anvil, hanging meat and pottery are good image-to-3D candidates)?
5. **Hand-painted everywhere?** Should the rest of the Tithelands be repainted to match one day?
6. **The rest of the brief:** the paste stopped partway through section 9 (file organization). Anything after it is missing.
