"""The three zones: terrain recipe plus everything drawn on the maps.

Each zone returns a dict:
  H, X, Z      heights (absolute m) on a 1 m grid
  size         side of the square zone (m)
  offset_z     where the zone centre sits on the world's z axis (zone 1 = 0)
  rivers       [(name, [(x, z), ...], width_m)]  drawn as water, flowing first -> last
  lakes        [(name, mask)]                     standing water
  falls        [(x, z, drop_m, name)]
  paths        [(kind, [(x, z), ...])]            road / track / stair / route / shortcut
  walls        [[(x, z), ...]]                    city and fort walls
  blocks       [(x, z, w, d)]                     building footprints (city texture)
  areas        [(num, name, x, z)]                numbered area labels
  pois         [(kind, x, z, label)]              shrine, dungeon, boss, rare, camp_dark, camp_white,
                                                  camp_outcast, exit, gate, bridge, vista, secret, door
  regions      [(kind, mask)]                     fen, bog, ash, snow, scree, pale, heather (map tint)
"""
import numpy as np
from terrain import (grid, fbm, gauss, smoothstep, carve_channel, flatten_path,
                     polyline_info, terrace, mask_poly, soft_mask, path_length)


# ====================================================================== ZONE 1
def zone1():
    """The Tithelands, rebuilt from levels/tithelands/tithelands.tscn and zone_terrain.gd."""
    size = 364.0
    X, Z = grid(size)
    hh = 5.0
    n = fbm(X, Z, 0.006, 3, seed=7)
    H = n * hh + hh * 1.3 + fbm(X * 3.1 + 500, Z * 3.1, 0.006, 3, seed=8) * hh * 0.25
    half = size / 2
    d_edge = np.minimum(half - np.abs(X), half - np.abs(Z))
    t = 1 - np.clip(d_edge / 28.0, 0, 1)
    H += 26.0 * t * t
    mounds = [(105, 28, 31.5, 11), (-133, -115.5, 38.5, -9), (-129.5, -112, 15.4, -5), (56, -119, 35, 5)]
    for mx, mz, r, h in mounds:
        d = np.hypot(X - mx, Z - mz) / r
        if h >= 0:
            H += h * np.exp(-d * d * 2)
        else:
            s = 0.9
            H += h * (1 - smoothstep(0.8 - 0.25 / s, 0.8 + 0.25 / s, d))
    roads = [
        [(0, 161), (0, 84), (1.4, 0), (0, -84), (0, -182)],
        [(0, 112), (-42, 91), (-70, 42), (-80.5, -14)],
        [(-80.5, -14), (-105, -63), (-115.5, -80.5)],
        [(7, 126), (42, 112), (77, 70), (98, 38.5)],
    ]
    smooth = fbm(X * 0.3, Z * 0.3, 0.006, 3, seed=7) * hh * 0.3 + hh * 1.3
    for r in roads:
        d, _ = polyline_info(X, Z, r)
        t2 = smoothstep(3.0, 9.6, d)
        H = smooth * (1 - t2) + H * t2
    river = [(-182, -21), (-105, -10.5), (-42, -5.6), (0, -3.5), (56, 3.5), (119, -7), (182, 10.5)]
    wl = hh * 1.3 - 0.9
    d, _ = polyline_info(X, Z, river)
    t3 = 1 - smoothstep(9 * 0.35, 9 * 1.5, d)
    H = H * (1 - t3) + (wl - 1.1) * t3

    tracks = [
        [(-76, 18), (-88, 23), (-99, 22)],
        [(3, -10), (14, -13), (24, -13)],
        [(77, 68), (86, 40), (80, 12), (74, -8), (80, -28), (87, -42), (100, -60), (114, -76), (120, -80)],
    ]
    paths = [("road", r) for r in roads] + [("track", t) for t in tracks]
    # Critical path: Crossroads -> north road -> checkpoint -> Highcrown gate.
    paths.append(("route", [(5, 116), (0, 84), (1, 0), (0, -84), (0, -180)]))

    woods = soft_mask(((X > 45) & (X < 170) & (Z > -150) & (Z < 120)) & (np.hypot(X - 105, Z - 28) > 30), 8)
    pois = [
        ("shrine", 6.3, 114.8, "Crossroads Shrine"),
        ("shrine", -75.6, -28.0, "Mill Shrine"),
        ("shrine", -103.6, -77.0, "Quarry Shrine"),
        ("camp_outcast", 36, 122, "Camp Hearth (yours)"),
        ("dungeon", -112, -84, "The Gullet"),
        ("rare", -105.7, 21, "Hobb the Unhanged (5%)"),
        ("camp_dark", 120.4, -81.2, "Raider camp"),
        ("camp_dark", 78.5, -9.5, "Woods camps"),
        ("camp_outcast", 28, -12.6, "Ford camp"),
        ("camp_white", 0, -84, "Knights' checkpoint"),
        ("bridge", 0, -3.5, "Broken bridge"),
        ("secret", 105, 43, "Tower gate shortcut"),
        ("exit", 0, -176, "To Highcrown (Zone 2)"),
    ]
    areas = [
        (1, "Crossroads", 6, 128), (2, "Farms", -30, 96), (3, "Burned Hamlet", -60, 58),
        (4, "The Mill", -88, -18), (5, "Hobb's Camp", -106, 30), (6, "The Quarry", -128, -112),
        (7, "Tithe River", -140, -26), (8, "East Woods", 82, 92), (9, "Watchtower Hill", 142, 58),
        (10, "Tithe Barn", 26, -62), (11, "Checkpoint", -32, -100), (12, "North Road", 14, -140),
    ]
    blocks = [(-21, 98, 7, 6), (-35, 88.2, 7, 6), (-56, 63, 6, 5), (-65.8, 54.6, 6, 5), (-51.8, 49, 6, 5),
              (-70, 68.6, 7, 6), (25.2, -61.6, 14, 9), (-87.5, -19.6, 9, 8), (105, 28, 6, 6)]
    walls = [[(90, 28), (94.4, 17.4), (105, 13), (115.6, 17.4), (120, 28), (115.6, 38.6), (105, 43), (94.4, 38.6), (90, 28)]]
    return dict(key="zone1", name="Zone 1 — The Tithelands", size=size, offset_z=0.0, X=X, Z=Z, H=H,
                rivers=[("Tithe River", river, 9)], lakes=[], falls=[], paths=paths, walls=walls,
                blocks=blocks, areas=areas, pois=pois, regions=[("woods", woods)],
                contour=2.0, index=10.0, levels="1 – 6", tagline="Low farm valley under Highcrown. Mud, rain, tithe barns.")


# ====================================================================== ZONE 2
# Local coordinates; the zone's south edge (z = +210) meets the Tithelands' north edge.
Z2_CROWN_WATER = [  # (x, z, bed elevation), flowing south from the upland to the fen
    (40, -210, 101), (38, -160, 99.5), (40, -122, 98),      # across the upland to the lip of the Veil
    (41, -112, 58), (43, -88, 56),                            # the Veil: a 40 m fall into the Crownpool
    (52, -58, 54.5), (57, -34, 53.5), (59, -27, 41),          # Upper Falls (12 m)
    (63, 10, 39.5), (65, 40, 38), (66, 47, 29),               # Middle Falls (9 m)
    (69, 80, 27), (71, 108, 25.5), (72, 114, 17),             # Lower Falls (8 m)
    (75, 138, 12), (95, 158, 5), (140, 166, 3.6), (210, 152, 3.0),  # Sluice, then out through the Lees
]
Z2_PALE_RUNNEL = [  # Bleachery runoff, west side, to the Pale Pools
    (-78, 52, 33), (-92, 80, 24), (-104, 112, 13), (-118, 145, 7), (-140, 172, 4), (-168, 190, 3.2),
]


def zone2():
    size = 420.0
    X, Z = grid(size)
    noise = fbm(X, Z, 0.012, 4, seed=21)
    big = fbm(X, Z, 0.004, 3, seed=22)

    # Lowland south of the walls: the Lees (fen) east and Mudside's gravel bank west.
    r01 = np.clip((150 - Z) / 220, 0, 1) ** 1.1
    H = 5.0 + r01 * 44 + big * (2.0 + 9 * r01) + noise * (0.8 + 2.5 * r01)   # foothills climb toward the scarp
    H += gauss(X, Z, -110, 165, 34, 3.5)                   # Mudside bank
    H += gauss(X, Z, 0, 190, 40, 2.5)                      # causeway rise at the zone edge

    # The scarp: an old fault. Upland in the north at 100-112 m, a cliff 25-45 m high.
    zs = -112 + 14 * np.sin(X / 70.0) + 8 * np.sin(X / 23.0 + 1.0)   # foot of the cliff
    upland = 101 + np.clip(-(Z + 120), 0, None) * 0.06 + noise * 2.5 + big * 3
    foot = 54 + big * 3 + noise * 1.5                                   # ground under the cliff
    cliff = smoothstep(zs + 4, zs - 9, Z)
    north = foot * (1 - cliff) + upland * cliff
    north_w = smoothstep(-25, -75, Z)                                   # behind the city the land is already high
    H = H * (1 - north_w) + np.maximum(H, north) * north_w

    # The Crown spur: the granite tongue the city stands on, rising from the gate to the crag.
    spur_c = np.clip((140 - Z) / 185.0, 0, 1)
    spur_h = 14 + spur_c ** 1.15 * 56                      # 14 m at the gate -> 70 m at the crag
    spur_w = 88 + 16 * np.clip((Z - 40) / 100, -1, 1) + big * 14
    spur_m = smoothstep(spur_w + 34, spur_w - 4, np.abs(X - 4 - 0.12 * (Z - 60))) * smoothstep(176, 128, Z)
    H = np.maximum(H, H * (1 - spur_m) + (spur_h + noise * 1.2) * spur_m)
    H += gauss(X, Z, 4, -46, 22, 6)                        # Crown Crag, cathedral rock
    # Saddle behind the crag joins the spur to the cliff foot.
    H = np.maximum(H, (56 + noise * 2) * smoothstep(-40, -62, Z) * (1 - smoothstep(60, 120, np.abs(X))))

    # Hill of Tabards: a ridge west of the city running up to the scarp.
    d_r, s_r = polyline_info(X, Z, [(-150, 70), (-135, 10), (-118, -50), (-105, -100), (-94, -128)])
    ridge_h = np.interp(s_r, [0, 62, 124, 176, 206], [36, 52, 70, 88, 100])
    H = np.maximum(H, ridge_h * np.exp(-(d_r / 30) ** 2) + noise * 1.5 + 4 * (1 - np.exp(-(d_r / 30) ** 2)))

    # The Cutting: Highcrown's old quarry, benches cut into the east flank of the scarp.
    cut_m = soft_mask(mask_poly(X, Z, [(105, 20), (175, 10), (185, -95), (150, -135), (110, -110), (100, -40)]), 5)
    cut_h = 30 + np.clip((20 - Z) / 140, 0, 1) * 70
    H = H * (1 - cut_m) + terrace(cut_h + noise * 0.5, 8, 0.18) * cut_m

    # City streets are terraced (6 m treads).
    city_poly = [(-95, 140), (95, 140), (98, -18), (40, -62), (-35, -62), (-98, -18)]
    city = mask_poly(X, Z, city_poly)
    city_s = soft_mask(city, 3)
    H = H * (1 - city_s) + terrace(H, 6.0, 0.22) * city_s

    # Charnel Pits east of the gorge (lime pits for the Cleansing's dead).
    for cx, cz in [(128, 72), (142, 82), (136, 96)]:
        H -= 3.5 * (1 - smoothstep(4, 7, np.hypot(X - cx, Z - cz)))

    # Water: the Crown Water gorge (deep), the Pale Runnel (shallow).
    H, bed, d_cw = carve_channel(H, X, Z, Z2_CROWN_WATER, 4.0, 13.0, sharp=0.55)
    H, bed2, d_pr = carve_channel(H, X, Z, Z2_PALE_RUNNEL, 2.0, 7.0)
    # Crownpool under the Veil.
    pool = np.hypot(X - 42, Z - 95 + 0) < 0  # placeholder replaced below
    pool = np.hypot(X - 43, Z + 94) < 13
    H = np.where(pool, np.minimum(H, 55.0), H)
    pale_pools = (np.hypot(X + 165, Z - 188) < 16) | (np.hypot(X + 146, Z - 176) < 9)
    H = np.where(pale_pools, np.minimum(H, 2.4), H)

    # Roads and stairs.
    road_main = [(0, 210), (0, 175), (0, 141)]
    street = [(0, 138), (-6, 110), (4, 80), (-2, 50), (0, 30), (6, 5), (2, -20), (4, -36)]
    pilgrim = [(-40, -30), (-70, -28), (-100, -40), (-118, -55), (-114, -80), (-106, -100), (-96, -112),
               (-84, -120), (-94, -130), (-78, -140), (-66, -158), (-50, -182), (-40, -208)]
    cutting_route = [(112, 60), (128, 30), (140, -10), (160, -50), (150, -100), (125, -126), (100, -150)]
    upland_track = [(-40, -208), (-20, -180), (20, -165), (39, -150)]
    mudside_track = [(0, 170), (-40, 172), (-80, 166), (-112, 168)]
    lees_track = [(4, 150), (40, 150), (74, 142)]
    for r, w in [(road_main, 3.5), (street, 3.0)]:
        H = flatten_path(H, X, Z, r, w, 5)

    paths = [("road", road_main), ("street", street), ("stair", pilgrim), ("stair", cutting_route),
             ("track", upland_track), ("track", mudside_track), ("track", lees_track),
             ("track", [(-6, 100), (-40, 92), (-70, 70)]),      # Lower Town to the Bleachery
             ("track", [(40, 60), (64, 60), (92, 64), (112, 60)]),   # Kingsbridge east
             ("shortcut", [(-2, 120), (0, 141)]),               # Penitents' Gate, opened from inside
             ("shortcut", [(30, -52), (40, -86)]),              # cathedral postern down to the Crownpool
             ("route", [(0, 208), (0, 178), (-40, 172), (-96, 166), (-60, 152), (40, 150), (74, 140),
                        (72, 112), (68, 82), (60, 60), (30, 62), (-6, 100), (-2, 50), (0, 30), (6, 5),
                        (2, -20), (-40, -30), (-70, -28), (-100, -40), (-118, -55), (-114, -80), (-106, -100),
                        (-96, -112), (-84, -120), (-94, -130), (-78, -140), (-66, -158), (-50, -182), (-40, -206)])]

    walls = [
        [(-95, 140), (-6, 140)], [(6, 140), (95, 140), (98, -18), (40, -62)],   # gate gap at x=0
        [(-35, -62), (-98, -18), (-95, 140)],
        [(-70, 30), (-6, 30)], [(6, 30), (90, 30)],                              # Rule Wall (inner)
        [(-35, -62), (40, -62)],
    ]
    rng = np.random.default_rng(5)
    blocks = []
    for bz in np.arange(132, -55, -9.5):
        for bx in np.arange(-88, 92, 9.0):
            jx, jz = bx + rng.uniform(-1.5, 1.5), bz + rng.uniform(-1.5, 1.5)
            if not mask_poly(np.array([[jx]]), np.array([[jz]]), city_poly)[0, 0]:
                continue
            if abs(jx) < 7 or np.min(np.hypot(*(np.array([(p[0], p[1]) for p in Z2_CROWN_WATER]) - (jx, jz)).T)) < 13:
                continue
            if np.hypot(jx - 4, jz + 46) < 20 or abs(jz - 30) < 5 or np.hypot(jx, jz - 120) < 13:
                continue
            if np.hypot(jx + 76, jz - 58) < 16:  # bleachery vats drawn separately
                continue
            if rng.random() < 0.82:
                blocks.append((jx, jz, rng.uniform(5, 8), rng.uniform(5, 7.5)))
    # Big buildings
    blocks += [(4, -46, 16, 30), (4, -64, 10, 8),             # cathedral + chapter house
               (-30, 10, 22, 10), (34, 12, 16, 12),             # barracks, Hall of Rules
               (-76, 58, 14, 10), (-66, 66, 8, 8)]              # bleachery sheds
    shanty = [(-118 + rng.uniform(-25, 25), 168 + rng.uniform(-16, 14), rng.uniform(3, 5), rng.uniform(3, 4.5)) for _ in range(34)]
    blocks += shanty

    fen = soft_mask((H < 5.6) & (Z > 120) & (X > -60), 3)
    pale = soft_mask(((d_pr < 9) | pale_pools) & (Z > 40), 3)
    scarp_face = soft_mask(np.abs(Z - zs) < 8, 2) * (1 - city_s)

    pois = [
        ("shrine", -105, 172, "Mudside Shrine"),
        ("shrine", -26, 96, "The Walled Shrine"),
        ("shrine", 18, 2, "Bellfoot Shrine"),
        ("dungeon", 4, -34, "The Reliquary (dungeon)"),
        ("rare", -138, 30, "Sir Gaspard (5%)"),
        ("camp_white", 0, 128, "Tithe Square"),
        ("camp_white", -30, 18, "Knights' barracks"),
        ("camp_outcast", -118, 160, "Mudside"),
        ("gate", 0, 141, "Penitents' Gate (barred)"),
        ("gate", 75, 139, "The Sluice"),
        ("gate", 0, 30, "Rule Gate"),
        ("bridge", 62, 62, "Kingsbridge"),
        ("bridge", 58, -10, "Rope walk"),
        ("gate", -86, -27, "West Postern"),
        ("secret", 120, -128, "Hermit's ledge"),
        ("exit", 0, 206, "To the Tithelands (Zone 1)"),
        ("exit", -40, -207, "Weathergate: to the Barrow Fells (Zone 3)"),
    ]
    falls = [(41, -116, 40, "The Veil"), (58, -30, 12, "Upper Falls"), (65.5, 44, 9, "Middle Falls"),
             (71.5, 111, 8, "Lower Falls")]
    areas = [
        (1, "Tithe Causeway", -50, 196), (2, "Mudside", -138, 150), (3, "The Lees", 150, 186),
        (4, "The Sluice & Culverts", 128, 116), (5, "Crown Gorge", 108, 84), (6, "Lower Town", -46, 118),
        (7, "The Bleachery", -76, 76), (8, "Charnel Pits", 150, 70), (9, "Upper Ward", -50, 4),
        (10, "Crown Crag", -34, -48), (11, "Hill of Tabards", -170, -20), (12, "Pilgrim Stair", -160, -112),
        (13, "The Cutting", 158, -40), (14, "Crownpool & the Veil", 78, -96), (15, "The Upland", 60, -180),
    ]
    rivers = [("Crown Water (upland)", [(p[0], p[1]) for p in Z2_CROWN_WATER[:3]], 5),
              ("Crown Water", [(p[0], p[1]) for p in Z2_CROWN_WATER[3:]], 6),
              ("Pale Runnel", [(p[0], p[1]) for p in Z2_PALE_RUNNEL], 3)]
    lakes = [("Crownpool", pool), ("Pale Pools", pale_pools)]
    return dict(key="zone2", name="Zone 2 — Highcrown", size=size, offset_z=-392.0, X=X, Z=Z, H=H,
                rivers=rivers, lakes=lakes, falls=falls, paths=paths, walls=walls, blocks=blocks,
                areas=areas, pois=pois, regions=[("fen", fen), ("pale", pale), ("cliff", scarp_face)],
                contour=5.0, index=25.0, levels="6 – 11  (Reliquary 9 – 12)",
                tagline="The White Knights' city on a granite spur, climbing to the cathedral crag and the scarp.")


# ====================================================================== ZONE 3
Z3_CROWN_WATER = [  # from Greymere Tarn south to the scarp lip (zone 2's Veil)
    (-112, -56, 144.6), (-108, -46, 143.8),                                                   # outlet through the lip
    (-105, -40, 129),                                                                         # Tarnspill falls
    (-100, -14, 122), (-92, 6, 118.5), (-84, 22, 117.4),
    (-74, 40, 116.2), (-58, 52, 115), (-40, 64, 113.8), (-26, 82, 112.4), (-8, 96, 110.6), (8, 112, 108.5),
    (26, 130, 104.6), (36, 150, 102.6), (48, 172, 102.3), (40, 200, 101.8), (42, 222, 101.3), (40, 240, 101),
]
Z3_RIVE = [(-40, -12), (-5, -38), (40, -55), (90, -64), (130, -74), (172, -95), (210, -112), (240, -118)]


def zone3():
    size = 480.0
    X, Z = grid(size)
    noise = fbm(X, Z, 0.011, 5, seed=31)
    big = fbm(X, Z, 0.0035, 4, seed=32)

    # High moor: 104 m at the scarp edge, rising gently north, rolling.
    H = 104 + np.clip(240 - Z, 0, None) * 0.045 + big * 14 + noise * 3.5
    for hx, hz, r, h in [(-20, 40, 40, 7), (60, 110, 30, -3), (-60, 200, 30, 4), (170, 140, 45, 8), (-200, 10, 50, 9)]:
        H += gauss(X, Z, hx, hz, r, h)                      # rolling moor swells
    # Mountains on the north edge with a pass between them.
    H += gauss(X, Z, -180, -205, 115, 88)                  # Old Grey
    H += gauss(X, Z, -132, -96, 80, 44)                    # Old Grey's south shoulder (holds the tarn)
    anvil = gauss(X, Z, 172, -195, 105, 110)
    H += np.minimum(anvil, 84)                             # the Anvil: flat-topped
    d_ridge, _ = polyline_info(X, Z, [(-240, -215), (-120, -215), (-60, -205), (40, -212), (240, -220)])
    ridge = 70 * np.exp(-(d_ridge / 40) ** 2)
    notch = 1 - 0.55 * np.exp(-((X + 15) / 40) ** 2)       # the Saddle
    H += ridge * notch
    H += np.abs(noise) * 18 * smoothstep(150, 200, H)      # broken crags up high

    # Greymere: a glacial cirque with a tarn, headwall to the north-west.
    ang = np.arctan2(Z + 80, X + 128)
    cirque = np.hypot((X + 128) / 58, (Z + 80) / 46) * (1 + 0.08 * np.sin(ang * 3 + 1))
    apron = np.where(cirque < 2.3, 150 + noise - 46 * smoothstep(1.0, 2.3, cirque) ** 0.9, -1e9)
    H = np.maximum(H, apron)                                # moraine apron that holds the water in
    k = smoothstep(0.45, 1.15, cirque)
    H = np.where(cirque < 1.15, np.minimum(H, 145 * (1 - k) + H * k + 2 * k * (1 - k)), H)
    tarn = np.hypot((X + 128) / 40, (Z + 80) / 30) * (1 + 0.1 * np.sin(ang * 4)) < 1.0
    H = np.where(tarn, np.minimum(H, 145.0), H)

    # Barrowfield: a low rise with burial mounds.
    H += gauss(X, Z, -150, 92, 70, 7)
    barrows = [(-170, 70, 11, 6), (-150, 60, 9, 5), (-132, 78, 13, 7.5), (-168, 104, 10, 5.5),
               (-145, 108, 8, 4.5), (-122, 102, 9, 5), (-186, 92, 8, 4), (-155, 128, 12, 6.5),
               (-128, 132, 7, 4)]
    for bx, bz, r, h in barrows:
        d = np.hypot(X - bx, Z - bz) / r
        H += h * np.clip(1 - d * d, 0, None) ** 0.7       # rounded, steep-sided mounds

    # Burning Fold knoll (Dark Ages war camp).
    H += gauss(X, Z, 118, 58, 34, 9)

    # Sallow Bog basin.
    bog_d = np.hypot((X - 70) / 62, (Z - 150) / 46) * (1 + 0.18 * fbm(X, Z, 0.02, 2, seed=33))
    H = np.where(bog_d < 1.0, H * smoothstep(0.55, 1.0, bog_d) + (102.8 + noise * 0.4) * (1 - smoothstep(0.55, 1.0, bog_d)), H)

    # Crown Water.
    H, bed, d_cw = carve_channel(H, X, Z, Z3_CROWN_WATER, 3.0, 16.0, sharp=0.8)

    # The Rive: a chasm 60-80 m deep. Rim lips slightly raised, black-veined walls.
    d_rv, s_rv = polyline_info(X, Z, Z3_RIVE)
    L = path_length(Z3_RIVE)[-1]
    width = np.interp(s_rv, [0, 40, 120, 250, L], [2, 10, 17, 19, 14])
    floor = np.interp(s_rv, [0, 40, 140, 250, L], [118, 82, 48, 44, 52])
    inside = 1 - smoothstep(width * 0.55, width + 2, d_rv)
    H = H * (1 - inside) + (floor + noise * 2) * inside
    H += 2.5 * np.exp(-((d_rv - width - 4) / 4) ** 2)

    # Weathergate: flatten the arrival.
    H = flatten_path(H, X, Z, [(-40, 240), (-40, 214)], 6, 6)

    paths = [
        ("track", [(-40, 238), (-40, 210), (-55, 170), (-70, 140), (-110, 110), (-150, 90)]),
        ("track", [(-55, 170), (-20, 140), (10, 115), (40, 96), (80, 70), (112, 58)]),
        ("track", [(-110, 110), (-115, 60), (-98, 20), (-92, -10), (-100, -48)]),
        ("track", [(112, 58), (90, 20), (60, 0), (40, -22)]),
        ("track", [(-100, -48), (-70, -40), (-40, -20)]),
        ("track", [(-100, -48), (-80, -100), (-50, -150), (-25, -185), (-15, -238)]),
        ("track", [(40, -22), (90, -30), (124, -46)]),
        ("stair", [(170, -60), (190, -100), (170, -138), (138, -150)]),
        ("route", [(-40, 236), (-40, 210), (-55, 170), (-20, 140), (10, 115), (40, 96), (80, 70), (112, 58),
                   (90, 20), (60, 0), (40, -22), (90, -30), (124, -46), (131, -74)]),
        ("route_alt", [(-55, 170), (-70, 140), (-110, 110), (-115, 60), (-98, 20), (-92, -10), (-100, -48),
                       (-70, -40), (-40, -20), (40, -22)]),
    ]
    stones = [(-90 + i * 9, 158 - i * 4.2) for i in range(10)]
    walls = [[(112, -104), (146, -104), (150, -44), (112, -42), (112, -104)],      # Cinderhold
             [(104, 44), (132, 44), (134, 72), (104, 72), (104, 44)]]              # Burning Fold palisade
    blocks = [(128, -88, 12, 10), (130, -60, 14, 9), (118, -74, 6, 6), (142, -74, 6, 6),
              (-70, -70, 5, 4), (-62, -72, 4, 4),                      # tarn hamlet
              (60, 140, 4, 3), (78, 162, 4, 3), (88, 140, 3, 3),       # peat huts
              (-40, 222, 7, 7)] + [(sx, sz, 1.6, 1.6) for sx, sz in stones]

    bog = soft_mask((bog_d < 0.95), 4)
    ash_m = soft_mask((d_rv < 75) & (d_rv > 18) & (X > -10) & (Z > -120), 10)
    snow = soft_mask(H > 172, 2)
    scree = soft_mask((H > 150) & (H <= 172), 2)
    heather = soft_mask((H > 104) & (H < 128) & (Z > -20) & (bog_d > 1.0), 6) * (1 - ash_m)
    pois = [
        ("shrine", -24, 214, "Weathergate Shrine"),
        ("shrine", -112, 116, "Barrow Shrine (the oldest)"),
        ("shrine", -84, -56, "Tarnside Shrine"),
        ("shrine", 40, -30, "Rivebridge Shrine"),
        ("dungeon", 131, -74, "Cinderhold (dungeon)"),
        ("rare", -132, 78, "The Long Man (5%, night)"),
        ("camp_dark", 118, 58, "The Burning Fold"),
        ("camp_dark", 84, -6, "Ashwood pickets"),
        ("camp_outcast", -66, -64, "Tarn hamlet"),
        ("door", 138, -150, "The Shut Door"),
        ("bridge", 22, -46, "Rivebridge"),
        ("secret", -150, 126, "Open barrow"),
        ("exit", -40, 237, "To Highcrown"),
        ("exit", -15, -236, "The road north (later)"),
    ]
    falls = [(-106, -43, 15, "Tarnspill")]
    areas = [
        (1, "Weathergate Rise", 100, 220), (2, "The Long Stones", -20, 176), (3, "Heather Moor", -190, 172),
        (4, "Barrowfield", -205, 120), (5, "Sallow Bog", 112, 176), (6, "The Burning Fold", 165, 64),
        (7, "Greymere Tarn", -190, -58), (8, "The Ashwood", 70, 22), (9, "The Rive", 210, -84),
        (10, "Cinderhold", 172, -36), (11, "The Saddle", 62, -206), (12, "Old Grey", -205, -200),
        (13, "The Anvil", 200, -192),
    ]
    rivers = [("Crown Water", [(p[0], p[1]) for p in Z3_CROWN_WATER], 5)]
    lakes = [("Greymere", tarn)]
    return dict(key="zone3", name="Zone 3 — The Barrow Fells", size=size, offset_z=-842.0, X=X, Z=Z, H=H,
                rivers=rivers, lakes=lakes, falls=falls, paths=paths, walls=walls, blocks=blocks,
                areas=areas, pois=pois, rive=(Z3_RIVE, inside),
                regions=[("heather", heather), ("bog", bog), ("ash", ash_m), ("scree", scree), ("snow", snow)],
                contour=5.0, index=25.0, levels="11 – 17  (Cinderhold 15 – 18)",
                tagline="Wind-scoured high moor, barrows and bog, up to the snowline and the black chasm.")


ALL = [zone1, zone2, zone3]
