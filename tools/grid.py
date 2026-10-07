# Zoomed view with pixel grid + coordinates, for hand pixel edits.  grid.py in.png out.png x0 y0 x1 y1 [scale]
import sys
from PIL import Image, ImageDraw
im = Image.open(sys.argv[1]).convert('RGBA'); x0, y0, x1, y1 = map(int, sys.argv[3:7]); s = int(sys.argv[7]) if len(sys.argv) > 7 else 16
c = im.crop((x0, y0, x1, y1)); bg = Image.new('RGBA', c.size, (60, 60, 75, 255)); bg.alpha_composite(c)
z = bg.resize((c.width * s, c.height * s), Image.NEAREST); d = ImageDraw.Draw(z)
for i in range(c.width + 1): d.line([(i * s, 0), (i * s, z.height)], fill=(0, 0, 0, 90))
for j in range(c.height + 1): d.line([(0, j * s), (z.width, j * s)], fill=(0, 0, 0, 90))
for i in range(c.width): d.text((i * s + 2, 1), str(x0 + i), fill=(255, 255, 255, 200))
for j in range(c.height): d.text((1, j * s + 2), str(y0 + j), fill=(255, 255, 255, 200))
z.save(sys.argv[2])
