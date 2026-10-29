# 026-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=180&turn=2&fence=4&view=fence&form=wedge&formN=8' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=180&turn=2&fence=4&view=fence&form=wedge&formN=8)
- Commit: 61645b6 (with uncommitted changes to its sources)
- Filed: 2026-10-28 17:47 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 24f72b2f065b0b9d |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 47187b0abf6f6e73 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: unchanged since 025-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 025-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 025-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 025-ground-sandbox

## What it shows
The same, with an eight-bot wedge (in yellow) patrolling the fence's left edge, point first, 3.0 yd from its places on average; the other 28 wanderers still a starburst.

## The story so far
The owner called the fish-school sandbox delightful but not quite it, and asked (2026-10-28) for an archived copy and a new one on the world's real ground: slopes over a limit unpathable, doodads avoided (issue 617e16c). The sandbox was archived and committed; a new tool reads every zone's heights from the map files and every collision box from the server's collision files; a new page shades the hills, paints ground steeper than a slider's limit red, and turns the bots aside from both. Formations (617e16e): shapes held rigid or turned to the heading; the owner's hero-less-moba, found the same day, marches its waves in ranks.
