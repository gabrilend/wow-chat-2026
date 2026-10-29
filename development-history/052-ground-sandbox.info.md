# 052-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=300&turn=3&fence=2&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=300&turn=3&fence=2&view=fence)
- Commit: eda909b (with uncommitted changes to its sources)
- Filed: 2026-10-28 22:48 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | d9340c4628e8c46c |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 051-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 051-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 051-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 051-ground-sandbox

## What it shows
Wedges, five minutes, after the bots looked 2 yards ahead and a refused cell became a wall at once: worse, 77,942 steps refused; only 83 known walls, because the refused cell was often the cell the bot stood in, and standing proves a cell open, undoing the mark at once.

## The story so far
The owner (2026-10-28): 'now they're just uncomfortably rubbing up against anything they can touch.' Bots looked a quarter of a yard ahead (turning only once touching) and pushed into unknown doodads for a whole second. Three tries: learning the refused cell at once (052), showing the bots the whole doodad they hit (053), and checking the whole stretch ahead, not just its far point (054).
