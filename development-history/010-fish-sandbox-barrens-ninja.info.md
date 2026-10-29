# 010-fish-sandbox-barrens-ninja

## What made it
- headless Firefox, 1600x900: fish-sandbox.html#continent=1&zone=The%20Barrens&theme=ninja&sim=240&turn=1&fence=0 (filed later; fingerprints are of today's files)
- Commit: 8660325 (with uncommitted changes to its sources)
- Filed: 2026-10-28 17:26 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/fish-sandbox.html` | 491a770b447085b2 |
| `scripts/generate-fish-sandbox-data` | ae5296051da592c6 |

## What changed since the previous picture
- `scripts/templates/fish-sandbox.html`: unchanged since 009-fish-sandbox-dun-morogh
- `scripts/generate-fish-sandbox-data`: unchanged since 009-fish-sandbox-dun-morogh

## What it shows
The Barrens in the ninja theme, sub-zones as soft patches, small yellow fence outlines scattered over it. Left of centre, on the coast, a small fence glowing green with the bots and the player. The panel names the fence The Barrens, Theramore Marine (46 spawns) and reads 0 of 36 circling: the first fence was a camp of guards, not monsters, and the bots were packed into it too tightly to circle. This is what led to keeping only creatures hostile to both sides as fences.

## The story so far
Then (2026-10-28) the fish-school sandbox: the whole world map in a browser page, zoomable, with 36 bots flocking clockwise inside fences drawn round where each kind of monster spawns, and themes to choose the look. Run headless by Firefox, driven by the address's settings, so a picture can be taken without anyone at the screen. The Barrens was drawn in each theme to compare looks.
