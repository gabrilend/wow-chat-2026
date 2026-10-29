# 027-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=240&turn=2&fence=4&view=fence&form=wedge&formN=8' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=240&turn=2&fence=4&view=fence&form=wedge&formN=8)
- Commit: 61645b6 (with uncommitted changes to its sources)
- Filed: 2026-10-28 17:47 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 235ef173be305364 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 47187b0abf6f6e73 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 026-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 026-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 026-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 026-ground-sandbox

## What it shows
After the change, 240 s: the wanderers' paths tangle and loop with no common point; 11 crossing; the yellow wedge patrolling along the top edge, 2.6 yd from its places; 9 turns down, 26 up.

## The story so far
The owner called the fish-school sandbox delightful but not quite it, and asked (2026-10-28) for an archived copy and a new one on the world's real ground: slopes over a limit unpathable, doodads avoided (issue 617e16c). The sandbox was archived and committed; a new tool reads every zone's heights from the map files and every collision box from the server's collision files; a new page shades the hills, paints ground steeper than a slider's limit red, and turns the bots aside from both. Crossings now aim at each bot's own point near the middle and come every 40-120 s: the starburst is gone.
