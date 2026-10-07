# Pixel-art helpers: exact native downsample of upscaled art, majority 2x reduce, palette tools.
import numpy as np
from PIL import Image

def load(path):
    return np.array(Image.open(path).convert('RGBA')).astype(np.int32)

def save(a, path, scale=1):
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGBA')
    if scale != 1: im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    im.save(path)

def native(a, k):
    """upscaled-by-k pixel art -> native (centre sample of each block)"""
    return a[k // 2::k, k // 2::k].copy()

def reduce2(a, outline_rgb=None):
    """2x reduction for pixel art: per 2x2 block take the most frequent colour; dark outline
    pixels win ties so 1-px outlines survive."""
    H, W = a.shape[0] // 2, a.shape[1] // 2
    out = np.zeros((H, W, 4), np.int32)
    lum = a[..., :3].sum(-1)
    for y in range(H):
        for x in range(W):
            blk = a[2 * y:2 * y + 2, 2 * x:2 * x + 2].reshape(4, 4)
            l = lum[2 * y:2 * y + 2, 2 * x:2 * x + 2].reshape(4)
            op = blk[:, 3] > 127
            if op.sum() < 2: continue
            cols = [tuple(c) for c in blk[op]]
            cnt = {c: cols.count(c) for c in cols}
            best = max(cnt.values())
            cand = [c for c in cnt if cnt[c] == best]
            # tie -> darkest (keeps outlines)
            c = min(cand, key=lambda c: c[0] + c[1] + c[2])
            out[y, x] = c
            out[y, x, 3] = 255
    return out
