# gimmickimg

Notes, small tools and a Godot player from experiments that animate **parts of a single 2D still image** and play
the result in Godot 4.7: cut out an object (SAM2 mask, erosion, feather, foreground colour estimation), fill the
hole behind it (LaMa), move the cut-out (a local sway, a long looped path) or loop a generated video clip, and draw
it all back over the still with correct front/behind order. Falling snow between depth bands, swaying flowers, a
flying bee and a flowing waterfall were the subjects.

This is an edited selection of a working repository, published as text and code only. **No images, videos or
scene files are published**: the still images used were a mix of generated pictures and a picture belonging to
another project, so the scenes cannot be rebuilt from this repository. What you get is the method, the code and what
was learned, with its limits.

## What is here

| Path | What it is | How far to trust it |
|---|---|---|
| [`wedo/`](wedo/README.md) | Three findings: cutting an object out of a still ([f-0002](wedo/findings/clean-cutout-from-still.md)), moving a cut-out across a still ([f-0001](wedo/findings/moving-cutout-part-across-still.md)), looping a generated clip ([f-0003](wedo/findings/looping-generated-clip.md)). Each says the conditions, what it rests on and where it stops. | Mostly the experimenting agents' own measurements and eyes, on a handful of images, 1-2 seeds per arm. Each finding says whose judgement it is. |
| [`tools/`](tools/) | Python helpers: `matte.py` (SAM2 segment / union / refine), `clean_plate.py` (LaMa inpainting), `overlay_masks.py`, `depth.py` (depth estimation) and `occlusion_check.py`. | Written for the experiments, run on Apple silicon (MPS/CPU). Not packaged: there is no requirements file; the experiment notes list what was installed. |
| [`player/`](player/) | A small Godot 4.7 project: `player/gimmick/gimmick_scene.gd` draws a scene described by a `scene.json` (layer types `image`, `video`, `frames`, `warp`, `sparkle`, `pollen`, `path`). `player/demo.gd` shows one and can write stills (`--shot`, `--frames`, `--dim`). | Checked on macOS with gl_compatibility and Forward Plus by the authors; not elsewhere. It needs a scene folder (`gimmick/scenes/<id>/scene.json` and its layer images) that you make yourself: none is included. |
| [`docs/delivery.md`](docs/delivery.md) | The scene and delivery format and the `gimmick_scene.gd` API. | Describes a build tool that is not published; read it as the format description. |
| [`experiments/`](experiments/) | Notes and (for `edge-extraction`) scripts of three experiments; other scripts and all images stay internal: `edge-extraction`, `window-loop` (generated room and far view behind a window), `partial-animation`. | Notes as written at the time, dates in them. |

## Things to know before you read the findings

- The findings and notes link to the working repository's run reports, challenge records and shared storage. **Those
  are not published**; such a link is evidence you cannot follow, and the finding's text says what it took from it.
  Hosts and machine names were replaced by general descriptions.
- Names such as `flower_pond`, `leaf_drift` or `mushroom_waterfall` are scenes whose images are not included.
- The "agents" named in the findings are the AI agents of the producing installation; "the person" is its owner.
  A finding says when no person has looked at a result.
- Models and tools used but not included: SAM 2.1 (hiera-large), LaMa (simple-lama-inpainting), pymatting, Wan 2.2,
  MiniMax H3 (through ComfyUI), Godot. Each has its own licence; check them before use.

## Licence

CC0-1.0 (see `LICENSE`), for the text and code of this repository.
