# High-resolution (non-pixel) dialog art: parchment box with a gold frame, name plate, leaf sprigs, "next" leaf.
# Drawn 4x supersampled with PIL, shipped as nine-patch textures. Run: .venv/bin/python tools/make_dialog_ui.py
import math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SS = 4
GOLD, GOLD_HI, GOLD_LO = (178, 142, 64), (238, 212, 138), (108, 78, 32)
DARK = (34, 25, 18)
rng = random.Random(7)


def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def leaf(d, cx, cy, ang, length, width, base, light, dark, vein=None, tip_curl=0.0):
    """one stylised leaf: pointed ellipse along `ang`, light half, dark rim line, midrib"""
    pts_l, pts_r, mid = [], [], []
    n = 28
    for i in range(n + 1):
        t = i / n
        w = math.sin(math.pi * t) ** 0.85 * width / 2 * (1.0 - 0.25 * t)
        curl = tip_curl * length * t * t
        x = t * length
        mid.append((x, curl))
        pts_l.append((x, curl - w)); pts_r.append((x, curl + w))
    def tr(p):
        c, s = math.cos(ang), math.sin(ang)
        return (cx + p[0] * c - p[1] * s, cy + p[0] * s + p[1] * c)
    poly = [tr(p) for p in pts_l] + [tr(p) for p in reversed(pts_r)]
    d.polygon(poly, fill=base)
    half = [tr(p) for p in mid] + [tr(p) for p in reversed(pts_r)]
    d.polygon(half, fill=light)
    d.line(poly + [poly[0]], fill=dark, width=max(2, int(SS * 0.9)), joint='curve')
    d.line([tr(p) for p in mid], fill=vein or dark, width=max(2, int(SS * 0.7)))


def sprig(size, stems, colors, seed=1):
    """transparent canvas with stems: list of (x, y, angle, length, leaves) in 0..1 units of `size`"""
    W, H = size
    im = Image.new('RGBA', (W * SS, H * SS), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    base, light, dark = colors
    for (x, y, ang, length, nleaf, lw) in stems:
        x0, y0, L = x * W * SS, y * H * SS, length * W * SS
        steps = 14
        path = []
        for i in range(steps + 1):
            t = i / steps
            curve = 0.18 * math.sin(t * math.pi) * L
            px = x0 + math.cos(ang) * L * t - math.sin(ang) * curve
            py = y0 + math.sin(ang) * L * t + math.cos(ang) * curve
            path.append((px, py))
        d.line(path, fill=dark, width=int(SS * 3.2))
        d.line(path, fill=lerp(base, dark, 0.35), width=int(SS * 1.8))
        for k in range(nleaf):
            t = (k + 1) / (nleaf + 0.6)
            idx = min(int(t * steps), steps - 1)
            px, py = path[idx]
            side = 1 if k % 2 == 0 else -1
            a = ang + side * (0.62 + 0.12 * rng.random())
            ll = L * (0.34 - 0.05 * k * 0.6) * lw
            leaf(d, px, py, a, ll, ll * 0.42, base, light, dark, tip_curl=0.08 * side)
        # terminal leaf
        ex, ey = path[-1]
        leaf(d, ex, ey, ang, L * 0.36 * lw, L * 0.15 * lw, base, light, dark)
    return im.resize((W, H), Image.LANCZOS)


def parchment(W, H):
    """cream paper: soft vertical gradient, fibre noise, a few hairline cracks"""
    y = np.linspace(0, 1, H)[:, None, None]
    top, bot = np.array([241, 237, 228]), np.array([223, 217, 204])
    img = (top * (1 - y) + bot * y) * np.ones((1, W, 1))
    nz = np.random.default_rng(3).normal(0, 1, (H // 2 + 1, W // 2 + 1))
    nz = np.array(Image.fromarray(((nz - nz.min()) / (nz.max() - nz.min()) * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)).astype(float) / 255 - 0.5
    img = img + nz[..., None] * 9
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).convert('RGBA')
    d = ImageDraw.Draw(im, 'RGBA')
    r = random.Random(11)
    for _ in range(3):                                       # hairline cracks (faint: nine-patch stretches them)
        x, yy = r.uniform(0, W), r.uniform(0, H)
        ang = r.uniform(0, 6.28); pts = [(x, yy)]
        for _ in range(r.randint(8, 16)):
            ang += r.uniform(-0.5, 0.5); x += math.cos(ang) * r.uniform(10, 26); yy += math.sin(ang) * r.uniform(10, 26)
            pts.append((x, yy))
        d.line(pts, fill=(120, 108, 92, 22), width=max(1, int(SS * 0.5)))
    return im


def gold_frame(W, H, radius, inset=0):
    """returns an RGBA frame: dark outline + bevelled gold band + inner dark line; the inside is transparent"""
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    S = SS
    d.rounded_rectangle((inset, inset, W - 1 - inset, H - 1 - inset), radius, fill=DARK + (255,))
    b = inset + 5 * S
    d.rounded_rectangle((b, b, W - 1 - b, H - 1 - b), radius - 4 * S, fill=GOLD + (255,))
    # bevel: light top/left, shadow bottom/right
    hl = Image.new('RGBA', (W, H), (0, 0, 0, 0)); hd = ImageDraw.Draw(hl)
    hd.rounded_rectangle((b, b, W - 1 - b, H - 1 - b), radius - 4 * S, outline=GOLD_HI + (255,), width=2 * S)
    hd.rounded_rectangle((b + 2 * S, b + 2 * S, W - 1 - b - 2 * S, H - 1 - b - 2 * S), radius - 6 * S, outline=GOLD_LO + (255,), width=2 * S)
    sh = Image.new('L', (W, H), 0); sd = ImageDraw.Draw(sh)
    sd.polygon([(0, 0), (W, 0), (0, H)], fill=255)           # light from the upper left
    sh = sh.filter(ImageFilter.GaussianBlur(S * 6))
    hi_only = Image.composite(hl, Image.new('RGBA', (W, H), (0, 0, 0, 0)), sh)
    im.alpha_composite(hi_only)
    d.rounded_rectangle((b + 6 * S, b + 6 * S, W - 1 - b - 6 * S, H - 1 - b - 6 * S), radius - 10 * S, outline=(54, 38, 20, 255), width=int(1.6 * S))
    hole = Image.new('L', (W, H), 255); hd2 = ImageDraw.Draw(hole)           # punch out the inside: the paper shows through
    hd2.rounded_rectangle((b + 7.6 * S, b + 7.6 * S, W - 1 - b - 7.6 * S, H - 1 - b - 7.6 * S), max(radius - 12 * S, 2), fill=0)
    im.putalpha(Image.fromarray((np.array(im.getchannel('A')).astype(float) * np.array(hole).astype(float) / 255).astype(np.uint8)))
    return im


def make_box():
    W, H = 384 * SS, 256 * SS
    radius = 22 * SS
    frame = gold_frame(W, H, radius)
    pad = 12 * SS
    paper = parchment(W, H)
    mask = Image.new('L', (W, H), 0)
    ImageDraw.Draw(mask).rounded_rectangle((pad, pad, W - 1 - pad, H - 1 - pad), radius - 11 * SS, fill=255)
    out = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    out.paste(paper, (0, 0), mask)
    out.alpha_composite(frame)
    # soft inner shadow under the gold edge
    sh = Image.new('L', (W, H), 0)
    ImageDraw.Draw(sh).rounded_rectangle((pad, pad, W - 1 - pad, H - 1 - pad), radius - 11 * SS, outline=255, width=9 * SS)
    sh = sh.filter(ImageFilter.GaussianBlur(5 * SS)).point(lambda v: int(v * 0.30))
    shade = Image.new('RGBA', (W, H), (70, 52, 30, 0)); shade.putalpha(Image.composite(sh, Image.new('L', (W, H), 0), mask))
    out.alpha_composite(shade)
    # small gold curls in the bottom-right and top-left corners (inside the fixed corner regions)
    d = ImageDraw.Draw(out)
    gc = sprig((90, 60), [(0.08, 0.80, -0.35, 0.80, 3, 0.9)], ((196, 160, 70), (244, 222, 150), (110, 80, 34)))
    gc = gc.rotate(0)
    out.alpha_composite(gc.resize((gc.width * SS, gc.height * SS), Image.LANCZOS), (W - gc.width * SS - 22 * SS, H - gc.height * SS - 16 * SS))
    return out.resize((384, 256), Image.LANCZOS)


def make_plate():
    W, H = 256 * SS, 112 * SS
    radius = 12 * SS
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, W - 1, H - 1), radius, fill=DARK + (255,))
    d.rounded_rectangle((4 * SS, 4 * SS, W - 1 - 4 * SS, H - 1 - 4 * SS), radius - 3 * SS, fill=GOLD + (255,))
    d.rounded_rectangle((7 * SS, 7 * SS, W - 1 - 7 * SS, H - 1 - 7 * SS), radius - 5 * SS, fill=(44, 36, 33, 255))
    # vertical gradient + a thin gold hairline inside
    g = np.linspace(0, 1, H)[:, None]
    shade = Image.fromarray(np.clip(np.stack([60 - 22 * g, 50 - 20 * g, 46 - 18 * g], -1) * np.ones((1, W, 1)), 0, 255).astype(np.uint8)).convert('RGBA')
    m = Image.new('L', (W, H), 0); ImageDraw.Draw(m).rounded_rectangle((7 * SS, 7 * SS, W - 1 - 7 * SS, H - 1 - 7 * SS), radius - 5 * SS, fill=255)
    img.paste(shade, (0, 0), m)
    d.rounded_rectangle((11 * SS, 11 * SS, W - 1 - 11 * SS, H - 1 - 11 * SS), radius - 8 * SS, outline=(150, 118, 54, 160), width=SS)
    hl = Image.new('RGBA', (W, H), (0, 0, 0, 0)); ImageDraw.Draw(hl).rounded_rectangle((4 * SS, 4 * SS, W - 1 - 4 * SS, H - 1 - 4 * SS), radius - 3 * SS, outline=GOLD_HI + (255,), width=SS * 2)
    sh2 = Image.new('L', (W, H), 0); ImageDraw.Draw(sh2).polygon([(0, 0), (W, 0), (0, H)], fill=255)
    img.alpha_composite(Image.composite(hl, Image.new('RGBA', (W, H), (0, 0, 0, 0)), sh2.filter(ImageFilter.GaussianBlur(SS * 8))))
    return img.resize((256, 112), Image.LANCZOS)


def make_arrow():
    """gold leaf-shaped 'next' marker pointing down"""
    W = H = 48
    im = Image.new('RGBA', (W * SS, H * SS), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    leaf(d, W * SS / 2, 6 * SS, math.pi / 2, 34 * SS, 26 * SS, (206, 168, 72), (244, 222, 150), (84, 58, 24))
    return im.resize((W, H), Image.LANCZOS)


if __name__ == '__main__':
    make_box().save('art/dlg/box.png')
    make_plate().save('art/dlg/plate.png')
    make_arrow().save('art/dlg/arrow.png')
    green = ((92, 150, 62), (150, 200, 96), (36, 70, 34))
    sprig((220, 120), [(0.04, 0.62, -0.12, 0.62, 3, 1.0), (0.10, 0.74, 0.42, 0.50, 2, 0.9)], green).save('art/dlg/sprig_green.png')
    sprig((200, 120), [(0.96, 0.78, math.pi + 0.18, 0.66, 4, 1.0), (0.94, 0.52, math.pi - 0.45, 0.46, 2, 0.8)],
          ((196, 160, 70), (244, 222, 150), (110, 80, 34))).save('art/dlg/sprig_gold.png')
    print('ok')
