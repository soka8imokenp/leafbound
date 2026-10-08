# Gemini profile drawings (2000 px, drawn on a 128 grid) -> clean 128x128 frames in Anzu's palette,
# white background and baked ground shadow removed, flipped to face right (the game mirrors for left).
import sys, os; sys.path.insert(0, 'tools')
from pix import *
from PIL import Image

K, D, R, O, S, G = (7, 1, 1), (81, 35, 39), (193, 61, 41), (241, 132, 48), (244, 213, 193), (132, 178, 87)
PAL = [K, D, R, O, S, G, (255, 255, 255)]                    # white = background


def to_grid(path):
    a = np.array(Image.open(path).convert('RGB')).astype(np.float32)
    STEP = a.shape[1] / 128.0                       # 2000 px originals or 1024 px screen-grabs alike
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


def despeckle(f, min_area=14):
    """delete detached fragments: opaque blobs (8-neighbour, bridged over a 1 px gap) smaller than min_area"""
    from scipy import ndimage
    m = f[..., 3] > 0
    lab, n = ndimage.label(ndimage.binary_dilation(m, structure=np.ones((3, 3))))
    for k in range(1, n + 1):
        blob = (lab == k) & m
        if blob.sum() < min_area:
            f[blob] = 0
    return f


def tidy(f):
    """outline discipline: (1) pixels sitting just OUTSIDE the dark outline are JPEG fringe -> erase;
    (2) holes enclosed by the sprite (the white eye highlights read as background) -> her highlight colour"""
    from scipy import ndimage
    for _ in range(2):
        m = f[..., 3] > 0
        for y in range(1, 127):
            for x in range(1, 127):
                if not m[y, x] or tuple(f[y, x, :3]) == K: continue
                for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                    if not m[y + dy, x + dx] and m[y - dy, x - dx] and tuple(f[y - dy, x - dx, :3]) == K:
                        f[y, x] = 0
                        break
    m = f[..., 3] > 0
    for y, x in zip(*np.where(ndimage.binary_fill_holes(m) & ~m)):
        f[y, x] = (*S, 255)
    return f


def isolated(f, keep=(60, 36, 100, 56)):
    """one-pixel noise: a pixel whose colour appears in none of its 8 neighbours becomes the neighbours' most
    common colour (the eye box is left alone, its highlights are meant to be single pixels)"""
    from collections import Counter
    x0, y0, x1, y1 = keep
    g = f.copy()
    for y in range(1, 127):
        for x in range(1, 127):
            if not f[y, x, 3] or (x0 <= x <= x1 and y0 <= y <= y1): continue
            c = tuple(f[y, x, :3])
            nb = [tuple(f[y + dy, x + dx, :3]) for dy in (-1, 0, 1) for dx in (-1, 0, 1)
                  if (dy or dx) and f[y + dy, x + dx, 3]]
            if len(nb) >= 4 and c not in nb:
                g[y, x, :3] = Counter(nb).most_common(1)[0][0]
    f[:] = g
    return f


def strays(f, y_min=106):
    """eraser pass: below the knee a skin-coloured pixel with 2+ empty 4-neighbours is a JPEG leftover, not boot"""
    for _ in range(3):
        m = f[..., 3] > 0
        for y in range(y_min, 128):
            for x in range(1, 127):
                if m[y, x] and tuple(f[y, x, :3]) == S:
                    empty = (not m[y - 1, x]) + (not m[y + 1, x]) + (not m[y, x - 1]) + (not m[y, x + 1])
                    if empty >= 2: f[y, x] = 0
    return f


def bob(f, dy):
    g = np.zeros_like(f); g[:100] = np.roll(f, dy, 0)[:100]; g[100:] = f[100:]
    if dy < 0: g[100 + dy:100] = np.where(g[100 + dy:100, ..., 3:4] > 0, g[100 + dy:100], f[100 + dy:100])
    return g


def frames():
    stand = tidy(strays(despeckle(clean_green(drop_shadow(to_grid('source/gemini/side_stand.jpg'))[:, ::-1].copy()))))
    walk = tidy(strays(despeckle(clean_green(drop_shadow(to_grid('source/gemini/side_walk.jpg'))[:, ::-1].copy()))))
    # One step pose only: a mirrored second one put the boots toe-backward. For a real second step
    # ask Gemini for the opposite contact pose and save it as source/gemini/side_walk2.jpg.
    walk2 = walk
    if os.path.exists('source/gemini/side_walk2.jpg'):
        walk2 = isolated(tidy(strays(despeckle(clean_green(drop_shadow(to_grid('source/gemini/side_walk2.jpg'))[:, ::-1].copy())))))
    return {'side_idle': [stand, bob(stand, 2)],
            'side_walk': [walk, bob(stand, -2), bob(walk2, -1) if walk2 is walk else walk2, bob(stand, -2)]}
