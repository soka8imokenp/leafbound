# Stitch the four screen-grab tiles of a Gemini portrait (765x1024 source) back into one image.
#   stitch_tiles.py out.png t0 t1 t2 t3
# Each grab is cropped to its non-white content first, so a grab taken at a different browser zoom still fits.
import sys
import numpy as np
from PIL import Image

def tile(path, sw, sh):
    im = Image.open(path).convert('RGB')
    a = np.array(im)
    m = (a < 248).any(-1)                                   # anything that is not the white page
    ys, xs = np.where(m)
    im = im.crop((xs.min(), ys.min(), xs.max() - 1, ys.max() - 1))   # drop the half-white edge row/column
    return im.resize((sw, sh), Image.LANCZOS)

out = Image.new('RGB', (765, 1024), (255, 0, 255))
dims = [(512, 512, 0, 0), (253, 512, 512, 0), (512, 512, 0, 512), (253, 512, 512, 512)]
for p, (sw, sh, x, y) in zip(sys.argv[2:6], dims):
    out.paste(tile(p, sw, sh), (x, y))
for dx in (763, 764):                                     # the very last columns can keep a white fringe: repeat the clean one
    out.paste(out.crop((762, 0, 763, 1024)), (dx, 0))
out.paste(out.crop((0, 1021, 765, 1022)), (0, 1022)); out.paste(out.crop((0, 1021, 765, 1022)), (0, 1023))
out.save(sys.argv[1]); print(out.size)
