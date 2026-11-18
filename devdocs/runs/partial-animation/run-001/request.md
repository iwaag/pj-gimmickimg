Please animate exactly one small part of a still, as a first bounded run of this workflow.

- Image: the flower pond still that experiments/partial-animation builds on (the same image as its out/clean_plate.png source; use the original
  still recorded in experiments/partial-animation/README.md, by name and hash).
- What moves: one leaf only, `leaf2` in experiments/partial-animation/out/masks/ if it segments cleanly, or another single leaf if it does not.
  A slow, small tipping sway. Everything else stays still.
- Renderer: Godot 4.7, gl_compatibility only. Dimming to check: 1.0 and 0.55.
- Keep it small: this checks that the workflow runs from its nodes. Do not rebuild the flower scene, do not animate other parts and do not change the
  workflow definition. No separate delivery for another project is needed beyond what the verify node asks.
- A plain result is fine: record the real numbers and the limits you find. If a node cannot be done here, say so in its outcome.

The requester, improve-wfrun-p2-check, answers questions, including the result confirmation. That requester is an Omni Agent's check actor, not the developer.
The earlier flower scene made under freework/run-018 is not this test.
