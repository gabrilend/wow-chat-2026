# 066-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=3&fence=2&view=fence&way=paint' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=3&fence=2&view=fence&way=paint)
- Commit: 1803bd2 (with uncommitted changes to its sources)
- Filed: 2026-10-29 12:41 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 2139c95f6b2f3830 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/templates/paint-paths.js` | f832d5349ccb17d1 |
| `scripts/generate-ground-sandbox-data` | b7e99ee971272a39 |
| `scripts/generate-ground-sandbox-page` | af4e5cf4e604cf95 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 065-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 065-ground-sandbox
- `scripts/templates/paint-paths.js`: first picture that names it
- `scripts/generate-ground-sandbox-data`: unchanged since 065-ground-sandbox
- `scripts/generate-ground-sandbox-page`: changed since 065-ground-sandbox

## What it shows
he Barrens' Witchwing Slayer area after 120 seconds, Pathfinding "painted
map", the first picture of it (1600 by 900, so the panel's last lines,
with the painted map's own measures, are cut off). Green trails curve
through the fence instead of zig-zagging; orange squares are doodads the
bots bumped and painted for all of them; faint white curves are planned
routes. The panel: stuck 0 times (orbit, 065: 213), spacing 22.4 yards,
fence covered 26%, turned aside 42 steps a second, stopped 20 a second.

## The story so far
he ground sandbox (617e16) compares ways to find a path on real ground
(617o7). On 2026-10-29 orbit's rings were mended (065), and the owner asked
for bots that paint what they learn onto a shared map, keep space from
walls (less near what they need), spread out, and walk naturally in arcs
(617o8). The painted map was built as one script the page and a Node test
share; 066 and 067 are its first pictures in the sandbox.
