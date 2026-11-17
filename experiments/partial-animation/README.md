# partial-animation (workflow `partial-animation`, first used in freework/run-018)

Reusable parts: `tools/matte.py` (SAM2 segment / union / refine = erosion + feather + foreground colour estimation; the
mushroom method of experiments/edge-extraction), `tools/clean_plate.py` (LaMa), `tools/overlay_masks.py`, `player/demo.gd --dim`.
Environment used: a uv venv with torch, torchvision, transformers, pymatting, opencv-python-headless, scipy, simple-lama-inpainting
(`--no-deps`, plus fire omegaconf easydict), SAM2.1 hiera-large from the HF cache, on Apple MPS/CPU.

flower_pond r2: `python flower_spec.py` -> `matte.py segment` -> `matte.py union` (left, right) -> `matte.py refine` -> plate mask
(union cleaned, dilated 9x9) -> `clean_plate.py` -> `build_flower_pond.py` -> scenes/flower_pond/recipe.json r2.
Outputs in `out/` (masks, cut-outs, clean plate, displacement maps); before/after in `evidence/`.

flower_pond r3 (partial-animation/run-002, bee flight): `run_bee.sh` (bee-free still by LaMa, leaf re-cut on it, bee matte, plate) -> `build_bee.py`
(bee body/wings split, figure-eight path as samples, recipe r3 with a `path` layer; player: `gimmick_scene.gd` type `path`, `seek()`;
`player/demo.gd --seq/--t/--quit` for deterministic stills). Evidence in `present_bee/`.
