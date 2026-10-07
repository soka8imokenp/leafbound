# Menu assets from the mockup: clean background (buttons painted over with nearby grass),
# 4 wooden buttons with alpha + hover/pressed variants, leaf/mote particle textures.
import sys; sys.path.insert(0, 'tools')
from pix import *
from PIL import Image, ImageEnhance
from scipy import ndimage

wood = np.array(Image.open('source/кнопки и текст как должны выглядить.png').convert('RGB')).astype(np.int32)
H, W = wood.shape[:2]
BTN = [(475, 551), (569, 645), (662, 738), (756, 830)]      # y ranges, x 108..303
X0, X1 = 100, 312

# background under the button column: copy the same rows from 215 px to the right, blend the seam
bg = wood.copy()
y0, y1 = 465, 842
src = wood[y0:y1, X0 + 215:X1 + 215]
bg[y0:y1, X0:X1] = src
for i in range(10):                                   # soft left/right seams
    a = (i + 1) / 11
    bg[y0:y1, X0 + i] = (wood[y0:y1, X0 + i] * (1 - a) + src[:, i] * a).astype(np.int32)
    bg[y0:y1, X1 - 1 - i] = (wood[y0:y1, X1 - 1 - i] * (1 - a) + src[:, -1 - i] * a).astype(np.int32)
Image.fromarray(bg.astype(np.uint8)).save('art/menu/bg.png')

# button alpha: differs from the cleaned background, filled, slightly grown
for k, (ya, yb) in enumerate(BTN):
    ya -= 4; yb += 5; xa, xb = 102, 310
    crop = wood[ya:yb, xa:xb]
    d = np.abs(crop - bg[ya:yb, xa:xb]).sum(-1) > 45
    d = ndimage.binary_closing(d, iterations=3)
    d = ndimage.binary_fill_holes(d)
    lab, n = ndimage.label(d); sizes = ndimage.sum(d, lab, range(1, n + 1))
    d = lab == (1 + int(np.argmax(sizes)))
    d = ndimage.binary_dilation(d, iterations=1)
    rgba = np.dstack([crop, d * 255]).astype(np.uint8)
    im = Image.fromarray(rgba, 'RGBA')
    im.save(f'art/menu/btn{k}.png')
    hov = ImageEnhance.Brightness(im.convert('RGB')).enhance(1.18).convert('RGBA'); hov.putalpha(im.getchannel('A'))
    hov.save(f'art/menu/btn{k}_hover.png')
    pr = ImageEnhance.Brightness(im.convert('RGB')).enhance(0.82).convert('RGBA'); pr.putalpha(im.getchannel('A'))
    pr.save(f'art/menu/btn{k}_pressed.png')
    print(k, (xa, ya), im.size, int(d.sum()))

# particles: pixel leaf 7x5 and a soft mote
leaf = np.zeros((5, 7, 4), np.int32)
L, Dk, Hi = (110, 160, 70, 255), (62, 104, 46, 255), (160, 200, 100, 255)
for y, row in enumerate(['..LLL..', '.LLHLL.', 'LLLHLLD', '.LLLLD.', '..DD...']):
    for x, ch in enumerate(row):
        if ch != '.': leaf[y, x] = {'L': L, 'D': Dk, 'H': Hi}[ch]
save(leaf, 'art/menu/leaf.png')
mote = np.zeros((2, 2, 4), np.int32); mote[:] = (255, 250, 220, 255); save(mote, 'art/menu/mote.png')

# ---- v2: keep the original mockup as background (buttons sit exactly on their baked copies)
orig = np.array(Image.open('source/кнопки и текст как должны выглядить.png').convert('RGB')).astype(np.int32)
for k in range(4):
    im = Image.open(f'art/menu/btn{k}.png')
    dis = ImageEnhance.Brightness(ImageEnhance.Color(im.convert('RGB')).enhance(0.3)).enhance(0.6).convert('RGBA')
    dis.putalpha(im.getchannel('A')); dis.save(f'art/menu/btn{k}_disabled.png')

# logo leaf as its own sprite: saturated greens in the leaf box, hole in the background inpainted
x0, y0, x1, y1 = 380, 80, 645, 262
box = orig[y0:y1, x0:x1].astype(float)
mx, mn = box.max(-1), box.min(-1)
sat = (mx - mn) / np.maximum(mx, 1)
leafm = (sat > 0.28) | ((mx < 90) & (sat > 0.15))          # leaf body + dark outline
leafm = ndimage.binary_closing(leafm, iterations=2)
leafm = ndimage.binary_fill_holes(leafm)
lab, n = ndimage.label(leafm); sizes = ndimage.sum(leafm, lab, range(1, n + 1))
leafm = lab == (1 + int(np.argmax(sizes)))
leafm = ndimage.binary_dilation(leafm, iterations=2)
Image.fromarray(np.dstack([orig[y0:y1, x0:x1], leafm * 255]).astype(np.uint8), 'RGBA').save('art/menu/logo_leaf.png')
bg2 = orig.astype(float).copy()
hole = np.zeros(orig.shape[:2], bool); hole[y0:y1, x0:x1] = leafm
for it in range(400):                                          # harmonic fill of the hole
    sm = (np.roll(bg2, 1, 0) + np.roll(bg2, -1, 0) + np.roll(bg2, 1, 1) + np.roll(bg2, -1, 1)) / 4
    bg2[hole] = sm[hole]
Image.fromarray(bg2.astype(np.uint8)).save('art/menu/bg.png')
print('leaf px', int(leafm.sum()), 'bbox', (x0, y0))

# blank plank (button without its text) for panels / pause buttons
pl = np.array(Image.open('art/menu/btn2.png')).astype(np.int32)
h, w = pl.shape[:2]
lum = pl[..., :3].mean(-1)
txt = np.zeros((h, w), bool); txt[22:62, 18:w - 18] = lum[22:62, 18:w - 18] < 120
txt = ndimage.binary_dilation(txt, iterations=2) & (pl[..., 3] > 0)
txt[:, :14] = False; txt[:, w - 14:] = False
for y in range(h):
    for x in range(w):
        if txt[y, x]:
            xl = x
            while xl > 0 and txt[y, xl]: xl -= 1
            pl[y, x] = pl[y, xl]
save(pl, 'art/menu/plank.png')
hv = Image.open('art/menu/plank.png'); hb = ImageEnhance.Brightness(hv.convert('RGB')).enhance(1.15).convert('RGBA'); hb.putalpha(hv.getchannel('A')); hb.save('art/menu/plank_hover.png')
