"""Writes assets/outpost/MANIFEST.md from the list below (the White Knights Outpost assets).
Edit an asset's status here, then run:  python tools/outpost_manifest.py assets/outpost/MANIFEST.md
Status: "b" built for the outpost, "r" a stand-in exists in the project, "" to do."""
import sys
H = "hideout "
cats = [
("A. Buildings", "buildings", [
 ("B01","Roadside inn / alehouse","","same as IN01"),
 ("B02","Civilian blacksmith workshop","","same as BS01"),
 ("B03","Stable and farrier shelter","","same as ST01"),
 ("B04","Large market shelter","b","`B04_large_market_shelter.scn` (open hall, walk-through)"),
 ("B05","Small market stall","b","`B05_small_market_stall.scn` (real-world size: market furniture); also MK01"),
 ("B06","Carpenter workshop","","same as CR01"),
 ("B07","Small cottage","b","`B07_small_cottage.scn` (enterable, lit hearth; built 1.3x like every building)"),
 ("B08","Medium cottage","b","`B08_medium_cottage.scn` (enterable, hearth on the east gable)"),
 ("B09","Storage shed","b","`B09_storage_shed.scn` (board walls, lean-to roof, enterable)"),
 ("B10","Guard shelter","b","= CP08 (an enclosed sentry hut can follow if wanted)"),
]),
("B. Castle approach and military checkpoint", "castle_approach", [
 ("CP01","Large White Knights banner","b","= WK01"),
 ("CP02","Small pennant","b","= WK03"),
 ("CP03","Banner pole","b","`CP03_banner_pole.scn` (a WK03 pennant fits at `POLE_PENNANT`)"),
 ("CP04","Stone torch holder","b","`CP04_stone_torch_holder.scn` (lit)"),
 ("CP05","Standing iron brazier","b","`CP05_standing_iron_brazier.scn` (lit, casts shadows)"),
 ("CP06","Wooden road barrier","b","`CP06_wooden_road_barrier.scn` (two face to face close a 12 m road)"),
 ("CP07","Movable timber barricade","b","`CP07_movable_timber_barricade.scn`"),
 ("CP08","Guard inspection shelter","b","`CP08_guard_inspection_shelter.scn` (open front, walk-in; built 1.3x: eaves 3.6 m)"),
 ("CP09","Toll and inspection table","b","`CP09_toll_inspection_table.scn`"),
 ("CP10","Guard bench","b","`CP10_guard_bench.scn`"),
 ("CP11","Spear rack","b","`CP11_spear_rack.scn`"),
 ("CP12","Weapon storage chest","b","`CP12_weapon_storage_chest.scn`"),
 ("CP13","Wooden shield display","b","`CP13_wooden_shield_display.scn`"),
 ("CP14","Supply barrels","b","`CP14_supply_barrels.scn`"),
 ("CP15","Supply crates","b","`CP15_supply_crates.scn` (also DT17)"),
 ("CP16","Rope and chain bundles","b","`CP16_rope_and_chain_bundles.scn`"),
 ("CP17","Iron lantern","b","`CP17_iron_lantern.scn` (lit; also FX03, ST24, MK24, BS22, IN15)"),
 ("CP18","Warning sign","b","`CP18_warning_sign.scn`"),
 ("CP19","Faction shield emblem","b","= WK05 (wall) / WK07 (plaque)"),
 ("CP20","Stone boundary marker","b","`CP20_stone_boundary_marker.scn`"),
]),
("C. White Knights faction assets", "white_knights", [
 ("WK01","Large ivory banner with red cross","b","`WK01_large_white_knights_banner.scn`"),
 ("WK02","Narrow hanging banner","b","`WK02_narrow_hanging_banner.scn`"),
 ("WK03","Small triangular pennant","b","`WK03_small_triangular_pennant.scn`"),
 ("WK04","Mounted standard","b","`WK04_mounted_standard.scn`"),
 ("WK05","Wooden shield with red cross","b","`WK05_wooden_shield_red_cross.scn`"),
 ("WK06","Heraldic signboard","b","`WK06_heraldic_signboard.scn`"),
 ("WK07","Coat-of-arms plaque","b","`WK07_coat_of_arms_plaque.scn`"),
 ("WK08","Red-and-ivory market awning","b","`WK08_red_ivory_market_awning.scn` (also MK03)"),
 ("WK09","Faction notice seal","b","`WK09_faction_notice_seal.scn`"),
 ("WK10","Stone insignia","b","`WK10_stone_insignia.scn`"),
 ("WK11","Banner ropes and fittings","b","`WK11_banner_ropes_and_fittings.scn`"),
 ("WK12","Banner stand","b","`WK12_banner_stand.scn` (WK02 hangs from it)"),
]),
("D. Stable and horse area", "stable", [
 ("ST01","Timber stable","",""),("ST02","Stall partitions","",""),("ST03","Stable doors","r",H+"`door_gate`"),
 ("ST04","Rectangular hay bales","",""),("ST05","Loose hay piles","",""),("ST06","Hay rack","",""),
 ("ST07","Wooden feeding trough","","also CO14"),("ST08","Water trough","",""),("ST09","Wooden water buckets","r",H+"`bucket_water`"),
 ("ST10","Grain sacks","r",H+"`sack_grain`"),("ST11","Feed baskets","r",H+"`basket_empty`"),("ST12","Hitching posts","",""),
 ("ST13","Horse fence sections","",""),("ST14","Stable gate","",""),("ST15","Saddle rack","",""),
 ("ST16","Saddles","","good image-to-3D candidate"),("ST17","Horse blankets","",""),("ST18","Bridles and reins","",""),
 ("ST19","Horseshoes","","also BS16"),("ST20","Farrier tool rack","",""),("ST21","Manure piles","",""),
 ("ST22","Manure cart","",""),("ST23","Wheelbarrow","r",H+"`wheelbarrow_empty`, `wheelbarrow_loaded`"),("ST24","Stable lantern","b","= CP17"),
 ("ST25","Grooming equipment","",""),
]),
("E. Market props", "market", [
 ("MK01","Merchant stall","b","= B05"),("MK02","Canvas awning","","WK08 in plain linen"),("MK03","Red-and-ivory awning","b","= WK08"),
 ("MK04","Merchant table","r",H+"`table_trestle`"),("MK05","Display shelves","r",H+"`shelf_3tier`"),("MK06","Fruit baskets","r",H+"`basket_*` (new fruit)"),
 ("MK07","Vegetable baskets","r",H+"`basket_turnips`"),("MK08","Grain sacks","r",H+"`sack_grain`"),("MK09","Bread baskets","r",H+"`basket_bread`"),
 ("MK10","Meat hooks","r",H+"`hook_iron`"),("MK11","Hanging meat","r",H+"`meat_rack`; good image-to-3D candidate"),("MK12","Fish basket","",""),
 ("MK13","Pottery display","",""),("MK14","Clay pots","","also CO16"),("MK15","Ceramic jugs","",""),
 ("MK16","Wooden bowls","r",H+"`utensils`"),("MK17","Weighing scales","",""),("MK18","Iron weights","",""),
 ("MK19","Hanging cloth bolts","",""),("MK20","Folded fabric","",""),("MK21","Leather goods display","",""),
 ("MK22","Merchant coin chest","r",H+"`chest_closed` (smaller); the coin box on CP09"),("MK23","Wooden price sign","r",H+"`sign_post`"),("MK24","Market lantern","b","= CP17"),
]),
("F. Blacksmith and forge", "blacksmith", [
 ("BS01","Open-sided forge building","",""),("BS02","Stone forge furnace","",""),("BS03","Anvil","","good image-to-3D candidate"),
 ("BS04","Anvil stump","",""),("BS05","Bellows","",""),("BS06","Hammers","r",H+"`mining_hammer`"),
 ("BS07","Tongs","",""),("BS08","Workbench","r",H+"`table_slab`"),("BS09","Tool rack","",""),
 ("BS10","Metal ingots","",""),("BS11","Coal basket","r",H+"`basket_empty`"),("BS12","Coal pile","r",H+"`ore_pile` (darker)"),
 ("BS13","Firewood stack","",""),("BS14","Quenching barrel","r",H+"`barrel_water`"),("BS15","Water bucket","r",H+"`bucket_water`"),
 ("BS16","Horseshoes","","= ST19"),("BS17","Sword blade blanks","",""),("BS18","Iron tools","r",H+"`broken_tools`"),
 ("BS19","Weapon rack","r",H+"`weapon_rack`"),("BS20","Chimney","",""),("BS21","Ash pile","",""),
 ("BS22","Forge lantern","b","= CP17"),
]),
("G. Inn and tavern", "inn", [
 ("IN01","Inn building","",""),("IN02","Tavern hanging sign","","WK06's frame with its own board"),("IN03","Outdoor benches","","also CO17"),
 ("IN04","Outdoor tables","r",H+"`table_trestle`"),("IN05","Dining tables","r",H+"`table_trestle`"),("IN06","Wooden stools","r",H+"`stool_0`-`stool_2`"),
 ("IN07","Bar counter","",""),("IN08","Ale barrels","r",H+"`barrel_large`, `barrel_stack`"),("IN09","Wooden drinking mugs","",""),
 ("IN10","Ceramic tankards","",""),("IN11","Cooking pots","r",H+"`tripod_pot`"),("IN12","Fireplace","",""),
 ("IN13","Firewood basket","",""),("IN14","Food plates and bowls","r",H+"`utensils`"),("IN15","Hanging lanterns","b","= CP17"),
 ("IN16","Beds and straw mattresses","r",H+"`bedding_straw`"),("IN17","Linen bedding","r",H+"`bedding_blanket`"),("IN18","Wall shelves","r",H+"`shelf_3tier`"),
 ("IN19","Hanging herbs","",""),("IN20","Tavern notice board","","WK09 notices on a board"),
]),
("H. Carpenter and trade workshop", "carpenter", [
 ("CR01","Carpenter workshop","",""),("CR02","Workbench","r",H+"`table_slab`"),("CR03","Sawhorse","",""),
 ("CR04","Hand saw","",""),("CR05","Wooden mallet","",""),("CR06","Chisels and carving tools","",""),
 ("CR07","Timber plank piles","",""),("CR08","Cut logs","",""),("CR09","Firewood","",""),
 ("CR10","Wood shavings","",""),("CR11","Wooden cart","r","zone 1 story props (tipped cart)"),("CR12","Cart wheels","",""),
 ("CR13","Wagon axle","",""),("CR14","Rope coils","r",H+"`rope_coil`"),("CR15","Wooden pegs","",""),
 ("CR16","Timber frame sections","r","zone 1 `building_kit.gd` frame walls"),
]),
("I. Cottages and civilian life", "cottages", [
 ("CO01","Small thatched cottage","b","= B07"),("CO02","Wattle-and-daub cottage","r","zone 1 `building_kit.gd`"),("CO03","Cottage doors","r","zone 1 `building_kit.gd`"),
 ("CO04","Wooden shutters","r","zone 1 `building_kit.gd`"),("CO05","Chimneys","r","built into B07; a separate piece to do"),("CO06","Vegetable gardens","",""),
 ("CO07","Garden fences","",""),("CO08","Clotheslines","",""),("CO09","Hanging linen","",""),
 ("CO10","Laundry baskets","",""),("CO11","Wood piles","",""),("CO12","Animal pens","",""),
 ("CO13","Chicken coop","",""),("CO14","Feed trough","","= ST07"),("CO15","Household tools","r",H+"`shovel`, `broken_tools`"),
 ("CO16","Clay storage jars","","= MK14"),("CO17","Benches","","= IN03"),("CO18","Household buckets","r",H+"`bucket_*`"),
]),
("J. Environment and terrain", "environment", [
 ("ENV01","Muddy road material","r","zone 1 terrain shader (road, ruts, puddles)"),("ENV02","Dirt path material","r","zone 1 terrain shader (tracks)"),("ENV03","Grass material","r","zone 1 terrain + `grass_field.gd`"),
 ("ENV04","Gravel and stone material","r","zone 1 cobble paving, scree"),("ENV05","Puddle decals","r","zone 1 terrain puddles"),("ENV06","Cart rut decals","r","zone 1 terrain ruts"),
 ("ENV07","Mud splash decals","",""),("ENV08","Small grass clumps","r","`grass_field.gd`"),("ENV09","Tall grass clumps","r","`plant_scatter.gd`"),
 ("ENV10","Ferns","r","`plant_kit.gd` bracken, scanned ferns"),("ENV11","Brambles","r","`plant_kit.gd`"),("ENV12","Bushes","r","shrubs, holly (`plant_kit.gd`)"),
 ("ENV13","Mossy rocks","r","`assets/nature/rock_moss_set_*`"),("ENV14","Large boulders","r","`boulder.gd`"),("ENV15","Fallen logs","r","zone 1 deadwood"),
 ("ENV16","Oak trees","r","`tree_species.gd` oak"),("ENV17","Beech trees","r","`tree_species.gd` beech"),("ENV18","Birch trees","r","`tree_species.gd` birch"),
 ("ENV19","Tree stumps","",""),("ENV20","Split-rail fences","",""),("ENV21","Wattle fences","",""),
 ("ENV22","Fence gates","",""),("ENV23","Stone path pieces","",""),("ENV24","Creek water material","r","`water_stream.gd` (the brook)"),
 ("ENV25","Creek rocks","r","scree, `quarry_kit.gd`"),("ENV26","Small footbridge","r",H+"`bridge_3m`"),("ENV27","Wildflowers","r","`plant_kit.gd` bluebell, foxglove"),
 ("ENV28","Dead leaves and debris","r","terrain leaf litter"),
]),
("K. Lighting and VFX", "vfx", [
 ("FX01","Standing wooden torch","r",H+"`torch_stand`"),("FX02","Iron brazier","b","= CP05"),("FX03","Hanging lantern","b","= CP17"),
 ("FX04","Wall-mounted lantern","",""),("FX05","Candle cluster","r",H+"`candles_3`"),("FX06","Forge fire","r","hideout kit `fire_fx()`"),
 ("FX07","Smoke","r","hideout kit `fire_fx()`"),("FX08","Torch flame","r","hideout kit `fire_fx()`"),("FX09","Campfire","r",H+"`campfire_ring`"),
 ("FX10","Ground fog","r","`mist.gd`"),("FX11","Fire sparks","r","hideout kit `fire_fx()`"),("FX12","Rain splash","",""),
 ("FX13","Water ripples","",""),
]),
("L. Small environmental storytelling props", "props", [
 ("DT01","Abandoned wooden bucket","r",H+"`bucket_empty`"),("DT02","Broken crate","r",H+"`crate_broken`"),("DT03","Empty sack","r",H+"`sack_slumped`"),
 ("DT04","Wooden spoon","",""),("DT05","Clay plate","",""),("DT06","Hanging rope","r",H+"`hanging_rope_2m`"),
 ("DT07","Old iron chain","r",H+"`chain_1m`"),("DT08","Rusted tools","r",H+"`broken_tools`"),("DT09","Wooden handcart","",""),
 ("DT10","Broken wagon wheel","",""),("DT11","Straw bundles","",""),("DT12","Scattered firewood","",""),
 ("DT13","Fallen signboard","","WK06's board, fallen"),("DT14","Stone piles","r",H+"`rubble_small`"),("DT15","Animal tracks and hoofprints","","decal"),
 ("DT16","Paper notices","b","= WK09 (plain variants still to do)"),("DT17","White Knights supply crates","b","= CP15"),("DT18","Tattered cloth","",""),
 ("DT19","Old shields","","worn WK05"),("DT20","Abandoned spear","",""),
]),
]
icon = {"b":"✅","r":"♻️","":"⬜"}
word = {"b":"built","r":"stand-in exists","":"to do"}
tot = {"b":0,"r":0,"":0}
for _,_,items in cats:
    for it in items: tot[it[2]] += 1
n = sum(tot.values())
out = []
out.append("# White Knights Outpost: asset manifest\n")
out.append("*Every asset in the owner's brief (`docs/outpost/OUTPOST_BRIEF.md`, section 6), with its status. Plan and rules: `OUTPOST_PLAN.md`. Generated by `tools/outpost_manifest.py`: change an asset's status there and rerun it, rather than editing this file.*\n")
out.append("**Status:** ✅ built for the outpost (hand-painted, baked to `assets/outpost/<folder>/<ID_name>.scn`) · ♻️ something usable already exists in the project and can stand in, but the outpost version is still to make · ⬜ to do.\n")
out.append(f"**Totals ({n} assets):** ✅ {tot['b']} built · ♻️ {tot['r']} with a stand-in · ⬜ {tot['']} to do. Some IDs are the same asset under two names (marked \"=\" or \"same as\"); they are counted under both.\n")
out.append("**How each asset is made:** built in code for now (`assets/outpost/`, like the bandit-hideout kit). Any asset can later be swapped for a GLB the owner makes with an image-to-3D tool: keep the same file name, origin and size (rules in `OUTPOST_PLAN.md`, section 6).\n")
out.append("\"hideout\" means the bandit-hideout library, `assets/hideout/<folder>/<name>.scn`.\n")
for title, folder, items in cats:
    b = sum(1 for i in items if i[2]=="b")
    out.append(f"\n## {title} (`{folder}/`, {b} of {len(items)} built)\n")
    out.append("| ID | Asset | Status | File or stand-in |")
    out.append("|---|---|---|---|")
    for i in items:
        out.append(f"| {i[0]} | {i[1]} | {icon[i[2]]} | {i[3]} |")
open(sys.argv[1],"w").write("\n".join(out)+"\n")
print(n, tot)
