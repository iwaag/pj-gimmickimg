#!/usr/bin/env python3
"""Edge refinement for one still: SAM2 masks -> erode -> feather -> foreground colour estimation -> RGBA cut-outs.

This is the mushroom method of freework/run-007..009 (experiments/edge-extraction/sam2_extract.py + refine.py, ch-0001)
made reusable. Needs torch, transformers (facebook/sam2.1-hiera-large) and pymatting; runs on Apple MPS or CPU.

  matte.py segment <spec.json> <outdir>   spec: {"image": path, "objects": [{"name", "box": [x0,y0,x1,y1],
                                          "points": [[x,y],...], "neg_points": [[x,y],...]}]}  -> <name>_mask.png
  matte.py union   <out.png> <mask.png>...   several objects' masks as one
  matte.py refine  <image> <mask.png> <out_rgba.png> [--erode 1] [--feather 1.0]
                                          -> RGBA with the background colour removed from edge pixels
"""
import argparse, json, os, sys
import numpy as np, cv2
from PIL import Image


def segment(spec_path, outdir):
    import torch
    from transformers import Sam2Processor, Sam2Model
    spec = json.load(open(spec_path))
    img = Image.open(spec["image"]).convert("RGB")
    dev = "mps" if torch.backends.mps.is_available() else "cpu"
    name = "facebook/sam2.1-hiera-large"
    proc = Sam2Processor.from_pretrained(name); model = Sam2Model.from_pretrained(name).to(dev).eval()
    os.makedirs(outdir, exist_ok=True)
    for o in spec["objects"]:
        pts = [list(p) for p in o.get("points", [])] + [list(p) for p in o.get("neg_points", [])]
        labels = [1] * len(o.get("points", [])) + [0] * len(o.get("neg_points", []))
        kw = dict(images=img, return_tensors="pt")
        if o.get("box"): kw["input_boxes"] = [[list(o["box"])]]
        if pts: kw["input_points"] = [[pts]]; kw["input_labels"] = [[labels]]
        inp = proc(**kw).to(dev)
        with torch.no_grad(): out = model(**inp, multimask_output=False)
        m = proc.post_process_masks(out.pred_masks.cpu(), inp["original_sizes"].cpu(), binarize=True)[0][0, 0].numpy() > 0
        Image.fromarray((m * 255).astype(np.uint8)).save(f"{outdir}/{o['name']}_mask.png")
        print(o["name"], int(m.sum()), "px")


def clean(m, close=3, min_px=150):
    """SAM leaves pin-holes and crumbs: close small gaps, fill holes, drop specks."""
    from scipy import ndimage as ndi
    m = m.astype(bool)
    if close: m = cv2.morphologyEx(m.astype(np.uint8), cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * close + 1,) * 2)).astype(bool)
    m = ndi.binary_fill_holes(m)
    lab, n = ndi.label(m)
    for i in range(1, n + 1):
        if (lab == i).sum() < min_px: m[lab == i] = False
    return m


def alpha_from(mask, erode=1, feather=1.0):
    m = clean(np.asarray(mask) > 127).astype(np.uint8)
    if erode: m = cv2.erode(m, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * erode + 1,) * 2))
    return np.clip(cv2.GaussianBlur(m.astype(np.float32), (0, 0), feather), 0, 1).astype(np.float64)


def refine(image, mask, out, erode=1, feather=1.0):
    from pymatting import estimate_foreground_ml
    rgb = np.asarray(Image.open(image).convert("RGB")).astype(np.float64) / 255
    a = alpha_from(Image.open(mask).convert("L"), erode, feather)
    fg = np.clip(estimate_foreground_ml(rgb, a), 0, 1)
    Image.fromarray((np.dstack([fg, a]) * 255).round().astype(np.uint8)).save(out)


if __name__ == "__main__":
    ap = argparse.ArgumentParser(); sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("segment"); s.add_argument("spec"); s.add_argument("outdir")
    r = sub.add_parser("refine"); r.add_argument("image"); r.add_argument("mask"); r.add_argument("out")
    r.add_argument("--erode", type=int, default=1); r.add_argument("--feather", type=float, default=1.0)
    u = sub.add_parser("union"); u.add_argument("out"); u.add_argument("masks", nargs="+")
    a = ap.parse_args()
    if a.cmd == "segment": segment(a.spec, a.outdir)
    elif a.cmd == "union":
        m = np.zeros(np.asarray(Image.open(a.masks[0])).shape[:2], bool)
        for f in a.masks: m |= np.asarray(Image.open(f).convert("L")) > 127
        Image.fromarray((m * 255).astype(np.uint8)).save(a.out)
    else: refine(a.image, a.mask, a.out, a.erode, a.feather)
