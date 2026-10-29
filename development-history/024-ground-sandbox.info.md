# 024-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=parchment&sim=30&turn=1&fence=4' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=parchment&sim=30&turn=1&fence=4)
- Commit: 61645b6 (with uncommitted changes to its sources)
- Filed: 2026-10-28 17:43 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 6d94c811a27f766a |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 47187b0abf6f6e73 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 023-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 023-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 023-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 023-ground-sandbox

## What it shows
The same view after the mirror fix: the Barrens' coast and lakes on the right (east), Mulgore and Stonetalon's land on the left, Kalimdor's east coast on the right; the craters bottom left now.

## The story so far
The owner called the fish-school sandbox delightful but not quite it, and asked (2026-10-28) for an archived copy and a new one on the world's real ground: slopes over a limit unpathable, doodads avoided (issue 617e16c). The sandbox was archived and committed; a new tool reads every zone's heights from the map files and every collision box from the server's collision files; a new page shades the hills, paints ground steeper than a slider's limit red, and turns the bots aside from both. The ground sandbox now draws east on the right; the fish-school sandbox (and its archive) still draws it mirrored.
