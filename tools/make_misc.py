# Small textures (shadow, E key) + synthesized sound effects (no downloads).
import sys, wave; sys.path.insert(0, 'tools')
from pix import *
rng = np.random.default_rng(3)

# shadow ellipse 16x6
sh = np.zeros((6, 16, 4), np.int32)
for y in range(6):
    for x in range(16):
        if ((x - 7.5) / 8) ** 2 + ((y - 2.5) / 3) ** 2 <= 1: sh[y, x] = (30, 18, 14, 110)
save(sh, 'art/shadow.png')
# "E" key icon 9x10: light key cap with dark letter
key = np.zeros((10, 9, 4), np.int32)
key[0:9, 0:9] = (60, 40, 30, 255); key[1:8, 1:8] = (238, 222, 196, 255); key[9, 1:8] = (60, 40, 30, 255)
key[8, 1:8] = (190, 160, 130, 255)
for (y, x) in [(2, 3), (2, 4), (2, 5), (3, 3), (4, 3), (4, 4), (5, 3), (6, 3), (6, 4), (6, 5)]: key[y, x] = (60, 40, 30, 255)
save(key, 'art/key_e.png')

SR = 22050
def wav(name, x):
    x = np.clip(x, -1, 1); d = (x * 32767).astype('<i2').tobytes()
    with wave.open(f'sfx/{name}.wav', 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(d)
def lowpass(x, a):
    y = np.zeros_like(x); acc = 0.0
    for i, v in enumerate(x): acc += a * (v - acc); y[i] = acc
    return y
t = lambda s: np.arange(int(SR * s)) / SR

# fire crackle loop 4 s: soft rumble + random pops
n = len(t(4)); x = lowpass(rng.normal(0, 1, n), 0.02) * 0.6
for _ in range(70):
    p = rng.integers(0, n - 800); L = rng.integers(60, 500)
    x[p:p + L] += rng.normal(0, 1, L) * np.exp(-np.arange(L) / (L / 4)) * rng.uniform(0.2, 0.8)
fade = np.minimum(1, np.minimum(np.arange(n), n - np.arange(n)) / 400); wav('crackle', x * 0.5 * fade)
# purr 2.6 s: low noise, amplitude-modulated at ~26 Hz, two breaths
tt = t(2.6); nz = lowpass(rng.normal(0, 1, len(tt)), 0.05)
env = (0.5 + 0.5 * np.sin(2 * np.pi * 26 * tt)) * np.sin(np.pi * (tt % 1.3) / 1.3) ** 0.7
wav('purr', nz * env * 2.2)
# radio static 2.5 s
tt = t(2.5); nz = rng.normal(0, 1, len(tt)) - lowpass(rng.normal(0, 1, len(tt)), 0.1)
env = 0.35 + 0.25 * np.sin(2 * np.pi * 3 * tt) + 0.15 * (rng.random(len(tt)) > 0.997)
wav('static', nz * env * 0.35 * np.minimum(1, np.minimum(tt, 2.5 - tt) * 20))
# text blip 35 ms
tt = t(0.035); wav('blip', np.sign(np.sin(2 * np.pi * 540 * tt)) * np.exp(-tt * 90) * 0.18)
# footstep 70 ms, soft wooden thump
tt = t(0.07); wav('step', lowpass(rng.normal(0, 1, len(tt)), 0.15) * np.exp(-tt * 70) * 0.9)
print('ok')
