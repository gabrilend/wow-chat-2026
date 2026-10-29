# 059-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=180&turn=3&fence=2&view=fence&way=learn' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=180&turn=3&fence=2&view=fence&way=learn)
- Commit: 048e303 (with uncommitted changes to its sources)
- Filed: 2026-10-28 23:22 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 0c90137732b83d3a |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: unchanged since 058-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 058-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 058-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 058-ground-sandbox

## What it shows
Learn the map: the bots know no steep ground until refused by it; route lines bend round what they have learned; 2,919 routes planned; 60 steps a second with no way (the most of the five, early in the learning).

## The story so far
The owner (2026-10-28) asked for 3-5 radically different pathfinding solutions of equal weight, viewable in game (617o7). The ground sandbox gained a Pathfinding choice: orbit (the way grown so far), flow field, graph and A*, potential field, learn the map; each run here on the Witchwing Slayer area, wedges mode, 180 seconds.
