---
id: gimmickimg-f-0003
title: Looping a generated clip - first=last conditioning gave opposite results in two scenes
summary: With the same local MiniMax H3 setup, first=last-frame conditioning barely moved a window's far view (clouds, trees) but looped a waterfall cleanly while keeping its flow; ping-pong looped both but reversed the waterfall's flow. Which loop method to use depended on the subject; each arm is n=1-2 on one scene.
categories: [generation, motion]
tags: [video-generation, loop, minimax-h3, first-last-frame, ping-pong, crossfade, waterfall, window, godot]
status: conflicting-observations
updated: "2026-11-04"
references:
  - {role: evidence, ref: experiments/window-loop/results.md, note: "freework/run-010: arms a (first=last, gentle), a2 (first=last, strong prompt), b (first only + ping-pong); metrics step/drift/wrap"}
  - {role: evidence, ref: devdocs/runs/freework/run-010/report.md, note: "same content, run summary"}
  - {role: evidence, ref: devdocs/runs/freework/run-013/report.md, note: "freework/run-013: arms a (first=last), b (ping-pong), a + 16-frame crossfade, c (last = first shifted down 40 px); seeds 1,2"}
  - {role: illustration, ref: experiments/window-loop/capture/b_pingpong.mp4, note: "Godot render of the window arm b; the arm a/a2 renders are beside it"}
  - {role: illustration, ref: devdocs/runs/freework/run-013/presentations/p1/content/compare_a_loop_vs_b_pingpong.mp4, note: "waterfall loop vs ping-pong side by side - a person can watch the reversal"}
  - {role: acceptance, by: iwaag (the person), ref: devdocs/runs/freework/run-013/run.json, note: "review rv1: 'good result, please finish'. The review page asked whether first=last is preferred over ping-pong, so this covers the waterfall choice; the reason is not stated."}
  - {role: acceptance, by: producing agent only, ref: devdocs/runs/freework/run-010/run.json, note: "window-loop: no person's review recorded; 'loops seamlessly' is the agent's metric and Godot captures"}
  - {role: context, ref: experiments/window-loop/verify.md, note: "environment: H3 local on a GPU workstation, Theora via imageio's ffmpeg, SAM3 weights missing"}
---

# Looping a generated clip

## The two observations
Both used local MiniMax H3 (FL2VA int8 + Turbo LoRA) through ComfyUI on a GPU workstation, 73 frames, histogram-/step-based metrics
(step = mean |frame diff| in 0–255).

| | window far view (run-010) | waterfall (run-013) |
|---|---|---|
| size | 736x544 | 480x640 |
| first=last | step 0.55 (0.57 with a "strong wind" prompt); max drift from frame 0 1.6–1.7; wrap step 1.3–1.4 in Godot vs ~0.05 typical = small visible jump; clouds creep a few px, "reads as a still" | step 4.5 (seed 1), 3.65 (seed 2); wrap step 2.45 / 2.47; water flows down (+3.6 px/frame optical flow); loops without visible jump |
| first only + ping-pong | step 1.58, drift 21.5; wrap step not distinguishable from others; clouds billow, but grow rather than translate, so reversal shows as clouds shrinking | step 7.3, wrap 1.6 (metric-seamless), but water flows **up** on the way back (-5.0 px/frame) |
| other arms | none | first=last + 16-frame crossfade: wrap 4.4, worse than plain loop. Last = first shifted down 40 px: wrap step 26.8, whole scene dragged to the shifted frame - **rejected** |

Reading: first=last suppressed motion for a slow far view (clouds, trees) but not for a high-motion subject, where the
model's own flow carried through to the end frame. Ping-pong is safe for subjects without a direction (clouds),
not for directional flow (water). The producing agents' own explanation is "high-motion subject"; it was not tested.

## Why the comparison is weak
Scene, size, subject, prompts, and the frame given as anchor all differ between the two columns, so "subject" is only
one candidate explanation. Seeds: window n=1 per arm, waterfall 2 seeds (a, b), c partial; a third waterfall seed was
started and killed. A smoke test on another image showed the decoded last frame differs from frame 0 (mean 9.3/255)
even when first=last is given, so the end anchor is soft, which would also produce different behaviour per scene.
The waterfall frames were histogram-matched to frame 0 (a drift fix); the window frames were not (drift 21.5 remains and
was listed as a next step).

## Rejected / worse arms (kept on purpose)
- Crossfade (16 frames) on the waterfall: worse seam metric than the plain first=last loop.
- Shifted last frame (c): the generated motion bends the entire scene toward the shifted frame; wrap step 26.8.
- Stronger prompt on the window with first=last (a2): no change in motion (0.57 vs 0.55).
- Not run in either: Wan 2.2 FLF2V, VAEDecodeLoopKJ, a mid-clip guide frame (MiniMaxH3AddGuide), RIFE bridges, clips
  longer than 73 frames at these sizes (1088x800x124 did not finish in 20+ min on that workstation: VRAM ~49/50 GB; keep to ≲0.4 MP).

## Whose judgement
Window: metrics plus the agent's look at Godot captures; no person's review recorded. Waterfall: seam judged on stills and
metrics by the agent; the person reviewed the presentation (which includes the side-by-side clip) and approved the result.
No review isolates the loop point from the rest of the scene, and the hand-polygon edge of the waterfall sprite was
part of the same review.

## Not established
A rule for choosing the method before generating; behaviour of other subjects (rain, fire, foliage), other models,
longer clips; whether the soft end anchor can be tightened.
