# Gimmick scene deliveries

A **gimmick scene** is a still image with animated layers over it, played in Godot: a waterfall that flows, mushrooms
that sway, snow between depth bands. A **delivery** is how one leaves this project for another project or PC. It works
without this repository or a run's working copy. In the working repository it is built and checked by a tool and published to a
shared area; that tool and the scenes are not part of this public selection, so read this page as a description of the
format and of the player API.

## Scenes that can be delivered

| Scene | What it shows | Made in |
| --- | --- | --- |
| `mushroom_waterfall` | `assets/sample.png`: the waterfall flows (MiniMax H3 first=last-frame loop), the mushrooms sway (Wan 2.2 frames) | freework/run-008, run-013 |
| `flower_pond` | a still belonging to another project: flowers sway, the water ripples and glints, pollen drifts, the bee's leaf tips gently; r2: flowers are matted cut-outs over a clean plate; r3 (partial-animation/run-002): the bee is its own layer and flies a figure-eight | freework/run-017, run-018 |
| `leaf_drift` | the same still: leaf2 (the right lobe of the big leaf) comes loose, falls swaying, drifts slowly across the pond, fades and returns (44 s loop); nothing else moves | partial-animation/run-003 |
| `birds_glide` | the same still: two of the far sky birds (cut out with SAM2, sky inpainted with LaMa) glide slowly across the sky (60 s and 48 s loops); nothing else moves | partial-animation/run-007 |

A scene is described by `scenes/<id>/recipe.json` (format `gimmick_recipe` v1): size, the source image, layers in
draw order with their source files in this repository, provenance and known limits. A new scene is a new recipe over
an experiment's outputs; a changed scene is a higher `revision`.

## What a delivery holds

| Part | Content |
| --- | --- |
| `delivery.json` | format `gimmickimg_delivery` v1: scene id, label, revision, size, entry and layers; the source image's sha256; the producing commit and the state of the tree (`clean`, or `modified` with every changed source); provenance and limits; every file by path, size and sha256; how to use it |
| `gimmick/` | the relocatable player (`gimmick_scene.gd`, `alpha_mask.gdshader`) and `scenes/<id>/scene.json` with its layer files |
| `project.godot`, `demo.tscn`, `demo.gd` | a standalone Godot 4.7 project that shows the scene (`--scene=<id>`, `--shot=<png> --frames=<n>`) |
| `README.md` | the same facts for a person |

Layer types in `scene.json` (format `gimmick_scene` v1, paths relative to it): `image` (`src`, `position`), `video`
(Ogg Theora `src`, optional `alpha` image, `rect`, `loop`) and `frames` (`frames[]`, `fps`, `pingpong`,
`position`), `warp` (a crop of the still - an RGBA cut-out over a clean plate, or an opaque crop for background such as water - plus two displacement maps, `map_c` and `map_s`, R=dx G=dy, 127 = none;
displacement = `amp` px x (cos(wt) map_c + sin(wt) map_s), `period` s: a loopable local sway or ripple, zero at the crop's border; it takes `modulate` from the vertex colour, so dimming reaches it),
`sparkle` (`points` [x, y, size, period, phase]: glints added over the still) and `pollen` (`rect`, `count`, `size`,
`velocity`, `seed`, `alpha`: drifting motes that wrap at the rect with a fade) and `path` (`src` body RGBA, optional `wing_src`/`wing_pivot`/`wing_deg`/`wing_hz` for a fluttering part, `origin`, `period`, `samples` [t, x, y, rot deg, scale x (negative = mirrored), scale y, optional opacity 0..1 (a part that fades out and in to restart its loop)] evenly spaced over one loop, optional `behind` layers + `behind_when` [[t0, t1]] to draw it behind them for part of the loop: a sprite that flies a looping coordinate path). Opaque warp rectangles must not overlap; cut-out (alpha) ones may. Coordinates are in the scene's own pixels (`size`).

## Using one

Copy it off the shared area first (an import writes `.godot/` and sidecars next to the files), and check the copy
with `python3 -B tools/delivery.py verify <folder>` from this repository, or by comparing the sha256 values in
`delivery.json` (the WFE output manifest `.wfe-output.json` covers the same bytes).

- **See it:** `godot --headless --path <folder> --import`, then `godot --path <folder>`.
- **In a game:** copy `gimmick/` to any folder of your Godot project, then

  ```gdscript
  var g = load("res://<folder>/gimmick_scene.gd").new()
  g.scene_path = "res://<folder>/scenes/<id>/scene.json"
  g.fit = "cover"            # cover | contain | stretch, like a TextureRect
  g.set_anchors_preset(Control.PRESET_FULL_RECT)
  add_child(g)
  ```

  It is a `Control` that fills the rect you give it, ignores the mouse, and inherits `modulate` (dimming works as on
  a TextureRect). Videos autoplay and loop; freeing the node stops everything. A missing file is skipped and named in
  `g.problems`; `g.ok()` is true when everything loaded. No autoload, project setting or global class is needed.
- **Renderer:** gl_compatibility and Forward Plus (checked on macOS, project_coop p1). Godot 4.7.

## What the first deliveries taught (project_coop p1)

- Check a delivery against the experiment's own capture, not only "it loads": the first player build placed the
  waterfall correctly in logs but drew it oversized and half as bright. Two Godot facts caused it: a
  `VideoStreamPlayer` grows to the clip's own size unless `expand` is set before the stream and the size; and in a
  `canvas_item` shader the incoming `COLOR` already holds texture × modulate, so only its alpha may be replaced.
- A consumer asked whether `assets/sample.png` was its own still; answering with both hashes let it show the
  animation in place of the still without a new recipe. Say which image a scene is built over.
- A new revision replaces the recipe in `main`; earlier revisions survive as their published outputs, so a consumer
  can go back only while those outputs are kept (the consumer kept them).

- A `warp` layer must follow `modulate`: until freework/run-018 it ignored it and, dimmed to 0.55, showed bright rectangles
  (measured: dimmed/undimmed pixel ratio 1.0 in the warp regions vs 0.55 on the plate). In `warp.gdshader` the modulate is
  taken in `vertex()`: in `fragment()` COLOR already holds texture x modulate, so multiplying by it squares the picture.
  Check every delivery with `godot --path <folder> -- --shot=<png> --frames=90 --dim=0.55` (workflow `partial-animation`, node verify).
  (`--dim` sets an opaque grey modulate; `Color.WHITE * 0.55` also halves the alpha and makes layers see-through.)

## What a delivery is not

- Not a guarantee of look: it carries what the producing runs checked and the limits they recorded.
- Not a consumer's integration: where the scene appears, how it is dimmed or timed, belongs to the game using it.
- Not regenerated in place: a better loop is a new revision and a new delivery.
