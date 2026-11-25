#!/usr/bin/env python3
"""Textures for the White Knight, cut from the owner's character sheet.

    python3 tools/white_knight_textures.py

Reads docs/white_knight/white_knight_sheet.webp (the owner's sheet) and writes into
assets/characters/white_knight/textures/:
  wk_views.webp    an atlas: the FRONT / BACK / SIDE views and the three helmet close-ups,
                   doubled in size, the dark background filled with the nearest armour colour
                   (so a texel just off the silhouette is never black) and the hanging sword
                   painted out of the front view. Below the tabard's hem the background is
                   see-through (alpha 0), so the cloth's ragged edge is the painted one. The
                   model is coloured by projecting these pictures onto it (white_knight.gd).
  wk_chainmail.png (+ _n normal map)
                   a seamless tile cut from the CHAINMAIL detail panel.
and assets/characters/white_knight/wk_atlas.gd: where each picture sits in the atlas and how
its pixels line up with the model (centre, sole line, pixels per metre).

Needs Pillow, numpy and scipy.
"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage as nd

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHEET = os.path.join(ROOT, "docs/white_knight/white_knight_sheet.webp")
OUT = os.path.join(ROOT, "assets/characters/white_knight/textures")
GD = os.path.join(ROOT, "assets/characters/white_knight/wk_atlas.gd")
K = 2  # upscale

# ------------------------------------------------------------ the pictures on the sheet
# name: crop box (x0, y0, x1, y1) in sheet pixels, flip, then how the picture lines up:
#   body views: cx = the figure's centre line (sheet x), sole = the sheet y of y = 0 (m),
#               ppm = pixels per metre. Measured from the helm and the soles (1.915 m tall).
#   helm close-ups: see wk_atlas.gd (fitted to the helm's outline in each panel).
VIEWS = {
    "front": {"box": (262, 8, 434, 486), "flip": False, "cx": 339.5, "sole": 477.0, "ppm": 242.3},
    "back": {"box": (464, 8, 642, 486), "flip": False, "cx": 551.5, "sole": 478.0, "ppm": 242.8},
    "side_r": {"box": (810, 8, 932, 486), "flip": False, "cx": 856.5, "sole": 479.0, "ppm": 242.3},
    "side_l": {"box": (662, 8, 786, 486), "flip": True, "cx": 733.0, "sole": 480.0, "ppm": 243.9},
    "helm_front": {"box": (30, 532, 200, 742), "flip": False},
    "helm_side": {"box": (380, 532, 522, 742), "flip": False},
    "helm_back": {"box": (540, 532, 672, 742), "flip": False},
    "tabard_panel": {"box": (990, 535, 1172, 752), "flip": False},
}
# Where each picture goes in the atlas (top-left, atlas pixels).
PLACE = {
    "front": (8, 8), "back": (364, 8), "side_r": (736, 8), "side_l": (996, 8),
    "helm_front": (8, 980), "helm_side": (364, 980), "helm_back": (664, 980),
    "tabard_panel": (944, 980),
}
ATLAS = (2048, 1424)

# The sword hanging at the front view's left hip, painted out: below the hilt from the
# mirrored side of the figure, the hilt itself from the colours round it.
SWORD = [(375, 197), (392, 197), (437, 396), (421, 399)]
HILT_Y = 238


def load():
    return np.asarray(Image.open(SHEET).convert("RGB")).astype(np.float32)


def fg_mask(rgb):
    lum = rgb.mean(2)
    m = nd.uniform_filter(lum, 5)
    m2 = nd.uniform_filter(lum * lum, 5)
    sd = np.sqrt(np.maximum(m2 - m * m, 0))
    fg = (lum > 40) | (sd > 7)
    fg = nd.binary_closing(fg, iterations=3)
    fg = nd.binary_fill_holes(fg)
    fg = nd.binary_opening(fg, iterations=2)
    # keep the biggest piece (the figure / the helm), drop specks and the panel frames
    lab, n = nd.label(fg)
    if n > 1:
        sizes = nd.sum(fg, lab, range(1, n + 1))
        fg = lab == (np.argmax(sizes) + 1)
        fg = nd.binary_fill_holes(fg)
    return fg


def cloth_mask(rgb):
    """The tabard's ivory and red cloth, small stains filled in."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    lum = rgb.mean(2)
    ivory = (lum > 95) & ((r - b) < 75)
    red = (r > 70) & (r > g * 1.45) & (r > b * 1.35)
    m = nd.binary_closing(ivory | red, iterations=2)
    m = nd.binary_fill_holes(m)
    return nd.binary_opening(m, iterations=1)


def fill_background(rgb, fg):
    """Every background pixel takes the colour of the nearest figure pixel."""
    idx = nd.distance_transform_edt(~fg, return_distances=False, return_indices=True)
    return rgb[idx[0], idx[1]]


def in_poly(xs, ys, poly):
    inside = np.zeros(xs.shape, bool)
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % n]
        cond = ((y1 > ys) != (y2 > ys)) & (xs < (x2 - x1) * (ys - y1) / (y2 - y1 + 1e-9) + x1)
        inside ^= cond
    return inside


def paint_out_sword(sheet):
    h, w, _ = sheet.shape
    ys, xs = np.mgrid[0:h, 0:w]
    m = in_poly(xs, ys, SWORD)
    cx = VIEWS["front"]["cx"]
    out = sheet.copy()
    low = m & (ys >= HILT_Y)
    mx = np.clip(np.round(2 * cx - xs[low]).astype(int), 0, w - 1)
    out[ys[low], xs[low]] = sheet[ys[low], mx]
    hilt = m & (ys < HILT_Y)
    known = ~hilt
    idx = nd.distance_transform_edt(~known, return_distances=False, return_indices=True)
    filled = out[idx[0], idx[1]]
    out[hilt] = nd.uniform_filter(filled, size=(5, 5, 1))[hilt]
    return out


def seamless(img):
    """Blend a picture with itself shifted by half, so it tiles without a seam."""
    h, w, _ = img.shape
    rolled = np.roll(np.roll(img, h // 2, 0), w // 2, 1)
    yy = np.sin(np.pi * (np.arange(h) + 0.5) / h)[:, None]
    xx = np.sin(np.pi * (np.arange(w) + 0.5) / w)[None, :]
    m = np.clip((yy * xx) * 1.6, 0, 1) ** 1.2
    return img * m[..., None] + rolled * (1 - m[..., None])


def normal_map(rgb, strength):
    lum = nd.gaussian_filter(rgb.mean(2) / 255.0, 0.8)
    dx = (np.roll(lum, -1, 1) - np.roll(lum, 1, 1)) * strength
    dy = (np.roll(lum, -1, 0) - np.roll(lum, 1, 0)) * strength
    n = np.dstack([-dx, dy, np.ones_like(lum)])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    return ((n * 0.5 + 0.5) * 255).astype(np.uint8)


def delight(rgb, sigma):
    """Take out the light and shade painted across a patch, keep its detail and colour."""
    low = nd.gaussian_filter(rgb, (sigma, sigma, 0)) + 1.0
    return rgb / low * rgb.reshape(-1, 3).mean(0)


def save_tile(name, rgb, size, strength, gain=1.0, flatten=0.0):
    if flatten > 0.0:
        rgb = delight(rgb, flatten)
    t = seamless(rgb) * gain
    im = Image.fromarray(np.clip(t, 0, 255).astype(np.uint8)).resize(size, Image.LANCZOS)
    im.save(os.path.join(OUT, name + ".png"))
    Image.fromarray(normal_map(np.asarray(im).astype(np.float32), strength)).save(os.path.join(OUT, name + "_n.png"))


def main():
    os.makedirs(OUT, exist_ok=True)
    sheet = paint_out_sword(load())
    atlas = np.zeros((ATLAS[1], ATLAS[0], 4), np.float32) + 40.0
    atlas[..., 3] = 255.0
    info = {}
    for name, v in VIEWS.items():
        x0, y0, x1, y1 = v["box"]
        crop = sheet[y0:y1, x0:x1]
        fg = fg_mask(crop)
        crop = fill_background(crop, fg)
        alpha = np.full(fg.shape, 255.0)
        if "cx" in v:
            # below 0.62 m (round the tabard's hem) only the cloth itself is solid: the
            # background, the boots and the mail legs between the hem's teeth are see-through,
            # so the model's hem is cut to the painted ragged edge
            rows = np.arange(y0, y1)[:, None]
            low = np.broadcast_to((v["sole"] - rows) / v["ppm"] < 0.62, fg.shape)
            alpha[(~cloth_mask(sheet[y0:y1, x0:x1])) & low] = 0.0
        rgba = np.dstack([crop, alpha])
        if v["flip"]:
            rgba = rgba[:, ::-1]
        # resize colour and alpha apart: an RGBA resize would blacken the colour under alpha 0
        rgb_im = Image.fromarray(np.clip(rgba[..., :3], 0, 255).astype(np.uint8), "RGB")
        a_im = Image.fromarray(rgba[..., 3].astype(np.uint8), "L")
        size = (rgb_im.width * K, rgb_im.height * K)
        im = Image.merge("RGBA", (*rgb_im.resize(size, Image.LANCZOS).split(), a_im.resize(size, Image.LANCZOS)))
        px, py = PLACE[name]
        atlas[py:py + im.height, px:px + im.width] = np.asarray(im)
        d = {"ox": px, "oy": py, "w": im.width, "h": im.height}
        if "cx" in v:
            cx = v["cx"] - x0
            if v["flip"]:
                cx = (x1 - x0 - 1) - cx
            d.update({"cx": cx * K, "sole": (v["sole"] - y0) * K, "ppm": v["ppm"] * K})
        else:
            d.update({"x0": x0, "y0": y0})
        info[name] = d
    Image.fromarray(atlas.astype(np.uint8), "RGBA").save(os.path.join(OUT, "wk_views.webp"), quality=92, exact=True)

    # seamless tiles from the detail panels
    save_tile("wk_chainmail", sheet[542:742, 856:980], (256, 256), 7.0, 1.05, 30.0)

    with open(GD, "w") as f:
        f.write("extends RefCounted\n")
        f.write("## Made by tools/white_knight_textures.py: where each picture of the owner's sheet sits in\n")
        f.write("## textures/wk_views.webp (atlas pixels). Body views: cx = centre line, sole = the y = 0\n")
        f.write("## line, ppm = atlas pixels per metre. Helm close-ups: x0 / y0 = the sheet pixel of the\n")
        f.write("## panel's corner (the helm fit in white_knight.gd is in sheet pixels; K = upscale).\n\n")
        f.write("const SIZE := Vector2(%d, %d)\n" % ATLAS)
        f.write("const K := %d\n" % K)
        f.write("const VIEWS := {\n")
        for name, d in info.items():
            items = ", ".join('"%s": %s' % (k, float(val)) for k, val in d.items())
            f.write('\t"%s": {%s},\n' % (name, items))
        f.write("}\n")
    print("wrote", OUT, "and", GD)


if __name__ == "__main__":
    main()
