# Hand-placed face for the half-size Anzu (the 2x reduce turns her eyes into blobs).
import sys; sys.path.insert(0, 'tools')
from pix import *
K, D, R, O, S, G = (7, 1, 1), (81, 35, 39), (193, 61, 41), (241, 132, 48), (244, 213, 193), (132, 178, 87)
a = load('art/anzu_half.png')
def px(x, y, c): a[y, x, :3] = c; a[y, x, 3] = 255
for y in range(19, 27):
    for x in range(24, 40):
        if tuple(a[y, x, :3]) in (K, D, S, G): px(x, y, S)
def eye(x0, wing):
    for x in range(x0, x0 + 4): px(x, 19, K)
    px(wing, 19, K); px(wing, 18 if tuple(a[18, wing, :3]) != O else 19, K)
    for i, c in enumerate([K, S, K, K]): px(x0 + i, 20, c)
    for i, c in enumerate([K, K, K, K]): px(x0 + i, 21, c)
    for i, c in enumerate([D, K, K, D]): px(x0 + i, 22, c)
    for i, c in enumerate([G, O, O, G]): px(x0 + i, 23, c)
eye(25, 24); eye(35, 39)
px(31, 27, R); px(32, 27, R)          # mouth
px(25, 25, (247, 180, 160)); px(38, 25, (247, 180, 160))   # faint blush
save(a, 'art/anzu_front.png')
