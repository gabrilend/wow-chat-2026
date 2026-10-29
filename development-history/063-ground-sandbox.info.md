# 063-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=3&fence=2&view=fence&way=flow' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=3&fence=2&view=fence&way=flow)
- Commit: 55059d7 (with uncommitted changes to its sources)
- Filed: 2026-10-29 01:55 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | e58396db82550cdb |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 062-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 062-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 062-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 062-ground-sandbox

## What it shows
he same area after 120 seconds of play, flow field, after the page
learned to keep each planning point's open-or-blocked answer until what
is known changes (the corner rule asked two or three times as often, and
each fresh answer scanned the doodads near; 120 seconds of play now take
59 seconds to photograph, where it timed out at 90). The bots' green
tails cover the fence's middle and spread to its edges, crossing round
the steep red patches rather than through them; three circle markers
(circling bots) near the edges. The panel: spacing 18.3 yards, fence
covered 29%, 0 stopped, stuck 0 times, 0 orbits, 4,229 flow fields;
2,624 monsters alive, 43 killed.

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
