# White Knights Outpost asset library

Reusable 3D assets for the White Knights Outpost at the north end of the Tithelands: the Knights' banners, shields, signs and fittings now; the checkpoint, buildings, market, stable, forge, inn, carpenter, cottages and props to come. Plan: `OUTPOST_PLAN.md`. Every planned asset and its status: `MANIFEST.md`.

Built in GDScript on top of the bandit-hideout kit (`assets/hideout/`): the same mesh builder and the same asset layout, with hand-painted materials and simple collision.

## Using an asset

```gdscript
var n := (load("res://assets/outpost/white_knights/WK04_mounted_standard.scn") as PackedScene).instantiate()
add_child(n)
```

Each asset root is a `Node3D` with a `Mesh` (one mesh, a surface per material) and, for things you can bump into, a `Collision` (`StaticBody3D` with boxes and cylinders). In the editor, double-click any `.scn` in the FileSystem panel to look at it.

## Files

| Path | What |
| --- | --- |
| `materials/painter.gd` | Paints every texture in code: the emblem (ivory field, red cross pattee), oak, iron, gold, linen, stripes, rope, limestone, parchment |
| `materials/textures/*.png` | The painted textures. Paint over them or swap in AI art with the same name and size |
| `materials/outpost_kit.gd` | Materials, cloth (banners, pennants), the heater shield, carved and embossed shapes, the asset node |
| `materials/*.tres` | The shared materials, saved by the exporter |
| `white_knights/white_knights.gd` | Builders for WK01-WK12 |
| `catalog.gd` | Every built asset: folder, file name, builder |
| `<folder>/<ID_name>.scn` | The baked assets |

## Baking (after changing a builder or a texture)

Windows, from the project folder (`<godot>` = the console exe in HANDOFF.md):

```powershell
& "<godot>" --headless --path . --script res://tools/export_outpost.gd -- textures   # only after changing painter.gd
& "<godot>" --headless --path . --import                                             # only after the step above
& "<godot>" --headless --path . --script res://tools/export_outpost.gd               # bakes assets and materials
& "<godot>" --path . --resolution 1600x900 --script res://tests/visual_outpost.gd -- <out dir>   # preview pictures
```

Preview shots: `wk_overview wk_wall wk_stand wk_pennant`. Committed copies are in `docs/outpost/`.

## Conventions

- Meters, +Y up. Standing props sit on y = 0 at the centre of their base; hanging things have their origin at the top attachment point; wall-mounted things sit on the wall facing +Z.
- One emblem: `painter.gd arm_width()` defines the cross's shape for paint, carving (`outpost_kit.gd cross_poly()`) and wax alike.
- Tiling textures are sized in meters (oak 2 m, iron and gold 0.5 m, linen, stripes and limestone 1 m), so paint density matches across assets.
- Triangles: small props under 2,000, buildings under 8,000; meshes over 2,500 get automatic LODs.
- Scripts are loaded with `preload` constants, not `class_name`, so they run from the command line without an editor import.
- A parse error in a `--script` run can make headless Godot hang instead of exit. Kill only that process.
