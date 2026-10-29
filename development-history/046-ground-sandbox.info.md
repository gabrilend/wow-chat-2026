# 046-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=30&turn=2&fence=4' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=30&turn=2&fence=4)
- Commit: f0d6bb3 (with uncommitted changes to its sources)
- Filed: 2026-10-28 21:37 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 87e4d80417dc5b7d |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 045-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 045-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 045-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 045-ground-sandbox

## What it shows
The whole Barrens after 30 s, the Zhevra Runner cluster in the middle; the hint along the bottom now reads 'Scroll to zoom, middle-drag to pan'. The panning itself (holding the middle button and dragging) is not something a still picture can show.

## The story so far
The owner (2026-10-28) asked to drag the map with the middle button, panning only: added to the ground sandbox's controls.
