# Minimal .aseprite reader: prints size/frames/layers/tags and renders each frame to PNG.
# python3 ase_dump.py file.aseprite out_dir
import struct, zlib, sys, os
from PIL import Image

def read(path):
    d = open(path, 'rb').read()
    size, magic, nframes, W, H, depth = struct.unpack_from('<IHHHHH', d, 0)
    assert magic == 0xA5E0, 'not aseprite'
    transp_idx = d[28]
    pos = 128; frames = []; layers = []; tags = []; pal = [(0, 0, 0, 0)] * 256
    for fi in range(nframes):
        fsize, fmagic, oldn, dur = struct.unpack_from('<IHHH', d, pos)
        newn = struct.unpack_from('<I', d, pos + 12)[0]
        n = newn or oldn; p = pos + 16; cels = []
        for _ in range(n):
            csize, ctype = struct.unpack_from('<IH', d, p); body = d[p + 6:p + csize]
            if ctype == 0x2004:
                flags, ltype, child = struct.unpack_from('<HHH', body, 0)
                blend, opac = struct.unpack_from('<HB', body, 10)
                nl = struct.unpack_from('<H', body, 16)[0]
                layers.append(dict(name=body[18:18 + nl].decode('utf8', 'replace'), visible=bool(flags & 1), type=ltype, child=child, opacity=opac))
            elif ctype == 0x2005:
                li, x, y, op, ct = struct.unpack_from('<HhhBH', body, 0)
                if ct in (0, 2):
                    w, h = struct.unpack_from('<HH', body, 16); raw = body[20:]
                    if ct == 2: raw = zlib.decompress(raw)
                    cels.append(dict(layer=li, x=x, y=y, op=op, w=w, h=h, px=raw))
                elif ct == 1:
                    cels.append(dict(layer=li, link=struct.unpack_from('<H', body, 16)[0], x=x, y=y, op=op))
            elif ctype == 0x2019:
                psize, first, last = struct.unpack_from('<III', body, 0); q = 20
                for i in range(first, last + 1):
                    fl, r, g, b, a = struct.unpack_from('<HBBBB', body, q); q += 6
                    if fl & 1: q += 2 + struct.unpack_from('<H', body, q)[0]
                    pal[i] = (r, g, b, a)
            elif ctype == 0x2018:
                nt = struct.unpack_from('<H', body, 0)[0]; q = 10
                for _ in range(nt):
                    a, b = struct.unpack_from('<HH', body, q); q += 17
                    ln = struct.unpack_from('<H', body, q)[0]; tags.append((body[q + 2:q + 2 + ln].decode(), a, b)); q += 2 + ln
            p += csize
        frames.append(dict(dur=dur, cels=cels)); pos += fsize
    return dict(W=W, H=H, depth=depth, transp=transp_idx, frames=frames, layers=layers, tags=tags, pal=pal)

def render(a, fi):
    img = Image.new('RGBA', (a['W'], a['H']), (0, 0, 0, 0))
    for c in sorted(a['frames'][fi]['cels'], key=lambda c: c['layer']):
        if 'link' in c: c = next(k for k in a['frames'][c['link']]['cels'] if k['layer'] == c['layer'])
        L = a['layers'][c['layer']]
        if not L['visible'] or L['type'] != 0: continue
        w, h, px = c['w'], c['h'], c['px']
        if a['depth'] == 32: im = Image.frombytes('RGBA', (w, h), px)
        elif a['depth'] == 16: im = Image.frombytes('LA', (w, h), px).convert('RGBA')
        else:
            im = Image.new('RGBA', (w, h)); im.putdata([(0, 0, 0, 0) if v == a['transp'] else a['pal'][v] for v in px])
        img.alpha_composite(im, (max(c['x'], 0), max(c['y'], 0)), (max(-c['x'], 0), max(-c['y'], 0)))
    return img

if __name__ == '__main__':
    a = read(sys.argv[1]); out = sys.argv[2]; os.makedirs(out, exist_ok=True)
    base = os.path.splitext(os.path.basename(sys.argv[1]))[0].strip()
    print(base, f"{a['W']}x{a['H']}", 'depth', a['depth'], 'frames', len(a['frames']),
          'layers', [(l['name'], l['visible']) for l in a['layers']], 'tags', a['tags'])
    for i in range(len(a['frames'])):
        render(a, i).save(f"{out}/{base}_{i}.png")
