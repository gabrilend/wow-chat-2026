# The Custom Client's Optimization Checklist

What the custom client (issue 173) does on the processor each frame, what
must stay there, what moves to the graphics card, and in which order.
The work is issue 173u. Tick an item here when it is built and measured.

## How to measure

Run a picture: `scripts/custom-client --shot --hour 12` (add `--goto X Y`
for another place). Its report prints the average frame time, then the
milliseconds a frame spent in each phase, then the creatures' share.
Drawing phases measure handing work to the graphics card; "the card
finishing" is the wait for the card at the frame's end. When the card's
wait is small and a drawing phase is large, the processor is the
bottleneck, not the card. Compare before and after each item, at the
same place and hour.

## The first measurement (2026-10-06, Astranaar at noon)

About 36 ms a frame (about 27 frames a second). The card finished its
part in 0.13 ms and waited the rest of the time.

| Phase | ms a frame | What the processor does |
|---|---|---|
| Ground | 10.6 | 9 tiles x 256 patches, one draw order each, five pictures switched per order; none skipped, even behind the camera |
| Doodads and buildings | 10.1 | one order per piece of each of 394 models, and one per copy for camera-facing models |
| Creatures | 5.2 | bending every point of the 27 within sight in software (2.3), sending the bent points to the card (0.9), the bones' poses (1.1), drawing (0.75) |
| Animating doodads | 1.9 | software bending of swaying models, re-posing camera-facing copies, moving particles and rebuilding their squares |
| Water, sky, figures | about 2.3 | draw orders; the sky's colours re-sent |
| Moving her | 0.0 | collision and camera |
| The card finishing | 0.13 | waiting on the processor |

Re-run the picture for today's numbers; this table is the starting point.

## The rule

The processor decides *what* and *where*: a few numbers per object (a
place, a bone table, a colour). The graphics card does the per-point
and per-pixel work. Fewer, larger draw orders beat many small ones.

## Must stay on the processor

| Work | Why |
|---|---|
| Movement and collision | Instant yes-or-no answers that game logic reads back, which must agree with the server; costs nearly nothing |
| Choosing animations, and the bones' poses (about 100 numbers a model) | Needed on the processor anyway: items hang from bones, particles start at bones; reading them back from the card would cost more |
| Deciding what to draw | Coarse sight tests (tile, chunk, creature) and one short order per batch |
| Loading files, parsing tables | Can move to a second thread, never to the card |
| The light tables | A few numbers a frame |

## The checklist, in order

- [x] **1. Ground in one order a quarter tile, and sight tests.** Built
  2026-10-06 (`ground.c`, `sight.c`). Each tile is four meshes (64
  patches each); every ground picture is a layer of one shared texture
  array (reached through Raylib's OpenGL loader: Raylib has no arrays);
  each patch's four layer numbers ride on its points; the tile's blend
  pictures are one 1024 x 1024 picture; quarters out of sight aren't
  drawn. **Measured:** ground 10.6 ms to 0.04 ms a frame; 2,304 draw
  orders to about 6. The same picture (compared pixel by pixel: under
  0.1% apart, the moving doodads' difference).
- [x] **2a. Doodads: sight tests.** Built 2026-10-06 (`doodads.c`):
  each frame, each model's copies within the camera's sight are gathered
  (a ball: the copy's place, the model's reach times the copy's size,
  plus a tenth and a yard); only those are drawn. Buildings now know
  their reach too. **Measured:** doodads and buildings 13 ms to 2.2 ms a
  frame (about 150 orders); the whole frame without creatures 30 ms to
  14. The same picture (0.14% apart: particles).
- [ ] **2b. Doodads: fewer orders.** Pieces sharing a picture and blend
  merged; camera-facing copies (still one order each) folded in by step
  4. Smaller now that 2a is done; measure again after step 3.
- [x] **3a. Figures bent on the card.** Built 2026-10-06 (`figure.c`,
  `main.c`'s figure shader): each point's four bone numbers and weights
  go to the card once (in Raylib's colour and tangent slots: 5.1 has no
  bone slots); each frame only the bone poses go, as a one-row float
  picture per figure; the shader bends. **Measured:** creatures 5.2 ms
  to 1.7 ms a frame (posing the bones 0.8 of it); her and the
  bystanders 0.18 to 0.04. The same pictures (her, the bystanders mid-
  animation, her axe on her hand).
- [ ] **3b. Bending on the card (skinning in the shader): doodads.** Figures,
  swaying doodads and camera-facing doodads: their points are sent once
  with their bones and weights; each frame only a bone table (a small
  picture of matrices) goes to the card, and the shader bends and turns
  the points. Expected: creatures from about 5 ms to about 2 (the bone
  poses stay), doodad animating mostly gone. Better: same pictures, a
  harder shader.
- [ ] **4. Camera-facing doodads turned in the shader** (part of 3): no
  per-copy meshes or orders. Better.
- [ ] **5. The sky's colours as shader values**, not re-sent vertex
  colours. Tiny; cleaner. Better.
- [ ] **6. Particles drawn in one batch** from a list of positions,
  sizes and colours (instanced squares). Better, small. Moving their
  motion onto the card too (each particle worked out from its birth
  time) is possible but makes them harder to change: not now.
- [ ] **7. Pictures sent compressed.** The archives' pictures are DXT
  compressed; the card unpacks DXT in hardware, so they go as they are
  instead of unpacked on the processor. Faster tile loads, about 4 to 8
  times less picture memory. Better.
- [ ] **8. Loading on a second thread.** Tile files read and parsed off
  the frame, handed over when ready, so walking never stalls a frame.
  Better; the handing-over must be careful (the card is only spoken to
  from the main thread).

## Not to do

| Idea | Why not |
|---|---|
| Bone poses on the card (animations as pictures) | The processor needs the poses anyway (items, particles) |
| Collision on the card | Slow round trips for tiny answers; logic must match the server's |

## Related

- Issue 173u (the work), 173t (creatures' sight distance, already 100
  yards as the server sends them), 173s (tiles), 173o (particles).
- `docs/custom-client-datapath.md` (the frame's order).
