# THE GREENWOOD: Zone 1 audit and overhaul plan

*Written 2026-11-22 from "Zone 1 — The Greenwood: Updated Biome & Environment Brief" (the .docx on your desktop, text and reference board both read in full). This is Phases 1 and 2 only: **nothing in the game has been changed.** The only new files are this document and the "before" pictures in `docs/greenwood_before/`.*

## Progress

**Decisions (2026-11-22):** keep the name "The Tithelands" (the forest is "the Greenwood"); grade the existing scanned look toward the palette and build new trees and plants in a simpler painterly style; CC0 downloads OK; remove every fir; add the brook; keep Highcrown as it is.

| Stage | State |
|---|---|
| 0. Safety | **Done.** Branch `greenwood`, tag `pre-greenwood` on main. |
| 1. Foundations | **Done (ground and rock).** Terrain shader: limestone graded to the palette with horizontal beds lining up across cliffs, warm sandstone bands (south scarp, crag skirt, gorge), dark mudstone on soil slopes, moss on ledges, leaf litter under the canopy (Poly Haven `forest_leaves_02`). Land script `ground_extra()` feeds it. Puddles and grass colour still to do (stage 6). |
| 2. Tree library | **Done.** `game/world/tree_species.gd`: oak (8: young, mature, old), ancient oak (3), dead / stag-headed oak (4), beech (5), ash (5), birch (6, incl. clumps), yew (4); code-drawn bark and leaf textures; full detail to 80 m then a cheap far version. Gallery: `tools/preview_trees.gd`. |
| 3. Forest composition | **Done.** Every fir gone. Land script `tree_kind()` picks species by place (beech in deep interiors, ash by water, birch at the quarry, hamlet, scree and edges, yew at the churchyard, barrow, scarp top and a pocket in the East Woods). Expected shares: oak 55% (incl. 2.5% dead), beech 18%, ash 12%, birch 8%, yew 7%. Landmarks: great oak on the green, hollow oak at the East Lane bend, ancient oak at Knight's Gap, stag-headed oak below the watchtower, churchyard and barrow yews. No trees within 5 m of an enemy spawn, the Gullet door or the ladder. Trunk colliders sized per tree. A first "canopy light" in `DayNight`: under the trees the ambient turns lifted green instead of black. |
| 4. Terrain shaping | **Done.** In `tithelands_land.gd`: the west scarp is stepped (upper face, 2-4 m ledge, lower face) with a ragged brow, two combes bitten back into it (north of the quarry at z -152, south of the overlook at z 46) and a scree apron at its foot (kept clear of the quarry mouth); rock terraces on the crag's north-east face over the river; limestone knobs on the Knight's Gap hill shoulders (road untouched); rolling ground and three dells in the East Woods (barrow, raider farmstead and woods camps keep their ground); **the brook** from the east ridge past the crag into the river (carved bed, wadeable water ribbon built by `SculptedTerrain._brook()`, trees kept off it); a sunken lane from farmstead B up to the chapel (a new track). Rocks, boulders and cliff pieces keep 5 m off tracks. Placement audit unchanged from before (within a few cm); zone, camp and Gullet checks pass. Under-canopy light lifted further. Not done here: the dark scanned outcrop on the chapel ridge and the quarry corners (stage 5). |
| 5. Quarry and rock kit | **Done.** Three new worked terraces inside the same footprint (15 m step under the north bench, a high north-west step, a low half-cut step in the south-west); the floor cut has rounded corners and calmer edges, and the scarp noses at the quarry mouth are worn into shoulders (no more spikes). Terrain shader "worked stone" channel (UV2 from `ground_extra().z`): squared block courses with offset joints, fresh pale faces, pick marks, a pale dusty floor. New `game/world/quarry_kit.gd` (cut blocks, broken blocks, slabs, rubble, pale limestone and oak materials). The Gullet entrance is now `game/world/quarry_adit.gd` on the same GulletMouth node: a cut-limestone facade, an oak-shored adit with lagging and braces, a mine track running in, rubble, a lantern; the CaveDoor is untouched. New `QuarryWorks` node (`game/world/quarry_works.gd`): stacked blocks, half-cut blocks, a shear-legs crane with rope, hook and a slung block. Dressing: ladders and scaffold between terraces, a cart by the adit, spoil-heap rubble on a new spoil mound by the cart ramp. New `Scree` scatter (kit slabs, rubble and broken blocks: scarp foot, quarry wall feet, spoil heap, crag skirt, brook bed). Scanned rock faces and mossy boulders retinted pale. Quarry boulder 3 moved to the south rim (it floated on the new terrace). Audit: no new flags; zone, camp and Gullet checks pass; draw calls within ~3% of stage 4. Birch regrowth already from stage 3; brambles, nettles, ivy and foxglove come with stage 6. |
| 6. Ground plants | **Done.** Quarry walls: the block-course pattern removed at the owner's request (pale fresh stone with natural strata and faint tool marks); the Gullet entrance surround is now rough natural rock masses instead of cut-block courses. New `game/world/plant_kit.gd`: bracken, bramble, holly, bluebell, foxglove, wild garlic, wood sorrel, ivy carpets, mushrooms and bracket fungus, all code-drawn painterly cards. Placement rules in `tithelands_land.gd` from shade, wood edge, damp (river, brook) and disturbed ground (camps, ruins, burned hamlet, quarry margins); brambles keep to a band beside paths (`PlantScatter.road_band`); nettles now favour disturbed ground. Ivy climbs the old and ancient oaks and one stag-headed oak. Ancient oaks keep their leaves above 3.4 m so you can stand and fight under them. Grass thins and shortens under the canopy and its tips are less yellow. Puddles are soft damp patches that only shine when wet (no more grey discs). Plant densities cached per 4 m (load time); short draw ranges and small batches for small plants. Gallery: `tools/preview_plants.gd`. Checks pass; audit unchanged; FPS equal to stage 5 measured the same moment; load about 10.7 s (stage 5: 9.4 s). |
| 7. Props and story dressing | **Done.** Roads: wheel ruts (two darker bands either side of the centre that hold water after rain) and a grass strip down the middle of the narrow lanes (terrain shader, road distance in UV2.y). New `game/world/story_props.gd` (StoryProps node): two wayside shrines (oak post, carved cross, shingled pent roof, stone step with offerings) on the Tithe Road south entrance and Mill Lane, four mile stones along the Tithe Road, a hunters' high seat at the East Woods edge, a cart tipped in the ruts by the ford track, ivy climbing the chapel walls and the watchtower's west base. Two tumbled boundary walls running into the East Woods (`stone_walls.gd` gets a `ruin` option: gaps and runs of different heights). Each prop is its own mesh so distance culling works. Checks pass; FPS unchanged from stage 6. |
| 8. Lighting and atmosphere | **Done.** `DayNight` blends three area moods from `land.mood()` as the camera moves: deep woods (lifted green ambient, never black; exposure rises up to 45% like eyes adjusting; a little more haze for light shafts), the quarry (pale bounced light, dusty haze), the chapel and barrow (colder light, more mist). New `Mist` node (`game/world/mist.gd`): 10 local fog volumes from `land.mist_spots` (East Woods dells, brook, barrow, churchyard, river by the mill pond, ford, quarry dust), thicker at night and in rain; no global height fog. Palette colour grade: a 17x17x17 lookup built by `DayNight.palette_grade()` (shadows lean to deep woodland green, yellow-greens calmed, flowers and berries keep their colour, warm highlights); global saturation 0.8 to 0.9 since the grade is selective. `tests/visual_night.gd` gained woods shots at dawn, night and in rain. Checks pass; FPS no worse than stage 7 measured the same moment. |
| 9. Validation | **Done.** Final report below. |

### Final report (stage 9, 2026-11-22)

**Before and after.** Same 20 gameplay-camera spots: before in `docs/greenwood_before/`, after in `docs/greenwood_after/`, side by side in `docs/greenwood_after/compare_1.jpg` to `compare_4.jpg` (left before, right after).

**Gameplay validation**
| What | Result |
|---|---|
| All 15 checks (movement, combat, moves, enemy, death, loot, class, subclass, boss, camp, gullet, zone, audio, sound, prefs) + save_check | **All pass.** (Another session had uncommitted combat and enemy edits in this folder while they ran.) |
| 3-player network check | **Passes** (3 players, hits, downed and revive, loot roll, camp claim and raid). |
| Placement audit (`tools/zone1_audit.gd`) | **No new flags.** Every building, camp, shrine, vendor, door, gate, ladder and spawn is where it was. Trees: nothing in or against buildings. Enemy spawns: only the old "Checkpoint inside CheckpointPaving" note. |
| Routes (new `tools/route_check.gd`: a person-sized capsule every meter along every road and track) | Same as before the overhaul, with two improvements: Mill Lane no longer clips a terrain spike at the quarry mouth, and the Gullet door is no longer crowded by the old entrance blocks. The only route blockers are the intended ones (checkpoint barricade, raiders' barricade, zone edges, the bridge deck the road crosses) plus an old hay bale on Hobb's track. The new chapel lane is fully walkable (the chapel yard's edge was softened for it). |
| Access points (shrines, vendors, Gullet door, shortcut gate) | All clear. The quarry ladder touches the quarry wall, as it should. |
| Spawns, enemies, quests | No spawn or enemy placement moved; 5 m clearance round every enemy spawn for trees, rocks and plants. There is no quest system yet (PRIORITIES P4), so no quest triggers to break. No navigation mesh is used (enemies steer directly), so the route and access checks cover navigation. |
| Collision | Tree trunks sized per tree; quarry blocks, crane, adit, shrines, mile stones and the high seat have colliders; small plants and scree have none, as before. |

**Performance** (1920x1080, this PC, the original and the final version measured back to back; your Godot was running, so absolute numbers swing by 10-20% between runs)
| Spot | Original | Final |
|---|---|---|
| spawn north | 79 | 54 |
| spawn south | 114 | 83 |
| farms | 103 | 77 |
| river bank | 88 | 70 |
| mill | 96 | 77 |
| Hobb's camp | 84 | 68 |
| raider camp | 90 | 71 |
| road checkpoint | 79 | 64 |
| east woods | 86 | 76 |
| camp hearth | 100 | 75 |
| deep woods (new spot) | 77 | 57 |
| quarry floor (new spot) | 114 | 78 |
| barrow (new spot) | 117 | 78 |

The overhaul costs roughly **20-30% frame rate**; two spots are **below the 60 FPS target** on this PC (looking north from the spawn, inside the deep woods). The scene draws 1.5 to 3.5x more triangles (broadleaf crowns, ivy, plants, scree); GPU time measured only about 1 ms more per frame, so part of the cost is on the processor side and I could not pin it down today because the PC's load kept changing. Zone load: **8.2 s → 10.6 s** (15 s on the first load after the land script changes, while the terrain cache rebuilds).

**Remaining issues**
1. **Performance**: done. Every spot is above 100 FPS and faster than the original zone (see "Performance pass" below).
2. **Bracken up close** reads as flat striped cards (fine from a few meters).
3. **A few very dark views** remain where the camera is pressed against a slope or under a low crown.
4. **Old, not caused by the overhaul, but found by the route check:** the cliff-top path crosses the river gorge at about (-159, -45) on ground of 69-77° (not walkable); the long track up the watchtower hill is 45-48° near (77, 18); Mill Lane has a 56-63° step at the quarry mouth (-130, -96).
5. The scanned rock outcrop on the chapel ridge still looks odd; the chapel gravestones look like stumps (old models).
6. The look mixes photo-scanned textures with the new painterly trees and plants; it reads as one place, but a full repaint would unify it.
7. This branch also carries another session's "Safer saves" commit (63c09ed). Nothing is merged into `main` yet.

**Files.** New: `game/world/tree_species.gd`, `plant_kit.gd`, `quarry_kit.gd`, `quarry_adit.gd`, `quarry_works.gd`, `story_props.gd`, `mist.gd`, `tools/preview_trees.gd`, `tools/preview_plants.gd`, `tools/route_check.gd`, `assets/textures/leaf_litter/` (Poly Haven, CC0, in CREDITS). Changed: `game/world/sculpted_terrain.gd`, `forest_scatter.gd`, `plant_scatter.gd`, `stone_walls.gd`, `grass_field.gd`, `tithe_extras.gd`, `day_night.gd`, `levels/common/terrain_pbr.gdshader`, `grass.gdshader`, `materials/terrain_pbr.tres`, `tithelands_env.tres`, `levels/tithelands/tithelands.tscn`, `tithelands_land.gd`, `tithelands_dressing.gd`, `props/gullet_mouth.tscn`, `tools/relayout_tithelands.gd`, `tests/perf_zone.gd` (3 extra spots, CPU/GPU split, `noproc:`), `tests/visual_night.gd` (woods shots), docs. **Terrain areas changed:** west scarp (steps, ragged brow, two combes, scree), quarry (three terraces, rounded corners, spoil heap), Knight's Gap shoulders, watchtower hill north-east face, East Woods (rolling ground, three dells, the brook), the chapel lane and yard edge.

### Performance pass (after stage 9)

What was done (the look is unchanged: matching before/after pictures checked at six spots):
- **Per-tree detail switch** (`ForestScatter.per_tree_lod`, Woods and Oaks): before, full-detail trees were switched per 64 m patch, so trees up to ~125 m away were drawn in full. Now each tree switches to its cheap far shape at 40 m, a few patches checked per frame.
- **Shadow shape** (`ForestScatter.shadow_proxy`, `TreeSpecies` "shadow"): trees cast their sun shadow from the main limbs plus half the leaf cards at full size, out to the same 80 m patches as before. (A first try with the far shape's big cards closed the canopy gaps and lost the sunny patches on the ground; full-size cards keep them.)
- **Shared corners**: tree, plant and quarry-kit meshes are indexed (each corner computed once instead of once per triangle). Thinnest twigs use 3 sides instead of 4 (tree shapes unchanged).
- **Load-time cache** (`game/world/bake_cache.gd`, in `user://bake_cache/`, ~10 MB): code-painted leaf/bark/plant textures, tree shapes, where trees and plants stand, and the terrain meshes are saved after the first load. Keys include the source of every script involved and the settings, so editing the land, a builder or a scatter's settings simply rebuilds once. Exported builds bake every time (no script source), like the terrain grid.

Results (1920x1080; your game was running from the editor the whole time, so frame times swing a lot; triangle counts and GPU time are steadier):

| Spot | Triangles: original / before pass / after | GPU ms (best): before pass / after |
|---|---|---|
| spawn north | 3.0M / 4.8M / 3.9M | 9.5 / 7.7 |
| deep woods | 3.5M / 6.9M / 4.3M | 19.7 / 13.2 |
| raider camp | 3.0M / 6.8M / 3.6M | 15.4 / 10.7 |
| camp hearth | 3.1M / 5.0M / 3.0M | 16.9 / 9.4 |
| barrow | 1.9M / 6.7M / 2.8M | 16.2 / 11.4 |
| east woods | 2.1M / 4.1M / 3.0M | 10.6 / 8.7 |

Zone load: **10.6 s → 6.9 s** (the original was 8.2 s); the first load after a script change still takes the long way (~13-17 s) while the cache refills. Tools added: `tests/load_profile.gd` (load time per node), `perf_zone` now reports the best of four windows, a draw-call/triangle breakdown per node (`drawcalls`) and `set:Node.prop=value` A/B switches (also in `visual_env`, with `nodefaults`).

**Clean measurement (2026-11-23, game closed, only the idle editor open).** With nothing else running, the GPU time per frame was already back to the original's (5-9 ms against 5-8 ms); the frame was limited by the processor. Measuring each part on and off within one run showed the cause: **the zone's ~50 enemies, all standing idle and most of them 100+ m away, cost 7-9 ms of every frame** (animation 3.5 ms, script and physics 3.7 ms, drawing 2.6 ms). That was true in the original zone too (7 ms); the trees and plants of the overhaul cost about 1 ms on top. Fix: **`game/world/enemy_sleep.gd`** (node EnemySleep in the zone). An idle enemy with no player within 90 m (twice the longest sight range, 45 m) stops thinking and animating; it wakes as soon as a player comes within 90 m or anything changes its state (a hit, an ally's call). Raiders never sleep (they walk to the camp while "idle"). Enemy models fade out beyond 130 m. It works from outside the enemy script, so `enemy.gd` is unchanged. Host / single player only (friends' machines copy the host). New check: `sleep_check` (sleeping, waking at 70 m and noticing the player, waking when pulled into a fight, raiders never sleep).

| Spot | Original (two clean runs) | Now (two runs) |
|---|---|---|
| spawn north | 66 / 75 | 145 / 128 |
| spawn south | 111 / 116 | 171 / 168 |
| farms | 88 / 103 | 167 / 154 |
| river bank | 78 / 87 | 150 / 131 |
| mill | 84 / 104 | 144 / 139 |
| Hobb's camp | 81 / 95 | 138 / 141 |
| raider camp | 90 / 100 | 122 / 124 |
| road checkpoint | 73 / 88 | 120 / 104 |
| east woods | 82 / 98 | 150 / 141 |
| camp hearth | 89 / 103 | 138 / 141 |
| deep woods | 73 / 86 | 100 / 101 |
| quarry floor | 91 / 114 | 131 / 126 |
| barrow | 91 / 120 | 128 / 128 |

Every spot is now faster than the original zone and above 100 FPS at 1080p on this PC. Zone load 6.3 s (original 8.2 s). `perf_zone` now switches v-sync off itself (the settings default turns it on, which pinned every spot at 60) and has `ab:` same-run on/off measurements (`proc=Node`, `hide=Node`, `plants`, `enemyanim`, `farenemies=N`).

**Checks after stage 3:** `zone_check`, `camp_check`, `gullet_check` pass; placement audit shows no trees in or against buildings (the building flags it lists are unchanged from before). FPS at 1920x1080: 78 to 116 at the 10 spots (before: 81 to 128); zone load 8.1 s (before 6.6 s; trees are built at load, baking them to files is the fix if it matters). Pictures: `docs/greenwood_progress/`.

---

## 0. The short version

Zone 1 (the Tithelands) already has the right **skeleton** for the brief: a river valley, a limestone-style scarp in the west with a quarry and the Gullet's door cut into it, woods in the east, a village, farms, a mill, a tithe barn, a watchtower crag, a chapel and a barrow. The terrain, roads and building placement were rebuilt properly on 2026-11-21, and they pass the placement audit.

What does **not** match the brief is the **forest and the rock**:

1. **It is a fir forest.** About 62% of the zone's trees are firs (roughly 750 firs and 150 dead trees against 560 broadleaf trees). Every skyline in the before pictures is a row of fir spikes. The brief says "not a Scandinavian pine forest" and asks for oak (50%), beech, ash, birch and yew. There is only one broadleaf tree design, and it is a generic round "oak".
2. **The rock is all one dark grey.** The scarp, the quarry, the crag and every outcrop use one dark rock texture and two scanned rock faces tinted darker. The brief wants pale grey and beige limestone with horizontal layers, some warm sandstone, some dark mudstone.
3. **The quarry does not read as dug by people.** It is a smooth-walled box with one bench, spiky corners and a doorway made of stone blocks stuck onto the back wall: exactly the "natural cliff with a cave pasted into it" the brief warns against.
4. **The ground plants are thin.** There are 5 scanned plants (fern, nettle, one weed, two shrubs). The brief's signature plants (bracken, bramble, holly, bluebell, foxglove, ivy, wild garlic, wood sorrel, moss, fungi) are all missing.
5. **The light is flat.** A grey overcast haze over everything, the same everywhere; under the trees it goes near-black. The brief wants overcast light with filtered sun through the canopy, mist only in certain places, and shadows that are dark but never black.

So the work is: **a new tree library, a new rock and limestone look, a real worked quarry, the brief's ground plants with placement rules, a lighting pass, and targeted terrain shaping**, all inside the existing layout. Nothing needs to move.

---

## 1. How the audit was done

- Read the brief and its reference board in full.
- Read the zone's code and data: the land script (`levels/tithelands/tithelands_land.gd`), the terrain baker (`game/world/sculpted_terrain.gd`), the tree generator (`game/world/generated_tree.gd`), both scatter systems (`forest_scatter.gd`, `plant_scatter.gd`), the scene (`levels/tithelands/tithelands.tscn`), the environment (`levels/common/tithelands_env.tres`), the terrain shader and materials, the set dressing, the hideout asset library, and the earlier overhaul notes (`ZONE1_OVERHAUL.md`).
- **Before pictures** from the real third-person gameplay camera at 20 spots, plus a top-down map with every place (white) and enemy spawn (red): `docs/greenwood_before/` (start with `00_contact_sheet.jpg`). The "after" pictures will use exactly the same spots and names.
- **Frame rate** measured with `tests/perf_zone.gd` at 1920x1080: `docs/greenwood_before/00_perf_1080p.txt`.
- Counted the trees by kind from the land script's density maps.

| # | Picture | Spot (x, z) and heading |
|---|---|---|
| 01 | Spawn, looking north | (2, 128), north |
| 02 | Village green | (0, 92), south |
| 03 | Farms | (-20, 60), west |
| 04 | Burned hamlet street | (-56, 92), north-northwest |
| 05 | Mill | (-80, 16), west |
| 06 | Bridge | (0, 22), north |
| 07 | Tithe barn | (4, -30), northeast |
| 08 | Knight's Gap | (0, -85), north |
| 09 | Watchtower approach | (80, 60), north-northeast |
| 10 | Quarry approach | (-122, -78), west-northwest |
| 11 | Quarry floor, Gullet door | (-140, -96), west |
| 12 | Woods camp | (64, -55), east |
| 13 / 13b | East Woods | (120, 70), north / (150, 0), southwest |
| 14 | Chapel ridge | (-26, 148), west-southwest |
| 15 | Cliff-top overlook | (-152, 16), east |
| 16 | Ford and gorge | (30, -22), east |
| 17 | Barrow | (135, -125), northeast |
| 18 | Hobb's hollow | (-88, 24), west |
| 19 | River, west | (-60, -6), west |

---

## 2. The map as it is: what must not move

Coordinates in meters, x = east, z = south (north is up, −z). The zone is 364 m square.

| Kind | What | Where |
|---|---|---|
| **Player start** | Spawn0 to Spawn4 | (-3 to 3, 120) |
| **Shrines** (IDs `crossroads`, `mill`, `quarry`, `camp`) | Crossroads, Mill, Quarry shrines; the camp hearth | (-9, 116), (-80, 20), (-118, -92), (40, 128) |
| **Vendors** | Old Wenna, the Soul Broker | (16, 104), (-13, 138) |
| **Dungeon access** | Gullet mouth and its door (teleport into the Gullet) | (-169, -98) / (-166, -98) |
| **Shortcut** | Watchtower south gate (ID `watchtower_south`) | (105, 41) |
| **Ladder** | Quarry ladder (rim to floor) | (-150, -86) |
| **Major structures** | 3 village cottages, 2 farmsteads, burned hamlet (4 shells), mill and weir, broken bridge, tithe barn and walled yard, checkpoint, watchtower and palisade, chapel, barrow, Highcrown backdrop | as placed; all sit on level pads |
| **Camps** | Hobb's hollow, ford camp, raiders' farmstead, three woods camps, quarry camp | (-112, 32), (29, -33), (122, -84), (94, 86), (64, -55), (102, -51), (-150, -90) |
| **Enemy spawns** | 32 markers (RoadPatrol, Checkpoint, TitheBarn, Farms, Hamlet, Mill, HobbCamp, Woods*, RaiderCamp*, Tower*, Quarry*, BridgeGuard, FordCamp, NorthRoad...) | heights follow the ground at load |
| **Routes** | Tithe Road (south edge to north edge), Mill Lane (green to quarry), East Lane (green to watchtower), 6 tracks (towpath, ford track to the raiders, Hobb's track, the long way up the crag, cliff-top path, tithe yard) | `roads` and `tracks` in the land script |
| **Zone joins** | South road in, north road out to Highcrown at about 7 m high | edges |

**How these stay safe:** buildings and camps are not moved; the terrain baker already levels a pad under every building and every camp (`flats`), so reshaping the land around them cannot leave them floating. Enemy spawns, shrines and doors are placed by the scene, not the terrain, and their heights follow the ground. There is no navigation mesh: enemies steer directly, so the only way to "break navigation" is to put solid things (trees, rocks, colliders) in their way, which the placement rules below prevent.

---

## 3. Current state against the brief

| Brief asks for | Now | Gap |
|---|---|---|
| Oak-dominated broadleaf woodland: oak 50, beech 20, ash 12, birch 10, yew 8 | 62% fir; one round broadleaf design (5 shape variants); dead trees are generic | **Large.** New tree library needed |
| Ancient landmark oaks; variants by age, size, health | None | **Large** |
| Bracken, bramble, holly, bluebell, foxglove, ivy, moss, wild garlic, wood sorrel, nettles, fungi | Fern, nettle, one weed, two shrubs (Poly Haven scans); moss only as a ground texture | **Large** |
| Plants placed by moisture, light, disturbance, nearness to paths | Placed by one forest-density map, the same rule for all | **Medium.** The scatter system is good; it needs more inputs |
| Limestone quarry, pale with horizontal strata, worked by people | Dark grey smooth box, one bench, spiky corners, block doorway | **Large** |
| Limestone/sandstone/mudstone geology | One dark rock texture everywhere | **Large** |
| Rolling terrain, ridges, valleys, small streams, natural transitions | Good river valley; scarp is one long even wall; crag is a smooth dome; the East Woods are a plain ramp; no streams | **Medium.** Targeted shaping |
| Overcast light, filtered sun through canopy, local mist, no pure black | Flat grey haze everywhere; near-black under trees | **Medium** |
| Muted palette (#354536 ... #B5B1A3), selective saturation, no neon green | Grass tuft tips go quite yellow; rock is too dark; otherwise muted | **Small to medium** |
| Muddy roads, wagon ruts, stone crossings | One path texture; puddles are flat grey discs that read as plates (pictures 01, 11) | **Medium** |
| Cottages, bridges, walls, shrines, standing stones, palisades, carts | Mostly there (building kit, walls, chapel, barrow, palisade, carts). Missing: roadside shrines, mile stones, hunting stand, ivy on old stone | **Small** |
| Stylized, painterly, readable | Photo-scanned textures and plants (realistic), with code-drawn leaves | **Decision needed** (section 8) |
| Instancing, LOD, culling | Trees and plants are batched; trees stop at 175 m; plants stop at 55 to 230 m; no far "card" versions of trees | **Medium** |

### Smaller problems seen in the pictures
- **Camera inside fir branches** at the watchtower approach (picture 09): the fir branch cards don't fade fast enough, and the view goes dark. Broadleaf crowns sit higher, which mostly solves this, but the new trees need the same near-camera fade.
- **Spiky "pyramid" corners** on the quarry and scarp (pictures 10 and 11): the terrain grid makes sharp spikes where two steep cuts meet.
- **The west scarp is one even wall** with a flat top, the same height and texture for hundreds of meters (pictures 05, 10, 19). It reads as a dam.
- **The watchtower crag and the gorge** are smooth stretched rock (pictures 09, 13b).
- **Puddles** are flat grey discs, very visible in dry weather.
- **Trunk colliders** are the same size (0.38 m) for every tree; a big ancient oak needs a bigger one.

---

## 4. Assets: replace, improve, reuse

| Replace | Improve | Reuse as is |
|---|---|---|
| Fir tree (all of them) → yew where an evergreen is wanted | Broadleaf tree → becomes the **oak** species with real variants | Building kit and all buildings, chapel, barrow, mill, tithe barn, watchtower |
| Generic dead tree → **dead oak** (stag-headed) and dead birch | Scanned rock faces and mossy boulders → limestone tint and moss on top surfaces | Dry-stone walls, fields, fences, palisade |
| Gullet mouth (stone blocks) → **timber-shored adit** cut into a worked limestone face | Terrain shader → limestone/sandstone/mudstone, strata, leaf litter, wet mud | Hideout library: winch, pulley gantry, carts, track, support frames, scaffold, platforms, ladders, tools, rubble |
| Flat-disc puddles → puddles that blend into mud and only shine when wet | Grass → palette-matched colour (less yellow), shorter in the woods | River water, weir, mill race |
| Weed scan (generic) → bramble, nettle, foxglove, bracken | Fern scan → keep as woodland fern; bracken added as its own plant | Scanned stumps and fallen trunk (with moss and fungi added) |
| | Environment → colour grade, mist volumes, light by area | Day/night, rain, wetness, stars, lit windows |
| | Quarry dressing → many more mining structures, stacked cut blocks, spoil heaps | Highcrown backdrop (the "distant keep") |

---

## 5. Where the terrain itself should change (and why)

Each change is made in the land script, re-baked, and checked with the placement audit. Building pads and camp flats keep their ground level automatically.

| Area | Now | Change | Why | Gameplay kept by |
|---|---|---|---|---|
| **West scarp** (x ≈ -140, whole west side) | One smooth wall, flat top, 13.5 m falling to 4 m | Limestone **steps** (2 to 3 ledges in the face), a ragged broken brow, two or three **combes** (small wooded valleys cut back into the scarp), **scree aprons** at the foot, a band of warm sandstone low down in the south | The brief's "layered outcrops" and "weathered cliffs"; breaks the dam look | Scarp line stays where it is; cliff-top path and overlook flats unchanged; nothing placed on the track |
| **The quarry** (-150, -100) | One floor, one bench, spiky corners | 3 **cut terraces** stepping up the north and west walls inside the same footprint, sharp vertical cut faces between them, rounded inside corners (no spikes), a **spoil heap** ridge beside the cart ramp | "Must read as human-worked excavation" | Same outer footprint; floor, Gullet door, ladder, shrine and the three quarry spawns stay at their heights; cart ramp kept |
| **Knight's Gap** (0, -120) | Two smooth hills | Limestone **outcrops** breaking out at the notch and on the hill shoulders, a slightly deeper, more defined pass | A natural choke point should look like one | Checkpoint yard flat and the road untouched |
| **Watchtower Crag** (105, 26) | Smooth dome with a ring of boulders | Exposed **layered rock** on its steep north (river) face, ledges, a scree skirt | Brief's outcrops; makes landmark 2 read from a distance | Summit flat (19 m), gate, path up the south side, tower spawns unchanged |
| **East Woods** (x > 60) | A plain ramp to the east edge | **Rolling ridges and dells** (hollows where mist will lie), one **small brook** from the east ridge down to the river with a plank or stone crossing where the hunters' track meets it | Deep Woodland needs terrain that hides and reveals; brief asks for small streams | Woods camp flats, raider farmstead flat, ford track kept; the brook is shallow and wadeable everywhere |
| **South ridge** (z ≈ 160) | Smooth ridge with woods | A short **sunken lane** (holloway) up to the chapel, banks with exposed roots; a churchyard **yew pocket** round the chapel | Very English; gives the chapel a mood | Chapel pad unchanged; the lane is optional ground, no new route |
| **River gorge** (x 90 to 150) | Smooth steep banks | Layered rock on the steep bank, a few boulders breaking the water | Matches the crag | Ford, bridge and water level unchanged |
| **Corners of all cuts** | Spikes | Rounded corners in the cut maths | Pure fix | — |
| **Beyond the edge** | Low hills with firs | Same hills, broadleaf silhouettes | Skyline must be oak, not fir | Not playable ground |

**Stop rule (from the brief):** if any change would need a building, camp, spawn or route to move, I stop and ask instead.

---

## 6. Performance: now and risks

**Now (1920x1080, this PC):** 81 to 128 FPS at the 10 fixed spots (worst: looking north from the spawn, 81 FPS, 1,972 draw calls, 2.9 M triangles). Zone loads in 6.6 s.

**What costs the most today:** the scanned plants. Counting every copy in the zone (before distance culling), the scatter holds about 13 M triangles of deadwood, 11 M of weeds, 11 M of ferns and 9 M of shrubs, against 3 M for the firs and 1.3 M for the broadleaf trees. The scans have no lighter far versions of their own (the dead trunk alone is a 2.2 MB mesh), so whether Godot's automatic simplification applies to them in batches needs checking.

**Risks from the overhaul and how I'd handle them:**

| Risk | Handling |
|---|---|
| Broadleaf crowns are leaf cards, with more see-through pixels than a fir (overdraw) | Fewer, larger, well-filled leaf cards; cutout (not blended) transparency, as now; crowns built in the tree baker, not at runtime |
| More trees (oak forests are denser in silhouette) | Three detail levels per tree: full near, simpler crown at middle distance, **flat cards** far away so the skyline can stay full without the cost |
| Leaf shadows (expensive, but they make the "filtered sunlight") | Only the near detail level casts leaf shadows; far trees cast trunk shadows or none |
| Many more plant kinds | Each plant is light (code-built cards, not 1 MB scans); density thins with distance; small plants only drawn near |
| Mist volumes | A handful of local volumes in hollows, not more global fog |
| Load time (trees are generated in code today) | Bake the tree library to files with a tool, the way buildings are baked now |

**Target:** no spot below 60 FPS at 1920x1080 on this PC, load time no worse than now. Each stage ends with `perf_zone`.

---

## 7. The plan

### 7.1 Tree library (5 species, built in code like the buildings, baked to files)

Every species gets its own bark, its own leaf texture drawn in code, its own crown shape and branch pattern, several variants, and three distances of detail.

| Species | Share | Silhouette and look | Variants | Where |
|---|---|---|---|---|
| **English oak** | ~50% | Short thick trunk, root flare and exposed roots, low crooked limbs spreading wide, broad irregular crown with gaps, a broken limb now and then; deep fissured bark; lobed dark-green leaves | Young, mature (most), old, **ancient landmark** (huge girth, hollow, burrs, ivy, dead limbs; hand-placed), **dead / stag-headed** | Everywhere; dominant in the East Woods and on the gap hills; lone oaks in hedgerows and fields |
| **European beech** | ~20% | Tall, straight, smooth grey trunk with a buttressed base, few low branches, dense layered canopy high up; bright green oval leaves; bare dark ground under it | Mature, tall, twin-stem | Enclosed woodland interiors: the deep core of the East Woods and the north slopes |
| **European ash** | ~12% | Tall, open, upward-curving branches, light airy crown (you see sky through it); pale grey diamond bark; feathery leaves | Mature, tall, young | Woodland edges, damp ground by the river and brook, mixed in with oak |
| **Silver birch** | ~10% | Slim white trunk with black diamonds and peeling bark, thin drooping twigs, small light-green leaves, often in small groups | Single, leaning, clump of 2-3, young | Clearings, disturbed ground, **quarry benches and rim**, scree, woods edges, burned hamlet |
| **English yew** | ~8% | Short, massive, fluted reddish trunk (often several stems), very dark dense evergreen crown, low and broad | Mature, ancient, hedge-like | Ominous places only: **chapel churchyard**, **barrow ring**, the quarry's top edge, shrine clearings, one pocket deep in the East Woods |

- **Landmarks** (hand-placed, not scattered): the great oak on the village green over the crossroads shrine (planned in the old overhaul but never built), an ancient hollow oak at a bend of the East Lane, a dead stag-headed oak on the watchtower crag, a fallen giant you walk under in the East Woods, the churchyard yews, a yew ring at the barrow.
- **Variety without cloning:** every tree picks species, variant, size, lean and turn from where it stands; spacing comes from a jittered grid plus a density map (as now), then a minimum gap per species so groups form naturally (birch in clumps, beech evenly spaced, oak irregular).
- **Collisions:** trunk collider sized to each tree's real trunk.
- **Kept off:** roads, tracks, river, building pads, fields, camps, every enemy spawn (new 5 m clearance), the Gullet approach, the ladder.

### 7.2 Ground vegetation (code-built, light, placed by rules)

New density inputs computed by the land script for every square meter: **canopy** (how shaded), **moisture** (near water, low hollows, north-facing slopes), **disturbance** (near roads, camps, quarry, buildings, field edges), **path distance**.

| Plant | Built as | Placement rule |
|---|---|---|
| Bracken | Tall triangular fronds on stalks, in patches | Woodland edges, clearings, open slopes; moderate light; big patches, not dots |
| Woodland fern | Existing scan (fern_02) | Damp shade, under oak and ash, by the brook |
| Bramble | Arching thorny canes with leaves, a few berries, dense mounds | Path edges, along walls and fences, disturbed ground, burned hamlet, quarry margins |
| Holly | Dark glossy shrub, red berries | Understory in oak and beech woods; never on paths |
| Bluebells | Drooping blue flower stems in drifts | Dappled shade (half-open canopy) on gentle slopes; a few drifts only |
| Foxglove | Tall single spikes of purple bells | Woodland edges, clearings, the quarry floor margins; sparse |
| Wild garlic, wood sorrel | Low broad leaves with white flower heads; small trefoil leaves | Damp shade, by the brook and river banks; deep shade |
| Nettles | Existing scan | Camps, quarry margins, round buildings and ruins, dung heaps |
| English ivy | Leaf cards climbing trunks and walls | On old and ancient oaks, the chapel, ruins, the barrow stones; not every surface |
| Moss | In the materials: on top-facing parts of rocks, roots, logs and walls, more in shade and damp | Shaded stones, tree roots, fallen logs |
| Bracket fungus, mushrooms | Small meshes | On dead trunks, stumps and fallen logs; clusters in shaded corners |
| Leaf litter, fallen branches | Ground texture layer under the canopy plus scattered twigs | Under broadleaf canopy, fading out into the open |
| Grass | Existing system, recoloured | Shorter and thinner under trees, fuller in meadows; less yellow |

Combat spaces stay readable: camps, enemy spawns, roads and tracks get clearance; tall plants (bracken, bramble, foxglove) are kept out of the fighting circles.

### 7.3 Rocks and geology

- **Material:** the terrain shader gets a rock-type layer (limestone, sandstone, mudstone) and **horizontal strata** driven by height, so every steep face shows bedding lines that line up across the whole scarp. Limestone in the palette's pale grey and beige (#777C78 to #B5B1A3), sandstone in warm rust layers, mudstone in dark brown-grey on soil slopes. Existing rock texture kept as fine detail.
- **Rock kit, built in code:** limestone **ledge modules** (stacked bevelled slabs with joints, the classic limestone-pavement look), layered outcrops, **cut-block faces** for the quarry (squared blocks with pick marks and wedge holes), cracked slabs, angular rubble, gravel and scree patches, overhang lips. Existing scanned boulders kept, retinted pale, with moss on top.
- **Placement:** ledges follow the scarp, crag and gorge faces; scree at the foot of each face; rubble only where rock could have fallen.

### 7.4 The quarry (The Gullet)

Same place, same footprint, same door. What changes:

1. **Shape:** three cut terraces with vertical worked faces between them (section 5), a spoil heap of broken waste stone outside along the cart ramp, rounded corners.
2. **Surfaces:** pale limestone cut faces with square block scars, drill and wedge marks, tool scoring; the natural weathered brow above, with soil and roots hanging over.
3. **The Gullet entrance:** the stone-block doorway is replaced by an **adit**: a squared opening cut into the lowest face, shored with oak posts and a lintel, a rough plank door frame, rubble at its foot, a lantern, a mine-cart track running in. Same position, same door logic.
4. **Workings:** the existing pulley gantry and winch move to the terrace edges where they would lift stone; add a timber shear-legs crane, work platforms and ladders between terraces (hideout library pieces), stacked cut blocks ready to ship, half-cut blocks still in the face, abandoned carts, discarded tools, ropes, a workers' lean-to.
5. **Reclaimed by nature:** birch saplings on the benches, bramble and nettles round the margins, ivy on the old faces, foxglove on the spoil heap, moss on shaded ledges.
6. **Light:** the quarry floor slightly brighter and dustier than the woods (pale stone bounces light), so it feels exposed.

### 7.5 Medieval props and dressing

Structures stay where they are. Additions are small and only where they tell a story: a **roadside shrine** (wayside cross with a little roof) at the Mill Lane fork, **stone mile markers** on the Tithe Road, a **hunting stand** at a woods edge, a **wagon** stuck in ruts on the ford track, **boundary walls** (old, tumbled) running into the East Woods, **ivy** on the chapel and watchtower ruins, **wagon ruts and stone crossings** painted into the road surface, puddles that sit in the ruts.

### 7.6 Lighting, atmosphere, colour

- **Overcast but alive:** a brighter, slightly warmer cloud layer with breaks, so the sun can come through at times; shadows from leaf crowns give **filtered light** on the woodland floor; low **light shafts** through the canopy using the existing volumetric fog.
- **Area moods**, blended as you walk (a small "atmosphere" node that eases the environment settings by where the camera is; visual only, nothing networked):
  - *Open valley:* the brightest, light haze, the most colour.
  - *Deep woods:* darker, greener ambient light (never black: shadows lean toward #354536), a bit more haze.
  - *Quarry:* pale and dusty, cooler.
  - *Chapel and barrow:* colder, quieter, mist close to the ground.
- **Local mist:** a few mist volumes in the woods' dells, along the brook, at the barrow and the river at dawn. No global height fog (it would bury the Gullet's rooms; see HANDOFF).
- **Colour grade:** a colour-correction table built from the brief's palette: selective saturation (greens and earth readable, no neon), moderate contrast, warm highlights, no crushed blacks.
- **Readability:** paths kept lighter than the ground around them, enemies' silhouettes checked against the darkest woods, interactables (shrines, door, gate, ladder) kept lit.
- Checked at morning, noon, dusk and night, dry and in rain.

### 7.7 How the layout and gameplay are protected

- No building, camp, shrine, door, gate, ladder, vendor, spawn point or enemy spawn is moved or renamed. Zone ID, shrine IDs and the gate ID stay.
- Roads and tracks keep their control points. Only their surfaces and surroundings change.
- Terrain edits are made in the land script, so pads, flats and roads are re-applied on top every time.
- All new trees, rocks and plants obey the keep-off rules (roads, tracks, pads, fields, camps, plus a new clearance round every enemy spawn and the Gullet door).
- **After every stage:** the placement audit (`tools/zone1_audit.gd`: nothing floating, buried, blocking a road or a door), `zone_check`, `camp_check`, `gullet_check`, `perf_zone`, and the matched screenshots. At the end: every check, the 3-player check, and a walk of every route.
- Work on a branch (`greenwood`) with a tag on today's state, so any stage can be undone.

### 7.8 Order of work

| Stage | What | You look at it? |
|---|---|---|
| **0. Safety** | Branch and tag; before pictures (done) | — |
| **1. Foundations** | Terrain shader (rock types, strata, leaf litter, moss, rut and puddle fixes); the new density inputs (canopy, moisture, disturbance); colour grade draft | Pictures |
| **2. Tree library** | 5 species, variants, landmark oaks, dead oak, three detail levels, baker tool, a gallery scene with every tree | **Yes: tree gallery** before they go into the zone |
| **3. Forest composition** | Firs out, species maps by sub-biome (Deep Woodland, Paths and Clearings, Quarry), landmark trees placed | Pictures + FPS |
| **4. Terrain shaping** | Scarp, gap, crag, East Woods dells and brook, south ridge holloway, gorge, corner fix (area by area, each audited) | **Yes: terrain** |
| **5. Rock kit and the quarry** | Limestone modules, quarry terraces, cut faces, adit entrance, workings, spoil | **Yes: quarry** |
| **6. Ground vegetation** | The plant set and its rules | Pictures + FPS |
| **7. Props and story dressing** | Shrines, markers, hunting stand, ruts, ivy | Pictures |
| **8. Lighting and atmosphere** | Area moods, mist volumes, light shafts, final grade | Pictures at four times of day and in rain |
| **9. Validation** | After pictures from the same 20 spots, every check, 3-player check, FPS at 10 spots, full report with every changed file | **Yes: final** |

---

## 8. Decisions I need from you

1. **The name.** Keep the zone called "The Tithelands" (the valley and farms) and call the forest "the Greenwood" (the East Woods and the woods around the valley)? Or rename the whole zone to "The Greenwood" on screen? (The internal zone ID stays either way, so saves keep working.)
2. **Stylized or realistic.** The brief says "stylized, painterly". The zone today uses photo-scanned textures and plants. My suggestion: keep the scanned detail but grade everything toward the palette, and build all new trees and plants in a slightly simplified, painterly way (code-drawn leaves, clean shapes). A full repaint of every texture would be a much bigger job.
3. **Downloads.** New bark (beech, birch, ash, yew) and a leaf-litter ground texture would be easiest from CC0 sites (ambientCG, Poly Haven), logged in `assets/CREDITS.md` like before. OK? (Without them I'll draw them in code, which looks simpler.)
4. **Firs.** The brief rules out a pine forest. Remove every fir (my suggestion; yews take over the dark-evergreen role), or keep a few on the scarp top?
5. **The brook in the East Woods.** OK to add one small, shallow, wadeable brook? It is new water, but it blocks nothing.
6. **Highcrown** stays as the "distant keep" exactly as it is. OK?

When you've read this, tell me what to change, answer what you can of section 8, and I'll start at stage 0.
