# 071-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=3&fence=2&view=fence&way=learn' --window 1600x1300 (photographed: headless Firefox, 1600x1300, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=3&fence=2&view=fence&way=learn)
- Commit: 05e3504
- Filed: 2026-10-29 12:49 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 2139c95f6b2f3830 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/templates/paint-paths.js` | f832d5349ccb17d1 |
| `scripts/generate-ground-sandbox-data` | b7e99ee971272a39 |
| `scripts/generate-ground-sandbox-page` | 29502b7b6f306611 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: unchanged since 070-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 070-ground-sandbox
- `scripts/templates/paint-paths.js`: unchanged since 070-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 070-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 070-ground-sandbox

## What it shows
The Barrens' Witchwing Slayer area after 120 seconds, 36 bots, wedges, 1600 by 1300, Pathfinding learn the map: smoothness 113.1 degrees a yard (the same wobble as A*), 2,599 routes, stuck 0, 64 refused, turned aside 103 a second, spacing 16.5, covered 20%.

## The story so far
he ground sandbox (617e16) compares ways to find a path (617o7). On
2026-10-29 the painted map (617o8) joined the five, and the six were run
on the same area for the same two minutes with the same measures, the new
one being degrees turned a yard walked. These pictures (067-072) are that
comparison; their measure panels were cropped side by side to read it.
