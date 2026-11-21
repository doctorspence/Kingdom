extends RefCounted
## The Tithelands' land, as designed in ZONE1_OVERHAUL.md section 5.
## Meters, x = east, z = south (north is -z). The river's water is about 5.6 m
## high at the bridge; the village stands on a gentle rise to the south, the
## quarry scarp walls the west, Knight's Gap pinches the road in the north,
## Watchtower Crag and the East Woods fill the east.
##
## Read by SculptedTerrain (see game/world/sculpted_terrain.gd), which bakes
## it into the ground mesh. Change numbers here, then reload the scene.

var noise: FastNoiseLite

# ---- the river: points west to east; each point has a half width, a depth,
# a water level and how wide its banks slope (small = steep gorge banks).
var river := {
	"points": PackedVector2Array([
		Vector2(-186, -44), Vector2(-150, -34), Vector2(-122, -14), Vector2(-104, -6),   # mill pond above the weir
		Vector2(-95.5, -6.6), Vector2(-92.5, -7.4),                                  # the weir: a short drop (Mill Lane crosses here)
		Vector2(-84, -10), Vector2(-66, -16), Vector2(-42, -4), Vector2(-20, 6),
		Vector2(0, 2),                                                              # the broken bridge
		Vector2(20, -8), Vector2(40, -14),                                          # the ford: wide and shallow
		Vector2(62, -8), Vector2(84, 6), Vector2(106, 2), Vector2(128, -8),         # into the gorge under the crag
		Vector2(152, -4), Vector2(186, 8)]),
	"half_widths": PackedFloat32Array([5.0, 5.0, 5.5, 6.5, 6.0, 5.5, 5.0, 5.0, 5.0, 5.0, 5.0, 6.0, 8.5, 5.5, 5.0, 4.0, 3.8, 4.5, 5.0]),
	"depths": PackedFloat32Array([1.3, 1.3, 1.2, 1.1, 0.6, 0.5, 0.9, 1.2, 1.3, 1.2, 1.1, 0.9, 0.45, 1.1, 1.3, 1.6, 1.7, 1.5, 1.4]),
	"levels": PackedFloat32Array([6.9, 6.85, 6.8, 6.75, 6.72, 6.0, 5.92, 5.85, 5.75, 5.65, 5.6, 5.5, 5.4, 5.3, 5.2, 5.0, 4.7, 4.4, 4.2]),
	"banks": PackedFloat32Array([5.0, 5.0, 5.0, 4.0, 4.0, 4.0, 4.0, 5.0, 6.0, 6.0, 5.0, 6.0, 9.0, 5.0, 4.0, 2.5, 2.0, 3.0, 5.0]),
}

# ---- roads: control points (curved through), width, shoulder (how far the
# ground blends back to the land), ditch depth (main road only).
var roads := [
	{  # The Tithe Road: south edge, the village green, down to the broken bridge, the tithe barn, Knight's Gap, north to Highcrown.
		"points": PackedVector2Array([Vector2(3, 200), Vector2(4, 176), Vector2(2, 152), Vector2(-1, 132), Vector2(0, 114),
			Vector2(4, 96), Vector2(9, 76), Vector2(7, 54), Vector2(0, 34), Vector2(-3, 16), Vector2(0, 2), Vector2(2, -12),
			Vector2(7, -30), Vector2(8, -50), Vector2(3, -72), Vector2(-2, -92), Vector2(0, -110), Vector2(1, -128),
			Vector2(-2, -150), Vector2(0, -172), Vector2(0, -200)]),
		"width": 5.5, "shoulder": 4.0, "ditch": 0.22, "smooth": 7,
	},
	{  # Mill Lane: the green, the two farmsteads, the burned hamlet's street, the mill, across the weir, up to the quarry.
		"points": PackedVector2Array([Vector2(-2, 112), Vector2(-16, 108), Vector2(-30, 104), Vector2(-44, 100), Vector2(-56, 92),
			Vector2(-64, 80), Vector2(-70, 66), Vector2(-76, 52), Vector2(-82, 38), Vector2(-86, 24), Vector2(-88, 10),
			Vector2(-90, -6), Vector2(-94, -20), Vector2(-100, -34), Vector2(-110, -52), Vector2(-118, -70), Vector2(-124, -86),
			Vector2(-132, -98), Vector2(-144, -100)]),
		"width": 4.0, "shoulder": 3.0, "ditch": 0.0, "smooth": 5,
	},
	{  # East Lane: the green, the camp hearth, the woods edge, up to the watchtower's south gate.
		"points": PackedVector2Array([Vector2(2, 114), Vector2(14, 114), Vector2(28, 118), Vector2(40, 118), Vector2(54, 110),
			Vector2(66, 98), Vector2(76, 84), Vector2(86, 70), Vector2(96, 58), Vector2(103, 49), Vector2(105, 44)]),
		"width": 4.0, "shoulder": 3.0, "ditch": 0.0, "smooth": 5,
	},
]

# ---- narrow tracks (painted, they follow the ground).
var tracks := [
	{"points": PackedVector2Array([Vector2(-86, 8), Vector2(-66, -2), Vector2(-44, 8), Vector2(-22, 16), Vector2(-6, 14)])},       # towpath, mill to bridge
	{"points": PackedVector2Array([Vector2(6, 12), Vector2(24, 4), Vector2(38, -4), Vector2(42, -16), Vector2(44, -26),
		Vector2(56, -40), Vector2(72, -48), Vector2(90, -58), Vector2(108, -72), Vector2(118, -80)])},                             # over the ford to the raiders
	{"points": PackedVector2Array([Vector2(-80, 42), Vector2(-92, 38), Vector2(-102, 34), Vector2(-108, 32)])},                    # to Hobb's hollow
	{"points": PackedVector2Array([Vector2(60, 104), Vector2(58, 80), Vector2(60, 56), Vector2(63, 38), Vector2(71, 25),
		Vector2(82, 15), Vector2(94, 10), Vector2(104, 11)])},                                                                       # the long way up the crag
	{"points": PackedVector2Array([Vector2(-150, -78), Vector2(-157, -56), Vector2(-160, -30), Vector2(-158, -4), Vector2(-152, 16)])}, # cliff-top path to the overlook
	{"points": PackedVector2Array([Vector2(8, -50), Vector2(16, -50)])},                                                           # into the tithe yard
]

# ---- cuts: the quarry floor carved into the scarp, a bench along its north
# wall, and a cart ramp up to the bench.
var cuts := [
	{"center": Vector2(-150, -100), "half": Vector2(21, 16), "floor": 12.0, "edge": 1.6, "mode": "carve", "rock": 0.55, "rough": 3.0},
	{"center": Vector2(-155, -113.5), "half": Vector2(15, 3.4), "floor": 18.0, "edge": 0.8, "mode": "fill", "rock": 0.7},
	{"center": Vector2(-135, -114), "half": Vector2(6.5, 2.6), "floor": 18.0, "floor_end": 12.2, "edge": 1.0, "mode": "fill", "rock": 0.5},
]

# ---- fields: ploughed strips (ridge and furrow) and pasture, each walled in
# dry stone with a gate gap on edge number `gate`. `dir` is the way the furrows run.
var fields := [
	{"poly": PackedVector2Array([Vector2(-16, 130), Vector2(-32, 128), Vector2(-40, 150), Vector2(-18, 154)]), "kind": "plough", "dir": 80.0, "gate": 0},
	{"poly": PackedVector2Array([Vector2(12, 134), Vector2(34, 136), Vector2(36, 156), Vector2(14, 158)]), "kind": "pasture", "dir": 0.0, "gate": 3},
	{"poly": PackedVector2Array([Vector2(-46, 128), Vector2(-66, 112), Vector2(-78, 120), Vector2(-60, 140)]), "kind": "plough", "dir": 40.0, "gate": 0},
	{"poly": PackedVector2Array([Vector2(-24, 52), Vector2(-50, 56), Vector2(-54, 40), Vector2(-26, 36)]), "kind": "plough", "dir": 10.0, "gate": 0},
	{"poly": PackedVector2Array([Vector2(-30, -30), Vector2(-8, -26), Vector2(-10, -58), Vector2(-34, -62)]), "kind": "pasture", "dir": 0.0, "gate": 1},
]

# ---- dry-stone walls along the roads, and the tithe barn's walled yard.
var walls := [
	{"points": PackedVector2Array([Vector2(-4.5, 124), Vector2(-5, 140), Vector2(-6, 160)]), "height": 1.1, "piers": 12.0},
	{"points": PackedVector2Array([Vector2(5, 126), Vector2(6, 140), Vector2(7, 160)]), "height": 1.1, "piers": 12.0},
	{"points": PackedVector2Array([Vector2(12, -36), Vector2(38, -36), Vector2(38, -64), Vector2(12, -64), Vector2(12, -36)]), "height": 1.6, "piers": 13.0},
]

# ---- level spots: (x, z, radius, blend). Camps, the crag summit, the checkpoint
# yard, the village green, and the two reserved sites.
var flats := PackedVector4Array([
	Vector4(-4, 111, 13, 6),      # village green
	Vector4(105, 26, 19, 5),      # Watchtower Crag summit
	Vector4(0, -108, 17, 6),      # Knights' checkpoint yard in the gap
	Vector4(-112, 32, 9, 3),      # Hobb's hollow floor
	Vector4(29, -33, 7, 4),       # ford camp
	Vector4(122, -84, 13, 5),     # raiders' farmstead
	Vector4(94, 86, 6, 4),        # woods camp south
	Vector4(64, -55, 6, 4),       # woods camp middle
	Vector4(102, -51, 6, 4),      # woods camp north
	Vector4(40, 127, 7, 4),       # the camp hearth's yard
	Vector4(-152, 16, 5, 3),      # the overlook on the cliff top
	Vector4(-48, 160, 11, 12),    # RESERVED: ruined chapel (not built yet)
	Vector4(150, -140, 9, 12),    # RESERVED: old barrow (not built yet)
])

# ---- trampled dirt: (x, z, radius).
var clearings := PackedVector3Array([
	Vector3(-112, 32, 12), Vector3(29, -33, 9), Vector3(122, -84, 15), Vector3(94, 86, 8), Vector3(64, -55, 8),
	Vector3(102, -51, 8), Vector3(0, -108, 14), Vector3(12, -50, 8), Vector3(-92, 8, 7), Vector3(40, 127, 8),
	Vector3(105, 26, 13), Vector3(-46, 90, 6), Vector3(-36, 114, 5), Vector3(-150, -98, 14),
])

# Places kept clear of trees and rocks: (x, z, radius).
var keep_clear := PackedVector3Array([
	Vector3(-48, 160, 14), Vector3(150, -140, 12), Vector3(-152, 16, 7), Vector3(-4, 111, 18),
	Vector3(105, 26, 21), Vector3(0, -108, 19), Vector3(122, -84, 16), Vector3(-112, 32, 14),
	Vector3(-150, -100, 24), Vector3(29, -33, 10), Vector3(40, 127, 10),
	Vector3(94, 86, 10), Vector3(64, -55, 10), Vector3(102, -51, 10), Vector3(15, 64, 4),
])


func setup(n: FastNoiseLite) -> void:
	noise = n


## Where the valley floor runs: the river's z at a given x.
func river_z(x: float) -> float:
	var p: PackedVector2Array = river.points
	if x <= p[0].x:
		return p[0].y
	for i in p.size() - 1:
		if x <= p[i + 1].x:
			var t := (x - p[i].x) / (p[i + 1].x - p[i].x)
			return lerpf(p[i].y, p[i + 1].y, smoothstep(0.0, 1.0, t))
	return p[p.size() - 1].y


## The west scarp's cliff line (x) at a given z.
func scarp_x(z: float) -> float:
	return -140.0 + 6.0 * sin(z * 0.045) + 4.0 * sin(z * 0.11 + 1.0) + noise.get_noise_2d(17.0, z * 3.0) * 2.5


func _g(x: float, z: float, cx: float, cz: float, r: float) -> float:
	var dx := (x - cx) / r
	var dz := (z - cz) / r
	return exp(-(dx * dx + dz * dz) * 2.0)


## The land before roads and the river are cut in.
func natural(x: float, z: float) -> float:
	var dz := z - river_z(x)
	var d := absf(dz)
	var h := 7.0
	if dz > 0.0:
		h += 0.04 * d + 3.0 * (1.0 - exp(-d / 28.0))      # south: gentle rise to the village
	else:
		h += 0.035 * d + 2.6 * (1.0 - exp(-d / 28.0))     # north: to the tithe barn and the gap
	# Rolling ground, calmer near the river.
	var calm := smoothstep(6.0, 30.0, d)
	h += noise.get_noise_2d(x, z) * 1.8 * calm
	h += noise.get_noise_2d(x * 3.1 + 500.0, z * 3.1) * 0.45 * calm
	# South ridge (the woods and the reserved chapel), with a saddle for the road.
	var ridge_s := 8.0 * exp(-pow((z - 162.0) / 16.0, 2.0))
	ridge_s *= 1.0 - 0.65 * exp(-pow((x - 4.0) / 22.0, 2.0))
	h += ridge_s + maxf(0.0, z - 180.0) * 0.12
	# Knight's Gap: a ridge across the north with a notch for the road, and a hill either side.
	var fade := 1.0 - smoothstep(110.0, 150.0, absf(x))
	var ridge_n := 8.0 * exp(-pow((z + 120.0) / 17.0, 2.0)) * fade
	ridge_n *= 1.0 - 0.8 * exp(-pow(x / 20.0, 2.0))
	h += ridge_n
	h += 7.0 * _g(x, z, -44.0, -124.0, 26.0) + 8.0 * _g(x, z, 46.0, -118.0, 28.0)
	# Beyond the gap the land falls toward the fens under Highcrown.
	h -= maxf(0.0, -135.0 - z) * 0.06 * (1.0 - smoothstep(60.0, 140.0, absf(x)))
	# The west scarp: a cliff band, highest in the north, softening into a wooded slope in the south.
	var sx := scarp_x(z)
	var cliff := 1.0 - smoothstep(sx - 4.0, sx + 3.0, x)
	var tall := lerpf(13.5, 4.0, smoothstep(40.0, 120.0, z))
	h += tall * cliff + maxf(0.0, sx - x) * 0.05
	# Watchtower Crag: a flat-topped knoll, steep on the river (north) side.
	var cx := (x - 105.0) / (44.0 if x < 105.0 else 34.0)
	var cz := (z - 26.0) / (28.0 if z < 26.0 else 40.0)
	var q := sqrt(cx * cx + cz * cz) + noise.get_noise_2d(x * 5.0 + 900.0, z * 5.0) * 0.12
	h += 13.0 * (1.0 - smoothstep(0.55, 1.0, q))
	# Hobb's hollow: a sunken bowl by the river.
	var hd := Vector2(x + 112.0, z - 32.0).length() / 16.0
	h -= 3.5 * (1.0 - smoothstep(0.5, 1.0, hd))
	# The East Woods climb to a ridge at the east edge.
	h += 7.0 * smoothstep(125.0, 190.0, x)
	# Beyond the playable square: hills close the horizon (but not across the north road,
	# where Highcrown stands, nor where the river leaves).
	var out := maxf(absf(x), absf(z)) - 182.0
	if out > 0.0:
		var open_north := exp(-pow(x / 70.0, 2.0)) * (1.0 if z < 0.0 else 0.0)
		h += (10.0 * smoothstep(0.0, 90.0, out) + 0.05 * out) * (1.0 - open_north) + noise.get_noise_2d(x * 0.7, z * 0.7) * 4.0 * smoothstep(0.0, 40.0, out)
	return h


## How thick the forest is (0..1) at a point.
func forest(x: float, z: float) -> float:
	var f := 0.02
	# East Woods, with a wavy edge.
	var edge_e := 58.0 + 12.0 * sin(z * 0.03) + 6.0 * sin(z * 0.11)
	f = maxf(f, 0.85 * smoothstep(edge_e - 6.0, edge_e + 10.0, x))
	# South ridge woods.
	var edge_s := 148.0 + 6.0 * sin(x * 0.04)
	f = maxf(f, 0.7 * smoothstep(edge_s - 4.0, edge_s + 10.0, z))
	# On top of the scarp.
	f = maxf(f, 0.6 * (1.0 - smoothstep(scarp_x(z) - 16.0, scarp_x(z) - 6.0, x)))
	# The hills either side of Knight's Gap.
	f = maxf(f, 0.85 * smoothstep(0.25, 0.6, _g(x, z, -44.0, -124.0, 34.0)))
	f = maxf(f, 0.85 * smoothstep(0.25, 0.6, _g(x, z, 46.0, -118.0, 36.0)))
	# Along the river: a thin line of trees, thicker downstream.
	var dr := absf(z - river_z(x))
	f = maxf(f, (0.28 + 0.2 * smoothstep(0.0, 120.0, x)) * (smoothstep(7.0, 10.0, dr) - smoothstep(13.0, 20.0, dr)))
	# Thin the woods around the camps' approaches a little.
	return f


## Fallen boulders: under the scarp, around the crag, along the gorge, a few elsewhere.
func rocks(x: float, z: float) -> float:
	var r := 0.02
	var sx := scarp_x(z)
	r = maxf(r, 0.5 * (smoothstep(sx - 1.0, sx + 3.0, x) - smoothstep(sx + 8.0, sx + 14.0, x)) * (1.0 - smoothstep(30.0, 90.0, z)))
	var cq := Vector2((x - 105.0) / 30.0, (z - 26.0) / 28.0).length()
	r = maxf(r, 0.45 * (smoothstep(0.8, 1.0, cq) - smoothstep(1.1, 1.4, cq)))
	if x > 95.0:
		var dr := absf(z - river_z(x))
		r = maxf(r, 0.4 * (smoothstep(4.0, 6.0, dr) - smoothstep(9.0, 12.0, dr)))
	return r


## Ground clutter (stones, fallen logs, stumps): woods and woods edges mostly.
func clutter(x: float, z: float) -> float:
	return 0.08 + 0.5 * forest(x, z)


## Bushes: along woods edges, scattered in the woods, a few in the open.
func undergrowth(x: float, z: float) -> float:
	var f := forest(x, z)
	var edge := smoothstep(0.1, 0.4, f) * (1.0 - smoothstep(0.6, 0.85, f))
	return 0.03 + 0.25 * f + 0.45 * edge


## Ferns: the shade under the trees.
func ferns(x: float, z: float) -> float:
	return 0.7 * smoothstep(0.3, 0.75, forest(x, z))


## Nettles and weeds: everywhere a little, thicker at woods edges and by the river.
func weeds(x: float, z: float) -> float:
	var dr := absf(z - river_z(x))
	var bank := smoothstep(5.0, 8.0, dr) - smoothstep(10.0, 16.0, dr)
	return 0.12 + 0.3 * undergrowth(x, z) + 0.35 * bank


## Rock faces on steep ground (the scatter keeps only the steep spots).
func cliffs(_x: float, _z: float) -> float:
	return 0.55


## Fallen wood: in the woods.
func deadwood(x: float, z: float) -> float:
	return 0.04 + 0.35 * forest(x, z)
