# 067-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=3&fence=2&view=fence&way=paint' --window 1600x1300 (photographed: headless Firefox, 1600x1300, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=3&fence=2&view=fence&way=paint)
- Commit: 1803bd2 (with uncommitted changes to its sources)
- Filed: 2026-10-29 12:42 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 2139c95f6b2f3830 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/templates/paint-paths.js` | f832d5349ccb17d1 |
| `scripts/generate-ground-sandbox-data` | b7e99ee971272a39 |
| `scripts/generate-ground-sandbox-page` | 29502b7b6f306611 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: unchanged since 066-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 066-ground-sandbox
- `scripts/templates/paint-paths.js`: unchanged since 066-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 066-ground-sandbox
- `scripts/generate-ground-sandbox-page`: changed since 066-ground-sandbox

## What it shows
he same run taken 1600 by 1300 (the tool's new --window), so the whole
panel reads: painted map 15% walked, 1,937 wall cells learned (55 doodads
shown to the bots), smoothness 6.3 degrees turned a yard walked, stuck 0
times, stopped 0.0 steps a second, 54 steps refused by the world in two
minutes, spacing 19.1 yards, fence covered 26%. Trails spread over the
fence's middle and west; a bright knot of bots bunches at the narrow steep
notch on the east side by the violet sub-zone, where spreading still
fails.

## The story so far
he ground sandbox (617e16) compares ways to find a path on real ground
(617o7). On 2026-10-29 orbit's rings were mended (065), and the owner asked
for bots that paint what they learn onto a shared map, keep space from
walls (less near what they need), spread out, and walk naturally in arcs
(617o8). The painted map was built as one script the page and a Node test
share; 066 and 067 are its first pictures in the sandbox.
