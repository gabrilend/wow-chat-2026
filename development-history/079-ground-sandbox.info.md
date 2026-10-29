# 079-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=3&fence=2&view=fence&way=paint' --window 1600x1300 (photographed: headless Firefox, 1600x1300, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=3&fence=2&view=fence&way=paint)
- Commit: f8052c8 (with uncommitted changes to its sources)
- Filed: 2026-10-29 15:24 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 033ffa630f48f713 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/templates/paint-paths.js` | f832d5349ccb17d1 |
| `scripts/generate-ground-sandbox-data` | b7e99ee971272a39 |
| `scripts/generate-ground-sandbox-page` | 29502b7b6f306611 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 078-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 078-ground-sandbox
- `scripts/templates/paint-paths.js`: unchanged since 078-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 078-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 078-ground-sandbox

## What it shows
The Barrens' Witchwing Slayer area after 120 seconds, 36 bots, wedges, 1600 by 1300, Pathfinding painted map, with the least-walked waypoints tried: fence covered 27%, spacing 15.8 yards (the default's two runs: 26%, 19.1 and 19.3), turned aside 22 steps a second.

## The story so far
he painted map (617o8) spreads its bots by lanes and the crowd, and their
targets by the wedges (617e16k). 079 and 080 tried choosing each wedge
waypoint as the least-walked of five, by the painted map's counts; it was
undone after these two runs, since spacing fell.
