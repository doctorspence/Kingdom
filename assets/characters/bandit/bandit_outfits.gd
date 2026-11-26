extends RefCounted
## Every bandit. They all share the same body, boots, belt and skeleton; this table says what
## each wears on top and which colours it is painted in (overrides of bandit_paint.gd STYLES).
## Optional extras: "fur" (shoulder mantle), "noose", "helm", "pauldron_style".
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
	# the marauder, the raiders outside the Gullet: rust red under a shaggy fur mantle
	"marauder": {
		"hair": "crop", "beard": true, "hood": false, "mask": false, "cloak": false,
		"cowl": "none", "vest": true, "laces": true, "straps": "single", "fur": true,
		"pauldrons": [1.0], "forearms": {1.0: "bracer", -1.0: "wrap"}, "quiver": false,
		"patches": true,
		"colors": {
			"tunic": Color(0.340, 0.120, 0.080), "tunic_skirt": Color(0.360, 0.128, 0.082), "sleeve": Color(0.250, 0.185, 0.130),
			"trousers": Color(0.165, 0.130, 0.100), "vest": Color(0.150, 0.095, 0.065), "pauldron": Color(0.185, 0.120, 0.080),
			"hair": Color(0.120, 0.070, 0.045), "beard": Color(0.150, 0.085, 0.050), "brow": Color(0.080, 0.048, 0.032),
		},
	},
	# the other marauder look, so a pair doesn't match: long dark hair, crossed straps, darker fur
	"marauder_b": {
		"hair": "long", "beard": true, "hood": false, "mask": false, "cloak": false,
		"cowl": "none", "vest": false, "laces": false, "straps": "cross", "fur": true,
		"pauldrons": [-1.0], "forearms": {1.0: "bracer", -1.0: "bracer"}, "quiver": false,
		"patches": true,
		"colors": {
			"tunic": Color(0.245, 0.088, 0.065), "tunic_skirt": Color(0.230, 0.150, 0.095), "sleeve": Color(0.300, 0.115, 0.080),
			"trousers": Color(0.215, 0.185, 0.135), "fur": Color(0.185, 0.140, 0.105),
			"hair": Color(0.075, 0.058, 0.048), "beard": Color(0.085, 0.064, 0.050), "brow": Color(0.055, 0.040, 0.032),
		},
	},
	# the Bandit Captain: iron cap and shoulder plates, fur, a long dark plum cloak
	"captain": {
		"hair": "none", "beard": true, "hood": false, "mask": false, "cloak": true, "helm": true,
		"cowl": "none", "vest": true, "laces": false, "straps": "braces", "fur": true,
		"pauldrons": [1.0, -1.0], "pauldron_style": "plate", "forearms": {1.0: "bracer", -1.0: "bracer"}, "quiver": false,
		"patches": false,
		"colors": {
			"tunic": Color(0.215, 0.165, 0.220), "tunic_skirt": Color(0.235, 0.178, 0.240), "sleeve": Color(0.205, 0.190, 0.185),
			"trousers": Color(0.150, 0.135, 0.140), "vest": Color(0.130, 0.095, 0.078), "cloak": Color(0.175, 0.105, 0.170),
			"fur": Color(0.340, 0.310, 0.270),
		},
	},
	# Rook the Cutthroat: blood red from the ragged neckcloth to the torn cloak
	"rook": {
		"hair": "crop", "beard": false, "hood": false, "mask": false, "cloak": true,
		"cowl": "ragged", "vest": false, "laces": false, "straps": "cross",
		"pauldrons": [1.0], "forearms": {1.0: "bracer", -1.0: "bracer"}, "quiver": false,
		"patches": false,
		"colors": {
			"tunic": Color(0.360, 0.085, 0.065), "tunic_skirt": Color(0.300, 0.075, 0.060), "sleeve": Color(0.175, 0.135, 0.125),
			"trousers": Color(0.135, 0.112, 0.108), "cowl": Color(0.450, 0.115, 0.070), "cloak": Color(0.300, 0.065, 0.055),
			"pauldron": Color(0.135, 0.090, 0.072),
			"hair": Color(0.060, 0.045, 0.040), "brow": Color(0.050, 0.036, 0.030),
		},
	},
	# Hobb the Unhanged: bald, grizzled, and he kept the rope
	"hobb": {
		"hair": "none", "beard": true, "hood": false, "mask": false, "cloak": false,
		"cowl": "none", "vest": true, "laces": true, "straps": "single", "noose": true,
		"pauldrons": [1.0, -1.0], "forearms": {1.0: "wrap", -1.0: "wrap"}, "quiver": false,
		"patches": true,
		"colors": {
			"tunic": Color(0.335, 0.265, 0.170), "tunic_skirt": Color(0.300, 0.232, 0.148), "sleeve": Color(0.385, 0.350, 0.275),
			"trousers": Color(0.175, 0.150, 0.120), "vest": Color(0.120, 0.090, 0.068), "pauldron": Color(0.160, 0.118, 0.088),
			"beard": Color(0.420, 0.400, 0.370), "brow": Color(0.300, 0.280, 0.255),
		},
	},
	# Harl the Delver, the boss: a mail shirt under a torn miner's coat (harl_parts.gd adds the
	# coat, helmet, shoulder plate and black stone). A boss, so more detail than the others.
	"harl": {
		"hair": "nape", "beard": true, "hood": false, "mask": false, "cloak": false,
		"cowl": "none", "vest": false, "laces": false, "straps": "single",
		"pauldrons": [], "forearms": {}, "quiver": false, "patches": false,
		"harl": true, "atlas": 1024,
		"tunic_style": "mail", "skirt_style": "mail_skirt", "sleeves": [], "belt_margin": 0.034, "pouch": false,
		"colors": {
			"trousers": Color(0.125, 0.112, 0.100), "boot": Color(0.190, 0.135, 0.085), "boot_cuff": Color(0.215, 0.155, 0.098),
			"boot_foot": Color(0.180, 0.128, 0.080), "strap": Color(0.175, 0.112, 0.066), "belt": Color(0.200, 0.122, 0.070),
			"hair": Color(0.115, 0.095, 0.084), "beard": Color(0.135, 0.112, 0.098), "brow": Color(0.080, 0.064, 0.055), "plate": Color(0.160, 0.146, 0.136),
		},
	},
}
