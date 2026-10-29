# 062-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=10&turn=3&fence=2&view=fence&way=flow' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=10&turn=3&fence=2&view=fence&way=flow)
- Commit: 55059d7 (with uncommitted changes to its sources)
- Filed: 2026-10-29 01:52 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | ec0c268fbfb32ad0 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 061-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 061-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 061-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 061-ground-sandbox

## What it shows
he Barrens' Witchwing Slayer area ten seconds after the bots set out, by
the flow field, after the corner mend (diagonal steps no longer slip past
a blocked corner; the line check walks every point a line crosses). The
36 green bots are still a burst round the white player in the middle of
the yellow fence, their tails short spokes outward. Red patches inside
the fence are too steep; a violet strip at its right edge is a sub-zone
of its own. The panel: spacing 7.0 yards, fence covered 5%, 0 stopped,
stuck 0, orbits 0, 417 flow fields made. Taken at 10 seconds of play
because the run of 180 seconds before it (and one of 120) ran past the
picture tool's 90-second limit and filed nothing: the corner rule made
the page slower, mended for 063.

## The story so far
he ground sandbox (617e16) grew from a flock of fish on flat squares into
bots on the world's real ground: heights and steep ground, doodads,
fences reshaped by the land, monsters, circulation by wedges, and the
owner's stuck rule (back out, twice as far each time, orbit round). On
2026-10-28 five ways to find a path were added side by side (617o7), then
built again as the buddy module's own code with an offline test, whose
first runs found that the grid ways cut corners past a wall's end and that
the sampled line check missed clipped corners. 062 and 063 bring those
mends back to the page, so the page and the game agree; 063 also makes the
page fast enough again for the picture tool.
