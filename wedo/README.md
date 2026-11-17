# gimmickimg wedo: reusable findings

One Markdown file per finding in `findings/`. A finding says what a technique or lesson is, under which
conditions it was observed, what it rests on and where it stops. It is not a run report and does not tell a
later task what to do. Run reports (`devdocs/runs/`) and experiment notes (`experiments/`) stay where they are;
findings link to them.

The header and its vocabulary are defined by the contract, not here: `wfe knowledge --help` and agdevworld
`workflow_editor/docs/knowledge.md`. Check with `wfe knowledge check gimmickimg:wedo`.

Local habits on top of it:

- `status` here uses `observed-once`, `observed-repeatedly`, `conflicting-observations`.
- Where a finding's statement kind (technique, lesson, comparison) matters, say it in the body or `status`, not in
  `categories`.
- An `acceptance` reference says in `by` whether it is the person's review or an agent's acceptance, and the
  finding's body says what no person has reviewed.
- Keep `summary` to what the finding offers and where it stops; a finding does not tell a later task what to do.

Index:

| id | title |
|---|---|
| gimmickimg-f-0001 | [Moving a cut-out part widely across a still](findings/moving-cutout-part-across-still.md) |
| gimmickimg-f-0002 | [Cut-out of an object from a still: SAM2 + erosion + feather + foreground colour](findings/clean-cutout-from-still.md) |
| gimmickimg-f-0003 | [Looping a generated clip: first=last gave opposite results](findings/looping-generated-clip.md) |
