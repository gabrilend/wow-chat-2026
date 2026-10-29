# 025-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=180&turn=2&fence=4&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=180&turn=2&fence=4&view=fence)
- Commit: 61645b6 (with uncommitted changes to its sources)
- Filed: 2026-10-28 17:47 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 24f72b2f065b0b9d |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 47187b0abf6f6e73 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 024-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 024-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 024-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 024-ground-sandbox

## What it shows
Wanderers in the Zhevra Runner fence after 180 s: green straight paths radiating through the fence's exact middle like a starburst; 28 of 36 crossing at once; zone level 110.6 yd; 67 crossings, 16 turns down and 23 up, no orbit reversals.

## The story so far
The owner called the fish-school sandbox delightful but not quite it, and asked (2026-10-28) for an archived copy and a new one on the world's real ground: slopes over a limit unpathable, doodads avoided (issue 617e16c). The sandbox was archived and committed; a new tool reads every zone's heights from the map files and every collision box from the server's collision files; a new page shades the hills, paints ground steeper than a slider's limit red, and turns the bots aside from both. Then the owner asked (617e16d) for bots that choose their own crossings: straight through the middle, a hard turn at the far side toward the zone's level, three turns against the orbit reversing it. First try: every crossing aimed at the one middle point, the orchestrated look again.
