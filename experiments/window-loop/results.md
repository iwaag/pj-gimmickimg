# ch-0004 first experiment — animated far view behind a window (gimmickimg, 2026-10-24)

Summary: the pipeline works end to end (generated room -> interior RGBA with glass alpha 0 + LaMa-filled outdoor plate -> local MiniMax H3 on a GPU workstation -> Theora -> Godot 4.7 plays it behind the interior PNG). First=last-frame H3 loops but barely moves; first-frame-only H3 + ping-pong moves well and loops without a visible seam.

## Pipeline (all in experiments/window-loop/)
1. scene.png: Qwen-Image 2512 Lightning on the GPU workstation (tools/gen_scene.py), 1344x768, 6-pane sash window, seed 2 of 3.
2. tools/split.py: panes = bright pixels -> hole fill -> open (cuts the chair tip) -> per-pane bounding box, clipped at the sill -> mask_raw.png; interior_rgba.png (glass alpha 0, 1.2 px feather, 2 px erode); mask_overlay.jpg shows it. SAM3 had no weights on the GPU workstation so it was not used (see verify.md).
3. tools/plate.py: crop window box (351,83)-(950,522), LaMa (Mac, torch 2.2 cpu) on mullions+latches at 1.8x -> plate.png (1088x800), plate_736.png (736x544 used for H3). Faint seams where mullions were; hidden under the interior layer.
4. tools/h3.py: local MiniMax H3 FL2VA int8 + Turbo LoRA (6 steps), 736x544, 73 frames (3 s @24 fps).
5. tools/to_ogv.sh (imageio's ffmpeg has libtheora; Homebrew's does not) -> godot/video/*.ogv; godot/main.gd: VideoStreamPlayer (loop, expand) at the window box behind a Sprite2D of interior.png. Keys 1-3 switch arm. capture/*.mp4 are real Godot renders (--write-movie).

## Arms (tools/metrics.py; step = mean |frame diff| in 0-255; seam = last vs first frame)
| arm | what | step | max drift from f0 | loop |
|---|---|---|---|---|
| a_fl | first=last=plate, "gentle" prompt | 0.55 | 1.6 | wrap step in Godot 1.3-1.4 vs ~0.05 typical = a small visible jump; motion almost static |
| a2_fl_strong | first=last, "time-lapse, strong wind" prompt | 0.57 | 1.7 | same: prompt strength changed nothing |
| b_first + ping-pong | first frame only, play 0..72..1 (144 frames, 6 s) | 1.58 | 21.5 | seamless by construction; Godot wrap step not distinguishable from the other steps (max 2.0 anywhere) |
Smoke test with first=last on another image: decoded last frame differed from frame 0 (mean 9.3), so the end anchor is soft, not a pixel-exact pin.

## What worked
- Local H3 needs no API key: 736x544x73 frames takes 160-260 s on the GPU workstation. 1088x800x124 did not finish in 20+ min (VRAM was ~49/50 GB) and was interrupted — use <=~0.4 MP.
- Interior-with-holes over video needs no video alpha. The window cut-out is clean at 1344x768; the mullions hide the plate seams.
## Motion quality
- a/a2: clouds creep a few px, trees nearly still — reads as a still image. Confirms archsage's "first=last suppresses motion" for H3 too (n=1 clip each, one scene).
- b: clouds billow and drift, trees shimmer; but contrast/colour change over the clip (drift 21.5), clouds grow rather than translate, so a reversal is visible as clouds shrinking back. Plausible for a far view; not tested at longer length.
## Not done / uncertain
- Wan 2.2 FLF2V and cloud H3 were not run. No crossfade/VAEDecodeLoopKJ arm. Single scene, single seed per arm. Alpha edge quality at the window frame only checked by eye in Godot captures.
## Next
1. First=last with a mid-clip guide frame (MiniMaxH3AddGuide) or a slightly different last frame (e.g. cloud-shifted plate) instead of identical frames.
2. Wan 2.2 FLF2V arm; crossfade/RIFE bridge instead of ping-pong; longer clips (124 frames) at 640x480.
3. Colour-match the video's drift (histogram match to frame 0) to remove the contrast pulse.
