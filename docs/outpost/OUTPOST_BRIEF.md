# KINGDOM — White Knights Outpost: the owner's brief (verbatim)

*Pasted by the owner into Claude Code on 2026-11-25, with two concept pictures (`layout_concept.webp`, `asset_sheet_concept.webp`, in this folder). Kept here word for word so later sessions and ChatGPT can read it. **The paste ends partway through section 9**; anything after that is missing.*

*The owner's note with it:* "this is the outpost at the north end of the map that you pass through right before reaching the castle and its moat"

*Status and Claude Code's questions: see the 2026-11-25 entry in `DESIGN_INBOX.md`.*

---

# KINGDOM — WHITE KNIGHTS OUTPOST
## Master Environment Asset Production & Integration Prompt

You are the lead environment artist, 3D asset pipeline developer, and Godot technical artist for KINGDOM.

Your task is to build a complete, modular, reusable 3D environment asset library for the KINGDOM White Knights Outpost.

This is an existing game project. You must inspect the repository and actual Godot project before making changes.

The goal is to create a believable medieval English settlement outside a fortified White Knights castle, using the established KINGDOM art direction.

---

# 1. READ THE PROJECT DOCUMENTATION FIRST

Before doing anything:

1. Read `KINGDOM_MASTER_CONTEXT.md` if available.
2. Read `README.md`.
3. Read `HANDOFF.md`.
4. Read `DESIGN.md`.
5. Read `SPEC.md` (reference only; do not modify).
6. Read `ART_NEEDS.md`.
7. Read `ZONES_DESIGN.md`.
8. Read `PRIORITIES.md`.
9. Inspect the actual Godot project structure.
10. Inspect existing environment assets, materials, terrain, scenes, scripts, and import settings.

Do not assume the project is empty.

Identify:
- Existing environment asset standards.
- Existing terrain and world scale.
- Existing material and texture conventions.
- Existing scene organization.
- Existing lighting and atmosphere.
- Existing character scale.
- Existing import settings.
- Existing Godot rendering configuration.

Preserve existing working systems.

Do not overwrite or redesign unrelated areas of the game.

If documentation conflicts, identify the conflict before making significant architectural changes.

# 2. KINGDOM GAME IDENTITY AND ART DIRECTION

KINGDOM is an original dark medieval fantasy co-op action RPG.

The environment must look like an actual classic MMORPG game world, not an AI-generated cinematic illustration.

## Core visual reference

The art direction is inspired by:
- Warhammer Online: Age of Reckoning.
- World of Warcraft Classic.
- Medieval English environments from the Robin Hood era.
- The grounded environmental presentation of Kingdom Come: Deliverance.

These are broad visual references only. All assets, heraldry, buildings, symbols, and designs must be original to KINGDOM.

## Required visual style

Use:
- Hand-painted textures.
- Chunky, readable geometry.
- Slightly pixelated-looking texture detail.
- Simplified but recognizable architectural shapes.
- Strong, readable silhouettes.
- Painted highlights and shadows.
- Broad color transitions.
- Painted scratches, dirt, wear, and weathering.
- Moderate polygon density.
- Dark, restrained color palettes.

Avoid:
- Photorealistic PBR appearance.
- Hyperrealistic AI concept-art rendering.
- Modern AAA cinematic asset styling.
- Excessively smooth geometry.
- Tiny details that cannot be seen during gameplay.
- Bright, cheerful fantasy colors.
- Generic low-poly mobile-game aesthetics.
- Literal 2D pixel art.

The final result should look like a carefully hand-painted 3D MMORPG environment.

## Atmosphere

The world should feel:
- Dark.
- Dangerous.
- Old.
- Weathered.
- Lived in.
- Rural.
- Historically grounded.
- Occasionally beautiful, but never cheerful or overly clean.

Use natural variations in terrain, building placement, vegetation, materials, and lighting.

# 3. HISTORICAL PERIOD

The outpost should be inspired by 12th–13th-century medieval England, approximately the Robin Hood era.

Use period-appropriate architectural forms and materials.

Appropriate materials include:
- Oak timber.
- Thatched roofing.
- Wattle and daub.
- Rough limestone.
- Weathered fieldstone.
- Timber framing.
- Linen and wool canvas.
- Forged iron.
- Leather.
- Rope.
- Wooden shingles.
- Mud and gravel.

Avoid:
- Renaissance architecture.
- Victorian architecture.
- Modern industrial objects.
- Modern tools or machinery.
- Inappropriate fantasy architecture.
- Excessive Gothic cathedral styling.
- Viking or Norse architectural themes.

Buildings should look practical and functional rather than designed as elaborate fantasy monuments.

# 4. WHITE KNIGHTS FACTION IDENTITY

The White Knights control the castle and surrounding settlement.

Their visual identity must be consistent throughout the asset library.

## Faction palette

- Ivory/off-white: `#E5E0CE`
- Dark red: `#A52F35`
- Tarnished gold: `#C3A45B`
- Charcoal iron: `#292B30`
- Weathered brown timber.
- Natural stone gray.

## Heraldry

Create an original, consistent White Knights heraldic design based on an ivory field and dark red cross.

Use the same emblem across:
- Large flags.
- Small pennants.
- Guard shields.
- Cloth banners.
- Market standards.
- Wooden signs.
- Supply crates.
- Military checkpoint decorations.

Do not create a different cross design for every object.

The White Knights should look disciplined, wealthy, authoritative, and imposing.

The civilian settlement around them should look poorer, weathered, and more organic.

This contrast is important.

# 5. OUTPOST DESIGN AND SCALE

The outpost is a small permanent medieval settlement outside a fortified castle.

It is not a temporary military camp.

The castle itself is NOT part of this asset production phase.

The future castle will have:
- Stone outer walls.
- Gatehouse.
- Moat.
- Drawbridge.
- Portcullis.
- Fortified towers.

Prepare the outpost assets to connect naturally to that future castle entrance.

## Established proposed dimensions

Use these as initial layout targets, subject to verification against the existing Godot world scale:

| Feature | Target |
|---|---:|
| Main road | 12 meters wide |
| Drawbridge | 12 meters wide |
| Military checkpoint | 14 meters wide |
| Market area | Approximately 28 × 24 meters |
| Outpost area | Approximately 160 × 120 meters |
| Typical single-story building | 3.5–5 meters high |
| Typical two-story building | 6–8.5 meters high |

The road and drawbridge must accommodate two large horse-drawn wagons side by side, with appropriate clearance.

The outpost should feel naturally arranged around the road and terrain.

Do not create a symmetrical settlement or a perfectly organized grid.

# 6. ASSET LIBRARY TO CREATE

Build the following modular asset categories.

Use the IDs as asset identifiers and maintain a manifest documenting each asset's status.

## A. Buildings

- B01 — Roadside inn / alehouse.
- B02 — Civilian blacksmith workshop.
- B03 — Stable and farrier shelter.
- B04 — Large market shelter.
- B05 — Small market stall.
- B06 — Carpenter workshop.
- B07 — Small cottage.
- B08 — Medium cottage.
- B09 — Storage shed.
- B10 — Guard shelter.

Each building must be a separate reusable scene.

Where practical, use modular components:
- Walls.
- Roof sections.
- Doors.
- Windows.
- Shutters.
- Chimneys.
- Support beams.
- Foundations.

## B. Castle approach and military checkpoint

- CP01 — Large White Knights banner.
- CP02 — Small pennant.
- CP03 — Banner pole.
- CP04 — Stone torch holder.
- CP05 — Standing iron brazier.
- CP06 — Wooden road barrier.
- CP07 — Movable timber barricade.
- CP08 — Guard inspection shelter.
- CP09 — Toll and inspection table.
- CP10 — Guard bench.
- CP11 — Spear rack.
- CP12 — Weapon storage chest.
- CP13 — Wooden shield display.
- CP14 — Supply barrels.
- CP15 — Supply crates.
- CP16 — Rope and chain bundles.
- CP17 — Iron lantern.
- CP18 — Warning sign.
- CP19 — Faction shield emblem.
- CP20 — Stone boundary marker.

The checkpoint should communicate that the White Knights control access to the castle.

## C. White Knights faction assets

- WK01 — Large ivory banner with red cross.
- WK02 — Narrow hanging banner.
- WK03 — Small triangular pennant.
- WK04 — Mounted standard.
- WK05 — Wooden shield with red cross.
- WK06 — Heraldic signboard.
- WK07 — Coat-of-arms plaque.
- WK08 — Red-and-ivory market awning.
- WK09 — Faction notice seal.
- WK10 — Stone insignia.
- WK11 — Banner ropes and fittings.
- WK12 — Banner stand.

Create a reusable heraldry texture/material so every faction asset uses the same emblem.

## D. Stable and horse area

- ST01 — Timber stable.
- ST02 — Stall partitions.
- ST03 — Stable doors.
- ST04 — Rectangular hay bales.
- ST05 — Loose hay piles.
- ST06 — Hay rack.
- ST07 — Wooden feeding trough.
- ST08 — Water trough.
- ST09 — Wooden water buckets.
- ST10 — Grain sacks.
- ST11 — Feed baskets.
- ST12 — Hitching posts.
- ST13 — Horse fence sections.
- ST14 — Stable gate.
- ST15 — Saddle rack.
- ST16 — Saddles.
- ST17 — Horse blankets.
- ST18 — Bridles and reins.
- ST19 — Horseshoes.
- ST20 — Farrier tool rack.
- ST21 — Manure piles.
- ST22 — Manure cart.
- ST23 — Wheelbarrow.
- ST24 — Stable lantern.
- ST25 — Grooming equipment.

The stable must look occupied and functional.

## E. Market props

- MK01 — Merchant stall.
- MK02 — Canvas awning.
- MK03 — Red-and-ivory awning.
- MK04 — Merchant table.
- MK05 — Display shelves.
- MK06 — Fruit baskets.
- MK07 — Vegetable baskets.
- MK08 — Grain sacks.
- MK09 — Bread baskets.
- MK10 — Meat hooks.
- MK11 — Hanging meat.
- MK12 — Fish basket.
- MK13 — Pottery display.
- MK14 — Clay pots.
- MK15 — Ceramic jugs.
- MK16 — Wooden bowls.
- MK17 — Weighing scales.
- MK18 — Iron weights.
- MK19 — Hanging cloth bolts.
- MK20 — Folded fabric.
- MK21 — Leather goods display.
- MK22 — Merchant coin chest.
- MK23 — Wooden price sign.
- MK24 — Market lantern.

## F. Blacksmith and forge

- BS01 — Open-sided forge building.
- BS02 — Stone forge furnace.
- BS03 — Anvil.
- BS04 — Anvil stump.
- BS05 — Bellows.
- BS06 — Hammers.
- BS07 — Tongs.
- BS08 — Workbench.
- BS09 — Tool rack.
- BS10 — Metal ingots.
- BS11 — Coal basket.
- BS12 — Coal pile.
- BS13 — Firewood stack.
- BS14 — Quenching barrel.
- BS15 — Water bucket.
- BS16 — Horseshoes.
- BS17 — Sword blade blanks.
- BS18 — Iron tools.
- BS19 — Weapon rack.
- BS20 — Chimney.
- BS21 — Ash pile.
- BS22 — Forge lantern.

## G. Inn and tavern

- IN01 — Inn building.
- IN02 — Tavern hanging sign.
- IN03 — Outdoor benches.
- IN04 — Outdoor tables.
- IN05 — Dining tables.
- IN06 — Wooden stools.
- IN07 — Bar counter.
- IN08 — Ale barrels.
- IN09 — Wooden drinking mugs.
- IN10 — Ceramic tankards.
- IN11 — Cooking pots.
- IN12 — Fireplace.
- IN13 — Firewood basket.
- IN14 — Food plates and bowls.
- IN15 — Hanging lanterns.
- IN16 — Beds and straw mattresses.
- IN17 — Linen bedding.
- IN18 — Wall shelves.
- IN19 — Hanging herbs.
- IN20 — Tavern notice board.

## H. Carpenter and trade workshop

- CR01 — Carpenter workshop.
- CR02 — Workbench.
- CR03 — Sawhorse.
- CR04 — Hand saw.
- CR05 — Wooden mallet.
- CR06 — Chisels and carving tools.
- CR07 — Timber plank piles.
- CR08 — Cut logs.
- CR09 — Firewood.
- CR10 — Wood shavings.
- CR11 — Wooden cart.
- CR12 — Cart wheels.
- CR13 — Wagon axle.
- CR14 — Rope coils.
- CR15 — Wooden pegs.
- CR16 — Timber frame sections.

## I. Cottages and civilian life

- CO01 — Small thatched cottage.
- CO02 — Wattle-and-daub cottage.
- CO03 — Cottage doors.
- CO04 — Wooden shutters.
- CO05 — Chimneys.
- CO06 — Vegetable gardens.
- CO07 — Garden fences.
- CO08 — Clotheslines.
- CO09 — Hanging linen.
- CO10 — Laundry baskets.
- CO11 — Wood piles.
- CO12 — Animal pens.
- CO13 — Chicken coop.
- CO14 — Feed trough.
- CO15 — Household tools.
- CO16 — Clay storage jars.
- CO17 — Benches.
- CO18 — Household buckets.

## J. Environment and terrain

- ENV01 — Muddy road material.
- ENV02 — Dirt path material.
- ENV03 — Grass material.
- ENV04 — Gravel and stone material.
- ENV05 — Puddle decals.
- ENV06 — Cart rut decals.
- ENV07 — Mud splash decals.
- ENV08 — Small grass clumps.
- ENV09 — Tall grass clumps.
- ENV10 — Ferns.
- ENV11 — Brambles.
- ENV12 — Bushes.
- ENV13 — Mossy rocks.
- ENV14 — Large boulders.
- ENV15 — Fallen logs.
- ENV16 — Oak trees.
- ENV17 — Beech trees.
- ENV18 — Birch trees.
- ENV19 — Tree stumps.
- ENV20 — Split-rail fences.
- ENV21 — Wattle fences.
- ENV22 — Fence gates.
- ENV23 — Stone path pieces.
- ENV24 — Creek water material.
- ENV25 — Creek rocks.
- ENV26 — Small footbridge.
- ENV27 — Wildflowers.
- ENV28 — Dead leaves and debris.

## K. Lighting and VFX

- FX01 — Standing wooden torch.
- FX02 — Iron brazier.
- FX03 — Hanging lantern.
- FX04 — Wall-mounted lantern.
- FX05 — Candle cluster.
- FX06 — Forge fire.
- FX07 — Smoke.
- FX08 — Torch flame.
- FX09 — Campfire.
- FX10 — Ground fog.
- FX11 — Fire sparks.
- FX12 — Rain splash.
- FX13 — Water ripples.

## L. Small environmental storytelling props

- DT01 — Abandoned wooden bucket.
- DT02 — Broken crate.
- DT03 — Empty sack.
- DT04 — Wooden spoon.
- DT05 — Clay plate.
- DT06 — Hanging rope.
- DT07 — Old iron chain.
- DT08 — Rusted tools.
- DT09 — Wooden handcart.
- DT10 — Broken wagon wheel.
- DT11 — Straw bundles.
- DT12 — Scattered firewood.
- DT13 — Fallen signboard.
- DT14 — Stone piles.
- DT15 — Animal tracks and hoofprints.
- DT16 — Paper notices.
- DT17 — White Knights supply crates.
- DT18 — Tattered cloth.
- DT19 — Old shields.
- DT20 — Abandoned spear.

This is the planned asset scope. Do not attempt to generate every item in one operation.

# 7. TECHNICAL ASSET REQUIREMENTS

The project uses Godot 4.7.2 and GDScript.

Inspect existing technical conventions before deciding implementation details.

## 3D model format

Prefer:
- GLB for imported models.
- Embedded textures where appropriate.
- Reusable Godot scenes for individual assets.
- Shared materials where possible.

For assets created externally using image-to-3D tools, treat incoming GLBs as source assets requiring inspection and possible cleanup.

Do not assume an imported model is game-ready.

Inspect:
- Scale.
- Origin.
- Orientation.
- Mesh quality.
- Texture quality.
- Material setup.
- UVs.
- Polygon count.
- Collision requirements.
- Compatibility with the existing Godot rendering pipeline.

Do not assume props need character skeletons or rigging.

## Scale

Use meters consistently.

Establish a standard asset scale based on the existing player character and project conventions.

Examples of approximate real-world dimensions:
- Barrel: 0.6–0.9 m tall.
- Hay bale: 0.8–1.2 m long.
- Market table: 1.2–2.0 m long.
- Door: 1.0–1.2 m wide and approximately 2 m tall.
- Stable stall: sized for a horse.
- Main road: 12 m wide.

These are initial design targets, not substitutes for checking existing project scale.

## Asset optimization

Assets must be suitable for a third-person multiplayer MMORPG.

Use:
- Reasonable polygon counts.
- Reusable materials.
- Texture atlases where appropriate.
- LODs for large or frequently repeated objects when justified.
- Instancing for repeated vegetation and props.
- Simple collision meshes.
- Static geometry where appropriate.
- Efficient draw-call management.

Avoid excessive material duplication and unnecessary high-resolution textures.

# 8. IMAGE-TO-3D WORKFLOW

The asset images and 3D models may be created separately using external image-to-3D tools such as Modelado.

You must distinguish between:
1. Concept reference images.
2. Single-object image-to-3D source images.
3. Generated GLB models.
4. Cleaned and optimized game-ready models.
5. Integrated Godot scenes.

Do not treat an asset catalog poster as an actual collection of source models.

Do not attempt to turn an entire asset sheet into one 3D object.

Each individual image-to-3D input should contain:
- One isolated object.
- Clear silhouette.
- Neutral background.
- Three-quarter view.
- No text or labels.
- No multiple objects overlapping.
- Clear material definition.

For modular assets, keep separate components separate where practical.

When an actual GLB is missing, do not claim the model has been created.

You may create a temporary placeholder only when needed to establish a scene or test integration. Label it clearly as a placeholder.

# 9. FILE ORGANIZATION

Create an organized asset structure following the existing project conventions.

Proposed structure:

```
game/
  assets/
    environment/
      outpost/
        buildings/
        castle_approach/
        white_knights/
        market/
        stable/
        blacksmith/
        inn/
        carpenter/
        cottages/
        props/
        environment/
        materials/
        vfx/

  world/
    outpost/
      scenes/
      components/
      materials/
```

Adapt this to the existing repository rather than blindly duplicating folders.

Use clear filenames and preserve the asset IDs.

Example:

`WK01_large_white_knights_banner.glb`

`ST04_rectangular_hay_bale.glb`

`BS03_blacksmith

*(the paste ends here)*
