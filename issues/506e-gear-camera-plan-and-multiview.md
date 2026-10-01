# 506e - Gear Camera Plan and Multi-View Rings

## Status
- Created: 2026-09-27
- Phase: 5
- Parent: 506
- Blocked by: 506b (a concept view to start from); Stable Zero123 weights
  installed; ComfyUI running (locally or on a remote host)
- Priority: High

## Current Behavior

**Written 2026-09-27, untested** (ComfyUI can't run yet):
- The camera plan as data: `assets/gear-designs/camera-plan.lua` (eight
  compass views per ring; rings middle 0, above 20, below -20, higher 40,
  lower -40 degrees; levels of 1, 3 or 5 rings; the four views the mesh
  stage takes).
- The workflow `assets/gear-designs/comfyui/multiview.json`: ComfyUI's
  built-in Stable Zero123 (`StableZero123_Conditioning_Batched`) makes one
  ring as a batch of eight, azimuth 0 in 45-degree steps, at the ring's
  elevation.
- The client: `scripts/gear-comfy-submit --workflow multiview --ring
  NAME`, saving `mv_<ring>_NNNNN_.png` in the design's folder.
- Checked (`scripts/test-gear-designs`, parts 6 and 7): every node and input
  against the installed ComfyUI source; the plan's eight views 45 degrees
  apart and five rings, middle first; the workflow's batch agreeing with
  the plan. Two planted faults (a wrong step, a misspelt input) each fail
  it.

## Intended Behavior

The owner, 2026-09-27, verbatim:

> We'd generate pictures at first one of 8 angles (compass orientated
> webcams facing in) then we'd gather middle and lower shots too, then 5

> then a ring above and below the middle ring. that's the 5 I mentioned.
> Each with 8 perspectives of them on the subject, whatever kind of model
> it is that we're trying to generatee.

> eight x (1 or 3 or 5) webcam interially focused radially spread

> my friend was hacked when using someone else's utilities. I'll only use
> their maps of the utilities that come with the software. I can do a
> model though, because models do not determine behavior.

- Every subject (an item, a creature, a character) is seen by the same
  rig: eight cameras facing in, 45 degrees apart, at 1, 3 or 5 heights
  (8, 24 or 40 views), made by a multi-view model so the views agree.
- Built-in ComfyUI nodes only; downloaded weights allowed, safetensors
  preferred (`docs/gear-3d-pipeline.md`, "Security").

## Suggested Implementation Steps

1. Download Stable Zero123's weights (a safetensors copy if one exists;
   otherwise the `.ckpt`, which ComfyUI loads weights-only) into the
   installation's checkpoints, with its `import-models`.
2. **Test** once ComfyUI serves: `scripts/gear-comfy-submit --profile
   <id> --workflow multiview --ring middle` after that design's concept
   view exists. Pass: eight `mv_middle_*.png` in its folder, a line each in
   `assets/gear-designs/generated.tsv`, and the same eight again with the same
   seed.
3. **Which way azimuth turns**: look at views 1-3 of a subject with a
   marked left side (a shield on its left arm); if the marked side shows in
   view 3 (90 degrees), the plan's `mesh_inputs` are right; otherwise swap
   left and right there.
4. Run the other rings; judge how far from level the model holds up (its
   training covered about 30 degrees up or down), and tune the heights in
   the plan.
5. The gallery shows the ring views (506d reads the design's folder).

## Related Issues

- **506** parent; **506b**; **506f** takes four middle-ring views
