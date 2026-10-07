# Room background: pixelized concept (1024 -> 256, 48-colour palette) with the objects that become
# separate hand-drawn sprites erased, steam puffs/vase/watermark removed, shoes moved off the table.
import sys; sys.path.insert(0, 'tools')
from pix import *
from PIL import Image

im = Image.open('source/photo_2026-10-07_13-12-57.jpg').convert('RGB').resize((256, 256), Image.BOX)
q = im.quantize(48, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert('RGBA')
a = np.array(q).astype(np.int32)

def fill(x0, y0, x1, y1, mode):
    """erase [x0,x1)x[y0,y1) and fill from the nearest clean pixel in the given direction"""
    src = a.copy()
    for y in range(y0, y1):
        for x in range(x0, x1):
            if mode == 'left':  a[y, x] = src[y, x0 - 1]
            elif mode == 'right': a[y, x] = src[y, x1]
            elif mode == 'up':  a[y, x] = src[y0 - 1, x]
            elif mode == 'down': a[y, x] = src[y1, x]
            elif mode == 'h':   a[y, x] = src[y, x0 - 1] if x - x0 < x1 - x else src[y, x1]

# stove: wall rows from the sides, floor strips beside the new sprite
fill(142, 66, 155, 92, 'left'); fill(166, 66, 184, 92, 'right'); fill(155, 76, 166, 92, 'h')
fill(142, 92, 184, 130, 'h')
# steam puffs on / right of the chimney
fill(166, 42, 172, 70, 'right'); fill(155, 44, 166, 76, 'up')
# vase standing above the new (bigger) table
fill(70, 168, 100, 188, 'up')
# shoes: move 22 px right so the table does not swallow them
shoes = a[206:227, 127:153].copy()
fill(127, 206, 153, 227, 'up')
for y in range(shoes.shape[0]):
    for x in range(shoes.shape[1]):
        p = shoes[y, x]
        if p[:3].sum() < 330:            # dark shoe pixels only, floor stays
            a[206 + y, 149 + x] = p
# Gemini watermark
a[232:252, 232:252] = a[252, 252]
save(a, 'art/room_bg.png')
print('ok')
