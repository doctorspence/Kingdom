# ZONES 1 to 3: Map Layouts (working draft)

*Started 2026-11-21. The layout and story for the first three zones, with the Tithelands (zone 1) as built and two new zones after it. Nothing here is built yet, and `DESIGN.md` is not changed. Every name and number is a first suggestion; rename anything.*

**The maps (in this folder):**
| File | What it shows |
|---|---|
| `ZONES_OVERVIEW.png` / `.svg` | All three zones stacked as they join up, the elevation along the main route, one card per zone |
| `ZONE1_TITHELANDS_MAP.png` / `.svg` | Zone 1, redrawn from the real `tithelands.tscn` positions and terrain settings |
| `ZONE2_HIGHCROWN_MAP.png` / `.svg` | Zone 2, the city of Highcrown |
| `ZONE3_BARROW_FELLS_MAP.png` / `.svg` | Zone 3, the high moor |
| `heightmaps/zone*_height.png` + `heightmaps.json` | 16-bit heightmaps (1 pixel = 1 m) of the exact ground drawn on the maps, for building the terrain |
| `tools/zone_maps/` | The Python script that makes the maps and heightmaps (`python render.py out`), so the layout can be changed and redrawn |

Map conventions are the same as `ZoneTerrain`: meters, **x = east, z = south, north is up (−z)**, origin at the zone's center. **Heights are in meters above the Tithe River**, so the three zones line up when you walk from one to the next. Zone 1's map is an approximation of the real ground (Godot's noise can't be copied exactly), but every place, road, mound and the river use the real numbers from the scene.

---

## 1. Decisions so far (mine; tell me what to change)

| Topic | Suggestion |
|---|---|
| Order | Tithelands → **Highcrown** (north, up the road you already see) → **the Barrow Fells** (the high moor behind the city) |
| Shape of the land | Each zone climbs higher than the last: lowland valley (0 to 35 m), a city on a rising spur under a cliff (2 to 108 m), a high moor with peaks and a chasm (44 to 286 m) |
| Joining | Zone 2's south edge is zone 1's north edge (same x). Zone 3's south edge is zone 2's north edge (same x). The ground height matches at each crossing (about 7 m and about 107 m) |
| One river ties them together | The **Crown Water** rises in a mountain lake in zone 3, crosses the moor, falls 40 m off the cliff into Highcrown, drops down three more falls through the city's gorge, leaves through the Sluice and soaks into the fen. Water always runs downhill on these maps (checked by the script) |
| Levels | Zone 1: 1 to 6. Zone 2: 6 to 11 (dungeon 9 to 12; the level 10 subclass choice falls here). Zone 3: 11 to 17 (dungeon 15 to 18) |
| Size | Zone 1: 364 m. Zone 2: 420 m. Zone 3: 480 m. The main route is about 900 m of walking in zone 2 and 500 m in zone 3, plus side areas |
| Shrines | 3 or 4 per zone plus one halfway through each dungeon, like the Gullet |
| Darker as you go | Zone 1 is mud and bandits. Zone 2 adds the Knights' hidden use of the black stone. Zone 3 has open sorcery, the first undead, and a hint of the older peoples (a sealed dwarf-sized door) |

---

## 2. The story thread (suggested lore)

The Gullet already says the black stone existed before either faction, and its ledger says someone **ordered** the quarry's lower passage sealed. These zones follow that thread upward:

1. **Tithelands.** Bandits dig up a black stone and Harl is changed by it. The ledger: *"We were ordered to seal the lower passage."*
2. **Highcrown.** The order came from the White Knights. They preach against forbidden power, but the Reliquary under their cathedral is full of confiscated blackstone, and their white tabards are bleached in lye laced with stone dust (*"Stays white. Nobody asks how."*). The runoff made the lower town sick. The Knights called the sickness heresy, sealed the gate and burned the lower town: **the Cleansing**. This is why you couldn't enter the city in zone 1.
3. **Barrow Fells.** The stone breaks the surface in the **Rive**, a black chasm on the high moor. The Dark Ages mine and worship it there openly. But the moor is full of barrows from a people older than both factions, who fought the stone long ago, and the **oldest shrine** stands among their graves. *Optional answer to the open "death lore" question:* the barrow-folk built the shrines to bind souls so the stone could not take them, which is why players keep coming back.

---

## 3. Zone 1: The Tithelands (built; for reference)

Low, wet farm valley. The road runs north from the Crossroads over the broken bridge, past the tithe barn and the Knights' checkpoint, and ends at the zone's north edge with Highcrown's walls in the fog. Nothing about zone 1 has to change, except two small fixes so it joins zone 2 cleanly (see section 6).

---

## 4. Zone 2: Highcrown

*The White Knights' city on a granite spur. Sealed for the Cleansing, so you come in the back way.*

**Lay of the land.** A long tongue of granite (the **Crown spur**) runs south from a 40 m cliff (the **Scarp**). The city covers the spur in **terraces 6 m apart**, climbing from 12 m at the gate to 72 m at the cathedral crag. The Crown Water cuts a **gorge** down the city's east side, 8 m deep at the bottom and 25 m deep near the top, stepping down in waterfalls. West of the city a narrow ridge (the **Hill of Tabards**) climbs to the Scarp; east, the old quarry (**the Cutting**) is cut into the cliff in big 8 m steps. South of the walls the ground falls to a fen (the Lees) and the shanty town of Mudside.

**Main route (first time, about 900 m):** Causeway → Mudside (shrine; the gate is barred) → along the wall to the **Sluice** → wade in through the broken grate and the **Culverts** (a short tunnel) → up the gorge past the Lower Falls → across **Kingsbridge** into the burned **Lower Town** (the Walled Shrine) → **Rule Gate** → **Upper Ward** (Bellfoot Shrine) → the **Reliquary** under the cathedral (dungeon) → out the **West Postern** and up the spine of the Hill of Tabards → the **Pilgrim Stair** switchbacks up the Scarp → **Weathergate**, into zone 3.

| # | Area | Center (x, z) | Ground | What happens here | Mood |
|---|---|---|---|---|---|
| 1 | Tithe Causeway | 0, 190 | 7 m | Raised road over the fen from the Tithelands. Gibbets, carts left in the queue | Wet, grey, crows |
| 2 | Mudside | −118, 160 | 8 m | Outcast shanty against the wall, turned away at the gate. **Hub:** Mudside Shrine, a fence (vendor), rumors. Drinks from the Pale Runnel and is sick | Smoke, coughing, the only warm fires |
| 3 | The Lees | 150, 180 | 3 to 5 m | Reed fen where the Crown Water spreads out. Slow wading, drowned carts, hound packs. Optional loot | Mist low on the water |
| 4 | The Sluice & Culverts | 75, 139 | 12 m | The water gate under the wall. Its grate is broken: wade in. A short, dark culvert under the city | Echoes, dripping |
| 5 | Crown Gorge | 66, 80 | 17 to 40 m | Walkways and waterwheels along the gorge. Lower Falls (8 m), Middle Falls (9 m), Upper Falls (12 m). Kingsbridge (stone arch) and a rope walk cross it | Roar of water, spray, wet rock |
| 6 | Lower Town | −40, 105 | 12 to 30 m | Burned terraces, chalk-marked doors, plague carts, barricaded streets. **Cleanser** patrols with torches. The **Walled Shrine**: an old shrine the Knights bricked up and couldn't destroy; break in | Ash falling, embers, bells |
| 7 | The Bleachery | −76, 60 | 34 m | Lye vats on the spur's west edge. Pale runoff stains the cliff white and runs down to Mudside as the Pale Runnel. Lore clue: stone dust in the lye | Bleach-white, steam |
| 8 | Charnel Pits | 140, 80 | 15 to 20 m | Lime pits outside the east wall where the Cleansing's dead went. Optional, grim, good loot | Lime-white, silence, flies |
| 9 | Upper Ward | −30, 10 | 42 to 60 m | Behind the inner Rule Wall: barracks, drill yard, the Hall of Rules (archive). Heavy Knight patrols. **Bellfoot Shrine** | Clean, white, orderly, hostile |
| 10 | Crown Crag | 4, −46 | 66 to 72 m | Granite top of the spur: the cathedral and chapter house. Entrance to the **Reliquary** | Wind, banners, organ |
| 11 | Hill of Tabards | −140, 0 | 40 to 70 m | Knights' cemetery on a ridge: graves marked by tabards on poles, an ossuary. **Named rare** | Fog in the graves, flapping cloth |
| 12 | Pilgrim Stair | −100, −110 | 60 to 106 m | Up the ridge's spine to the cliff, then switchbacks cut into the Scarp face | Exposed, wind, long views back over the city |
| 13 | The Cutting | 150, −40 | 30 to 100 m | Optional second way up: Highcrown's old quarry, climbed bench by bench. Leads to the **Hermit's ledge** (secret) on top | Dusty, ledges, falling stone |
| 14 | Crownpool & the Veil | 43, −94 | 55 m | Behind the cathedral the Crown Water falls 40 m off the Scarp into a pool. A postern from the cathedral opens down to it (shortcut) | Thunder of the fall, rainbows in sun |
| 15 | The Upland | 40, −170 | 100 to 108 m | Top of the Scarp: open heath where the Crown Water runs to the cliff edge. Weathergate post at the north edge | First open sky, wind |

**Shrines:** Mudside (8 m), the Walled Shrine (24 m), Bellfoot (50 m), and one halfway through the Reliquary.

**Shortcuts:**
- **Penitents' Gate**, barred from inside; open it from Tithe Square to link the Causeway straight to the Lower Town.
- **Cathedral postern** down to the Crownpool (opens after the Reliquary's boss).
- Kingsbridge or the rope walk: two ways across the gorge.

**Dungeon: the Reliquary** (levels 9 to 12, about 10 to 12 minutes). Vaults under the cathedral where the Knights keep "confiscated heresies": shelves of sealed blackstone, ossuaries, a chapel lit by stone that doesn't burn. Halfway shrine. **Boss (suggestion): Lord Censor Aubrecht**, the Knight who ordered the Gullet sealed and ran the Cleansing. Phase 1 is a disciplined sword-and-shield Knight (reuses the Captain's block, bash and red overhead). In phase 2 he cracks a reliquary open and fights with blackstone, the hypocrisy shown. Readable objects: the Cleansing order and the letter to the quarry foreman.

**Named rare: Sir Gaspard, Twice-Buried** (5%, Hill of Tabards). A Knight who wouldn't stay in his grave. *"They buried him with honors. Then again, with a shovel."*

**Enemies.** Reuse: White Knight Zealot (patrols, horns), Gaunt Hounds (the Lees), Bandits as Mudside cutthroats. New: **Cleanser** (torch and burning ground), **Bell-ringer** (caller that rings the ward bell), **Knight Inquisitor** (elite, a reskinned Captain), **Bleacher** (slow, pale worker; poison buildup).

**Weather and change across the zone:** fen mist at the bottom, ash and ember-fall in the Lower Town, clean wind in the Upper Ward, spray and noise at the falls, clear sky on the Upland. At night the burned streets glow.

---

## 5. Zone 3: The Barrow Fells

*A wind-scoured high moor behind the Scarp. Barrows, a bog, a mountain lake, two snow peaks, and the black chasm where the stone comes up.*

**Lay of the land.** A rolling moor at 104 to 125 m rises gently north to two peaks: **Old Grey** (283 m, west) and **the Anvil** (260 m, flat-topped, east), with a pass between them (**the Saddle**, about 150 m) to the north edge. **Greymere Tarn** sits in a bowl high on Old Grey's flank (145 m); its outflow drops 15 m at **Tarnspill** and becomes the Crown Water, which crosses the moor, feeds **Sallow Bog** and runs off south to Highcrown. Across the middle runs **the Rive**: a chasm 20 to 40 m wide and up to 75 m deep, with black veins in the walls. The trees near it have turned grey and brittle (**the Ashwood**). **Cinderhold**, the Dark Ages' fortress, spans the Rive.

**Main route (about 500 m, then the dungeon):** Weathergate (shrine) → the Long Stones → along the bog's edge to the **Burning Fold** (Dark Ages war camp on a knoll) → through the **Ashwood** → **Rivebridge** (shrine) → **Cinderhold** (dungeon), going down into the Rive.
**Alternative route (west, longer, safer):** Long Stones → **Barrowfield** (Barrow Shrine) → up to **Greymere Tarn** (Tarnside Shrine) → down along the Rive's south rim to Rivebridge.

| # | Area | Center (x, z) | Ground | What happens here | Mood |
|---|---|---|---|---|---|
| 1 | Weathergate Rise | −40, 220 | 106 to 110 m | Top of the Pilgrim Stair: a ruined watch post. **Weathergate Shrine**. First view: moor, peaks, and a black scar on the horizon | Gale, flapping banners |
| 2 | The Long Stones | −50, 150 | 112 to 118 m | A row of ten standing stones across the moor. Lore carvings; a puzzle hook later | Stillness between gusts |
| 3 | Heather Moor | everywhere south | 104 to 125 m | Open heather, swells and hollows, sheep bones. Hound packs and a big moor predator. Little cover, so you are seen from far away | Purple-brown, scudding cloud shadows |
| 4 | Barrowfield | −150, 95 | 115 to 128 m | Nine grass-covered burial mounds on a rise. One is open (secret). **Barrow Shrine**, the oldest shrine in the game. Barrow dead at night | Low fog, silence, cold |
| 5 | Sallow Bog | 70, 150 | 102 to 103 m | Peat bog in a basin: black pools, cutters' huts, slow wading, lights over the water at night (first open sorcery) | Damp, green-black, will-o'-wisps |
| 6 | The Burning Fold | 118, 58 | 122 m | Dark Ages war camp on a knoll behind a palisade. Raids on the Tithelands start here. Blood-ritual casters | Bonfires, drums, red banners |
| 7 | Greymere Tarn | −128, −80 | 145 m | Mountain lake in a bowl under Old Grey's cliffs. A fishing hamlet of Outcasts (vendor). **Tarnside Shrine**. Mage-initiation hook: something drowned in the lake | Still grey water, cold, echoes |
| 8 | The Ashwood | 70, 10 | 115 to 120 m | Petrified forest along the Rive's south rim, ground grey with ash. Dark Ages pickets. The corruption is spreading south | Colorless, brittle, no birds |
| 9 | The Rive | 130, −74 | rim 120 m, floor 45 m | The chasm. Rope bridges and ledges along the walls; exposed black stone | Vertigo, a low hum from below |
| 10 | Cinderhold | 131, −74 | 120 m, down to 46 m | Dark Ages fortress across the Rive; the dungeon goes down into the chasm to the main mass of black stone | Firelight, chanting, heat from below |
| 11 | The Saddle | −15, −190 | about 150 m | Pass between the peaks: scree, sleet, snow above 170 m. The road north (zone 4, later) | Snow, whiteout gusts |
| 12 | Old Grey | −180, −205 | up to 283 m | Western peak. Cliffs over the tarn. Optional climb, lookout | Snowfield, wind |
| 13 | The Anvil | 172, −195 | up to 260 m | Flat-topped eastern peak. On its flank, **the Shut Door** (a sealed stone door far too big and too old for humans; a teaser for dwarves later) | Snow, an iron-cold quiet |

**Shrines:** Weathergate (110 m), Barrow (116 m), Tarnside (149 m), Rivebridge (119 m), and one halfway through Cinderhold.

**Shortcuts and secrets:** the open barrow; a rope descent from the Rive's rim into Cinderhold's lower level (opens from inside); the Shut Door (closed for now).

**Dungeon: Cinderhold** (levels 15 to 18). Starts on the bridge-fortress over the Rive and goes down 75 m into the chasm. **Boss (suggestion): Vessa, the Kindled**, the Dark Ages' high priestess, who channels the stone openly: the first fully magical boss, the reverse of Harl's understated power.

**Named rare: the Long Man** (5%, Barrowfield, **night only**). Something very tall walks between the barrows.

**Enemies.** Reuse: Dark Ages Marauder, Gaunt Hounds. New: **Cinder Cultist** (blood-ritual caster), **Barrow Dead** (first undead), **Rive Thrall** (people the stone changed further than Harl), a **Moor Stalker** (large predator, hunts in the open).

**Weather and change across the zone:** gales on the open moor, mist in the barrows, wet glow in the bog, sleet then snow above 150 to 170 m, an unnatural stillness and grey ash near the Rive.

---

## 6. Building notes (for Claude Code)

- **Zone 1 needs one small change to join zone 2:** move the Highcrown backdrop (`Highcrown` node, now at z = −238) to about **z = −255**, so its wall stands where zone 2's south wall is (world z = −252). The north road already stays at about 7 m right to the edge, which matches zone 2's causeway.
- **World placement:** zone 2's center is at world z = −392 and zone 3's at z = −842 (zone 1 at 0). All three share x. Zones can still load separately; this is only so their edges match.
- **Terrain:** `ZoneTerrain` today can make noise hills, round hills and pits, one river and flat roads. These zones also need **ridges, cliffs (the Scarp), terraces (city streets and the Cutting), a deep chasm (the Rive), several rivers with waterfalls, and lakes**. The simplest way: add a "load a heightmap" option to `ZoneTerrain` and use `heightmaps/zone2_height.png` and `zone3_height.png` (16-bit; `heightmaps.json` gives each one's min and max height). The painted ground types (grass, mud, road, rock) can stay as they work now.
- **Water** is a list of points with a bed height at each point (`Z2_CROWN_WATER`, `Z2_PALE_RUNNEL`, `Z3_CROWN_WATER` in `tools/zone_maps/zones.py`). Waterfalls are where the bed height drops sharply.
- **Underground parts:** the Culverts (short), the Reliquary and Cinderhold are separate interior builds like the Gullet; the maps only show their entrances.
- **To change a layout:** edit `tools/zone_maps/zones.py` and run `python render.py out`. The maps and heightmaps redraw from the same data, so they never disagree.

---

## 7. Decisions I need from you

1. **Order:** Highcrown as zone 2, or should Highcrown stay a hub you visit and zone 2 be wild land somewhere else?
2. **Can you walk through the city before the Reliquary?** The plan has the whole city hostile (sealed for the Cleansing). Alternative: the Lower Town is hostile, the Upper Ward is a guarded safe town for Outcasts who pay a tithe.
3. **Lore:** keep the "Knights ordered the Gullet sealed" thread and the shrine origin among the barrows?
4. **Names:** Crown Water, the Rive, Cinderhold, Lord Censor Aubrecht, Vessa the Kindled, Sir Gaspard, the Long Man, Old Grey, the Anvil, the Barrow Fells.
5. **Undead in zone 3:** the design says it gets stranger as you go north; is zone 3 the right place for the first undead?
