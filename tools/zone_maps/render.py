"""Draws the three zone maps, the overview with the route's elevation profile,
and exports 16-bit heightmaps. Run: python3 render.py out_dir"""
import json
import os
import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patheffects as pe
from matplotlib import font_manager
from matplotlib.colors import LinearSegmentedColormap, LightSource, Normalize
from matplotlib.patches import Rectangle, Circle, FancyArrow, Polygon
import numpy as np
from PIL import Image

import zones as Zs
from terrain import path_length

for f in ["texgyrepagella-regular.otf", "texgyrepagella-bold.otf", "texgyrepagella-italic.otf",
          "texgyrepagella-bolditalic.otf"]:
    font_manager.fontManager.addfont("/usr/share/texmf/fonts/opentype/public/tex-gyre/" + f)
SERIF = "TeX Gyre Pagella"
SANS = "DejaVu Sans"

PAPER = "#e9e1cf"
INK = "#2b241c"
HALO = [pe.withStroke(linewidth=3, foreground=PAPER, alpha=0.9)]
HALO_S = [pe.withStroke(linewidth=2.2, foreground=PAPER, alpha=0.9)]

# Elevation colours (absolute metres), muted to the game's washed-out palette.
ELEV_STOPS = [(-8, "#2f3a33"), (0, "#45523f"), (8, "#5e6845"), (20, "#76774f"), (40, "#8b8459"),
              (65, "#9a8f68"), (95, "#8e8865"), (115, "#857c62"), (135, "#86806f"), (150, "#8f8a82"), (170, "#aaa7a1"),
              (200, "#cfcdc9"), (240, "#eeedea"), (300, "#ffffff")]
EMIN, EMAX = ELEV_STOPS[0][0], ELEV_STOPS[-1][0]
CMAP = LinearSegmentedColormap.from_list(
    "kingdom", [((e - EMIN) / (EMAX - EMIN), c) for e, c in ELEV_STOPS])
NORM = Normalize(EMIN, EMAX)

WATER = "#4f6f7c"
WATER_EDGE = "#2f4650"
REGION_TINT = {
    "woods": ("#2f3d27", 0.42), "fen": ("#4d6150", 0.45), "bog": ("#38402c", 0.55),
    "pale": ("#e8e6dc", 0.55), "ash": ("#2c2a2a", 0.45), "heather": ("#6e5568", 0.22),
    "scree": ("#9a958c", 0.35), "snow": ("#ffffff", 0.6), "cliff": ("#3a332b", 0.25),
}
POI_STYLE = {
    "shrine": dict(marker="D", s=120, c="#e5a13a", ec="#5a3a0c", lw=1.4, z=12),
    "dungeon": dict(marker="v", s=210, c="#1b1714", ec="#c0392b", lw=2.2, z=12),
    "boss": dict(marker="X", s=150, c="#c0392b", ec="#1b1714", lw=1, z=12),
    "rare": dict(marker="*", s=300, c="#8e5bd1", ec="#2b1840", lw=1, z=12),
    "camp_dark": dict(marker="s", s=90, c="#7a1f17", ec="#120c0a", lw=1.4, z=11),
    "camp_white": dict(marker="s", s=90, c="#efe9da", ec="#a8892f", lw=1.8, z=11),
    "camp_outcast": dict(marker="o", s=85, c="#8a6a45", ec="#2b1d10", lw=1.4, z=11),
    "gate": dict(marker="H", s=95, c="#6d655b", ec="#1b1714", lw=1.2, z=11),
    "bridge": dict(marker="$⌢$", s=180, c="#3b2d1e", ec="none", lw=0, z=11),
    "vista": dict(marker="^", s=110, c="#cfc3a3", ec="#2b241c", lw=1.2, z=11),
    "secret": dict(marker="d", s=110, c="#5f8f5a", ec="#1d331a", lw=1.2, z=11),
    "door": dict(marker="s", s=130, c="#4b3b2b", ec="#d0b070", lw=2.0, z=11),
    "exit": dict(marker=">", s=0, c="none", ec="none", lw=0, z=11),
}
POI_NAMES = {
    "shrine": "Shrine (rest, bank, travel)", "dungeon": "Dungeon entrance", "rare": "Named rare (5% spawn)",
    "camp_dark": "Dark Ages camp", "camp_white": "White Knight post", "camp_outcast": "Outcast camp / hub",
    "gate": "Gate or water gate", "bridge": "Bridge", "vista": "Lookout", "secret": "Secret / optional",
    "door": "Sealed door (teaser)",
}
PATH_STYLE = {
    "road": [dict(color="#3b2f22", lw=5.2), dict(color="#d9c79f", lw=3.2)],
    "street": [dict(color="#3b2f22", lw=3.6), dict(color="#cdbb93", lw=2.0)],
    "track": [dict(color="#4a3a28", lw=1.4, ls=(0, (4, 2.5)))],
    "stair": [dict(color="#2b241c", lw=3.0), dict(color="#d9c79f", lw=1.6, ls=(0, (1.2, 1.2)))],
    "route": [dict(color="#1b1510", lw=5.0, alpha=0.55, solid_capstyle="round"),
              dict(color="#f3b34a", lw=3.0, ls=(0, (2.2, 1.4)), solid_capstyle="round")],
    "route_alt": [dict(color="#1b1510", lw=4.0, alpha=0.35, solid_capstyle="round"),
                  dict(color="#f6dca6", lw=2.2, ls=(0, (1.2, 1.6)), solid_capstyle="round")],
    "shortcut": [dict(color="#4f8a43", lw=2.4, ls=(0, (3, 1.6)))],
}
PATH_NAMES = {"road": "Road", "street": "Main street", "track": "Track or trail", "stair": "Cliff stair / switchbacks",
              "route": "Main route (first time through)", "route_alt": "Alternative route",
              "shortcut": "Shortcut (opens from the far side)"}


def shade(z):
    H = z["H"]
    ls = LightSource(azdeg=315, altdeg=42)
    rgb = CMAP(NORM(H))[..., :3]
    hs = ls.hillshade(H, vert_exag=2.2 if z["key"] == "zone1" else 1.5, dx=1, dy=1)
    out = rgb * (0.55 + 0.6 * hs[..., None])
    for kind, m in z["regions"]:
        col, a = REGION_TINT[kind]
        c = np.array(matplotlib.colors.to_rgb(col))
        w = (m * a)[..., None]
        out = out * (1 - w) + c * w
    return np.clip(out, 0, 1)


def scatter_glyphs(ax, z, kind, rng):
    """Little symbols that read as woods, reeds, dead trees or standing stones."""
    m = dict(z["regions"]).get(kind)
    if m is None:
        return
    half = z["size"] / 2
    pts = rng.uniform(-half, half, (5000, 2))
    keep = [p for p in pts if m[int(p[1] + half), int(p[0] + half)] > 0.55]
    keep = np.array(keep[:900 if kind == "woods" else 420])
    if len(keep) == 0:
        return
    if kind == "woods":
        ax.scatter(keep[:, 0], keep[:, 1], marker="^", s=16, c="#1f2a19", alpha=0.55, lw=0, zorder=3)
    elif kind in ("fen", "bog"):
        ax.scatter(keep[:, 0], keep[:, 1], marker="$ψ$", s=22, c="#26332a", alpha=0.55, lw=0, zorder=3)
    elif kind == "ash":
        ax.scatter(keep[:, 0], keep[:, 1], marker="|", s=26, c="#141212", alpha=0.6, lw=1.1, zorder=3)
    elif kind == "heather":
        ax.scatter(keep[:, 0], keep[:, 1], marker=".", s=7, c="#4a3346", alpha=0.35, lw=0, zorder=3)


def draw_zone(z, out_dir):
    half = z["size"] / 2
    fig = plt.figure(figsize=(16.5, 12), facecolor=PAPER)
    ax = fig.add_axes([0.025, 0.04, 0.63, 0.86])
    ax.set_facecolor(PAPER)
    rng = np.random.default_rng(3)

    ax.imshow(shade(z), extent=(-half, half, half, -half), interpolation="bilinear", zorder=0)
    for kind in ["woods", "fen", "bog", "ash", "heather"]:
        scatter_glyphs(ax, z, kind, rng)

    # The Rive: dark chasm with black veins.
    if "rive" in z:
        pts, inside = z["rive"]
        ax.contourf(z["X"], z["Z"], inside, levels=[0.35, 1.01], colors=["#161413"], alpha=0.78, zorder=2)
        p = np.array(pts)
        for k in range(1, 30):
            i = rng.integers(0, len(p) - 1)
            t = rng.random()
            a = p[i] + (p[i + 1] - p[i]) * t
            ang = rng.uniform(0, np.pi)
            L = rng.uniform(6, 18)
            ax.plot([a[0], a[0] + L * np.cos(ang)], [a[1], a[1] + L * np.sin(ang)],
                    color="#000", lw=0.8, alpha=0.7, zorder=2)

    # Contours.
    H = z["H"]
    step, idx = z["contour"], z["index"]
    lv = np.arange(np.floor(H.min() / step) * step, H.max() + step, step)
    ax.contour(z["X"], z["Z"], H, levels=lv, colors="#3a2f24", linewidths=0.35, alpha=0.45, zorder=4)
    li = lv[np.isclose(lv % idx, 0)]
    cs = ax.contour(z["X"], z["Z"], H, levels=li, colors="#2b2118", linewidths=0.9, alpha=0.7, zorder=4)
    lab = ax.clabel(cs, fmt="%d m", fontsize=7, inline=True, inline_spacing=2)
    for t in lab:
        t.set_color("#2b2118")
        t.set_fontfamily(SANS)

    # Water.
    for name, mask in z["lakes"]:
        ax.contourf(z["X"], z["Z"], mask.astype(float), levels=[0.5, 1.5], colors=[WATER], zorder=5)
        ax.contour(z["X"], z["Z"], mask.astype(float), levels=[0.5], colors=[WATER_EDGE], linewidths=1.1, zorder=5)
    px_per_m = (0.63 * 16.5 * 72) / z["size"]
    for name, pts, w in z["rivers"]:
        p = np.array(pts)
        ax.plot(p[:, 0], p[:, 1], color=WATER_EDGE, lw=w * px_per_m + 1.6, solid_capstyle="round",
                solid_joinstyle="round", zorder=5)
        ax.plot(p[:, 0], p[:, 1], color=WATER, lw=w * px_per_m, solid_capstyle="round",
                solid_joinstyle="round", zorder=5)
        # Flow arrow mid-river.
        L = path_length(p)
        s = L[-1] * 0.5
        i = np.searchsorted(L, s) - 1
        a = p[i] + (p[i + 1] - p[i]) * (s - L[i]) / (L[i + 1] - L[i])
        d = (p[i + 1] - p[i]) / np.linalg.norm(p[i + 1] - p[i])
        ax.annotate("", xy=a + d * 6, xytext=a - d * 6,
                    arrowprops=dict(arrowstyle="-|>", color="#dfe8ea", lw=1.3), zorder=6)
    for fx, fz, drop, name in z["falls"]:
        ax.scatter([fx], [fz], marker="$≡$", s=170, c="#f4f7f7", zorder=7, lw=0)
        ax.text(fx + 6, fz + 2, f"{name}\n{drop} m fall", fontsize=7.5, fontfamily=SERIF, style="italic",
                color="#1f3a44", zorder=9, path_effects=HALO_S, va="center")

    # Buildings and walls.
    for bx, bz, w, d in z["blocks"]:
        ax.add_patch(Rectangle((bx - w / 2, bz - d / 2), w, d, fc="#5b5048", ec="#2a221c", lw=0.4, zorder=6))
    for wall in z["walls"]:
        p = np.array(wall)
        ax.plot(p[:, 0], p[:, 1], color="#2a2520", lw=3.2, solid_capstyle="butt", zorder=7)
        ax.plot(p[:, 0], p[:, 1], color="#8a8378", lw=1.4, solid_capstyle="butt", zorder=7)
        ax.scatter(p[:, 0], p[:, 1], marker="s", s=30, c="#8a8378", edgecolors="#2a2520", lw=1, zorder=7)

    # Paths.
    order = ["track", "road", "street", "stair", "shortcut", "route_alt", "route"]
    for kind in order:
        for k, pts in z["paths"]:
            if k != kind:
                continue
            p = np.array(pts)
            for st in PATH_STYLE[kind]:
                ax.plot(p[:, 0], p[:, 1], zorder=8 if kind.startswith("route") else 7, **st)
            if kind == "shortcut":
                ax.annotate("", xy=p[-1], xytext=p[-2], arrowprops=dict(arrowstyle="-|>", color="#4f8a43", lw=2), zorder=8)

    # Points of interest.
    for kind, x, y, label in z["pois"]:
        if kind == "exit":
            dx = 0
            dy = -1 if y < 0 else 1
            ax.add_patch(FancyArrow(x, y - dy * 14, 0, dy * 12, width=7, head_width=16, head_length=8,
                                    fc="#f3b34a", ec=INK, lw=1.2, zorder=12, length_includes_head=True))
            ax.text(x + 12, y - dy * 8, label, fontsize=9.5, fontfamily=SERIF, weight="bold", color=INK,
                    path_effects=HALO, zorder=13, va="center")
            continue
        st = POI_STYLE[kind]
        if kind == "shrine":
            ax.scatter([x], [y], s=700, c="#e5a13a", alpha=0.25, lw=0, zorder=10)
        ax.scatter([x], [y], marker=st["marker"], s=st["s"], c=st["c"], edgecolors=st["ec"],
                   linewidths=st["lw"], zorder=st["z"])
        ax.text(x + 5.5, y - 4.5, label, fontsize=8, fontfamily=SANS, color=INK,
                path_effects=HALO_S, zorder=13)

    # Area numbers and names.
    for num, name, x, y in z["areas"]:
        ax.add_patch(Circle((x, y), 6.5 * z["size"] / 420, fc=INK, ec=PAPER, lw=1.4, zorder=14))
        ax.text(x, y, str(num), ha="center", va="center", fontsize=8.5, color=PAPER, weight="bold",
                fontfamily=SANS, zorder=15)
        ax.text(x, y + 10 * z["size"] / 420, name.upper(), ha="center", va="top", fontsize=10.5,
                fontfamily=SERIF, weight="bold", color="#231b13", path_effects=HALO, zorder=15)

    # Spot heights: highest point and a few named ones.
    for (sx, sz) in z.get("spots", []):
        e = H[int(sz + half), int(sx + half)]
        ax.scatter([sx], [sz], marker="^", s=26, c=INK, zorder=9)
        ax.text(sx + 3, sz + 3, f"{e:.0f}", fontsize=7, fontfamily=SANS, color=INK, path_effects=HALO_S, zorder=9)

    ax.set_xlim(-half, half)
    ax.set_ylim(half, -half)
    ax.set_aspect("equal")
    ax.set_xticks(np.arange(-np.floor(half / 50) * 50, half + 1, 50))
    ax.set_yticks(np.arange(-np.floor(half / 50) * 50, half + 1, 50))
    ax.tick_params(labelsize=7, colors="#5a4c3c", length=3)
    ax.grid(color="#2b241c", alpha=0.08, lw=0.6)
    for sp in ax.spines.values():
        sp.set_edgecolor(INK)
        sp.set_linewidth(2)
    ax.set_xlabel("x (m, east)", fontsize=8, color="#5a4c3c", fontfamily=SANS)
    ax.set_ylabel("z (m, south)   — north is up", fontsize=8, color="#5a4c3c", fontfamily=SANS)

    # Scale bar and north arrow.
    sb_x, sb_y = -half + 14, half - 14
    for i in range(4):
        ax.add_patch(Rectangle((sb_x + i * 25, sb_y - 3), 25, 3, fc=INK if i % 2 == 0 else PAPER, ec=INK, lw=0.8, zorder=16))
    ax.text(sb_x, sb_y - 6, "0", fontsize=7, fontfamily=SANS, zorder=16, path_effects=HALO_S)
    ax.text(sb_x + 100, sb_y - 6, "100 m", fontsize=7, fontfamily=SANS, zorder=16, ha="center", path_effects=HALO_S)
    nx, ny = half - 22, -half + 34
    ax.add_patch(Polygon([(nx, ny - 18), (nx - 6, ny), (nx, ny - 5), (nx + 6, ny)], fc=INK, ec=INK, zorder=16))
    ax.text(nx, ny - 21, "N", ha="center", va="bottom", fontsize=12, fontfamily=SERIF, weight="bold", zorder=16,
            path_effects=HALO)

    # ---- Title and side panel.
    fig.text(0.025, 0.955, z["name"].upper(), fontsize=25, fontfamily=SERIF, weight="bold", color=INK)
    fig.text(0.025, 0.925, f"{z['tagline']}   ·   Player levels {z['levels']}   ·   "
             f"{z['size']:.0f} × {z['size']:.0f} m   ·   ground {H.min():.0f} to {H.max():.0f} m",
             fontsize=11, fontfamily=SERIF, style="italic", color="#4a3d2f")

    px = 0.68
    fig.text(px, 0.885, "AREAS", fontsize=13, fontfamily=SERIF, weight="bold", color=INK)
    y = 0.862
    for num, name, x, zz in z["areas"]:
        e = H[int(np.clip(zz + half, 0, 2 * half)), int(np.clip(x + half, 0, 2 * half))]
        fig.text(px, y, f"{num:>2}", fontsize=9.5, fontfamily=SANS, weight="bold", color=INK)
        fig.text(px + 0.02, y, name, fontsize=10.5, fontfamily=SERIF, color=INK)
        y -= 0.0205

    y -= 0.012
    fig.text(px, y, "KEY", fontsize=13, fontfamily=SERIF, weight="bold", color=INK)
    y -= 0.025
    used = {k for k, *_ in z["pois"]}
    kax = fig.add_axes([px, 0.04, 0.15, y - 0.03])
    kax.set_xlim(0, 10)
    n_items = len([k for k in POI_NAMES if k in used]) + len({k for k, _ in z["paths"]}) + 4
    kax.set_ylim(n_items + 0.5, -0.5)
    kax.axis("off")
    row = 0
    for k, nm in POI_NAMES.items():
        if k not in used:
            continue
        st = POI_STYLE[k]
        kax.scatter([0.6], [row], marker=st["marker"], s=st["s"] * 0.8, c=st["c"], edgecolors=st["ec"], linewidths=st["lw"])
        kax.text(1.5, row, nm, va="center", fontsize=9, fontfamily=SANS, color=INK)
        row += 1
    for k in ["route", "route_alt", "road", "street", "track", "stair", "shortcut"]:
        if k not in {kk for kk, _ in z["paths"]}:
            continue
        for st in PATH_STYLE[k]:
            kax.plot([0, 1.2], [row, row], **st)
        kax.text(1.5, row, PATH_NAMES[k], va="center", fontsize=9, fontfamily=SANS, color=INK)
        row += 1
    kax.plot([0, 1.2], [row, row], color=WATER_EDGE, lw=5)
    kax.plot([0, 1.2], [row, row], color=WATER, lw=3.4)
    kax.text(1.5, row, "River (arrow = flow)   ≡ waterfall", va="center", fontsize=9, fontfamily=SANS, color=INK)
    row += 1
    kax.add_patch(Rectangle((0.1, row - 0.3), 1.0, 0.6, fc="#5b5048", ec="#2a221c"))
    kax.text(1.5, row, "Buildings      ▬ walls", va="center", fontsize=9, fontfamily=SANS, color=INK)
    row += 1
    kax.text(0.0, row, f"Contours every {step:g} m, bold every {idx:g} m", va="center", fontsize=9,
             fontfamily=SANS, color=INK, style="italic")

    # Elevation bar (shared scale for all three zones).
    cax = fig.add_axes([0.86, 0.06, 0.017, 0.78])
    grad = np.linspace(EMAX, EMIN, 400)[:, None]
    cax.imshow(CMAP(NORM(grad)), aspect="auto", extent=(0, 1, EMIN, EMAX))
    cax.axhspan(H.min(), H.max(), xmin=0, xmax=1, fc="none", ec="#c0392b", lw=2)
    cax.set_xticks([])
    cax.yaxis.tick_right()
    cax.set_yticks([0, 25, 50, 75, 100, 125, 150, 175, 200, 250, 300])
    cax.tick_params(labelsize=8)
    cax.set_title("Elevation (m)\nall zones", fontsize=9, fontfamily=SERIF, color=INK)
    fig.text(0.895, 0.06, "Red box = this zone's\nrange. Heights are\nmeasured from the\nTithe River (0 m), so\nthe zones line up.",
             fontsize=8, fontfamily=SANS, color="#4a3d2f", va="bottom")

    for ext in ("png", "svg"):
        fig.savefig(os.path.join(out_dir, f"{z['file']}.{ext}"), dpi=150 if ext == "png" else 72, facecolor=PAPER)
    plt.close(fig)


def route_profile(z):
    pts = [p for k, p in z["paths"] if k == "route"][0]
    p = np.array(pts, float)
    L = path_length(p)
    s = np.arange(0, L[-1], 2.0)
    xs = np.interp(s, L, p[:, 0])
    zs = np.interp(s, L, p[:, 1])
    half = z["size"] / 2
    H = z["H"]
    e = H[np.clip((zs + half).astype(int), 0, H.shape[0] - 1), np.clip((xs + half).astype(int), 0, H.shape[1] - 1)]
    return s, e, xs, zs


def draw_overview(all_z, out_dir):
    fig = plt.figure(figsize=(18, 12), facecolor=PAPER)
    # Stacked map in world coordinates (shared x, z offset per zone).
    ax = fig.add_axes([0.02, 0.04, 0.27, 0.86])
    ax.set_facecolor(PAPER)
    for z in all_z:
        half = z["size"] / 2
        oz = z["offset_z"]
        ax.imshow(shade(z), extent=(-half, half, oz + half, oz - half), interpolation="bilinear", zorder=0)
        ax.add_patch(Rectangle((-half, oz - half), 2 * half, 2 * half, fc="none", ec=INK, lw=1.5, zorder=3))
        for name, pts, w in z["rivers"]:
            q = np.array(pts)
            ax.plot(q[:, 0], q[:, 1] + oz, color=WATER, lw=1.6, zorder=4)
        for name, mask in z["lakes"]:
            ax.contourf(z["X"], z["Z"] + oz, mask.astype(float), levels=[0.5, 1.5], colors=[WATER], zorder=4)
        for k, pts in z["paths"]:
            if k == "route":
                q = np.array(pts)
                ax.plot(q[:, 0], q[:, 1] + oz, color="#1b1510", lw=3.6, alpha=0.5, zorder=5)
                ax.plot(q[:, 0], q[:, 1] + oz, color="#f3b34a", lw=2.0, ls=(0, (2, 1.2)), zorder=5)
        for kind, x, y, label in z["pois"]:
            if kind in ("shrine", "dungeon", "rare"):
                st = POI_STYLE[kind]
                ax.scatter([x], [y + oz], marker=st["marker"], s=st["s"] * 0.45, c=st["c"],
                           edgecolors=st["ec"], linewidths=1, zorder=6)
        ax.text(-half + 8, oz - half + 10, z["name"].split("— ")[1].upper(), fontsize=11.5, fontfamily=SERIF,
                weight="bold", va="top", color=INK, path_effects=HALO, zorder=7)
        ax.text(-half + 8, oz - half + 30, f"levels {z['levels'].split('(')[0].strip()}", fontsize=8.5,
                fontfamily=SANS, va="top", color=INK, path_effects=HALO_S, zorder=7)
    ax.set_xlim(-245, 245)
    ax.set_ylim(185, -1085)
    ax.set_aspect("equal")
    ax.axis("off")

    # Elevation profile along the main route, one zone after the other.
    pax = fig.add_axes([0.35, 0.47, 0.62, 0.38])
    pax.set_facecolor("#efe8d8")
    offset = 0.0
    zone_cols = ["#76774f", "#9a8f68", "#857a6e"]
    marks = {
        "zone1": [(0, "Crossroads"), (0.47, "Broken bridge"), (0.73, "Checkpoint"), (0.9, "North road")],
        "zone2": [(0.0, "Causeway"), (0.13, "Mudside"), (0.27, "Sluice"), (0.36, "Lower Falls"),
                  (0.55, "Lower Town"), (0.66, "Rule Gate"), (0.75, "Upper Ward"), (0.86, "Pilgrim Stair"),
                  (0.995, "Weathergate")],
        "zone3": [(0.2, "Long Stones"), (0.42, "Bog edge"), (0.55, "Burning Fold"),
                  (0.72, "Ashwood"), (0.85, "Rivebridge"), (0.99, "Cinderhold")],
    }
    for z, col in zip(all_z, zone_cols):
        s, e, *_ = route_profile(z)
        pax.fill_between(s + offset, -10, e, color=col, alpha=0.85, lw=0)
        pax.plot(s + offset, e, color=INK, lw=1.4)
        pax.axvline(offset, color=INK, lw=1, ls="--", alpha=0.6)
        pax.text(offset + 8, 228, z["name"].split("— ")[1], fontsize=13, fontfamily=SERIF, weight="bold", color=INK)
        for frac, name in marks[z["key"]]:
            i = min(int(frac * (len(s) - 1)), len(s) - 1)
            pax.plot([s[i] + offset] * 2, [e[i], e[i] + 16], color=INK, lw=0.7)
            pax.text(s[i] + offset, e[i] + 18, name, rotation=60, fontsize=8.5, fontfamily=SANS, color=INK,
                     ha="left", va="bottom")
        offset += s[-1]
    # Cinderhold's descent into the Rive (dungeon, below ground).
    pax.annotate("Cinderhold descends\ninto the Rive (≈ 45 m)", xy=(offset - 5, 50), xytext=(offset - 330, 30),
                 fontsize=8.5, fontfamily=SANS, arrowprops=dict(arrowstyle="->", color=INK), color=INK)
    pax.plot([offset - 5, offset - 5], [121, 46], color="#1b1714", lw=3, ls=(0, (2, 1.5)))
    pax.set_xlim(0, offset)
    pax.set_ylim(-10, 260)
    pax.set_ylabel("Elevation (m)", fontsize=10, fontfamily=SERIF)
    pax.set_xlabel("Distance walked along the main route (m)", fontsize=10, fontfamily=SERIF)
    pax.tick_params(labelsize=8)
    pax.grid(alpha=0.2)
    pax.set_title("THE CLIMB: elevation along the main route, Crossroads to Cinderhold", fontsize=14,
                  fontfamily=SERIF, weight="bold", color=INK, loc="left")

    # Zone cards.
    cards = [
        ("1  THE TITHELANDS", "Lowland, 0 to 35 m  ·  built",
         "Wet farm valley under Highcrown: river, farms, burned hamlet, east woods, the quarry pit. "
         "The road north ends at the Knights' checkpoint and the walls in the fog.",
         [("Shrines", "Crossroads, Mill, Quarry, Camp Hearth"), ("Dungeon", "The Gullet (Harl the Delver)"),
          ("Named rare", "Hobb the Unhanged"), ("Factions", "Knights north, Dark Ages east"),
          ("Weather", "Overcast, rain, river fog")]),
        ("2  HIGHCROWN", "Spur and scarp, 2 to 108 m  ·  new",
         "The White Knights' walled city on a granite spur, sealed for 'the Cleansing'. Fen and shanty outside; "
         "inside, a burned lower town, a waterfall gorge and terraces up to the cathedral crag.",
         [("Shrines", "Mudside, Walled Shrine, Bellfoot"), ("Dungeon", "The Reliquary (Lord Censor Aubrecht)"),
          ("Named rare", "Sir Gaspard, Twice-Buried"), ("Factions", "White Knights; Outcasts in Mudside"),
          ("Weather", "Ash, smoke, bells, spray at the falls")]),
        ("3  THE BARROW FELLS", "High moor, 44 to 286 m  ·  new",
         "Wind-scoured upland: standing stones, barrows, peat bog, a tarn in a cirque and two snow peaks. "
         "The Rive, a black chasm, splits the moor; Cinderhold straddles it.",
         [("Shrines", "Weathergate, Barrow, Tarnside, Rive"), ("Dungeon", "Cinderhold (Vessa, the Kindled)"),
          ("Named rare", "The Long Man (night only)"), ("Factions", "Dark Ages; the first undead"),
          ("Weather", "Gales, sleet, snow above 170 m")]),
    ]
    import textwrap
    for i, (t, sub, body, facts) in enumerate(cards):
        x0 = 0.35 + i * 0.21
        fig.patches.append(Rectangle((x0, 0.05), 0.195, 0.33, transform=fig.transFigure, fc="#efe8d8",
                                     ec=INK, lw=1.2))
        fig.text(x0 + 0.01, 0.36, t, fontsize=13, fontfamily=SERIF, weight="bold", color=INK, va="top")
        fig.text(x0 + 0.01, 0.333, sub, fontsize=10, fontfamily=SERIF, style="italic", color="#5a4a38", va="top")
        fig.text(x0 + 0.01, 0.305, "\n".join(textwrap.wrap(body, 46)), fontsize=9.3, fontfamily=SANS,
                 color=INK, va="top", linespacing=1.4)
        fy = 0.19
        for k, v in facts:
            fig.text(x0 + 0.01, fy, k.upper(), fontsize=7.5, fontfamily=SANS, weight="bold", color="#6a5844", va="top")
            fig.text(x0 + 0.062, fy, v, fontsize=8.8, fontfamily=SANS, color=INK, va="top")
            fy -= 0.026
    fig.text(0.02, 0.955, "KINGDOM — THE FIRST THREE ZONES", fontsize=26, fontfamily=SERIF, weight="bold", color=INK)
    fig.text(0.02, 0.925, "Each zone starts where the last one ends. The Crown Water rises in the Barrow Fells, falls "
             "40 m off the scarp into Highcrown, cuts its gorge through the city and drains into the fen below.",
             fontsize=11, fontfamily=SERIF, style="italic", color="#4a3d2f")
    for ext in ("png", "svg"):
        fig.savefig(os.path.join(out_dir, f"ZONES_OVERVIEW.{ext}"), dpi=150 if ext == "png" else 72, facecolor=PAPER)
    plt.close(fig)


def export_heightmap(z, out_dir):
    H = z["H"]
    lo, hi = float(H.min()), float(H.max())
    img = np.round((H - lo) / (hi - lo) * 65535).astype(np.uint16)
    Image.fromarray(img).save(os.path.join(out_dir, f"{z['key']}_height.png"))
    return dict(file=f"{z['key']}_height.png", size_m=z["size"], pixels=int(H.shape[0]), meters_per_pixel=1.0,
                min_height_m=round(lo, 2), max_height_m=round(hi, 2),
                note="16-bit grey: height = min + value/65535 * (max - min). Row 0 is north (-z), column 0 is west (-x).")


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    os.makedirs(out, exist_ok=True)
    os.makedirs(os.path.join(out, "heightmaps"), exist_ok=True)
    built = []
    meta = {}
    files = {"zone1": "ZONE1_TITHELANDS_MAP", "zone2": "ZONE2_HIGHCROWN_MAP", "zone3": "ZONE3_BARROW_FELLS_MAP"}
    spots = {"zone1": [(105, 28), (56, -119), (-133, -118)],
             "zone2": [(4, -46), (-118, -60), (-40, -205), (0, 138), (150, -90)],
             "zone3": [(-180, -205), (172, -195), (-15, -210), (-128, -80), (130, -74)]}
    for f in Zs.ALL:
        z = f()
        z["file"] = files[z["key"]]
        z["spots"] = spots[z["key"]]
        draw_zone(z, out)
        meta[z["key"]] = export_heightmap(z, os.path.join(out, "heightmaps"))
        built.append(z)
        print("drew", z["key"])
    draw_overview(built, out)
    with open(os.path.join(out, "heightmaps", "heightmaps.json"), "w") as fh:
        json.dump(meta, fh, indent=2)
    print("done")
