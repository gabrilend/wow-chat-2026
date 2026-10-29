# 051-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=300&turn=3&fence=2&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=300&turn=3&fence=2&view=fence)
- Commit: 921e4fc (with uncommitted changes to its sources)
- Filed: 2026-10-28 22:05 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 187ca6179f06d5e5 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 050-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 050-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 050-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 050-ground-sandbox

## What it shows
The Witchwing Slayer area in 'wedges' mode after waypoints were drawn even over each wedge's area (not by distance, which crowded the narrow middle): the bots' straight legs reach further out, spacing 15.4 yards (9.7 before); 360 wedge moves (40 reversed, 31 across); 51 fights done.

## The story so far
Wedges by momentum (617e16k, 050), then their waypoints spread by area so the middle isn't crowded (051).
