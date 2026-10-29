# 012-fish-sandbox-barrens-night

## What made it
- headless Firefox, 1600x900: fish-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=240&turn=1&fence=0, after the fences were limited to monsters (filed later; fingerprints are of today's files)
- Commit: 8660325 (with uncommitted changes to its sources)
- Filed: 2026-10-28 17:26 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/fish-sandbox.html` | 491a770b447085b2 |
| `scripts/generate-fish-sandbox-data` | ae5296051da592c6 |

## What changed since the previous picture
- `scripts/templates/fish-sandbox.html`: unchanged since 011-fish-sandbox-barrens-parchment
- `scripts/generate-fish-sandbox-data`: unchanged since 011-fish-sandbox-barrens-parchment

## What it shows
The Barrens in night sea after the fix: many larger yellow fences now, linked spawns within 90 yards and padded. Right of centre a fence glows green: Venture Co. Supervisor (17 spawns). The panel: 36 of 36 circling, all clockwise, fence covered 61%, spacing 5.9 yd.

## The story so far
Then (2026-10-28) the fish-school sandbox: the whole world map in a browser page, zoomable, with 36 bots flocking clockwise inside fences drawn round where each kind of monster spawns, and themes to choose the look. Run headless by Firefox, driven by the address's settings, so a picture can be taken without anyone at the screen. Fences now come only from monsters, and nearby spawns are joined into one fence.
