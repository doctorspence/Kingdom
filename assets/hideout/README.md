# Bandit Hideout Asset Library

Reusable 3D assets for an occupied underground quarry: natural cave pieces, scavenged-timber
structures, storage, camp gear, mining equipment, torchlight and props. Realistic low fantasy:
no glowing crystals, no magic, no clean furniture. Godot 4.7, all geometry built in GDScript.

## Using an asset

Every asset is baked to a scene file you can instance directly:

```gdscript
var n := (load("res://assets/hideout/Storage_Containers/barrel_large.scn") as PackedScene).instantiate()
add_child(n)
```

Each asset root is a `Node3D` with a `Mesh` (`MeshInstance3D`, one mesh, a surface per material)
and a `Collision` (`StaticBody3D`). Lit assets (torches, fires, lanterns, candles) also carry
their own light and particles. The full list is `Materials/catalog.gd`: `[folder, name, builder]`.
The assembled demo is `Example_Hideout_Scene/hideout_example.scn` (layout in `hideout_scene.gd`).

## Folders

| Folder | Contents |
| --- | --- |
| `Cave_Geometry` | floor / wall / wet wall / ceiling tiles, tunnels, cave opening, rock fall, pillar, ledge, rock formations, stalagmites, stalactites, pool |
| `Wooden_Structures` | platforms, stairs, railings, ladders, posts, crossbeams, doors and gate, scaffold, bridges, barricade, hanging platform, shelves |
| `Storage_Containers` | barrels, barrel stack, crates, sacks, buckets, baskets, chests, mining boxes |
| `Camp_Equipment` | campfires, tripod and pot, stools, chairs, tables, utensils, bedding, tent, meat rack, hanging rope, personal area |
| `Mining_Equipment` | carts, track, pickaxe, shovel, hammer, wheelbarrows, winch, pulley gantry, timber support frames, broken tools, rubble, ore, rope coil |
| `Lighting_Props` | wall torches (bracket, cresset), torch stand, brazier, lantern, candles, oil lamp |
| `Environmental_Props` | chains, hooks, signs, weapon rack |
| `Materials` | shared materials (`*.tres`), `kit.gd`, `catalog.gd`, `flicker.gd` |
| `Example_Hideout_Scene` | the assembled hideout |

Each category folder holds builder scripts (`<name>.gd`, `<name>_extra.gd`) and the baked `.scn` files.

## Conventions

- Units are meters, +Y up, real-world scale (door 2 m, barrel ~1 m, mine cart gauge 0.6 m).
- Origins: props sit on y = 0 at the center of their base. Exceptions:
  - `platform`: center of the deck top (legs hang below).
  - `stairs`: bottom front, climbing toward -Z; the top is at y = `rise`.
  - `railing`: bottom of the first post, running along +X.
  - Hanging things (lantern, chain, hanging rope): the top attachment point.
  - Wall-mounted pieces (torch, hook, weapon rack): the wall contact point, facing +Z.
  - Wall tiles: bottom center, facing +Z.
- Modular snapping:
  - Platforms and cave tiles use a 2 m / 4 m grid.
  - Cave floor, wall and ceiling tile edges are pinned to the tile plane, so vary the seed per tile and they meet without gaps.
  - Track is 2 m with rails exactly at x = ±1 (rotate 90° to run along Z).
  - Tunnel sections share one arch profile (3.2 x 2.8 m) and chain end to end.
- Collision: convex for props, trimesh for walkable or concave pieces (platforms, tiles, tunnels, frames).
- Triangles: every asset is under 4,000; meshes over 2,500 get automatic LODs.
- Materials: PBR from the project textures (wood, iron with rust, stone variants, cloth, rope). UVs are in meters, so texture density is consistent.
- Variants come from the builder parameters: `barrel("small" | "large" | "water" | "grain" | "broken")`, `chair(0..2)`, `platform(w, d, leg, "plain" | "worn")`, and so on.

## Changing or adding assets

1. Edit or add a builder in the category script. It returns `Kit.asset(name, mb, collide)`.
   Use `Kit.MB` for geometry (`box`, `cyl`, `lathe`, `blob`, `grid`, `quad`, `tri`, `disc`) and
   `Kit.wood()`, `Kit.iron()`, `Kit.stone()`, `Kit.cloth()`, `Kit.rope()` for materials.
2. Add an entry to `Materials/catalog.gd`.
3. Bake everything (assets, materials, example scene):

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tools/export_hideout.gd
```

4. Review renders (opens a window; saves PNGs to the folder you pass):

```powershell
& "<godot console exe>" --path . --resolution 1600x900 --script res://tests/visual_hideout.gd -- <out dir> storage camp example_a
```

Shot names: `storage structures camp mining cave`, `storage_close camp_close mining_close`,
`more_structures more_camp more_mining more_props more_cave`, `example_a` to `example_e`.
`hideout_samples/` holds the committed renders.

## Gotchas

- A parse error in a `--script` run can make headless Godot hang instead of exit. Kill only that process (never all Godot processes; the editor or game may be open).
- Scripts are loaded with `preload` constants, not `class_name`, so they work from the command line without an editor import. Inner classes cannot call the outer script's static functions.
- Particle flames and lights flicker through `Materials/flicker.gd` on the light node, not a runtime tween, so saved scenes keep working.
- The look is procedural placeholder-grade detail. Final art can replace individual assets by keeping the same name, origin and scale.
