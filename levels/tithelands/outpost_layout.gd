extends RefCounted
## Where the White Knights Outpost stands in the Tithelands (OUTPOST_PLAN.md section 4, the owner's
## choice A: Highcrown moved closer, the outpost in front of its moat). Meters, x = east, z = south.
##
## GROUPS: each is [centre x, centre z, turn (degrees), [items]]. Each item is
##   [asset, x, z, turn, height above the ground]   (x, z: within the group, before turning it)
## where asset is "folder/ID_name" under assets/outpost/. Every item stands on the terrain under it
## (game/world/outpost.gd). Move a whole group by changing its centre; move one thing by its x, z.
## The land script also reads PADS (flattened ground), YARDS (trampled dirt, no grass) and KEEP
## (no trees, rocks or plants) from here.

const K := 1.3  # the buildings' size (buildings.gd SIZE): interiors are placed in drawn meters x K.

const GROUPS := [
	# The White Knights checkpoint at the drawbridge (the map's north edge is z -178.5).
	[0.0, -170.0, 0.0, [
		["castle_approach/CP06_wooden_road_barrier", -6.2, -2.0, 0.0, 0.0],
		["castle_approach/CP06_wooden_road_barrier", 6.2, -2.0, 180.0, 0.0],
		["castle_approach/CP08_guard_inspection_shelter", -10.5, -2.5, 90.0, 0.0],
		["castle_approach/CP08_guard_inspection_shelter", 10.5, -2.5, -90.0, 0.0],
		["castle_approach/CP17_iron_lantern", -8.6, -2.5, 0.0, 3.32],
		["castle_approach/CP17_iron_lantern", 8.6, -2.5, 0.0, 3.32],
		["castle_approach/CP05_standing_iron_brazier", -6.8, 3.0, 0.0, 0.0],
		["castle_approach/CP05_standing_iron_brazier", 6.8, 3.0, 0.0, 0.0],
		["castle_approach/CP04_stone_torch_holder", -7.0, -6.5, 0.0, 0.0],
		["castle_approach/CP04_stone_torch_holder", 7.0, -6.5, 0.0, 0.0],
		["castle_approach/CP03_banner_pole", -8.5, 8.0, 0.0, 0.0],
		["castle_approach/CP03_banner_pole", 8.5, 8.0, 0.0, 0.0],
		["white_knights/WK03_small_triangular_pennant", -8.5, 8.0, 0.0, 4.47],
		["white_knights/WK03_small_triangular_pennant", 8.5, 8.0, 180.0, 4.47],
		["castle_approach/CP09_toll_inspection_table", -4.4, 4.0, 0.0, 0.0],
		["castle_approach/CP10_guard_bench", -14.0, 3.5, 90.0, 0.0],
		["castle_approach/CP11_spear_rack", 14.5, 3.5, -90.0, 0.0],
		["castle_approach/CP12_weapon_storage_chest", 14.0, -5.5, -90.0, 0.0],
		["castle_approach/CP13_wooden_shield_display", -14.5, -5.5, 90.0, 0.0],
		["castle_approach/CP14_supply_barrels", 15.0, -1.0, -60.0, 0.0],
		["castle_approach/CP15_supply_crates", -15.5, -0.5, 80.0, 0.0],
		["castle_approach/CP16_rope_and_chain_bundles", 12.0, 8.0, 0.0, 0.0],
		["castle_approach/CP07_movable_timber_barricade", 17.0, 9.0, 20.0, 0.0],
		["castle_approach/CP18_warning_sign", 7.2, 18.0, -10.0, 0.0],
		["white_knights/WK06_heraldic_signboard", -7.5, 16.0, 160.0, 0.0],
		["white_knights/WK04_mounted_standard", -7.0, 12.0, 0.0, 0.0],
		["white_knights/WK04_mounted_standard", 7.0, 12.0, 0.0, 0.0],
		["environment/ENV07_mud_splash_decal", -3.0, 1.0, 0.0, 0.0],
		["props/DT15_animal_tracks_and_hoofprints", 2.0, 6.0, 5.0, 0.0],
	]],
	# Where the Knights' land begins, on the road out of Knight's Gap.
	[0.0, -138.0, 0.0, [
		["castle_approach/CP20_stone_boundary_marker", -7.5, 0.0, 15.0, 0.0],
		["castle_approach/CP20_stone_boundary_marker", 7.5, 0.0, -15.0, 0.0],
		["vfx/FX01_standing_wooden_torch", -6.8, -9.0, 0.0, 0.0],
		["vfx/FX01_standing_wooden_torch", 6.8, -9.0, 0.0, 0.0],
	]],
	# The market, west of the road; the shelter's open side faces the road (+x).
	[-24.0, -158.0, 90.0, [
		["buildings/B04_large_market_shelter", 0.0, 0.0, 0.0, 0.0],
		["buildings/B05_small_market_stall", -2.8, 0.6, 0.0, 0.0],
		["buildings/B05_small_market_stall", 2.8, 0.6, 0.0, 0.0],
		["market/MK06_fruit_basket", -3.4, 1.15, 0.0, 0.96],
		["market/MK07_vegetable_basket", -2.6, 1.15, 0.0, 0.96],
		["market/MK09_bread_basket", -1.95, 1.15, 0.0, 0.96],
		["market/MK15_ceramic_jugs", 2.2, 1.15, 0.0, 0.96],
		["market/MK16_wooden_bowls", 2.8, 1.15, 0.0, 0.96],
		["market/MK17_weighing_scales", 3.4, 1.1, 0.0, 0.96],
		["market/MK18_iron_weights", 3.3, 1.32, 0.0, 0.96],
		["market/MK08_grain_sacks", -0.4, 1.6, 0.0, 0.0],
		["market/MK12_fish_basket", 0.6, 2.2, 0.0, 0.0],
		["market/MK14_clay_pots", 4.6, 1.8, 0.0, 0.0],
		["market/MK13_pottery_display", 0.0, -2.6, 0.0, 0.0],
		["market/MK11_hanging_meat", -4.2, -2.4, 0.0, 0.0],
		["market/MK19_hanging_cloth_bolts", 4.0, -2.4, 0.0, 0.0],
		["market/MK21_leather_goods_display", -5.8, 1.0, 70.0, 0.0],
		["market/MK20_folded_fabric", 5.6, 0.4, 0.0, 0.0],
		["market/MK22_merchant_coin_chest", -1.4, -0.6, 0.0, 0.0],
		["market/MK23_wooden_price_sign", -1.4, 2.6, 10.0, 0.0],
		["market/MK04_merchant_table", 7.5, 3.5, -20.0, 0.0],
		["market/MK02_canvas_awning", 7.5, 3.0, -20.0, 0.0],
		["white_knights/WK08_red_ivory_market_awning", -8.5, 3.0, 15.0, 0.0],
		["market/MK04_merchant_table", -8.5, 3.4, 15.0, 0.0],
		["market/MK10_meat_hooks", -8.6, 1.4, 15.0, 0.0],
	]],
	# The civilian blacksmith, west of the market, its open side toward the road.
	[-44.0, -160.0, 90.0, [
		["buildings/B02_civilian_blacksmith_workshop", 0.0, 0.0, 0.0, 0.0],
		["blacksmith/BS03_anvil_on_stump", 0.2 * K, 0.2 * K, 15.0, 0.0],
		["blacksmith/BS14_quenching_barrel", 1.0 * K, 0.6 * K, 0.0, 0.0],
		["blacksmith/BS08_workbench", -1.6 * K, -1.4 * K, 0.0, 0.0],
		["blacksmith/BS06_hammers", -1.9 * K, -1.4 * K, 0.0, 1.15],
		["blacksmith/BS10_metal_ingots", -2.6 * K, -1.45 * K, 0.0, 1.15],
		["blacksmith/BS09_tool_rack", -1.0 * K, -2.0 * K, 0.0, 0.0],
		["blacksmith/BS12_coal_pile", 2.9 * K, -1.6 * K, 0.0, 0.0],
		["blacksmith/BS11_coal_basket", 2.4 * K, -0.4 * K, 0.0, 0.0],
		["blacksmith/BS13_firewood_stack", 3.6 * K, 1.2 * K, -90.0, 0.0],
		["blacksmith/BS19_weapon_rack", -2.3 * K, 1.6 * K, 60.0, 0.0],
		["blacksmith/BS15_water_bucket", 0.7 * K, 1.2 * K, 0.0, 0.0],
		["blacksmith/BS16_horseshoes", -0.3 * K, 1.0 * K, 0.0, 0.0],
		["blacksmith/BS17_sword_blade_blanks", -0.8 * K, -0.1 * K, 0.4, 0.0],
		["blacksmith/BS21_ash_pile", 2.2 * K, -1.2 * K, 0.0, 0.0],
		["blacksmith/BS18_iron_tools", -0.2 * K, -0.5 * K, 0.0, 0.0],
	]],
	# The inn, east of the road, its door facing the road (-x); a terrace in front.
	[26.0, -152.0, -90.0, [
		["buildings/B01_roadside_inn", 0.0, 0.0, 0.0, 0.0],
		["inn/IN04_outdoor_table", -3.2, 7.0, 10.0, 0.0],
		["inn/IN04_outdoor_table", 3.8, 7.4, -8.0, 0.0],
		["inn/IN20_tavern_notice_board", -6.2, 5.6, 20.0, 0.0],
		["inn/IN08_ale_barrels", 6.6, 5.0, -15.0, 0.0],
		["inn/IN05_dining_table", -0.5 * K, 0.6 * K, 0.0, 0.0],
		["inn/IN06_wooden_stools", -0.5 * K, 1.4 * K, 0.0, 0.0],
		["inn/IN05_dining_table", -2.6 * K, -1.4 * K, 90.0, 0.0],
		["inn/IN03_outdoor_bench", -1.9 * K, -1.4 * K, 90.0, 0.0],
		["inn/IN13_firewood_basket", -4.6 * K, 1.4 * K, 0.0, 0.0],
		["inn/IN11_cooking_pot", -3.6 * K, 1.9 * K, 0.0, 0.0],
		["inn/IN19_hanging_herbs", 1.0 * K, -2.4 * K, 0.0, 0.7],
		["inn/IN18_wall_shelves", 0.8 * K, -3.15 * K, 0.0, 0.0],
		["inn/IN09_wooden_mugs", -3.4, 7.1, 0.0, 0.78],
		["vfx/FX01_standing_wooden_torch", -7.5, 4.5, 0.0, 0.0],
	]],
	# The stable and farrier, east of the inn, open toward the road.
	[41.0, -169.0, -90.0, [
		["buildings/B03_stable_farrier_shelter", 0.0, 0.0, 0.0, 0.0],
		["stable/ST04_rectangular_hay_bales", -5.0 * K, -1.5 * K, 0.0, 0.0],
		["stable/ST05_loose_hay_piles", -4.2, 0.5, 0.0, 0.0],
		["stable/ST07_wooden_feeding_trough", 0.0, -1.4 * K, 0.0, 0.0],
		["stable/ST08_water_trough", -2.0, 5.5, 0.0, 0.0],
		["stable/ST12_hitching_post", 3.0, 6.5, 0.0, 0.0],
		["stable/ST13_horse_fence_section", -6.8, 6.5, 0.0, 0.0],
		["stable/ST14_stable_gate", -3.6, 6.5, 0.0, 0.0],
		["stable/ST15_saddle_rack", 4.2 * K, 1.2 * K, -30.0, 0.0],
		["stable/ST17_horse_blankets", -1.6 * K, 1.6 * K, 20.0, 0.0],
		["stable/ST21_manure_pile", 7.6, 1.0, 0.0, 0.0],
		["stable/ST22_manure_cart", 6.6, 4.0, -60.0, 0.0],
		["stable/ST23_wheelbarrow", 1.0, 4.4, 40.0, 0.0],
		["stable/ST25_grooming_equipment", 1.6, 3.2, 0.0, 0.0],
		["stable/ST11_feed_baskets", -0.5, 3.0, 0.0, 0.0],
	]],
	# The carpenter, south of Knight's Gap by the tithe barn lane.
	[28.0, -90.0, 0.0, [
		["buildings/B06_carpenter_workshop", 0.0, 0.0, 0.0, 0.0],
		["carpenter/CR03_sawhorse", -1.5, 4.6, 15.0, 0.0],
		["carpenter/CR07_timber_plank_pile", 3.5, 5.2, 80.0, 0.0],
		["carpenter/CR08_cut_logs", -5.6, 5.0, 70.0, 0.0],
		["carpenter/CR11_wooden_cart", 1.0, 7.6, 60.0, 0.0],
		["carpenter/CR12_cart_wheels", 5.6, 1.0, -20.0, 0.0],
		["carpenter/CR10_wood_shavings", -1.2, 4.0, 0.0, 0.0],
		["carpenter/CR16_timber_frame_section", -3.0, 8.4, 10.0, 0.0],
		["carpenter/CR13_wagon_axle", -1.0 * K, 1.6 * K, 0.0, 0.0],
		["carpenter/CR15_wooden_pegs", 1.6 * K, -1.2 * K, 0.0, 0.0],
	]],
	# A cottage with its garden, washing and hens, west of the road.
	[-28.0, -86.0, 15.0, [
		["buildings/B07_small_cottage", 0.0, 0.0, 0.0, 0.0],
		["cottages/CO06_vegetable_garden", -9.0, 3.0, 0.0, 0.0],
		["cottages/CO07_garden_fence", -9.0, 5.4, 0.0, 0.0],
		["cottages/CO07_garden_fence", -11.4, 5.4, 0.0, 0.0],
		["cottages/CO09_hanging_linen", 7.5, 5.0, -10.0, 0.0],
		["cottages/CO10_laundry_basket", 6.2, 6.0, 0.0, 0.0],
		["cottages/CO12_animal_pen", 8.0, -4.5, 0.0, 0.0],
		["cottages/CO13_chicken_coop", 8.0, -4.8, 0.0, 0.0],
		["cottages/CO15_household_tools", -4.4, 3.4, 90.0, 0.0],
		["inn/IN03_outdoor_bench", 1.0, 3.6, 0.0, 0.0],
		["environment/ENV23_stone_path_pieces", -1.3, 5.6, 0.0, 0.0],
	]],
	# The medium cottage and the storage shed.
	[-50.0, -72.0, 10.0, [
		["buildings/B08_medium_cottage", 0.0, 0.0, 0.0, 0.0],
		["blacksmith/BS13_firewood_stack", 7.5, -2.0, 90.0, 0.0],
		["cottages/CO08_clothesline", -2.0, 7.5, 0.0, 0.0],
	]],
	[-14.0, -100.0, 0.0, [
		["buildings/B09_storage_shed", 0.0, 0.0, 0.0, 0.0],
		["props/DT02_broken_crate", 3.0, 1.0, 20.0, 0.0],
		["props/DT01_abandoned_wooden_bucket", 2.4, 2.4, 0.0, 0.0],
	]],
	# A woodcutters' fire on the open ground south-west.
	[-42.0, -62.0, 0.0, [
		["vfx/FX09_campfire", 0.0, 0.0, 0.0, 0.0],
		["environment/ENV19_tree_stumps", -3.5, -2.5, 0.0, 0.0],
		["inn/IN03_outdoor_bench", -1.5, 2.6, 30.0, 0.0],
		["props/DT12_scattered_firewood", 2.6, -1.4, 0.0, 0.0],
	]],
	# What is left of a skirmish on the gap's east shoulder.
	[12.0, -126.0, 0.0, [
		["props/DT13_fallen_signboard", 0.0, 0.0, 0.0, 0.0],
		["props/DT19_old_shields", -1.8, 0.6, 0.0, 0.0],
		["props/DT20_abandoned_spear", 0.6, 1.6, 20.0, 0.0],
		["props/DT10_broken_wagon_wheel", 2.6, -0.8, 0.0, 0.0],
		["props/DT07_old_iron_chain", 1.0, 0.6, 40.0, 0.0],
		["props/DT14_stone_piles", 3.6, 1.8, 0.0, 0.0],
		["props/DT18_tattered_cloth", -2.6, -1.2, 0.0, 0.0],
	]],
]

## Flattened ground: (x, z, radius, blend).
const PADS := [
	Vector4(0, -168, 19, 6), Vector4(-24, -158, 9, 5), Vector4(-44, -160, 6, 4), Vector4(26, -152, 10, 5),
	Vector4(41, -169, 9, 5), Vector4(28, -89, 7, 5), Vector4(-28, -86, 7, 4), Vector4(-50, -72, 9, 4),
	Vector4(-14, -100, 4, 3),
]
## Trampled dirt, no grass: (x, z, radius).
const YARDS := [
	Vector3(0, -168, 16), Vector3(-22, -158, 13), Vector3(-44, -160, 8), Vector3(22, -152, 11), Vector3(40, -168, 10),
	Vector3(28, -86, 10), Vector3(-28, -84, 9), Vector3(-50, -71, 9), Vector3(-14, -100, 4), Vector3(-42, -62, 4),
]
## No trees, rocks or plants: (x, z, radius).
const KEEP := [
	Vector3(0, -168, 21), Vector3(-24, -158, 15), Vector3(-44, -160, 9), Vector3(26, -152, 13), Vector3(41, -169, 12),
	Vector3(28, -87, 12), Vector3(-28, -85, 13), Vector3(-50, -72, 12), Vector3(-14, -100, 6), Vector3(-42, -62, 6),
	Vector3(12, -126, 6), Vector3(0, -138, 9),
]
## The road through the outpost: 12 m wide from Knight's Gap to the drawbridge.
static func road() -> Dictionary:
	return {
		"points": PackedVector2Array([Vector2(0, -96), Vector2(0, -112), Vector2(0, -130), Vector2(0, -150), Vector2(0, -170), Vector2(0, -184)]),
		"width": 11.0, "shoulder": 3.0, "ditch": 0.0, "smooth": 5,
	}
## The moat in front of Highcrown's wall (beyond the north edge): from z0 to z1, half width hx, depth.
const MOAT := {"z0": -183.0, "z1": -194.0, "hx": 74.0, "depth": 3.2, "water": 1.4}
## Highcrown's backdrop: moved here from z -255; y puts its base at the ground.
const HIGHCROWN := Vector3(0, 12.8, -205)
