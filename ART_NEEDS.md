# ART & AUDIO NEEDS

The art and sound shopping list, grouped by the phase that needs it. We use **gray-box placeholders** (capsules, boxes) until real assets arrive, so nothing here blocks the build.

**Rules**
- **CC0 only** for downloaded assets (free for anything, no credit required). Fonts may be **OFL** (free, credit required). Always check the license on the download page.
- Log every asset in [`assets/CREDITS.md`](assets/CREDITS.md): what it is, where it came from, its license.
- **AI** column: ⭐ = great candidate for your AI-generated art.
- **Status**: ⬜ needed · 🟨 placeholder in the game · ✅ final

## Where to look (all free)
**Target look: detailed, not low-poly** (see DESIGN.md §12.1). The "Quality" column says whether a source can be final art or is a stand-in until better art exists.

| Source | Best for | Quality | License |
|---|---|---|---|
| **Poly Haven** (polyhaven.com) | Overcast sky images (HDRIs), ground and rock textures, scanned rocks and plants | **Final** (scanned models are very heavy and must be simplified first) | CC0 |
| **ambientCG** (ambientcg.com) | Tileable textures: mud, grass, cobblestone, rock, wood, metal, cloth | **Final** | CC0 |
| **Your AI art** | Textures, icons, concept art; image-to-3D for armor pieces and props | **Final** after cleanup (check each tool's license) | Yours |
| **Quaternius** (quaternius.com) | Rigged humanoids, a big animation library, village and nature kits, animals | Stand-in (low-poly); **animations can be final** | CC0 |
| **KayKit** (kaylousberg.itch.io) | Chunky stylized characters, animations, dungeon kit, weapons | Stand-in (low-poly) | CC0 (free versions) |
| **Kenney** (kenney.nl) | UI packs, particle textures, sound effects, castle and town kits | UI, particles and sounds can be final; models are stand-ins | CC0 |
| **Freesound** (freesound.org) | Sound effects (use the "Creative Commons 0" license filter) | CC0 when filtered |
| **OpenGameArt** (opengameart.org) | Music and effects (filter by CC0) | Mixed, so CC0 only |
| **Google Fonts** (fonts.google.com) | Medieval-style fonts for UI and item text | OFL |

> **Style note.** Quaternius and KayKit are low-poly and cartoony, so they're placeholders, not the final look. Anything human-shaped must use the **standard humanoid skeleton** so the detailed models replacing them reuse the same animations. Environment detail comes from real textures, simplified scanned rocks and plants, and modular building kits, painted onto sculpted terrain.

---

## Phase 1–3: Player, combat, first enemy
*Nothing required now; primitives work. These are the first upgrades worth making.*

| Need | Details | Likely source | AI | Status |
|---|---|---|---|---|
| Player body (male + female) | Rigged humanoid on the standard skeleton, ~1.85 m, swappable gear pieces. Phase 2 uses a free stand-in; detailed version later | Stand-in: Quaternius mannequin (male in use, female ready). Final: AI art + cleanup | ⭐ final | 🟨 mannequin |
| Player animations | Idle, walk, run, sprint, **strafe ×4 (missing: you "moonwalk" sideways when locked on)**, jump/fall/land, roll (3 speeds), 1H sword light combo ×3, heavy + charge, block idle/hit, parry, riposte, hit react light/heavy, stagger, guard break, death, drink flask, interact | Have: UAL1 + UAL2 Standard (idle, walk, jog, sprint, jump, roll, death, hit, sword combos, block). Missing: strafes, backstep, parry, riposte, guard break | | 🟨 partly |
| Sword, shield, Marauder axe | First weapon set | AI art / modeled; stand-ins built from simple shapes in `assets/placeholder/weapons/` | ⭐ | 🟨 shapes |
| Training dummy | Wooden post with straw | Primitive is fine | | ⬜ |
| Dark Ages Marauder | Big brute, black iron and rust, two-handed axe | Humanoid + outfit pieces | ⭐ textures | 🟨 rust-tinted mannequin |
| Marauder animations | Idle, walk, run, 3 telegraphed axe attacks (one delayed), hit react, stagger, death | Using UAL sword animations slowed down; real two-handed axe swings wanted | | 🟨 borrowed |
| Blood | 6–8 splatter decals, spurt particle sprites | Now: one splat drawn by code + droplet particles | ⭐ decals | 🟨 generated |
| Hit sparks | Metal-on-metal sparks for blocks and parries | Now: glowing particles + flash of light | | 🟨 generated |
| Shrine (test) | Stone pillar or altar with amber flame | Primitive, then kit piece (`game/world/shrine.tscn`) | ⭐ concept | 🟨 shapes |
| **Sounds** | Sword swings ×3, flesh hits ×3, armor hits ×2, block thud, parry clang, footsteps (dirt, stone), roll, grunts (pain ×3, effort ×3, death ×2), drink flask, heavy axe whoosh | Freesound (CC0), Kenney Impact Sounds / RPG Audio | | ⬜ |

## Phase 4: Multiplayer
| Need | Details | Likely source | AI | Status |
|---|---|---|---|---|
| UI font(s) | A readable serif for menus and item text; a heavier display font for titles | Google Fonts (OFL) | | ⬜ |
| Party frame and chat art | Simple dark frames | Kenney UI pack, recolored | ⭐ | ⬜ |
| Main menu background | Moody key art: the Tithelands in fog, Highcrown on the horizon | n/a | ⭐ | ⬜ |
| Downed and revive animations | Collapse, crawl, help up | Animation libraries | | ⬜ |

## Phase 5: Classes
| Need | Details | Likely source | AI | Status |
|---|---|---|---|---|
| Class icons and portraits | Bulwark, Lamplighter, Headsman | n/a | ⭐ | ⬜ |
| Ability icons (18) | 6 per class, readable at small size. Now: colored squares with 2 letters | n/a | ⭐ | 🟨 letters |
| Resource bar styles | Resolve (steel), Oil (amber), Tally (notches) | n/a | ⭐ | ⬜ |
| Creator presets | Faces, hair, beards, skin tones. Now: broad/slender mannequin + 5 colors | Modular character packs / AI | | 🟨 basic |
| Starting gear looks | Chain + shield (Bulwark), robe + lantern-staff (Lamplighter), leather + executioner's greatsword (Headsman) | Now: tinted mannequins + simple-shape staff and greatsword (`assets/placeholder/weapons/`) | ⭐ textures | 🟨 shapes |
| Ability effects | Shout ripple, ember projectile, lantern circle, smoke cloud, flash, light column, pyre; bleed and frost visuals | Now: simple glowing shapes made in code | ⭐ textures | 🟨 basic |
| **Sounds** | War shout, shield bash, ember whoosh and burst, lantern hum, smoke hiss, flash, executioner chop; status sounds | Freesound, Kenney | | ⬜ |

## Phase 6: Loot
| Need | Details | Likely source | AI | Status |
|---|---|---|---|---|
| **Item icons** (lots) | Every weapon, armor piece, ring, amulet, consumable; same lighting and angle | n/a | ⭐⭐ | ⬜ |
| Rarity frames | White, green, blue, purple, orange borders and glows | n/a | ⭐ | ⬜ |
| Inventory and paperdoll | Grid background, slot silhouettes, character panel | Kenney UI, recolored | ⭐ | ⬜ |
| Gold and soul icons | Coin, soul wisp | n/a | ⭐ | ⬜ |
| Vendors | Old Wenna (gold), the Soul Broker (hooded, no face) | Humanoid + outfits | ⭐ concept | ⬜ |
| Weapon models | Axe, mace, greatsword, spear, bow, staff (several variants each by tier) | KayKit / Quaternius weapons | ⭐ textures | ⬜ |
| Weapon animations | A moveset per weapon type | Animation libraries | | ⬜ |
| Dropped loot visuals | Item on the ground, rarity light beam | Particles | | ⬜ |
| **Sounds** | Pickup, coin, souls absorb, equip (cloth, mail, plate), **drop sounds per rarity** (Legendary must be special) | Freesound, Kenney | | ⬜ |

## Phase 7: Death
| Need | Details | Likely source | AI | Status |
|---|---|---|---|---|
| Glowing loot pile | Heap of gear with a pale soul-glow | Particles + props | | ⬜ |
| Death screen | Short cryptic text over darkness | n/a | ⭐ | ⬜ |
| **Sounds** | Death sting, pile hum, recovery sound | Freesound | | ⬜ |

## Phase 8: The Tithelands (zone 1)
| Need | Details | Likely source | AI | Status |
|---|---|---|---|---|
| Village and farm kit | Cottages, barns, fences, carts, a mill, burned versions | Quaternius Medieval Village kit, Kenney | ⭐ textures | ⬜ |
| Nature | Dead and living trees (with wind sway and distance versions), bushes, grass, rocks, reeds | Poly Haven scans (simplified), Blender's free tree generator, AI art; Quaternius only as stand-in | ⭐ bark/leaf textures | 🟨 cylinders |
| Terrain textures | Mud, wet grass, cobblestone road, rock | ambientCG, Poly Haven | ⭐ | ⬜ |
| Castle backdrop | Highcrown's walls and towers (seen through fog) | Kenney Castle Kit, kitbash | ⭐ concept | 🟨 boxes |
| Ruins and watchtower | Broken walls, tower, gate, **ladder** | Kits | | ⬜ |
| Shrines (3–4) | Old stone shrine with amber flame | Kit pieces + custom | ⭐ concept | 🟨 cylinder |
| Overcast sky | Gray cloudy sky image | Poly Haven HDRI | | 🟨 gradient |
| Rain | Rain particles, splashes, wet-surface look | Particles + shader | | 🟨 streaks only |
| White Knight Zealot | Off-white tabard, tarnished gold, sword and shield, horn | Humanoid + outfits | ⭐ textures | ⬜ |
| Gaunt Hound | Starved wolf-like dog, rigged (run, bite, lunge, howl) | Quaternius animals | ⭐ textures | 🟨 box body |
| Hobb the Unhanged | Bandit chief with a noose around his neck | Humanoid + outfits | ⭐ | ⬜ |
| Map | Parchment map art, icons (shrine, party, you) | n/a | ⭐⭐ | 🟨 shaded terrain |
| **Music** | 2–3 ambient zone loops (day, night), a combat sting | OpenGameArt (CC0) or commissioned | | ⬜ |
| **Ambience** | Wind, rain loop, crows, distant bells, river, campfire crackle | Freesound | | ⬜ |
| **Sounds** | Horn call, hound howl/bark/bite, knight shouts, marauder roars | Freesound | | ⬜ |

## Phase 9: The Gullet (cave dungeon)
| Need | Details | Likely source | AI | Status |
|---|---|---|---|---|
| Cave kit | Rock walls, tunnels, stalagmites, bones, puddles | KayKit Dungeon, Poly Haven rocks | ⭐ textures | ⬜ |
| Candles | Lots: clusters, wax drips, candle-chapel | Simple models | | ⬜ |
| Fog gate | Swirling barrier shader | Shader | | ⬜ |
| Brother Tallow (boss) | Huge monk crusted with burning candles, censer-flail | Humanoid scaled up + custom | ⭐⭐ concept | ⬜ |
| Boss animations | Flail sweeps, overhead slam, wax spit, grab, phase change, stance break, death | Animation libraries + custom | | ⬜ |
| Candle Acolytes | Robed fanatics | Humanoid + outfits | | ⬜ |
| **Music** | Boss track (2 phases) | OpenGameArt (CC0) | | ⬜ |
| **Sounds** | Cave drips, echoes, flail chains, fire whoosh, monk chanting | Freesound | | ⬜ |
| Cave entrance | Stone arch at the quarry rim with a light beacon (now a gray-box arch plus an amber light beam) | Kit pieces + custom | ⭐ concept | 🟨 gray-box |
| Gullet interior | Carved gray-box rooms and corridors with candle lights, now built in code | Cave kit above | ⭐ textures | 🟨 gray-box |
| Burning ground | Fire patch decal and flames for phase 2 (now a glowing disc and light) | Particles + decal | | 🟨 disc |

## Planned: classes and factions (see CLASS_PLAN.md)
| Need | Details | Likely source | AI | Status |
|---|---|---|---|---|
| Class icons | Martial, Vanguard, Mystic and the nine subclasses | AI art | ⭐⭐ | ⬜ |
| Faction banners and looks | White Knights (noble, disciplined, medieval), Dark Ages (darker, unsettling, ritual), Outcasts (mismatched, travel-worn) | AI concept art | ⭐⭐ | ⬜ |
| Subclass weapons | Daggers, throwing knives, crossbows, tower shields, warhammers, ritual charms and more | Kit pieces + custom | ⭐ | ⬜ |

## White Knights Outpost (OUTPOST_PLAN.md; full list in assets/outpost/MANIFEST.md)
228 assets in the owner's brief: 49 built, 80 with a stand-in already in the project, 99 to make. Built in code with hand-painted textures; any can be swapped for your art.
| Need | Details | Likely source | AI | Status |
|---|---|---|---|---|
| White Knights set WK01-WK12 | Banners, pennant, standard, shield, signboard, plaque, awning, notice, stone insignia, fittings, banner stand | Code (`assets/outpost/white_knights/`) | | ✅ |
| Checkpoint CP01-CP20 | Barrier, barricade, guard shelter, toll table, bench, racks, chest, braziers, torch holders, lantern, stencilled barrels and crates, rope and chain, warning sign, boundary marker | Code (`assets/outpost/castle_approach/`) | | ✅ |
| Hand-painted textures | Emblem, oak, iron, gold, linen, stripes, rope, limestone, parchment (`assets/outpost/materials/textures/*.png`). Paint over them or replace with AI art, same name and size | Code now | ⭐⭐ | 🟨 code-painted |
| Organic props | Saddles, anvil, hanging meat, pottery, bellows: good image-to-3D candidates (one object per image, three-quarter view, plain background, no text) | Image-to-3D (e.g. Modelado) or code | ⭐⭐ | ⬜ |
| Buildings | Inn, blacksmith, stable, market shelter, carpenter, cottages, shed, guard shelter. All at 1.3x real-world size. Cottages, shed, market shelter and stall built; inn, blacksmith, stable, carpenter to do | Code kit (`assets/outpost/buildings/`) | ⭐ textures | 🟨 6 of 10 |

## Camp and raids (Phase 13, gray-box now)
| Need | Details | Likely source | AI | Status |
|---|---|---|---|---|
| Camp props | Fire pit and hearth, palisade stakes and gate, watch-fire torches, crates and barrels, a banner (all boxes and posts now) | Kenney or Quaternius medieval kits, plus custom | ⭐ | 🟨 gray-box |
| Raid chest | The reward drops as ordinary item beams; a real chest model would be nicer | Kit piece | | ⬜ |
| Raider look | Raiders reuse the Marauder, Zealot and Hound; a captain model for later | Existing + AI | ⭐⭐ | ⬜ |
| Sounds | A real war horn, palisade creaks, fire crackle at the hearth, a victory sting | Freesound (CC0) | | ⬜ |

## Later
Camp structures and raid enemies · dwarves and elves · high-tier armor (spikes, skulls, chains, banners) · dismemberment pieces · world bosses.
