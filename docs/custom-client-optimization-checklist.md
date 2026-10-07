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
- [x] **3b. Doodads bent on the card.** Built 2026-10-06 (`doodads.c`):
  swaying and camera-facing models carry bones and weights on their
  points, sent once; each model's bone poses go as a float picture, one
  row for a swaying model (its copies share the pose) or one row per
  copy drawn for a camera-facing one (the shader picks the row by the
  instance's number). The skybox goes the same way.
- [x] **4. Camera-facing doodads without per-copy meshes** (part of
  3b): each copy in sight is still turned on the processor, but only its
  bones (a handful), into its row; all copies go in one order instead of
  one each. **Measured (3b and 4):** animating doodads 2.0 ms to 0.34 ms
  a frame; the whole frame without creatures about 13 ms. The same
  pictures (the gate's orb, the aurora, daytime within 0.09%).
- [x] **5. The sky's colours as shader values.** Built 2026-10-06
  (`sky.c`): each dome point knows which of the five sky colours it
  takes; the colours go as five shader values; the dome is sent once.
- [x] **5b. Sight tests for the far horizon and water** (found on the
  way: the horizon drew up to 160 low-detail tiles, the water every
  layer, each its own order, none skipped). `horizon.c`, `water.c`: each
  piece's bounding ball tested. **Measured:** sky and horizon 0.7 to
  0.17 ms a frame; water 0.77 to 0.08. The whole frame at Astranaar,
  with its 467 creatures: about 13 ms (36 at the start).
- [ ] **6. Particles drawn in one batch** from a list of positions,
  sizes and colours (instanced squares). Better, but **measured small**
  (2026-10-06, Astranaar at night): drawing them 0.33 ms a frame, moving
  them part of animating doodads' 0.3. Left for when particles grow
  (spells). Moving their motion onto the card too (each particle worked
  out from its birth time) is possible but makes them harder to change.
- [x] **7. Pictures sent compressed** (models, doodads, buildings).
  Built 2026-10-06 (`texture.c`): a DXT picture goes to the card as
  stored, with the game's own smaller copies (through OpenGL directly:
  Raylib 5.1 miscounts some small copies); others are unpacked as
  before. **Measured:** model pictures round Astranaar 92.2 MB to 13.9
  MB on the card; the same picture (0.48% apart: the game's own smaller
  copies instead of the card's). Still unpacked: the ground's picture
  array (one format for all its layers; its pictures are DXT1, but a
  mixed format would need care), painted skins (made on the processor),
  water ripples (small).
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
