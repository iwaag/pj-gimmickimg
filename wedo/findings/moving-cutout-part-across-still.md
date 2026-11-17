---
id: gimmickimg-f-0001
title: Moving a cut-out part widely across a still (the bee of flower_pond)
summary: A part of a still (a bee) can be made to fly a long loopable path by treating it as its own cut-out layer driven by sampled path data; the effort goes into making the part separable (bee-free plate, re-cut of what it covered) and into hand-set depth and orientation rules, not into the motion code.
categories: [motion, composition]
tags: [partial-animation, cut-out, path-motion, clean-plate, occlusion, godot, flower_pond]
status: observed-repeatedly
updated: "2026-11-04"
references:
  - {role: evidence, ref: devdocs/runs/partial-animation/run-002/report.md, note: "what was done, checks that ran, known defects; written by the producing agent"}
  - {role: evidence, ref: experiments/partial-animation/run_bee.sh, note: "the order of steps as run (mask, LaMa on bee, re-cut leaf, matte, plate)"}
  - {role: evidence, ref: experiments/partial-animation/build_bee.py, note: "body/wing split, 337-sample path"}
  - {role: evidence, ref: scenes/flower_pond/recipe.json, note: "revision 3 holds the path layer; r2 is in git history"}
  - {role: acceptance, by: "ponderer-agent (requester, an agent)", ref: devdocs/runs/partial-animation/run-002/run.json, note: "node review: bee reads as flying, edges ok, no bee left on plate, no front/behind pop; defects accepted. No review by the person (iwaag) is recorded in this run."}
  - {role: illustration, ref: devdocs/runs/partial-animation/run-002/presentations/p1/content/bee_flight_14s_loop.mp4, note: "the clip to watch; NOT a faithful capture: ~18 repeated frames from a stalled capture tool, and the 11 Hz wing flutter is only visible live"}
  - {role: illustration, ref: "a delivery on the working installation's shared storage (not public)", note: "published delivery of flower_pond r3 (Godot player + scene); runnable, not re-run by the writer of this finding"}
  - {role: evidence, ref: devdocs/runs/partial-animation/run-003/report.md, note: "second use of the path layer: leaf2 comes loose and drifts across the pond (44 s loop); added an optional 7th sample value, opacity; judged by the producing agent only"}
  - {role: evidence, ref: devdocs/runs/partial-animation/run-007/report.md, note: "birds_glide r1: two tiny sky birds on 60/48 s glides with fade-restart; sky means no re-cut or depth rule; producing agent's own checks only, no review recorded"}
  - {role: context, ref: devdocs/runs/freework/run-018/report.md, note: "the SAM2 mask of the bee (and the matte pipeline) came from here; see gimmickimg-f-0002"}
---

# Moving a cut-out part widely across a still

## What was observed
In `flower_pond` (still `assets/flower_pond/view.png`), the bee, previously a static part of the picture, became
its own layer and flies a 14 s figure-eight (x 156–1196, y 245–565 px) that loops. The request was framed as
"existing swaying method + coordinate movement"; the producing agent's answer was that this was about right:
the new layer type was about 60 lines of player code. Most of the work was elsewhere.

## The technique, in the order that worked
1. Mask the part (SAM2; the existing bee mask was good, one antenna tip was added by hand as a 5 px line).
2. Fill the part out of the **still** (LaMa) to get a still without it.
3. Re-segment and re-matte whatever the part used to cover (here the big leaf) **on that still**. Otherwise the
   leaf cut-out contains the bee and "the bee moves twice".
4. Matte the part (`tools/matte.py refine`, erode 1, feather 0.8) and build the clean plate from the part-free still.
5. Drive the part by a `path` layer: samples `[t, x, y, rot, scale_x, scale_y]` (337 of them), played looped;
   wings were a separate piece (alpha 0.72, translucent in the photo) rotated about their root at 11 Hz ±16°.
6. Depth is a rule: a draw-order window puts the part in front of or behind named layers during parts of the loop;
   the switch is placed at the crossing where nothing overlaps (no visible pop). Scale differs per lobe
   (1.5x in front, 0.9x behind).

## Conditions
One image; one object that was already well segmented; Godot 4.7.2, gl_compatibility on macOS Metal;
player and recipe format extended in the same run (`type: path`, `seek(t)`).

## Limits and contrary observations (all from the producing agent's own report)
- One pose only (a side view facing left), mirrored when flying right. The turn is a squash through edge-on, not 3D.
  Wings are a rigid piece, not a flap cycle; antennae mostly lost; faint green fringe at the front legs.
- "Behind" only works against cut-out layers (the swaying flowers). Uncut things (rocks, anything in the plate)
  cannot occlude the part. Depth does not come from depth estimation.
- Checks that ran: scene loads; one full loop in frames and stills judged by eye; dimmed/undimmed pixel ratio 0.548
  in the bee's box at modulate 0.55 (plate 0.547); delivery build + verify.
- Checks **not** run: Forward+, a numeric loop-seam diff (periodicity is by construction, t=0 equals t=1 samples),
  frame-by-frame judgement of wing flutter.
- Not compared: no other motion method (e.g. generated video of the bee) was tried, so "path layer is the right way"
  is not shown, only that it worked here.

## Whose judgement
The "reads as flying" verdict is another agent's (the requesting project's agent, after viewing the presentation).
The producing agent's checks are its own measurements and eye. The person's judgement of this result is not
recorded in the run; ch-0001-style edge preferences of the person are in gimmickimg-f-0002.

## Later observation (partial-animation/run-003, producing agent only)
The same `path` layer drove a second part, leaf2 (881 samples, 44 s loop: rest, fall with decaying sway, 25 s drift
across the water, fade out and back in). It reused leaf2's earlier cut-out and plate, so little of the separability
effort was repeated. Path samples gained an optional opacity value (2 lines of player code) because a lobe cannot be
shown growing back from one flat cut-out; the restart is a fade. Limits seen there: the leaf is drawn over everything
including shore grass (grass is in the plate, cannot cover it), no wake or reflection, a hard stop on landing, and for
about 7 s per loop the big leaf is missing its lobe. Path numbers were chosen by eye, not from depth. No person or
requesting agent review is recorded; Forward+ and the fade under dimming were not checked.

Partial-animation/run-005 (report on main, not in this copy, so not a checked reference) used the layer a third time: the same matted bee sprite,
shrunk to about 0.3x, flew its own 9 s loop over the far meadow, with no new cut-out or plate. Layer order was set by
a path calculation (the small bee would otherwise pass over the big one about 5% of the time); depth is layer order
only. Limits there: same pose, antennae lost, far bee not occluded by still flowers (they are in the plate), Forward+
not checked. Accepted by Omni Agent as an experiment; no person has looked.

Partial-animation/run-007 (birds_glide r1, on main and in this copy) used it a fourth time on a different kind of part: two tiny
(~230 px, ~25 px wide) blurred far sky birds, cut with the finding-0002 pipeline, LaMa plate, a straight 60 s / 48 s glide
(~4 px/s, small bob and roll, 6 % scale swell) that restarts by fade-out/fade-in (opacity, the 7th sample value from leaf2),
since a straight path cannot close. Here the separability effort was nearly nil (sky covers and is covered by nothing, so no
re-cut and no depth rule), which fits "the effort is in separability" from the other side. The producing agent states it
adapted this finding (dropped the re-cut and depth rules, added the fade-restart); the work matches that. Checks, all its
own: recomposite error 0.54/0.43 grey levels, outside the sky box render equals the still, dim ratio 0.545-0.550 at 0.55.
Limits there: one frozen pose, no wing flap; faintest wing tips beyond the mask lost; plate smoother than the grain; both
birds go right, heading ambiguous; paths by eye (bird A ends ~35 px from a frozen bird); Forward+, a numeric loop-seam diff
and a live watch of the clip were not done. No person or requesting agent review was recorded when it finished.

## Not established
Whether a different bee image, a faster path, or a part that overlaps more uncut content works; whether a path past a frozen
neighbour (run-007, ~35 px) or through detailed content reads right in motion; whether the
depth rule survives a path that crosses rocks.
