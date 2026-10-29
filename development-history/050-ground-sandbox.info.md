# 050-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=300&turn=3&fence=2&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=300&turn=3&fence=2&view=fence)
- Commit: 098f6c2 (with uncommitted changes to its sources)
- Filed: 2026-10-28 22:02 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | aaf04e56db73f264 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 049-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 049-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 049-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 049-ground-sandbox

## What it shows
The Witchwing Slayer area in the new 'wedges' turning mode after five minutes: the bots' trails are straight legs between waypoints, each bot's inside its assigned wedge; the panel: 360 wedge moves (61 with momentum reversed, 34 across the arena), 39 fights done, spacing 9.7 yards, 13% of the fence covered in the last minute; most bots still within the middle half of the area.

## The story so far
Circulation (617e16k): the emptiest-sector move (049) gave way, at the owner's asking, to wedges by momentum: each bot assigned a wedge, every waypoint inside it, reassigned every 30 seconds to the neighbour its momentum points to, sometimes reversed, sometimes across the arena.
