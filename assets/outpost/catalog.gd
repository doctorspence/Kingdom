extends RefCounted
## Every built asset in the outpost library: [folder, ID_name, builder Callable].
## tools/export_outpost.gd bakes each to assets/outpost/<folder>/<ID_name>.scn.
## The full planned list, with what is built and what is not, is MANIFEST.md.

const WK := preload("res://assets/outpost/white_knights/white_knights.gd")
const CP := preload("res://assets/outpost/castle_approach/castle_approach.gd")
const BLD := preload("res://assets/outpost/buildings/buildings.gd")


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
	return e
