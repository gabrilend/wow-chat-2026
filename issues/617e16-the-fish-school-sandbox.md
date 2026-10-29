# 617e16 - The Fish-School Sandbox

## Status
- Created: 2026-10-28
- Phase: 6
- Parent: 617e
- Related: 617e14 (the world watched from above: zone data, renderer,
  benchmark), 617e14e (the picture judge), 617e7 (The Barrens' page, the
  first of its kind), 617e15 (places conquered)
- Priority: High
- Sub-issues: 617e16a (positions streamed from the world server), 617e16b
  (the judging machinery), 617e16c (the sandbox on the ground), 617e16d
  (wanderers who choose their own crossings), 617e16e (formations)
- State: in progress (the page, its data, its flock, the live players and
  the human half of the judging built 2026-10-28; the machine judge waits
  on the image pipeline's repair)

## Origin

The owner, 2026-10-28:

> What we're looking for is the image pipeline to look like the movements
> of a school of fish. To get that specific output we might need to make it
> so they always rotate in one direction, say, clockwise? What we're
> looking for right now specifically is just, flow, through a sub-zone, in
> a roughly circular pattern that fills all the gaps and explores all the
> shape. When the "player" (just a dot) moves to a different sub-zone, the
> bots should follow. They don't need to follow terrain and such for now,
> let's just... paint a sub-zone (monster spawning location zone) with a
> yellow fence, and the bots (green dots) will wander around there. If the
> player clicks somewhere else it'll highlight a different yellow fence.
> The bots should try and wander around in the sub-zone (which is just the
> area that a monster type spawns in - one monster type, but if the player
> is within multiple "sub-zones" then the NPCs will wander in that
> sub-zone.

And of the page: "having a web page we could go to that shows the
location of each of the players in the game is just a neat utility to
have. Can we have several different visual themes for the map? If we zoom
out, it should take us to the world map, and if we click or zoom in on one
of the zones, it should slowly zoom and bring us to that zone in
particular." Of the judge: "we're using that image generation as a
standard to continue iterating until it starts to seem reasonably
confident that the behavior we've programmed into a group of ~36 bots
wandering around in a zone have movement patterns that feel like a fish.
We can try multiple attempts each round of code iteration, like pushing
all of them into the same sub-zone or whatever."

## Current Behavior

**Built 2026-10-28** (not yet seen by the owner):
- `scripts/generate-fish-sandbox-data` reads the zone data
  (`assets/zone-maps/`, 617e14b) and the world database's creature spawns,
  and writes `assets/fish-sandbox/sandbox-data.js`: each continent's zones
  and sub-zones as grids, and the **fences**: for each zone, the places
  one kind of monster spawns (a monster: not friendly to either side's
  players, by the faction table's own rule, so neutral beasts count and
  guards and camps don't; its spawns gathered where they lie within 90
  yards of each other, at least 4 of them), each the outline round them
  with 15 yards to spare, named after the monster: 2,119 fences on the two
  continents. (First tries: 45 yards made fences too small for 36 bots to
  circle in, none circling; without the friendliness rule the largest
  Barrens fence was a camp of Theramore Marines.)
- `scripts/generate-fish-sandbox-page` puts that data into
  `docs/HTML/fish-sandbox.html`, which opens from the file itself (no
  server). The page:
  - a continent seen whole (Eastern Kingdoms or Kalimdor), its zones in
    their sub-zones' tints; a click on a zone, or zooming in on it, glides
    the view to that zone; zooming out far enough glides back to the
    continent;
  - themes: grey patchwork (617e7's), parchment, night sea, and "ninja"
    (black, neon green, red: the owner's Mastermind's colours);
  - in a zone: its fences in yellow, the one in play bright; the player a
    white dot moved by a click; 36 bots, green dots with fading tails;
  - the flock: each bot circles the fence's middle, clockwise by default
    ("always rotate in one direction"), aiming a little ahead on its circle
    at a depth of its own between the middle and the fence, a depth that
    drifts slowly so that, over time, the whole shape is swept ("fills all
    the gaps and explores all the shape"); bots keep apart from close
    neighbours and lean toward their neighbours' heading (a school); a bot
    outside the fence heads for its middle. The player inside several
    fences: the smallest holds the bots. The player outside every fence:
    the bots follow the player;
  - its measures, live: how much of the fence the bots crossed in the last
    minute, how many circle and which way, their spacing; a close-up of
    the fence in play; and a button that saves a strip of frames as a
    picture, for the judge;
  - driven from its address for a headless browser (continent, zone,
    theme, turning, bots, fence, seconds of play run at once, the
    close-up): Firefox's `--screenshot` takes the judge's frames with no
    person.
  First result (The Barrens, a Venture Co. Supervisor fence, 36 bots, 4
  minutes of play, clockwise): 35 of 36 circling clockwise, 59% of the
  fence crossed in the last minute, 5.3 yards between neighbours; the
  picture is a spiral with arms, tighter at its middle; the fence's
  corners are seldom reached.

## Intended Behavior

As the owner's words above, and:
- **Live players** on the same page: the world recorder's positions
  (617e14a) drawn as dots, read every few seconds (needs a small local web
  server: the page alone cannot read files on its own).
- **The judge** (617e14e): frames scored for "a school of fish", round
  after round, each round's code change kept or dropped by the score.

## Suggested Implementation Steps

1. The data and the page (done).
2. The flock tuned by its own measures, then by the judge.
3. The judge: the image pipeline (`/mnt/kaun/stable-diffusion`) made to
   run (its last update stopped building OpenBLAS on 2026-10-10, so
   ComfyUI does not start); then "a school of fish" pictures made with its
   Stable Diffusion model, and each frame strip scored by how close its
   picture embedding (the CLIP image encoder it holds) lies to theirs.
4. Live players through a small local server.
5. What the flock learns, carried back into the server's roaming (617e2).

## Open Questions

Gathered 2026-10-28 into 617's own list (question 16), merged with the
same questions from other sub-issues; answers are written back here.

1. **The judge's yardstick**: the pipeline makes pictures, it doesn't
   describe them. Scoring frames against "school of fish" pictures it
   makes (their embeddings compared) is one way; another is a model that
   reads pictures and answers questions (none is installed). Which?
2. (Answered 2026-10-28) **Clockwise only?** "The path finding should
   eventually be both clockwise and counter clockwise. Right now we're
   isolating one direction until we get the pattern right, then we do
   both." Clockwise now; both later.
3. (Answered 2026-10-28) **Live players**: by a patch to the world server,
   which serves the positions itself (617e16a); no other server.
