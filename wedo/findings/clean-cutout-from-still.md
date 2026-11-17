---
id: gimmickimg-f-0002
title: Cut-out of an object from a still - SAM2 mask, 1 px erosion, feather, foreground colour estimation
summary: "Replacing hand-drawn ellipse masks with SAM2.1 box+point masks, then eroding 1 px, feathering and estimating foreground colour, removed the surrounding grass from 7 of 8 mushroom cut-outs and is the edge method behind flower_pond; the individual steps were never tested one by one, and for fuzzy, translucent or occluded objects the evidence is mixed - two compact blue flower clusters were cut and swayed with SAM2 as a solid silhouette (florets not separate, softer, small sway); translucent and occluded cases are still not solved."
categories: [extraction]
tags: [segmentation, sam2, matting, pymatting, edge, cut-out, ch-0001, mushroom, flower_pond]
status: observed-repeatedly
updated: "2026-11-04"
references:
  - {role: evidence, ref: experiments/edge-extraction/summary.md, note: "first trial: 8 ellipse components vs SAM2; sizes, 7 of 8 clean, what was not solved; the agent's own judgement on magenta/white/black"}
  - {role: illustration, ref: experiments/edge-extraction/compare_ellipse_vs_sam.png, note: "ellipse (top) vs SAM (bottom) on magenta/white/black"}
  - {role: evidence, ref: devdocs/runs/freework/run-008/report.md, note: "Wan sway re-run on the SAM2 cut-outs: clean at rest, but seed 3 invents a second stem on the big mushroom; seed 2 stable"}
  - {role: evidence, ref: devdocs/runs/freework/run-018/report.md, note: "same method on 8 flower_pond objects; edge crops r1 (opaque rectangle, 24 px hand feather) vs r2; dimming ratios"}
  - {role: acceptance, by: "ponderer-agent (requester, an agent)", ref: devdocs/runs/freework/run-018/run.json, note: "review node: r2 accepted after viewing edge and dimming comparisons; the node says the person's (iwaag) own review 'follows later' - not recorded in this repository"}
  - {role: evidence, ref: devdocs/runs/partial-animation/run-001/report.md, note: "leaf2: mask 12828 px, defaults, outside-region render identical to the still, edge ring dim ratio 0.5475; cut-out 'slightly softer'"}
  - {role: evidence, ref: devdocs/runs/partial-animation/run-002/report.md, note: "bee: same pipeline, feather 0.8; translucent wings handled by hand (polygon + alpha 0.72); green fringe remained at the legs"}
  - {role: evidence, ref: devdocs/runs/partial-animation/run-004/report.md, note: "blue_sway r1: middle blue cluster (dark backdrop) cut with head-only prompt, matted, swayed 7 px; stem prompt failed; hull silhouette, softer head. Accepted by Omni Agent (an agent) for one dark-backdrop cluster; not the person"}
  - {role: evidence, ref: devdocs/runs/partial-animation/run-006/report.md, note: "blue_sway_right r1: right cluster (1160,415) against rock/leaf, heads and stem/leaves as two clean SAM2 masks, pivot pinned in rock, about 6 px sway; reviewed by the producing agent only"}
  - {role: evidence, ref: devdocs/runs/partial-animation/run-003/report.md, note: "leaf2 reused from run-001 (cut-out edge not re-measured); 1-2 px ring around the leaf differs from the still; no person looked"}
  - {role: evidence, ref: devdocs/runs/partial-animation/run-007/report.md, note: "birds_glide: two ~230 px sky birds cut with matte.py defaults; recomposite error 0.54/0.43; producing agent only, and it says it did not read this finding"}
  - {role: illustration, ref: devdocs/runs/freework/run-018/presentations/p1/content/index.html, note: "edge crops before/after; r1 vs r2 mixes several changes, see Limits"}
  - {role: context, ref: tools/matte.py, note: "the reusable form: segment / union / refine; needs torch, transformers (facebook/sam2.1-hiera-large), pymatting; Apple MPS or CPU"}
  - {role: context, ref: "challenge ch-0001 (wfe challenge show ch-0001)", note: "the person's feedback that motivated it (quoted there, conversation 20261022-230244-zlcew6 #310); state resolved, last changed by iwaag 2026-10-23. Read by the writer; the reason for resolving is not recorded there."}
  - {role: unchecked, ref: devdocs/runs/freework/run-007/, note: "origin runs of the mushroom trial (run-007..009) were not read; their content is taken from experiments/edge-extraction/summary.md and run-008's report"}
---

# Getting a clean cut-out of an object from a still

## What was observed
- **Problem** (the person, after freework/run-006): cut-outs made with hand-drawn ellipses carried bits of grass and
  moss that moved with the mushroom when it was animated.
- **Trial** (experiments/edge-extraction): SAM2.1 hiera-large (Hugging Face transformers, local, Apple MPS) was given
  each component's bounding box plus its deepest interior point; then erode 1 px, Gaussian feather sigma 1,
  `pymatting.estimate_foreground_ml` to remove background colour from edge pixels. The SAM masks were 20–35 % smaller
  than the ellipses for the large mushrooms (10658 -> 8358 px); 7 of 8 cut-outs looked clean on magenta, white and black.
- **Reuse**: `tools/matte.py` packages this (it also closes pin-holes, fills holes and drops specks < 150 px
  before eroding - whether the first trial did the same was not checked). The same defaults were used for 8
  flower_pond objects (freework/run-018), a leaf (partial-animation/run-001) and a bee (run-002, feather 0.8).
  Each of those reports checked that the cut-out did not move anything outside its region (leaf: 0 px changed outside,
  render identical to the still) and that it dims with the scene (ratio 0.548–0.549 vs target 0.55).

- **Update from partial-animation runs 003-006 (agents only).** Run-004 and run-006 cut and swayed two of the
  fuzzy blue clusters that this finding first listed as not cut out. Run-004 (middle cluster, dark backdrop): a
  head-only prompt (box, 3 interior and 2 negative points) gave a clean 3162 px mask; no halo on magenta/black/white;
  a variant prompting the thin stem failed (merged stem, backdrop and a purple flower), so the stem stays in the
  still and the head pivots at its base. Run-006 (right cluster at (1160,415), against rock and leaf): heads
  (4290 px) and stem/leaves (2239 px) both came out clean on the first try, with negative points on the neighbouring
  stem; no halo of dark forest on magenta; stem pinned where it enters the rock. Both checked dimming (0.549 and
  0.547 vs 0.55 target) and that pixels outside the warp rectangle equal the still. Run-003 reused leaf2's
  cut-out and found a 1-2 px ring around it differing from the still (777 px over 30 levels).

- **Update from partial-animation/run-007 (agent only).** The same pipeline (via `tools/matte.py` defaults, feather 0.8)
  cut two tiny far sky birds (SAM2 masks of 236 and 228 px, generous with a halo and missing the faintest wing tips, by
  eye on overlays). Check: cut-out recomposited over the LaMa plate reproduces the still (mean abs error 0.54 / 0.43 grey
  levels), which shows the pair is consistent, not that the edge looks right on a differently coloured sky; moving birds
  looked like their frozen neighbours at 3x, no halo seen, dim ratio 0.545-0.550. Honest caveat from that run: it did
  not read this finding; the method matched by coincidence of tool defaults, so this is another use of the pipeline,
  not a test of the finding's advice. It does not touch the open cases (fuzzy, translucent, occluded): the birds are small,
  dark, blurred and opaque against sky.

## Conditions
Still images of a garden/forest scene at about 1000–1300 px; solid, opaque objects with a visible boundary; one
prompt (box + point) per object; SAM2 run locally (the GPU workstation's ComfyUI had no SAM2/BiRefNet/matting weights; SAM3 nodes
existed without a checkpoint). Followed by LaMa inpainting for the plate behind the object.

## Limits and contrary observations
- **No ablation.** Erosion, feather and foreground-colour estimation were always applied together. The data show
  "SAM2 + all three" beats "ellipse"; nothing shows how much each of the three contributes, or that 1 px / sigma 1
  are good values (0.8 was used once without comparison).
- The flower_pond before/after (r1 vs r2) compares an opaque rectangle with a hand feather against SAM2 cut-outs plus
  a clean plate: the gain is not attributable to the matting alone.
- Occluded objects: the top-right mushroom is partly hidden by grass, so its cut-out is fragmented (SAM is right; the
  ellipse had hidden that). One of the eight components was missing from the SAM mask and vanished.
- Fuzzy blue clusters: first listed as not cut out; now two were (see Update), so "not cut out" is withdrawn for compact clusters on a dark or rock backdrop. What remains: both masks are solid hulls (gaps between florets hold backdrop and move with the cluster; fuzzy tips rounded, "crisp floret tips lost"), the heads look softer when displaced, sway is small (about 6-7 px; larger would show the invented plate in run-006), no per-floret motion. The left-edge cluster and the small pink flower were not tried. A trimap/ViTMatte trial (ch-0001) was not run in either. Stems are cut where SAM2 ends, and in run-004 not cut at all. Cut-outs are
  slightly softer than the still (leaf2). A trimap/ViTMatte step was judged unnecessary at this resolution, not tried.
- Translucent parts (bee wings) needed hand handling; a waterfall (semi-transparent water/mist) was not cut with SAM2
  at all (hand polygon, sigma 9) because there is no solid edge; a window interior used threshold + bounding boxes
  because the SAM3 weights were missing. So the method is for solid objects; it was not tested against those cases.
- Downstream: a generated sway (Wan 2.2) on clean SAM2 cut-outs can still invent geometry (second stem, seed 3).
  That is a property of the video model, not of the cut-out, but it hides edge quality.
- Judged "at rest" or in short loops on stills and clips; not a long clip with the person watching.

## Whose judgement
Edge quality in the trial, in the run-018/run-002 reports and in runs 003/004/006/007 is the producing agent's eye plus measurements; run-018,
run-002 and run-004 were accepted by the requesting agent (run-004 accepted from edge and phase crops, not the delivery;
run-006, run-003 and run-007 had no review beyond the producing agent). No person has looked at the blue-cluster results. The person's judgement exists only as the original complaint
and the later resolution of ch-0001; a person's review of the new edges is, per run-018's node, still pending.

## Not established
Which step matters; whether the blue-cluster result holds for the left cluster or in other lighting; whether the softness is acceptable beside the other flowers (left open in run-004); behaviour on other image types (portraits, photographs with soft depth of field, night scenes);
robustness without a point prompt; the effect of image resolution.
