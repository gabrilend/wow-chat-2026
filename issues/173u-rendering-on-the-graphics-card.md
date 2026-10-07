# 173u - Rendering on the Graphics Card

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173f (ground), 173g (doodads), 173j (figures), 173o (particles)
- Related: 173t (creatures within sight), 173s (tiles)
- Checklist: `docs/custom-client-optimization-checklist.md`
- Priority: High

## Origin

The owner, 2026-10-06, on creatures costing 6 ms a frame: "um... 6ms per
frame sounds like a lot." Then: "what are we doing on the CPU right now?
The visual rendering should be entirely GPU based. Can you give me a
breakdown of what must be CPU and what we can offload, and if it would be
better or worse?" Then: "can you write these into an optimization
checklist in the docs/ directory?"

## Current Behavior

Measured (picture reports' per-phase timing, 2026-10-06): about 36 ms a
frame at Astranaar, the graphics card waiting on the processor. The
processor issues about 2,300 ground draw orders and thousands of doodad
ones a frame, bends figures and swaying doodads point by point and
re-sends them, re-poses camera-facing doodad copies, rebuilds particle
squares, and re-sends the sky's colours. Nothing is skipped for being out
of sight except creatures (beyond 100 yards or behind the camera).

**Step 1 built (2026-10-06):** the ground is four draw orders a tile,
quarters out of sight skipped (`sight.h` / `sight.c`: the view's six
walls from the camera's matrix, and a ball test; tested without a
window). Ground: 10.6 ms to 0.04 ms a frame, about 6 orders. Picture
reports now count the ground's orders.

**Step 2a built (2026-10-06):** doodad and building copies outside the
camera's sight aren't drawn (each model's visible copies gathered per
frame; buildings now know their reach). Doodads 13 ms to 2.2 ms a frame,
about 150 orders; the frame without creatures 30 ms to 14.

## Intended Behavior

The processor decides what and where (a few numbers per object); the
card does per-point and per-pixel work; draw orders are few and large.
The checklist's eight items, in its order: ground in one order a tile
with sight tests; doodad sight tests and merged orders; bending on the
card (figures, swaying and camera-facing doodads); sky colours as shader
values; particles in one batch; compressed pictures; loading on a second
thread. Each is measured before and after with the picture report, at
the same place and hour, and the same pictures come out.

## Suggested Implementation Steps

1. Ground (`ground.c`): one mesh per tile; the tile's pictures in a
   texture array (Raylib has none: raw OpenGL through `rlgl`), each
   patch's four layer numbers on its points; blend maps in one tile-sized
   texture; a tile outside the view not drawn. The picture compared
   before and after.
2. Doodads (`doodads.c`): sight tests per copy (bounding sphere against
   the view), pieces sharing picture and blend merged.
3. Bending on the card (`figure.c`, `doodads.c`, the model shader): bone
   indices and weights as point attributes, the bone matrices as a float
   texture per figure; the shader bends; camera-facing bones turned in
   the shader.
4. Sky (`sky.c`): the five colours as uniforms.
5. Particles (`doodads.c`): one instanced draw per emitter.
6. Pictures (`blp.c` and its users): DXT blocks uploaded compressed.
7. Loading (`main.c`'s tile refresh): reading and parsing on a worker
   thread; the card fed on the main one.
8. After each: the picture report's numbers into the checklist.
