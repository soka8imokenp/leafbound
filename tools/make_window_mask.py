# Window glass mask for the living sky: 4 clean panes (the frame and mullions stay from the room background).
# Origin of the mask in room pixels: (109, 43); size 29x23.
import sys; sys.path.insert(0, 'tools')
from pix import *
m = np.zeros((23, 29, 4), np.int32)
for (xa, xb, ya, yb) in [(1, 12, 0, 8), (16, 27, 0, 8), (1, 12, 12, 21), (16, 27, 12, 21)]:
    m[ya:yb + 1, xa:xb + 1] = (255, 255, 255, 255)
save(m, 'art/window_mask.png')
print('panes', int((m[..., 3] > 0).sum()), 'px')
