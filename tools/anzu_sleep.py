# Sleeping Anzu for the bed: her head (native 128 px art) with closed eyes + the bed's own quilt edge
# as a blanket overlay pulled up to the chin.
import sys; sys.path.insert(0, 'tools')
from pix import *

K, D, R, O, S, G = (7, 1, 1), (81, 35, 39), (193, 61, 41), (241, 132, 48), (244, 213, 193), (132, 178, 87)
n = load('art/anzu_native.png')
head = np.zeros_like(n); head[:60] = n[:60]
head[head[..., 3] > 0, 3] = 255
for (x0, x1) in ((48, 60), (70, 82)):                     # wipe open eyes to skin
    for y in range(39, 52):
        for x in range(x0, x1):
            if head[y, x, 3] and tuple(head[y, x, :3]) in (K, D, G, O): head[y, x, :3] = S
def px(x, y, c=K): head[y, x, :3] = c; head[y, x, 3] = 255
for x0 in (49, 71):                                        # closed lids  ︶ with a lash
    for x in range(x0 + 1, x0 + 8): px(x, 46)
    px(x0, 45); px(x0 + 8, 45)
    px(x0 + 2, 47, D); px(x0 + 6, 47, D)
px(48, 44); px(82, 44)
save(head, 'art/anzu_sleep.png')

bed = load('art/ase/bed_0.png')
blanket = np.zeros_like(bed); blanket[37:41] = bed[37:41]
save(blanket, 'art/bed_blanket.png')
print('ok')
