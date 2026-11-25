extends RefCounted
## The bandits' own held gear (their swords, daggers and maces are the game's existing weapon
## models): the battered round plank shield, with a wooden or an iron rim, a rough crossbow and
## a bearded axe.
## Everything follows the game's hand convention (CharacterModel.attach_to_hand).
##  - Shield: grip at the origin, its face looks along -X (the back of the left hand).
##  - Crossbow: grip at the origin, it shoots along -Z with its top toward +Y (crossbow_hold.gd
##    turns the hands to suit).
##  - Axe (the marauders' and Hobb's): grip at the origin, haft along +Y, blade toward +X.

const Mesh_ := preload("res://assets/characters/bandit/bandit_mesh.gd")

## The shield board: its centre in the hand's frame, and its radius.
const SHIELD_CENTRE := Vector3(-0.058, 0.0, 0.085)
const SHIELD_RADIUS := 0.292
## The nose of the crossbow.
const CROSSBOW_TIP := Vector3(0.0, 0.058, -0.405)


static func crossbow(m) -> void:
	m.group = "Crossbow"
	m.density = 1.0
	var none := {}
	# the stock: a squared beam, deeper at the shoulder end
	# [z, half width, bottom, top]
	var rings := []
	for r in [[0.200, 0.026, -0.012, 0.074], [0.150, 0.028, 0.002, 0.082], [0.060, 0.020, 0.030, 0.078], [-0.100, 0.024, 0.030, 0.078],
			[-0.300, 0.022, 0.036, 0.076], [-0.388, 0.026, 0.034, 0.078]]:
		rings.append([Vector3(r[1], r[2], r[0]), Vector3(r[1], r[3], r[0]), Vector3(-r[1], r[3], r[0]), Vector3(-r[1], r[2], r[0])])
	m.loft("timber", rings, none, {"cap_start": true, "cap_end": true})
	# hand grip and trigger
	m.box("grip", Vector3(0, -0.006, 0.012), Vector3(0.028, 0.092, 0.034), none, Basis(Vector3.RIGHT, -0.22))
	m.bar("iron", Vector3(0, 0.030, -0.036), Vector3(0, -0.018, -0.052), 0.008, 0.008, Vector3.BACK, none)
	m.bar("iron", Vector3(0, -0.018, -0.052), Vector3(0, -0.046, -0.010), 0.008, 0.006, Vector3.DOWN, none)
	# the bow: two limbs swept back from an iron bridle at the nose
	for s in [1.0, -1.0]:
		var pts := [Vector3(0.0, 0.052, -0.350), Vector3(0.095 * s, 0.052, -0.358), Vector3(0.190 * s, 0.054, -0.326), Vector3(0.268 * s, 0.056, -0.255)]
		var size := [0.019, 0.017, 0.013, 0.009]
		var limb := []
		for i in 4:
			var along: Vector3 = (pts[mini(i + 1, 3)] - pts[maxi(i - 1, 0)]).normalized()
			var side := along.cross(Vector3.UP).normalized()
			limb.append(Mesh_.ring(pts[i], side, Vector3.UP, size[i], size[i] * 1.15, 4, 2.0, PI / 4.0))
		m.loft("timber", limb, none, {"cap_end": true})
		m.box("iron", pts[3], Vector3(0.022, 0.026, 0.022), none)
		# the drawn string
		m.bar("string", pts[3] + Vector3(0, 0.006, 0), Vector3(0.006 * s, 0.086, -0.092), 0.006, 0.005, Vector3.UP, none)
	m.box("iron", Vector3(0, 0.056, -0.352), Vector3(0.066, 0.058, 0.036), none)
	m.box("iron", Vector3(0, 0.082, -0.092), Vector3(0.030, 0.014, 0.022), none)
	# the stirrup at the nose
	for s in [1.0, -1.0]:
		m.bar("iron", Vector3(0.020 * s, 0.054, -0.380), Vector3(0.050 * s, 0.054, -0.455), 0.012, 0.012, Vector3.UP, none)
	m.bar("iron", Vector3(0.056, 0.054, -0.455), Vector3(-0.056, 0.054, -0.455), 0.012, 0.012, Vector3.UP, none)
	# a bolt in the groove
	m.bar("arrow_shaft", Vector3(0, 0.090, -0.095), Vector3(0, 0.090, -0.385), 0.011, 0.011, Vector3.UP, none)
	var tip := Vector3(0, 0.090, -0.430)
	for q in [[Vector3(0.016, 0.090, -0.385), Vector3(0, 0.102, -0.385)], [Vector3(0, 0.102, -0.385), Vector3(-0.016, 0.090, -0.385)],
			[Vector3(-0.016, 0.090, -0.385), Vector3(0, 0.080, -0.385)], [Vector3(0, 0.080, -0.385), Vector3(0.016, 0.090, -0.385)]]:
		m.poly("iron", [q[0], tip, q[1]], none, Vector3(0, 0.090, -0.390))
	for s in [1.0, -1.0]:
		m.poly("fletch", [Vector3(0, 0.094, -0.100), Vector3(0.020 * s, 0.100, -0.092), Vector3(0.018 * s, 0.098, -0.140), Vector3(0, 0.094, -0.150)], none, Vector3(0, 0.05, -0.12))


## A heavy bearded axe. The haft runs along +Y from the grip, the blade faces +X.
static func axe(m) -> void:
	m.group = "Axe"
	m.density = 1.0
	var none := {}
	# the haft, thicker toward the butt, with a wrapped grip
	var haft := []
	for r in [[-0.270, 0.032], [-0.220, 0.027], [0.300, 0.025], [0.820, 0.024], [1.055, 0.027]]:
		haft.append(Mesh_.ring(Vector3(0, r[0], 0), Vector3.RIGHT, Vector3.BACK, r[1], r[1] * 0.86, 7))
	m.loft("haft", haft, none, {"cap_start": true, "cap_end": true})
	for part in [["grip", -0.095, 0.150, 0.031], ["iron", -0.285, -0.245, 0.037], ["iron", 0.760, 0.785, 0.031]]:
		var band := []
		for y: float in [part[1], part[2]]:
			band.append(Mesh_.ring(Vector3(0, y, 0), Vector3.RIGHT, Vector3.BACK, part[3], part[3] * 0.88, 7))
		m.loft(part[0], band, none, {"cap_start": true, "cap_end": true})
	# the head: iron cheeks widening into the blade. [x, top, bottom, half thickness]
	var cols := [[-0.040, 0.995, 0.855, 0.034], [0.044, 0.990, 0.858, 0.032], [0.140, 1.004, 0.862, 0.016], [0.248, 1.048, 0.758, 0.010]]
	var rings := []
	for c in cols:
		rings.append([Vector3(c[0], c[2], c[3]), Vector3(c[0], c[1], c[3]), Vector3(c[0], c[1], -c[3]), Vector3(c[0], c[2], -c[3])])
	m.loft("iron", rings, none, {"cap_start": true})
	# the ground edge, curved and bright
	var back_line := []
	for i in 5:
		back_line.append(Vector2(0.248, lerpf(1.048, 0.758, i / 4.0)))
	var edge := [Vector2(0.292, 1.072), Vector2(0.332, 0.992), Vector2(0.342, 0.900), Vector2(0.322, 0.806), Vector2(0.268, 0.724)]
	for i in 4:
		for s in [1.0, -1.0]:
			m.poly("axe_edge", [Vector3(back_line[i].x, back_line[i].y, 0.010 * s), Vector3(edge[i].x, edge[i].y, 0.001 * s),
					Vector3(edge[i + 1].x, edge[i + 1].y, 0.001 * s), Vector3(back_line[i + 1].x, back_line[i + 1].y, 0.010 * s)],
					none, Vector3(0.26, 0.9, 0.0))
	# close the two horns of the blade
	for k in [[0, 0], [4, 4]]:
		var b: Vector2 = back_line[k[0]]
		var e: Vector2 = edge[k[1]]
		m.poly("axe_edge", [Vector3(b.x, b.y, 0.010), Vector3(e.x, e.y, 0.0), Vector3(b.x, b.y, -0.010)], none, Vector3(0.26, 0.9, 0.0))
	# a short spike behind
	var point := Vector3(-0.138, 0.925, 0.0)
	var base := [Vector3(-0.038, 0.965, 0.022), Vector3(-0.038, 0.965, -0.022), Vector3(-0.038, 0.885, -0.022), Vector3(-0.038, 0.885, 0.022)]
	for i in 4:
		m.poly("iron", [base[i], base[(i + 1) % 4], point], none, Vector3(-0.05, 0.925, 0.0))
	# the haft shows through the top of the socket, wedged
	m.box("metal", Vector3(0, 1.058, 0), Vector3(0.014, 0.012, 0.034), none)


static func shield(m, iron := false) -> void:
	m.group = "ShieldIron" if iron else "Shield"
	var rim_style := "iron_rim" if iron else "wood_rim"
	m.density = 1.0
	var none := {}
	var c := SHIELD_CENTRE
	var r := SHIELD_RADIUS
	var n := 14
	# the rim is a little uneven: chipped and re-cut over the years
	var chips := [1.0, 0.995, 1.0, 0.975, 1.0, 1.005, 0.99, 1.0, 0.96, 1.0, 0.995, 1.0, 0.985, 1.0]
	var disc := func(x: float, radius: float, uneven := false) -> Array:
		var out := []
		for i in n:
			var a := TAU * i / n
			var k: float = radius * (chips[i] if uneven else 1.0)
			out.append(c + Vector3(x, cos(a) * k, sin(a) * k))
		return out
	var inside := c + Vector3(0.0, 0, 0)
	# face: slightly domed planks
	var face_outer: Array = disc.call(-0.012, r - 0.034)
	var face_mid: Array = disc.call(-0.024, r * 0.55)
	m.loft("wood", [face_outer, face_mid], none, {"inside": inside, "cap_end": false})
	m.poly("wood", face_mid, none, inside)
	# back
	m.poly("wood_back", disc.call(0.014, r - 0.034), none, inside)
	# thick rim
	var rim := [disc.call(-0.012, r - 0.040), disc.call(-0.030, r - 0.034), disc.call(-0.028, r - 0.002, true),
			disc.call(0.016, r, true), disc.call(0.026, r - 0.030), disc.call(0.012, r - 0.040)]
	for k in rim.size() - 1:
		for i in n:
			var j := (i + 1) % n
			var a0 := TAU * (i + 0.5) / n
			var core := c + Vector3(-0.004, cos(a0) * (r - 0.022), sin(a0) * (r - 0.022))
			m.poly(rim_style, [rim[k][i], rim[k][j], rim[k + 1][j], rim[k + 1][i]], none, core)
	# iron boss: a flange and a faceted dome, with rivets
	var flange: Array = []
	var shoulder: Array = []
	var top: Array = []
	for i in 8:
		var a := TAU * i / 8.0
		flange.append(c + Vector3(-0.026, cos(a) * 0.088, sin(a) * 0.088))
		shoulder.append(c + Vector3(-0.048, cos(a) * 0.066, sin(a) * 0.066))
		top.append(c + Vector3(-0.078, cos(a) * 0.036, sin(a) * 0.036))
	m.loft("iron", [flange, shoulder, top], none, {"inside": inside})
	for i in 8:
		m.poly("iron", [top[i], top[(i + 1) % 8], c + Vector3(-0.092, 0, 0)], none, inside)
	var rivets := 12 if iron else 6
	for i in rivets:
		var a := TAU * i / rivets + 0.26
		m.box("iron", c + Vector3(-0.026, cos(a) * (r - 0.062), sin(a) * (r - 0.062)), Vector3(0.016, 0.020, 0.020), none, Basis(Vector3.RIGHT, a))
	# the hand grip and arm strap on the back
	m.box("grip", Vector3(-0.012, 0.0, 0.0), Vector3(0.028, 0.150, 0.030), none)
	for s in [1.0, -1.0]:
		m.box("grip", Vector3(-0.030, 0.072 * s, 0.0), Vector3(0.030, 0.022, 0.038), none)
	m.box("grip", c + Vector3(0.026, 0.0, 0.080), Vector3(0.012, 0.230, 0.042), none)
