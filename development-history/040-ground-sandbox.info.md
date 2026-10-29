# 040-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=240&turn=2&fence=2&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=240&turn=2&fence=2&view=fence)
- Commit: 8f7691d (with uncommitted changes to its sources)
- Filed: 2026-10-28 21:12 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 10796e2d8ad5ae58 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 039-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 039-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 039-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 039-ground-sandbox

## What it shows
The Witchwing Slayer area, night sea, wanderers, 240 s, with peninsulas found: one, its door a violet ring on the area's right edge, its corners all seen (no violet left); the panel: 1 found, 1 seen whole, 0 bots exploring; 179 bumps, 1288 buffer cells; 55 fights done. The panel is wider now (340 px) but its longest lines still run past it.

## The story so far
The owner (2026-10-28) asked for peninsulas (rooms and pockets behind a narrow way) to be explored to every corner, and treated as an instance, the bots as tanks, when the player is inside one (617e16i). Each walkable part is now shrunk by two points, split into pieces, grown back; pieces other than the main body are peninsulas, their doors where they touch it. Bots near an unseen door go in and walk to the nearest unseen corner until all are seen.
