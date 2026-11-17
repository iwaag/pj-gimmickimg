#!/usr/bin/env python3
"""Clean plate: LaMa inpaints the still where the animated layers sit, so nothing moves twice.
usage: clean_plate.py <image> <mask.png (white = fill)> <out.png>   (needs simple-lama-inpainting; used by tools/lama_run.py before)"""
import sys, numpy as np
from PIL import Image
from simple_lama_inpainting import SimpleLama
img = Image.open(sys.argv[1]).convert("RGB"); m = Image.open(sys.argv[2]).convert("L")
r = SimpleLama(device="cpu")(img, m).convert("RGB").crop((0, 0) + img.size)
k = (np.asarray(m) > 0)[..., None]   # keep every pixel outside the mask exactly as in the still
Image.fromarray(np.where(k, np.asarray(r), np.asarray(img)).astype(np.uint8)).save(sys.argv[3])
