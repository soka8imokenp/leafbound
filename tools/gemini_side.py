# Gemini profile drawings (2000 px, drawn on a 128 grid) -> clean 128x128 frames in Anzu's palette,
# white background and baked ground shadow removed, flipped to face right (the game mirrors for left).
import sys; sys.path.insert(0, 'tools')
from pix import *
from PIL import Image

K, D, R, O, S, G = (7, 1, 1), (81, 35, 39), (193, 61, 41), (241, 132, 48), (244, 213, 193), (132, 178, 87)
PAL = [K, D, R, O, S, G, (255, 255, 255)]                    # white = background
STEP = 2000 / 128


def to_grid(path):
    a = np.array(Image.open(path).convert('RGB')).astype(np.float32)
    out = np.zeros((128, 128, 4), np.int32)
    pal = np.array(PAL, np.float32)
    for gy in range(128):
        for gx in range(128):
            y0, x0 = int(gy * STEP + STEP * 0.3), int(gx * STEP + STEP * 0.3)
            blk = a[y0:int(y0 + STEP * 0.4), x0:int(x0 + STEP * 0.4)].reshape(-1, 3)
            c = np.median(blk, 0)
            i = int(np.argmin(((pal - c) ** 2).sum(1)))
            if i == len(PAL) - 1: continue
            out[gy, gx] = (*PAL[i], 255)
    return out


def drop_shadow(f):
    """ground shadow = dark blob under the boots; keep only boot columns, close them with a sole"""
    rows = [y for y in range(100, 128) if f[y, :, 3].any()]
    # sole row: the lowest row that still has light pixels (laces / socks) above the shadow band
    boot_cols = set()
    for y in range(104, 116):
        boot_cols |= set(np.flatnonzero(f[y, :, 3]).tolist())
    sole = 120
    for y in range(116, 128):
        for x in range(128):
            if not f[y, x, 3]: continue
            if y > sole or x not in boot_cols:
                f[y, x] = 0
    for x in sorted(boot_cols):                           # sole outline
        if f[sole - 1, x, 3]: f[sole, x] = (*K, 255)
    return f


if __name__ == '__main__':
    res = {}
    for name in ('side_stand', 'side_walk'):
        g = drop_shadow(to_grid(f'source/gemini/{name}.jpg'))[:, ::-1].copy()   # face right
        save(g, f'art/gemini_{name}.png')
        res[name] = g
        ys, xs = np.where(g[..., 3] > 0)
        print(name, 'bbox', xs.min(), ys.min(), xs.max(), ys.max())
    row = np.concatenate([res['side_stand'], res['side_walk']], 1)
    im = Image.fromarray(row.astype(np.uint8), 'RGBA')
    bg = Image.new('RGBA', im.size, (74, 60, 50, 255)); bg.alpha_composite(im)
    bg.resize((im.width * 3, im.height * 3), Image.NEAREST).save('build/gemini_side_x3.png')


def clean_green(f):
    """JPEG fringe snapped to green: keep green only on the clip, in the eye and on the sock stripes"""
    for y, x in zip(*np.where(f[..., 3] > 0)):
        if tuple(f[y, x, :3]) != G: continue
        if y < 26 or 98 <= y <= 108: continue
        nb = [f[y + dy, x + dx, 3] if 0 <= y + dy < 128 and 0 <= x + dx < 128 else 0
              for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1))]
        if all(nb) and 36 <= y <= 52: continue
        f[y, x, :3] = K if not all(nb) else R
    return f


def swap_legs(f, y0=100, cx=None):
    """other contact pose: legs mirrored around the body centre, each boot turned back toe-forward"""
    g = f.copy()
    legs = f[y0:, :].copy()
    g[y0:, :] = 0
    ys, xs = np.where(legs[..., 3] > 0)
    c = cx if cx is not None else (xs.min() + xs.max()) / 2.0
    for y, x in zip(ys, xs):
        X = int(round(2 * c - x))
        if 0 <= X < 128: g[y0 + y, X] = legs[y, x]
    # turn each boot back: flip every connected blob of the lower boot rows within its own bbox
    from scipy import ndimage
    region = g[108:, :, 3] > 0
    lab, n = ndimage.label(region)
    for k in range(1, n + 1):
        yy, xx = np.where(lab == k)
        x0, x1 = xx.min(), xx.max()
        blk = g[108 + yy.min():108 + yy.max() + 1, x0:x1 + 1].copy()
        msk = (lab[yy.min():yy.max() + 1, x0:x1 + 1] == k)
        flipped, fm = blk[:, ::-1], msk[:, ::-1]
        tgt = g[108 + yy.min():108 + yy.max() + 1, x0:x1 + 1]
        tgt[msk] = 0
        tgt[fm] = flipped[fm]
    return g


def bob(f, dy):
    g = np.zeros_like(f); g[:100] = np.roll(f, dy, 0)[:100]; g[100:] = f[100:]
    if dy < 0: g[100 + dy:100] = np.where(g[100 + dy:100, ..., 3:4] > 0, g[100 + dy:100], f[100 + dy:100])
    return g


def frames():
    stand = clean_green(drop_shadow(to_grid('source/gemini/side_stand.jpg'))[:, ::-1].copy())
    walk = clean_green(drop_shadow(to_grid('source/gemini/side_walk.jpg'))[:, ::-1].copy())
    walk2 = swap_legs(walk)
    return {'side_idle': [stand, bob(stand, 2)],
            'side_walk': [walk, bob(stand, -2), walk2, bob(stand, -2)]}
