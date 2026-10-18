# 173u - Rendering on the Graphics Card

*Continues in the W client (`/mnt/kaun/custom-client/`), since the move on 2026-10-07 (173v): docs/005 and docs/047, 302, 305. This issue stays as the record of how the client began; its paths are as they were then.*

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

**Step 3a built (2026-10-06):** figures (her, bystanders, creatures,
their items) are bent by the graphics card: bone numbers and weights on
the points, sent once; the bone poses each frame as a one-row float
picture; the figure shader bends. Creatures 5.2 ms to 1.7 ms a frame.


**Steps 3b and 4 built (2026-10-06):** swaying and camera-facing doodads
(and the skybox) are bent by the card too: bones and weights on their
points; a float picture of bone poses per model, one row shared by a
swaying model's copies, one row per copy in sight for a camera-facing
one (whose bones alone are turned on the processor), all its copies in
one order. Animating doodads 2.0 ms to 0.34 ms a frame. Nothing is bent
point by point on the processor any more.

**Step 5 built, and sight tests for the horizon and water (2026-10-06):**
the sky dome is sent once, its five colours as shader values; the far
horizon's tiles and the water's layers out of sight aren't drawn. Sky
and horizon 0.7 to 0.17 ms, water 0.77 to 0.08. The whole frame at
Astranaar with its creatures: about 13 ms (36 at the start).

**Step 7 built (2026-10-06):** model, doodad and building pictures
stored compressed go to the card as stored (`texture.h` / `texture.c`):
92.2 MB to 13.9 MB round Astranaar. Step 6 (particles in one batch) was
measured small (0.33 ms) and is left for later.

**Step 8a built (2026-10-06):** creatures are built as they come within
110 yards, nearest first, at most 4 ms a frame, and freed beyond 130
(instead of every spawn of a tile at its load). Tile loads (picture
reports now time them): 236 ms on average to 62, the slowest 706 to
126. What stalls a tile load now: the ground's points and blend picture
(the slopes come from the server's heights), and new doodad models.

**Step 8b built (2026-10-06):** a second thread reads ahead the ring of
tiles beyond those loaded (`prefetch.h` / `prefetch.c`), unpacking every
file each will want into the archive reader's memory (now locked, so
the threads share it). Loads while she walks: 48 ms on average to 37.

**Step 8c built (2026-10-07):** a tile's ground is prepared without the
window (`ground_prep.h` / `ground_prep.c`: the file read, the points and
their light, the blend picture, the pictures not yet on the card
unpacked with their smaller copies), by the reading-ahead thread for
the ring ahead, kept until taken (`prefetch_take_ground`), let go when
she turns away (`prefetch_keep_near`). The main thread only sends; each
new picture goes into its own layer with its own smaller copies (the
card's remaking of all 256 layers cost 5 ms a load). The server-height
reader loads under a lock. Walking loads 31 ms to 14 (the ground 23 to
5). Race-checked (`build-custom-client --tsan`) and address-checked.
Left (8d): parsing new doodad models on that thread too (about 9 of the
14 ms).

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
