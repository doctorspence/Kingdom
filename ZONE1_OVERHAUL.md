# ZONE 1 OVERHAUL: audit and redesign proposal

*Written 2026-11-21. Decisions (2026-11-21): 1 yes (CC0 downloads OK), 2 yes (new layout), 3 yes (brighter baseline), 4 hold the chapel and barrow sites empty for now.*

## Progress

| Stage | State |
|---|---|
| 1. Ground system | **Built.** `game/world/sculpted_terrain.gd` bakes a 1 m height grid from the zone's land script (`levels/tithelands/tithelands_land.gd`): landform, a meandering river with its own width, depth, bank and water level per point (a weir at the mill), roads that follow the ground (smoothed profiles, crown, ditch), quarry cuts with ragged edges, level spots, ridge-and-furrow fields, and a level pad under every building with a `pad` metadata. Collision is a height field. Beyond the playable edge the land continues as low-detail hills (no more bowl). `game/world/forest_scatter.gd` places woods, rocks and clutter from density maps on an even jittered grid (trees drawn in batches). |
| 2. New land and layout | **Built.** Everything moved to the section 5 plan by `tools/relayout_tithelands.gd` (re-runnable). The audit shows no floating, buried or road-blocking buildings, and every door faces its road or yard. `zone_check` and `camp_check` pass. |
| Lighting baseline | **Done** (brighter overcast day: sky, exposure, contrast, saturation, fog, sun). |
| Performance | The underground Gullet was drawn through the ground from the whole zone (20 million of the 23 million triangles at the spawn). `game/world/underground_cull.gd` shows it only underground: 23M → 3M triangles, 7,600 → 2,800 draw calls at the spawn. Grass is the next cost to look at. |
| 3. Walls, fields, dressing | **In progress.** Dry-stone walls (`game/world/stone_walls.gd`), ploughed and pasture fields, and set dressing from the hideout library (`levels/tithelands/tithelands_dressing.gd`). |
| Reserved sites | Ruined chapel at (−48, 160) and old barrow at (150, −140): level ground, kept clear of trees and rocks, nothing built. |

**Quality target:** the detail level of your three reference screenshots (dry-stone walls built from individual stones, cobbles you can count, thick varied grass, real leafy trees, readable color), the Elden Ring brief for composition, landmarks and discovery, and our own grounded medieval dark fantasy look (muted color, weathered materials, no glowing magic).

**How the audit was done**
- `tools/zone1_audit.gd` (new) loads the real Tithelands scene and measures every placed object: how far each corner floats above or sinks into the ground, distance to roads and river, which way doors face compared with the nearest road, overlaps, trees and rocks inside buildings, enemy spawns inside walls, how much the roads are cut into or raised above the land. It is reusable for the final check (Phase 7). Run: `Godot_console.exe --headless --path . --script res://tests/run.gd -- ../tools/zone1_audit`
- 13 screenshots from the real third-person gameplay camera, in `docs/zone1_audit/`.

---

## 1. Verdict in one paragraph

The zone has a good skeleton (a river valley, a road north to Highcrown, a sensible order of places), but it cannot reach the target by moving things around. Most problems come from **five things in how the zone is built**, not from single misplaced objects: (1) buildings are dropped on the ground by their center point only, so on any slope they float on one side; (2) every road in the zone is flattened to the same height (6.5 m) whatever the land does, so roads are raised embankments or trenches; (3) the zone's edges are smooth 26 m ramps on all four sides, which read as a giant bowl; (4) trees, rocks and clutter are sprinkled randomly over big rectangles, so there are no real forests, forest edges or clearings, and trees land against buildings and paths; (5) every building's door is on the same side of the model and the turn values were picked without looking at the roads. On top of that, **all art is simple boxes and cones**, and detailed art is what your screenshots show. The fix is to rebuild the ground and placement system first, then re-lay the zone, then replace the art.

---

## 2. Prioritized problem list

**P0 = breaks believability everywhere, fix first. P1 = layout. P2 = art. P3 = lighting and performance.**

| # | Pri | Problem | Evidence | Proposed solution |
|---|---|---|---|---|
| 1 | P0 | **Buildings float on slopes.** The snap puts the center on the ground; corners on the low side hang in the air. | Watchtower floats **2.5 m** on its low side, tower palisade walls 0.8 to 1.2 m, Farm1 cottage **1.6 m** (screenshot a02 shows a dark gap under it), Farm2 1.3 m, Tithe Barn 1.1 m, Mill 1.2 m, shortcut gate **4.7 m**. 25 objects in all | A **building pad** system: the terrain flattens a level pad under each building's footprint and blends it into the slope, and buildings get a stone plinth that runs into the ground on the downhill side (real houses on slopes do exactly this) |
| 2 | P0 | **Buildings and props sit on roads.** | Farm1 on the road (0 m from center line), Mill on the road (0.1 m), Burned1 and Burned2 on the road (0.2 m), Farm2 1.2 m, a palisade wall section dug **5 m** into the road bank, carts and a gallows in the middle of lanes, the mill cart in the river | Roads become part of the layout plan: buildings are placed from a lot along a road (setback 3 to 6 m), and the audit flags anything closer |
| 3 | P0 | **Doors face away from roads.** Every building model has its door on the same side, and the turn values ignore where the road is. | Tithe Barn doors face **east; its road is 33 m west, directly behind it** (a07). Mill door faces away from its road (153° off). Farm1 door faces 117° away from the road, and the ground drops 0.7 m in front of the door. HamletCottage has a 0.7 m drop at its door | Placement turns each building so the door faces its yard or road automatically; a check fails if the door faces away or the ground in front of it isn't walkable |
| 4 | P0 | **Roads are dead flat across the whole zone** at 6.4 to 6.8 m, whatever the land does. | Raised up to **2.6 m** above the fields along the farm road, cut up to **2.7 m** into the hills by the checkpoint and quarry road, **7 m** at the north edge. Roads are made of a few straight lines, a fixed 6 m wide, with hard elbows | Roads follow the land with gentle grades and only a little local smoothing; curved splines instead of straight segments; width changes (main road 5 to 6 m, lanes 3 to 4 m, tracks 1.5 m); ruts, verges, drainage ditches, puddles in the low spots |
| 5 | P0 | **The zone is a bowl.** All four edges are identical smooth ramps 26 m high; the quarry is a perfectly round pit with smooth walls. | Visible in a05, a06, a10, a13: flat grey slopes behind everything | Natural boundaries: a limestone **scarp** (cliff band) on the west, a wooded ridge on the south, the river gorge and thick old forest on the east, the hill pass and the road to Highcrown on the north. The quarry is cut into the scarp in benches, not dug as a round hole |
| 6 | P0 | **The river is a canal.** Even width, straight segments, steep mud banks, the same depth everywhere. | a05, a13 | Meanders, wide shallow fords, gravel bars, reeds, a weir at the mill, rocks breaking the surface, a steeper wooded stretch in the east |
| 7 | P1 | **Trees are sprinkled at random**, so there are no woods with edges, no clearings, no glades, and trees end up against paths and houses. The camera ends up inside tree branches. | Camera inside firs in a03, a04, a09. Trees inside the tower wall and gate; rocks inside a cottage; clutter against the barn, a signpost and a cart | Forests painted as areas with density (thick core, thinning edge, undergrowth line), real clearings, trees kept off paths and away from buildings, and the camera pulled in front of foliage |
| 8 | P1 | **Places overlap.** | The Mill Shrine sits inside the mill (30 m² overlap). The raider camp's burned house is in the campfire. 3 enemy spawns are inside buildings or walls (`HamletExtra` inside Burned3, `TowerYard` inside the watchtower) | Re-lay each site from a plan (section 5) |
| 9 | P1 | **Settlements don't read as settlements.** Two cottages, a few fence pieces in straight rows, burned houses scattered in a triangle. No yards, wells, gardens, sheds, paths to doors | a02, a04 | Clusters around a green, yard or street; each house has a purpose (section 5) |
| 10 | P1 | **Few landmarks and sightlines.** From most places you see the same grey edge slopes and fir cones. The only real landmark is Highcrown | a06, a13 | 5 strong silhouettes placed on sightlines (section 5.3) |
| 11 | P1 | **Empty middle ground.** Only 24% of the inner zone is nearly flat, but the flat parts are featureless lawn; the slopes are gentle noise everywhere | Terrain stats; a11 | Hand-shaped heightmap: fields on the flats, hedgerows and stone walls dividing them, ridges and knolls placed on purpose |
| 12 | P2 | **Art is simple boxes and cones.** Buildings are boxes with a texture, roofs are one triangle prism, trees are fans of needle strips, there are no broadleaf trees at all. | Every screenshot | Replace with detailed modular kits (section 6). This is the biggest gap to your reference screenshots |
| 13 | P2 | **Ground detail is thin.** One road texture, flat grass blades, ferns, a few pebbles. No stone walls, verges, cart ruts, flowers, thistles or nettles | a01, a07 | Ground decal layer (ruts, stones, leaf litter), 4 or 5 grass and weed types, wildflowers, hedges and dry-stone walls |
| 14 | P3 | **Murky, under-lit look.** Every shot is dim brown-grey; color barely reads at noon. Your references are bright with clear color | All screenshots | A brighter overcast-day baseline: the mood comes from desaturated color, fog and cloud shadow, not from darkness (section 7) |
| 15 | P3 | **Performance.** Up to **17 million triangles and 6,300 draw calls** in one frame looking north from the spawn; 22 to 28 FPS at the farms and spawn on this PC. Trees have no distance versions (LODs) | Audit FPS lines | Tree LODs and far billboards, merging small props into batches, distance fading for clutter. Target 60 FPS at the spawn |
| 16 | P3 | Small things: a palisade "beacon" pole of light over the Gullet door looks like a stick in the sky (a10); the cobble patch at the Crossroads floats 1.8 m on one side; Signpost 2 stands in the river | a10, audit | Fixed during the re-lay |

**Not caused by the zone, but seen during the audit:** loading the Tithelands headless showed `Bandit_Sword.glb` has not been imported yet (it is new, uncommitted work in `assets/characters/bandit/`), so bandit spawns error out until the editor imports it. Opening the project in the editor once should fix it. I did not touch it.

---

## 3. What is worth keeping

| Keep as is | Keep, but rework | Replace |
|---|---|---|
| The ground textures (15 ambientCG PBR sets) and the blended ground shader | `ZoneTerrain`: add heightmap ground, building pads, spline roads | The bowl edges and the round quarry pit |
| The river water shader | `Scatter`: forest areas instead of rectangles | All building models (cottage, barn, mill, burned cottage, watchtower, tent) |
| Day/night, rain, fog, cloud layer | `GroundSnap`: replace with the pad-aware placer | Fir and dead trees (keep as a stand-in until new trees exist) |
| Campfire (flames, smoke, light) | Grass field: more types, kept out of buildings | Fence, barricade, palisade (rebuild as a modular kit) |
| Shrines, vendors, camp hearth, shortcut gate, ladders, cave door: **their logic** | Highcrown backdrop (move to z = −255 as planned in ZONES_DESIGN.md) | Cart, signpost, gallows, crates, barrels: replace with the **hideout asset library** versions, which are already more detailed |
| Enemy spawn points and the spawn director (names and tables stay, positions move) | Checkpoint dressing (banners, stalls) | Boulder generator (keep for small stones; big rocks become cliff and outcrop pieces) |

---

## 4. Rules for the redesign (how it stays playable)

- **Same IDs:** shrine IDs (`crossroads`, `mill`, `quarry`, `camp`), the gate ID `watchtower_south`, spawn point names, the zone ID. Saves keep working (explored map, opened shortcut, claimed camp).
- **Same order of play:** start at the Crossroads, levels 1 to 6, Gullet in the north-west, north road to Highcrown. The Gullet interior is untouched; only its outdoor door moves with the quarry.
- **Same scale:** 364 m square (your "not empty, not spread out" ruling). Zone 2 still joins at the north edge, about 7 m high.
- **Checks:** `zone_check` and `camp_check` get updated coordinates where they move; all checks must pass after each stage; the audit tool must show zero floating or buried buildings, zero doors facing away, nothing on a road.

---

## 5. Proposed new layout

### 5.1 The land

```
 N   ................ Highcrown on the skyline ................
     ~~~ wooded hills ~~~  [ KNIGHT'S GAP ]  ~~~ wooded hills ~~~
     SCARP  quarry benches     | checkpoint in the pass |    old barrow
     (cliff   Gullet mouth     |                        |    raider camp in a
     band)        \          tithe barn compound        |    ruined farmstead
      |          mill + weir ~~~~~~~ bridge ~~~~~~~~ ford ~~~~~~~~~~~ river gorge
      |    Hobb's hollow      \  river meadows           \      EAST WOODS (dense,
      |                burned hamlet street            watchtower crag   dark, old)
      |   farmstead A          \                        /
      |            farmstead B  CROSSROADS VILLAGE --- camp hearth
     ~~~~~~~~~~~ south ridge: hedges, coppice, ruined chapel overlook ~~~~~~~~~~~
 S
```

- **West:** a 12 to 20 m limestone **scarp** runs north to south and forms the west edge. The quarry is cut into its face in three benches, so it looks quarried, not dug. A switchback cart track climbs it. A hidden footpath runs along the cliff top to an overlook.
- **South:** the land rises gently to a low ridge with hedgerows, coppiced woodland and a **ruined chapel** on the crest (an overlook back over the whole valley, and an optional secret).
- **East:** **Watchtower Crag**, a real rocky knoll with exposed rock on its north face, then the **East Woods**: old, dense, darker forest climbing to a wooded ridge. The river runs through a short rocky gorge on its way out.
- **North:** two wooded hills pinch the road into **Knight's Gap**, a natural choke point where the checkpoint makes sense. Beyond it the road climbs onto open ground with Highcrown filling the skyline.
- **Middle:** the river valley. The river meanders in three wide bends: shallow gravel fords, reed beds, a mill weir, alders and willows along the banks.

### 5.2 Roads and paths

| Kind | Width | Route |
|---|---|---|
| **Tithe Road** (main) | 5 to 6 m, ruts, stone patches, a ditch on the uphill side | South edge → Crossroads village green → bends down to the **broken bridge** → up past the tithe barn gate → through Knight's Gap → north edge |
| **Mill Lane** | 3.5 to 4 m | Crossroads → farmstead A and B gates → the **burned hamlet street** → the mill (across the weir bridge) → the quarry track |
| **Quarry Track** | 3 m, cart ruts, spoil | Mill → switchbacks up to the quarry benches → the Gullet mouth |
| **East Lane** | 3.5 m | Crossroads → camp hearth → the woods edge → the watchtower path (the shortcut gate) |
| **Footpaths and tracks** | 1.2 to 2 m | River towpath (mill → bridge → ford), hunters' track through the East Woods to the raider camp, a sunken lane up to the chapel, the cliff-top path, a game trail to Hobb's hollow |

Every path ends at something (a gate, a camp, a view, a loot spot); no road runs into the zone edge except the Tithe Road north (to zone 2) and the south road (where you arrived from).

### 5.3 Places

| Place | Now | Proposed |
|---|---|---|
| **Crossroads village** (start) | Shrine on a cobble patch, gallows next to the spawn, two vendors on the road | A small village around a **triangular green** where three roads meet. The shrine stands under a huge old **oak** (landmark 1). A well, 3 or 4 cottages with fenced gardens and doors facing the green, a smithy lean-to (Old Wenna), an alehouse with a hanging sign, woodpiles, a cart being loaded. The gallows moves to the village edge on the road out, as a warning to arrivals |
| **Farmsteads A and B** | Two loose cottages and straight fence rows | Two courtyard farms off Mill Lane: house + barn + shed around a muddy yard, gate onto the lane, paddock, hay rick, plough, strip fields divided by dry-stone walls and hedges (the stone walls from your first screenshot) |
| **Burned hamlet** | Three burned shells in a triangle, one on the road | A **street** of 5 burned houses along Mill Lane, one still standing, scorch marks, a collapsed roof across the lane, a cart of looted goods, the gallows on its little green. Bandits are picking through it |
| **The mill** | Mill on the road, shrine inside it, door away from the lane | A stone mill on a **weir** with its wheel on the mill race, door onto Mill Lane, the miller's cottage, sacks and millstones, a footbridge over the race. Mill Shrine moves to the lane junction by the weir |
| **Hobb's hollow** | Tents on open grass | A camp in a sunken hollow by the river, under an overhang, with a lookout on the rim. You see the smoke before the camp |
| **Tithe Barn** | Huge box with its back to the road | A walled **tithe compound**: the great barn with its doors onto a yard, a stone wall and gatehouse opening onto the Tithe Road, tithe carts queued outside. The Knights' tax collectors work here, and you can see it is guarded |
| **Knights' checkpoint** | Barricades across a flat road | In **Knight's Gap**: barricade and gate across the pass, tents and stalls on the flat ground beside it, banners on the slopes. A natural choke point: the only way north, unless you find the cliff path |
| **Watchtower Crag** | A tower floating on a smooth hill, a palisade ring that floats and digs in | A ruined **stone tower on a rock crag** (landmark 2), a palisade that follows the contour of the summit, the shortcut gate on the path up the south side, broken siege debris below |
| **The quarry** | A round pit with smooth walls, a stone box for the Gullet mouth | Three **benches cut into the scarp**, spoil heaps, a timber crane and winch, workers' shacks, a cart track, cut blocks stacked to ship. The Gullet mouth is a dark cleft at the back of the lowest bench, with timber shoring (landmark 3: the crane silhouette on the cliff) |
| **East Woods** | Firs sprinkled at even spacing | Dense, old, dark mixed forest. Three real clearings for camps, an abandoned woodcutters' camp, a fallen giant tree you walk under, fog lying in the hollows |
| **Raider camp** (north-east) | Tents around a burned shell | Raiders holding a **ruined farmstead** on the edge of the woods: barricaded gaps in the walls, a watch platform, stolen tithe carts |
| **Ford camp** | A camp on the bank | Kept: guards the **shallow ford** below the bridge (the second way across) |
| **New: ruined chapel** | — | On the south ridge (landmark 4). An overlook over the whole valley; optional loot, lore |
| **New: old barrow** | — | A grassed burial mound with standing stones north-east of the woods (landmark 5), sealed; a hint at zone 3's barrow-folk |

**Sightlines (what you see from where):** from the spawn: the oak on the green, the road falling away to the bridge, the watchtower crag on the right, Highcrown on the skyline. From the bridge: the mill wheel up-river, the tithe compound ahead, Knight's Gap beyond. From the watchtower: the whole East Woods and the raider smoke. From the quarry rim: the valley and the chapel on the far ridge.

---

## 6. Assets

### 6.1 The honest part about detail

Your screenshots are from games made by large art teams with hand-made models and painted textures. Everything in Kingdom so far is built in code from boxes, which tops out well below that. To get close we need **real detailed models**, from three possible sources (decision 1 in section 9):

| Source | Good for | Limits |
|---|---|---|
| **A. Code-built kits, done properly** (like the new hideout library: bevelled and roughened shapes, individual stones and planks, PBR textures) | Buildings, walls, fences, props, roads. I can build all of these without any downloads | Trees and plants never look as good as scanned or hand-made ones |
| **B. CC0 downloads** (Poly Haven scanned rocks, logs, stumps, shrubs and plants; ambientCG textures; possibly free tree models) | Rocks, cliffs, plants, trees, more textures. Photo-real detail | Needs your OK for each download; some scans are very heavy and must be simplified |
| **C. Your AI art pipeline** | Hero pieces: the oak, the chapel, the watchtower, signs and banners | Slow, needs cleanup per piece |

**My recommendation:** A for all buildings and props (consistent style, one material set), B for rocks, cliff pieces, plants and trees, C later for 3 to 5 hero landmarks.

### 6.2 Asset list (modular, reusable)

| Group | New pieces |
|---|---|
| **Buildings** (modular half-timber + stone kit) | Wall panels (plaster, wattle, stone, timber), corner posts, doors, shutters, windows, gable ends, thatch and shingle roofs with real thickness and overhang, chimneys, plinths that go into slopes. Assembled into: 3 cottages, longhouse/farmhouse, barn, shed, lean-to, smithy, alehouse, stone mill, tithe barn, chapel ruin, tower ruin, gatehouse, ruined variants of each, burned variants |
| **Walls and boundaries** | Dry-stone wall (straight, end, corner, broken, gate gap), wattle fence, post-and-rail fence, gates, hedgerow, palisade kit that follows the ground, stone ruins (wall stubs, arches, rubble) |
| **Nature** | Broadleaf trees: oak (3 sizes), ash, alder and willow (riverside), birch; firs (improved); dead trees; saplings; bushes (bramble, hawthorn, elder); 4 or 5 grass and weed types, nettles, thistles, wildflowers, reeds; fallen trees, branches, stumps with roots, leaf litter |
| **Rock** | Cliff face pieces for the scarp and crag, outcrops, boulders, river stones, scree |
| **Props** (hideout library first, add what is missing) | Carts, wagons, hay carts, barrels, crates, sacks, wells, signposts, lanterns, torches, benches, tables, hay ricks, woodpiles, ploughs, scythes, millstones, troughs, beehives, laundry lines, gallows, gibbets, banners, tithe tallies |
| **Ground** | Road edge pieces, cart rut decals, cobble road sections, puddles, gravel, muddy patches, path stones, drainage ditches, small culvert bridges |

---

## 7. Lighting and atmosphere

- **Baseline:** a brighter, cool overcast day. Proper exposure, desaturated greens and browns, darkness kept for night, woods and caves.
- **Contrast between places:** open fields bright and windy; East Woods darker and enclosed with low fog in the hollows and shafts of light through clearings; the quarry pale and dusty; the river with mist in the mornings.
- **Warm light only where people are:** village windows, the smithy, campfires, braziers at the checkpoint.
- Check every change from the real gameplay camera at morning, noon, dusk and night, in clear weather and rain.

---

## 8. Proposed stages (each checked before the next)

| Stage | What | Checked by |
|---|---|---|
| **1. Ground system** | Heightmap terrain in `ZoneTerrain`, building pads, spline roads that follow the ground, forest-area scatter, placement check in `tools/zone1_audit.gd` | Old layout still loads; audit; all checks pass |
| **2. New land and road network** | Sculpt the new heightmap (scarp, ridge, crag, gap, river bends), lay the roads, move every place to its new site with the current gray props | Walk the routes; audit shows zero floating, buried or misfacing buildings; `zone_check`, `camp_check` |
| **3. Building and wall kit** | Modular kit, then the assembled buildings and boundaries, replacing the old boxes | Screenshot set from the gameplay camera, you look |
| **4. Nature** | Trees, bushes, plants, rocks, cliffs (sources from decision 1), forests painted in | Screenshots, FPS |
| **5. Storytelling dressing** | Each site dressed from its story (section 5.3) | Walkthrough |
| **6. Lighting and atmosphere** | Section 7 | Screenshots at four times of day and in rain |
| **7. Final validation** | Audit with zero errors, all checks, the 3-player check, FPS at 10 fixed spots, a full walk | Report to you |

Stages 1 and 2 need no new art and fix the most visible "this is not a real place" problems. I suggest you look at the zone after stage 2 before we put work into art.

---

## 9. Decisions I need from you

1. **Art sources:** OK to download CC0 rocks, plants and trees (Poly Haven, ambientCG and similar) in addition to code-built kits? Each download would be logged in `assets/CREDITS.md`.
2. **Layout:** go ahead with the new layout in section 5 (scarp, Knight's Gap, tithe compound, village around a green, quarry benches, chapel and barrow), or keep the current place positions and only fix them where they stand?
3. **Brightness:** OK to move to a brighter overcast-day baseline (section 7)? The game is quite dark now; your reference screenshots are bright.
4. **New places:** add the ruined chapel and the old barrow, or leave them out for now?
