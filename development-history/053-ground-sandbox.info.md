# 053-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=300&turn=3&fence=2&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=300&turn=3&fence=2&view=fence)
- Commit: eda909b (with uncommitted changes to its sources)
- Filed: 2026-10-28 22:49 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 72f381d46a7964f1 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 052-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 052-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 052-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 052-ground-sandbox

## What it shows
After a refusal shows every bot the doodad it hit (its whole footprint, drawn orange): 79 doodads shown, but still 79,120 steps refused: looking only at the point 2 yards ahead jumps over a thin trunk while the next step still hits it.

## The story so far
The owner (2026-10-28): 'now they're just uncomfortably rubbing up against anything they can touch.' Bots looked a quarter of a yard ahead (turning only once touching) and pushed into unknown doodads for a whole second. Three tries: learning the refused cell at once (052), showing the bots the whole doodad they hit (053), and checking the whole stretch ahead, not just its far point (054).
