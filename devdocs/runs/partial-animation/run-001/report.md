# partial-animation/run-001: one leaf tips (leaf2)

Summary: leaf2 of the flower pond still (assets/flower_pond/view.png, sha256 5064b6df33669ee8dcfb0fa95b7d171a7df12cd1fc436d29cb19d394f311db45) now tips slowly over a LaMa clean plate; scene `leaf2_tip` r1, checked in Godot 4.7.2 gl_compatibility at dim 1.0 and 0.55. Nothing else moves.

- analyze: SAM2.1-large, box + 1 point, leaf2 mask 12828 px, clean (left edge = foreground leaf occlusion).
- edge-refine: erode 1, feather 1.0, foreground colour estimation (tools/matte.py defaults).
- clean-plate: LaMa, mask dilated 9x9 (15900 px); looks fine by eye, slightly soft.
- build-layer: scenes/leaf2_tip/recipe.json (plate + one warp layer, dy-only, 4.5 px amp, 6 s loop, hinge x=1000). Delivery build/verify OK.
- verify (Apple M3 Ultra, OpenGL 4.1 Metal, 60 fixed fps, t~0 and t=3 s): 12475 px change between phases, all inside x1006-1200 / y285-430; 0 changed outside; outside the leaf region render == original still (max diff 0). Dimmed/undimmed: plate 0.5477, leaf 0.549, edge ring 0.5475 (target 0.55).
Evidence: devdocs/runs/partial-animation/run-001/evidence/ (numbers.txt, phases.png, dim_pair.png, shots).

Limits / not done: cut-out slightly softer than the still; Forward+ not tested; no previous revision to compare; README of experiments/partial-animation does not record the still's name/hash (taken from flower_spec.json, verified equal to present/still.png); delivery folder has no .import files, a consumer must run `godot --headless --import` once (else images missing); no separate delivery was published (not asked); the flower_pond scene was not touched; the earlier build used a one-off venv in /tmp (uv, torch/transformers/pymatting/simple-lama).
