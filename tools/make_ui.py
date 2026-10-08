# Room polish assets: soft contact shadow and sun / moon icons for the side HUD.
import sys; sys.path.insert(0, 'tools')
from pix import *

# contact shadow 64x16: dark core + a lighter ring (two alpha steps keep it pixel-art, no smooth gradient)
sh = np.zeros((16, 64, 4), np.int32)
for y in range(16):
    for x in range(64):
        d = ((x - 31.5) / 32.0) ** 2 + ((y - 7.5) / 8.0) ** 2
        if d <= 0.55: sh[y, x] = (28, 16, 14, 118)
        elif d <= 1.0: sh[y, x] = (28, 16, 14, 62)
save(sh, 'art/shadow_big.png')

def icon(rows, col, name):
    a = np.zeros((len(rows), len(rows[0]), 4), np.int32)
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch != '.': a[y, x] = (*col, 255)
    save(a, name)

icon(['....Y....', '.Y..Y..Y.', '..YYYYY..', '..YYYYY..', 'Y.YYYYY.Y', '..YYYYY..', '..YYYYY..', '.Y..Y..Y.', '....Y....'],
     (255, 214, 120), 'art/ui_sun.png')
icon(['..LLLL...', '.LLL.....', 'LLL......', 'LLL......', 'LLL......', 'LLL......', '.LLL...L.', '..LLLLL..', '.........'],
     (190, 206, 255), 'art/ui_moon.png')
print('ok')
