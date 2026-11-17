# Trial: SAM2 box+point masks, erode 1 px, feather, foreground colour estimation (survey steps 1-2)

Summary: SAM2.1-large masks replace the hand-drawn ellipses; the surrounding grass/moss is gone from 7 of 8 cut-outs and the edges look clean on magenta, white and black.

- Method: for each of the 8 old ellipse components, SAM2.1 hiera-large (HF transformers, run locally on Apple MPS; the GPU workstation's ComfyUI had no SAM2/BiRefNet/matting weights installed - only SAM3 nodes without a visible checkpoint) got the component's bounding box plus its deepest interior point. Then erode 1 px, Gaussian feather sigma 1, and pymatting `estimate_foreground_ml` to remove background colour from edge pixels.
- Result: SAM masks are 20-35% smaller than the ellipses for the large mushrooms (e.g. 10658 -> 8358 px).
- Not solved: the top-right mushroom is partly hidden by grass leaves in the source, so its cut-out is fragmented (SAM is right, but the old ellipse mask hid this). Moving-frame check and the Wan re-run were not done. Fuzzy-edge trimap/ViTMatte was not needed at this resolution.
- Files: `sam2_extract.py`, `refine.py`, `sam_mask.png`, `compare_ellipse_vs_sam.png` (top: ellipse, bottom: SAM; magenta/white/black), `zoom_big_mushroom.png` (left ellipse, right SAM), `*_rgba.png` cut-outs.
