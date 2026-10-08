# Room background v2: the EMPTY room drawn by Gemini from our concept (same composition, pixel-aligned, no furniture)
# + the few concept objects we keep as part of the picture (nightstand with the radio, shelf, rug, scarf, slippers),
# cut out of the old concept by their difference from the empty room.  The bed, table, stove and cat are the
# hand-drawn Aseprite sprites placed on top in Godot.
#   source/gemini/room_empty_gemini.png  (1024, empty room)       art/room_k4.0.png  (old concept, 256 px)
import sys; sys.path.insert(0, 'tools')
from pix import *
from PIL import Image
from scipy import ndimage

new = Image.open('source/gemini/room_empty_gemini.png').convert('RGB').resize((256, 256), Image.BOX)
old = Image.open('art/room_k4.0.png').convert('RGB')
a = np.array(new).astype(np.int32)
b = np.array(old).astype(np.int32)

# Gemini's sparkle watermark (bottom right) -> the backdrop colour
edge = np.concatenate([a[:6].reshape(-1, 3), a[-6:].reshape(-1, 3), a[:, :6].reshape(-1, 3), a[:, -6:].reshape(-1, 3)])
bgc = np.median(edge, 0).astype(np.int32)
a[236:255, 236:255] = bgc

# the two renderings differ a little in tone: measured on a clean wall patch, applied to everything pasted from the old one
TONE = np.median((b[70:100, 150:190] - a[70:100, 150:190]).reshape(-1, 3), 0)
print('tone offset old-new', TONE.round(1))

# objects to keep: (name, bbox x0,y0,x1,y1 in room pixels)
KEEP = [('shelf', (196, 84, 240, 200), 36),
        ('rug', (136, 126, 198, 160), 55), ('scarf', (28, 180, 48, 216), 55)]
d = np.abs(ndimage.uniform_filter(a.astype(float), size=(3, 3, 1)) - ndimage.uniform_filter(b.astype(float), size=(3, 3, 1))).sum(-1)
diff_all = ndimage.binary_closing(np.abs(ndimage.uniform_filter(b - TONE, size=(3, 3, 1)) - ndimage.uniform_filter(a, size=(3, 3, 1))).sum(-1) > 30, iterations=1)
for name, (x0, y0, x1, y1), thr in KEEP:
    diff = ndimage.binary_closing(d > thr, iterations=2)
    m = np.zeros(diff.shape, bool); m[y0:y1, x0:x1] = diff[y0:y1, x0:x1]
    lab, n = ndimage.label(m)
    if n == 0: continue
    sizes = ndimage.sum(m, lab, range(1, n + 1))
    keep_ids = [i + 1 for i in range(n) if sizes[i] >= 40]
    m = ndimage.binary_fill_holes(np.isin(lab, keep_ids))
    m = ndimage.binary_dilation(m, iterations=1)
    a[m] = np.clip(b[m] - TONE, 0, 255)
    print(name, int(m.sum()), 'px kept')
# nightstand + radio + cable: solid parts as rectangles, the radio handle and the cable loops from the difference mask
def rect(m, x0, y0, x1, y1): m[y0:y1, x0:x1] = True
ns = np.zeros(diff_all.shape, bool)
for r in [(104, 83, 133, 97), (100, 93, 132, 104), (101, 103, 131, 121), (101, 120, 107, 130), (125, 120, 131, 130)]:
    rect(ns, *r)
for (x0, y0, x1, y1) in [(103, 74, 134, 84), (131, 92, 144, 110)]:
    ns[y0:y1, x0:x1] |= diff_all[y0:y1, x0:x1]
ns = ndimage.binary_fill_holes(ndimage.binary_closing(ns, iterations=1))
a[ns] = np.clip(b[ns] - TONE, 0, 255)
print('nightstand+radio', int(ns.sum()), 'px kept')

# slippers: dark pixels of the old pair, moved 22 px right so the table sprite does not cover them
sh = b[206:227, 127:153]
for y in range(sh.shape[0]):
    for x in range(sh.shape[1]):
        if sh[y, x].sum() < 330: a[206 + y, 127 + x + 22] = sh[y, x]

# palette: one 48-colour palette for the whole picture, like before
q = Image.fromarray(a.astype(np.uint8)).quantize(48, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert('RGBA')
out = np.array(q).astype(np.int32)
# backdrop around the cabin -> transparent (it floats in the game's own dark)
mask = np.abs(out[..., :3] - bgc).sum(-1) < 34
lab, n = ndimage.label(mask)
border = set(lab[0, :]) | set(lab[-1, :]) | set(lab[:, 0]) | set(lab[:, -1]); border.discard(0)
out[np.isin(lab, list(border)), 3] = 0
save(out, 'art/room_bg.png')
print('room_bg.png written; backdrop', bgc)
