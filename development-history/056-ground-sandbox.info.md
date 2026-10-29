# 056-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=300&turn=3&fence=2&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=300&turn=3&fence=2&view=fence)
- Commit: 0d1590d (with uncommitted changes to its sources)
- Filed: 2026-10-28 23:06 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 5d9d484f7490030a |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 055-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 055-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 055-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 055-ground-sandbox

## What it shows
Wedges, five minutes, with backing out before orbiting, doubling until the bot passes its forwardmost stuck spot: white rings (backing out) and cyan rings (orbiting) round many bots; the panel: stuck 448 times, backed out 448 times for 7,470 yards (the rest of the line, longest and relaxed, past the panel's edge); orbits 443 begun, 39 left by sight, 104 turned round; spacing 23.9 yards.

## The story so far
The owner (2026-10-28): back out first, doubling the back-up each time stuck, reset once past the forwardmost stuck spot along the way forward; then orbit (617e16h). Built on the orbit version; one edit's line search came back empty and rewrote the whole template, which was restored from its commit and the edits redone.
