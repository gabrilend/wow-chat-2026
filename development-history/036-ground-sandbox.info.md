# 036-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=180&turn=2&at=2236,4631&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=180&turn=2&at=2236,4631&view=fence)
- Commit: 9758e9c (with uncommitted changes to its sources)
- Filed: 2026-10-28 21:07 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | dc1ee1ddafa1305c |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 035-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 035-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 035-ground-sandbox
- `scripts/generate-ground-sandbox-page`: changed since 035-ground-sandbox

## What it shows
The two Razorfen fences overlapping, both outlines lit, the panel naming them together (67 spawns); the bots jammed in a knot by the player: 133 bumps had left 532 buffer cells, 508 steps a second turned aside, 40 with no way at all. Brushing a buffer counted as a bump, so buffers bred buffers.

## The story so far
The owner (2026-10-28) added: a bump (less progress than meant) leaves a buffer of clearance round the obstacle, routed round or walked through on a straight crossing; and where fences of different monsters overlap, the player standing in both makes both the wandering area, with fights on the way unless more than half a zone from the player (617e16h, 617e16f). Tried on the Barrens' Razorfen Battleguard and Thornweaver fences, which overlap on hilly ground.
