# Anzu animation frames (64x64 each) built from the cleaned front sprite:
#   down/up/side x idle(2) + walk(4).  Side = 3/4 turn (face shifted toward the step), left = flipped.
import sys; sys.path.insert(0, 'tools')
from pix import *

K, D, R, O, S, G = (7, 1, 1), (81, 35, 39), (193, 61, 41), (241, 132, 48), (244, 213, 193), (132, 178, 87)
BL = (247, 180, 160)
base = load('art/anzu_front.png')
base[59:62] = 0                       # baked ground shadow -> separate shadow node in Godot
base[58, 30:33] = 0
for x in range(25, 39):               # boots keep their bottom outline
    if base[58, x, 3] and x not in (30, 31, 32): base[58, x, :3] = K

def isc(p, c): return p[3] > 0 and tuple(p[:3]) == c

def shift_rows(a, y0, y1, dy, x0=0, x1=64):
    """move rows [y0,y1) by dy (content only, alpha-aware)"""
    blk = a[y0:y1, x0:x1].copy(); a[y0:y1, x0:x1] = 0
    ys = slice(max(y0 + dy, 0), min(y1 + dy, 64))
    src = blk[max(-dy - (y0 + dy - max(y0 + dy, 0)), 0):][:ys.stop - ys.start] if False else blk
    for i in range(blk.shape[0]):
        y = y0 + i + dy
        if 0 <= y < 64:
            m = blk[i, :, 3] > 0
            a[y, x0:x1][m] = blk[i][m]
    return a

def leg(a, side, lift=0, dx=0):
    """redraw one leg (rows 49..58) lifted by `lift` px and shifted dx"""
    x0, x1 = (24, 31) if side == 'L' else (32, 40)
    blk = a[49:59, x0:x1].copy(); a[49:59, x0:x1] = 0
    for i in range(10):
        y = 49 + i - lift
        if i < lift: continue                     # sock top hidden under the skirt
        m = blk[i, :, 3] > 0
        xs = np.arange(x0, x1) + dx
        for j in np.flatnonzero(m):
            if 0 <= xs[j] < 64: a[y, xs[j]] = blk[i, j]
    return a

def body_bob(a, dy):
    """head+torso (rows 0..48) move dy, legs stay"""
    return shift_rows(a, 0, 49, dy)

# ---------- front (down) ----------
down_idle = [base.copy(), body_bob(base.copy(), 1)]
down_walk = [leg(base.copy(), 'L', 2), body_bob(base.copy(), -1), leg(base.copy(), 'R', 2), body_bob(base.copy(), -1)]

# ---------- back (up): mirror, paint the face over with hair continuing from above ----------
back = base[:, ::-1].copy()
def hair_back(img, y0, y1, x0, x1):
    """back-of-head hair: orange base, darker strands every 4 px, darker toward the tips"""
    for y in range(y0, y1):
        for x in range(x0, x1):
            if img[y, x, 3] == 0: continue
            c = O
            if (x - x0 + (y // 6)) % 4 == 0: c = R
            if y >= y1 - 3 and (x - x0) % 2 == 0: c = R
            if y == y1 - 1 and (x - x0) % 4 == 1: c = D
            img[y, x, :3] = c
hair_back(back, 15, 29, 20, 43)
for y in range(15, 29):                # keep a 1-px dark shade along the silhouette sides
    xs = np.flatnonzero(back[y, :, 3] > 0)
    if len(xs): back[y, xs.min() + 1, :3] = R; back[y, xs.max() - 1, :3] = R
for y in (29, 30, 31):                 # neck hidden by hair
    for x in range(20, 44):
        if isc(back[y, x], S): back[y, x, :3] = R
up_idle = [back.copy(), body_bob(back.copy(), 1)]
up_walk = [leg(back.copy(), 'L', 2), body_bob(back.copy(), -1), leg(back.copy(), 'R', 2), body_bob(back.copy(), -1)]

# ---------- side (right): 3/4 turn ----------
side = base.copy()
def eye(img, x0, w, wing):
    rows = [[K] * w, [K, S] + [K] * (w - 2), [K] * w, [D] + [K] * (w - 2) + [D], [G] + [O] * (w - 2) + [G]]
    for i, r in enumerate(rows):
        for j, c in enumerate(r): img[19 + i, x0 + j, :3] = c; img[19 + i, x0 + j, 3] = 255
    img[19, wing, :3] = K; img[18, wing, :3] = K
for y in range(19, 28):
    for x in range(24, 41):
        if side[y, x, 3] and (tuple(side[y, x, :3]) in (S, G, BL) or (tuple(side[y, x, :3]) in (K, D) and y <= 24)):
            side[y, x, :3] = S
hair_back(side, 19, 28, 22, 27)        # far cheek hidden by hair
eye(side, 28, 3, 27); eye(side, 36, 4, 40)
side[27, 35, :3] = R; side[27, 36, :3] = R
side[25, 39, :3] = BL; side[25, 30, :3] = BL
side_idle = [side.copy(), body_bob(side.copy(), 1)]
side_walk = [leg(leg(side.copy(), 'L', 1, 1), 'R', 0, -1), body_bob(side.copy(), -1),
             leg(leg(side.copy(), 'R', 1, 1), 'L', 0, -1), body_bob(side.copy(), -1)]

rows = [('down_idle', down_idle), ('down_walk', down_walk), ('up_idle', up_idle), ('up_walk', up_walk),
        ('side_idle', side_idle), ('side_walk', side_walk)]
sheet = np.zeros((64 * len(rows), 64 * 4, 4), np.int32)
for r, (name, fr) in enumerate(rows):
    for i, f in enumerate(fr): sheet[r * 64:(r + 1) * 64, i * 64:(i + 1) * 64] = f
save(sheet, 'art/anzu_sheet.png')
save(sheet, '/tmp/claude-1000/-home-soka-Projects-3d-Sumire/ae311678-f4bc-4b71-8cde-1148f9806f08/scratchpad/anzu_sheet_x4.png', 4)
print('rows', [n for n, _ in rows])
