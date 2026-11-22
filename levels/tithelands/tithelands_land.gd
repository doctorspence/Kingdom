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
	{"points": PackedVector2Array([Vector2(-45, 131), Vector2(-44, 138), Vector2(-45, 145), Vector2(-47, 151), Vector2(-49, 156)])},           # the sunken lane up to the chapel
]

# ---- cuts: the quarry floor carved into the scarp, a bench along its north
# wall, and a cart ramp up to the bench.
var cuts := [
	{"center": Vector2(-150, -100), "half": Vector2(21, 16), "floor": 12.0, "edge": 1.6, "mode": "carve", "rock": 0.55, "rough": 3.0},
	{"center": Vector2(-155, -113.5), "half": Vector2(15, 3.4), "floor": 18.0, "edge": 0.8, "mode": "fill", "rock": 0.7},
	{"center": Vector2(-135, -114), "half": Vector2(6.5, 2.6), "floor": 18.0, "floor_end": 12.2, "edge": 1.0, "mode": "fill", "rock": 0.5},
	# The mill race (cut after the pads; the walls come with the mill model, see building_landmarks.gd):
	# the wheel pit, the sluice stub to the pond, and the tailrace down to the river below the weir.
	{"center": Vector2(-104, -1.3), "half": Vector2(3.4, 1.0), "floor": 6.3, "edge": 0.25, "mode": "carve", "rock": 0.8, "late": true},
	{"center": Vector2(-106, -3.0), "half": Vector2(0.8, 0.7), "floor": 6.3, "edge": 0.25, "mode": "carve", "rock": 0.8, "late": true},
	{"center": Vector2(-98.2, -1.3), "half": Vector2(2.8, 1.0), "floor": 5.85, "edge": 0.25, "mode": "carve", "rock": 0.8, "late": true},
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
	Vector4(-48, 160, 11, 12),    # ruined chapel (built: props/chapel.tscn)
	Vector4(150, -140, 9, 12),    # old barrow (built: props/barrow.tscn)
])

# ---- trampled dirt: (x, z, radius).
var clearings := PackedVector3Array([
	Vector3(-112, 32, 12), Vector3(29, -33, 9), Vector3(122, -84, 15), Vector3(94, 86, 8), Vector3(64, -55, 8),
	Vector3(102, -51, 8), Vector3(0, -108, 14), Vector3(12, -50, 8), Vector3(-92, 8, 7), Vector3(40, 127, 8),
	Vector3(105, 26, 13), Vector3(-46, 90, 6), Vector3(-36, 114, 5), Vector3(-150, -98, 14),
])

# Places kept clear of trees and rocks: (x, z, radius).
var keep_clear := PackedVector3Array([
	Vector3(-49, 160, 15), Vector3(150, -140, 17), Vector3(-152, 16, 7), Vector3(-4, 111, 18),
	Vector3(105, 26, 21), Vector3(0, -108, 19), Vector3(122, -84, 16), Vector3(-112, 32, 14),
	Vector3(-150, -100, 24), Vector3(29, -33, 10), Vector3(40, 127, 10),
	Vector3(94, 86, 11), Vector3(64, -55, 11), Vector3(102, -49, 14), Vector3(15, 64, 4),
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


# ---- the brook in the East Woods (west end joins the river) and the chapel's sunken lane.
var brook := PackedVector2Array([Vector2(186, 74), Vector2(171, 66), Vector2(159, 58), Vector2(149, 46),
	Vector2(142, 32), Vector2(135, 18), Vector2(129, 6), Vector2(126, -5)])
var holloway := PackedVector2Array([Vector2(-45, 131), Vector2(-44, 138), Vector2(-45, 145), Vector2(-47, 151), Vector2(-49, 156)])


## (distance to a polyline, position along it 0..1).
func _line_dist(p: Vector2, pts: PackedVector2Array) -> Vector2:
	var best := INF
	var best_t := 0.0
	var total := 0.0
	var lens := PackedFloat32Array()
	for i in pts.size() - 1:
		lens.append(pts[i].distance_to(pts[i + 1]))
		total += lens[i]
	var run := 0.0
	for i in pts.size() - 1:
		var a := pts[i]
		var ab := pts[i + 1] - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		var dd := p.distance_to(a + ab * t)
		if dd < best:
			best = dd
			best_t = (run + lens[i] * t) / maxf(total, 0.001)
		run += lens[i]
	return Vector2(best, best_t)


## The west scarp's cliff line (x) at a given z.
func scarp_x(z: float) -> float:
	var base := -140.0 + 6.0 * sin(z * 0.045) + 4.0 * sin(z * 0.11 + 1.0) + noise.get_noise_2d(17.0, z * 3.0) * 2.5
	# Two combes: small wooded valleys bitten back into the scarp (north of the quarry, south of the overlook).
	return base - 10.0 * exp(-pow((z + 152.0) / 8.0, 2.0)) - 9.0 * exp(-pow((z - 46.0) / 7.0, 2.0))


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
	var tall := lerpf(13.5, 4.0, smoothstep(40.0, 120.0, z))
	# Limestone steps: an upper face, a ledge 2 to 4 m wide, a lower face; a ragged, broken
	# brow; and a scree apron of fallen rock at the foot.
	var u := x - sx - noise.get_noise_2d(19.0, z * 4.0) * 1.4
	var lw := 3.0 + 1.0 * noise.get_noise_2d(23.0, z * 1.5)
	var split := 0.5 + 0.12 * noise.get_noise_2d(29.0, z * 2.0)
	var upper := 1.0 - smoothstep(-4.5, -2.5, u)
	var lower := 1.0 - smoothstep(lw - 2.5, lw, u)
	h += tall * (split * upper + (1.0 - split) * lower) + maxf(0.0, sx - x) * 0.05
	var foot := lw
	h += tall * 0.11 * (smoothstep(foot - 1.0, foot + 0.5, u) - smoothstep(foot + 1.0, foot + 9.0, u)) * (0.75 + 0.5 * absf(noise.get_noise_2d(x * 6.0, z * 6.0))) * smoothstep(38.0, 50.0, Vector2(x, z).distance_to(Vector2(-150, -100)))
	# Watchtower Crag: a flat-topped knoll, steep on the river (north) side.
	var cx := (x - 105.0) / (44.0 if x < 105.0 else 34.0)
	var cz := (z - 26.0) / (28.0 if z < 26.0 else 40.0)
	var q := sqrt(cx * cx + cz * cz) + noise.get_noise_2d(x * 5.0 + 900.0, z * 5.0) * 0.12
	var cs := 1.0 - smoothstep(0.55, 1.0, q)
	# Its north-east face over the river breaks into rock terraces (layered outcrops).
	var steps := floorf(cs * 4.0) / 4.0 + smoothstep(0.72, 1.0, fposmod(cs * 4.0, 1.0)) / 4.0
	cs = lerpf(cs, steps, 0.85 * smoothstep(106.0, 114.0, x) * (1.0 - smoothstep(14.0, 24.0, z)))
	h += 13.0 * cs
	# Hobb's hollow: a sunken bowl by the river.
	var hd := Vector2(x + 112.0, z - 32.0).length() / 16.0
	h -= 3.5 * (1.0 - smoothstep(0.5, 1.0, hd))
	# The East Woods climb to a ridge at the east edge.
	h += 7.0 * smoothstep(125.0, 190.0, x)
	# ...over rolling ground with dells where the mist will lie.
	var ew := smoothstep(60.0, 95.0, x)
	# ...but the barrow, the raiders' farmstead and the woods camps keep their ground.
	for site: Vector2 in [Vector2(150, -140), Vector2(122, -84), Vector2(102, -49), Vector2(64, -55), Vector2(94, 86)]:
		ew *= smoothstep(14.0, 30.0, Vector2(x, z).distance_to(site))
	h += ew * (noise.get_noise_2d(x * 1.6 + 300.0, z * 1.6) * 2.4 + noise.get_noise_2d(x * 4.0, z * 4.0 + 90.0) * 0.5)
	h -= 2.6 * _g(x, z, 148.0, 42.0, 24.0) + 2.0 * _g(x, z, 152.0, -36.0, 26.0) + 1.6 * _g(x, z, 82.0, 62.0, 18.0)
	# Knight's Gap: limestone knobs break out on the hill shoulders (not on the road).
	for hc: Vector2 in [Vector2(-44.0, -124.0), Vector2(46.0, -118.0)]:
		var hdist := Vector2(x, z).distance_to(hc)
		var knob := maxf(0.0, (1.0 - absf(noise.get_noise_2d(x * 3.5 + 700.0, z * 3.5))) - 0.72) / 0.28
		h += 3.2 * knob * (1.0 - smoothstep(14.0, 28.0, hdist)) * smoothstep(14.0, 22.0, absf(x))
	# The brook: a stony channel from the east ridge down past the crag into the river.
	var bd := _line_dist(Vector2(x, z), brook)
	h -= 1.0 * (1.0 - smoothstep(0.9, 4.5, bd.x))
	# The sunken lane to the chapel, worn deep into the ridge (deepest halfway up).
	var hl := _line_dist(Vector2(x, z), holloway)
	h -= 1.6 * sin(PI * clampf(hl.y, 0.0, 1.0)) * (1.0 - smoothstep(1.3, 5.0, hl.x))
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


## Extra ground data for the terrain shader: (leaf litter under the broadleaf
## canopy 0..1, sandstone share of the rock 0..1; the rest is limestone).
func ground_extra(x: float, z: float) -> Vector2:
	var f := forest(x, z)
	var litter := smoothstep(0.2, 0.65, f) * (0.75 + 0.25 * noise.get_noise_2d(x * 2.0 + 40.0, z * 2.0))
	# Warm sandstone: low down in the south of the scarp, the crag's skirt, the gorge banks.
	var sand := 0.0
	sand = maxf(sand, smoothstep(10.0, 60.0, z) * (1.0 - smoothstep(scarp_x(z) + 2.0, scarp_x(z) + 14.0, x)))
	var cq := Vector2((x - 105.0) / 40.0, (z - 26.0) / 36.0).length()
	sand = maxf(sand, 0.55 * (smoothstep(0.5, 0.8, cq) - smoothstep(1.1, 1.5, cq)))
	if x > 85.0:
		sand = maxf(sand, 0.6 * (1.0 - smoothstep(8.0, 16.0, absf(z - river_z(x)))))
	sand *= 0.7 + 0.3 * noise.get_noise_2d(x * 1.3, z * 1.3 + 200.0)
	return Vector2(clampf(litter, 0.0, 1.0), clampf(sand, 0.0, 1.0))


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


# ---- The Greenwood's trees (see GREENWOOD_OVERHAUL.md 7.1) ---------------------------

## Woodland density for the Woods scatter (the old forest map, all broadleaf now).
func woodland(x: float, z: float) -> float:
	return forest(x, z) * smoothstep(2.5, 4.5, _line_dist(Vector2(x, z), brook).x)


## Lone trees in the open: hedgerow and field oaks, ash by the water.
func lone_trees(x: float, z: float) -> float:
	var open := 1.0 - smoothstep(0.08, 0.3, forest(x, z))
	var dr := absf(z - river_z(x))
	return open * (0.012 + 0.03 * (smoothstep(7.0, 10.0, dr) - smoothstep(14.0, 22.0, dr)))


## Which species stands here. roll is 0..1 (seeded per spot). Target shares over
## the zone: oak ~50%, beech ~20%, ash ~12%, birch ~10%, yew ~8% (brief section 4).
func tree_kind(x: float, z: float, roll: float) -> String:
	var f := forest(x, z)
	var dr := absf(z - river_z(x))
	var p := Vector2(x, z)
	# Ominous places: churchyard, barrow, quarry brow, a dark pocket deep in the East Woods.
	var yew := 0.0
	yew = maxf(yew, 0.9 * (1.0 - smoothstep(18.0, 34.0, p.distance_to(Vector2(-50, 160)))))
	yew = maxf(yew, 0.9 * (1.0 - smoothstep(18.0, 34.0, p.distance_to(Vector2(150, -140)))))
	yew = maxf(yew, 0.5 * (1.0 - smoothstep(20.0, 40.0, p.distance_to(Vector2(-168, -100)))))
	yew = maxf(yew, 0.8 * (1.0 - smoothstep(12.0, 26.0, p.distance_to(Vector2(146, 40)))))
	yew = maxf(yew, 0.35 * (1.0 - smoothstep(10.0, 22.0, p.distance_to(Vector2(-44, -128)))))
	# Yews love limestone: scattered along the scarp top, and a few in the deep woods.
	yew = maxf(yew, 0.3 * (1.0 - smoothstep(scarp_x(z) - 14.0, scarp_x(z) - 3.0, x)))
	yew = maxf(yew, 0.07 * smoothstep(0.6, 0.85, f))
	# Birch: disturbed ground and edges: the quarry, the burned hamlet, scree, wood edges.
	var birch := 0.13 + 0.25 * (smoothstep(0.08, 0.25, f) - smoothstep(0.35, 0.6, f))
	birch = maxf(birch, 0.65 * (1.0 - smoothstep(25.0, 55.0, p.distance_to(Vector2(-145, -98)))))
	birch = maxf(birch, 0.5 * (1.0 - smoothstep(20.0, 40.0, p.distance_to(Vector2(-74, 58)))))
	var sx := scarp_x(z)
	birch = maxf(birch, 0.35 * (smoothstep(sx - 2.0, sx + 2.0, x) - smoothstep(sx + 10.0, sx + 18.0, x)))
	# Beech: the enclosed interiors of the deep woods.
	var beech := 0.32 * smoothstep(0.55, 0.8, f) + 0.25 * smoothstep(90.0, 130.0, x) * smoothstep(0.5, 0.8, f)
	# Ash: damp ground by the water, and the airy edges.
	var ash := 0.18 + 0.3 * (1.0 - smoothstep(12.0, 30.0, dr)) + 0.1 * (1.0 - smoothstep(0.3, 0.6, f))
	var dead := 0.04 + 0.08 * (1.0 - smoothstep(30.0, 50.0, p.distance_to(Vector2(105, 26))))
	var oak := 1.0
	var total := yew + birch + beech + ash + dead + oak
	var r := roll * total
	for pair: Array in [["yew", yew], ["birch", birch], ["beech", beech], ["ash", ash], ["oak_dead", dead]]:
		if r < pair[1]:
			return pair[0]
		r -= pair[1]
	return "oak"


## Hand-placed landmark trees: [kind, x, z, yaw degrees, scale, variant].
var landmark_trees := [
	["oak_ancient", -10.0, 103.0, 20.0, 1.0, 0],   # the great oak on the village green
	["oak_ancient", 49.0, 101.0, 140.0, 0.9, 1],   # the hollow oak at the East Lane bend
	["oak_ancient", -44.0, -136.0, 250.0, 0.95, 2],  # on the shoulder of Knight's Gap
	["oak_dead", 126.0, 44.0, 70.0, 1.35, 0],      # the stag-headed oak below the watchtower
	["yew", -66.0, 160.0, 30.0, 1.15, 3],          # churchyard yews
	["yew", -50.0, 177.0, 200.0, 1.0, 0],
	["yew", -34.0, 168.0, 110.0, 0.9, 2],
	["yew", 133.0, -153.0, 10.0, 1.1, 3],          # yews by the barrow
	["yew", 168.0, -126.0, 150.0, 1.0, 1],
	["yew", 160.0, -158.0, 260.0, 0.9, 0],
]

## Enemy spawn points (EnemySpawns in the scene): no trees or rocks on top of a fight.
const SPAWN_CLEAR := [
	Vector2(5, 32), Vector2(0, -110), Vector2(8, -116), Vector2(13, -46), Vector2(8, -28), Vector2(-40, 92),
	Vector2(-72, 60), Vector2(-74, 44), Vector2(-90, 58), Vector2(-92, 6), Vector2(-112, 30), Vector2(-118, 39),
	Vector2(93, 85), Vector2(65, -54), Vector2(101, -50), Vector2(120, -81), Vector2(129, -85), Vector2(113, -90),
	Vector2(99, 30), Vector2(105, 47), Vector2(-152, -72), Vector2(-148, -98), Vector2(-163, -106), Vector2(10, 14),
	Vector2(6, 46), Vector2(-52, 96), Vector2(28, -32), Vector2(6, -62), Vector2(-84, 30), Vector2(-116, -62),
	Vector2(60, 88), Vector2(-30, 88),
]


func _init() -> void:
	for s: Vector2 in SPAWN_CLEAR:
		keep_clear.append(Vector3(s.x, s.y, 5.0))
	keep_clear.append(Vector3(-166.5, -98.0, 7.0))  # the Gullet door
	keep_clear.append(Vector3(-150.0, -86.0, 4.0))  # the quarry ladder
	for lt: Array in landmark_trees:
		keep_clear.append(Vector3(lt[1], lt[2], 6.0 if String(lt[0]).begins_with("oak_anc") else 3.5))


## How much of the woods here is fir rather than broadleaf (0..1).
func conifer_share(x: float, z: float) -> float:
	var c := 0.45
	c = maxf(c, 0.9 * (1.0 - smoothstep(scarp_x(z) - 14.0, scarp_x(z) - 4.0, x)))  # on the scarp
	c = maxf(c, 0.85 * smoothstep(0.2, 0.5, _g(x, z, -44.0, -124.0, 34.0) + _g(x, z, 46.0, -118.0, 36.0)))  # gap hills
	c = maxf(c, 0.7 * smoothstep(150.0, 170.0, z))  # the south ridge crest
	var dr := absf(z - river_z(x))
	c *= 0.35 + 0.65 * smoothstep(8.0, 30.0, dr)  # alders and willows by the water
	return clampf(c, 0.0, 1.0)


func conifers(x: float, z: float) -> float:
	return forest(x, z) * conifer_share(x, z)


## Broadleaf trees: the rest of the woods, plus lone trees in the fields and hedgerows.
func broadleaf(x: float, z: float) -> float:
	return forest(x, z) * (1.0 - conifer_share(x, z)) + 0.012
