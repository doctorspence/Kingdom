"""Writes assets/outpost/MANIFEST.md from the list below (the White Knights Outpost assets).
Edit an asset's status here, then run:  python tools/outpost_manifest.py assets/outpost/MANIFEST.md
Status: "b" built for the outpost, "r" a stand-in exists in the project, "" to do."""
import sys
H = "hideout "
cats = [
("A. Buildings", "buildings", [
 ("B01","Roadside inn / alehouse","b","`B01_roadside_inn.scn` (two storeys; taproom with bar and hearth; the upper floor is a ceiling for now); also IN01"),
 ("B02","Civilian blacksmith workshop","b","`B02_civilian_blacksmith_workshop.scn` (open forge, furnace, chimney, bellows); also BS01"),
 ("B03","Stable and farrier shelter","b","`B03_stable_farrier_shelter.scn` (three stalls, hay rack); also ST01"),
 ("B04","Large market shelter","b","`B04_large_market_shelter.scn` (open hall, walk-through)"),
 ("B05","Small market stall","b","`B05_small_market_stall.scn` (real-world size: market furniture); also MK01"),
 ("B06","Carpenter workshop","b","`B06_carpenter_workshop.scn` (open front, workbench, plank rack); also CR01"),
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
 ("ST01","Timber stable","b","= B03"),("ST02","Stall partitions","b","built into B03"),("ST03","Stable doors","b","`ST03_stable_doors.scn`"),
 ("ST04","Rectangular hay bales","b","`ST04_rectangular_hay_bales.scn`"),("ST05","Loose hay piles","b","`ST05_loose_hay_piles.scn`"),("ST06","Hay rack","b","`ST06_hay_rack.scn`"),
 ("ST07","Wooden feeding trough","b","`ST07_wooden_feeding_trough.scn`"),("ST08","Water trough","b","`ST08_water_trough.scn`"),("ST09","Wooden water buckets","b","= BS15"),
 ("ST10","Grain sacks","b","= MK08"),("ST11","Feed baskets","b","`ST11_feed_baskets.scn`"),("ST12","Hitching posts","b","`ST12_hitching_post.scn`"),
 ("ST13","Horse fence sections","b","`ST13_horse_fence_section.scn`"),("ST14","Stable gate","b","`ST14_stable_gate.scn`"),("ST15","Saddle rack","b","`ST15_saddle_rack.scn`"),
 ("ST16","Saddles","b","`ST16_saddle.scn`"),("ST17","Horse blankets","b","`ST17_horse_blankets.scn`"),("ST18","Bridles and reins","b","`ST18_bridles_and_reins.scn`"),
 ("ST19","Horseshoes","b","= BS16"),("ST20","Farrier tool rack","b","`ST20_farrier_tool_box.scn`"),("ST21","Manure piles","b","`ST21_manure_pile.scn`"),
 ("ST22","Manure cart","b","`ST22_manure_cart.scn`"),("ST23","Wheelbarrow","b","`ST23_wheelbarrow.scn`"),("ST24","Stable lantern","b","= CP17"),
 ("ST25","Grooming equipment","b","`ST25_grooming_equipment.scn`"),
]),
("E. Market props", "market", [
 ("MK01","Merchant stall","b","= B05"),("MK02","Canvas awning","b","`MK02_canvas_awning.scn`"),("MK03","Red-and-ivory awning","b","= WK08"),
 ("MK04","Merchant table","b","`MK04_merchant_table.scn`"),("MK05","Display shelves","b","`MK05_display_shelves.scn`"),("MK06","Fruit baskets","b","`MK06_fruit_basket.scn`"),
 ("MK07","Vegetable baskets","b","`MK07_vegetable_basket.scn`"),("MK08","Grain sacks","b","`MK08_grain_sacks.scn`"),("MK09","Bread baskets","b","`MK09_bread_basket.scn`"),
 ("MK10","Meat hooks","b","`MK10_meat_hooks.scn`"),("MK11","Hanging meat","b","`MK11_hanging_meat.scn`"),("MK12","Fish basket","b","`MK12_fish_basket.scn`"),
 ("MK13","Pottery display","b","`MK13_pottery_display.scn`"),("MK14","Clay pots","b","`MK14_clay_pots.scn`"),("MK15","Ceramic jugs","b","`MK15_ceramic_jugs.scn`"),
 ("MK16","Wooden bowls","b","`MK16_wooden_bowls.scn`"),("MK17","Weighing scales","b","`MK17_weighing_scales.scn`"),("MK18","Iron weights","b","`MK18_iron_weights.scn`"),
 ("MK19","Hanging cloth bolts","b","`MK19_hanging_cloth_bolts.scn`"),("MK20","Folded fabric","b","`MK20_folded_fabric.scn`"),("MK21","Leather goods display","b","`MK21_leather_goods_display.scn`"),
 ("MK22","Merchant coin chest","b","`MK22_merchant_coin_chest.scn`"),("MK23","Wooden price sign","b","`MK23_wooden_price_sign.scn`"),("MK24","Market lantern","b","= CP17"),
]),
("F. Blacksmith and forge", "blacksmith", [
 ("BS01","Open-sided forge building","b","= B02"),("BS02","Stone forge furnace","b","built into B02"),("BS03","Anvil","b","`blacksmith/BS03_anvil_on_stump.scn` (with BS04)"),
 ("BS04","Anvil stump","b","= BS03"),("BS05","Bellows","b","`BS05_bellows.scn`"),("BS06","Hammers","b","`BS06_hammers.scn`"),
 ("BS07","Tongs","b","`BS07_tongs.scn`"),("BS08","Workbench","b","`BS08_workbench.scn`"),("BS09","Tool rack","b","`BS09_tool_rack.scn`"),
 ("BS10","Metal ingots","b","`BS10_metal_ingots.scn`"),("BS11","Coal basket","b","`BS11_coal_basket.scn`"),("BS12","Coal pile","b","`BS12_coal_pile.scn`"),
 ("BS13","Firewood stack","b","`BS13_firewood_stack.scn`"),("BS14","Quenching barrel","b","`BS14_quenching_barrel.scn`"),("BS15","Water bucket","b","`BS15_water_bucket.scn`"),
 ("BS16","Horseshoes","b","`BS16_horseshoes.scn`"),("BS17","Sword blade blanks","b","`BS17_sword_blade_blanks.scn`"),("BS18","Iron tools","b","`BS18_iron_tools.scn`"),
 ("BS19","Weapon rack","b","`BS19_weapon_rack.scn`"),("BS20","Chimney","b","built into B02"),("BS21","Ash pile","b","`BS21_ash_pile.scn`"),
 ("BS22","Forge lantern","b","= CP17"),
]),
("G. Inn and tavern", "inn", [
 ("IN01","Inn building","b","= B01"),("IN02","Tavern hanging sign","b","built into B01 (a painted tankard)"),("IN03","Outdoor benches","b","`IN03_outdoor_bench.scn`"),
 ("IN04","Outdoor tables","b","`IN04_outdoor_table.scn`"),("IN05","Dining tables","b","`IN05_dining_table.scn`"),("IN06","Wooden stools","b","`IN06_wooden_stools.scn`"),
 ("IN07","Bar counter","b","built into B01"),("IN08","Ale barrels","b","`IN08_ale_barrels.scn`"),("IN09","Wooden drinking mugs","b","`IN09_wooden_mugs.scn`"),
 ("IN10","Ceramic tankards","b","`IN10_ceramic_tankards.scn`"),("IN11","Cooking pots","b","`IN11_cooking_pot.scn`"),("IN12","Fireplace","b","built into B01"),
 ("IN13","Firewood basket","b","`IN13_firewood_basket.scn`"),("IN14","Food plates and bowls","b","= MK16"),("IN15","Hanging lanterns","b","= CP17"),
 ("IN16","Beds and straw mattresses","b","`IN16_bed_straw_mattress.scn`"),("IN17","Linen bedding","b","`IN17_bed_linen_bedding.scn`"),("IN18","Wall shelves","b","`IN18_wall_shelves.scn`"),
 ("IN19","Hanging herbs","b","`IN19_hanging_herbs.scn`"),("IN20","Tavern notice board","b","`IN20_tavern_notice_board.scn`"),
]),
("H. Carpenter and trade workshop", "carpenter", [
 ("CR01","Carpenter workshop","b","= B06"),("CR02","Workbench","b","`CR02_workbench.scn`"),("CR03","Sawhorse","b","`CR03_sawhorse.scn`"),
 ("CR04","Hand saw","b","`CR04_hand_saw.scn`"),("CR05","Wooden mallet","b","`CR05_wooden_mallet.scn`"),("CR06","Chisels and carving tools","b","`CR06_chisels_and_carving_tools.scn`"),
 ("CR07","Timber plank piles","b","`CR07_timber_plank_pile.scn`"),("CR08","Cut logs","b","`CR08_cut_logs.scn`"),("CR09","Firewood","b","= BS13"),
 ("CR10","Wood shavings","b","`CR10_wood_shavings.scn`"),("CR11","Wooden cart","b","`CR11_wooden_cart.scn`"),("CR12","Cart wheels","b","`CR12_cart_wheels.scn`"),
 ("CR13","Wagon axle","b","`CR13_wagon_axle.scn`"),("CR14","Rope coils","b","= CP16"),("CR15","Wooden pegs","b","`CR15_wooden_pegs.scn`"),
 ("CR16","Timber frame sections","b","`CR16_timber_frame_section.scn`"),
]),
("I. Cottages and civilian life", "cottages", [
 ("CO01","Small thatched cottage","b","= B07"),("CO02","Wattle-and-daub cottage","b","= B08 (wattle-and-daub)"),("CO03","Cottage doors","b","`CO03_cottage_door.scn`"),
 ("CO04","Wooden shutters","b","`CO04_wooden_shutters.scn`"),("CO05","Chimneys","b","`CO05_chimney_stack.scn`"),("CO06","Vegetable gardens","b","`CO06_vegetable_garden.scn`"),
 ("CO07","Garden fences","b","`CO07_garden_fence.scn`"),("CO08","Clotheslines","b","`CO08_clothesline.scn`"),("CO09","Hanging linen","b","`CO09_hanging_linen.scn`"),
 ("CO10","Laundry baskets","b","`CO10_laundry_basket.scn`"),("CO11","Wood piles","b","= BS13"),("CO12","Animal pens","b","`CO12_animal_pen.scn`"),
 ("CO13","Chicken coop","b","`CO13_chicken_coop.scn`"),("CO14","Feed trough","b","= ST07"),("CO15","Household tools","b","`CO15_household_tools.scn`"),
 ("CO16","Clay storage jars","b","= MK14"),("CO17","Benches","b","= IN03"),("CO18","Household buckets","b","= BS15"),
]),
("J. Environment and terrain", "environment", [
 ("ENV01","Muddy road material","r","zone 1 terrain shader (road, ruts, puddles)"),("ENV02","Dirt path material","r","zone 1 terrain shader (tracks)"),("ENV03","Grass material","r","zone 1 terrain + `grass_field.gd`"),
 ("ENV04","Gravel and stone material","r","zone 1 cobble paving, scree"),("ENV05","Puddle decals","r","zone 1 terrain puddles"),("ENV06","Cart rut decals","r","zone 1 terrain ruts"),
 ("ENV07","Mud splash decals","",""),("ENV08","Small grass clumps","r","`grass_field.gd`"),("ENV09","Tall grass clumps","r","`plant_scatter.gd`"),
 ("ENV10","Ferns","r","`plant_kit.gd` bracken, scanned ferns"),("ENV11","Brambles","r","`plant_kit.gd`"),("ENV12","Bushes","r","shrubs, holly (`plant_kit.gd`)"),
 ("ENV13","Mossy rocks","r","`assets/nature/rock_moss_set_*`"),("ENV14","Large boulders","r","`boulder.gd`"),("ENV15","Fallen logs","r","zone 1 deadwood"),
 ("ENV16","Oak trees","r","`tree_species.gd` oak"),("ENV17","Beech trees","r","`tree_species.gd` beech"),("ENV18","Birch trees","r","`tree_species.gd` birch"),
 ("ENV19","Tree stumps","",""),("ENV20","Split-rail fences","b","= ST13"),("ENV21","Wattle fences","b","= CO07"),
 ("ENV22","Fence gates","b","= ST14"),("ENV23","Stone path pieces","",""),("ENV24","Creek water material","r","`water_stream.gd` (the brook)"),
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
 ("DT07","Old iron chain","r",H+"`chain_1m`"),("DT08","Rusted tools","r",H+"`broken_tools`"),("DT09","Wooden handcart","b","= ST22's cart (CR11 without the load)"),
 ("DT10","Broken wagon wheel","",""),("DT11","Straw bundles","b","= ST04 / ST05"),("DT12","Scattered firewood","",""),
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
