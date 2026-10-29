# 044-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=180&turn=2&fence=4' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=180&turn=2&fence=4)
- Commit: 8a50883 (with uncommitted changes to its sources)
- Filed: 2026-10-28 21:29 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | b3fd0fbbd1c447e5 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 043-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 043-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 043-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 043-ground-sandbox

## What it shows
The whole Barrens, night sea, the player in the Zhevra Runner fence: the player's sub-zone's squares shaded faintly white (a broad central region); the panel reads 'The Barrens, The Barrens - Zhevra Runner (83 spawns; part 1 of 5, 103,056 sq yd walkable)': the area cut from 179,340 to 103,056 square yards, still large, because the player's sub-zone is the zone's own name, the ground between the named places.

## The story so far
The owner (2026-10-28) saw areas covering nearly the whole map and asked for two fences, the monsters' and the sub-zone's, the bots wandering where both hold (617e16j). The page now keeps each square's sub-zone and cuts every area to the player's; where that sub-zone is the zone's generic one, the cut does little.
