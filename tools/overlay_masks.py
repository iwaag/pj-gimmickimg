#!/usr/bin/env python3
"""usage: overlay_masks.py <image> <out.png> <mask.png>...   tint each mask over the still, to judge segmentation."""
import sys, numpy as np
from PIL import Image
im = np.asarray(Image.open(sys.argv[1]).convert("RGB")).astype(float); ov = im.copy()
cols = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0), (255, 0, 255), (0, 255, 255)]
for i, f in enumerate(sys.argv[3:]):
    m = np.asarray(Image.open(f)) > 127
    ov[m] = ov[m] * 0.4 + np.array(cols[i % 6]) * 0.6
Image.fromarray(ov.astype(np.uint8)).save(sys.argv[2])
