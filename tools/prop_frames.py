# Animated props: cat breathing (4 frames), stove fire flicker (4 frames), tiny particle textures.
import sys; sys.path.insert(0, 'tools')
from pix import *
rng = np.random.default_rng(7)

# ---- cat: inhale = back (x>=13, rows 1..16) rises 1 px, row 16 duplicated so no gap
cat = load('art/ase/cat_0.png')
inh = cat.copy()
for x in range(13, 32):
    col = cat[:, x].copy()
    for y in range(0, 16): inh[y, x] = col[y + 1]
frames = [cat, inh, inh, cat]           # slow in, hold, out (timing in Godot)
sheet = np.concatenate(frames, 1); save(sheet, 'art/cat_breath.png')

# ---- stove fire: recolour the fire window pixels each frame
st = load('art/ase/pechka_0.png')
fire = [(y, x) for y in range(33, 44) for x in range(8, 22)
        if st[y, x, 3] and st[y, x, 0] > 150 and st[y, x, 0] - st[y, x, 2] > 60]
glow_win = [(y, x) for y in range(34, 43) for x in range(9, 21)
            if st[y, x, 3] and st[y, x, :3].sum() < 120]          # dark inside the window
PAL = [(120, 34, 22), (196, 74, 30), (238, 122, 44), (250, 186, 84), (255, 226, 150)]
out = []
for f in range(4):
    a = st.copy()
    for (y, x) in fire:
        h = (43 - y) / 10                                        # hotter at the bottom
        v = 1.2 + 2.2 * (1 - h) + rng.normal(0, 0.9)
        a[y, x, :3] = PAL[int(np.clip(round(v), 0, 4))]
    for (y, x) in glow_win:                                       # a few embers flicker in the dark
        if rng.random() < 0.12: a[y, x, :3] = PAL[rng.integers(0, 2)]
    out.append(a)
save(np.concatenate(out, 1), 'art/stove_fire.png')
print('fire px', len(fire), 'glow px', len(glow_win))

# ---- particle textures
dot = np.zeros((2, 2, 4), np.int32); dot[:] = (255, 255, 255, 255); save(dot, 'art/px2.png')
z = np.zeros((5, 5, 4), np.int32)
for (y, x) in [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (1, 3), (2, 2), (3, 1), (4, 0), (4, 1), (4, 2), (4, 3), (4, 4)]:
    z[y, x] = (255, 255, 255, 255)
save(z, 'art/z.png')
heart = np.zeros((5, 5, 4), np.int32)
for y, row in enumerate(['.X.X.', 'XXXXX', 'XXXXX', '.XXX.', '..X..']):
    for x, ch in enumerate(row):
        if ch == 'X': heart[y, x] = (235, 90, 90, 255)
save(heart, 'art/heart.png')
