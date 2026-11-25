extends RefCounted
## Every built asset in the outpost library: [folder, ID_name, builder Callable].
## tools/export_outpost.gd bakes each to assets/outpost/<folder>/<ID_name>.scn.
## The full planned list, with what is built and what is not, is MANIFEST.md.

const WK := preload("res://assets/outpost/white_knights/white_knights.gd")
const CP := preload("res://assets/outpost/castle_approach/castle_approach.gd")
const BLD := preload("res://assets/outpost/buildings/buildings.gd")
const MKT := preload("res://assets/outpost/market/market.gd")
const BSM := preload("res://assets/outpost/blacksmith/blacksmith.gd")
const STB := preload("res://assets/outpost/stable/stable.gd")
const INN := preload("res://assets/outpost/inn/inn.gd")
const CRP := preload("res://assets/outpost/carpenter/carpenter.gd")
const COT := preload("res://assets/outpost/cottages/cottages.gd")
const ENVR := preload("res://assets/outpost/environment/environment.gd")
const VFX := preload("res://assets/outpost/vfx/vfx.gd")
const STO := preload("res://assets/outpost/props/story.gd")


static func entries() -> Array:
	var e: Array = []
	var W := "white_knights"
	e.append([W, "WK01_large_white_knights_banner", WK.large_banner])
	e.append([W, "WK02_narrow_hanging_banner", WK.narrow_banner])
	e.append([W, "WK03_small_triangular_pennant", WK.small_pennant])
	e.append([W, "WK04_mounted_standard", WK.mounted_standard])
	e.append([W, "WK05_wooden_shield_red_cross", WK.wooden_shield])
	e.append([W, "WK06_heraldic_signboard", WK.signboard])
	e.append([W, "WK07_coat_of_arms_plaque", WK.plaque])
	e.append([W, "WK08_red_ivory_market_awning", WK.market_awning])
	e.append([W, "WK09_faction_notice_seal", WK.notice_seal])
	e.append([W, "WK10_stone_insignia", WK.stone_insignia])
	e.append([W, "WK11_banner_ropes_and_fittings", WK.banner_fittings])
	e.append([W, "WK12_banner_stand", WK.banner_stand])
	# CP01, CP02 and CP19 are WK01, WK03 and WK05.
	var C := "castle_approach"
	e.append([C, "CP03_banner_pole", CP.banner_pole])
	e.append([C, "CP04_stone_torch_holder", CP.stone_torch_holder])
	e.append([C, "CP05_standing_iron_brazier", CP.iron_brazier])
	e.append([C, "CP06_wooden_road_barrier", CP.road_barrier])
	e.append([C, "CP07_movable_timber_barricade", CP.timber_barricade])
	e.append([C, "CP08_guard_inspection_shelter", CP.guard_shelter])
	e.append([C, "CP09_toll_inspection_table", CP.toll_table])
	e.append([C, "CP10_guard_bench", CP.guard_bench])
	e.append([C, "CP11_spear_rack", CP.spear_rack])
	e.append([C, "CP12_weapon_storage_chest", CP.weapon_chest])
	e.append([C, "CP13_wooden_shield_display", CP.shield_display])
	e.append([C, "CP14_supply_barrels", CP.supply_barrels])
	e.append([C, "CP15_supply_crates", CP.supply_crates])
	e.append([C, "CP16_rope_and_chain_bundles", CP.rope_chain_bundles])
	e.append([C, "CP17_iron_lantern", CP.iron_lantern])
	e.append([C, "CP18_warning_sign", CP.warning_sign])
	e.append([C, "CP20_stone_boundary_marker", CP.boundary_marker])
	var B := "buildings"
	e.append([B, "B01_roadside_inn", BLD.inn])
	e.append([B, "B02_civilian_blacksmith_workshop", BLD.blacksmith])
	e.append([B, "B03_stable_farrier_shelter", BLD.stable])
	e.append([B, "B04_large_market_shelter", BLD.market_shelter])
	e.append([B, "B05_small_market_stall", BLD.market_stall])
	e.append([B, "B07_small_cottage", BLD.small_cottage])
	e.append([B, "B08_medium_cottage", BLD.medium_cottage])
	e.append([B, "B06_carpenter_workshop", BLD.carpenter])
	e.append([B, "B09_storage_shed", BLD.storage_shed])
	e.append(["blacksmith", "BS03_anvil_on_stump", BLD.anvil_on_stump])
	var M := "market"
	for it in [["MK02_canvas_awning", MKT.canvas_awning], ["MK04_merchant_table", MKT.merchant_table],
			["MK05_display_shelves", MKT.display_shelves], ["MK06_fruit_basket", MKT.fruit_basket],
			["MK07_vegetable_basket", MKT.vegetable_basket], ["MK08_grain_sacks", MKT.grain_sacks],
			["MK09_bread_basket", MKT.bread_basket], ["MK10_meat_hooks", MKT.meat_hooks],
			["MK11_hanging_meat", MKT.hanging_meat], ["MK12_fish_basket", MKT.fish_basket],
			["MK13_pottery_display", MKT.pottery_display], ["MK14_clay_pots", MKT.clay_pots],
			["MK15_ceramic_jugs", MKT.ceramic_jugs], ["MK16_wooden_bowls", MKT.wooden_bowls],
			["MK17_weighing_scales", MKT.weighing_scales], ["MK18_iron_weights", MKT.iron_weights],
			["MK19_hanging_cloth_bolts", MKT.hanging_cloth], ["MK20_folded_fabric", MKT.folded_fabric],
			["MK21_leather_goods_display", MKT.leather_goods], ["MK22_merchant_coin_chest", MKT.coin_chest],
			["MK23_wooden_price_sign", MKT.price_sign]]:
		e.append([M, it[0], it[1]])
	var S := "blacksmith"
	for it in [["BS05_bellows", BSM.bellows], ["BS06_hammers", BSM.hammers], ["BS07_tongs", BSM.tongs],
			["BS08_workbench", BSM.workbench], ["BS09_tool_rack", BSM.tool_rack], ["BS10_metal_ingots", BSM.ingots],
			["BS11_coal_basket", BSM.coal_basket], ["BS12_coal_pile", BSM.coal_pile], ["BS13_firewood_stack", BSM.firewood_stack],
			["BS14_quenching_barrel", BSM.quench_barrel], ["BS15_water_bucket", BSM.water_bucket], ["BS16_horseshoes", BSM.horseshoes],
			["BS17_sword_blade_blanks", BSM.blade_blanks], ["BS18_iron_tools", BSM.iron_tools], ["BS19_weapon_rack", BSM.weapon_rack],
			["BS21_ash_pile", BSM.ash_pile]]:
		e.append([S, it[0], it[1]])
	for it in [["ST03_stable_doors", STB.stable_doors], ["ST04_rectangular_hay_bales", STB.hay_bales], ["ST05_loose_hay_piles", STB.hay_piles],
			["ST06_hay_rack", STB.hay_rack], ["ST07_wooden_feeding_trough", STB.feed_trough], ["ST08_water_trough", STB.water_trough],
			["ST11_feed_baskets", STB.feed_baskets], ["ST12_hitching_post", STB.hitching_post], ["ST13_horse_fence_section", STB.fence_section],
			["ST14_stable_gate", STB.stable_gate], ["ST15_saddle_rack", STB.saddle_rack], ["ST16_saddle", STB.saddle],
			["ST17_horse_blankets", STB.horse_blankets], ["ST18_bridles_and_reins", STB.bridles], ["ST20_farrier_tool_box", STB.farrier_tools],
			["ST21_manure_pile", STB.manure_pile], ["ST22_manure_cart", STB.manure_cart], ["ST23_wheelbarrow", STB.wheelbarrow],
			["ST25_grooming_equipment", STB.grooming]]:
		e.append(["stable", it[0], it[1]])
	for it in [["IN03_outdoor_bench", INN.outdoor_bench], ["IN04_outdoor_table", INN.outdoor_table], ["IN05_dining_table", INN.dining_table],
			["IN06_wooden_stools", INN.stools], ["IN08_ale_barrels", INN.ale_barrels], ["IN09_wooden_mugs", INN.mugs],
			["IN10_ceramic_tankards", INN.tankards], ["IN11_cooking_pot", INN.cooking_pot], ["IN13_firewood_basket", INN.firewood_basket],
			["IN16_bed_straw_mattress", INN.bed], ["IN17_bed_linen_bedding", INN.bed_linen], ["IN18_wall_shelves", INN.wall_shelves],
			["IN19_hanging_herbs", INN.hanging_herbs], ["IN20_tavern_notice_board", INN.notice_board]]:
		e.append(["inn", it[0], it[1]])
	for it in [["CR02_workbench", CRP.workbench], ["CR03_sawhorse", CRP.sawhorse], ["CR04_hand_saw", CRP.hand_saw],
			["CR05_wooden_mallet", CRP.mallet], ["CR06_chisels_and_carving_tools", CRP.chisels], ["CR07_timber_plank_pile", CRP.plank_pile],
			["CR08_cut_logs", CRP.cut_logs], ["CR10_wood_shavings", CRP.shavings], ["CR11_wooden_cart", CRP.wooden_cart],
			["CR12_cart_wheels", CRP.cart_wheels], ["CR13_wagon_axle", CRP.wagon_axle], ["CR15_wooden_pegs", CRP.pegs],
			["CR16_timber_frame_section", CRP.frame_section]]:
		e.append(["carpenter", it[0], it[1]])
	for it in [["CO03_cottage_door", COT.cottage_door], ["CO04_wooden_shutters", COT.shutters], ["CO05_chimney_stack", COT.chimney],
			["CO06_vegetable_garden", COT.vegetable_garden], ["CO07_garden_fence", COT.garden_fence], ["CO08_clothesline", COT.clothesline],
			["CO09_hanging_linen", COT.hanging_linen], ["CO10_laundry_basket", COT.laundry_basket], ["CO12_animal_pen", COT.animal_pen],
			["CO13_chicken_coop", COT.chicken_coop], ["CO15_household_tools", COT.household_tools]]:
		e.append(["cottages", it[0], it[1]])
	for it in [["ENV07_mud_splash_decal", ENVR.mud_splash], ["ENV19_tree_stumps", ENVR.tree_stumps], ["ENV23_stone_path_pieces", ENVR.stone_path],
			["ENV25_creek_rocks", ENVR.creek_rocks], ["ENV26_small_footbridge", ENVR.footbridge]]:
		e.append(["environment", it[0], it[1]])
	for it in [["FX01_standing_wooden_torch", VFX.standing_torch], ["FX04_wall_mounted_lantern", VFX.wall_lantern], ["FX05_candle_cluster", VFX.candles],
			["FX09_campfire", VFX.campfire], ["FX12_rain_splash", VFX.rain_splash], ["FX13_water_ripples", VFX.water_ripples]]:
		e.append(["vfx", it[0], it[1]])
	for it in [["DT01_abandoned_wooden_bucket", STO.bucket], ["DT02_broken_crate", STO.broken_crate], ["DT03_empty_sack", STO.empty_sack],
			["DT04_wooden_spoon", STO.spoon], ["DT05_clay_plate", STO.clay_plate], ["DT06_hanging_rope", STO.hanging_rope],
			["DT07_old_iron_chain", STO.old_chain], ["DT08_rusted_tools", STO.rusted_tools], ["DT10_broken_wagon_wheel", STO.broken_wheel],
			["DT12_scattered_firewood", STO.scattered_firewood], ["DT13_fallen_signboard", STO.fallen_signboard], ["DT14_stone_piles", STO.stone_piles],
			["DT15_animal_tracks_and_hoofprints", STO.tracks], ["DT18_tattered_cloth", STO.tattered_cloth], ["DT19_old_shields", STO.old_shields],
			["DT20_abandoned_spear", STO.abandoned_spear]]:
		e.append(["props", it[0], it[1]])
	return e
