# 078-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=0&zone=Burning%20Steppes&theme=grey%20patchwork&sim=120&turn=1&fence=0&view=fence&way=paint' --window 1600x1300 (photographed: headless Firefox, 1600x1300, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=0&zone=Burning%20Steppes&theme=grey%20patchwork&sim=120&turn=1&fence=0&view=fence&way=paint)
- Commit: f8052c8
- Filed: 2026-10-29 15:23 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | d6ac2d9f64012a90 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/templates/paint-paths.js` | f832d5349ccb17d1 |
| `scripts/generate-ground-sandbox-data` | b7e99ee971272a39 |
| `scripts/generate-ground-sandbox-page` | 29502b7b6f306611 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: unchanged since 077-ground-sandbox-owner-burning-steppes
- `scripts/templates/ground-decode.js`: unchanged since 076-ground-sandbox
- `scripts/templates/paint-paths.js`: unchanged since 076-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 076-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 076-ground-sandbox

## What it shows
n attempt to run the painted map where the owner's picture 077 was taken
(Burning Steppes, fence 0, clockwise, 120 seconds, 1600 by 1300). With the
player where the page puts them, the part in play is a pocket: "Firegut
Brute (18 spawns; part 4 of 6, 260 sq yd walkable)", not 077's merged area
of 47,569 square yards. The camera fits the pocket, so each bot is a large
green disc: all 36 crammed into a gold-painted square of ground (62%
walked) under a big orange learned doodad, the white player disc outside
it on red steep ground. The panel: spacing 2.0 yards, fence covered 100%,
turned aside 369 steps a second, smoothness 155.1 degrees a yard (the bots
jostle), stuck 0, 1 step refused by the world, 66 wall cells learned.
36 bots can't spread through 260 square yards by any way of finding a path:
that is the sandbox putting a whole army into a sliver of an area, an
area-rules question, not a pathfinding one.

## The story so far
fter comparing the six ways on the Barrens (067-076), the owner filed a
picture of the 2026-10-28 version knotting on a Burning Steppes ledge (077).
078 tried the painted map on the same fence and found the part in play to
be a 260-square-yard pocket instead.
