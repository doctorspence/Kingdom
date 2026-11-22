"""Heightfields for the first three zones of Kingdom.

Coordinates match ZoneTerrain: meters, x = east, z = south (north is -z),
origin at the zone centre. Heights are absolute meters above the Tithelands
river, so the three zones line up when you walk from one into the next.
"""
import numpy as np

RNG_SEED = 7


# ---------------------------------------------------------------- helpers
def grid(size, cell=1.0):
    half = size / 2
    xs = np.arange(-half, half + 0.001, cell)
    X, Z = np.meshgrid(xs, xs)  # row = z (north at row 0), col = x
    return X, Z


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def _value_noise(X, Z, freq, seed):
    rng = np.random.default_rng(seed)
    n = 257
    table = rng.random((n, n))
    u = (X * freq) % (n - 1)
    v = (Z * freq) % (n - 1)
    i0 = np.floor(u).astype(int)
    j0 = np.floor(v).astype(int)
    fu = u - i0
    fv = v - j0
    fu = fu * fu * (3 - 2 * fu)
    fv = fv * fv * (3 - 2 * fv)
    a = table[j0, i0]
    b = table[j0, i0 + 1]
    c = table[j0 + 1, i0]
    d = table[j0 + 1, i0 + 1]
    return (a * (1 - fu) + b * fu) * (1 - fv) + (c * (1 - fu) + d * fu) * fv


def fbm(X, Z, freq, octaves=4, seed=RNG_SEED):
    """Fractal noise in roughly [-1, 1]."""
    total = np.zeros_like(X)
    amp, f, norm = 1.0, freq, 0.0
    for o in range(octaves):
        total += amp * (_value_noise(X + 1000, Z + 1000, f, seed + o) * 2 - 1)
        norm += amp
        amp *= 0.5
        f *= 2.0
    return total / norm


def polyline_info(X, Z, pts):
    """Distance to a polyline and the distance travelled along it at the closest point."""
    pts = np.asarray(pts, float)
    best = np.full(X.shape, np.inf)
    along = np.zeros(X.shape)
    run = 0.0
    for (ax, az), (bx, bz) in zip(pts[:-1], pts[1:]):
        dx, dz = bx - ax, bz - az
        L2 = dx * dx + dz * dz
        L = np.sqrt(L2)
        t = np.clip(((X - ax) * dx + (Z - az) * dz) / L2, 0, 1)
        px, pz = ax + t * dx, az + t * dz
        d = np.hypot(X - px, Z - pz)
        m = d < best
        best[m] = d[m]
        along[m] = run + t[m] * L
        run += L
    return best, along


def path_length(pts):
    pts = np.asarray(pts, float)
    return np.concatenate([[0], np.cumsum(np.hypot(*np.diff(pts, axis=0).T))])


def gauss(X, Z, cx, cz, r, h):
    d2 = ((X - cx) ** 2 + (Z - cz) ** 2) / (r * r)
    return h * np.exp(-d2 * 2.0)


def carve_channel(H, X, Z, pts_elev, bed_half, bank_half, sharp=1.0):
    """Cut a river or gorge: the bed follows the given elevations (monotone downhill),
    the banks blend back into the land. Returns the new heights and the water surface."""
    pts = [(p[0], p[1]) for p in pts_elev]
    el = np.array([p[2] for p in pts_elev], float)
    d, s = polyline_info(X, Z, pts)
    bed = np.interp(s, path_length(pts), el)
    t = 1 - smoothstep(bed_half, bank_half, d) ** sharp
    newH = np.where(H > bed, H * (1 - t) + bed * t, H)
    return newH, bed, d


def flatten_path(H, X, Z, pts, half_w, blend):
    """Roads: ease the ground toward a smoothed version along the path."""
    d, s = polyline_info(X, Z, pts)
    t = 1 - smoothstep(half_w, half_w + blend, d)
    # Smooth target: average of the local ground (cheap blur).
    from scipy.ndimage import uniform_filter
    smooth = uniform_filter(H, size=int(half_w * 3) | 1)
    return H * (1 - t) + smooth * t


def terrace(H, step, riser=0.25):
    """Stepped ground: flat treads and short steep risers (city streets, quarry benches)."""
    q = H / step
    f = q - np.floor(q)
    stepped = np.floor(q) + smoothstep(1 - riser, 1.0, f)
    return stepped * step


def mask_poly(X, Z, poly):
    from matplotlib.path import Path
    p = Path(np.asarray(poly))
    pts = np.column_stack([X.ravel(), Z.ravel()])
    return p.contains_points(pts).reshape(X.shape)


def soft_mask(mask, blur):
    from scipy.ndimage import gaussian_filter
    return np.clip(gaussian_filter(mask.astype(float), blur), 0, 1)
