# 008-fish-sandbox-world

## What made it
- headless Firefox, 1600x900: docs/HTML/fish-sandbox.html#continent=0&theme=grey%20patchwork (filed later from tmp/shared-memory; fingerprints are of today's files)
- Commit: 8660325 (with uncommitted changes to its sources)
- Filed: 2026-10-28 17:26 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/fish-sandbox.html` | 491a770b447085b2 |
| `scripts/generate-fish-sandbox-data` | ae5296051da592c6 |

## What changed since the previous picture
- `scripts/templates/fish-sandbox.html`: first picture that names it
- `scripts/generate-fish-sandbox-data`: first picture that names it

## What it shows
The Eastern Kingdoms whole, faint on grey (the grey patchwork theme), zones as patches in muted colours. The control panel at top left: continent, theme, 36 bots, speed 4x, clockwise turning, 40 s tails, buttons World, Scatter bots, Save a frame strip. A hint at the bottom: click a zone to fly there.

## The story so far
Then (2026-10-28) the fish-school sandbox: the whole world map in a browser page, zoomable, with 36 bots flocking clockwise inside fences drawn round where each kind of monster spawns, and themes to choose the look. Run headless by Firefox, driven by the address's settings, so a picture can be taken without anyone at the screen.
