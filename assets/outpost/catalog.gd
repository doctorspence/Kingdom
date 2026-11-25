extends RefCounted
## Every built asset in the outpost library: [folder, ID_name, builder Callable].
## tools/export_outpost.gd bakes each to assets/outpost/<folder>/<ID_name>.scn.
## The full planned list, with what is built and what is not, is MANIFEST.md.

const WK := preload("res://assets/outpost/white_knights/white_knights.gd")


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
	return e
