# 038-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=180&turn=2&at=2236,4631&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=180&turn=2&at=2236,4631&view=fence)
- Commit: 9758e9c (with uncommitted changes to its sources)
- Filed: 2026-10-28 21:09 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | e462c3716aba7703 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 037-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 037-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 037-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 037-ground-sandbox

## What it shows
After crossings were given a time limit: bots move a little more, but 220 steps a second find no way at all; 422 buffer cells, as hard walls, seal the narrow passages of the pocket.

## The story so far
The owner (2026-10-28) added: a bump (less progress than meant) leaves a buffer of clearance round the obstacle, routed round or walked through on a straight crossing; and where fences of different monsters overlap, the player standing in both makes both the wandering area, with fights on the way unless more than half a zone from the player (617e16h, 617e16f). Tried on the Barrens' Razorfen Battleguard and Thornweaver fences, which overlap on hilly ground.
