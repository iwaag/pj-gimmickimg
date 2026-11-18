# blue_sway_right r1 — report

Result: the right-hand blue cluster (1160, 415) now sways as a matted RGBA cut-out over a LaMa clean plate; it can be made good. New scene `scenes/blue_sway_right` r1; no other scene touched.
Judged from: Godot 4.7 gl_compatibility renders at modulate 1.0 and 0.55 (4 phases, a 6 s loop video), and crops of mask / cut-out / plate. Limits: sway is small (about ±6 px at the head), the cluster is cut as one blob (florets are not separate), and I judged by eye plus numbers; no other person has looked yet.
Watch: `evidence/blue_sway_right_zoom.mp4` (6 s loop, undimmed | dimmed 0.55) and `evidence/sheet_phases.png`; the delivery was built and verified but not published (run has no share; wfe run publish refused), rebuild with `python3 tools/delivery.py build --scene blue_sway_right --out <dir>`.

## What I did
1. Analyze: SAM2 (facebook/sam2.1-hiera-large) with two prompts (`experiments/partial-animation/blue_right/spec.json`): heads (box + 3 interior points) and stem+leaves (box + 2 points on the stem, 2 negative points on the neighbouring pink stem). Both masks came out clean on first try (heads 4290 px, stem/leaves 2239 px); the leaf above-left and the pink cosmos stem to the right did not leak in. The head mask is a solid silhouette: dark gaps between florets are inside it (see limits).
2. Edge refine: `tools/matte.py union` + `refine --erode 1 --feather 1.0` (foreground colour estimation). On magenta (`evidence/cutout_on_magenta_crop.png`) the edge shows no halo of the dark forest behind; florets edges are soft but not rectangular.
3. Clean plate: LaMa (`tools/clean_plate.py`), mask dilated 9 px. The plate behind the cluster is a plausible rock ridge and soft forest (`evidence/plate_blue_removed_crop.png`). Only visible where the cluster sways away.
4. Build: warp layer (crop 180×170 at (1090,350), two loopable displacement maps, amp 8, period 6 s). Displacement grows with distance from the stem root (1245,498) inside the rock, ^1.6, with a small phase lag up the stem and a 0.2 vertical dip. So the stem is pinned where it enters the rock and the head swings most. A new scene id with its own plate means the older flower_pond scene (where this cluster is left still) is untouched.
5. Verify: `tools/delivery.py build/verify` ok (11 files); Godot gl_compatibility, `--fixed-fps 60`. Dimmed/undimmed mean ratio 0.5472 in the cluster box and 0.5477 over the whole frame (0.55 expected after sRGB rounding): no bright rectangle. Pixels outside the warp rect are identical to the still (mean abs diff 0.0). Head displacement measured ~4 px at amp 6 before I raised it to 8; at amp 8 it is visibly ~6 px left-right between phases (`evidence/sheet_phases.png`).

## Decisions
- Cut the cluster despite the earlier flower_pond note that SAM2 cannot cut fuzzy blue clusters: this one is compact and against dark background, and SAM2 gave a usable mask. The left-edge blue cluster was not tried.
- Warp (displacement) rather than video: matches the existing player, loops exactly, ships small. Whole cluster moves as one body; no per-floret motion.
- Amp 8 over 6: 6 looked nearly still at this size.
- Stem root pinned (weight 0 at the root) because the stem disappears into rock; moving it would reveal the plate's invented rock.

## Did not work / unresolved
- The shader's time is `TIME`, not the player's `seek()`: stills at different `--t` look identical; I used `--fixed-fps` and `--frames` to pick phases. Not changed (player untouched).
- Mask of the head has a small dark speck at the top-left (also in the still); the dark gaps between florets move with the blob, so a bit of dark rather than forest is carried — only visible at 3x zoom.
- The LaMa plate was not stress-checked beyond ±8 px sway; a bigger sway would show invented rock/forest.
- Not tried: Forward+ (only gl_compatibility as requested), a second matting method (ch-0001 trimap trial), per-floret motion.
- `wfe knowledge` was not consulted.

Files: `scenes/blue_sway_right/recipe.json`, `experiments/partial-animation/blue_right/{spec.json,build.py,out/}`, `devdocs/runs/partial-animation/run-006/evidence/`.
