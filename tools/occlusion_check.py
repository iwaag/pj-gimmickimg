"""Occlusion check on debug renders (black layer silhouettes, snow band j in colour j: R,G,B,Y).
For each band j, count its flake pixels lying where mask_k>0.98 for k>j (nearer occluders): expected 0.
usage: occlusion_check.py frames_dir art_dir frame_idx,..."""
import sys, numpy as np
from PIL import Image
fd, art, idx = sys.argv[1], sys.argv[2], [int(i) for i in sys.argv[3].split(",")]
masks = {k: np.array(Image.open(f"{art}/mask_{k}.png")) > 250 for k in (1, 2, 3)}
tot = {}
for i in idx:
    f = np.array(Image.open(f"{fd}/f{i:08d}.png").convert("RGB")).astype(int)
    r, g, b = f[..., 0], f[..., 1], f[..., 2]; T = 60
    cls = [(r > T) & (g < T // 2) & (b < T // 2), (g > T) & (r < T // 2) & (b < T // 2),
           (b > T) & (r < T // 2) & (g < T // 2), (r > T) & (g > T) & (b < T // 2)]
    for j, c in enumerate(cls):
        vis = int(c.sum())
        over = {k: int((c & masks[k]).sum()) for k in range(j + 1, 4)}
        beh = int((c & masks[j]).sum()) if j >= 1 else None   # control: own-band flakes in its own near-region (allowed)
        print(f"frame {i} band {j}: flake px {vis}; over nearer masks {over}; own-mask {beh}")
        t = tot.setdefault(j, [0, 0]); t[0] += vis; t[1] += sum(over.values())
print("TOTAL band: (flake px, px over nearer masks)", tot)
