# Anzu frames at her NATIVE 128x128 resolution (the original art, no redraw).
# Shown at 0.5 scale in the room, so every original pixel stays visible on screen.
# Rows: down_idle, down_walk, up_idle, up_walk, side_idle, side_walk (4 columns, 128x128 each).
import sys; sys.path.insert(0, 'tools')
from pix import *

K, D, R, O, S, G = (7, 1, 1), (81, 35, 39), (193, 61, 41), (241, 132, 48), (244, 213, 193), (132, 178, 87)
BOOT_L, BOOT_R = (50, 59), (69, 77)
SOLE = 121

base = load('art/anzu_native.png')
base[base[..., 3] > 0, 3] = 255
# --- cut the baked ground shadow, keep the boots down to the sole
for y in range(117, 128):
    for x in range(128):
        inside = BOOT_L[0] <= x <= BOOT_L[1] or BOOT_R[0] <= x <= BOOT_R[1]
        if not inside or y > SOLE:
            base[y, x] = 0
            continue
        edge = x in (BOOT_L[0], BOOT_L[1], BOOT_R[0], BOOT_R[1]) or y == SOLE
        base[y, x] = (*K, 255) if edge else (*D, 255)
FEET = SOLE


def shift_block(a, y0, y1, x0, x1, dy=0, dx=0):
    blk = a[y0:y1, x0:x1].copy()
    a[y0:y1, x0:x1] = 0
    for i in range(blk.shape[0]):
        for j in range(blk.shape[1]):
            if blk[i, j, 3]:
                Y, X = y0 + i + dy, x0 + j + dx
                if 0 <= Y < 128 and 0 <= X < 128: a[Y, X] = blk[i, j]
    return a


def bob(a, dy):
    """head + torso move, legs stay (rows above the knee line)"""
    return shift_block(a.copy(), 0, 99, 0, 128, dy=dy)


def lift(a, side, h):
    """raise one leg (sock + boot) by h px; the sock top slides under the skirt"""
    a = a.copy()
    x0, x1 = (48, 62) if side == 'L' else (66, 80)
    legs = a[99:FEET + 1, x0:x1].copy()
    a[99:FEET + 1, x0:x1] = 0
    for i in range(legs.shape[0]):
        Y = 99 + i - h
        if Y < 99: continue
        m = legs[i, :, 3] > 0
        a[Y, x0:x1][m] = legs[i][m]
    return a


# ---- back view: mirror; below the crown the whole head interior is repainted as broad strands
import math
back = base[:, ::-1].copy()
CROWN = (64.0, 4.0)
def edge(y, x):
    return any(back[y + dy, x + dx, 3] == 0 for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
ys_, xs_ = np.where(back[:60, :, 3] > 0)
for y, x in zip(ys_, xs_):
    if y < 24: continue
    c0 = tuple(back[y, x, :3])
    if (c0 == G and y < 36) or (c0 == K and edge(y, x)): continue
    if c0 in (D, K) and x < 46 and y < 36: continue                # hair-clip knot stays
    if y >= 58: continue
    ang = math.atan2(x - CROWN[0], y - CROWN[1])
    k = ang * 9.0 + 0.35 * math.sin(ang * 23.0) + 0.2 * math.sin(ang * 51.0)
    frac = k - math.floor(k)
    c = O
    if frac < 0.14: c = R                                          # strand separation
    if x > 78 and frac > 0.55: c = R                               # shadow side
    if y >= 52 and frac < 0.45: c = R                              # tips
    if y >= 55 and frac < 0.2: c = D
    back[y, x, :3] = c
for y in range(58, 64):                                            # neck hidden by hair
    for x in range(40, 90):
        if back[y, x, 3] and tuple(back[y, x, :3]) == S: back[y, x, :3] = R

# ---- side (3/4 to the right): her own face, eyes and mouth glance 2 px toward the step
side = base.copy()
feat = side[36:56, 46:84].copy()
for y in range(36, 56):
    for x in range(49, 82):
        p = feat[y - 36, x - 46]
        if p[3] and tuple(p[:3]) != S and not (y < 40 and tuple(p[:3]) in (O, R)):
            side[y, x, :3] = S                                 # clear features to skin
for y in range(36, 56):
    for x in range(49, 82):
        p = feat[y - 36, x - 46]
        if p[3] and tuple(p[:3]) != S and not (y < 40 and tuple(p[:3]) in (O, R)):
            side[y, x + 2] = p

# ---- hand-drawn profile: art/anzu_side.aseprite, layer "Draw" (6 frames: idle 0-1, walk 2-5)
import os, ase_dump
drawn = []
if os.path.exists('art/anzu_side.aseprite'):
    ase = ase_dump.read('art/anzu_side.aseprite')
    for i in range(len(ase['frames'])):
        im = ase_dump.render_layer(ase, i, 'Draw')
        drawn.append(None if im is None else np.array(im).astype(np.int32))
use_drawn = len(drawn) >= 6 and all(d is not None and d[..., 3].any() for d in drawn)
if use_drawn:
    print('side frames: hand-drawn profile from art/anzu_side.aseprite')

# ---- Gemini profile drawings (source/gemini/side_*.jpg), used when there is no hand-drawn profile
gem = None
if not use_drawn and os.path.exists('source/gemini/side_stand.jpg') and os.path.exists('source/gemini/side_walk.jpg'):
    import gemini_side
    gem = gemini_side.frames()
    print('side frames: Gemini profile (source/gemini)')

rows = [
    ('down_idle', [base, bob(base, 2)]),
    ('down_walk', [lift(base, 'L', 4), bob(base, -2), lift(base, 'R', 4), bob(base, -2)]),
    ('up_idle', [back, bob(back, 2)]),
    ('up_walk', [lift(back, 'L', 4), bob(back, -2), lift(back, 'R', 4), bob(back, -2)]),
    ('side_idle', drawn[0:2] if use_drawn else gem['side_idle'] if gem else [side, bob(side, 2)]),
    ('side_walk', drawn[2:6] if use_drawn else gem['side_walk'] if gem else
                  [shift_block(lift(side, 'L', 4), 99, 122, 66, 80, dx=3), bob(side, -2),
                   shift_block(lift(side, 'R', 4), 99, 122, 48, 62, dx=3), bob(side, -2)]),
]
sheet = np.zeros((128 * len(rows), 128 * 4, 4), np.int32)
for r, (name, fr) in enumerate(rows):
    for i, f in enumerate(fr):
        sheet[r * 128:(r + 1) * 128, i * 128:(i + 1) * 128] = f
save(sheet, 'art/anzu_sheet_hd.png')
print('feet row', FEET, 'sheet', sheet.shape)
