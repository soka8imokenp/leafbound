# Cut an illustrated portrait out of its flat magenta background (soft matte + despill) and crop to the figure.
#   portrait_cut.py in.png out.png [target_height]
import sys
import numpy as np
from PIL import Image, ImageFilter

def cut(img):
    a = np.array(img.convert('RGB')).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mag = np.clip((np.minimum(r, b) - g) / 255.0, 0, 1)             # magenta-ness: ~1 on the backdrop, ~0 on skin/hair/leaf
    alpha = 1.0 - np.clip((mag - 0.30) / 0.30, 0, 1)                # soft edge between 0.30 and 0.60
    # despill: remove the pink glow that bleeds into the anti-aliased outline
    spill = np.clip(mag, 0, 1) * (alpha > 0)
    g2 = g + 0 * spill
    cap = np.maximum(g, 0.55 * (r + b) / 2 * (1 - alpha) + g * alpha)
    rr = np.where(alpha < 1, np.minimum(r, g * 1.0 + (r - g) * alpha), r)
    bb = np.where(alpha < 1, np.minimum(b, g * 1.0 + (b - g) * alpha), b)
    rgb = np.dstack([rr, g, bb])
    al = Image.fromarray((alpha * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.6))
    out = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8)).convert('RGBA')
    out.putalpha(al)
    return out

if __name__ == '__main__':
    im = cut(Image.open(sys.argv[1]))
    if '--frame' not in sys.argv:                       # --frame keeps the whole source frame (all moods share one coordinate system)
        bb = im.getchannel('A').point(lambda v: 255 if v > 24 else 0).getbbox()
        im = im.crop(bb)
    if len(sys.argv) > 3 and sys.argv[3].isdigit():
        h = int(sys.argv[3]); im = im.resize((round(im.width * h / im.height), h), Image.LANCZOS)
    im.save(sys.argv[2]); print(im.size)
