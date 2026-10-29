# 073-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=3&fence=2&view=fence&way=astar' --window 1600x1300 (photographed: headless Firefox, 1600x1300, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=3&fence=2&view=fence&way=astar)
- Commit: 05e3504 (with uncommitted changes to its sources)
- Filed: 2026-10-29 12:54 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 7ff157c79b7670c6 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/templates/paint-paths.js` | f832d5349ccb17d1 |
| `scripts/generate-ground-sandbox-data` | b7e99ee971272a39 |
| `scripts/generate-ground-sandbox-page` | 29502b7b6f306611 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 072-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 072-ground-sandbox
- `scripts/templates/paint-paths.js`: unchanged since 072-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 072-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 072-ground-sandbox

## What it shows
he Barrens' Witchwing Slayer area after 120 seconds, 36 bots, wedges,
1600 by 1300, Pathfinding "graph and A*", after A*'s steered-to point was
held (kept while more than 3 yards off and in sight, instead of chosen
afresh each step): smoothness 92.9 degrees turned a yard walked (069,
before: 120.4), 80 steps refused by the world. Still far above the painted
map's 6.3: A*'s routes graze steep edges (it keeps no distance), each step
the bot's own look-ahead turns it off the edge and its route point pulls
it back (turned aside 63 steps a second in 069; the painted map 24).

## The story so far
he six ways were compared on one run (067-072); A* and "learn the map"
showed a wobble of over 100 degrees a yard. Holding the steered-to point
took a fifth of it away (073); the rest is the routes grazing walls, which
the painted map's space from walls is built to avoid.
