extends RefCounted
## The four bandits. Every one shares the same body, boots, belt and skeleton; this table says what
## each wears on top and which colours it is painted in (overrides of bandit_paint.gd STYLES).
## tools/build_bandit.gd builds one scene (BD_<name>.scn) and one texture per entry.

const OUTFITS := {
	# the swordsman: long hair, short beard, laced vest, brown cowl, one shoulder guard
	"rough": {
		"hair": "long", "beard": true, "hood": false, "mask": false, "cloak": false,
		"cowl": "full", "vest": true, "laces": true, "straps": "single",
		"pauldrons": [1.0], "forearms": {1.0: "bracer", -1.0: "wrap"}, "quiver": false,
		"patches": true, "colors": {},
	},
	# the mace man: cropped hair, bare neck, both shoulders armoured, a rust-red tunic
	"brute": {
		"hair": "crop", "beard": true, "hood": false, "mask": false, "cloak": false,
		"cowl": "none", "vest": true, "laces": true, "straps": "single",
		"pauldrons": [1.0, -1.0], "forearms": {1.0: "bracer", -1.0: "bracer"}, "quiver": false,
		"patches": true,
		"colors": {
			"tunic": Color(0.300, 0.165, 0.115), "tunic_skirt": Color(0.315, 0.172, 0.118), "sleeve": Color(0.335, 0.295, 0.235),
			"trousers": Color(0.200, 0.168, 0.125), "vest": Color(0.165, 0.120, 0.088), "pauldron": Color(0.200, 0.140, 0.095),
			"hair": Color(0.095, 0.072, 0.058), "beard": Color(0.105, 0.078, 0.060), "brow": Color(0.070, 0.050, 0.040),
		},
	},
	# the knife man: olive hood and long torn cloak, cloth mask, crossed straps with a square clasp
	"rogue": {
		"hair": "none", "beard": false, "hood": true, "mask": true, "cloak": true,
		"cowl": "ragged", "vest": false, "laces": false, "straps": "cross",
		"pauldrons": [], "forearms": {1.0: "bracer", -1.0: "bracer"}, "quiver": false,
		"patches": false,
		"colors": {
			"tunic": Color(0.225, 0.225, 0.150), "tunic_skirt": Color(0.262, 0.215, 0.132), "sleeve": Color(0.245, 0.240, 0.162),
			"trousers": Color(0.200, 0.180, 0.170), "cowl": Color(0.278, 0.178, 0.110), "hood": Color(0.292, 0.272, 0.178),
		},
	},
	# the crossbowman: green sleeves, tan skirt, dark jerkin with braces, quiver on the back
	"marksman": {
		"hair": "long", "beard": true, "hood": false, "mask": false, "cloak": false,
		"cowl": "full", "vest": true, "laces": false, "straps": "braces",
		"pauldrons": [], "forearms": {1.0: "bracer", -1.0: "bracer"}, "quiver": true,
		"patches": true,
		"colors": {
			"sleeve": Color(0.330, 0.338, 0.190), "tunic": Color(0.430, 0.335, 0.200), "tunic_skirt": Color(0.465, 0.362, 0.215),
			"trousers": Color(0.285, 0.252, 0.145), "cowl": Color(0.300, 0.180, 0.100), "hood": Color(0.272, 0.165, 0.092),
			"vest": Color(0.170, 0.112, 0.076),
		},
	},
}
