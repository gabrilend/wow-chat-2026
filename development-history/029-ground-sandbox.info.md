# 029-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=180&turn=2&fence=0&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=180&turn=2&fence=0&view=fence)
- Commit: 20e5cf2 (with uncommitted changes to its sources)
- Filed: 2026-10-28 18:47 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 3764bad540fa7953 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 47187b0abf6f6e73 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: unchanged since 028-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 028-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 028-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 028-ground-sandbox

## What it shows
The Venture Co. Supervisor fence over Boulder Lode Mine, close: its walkable ground is six separate parts; the player (white) stands in part 3, a small pocket (1,719 sq yd) walled by steep red ground; the 36 bots fill it, all circling (15 clockwise, 21 anticlockwise), 97% of it covered; the rest of the outline (yellow) runs over red ground.

## The story so far
The owner (2026-10-28) asked for the wandering areas to be reshaped by the ground (617e16f): impassable ground walled off and orbited, fences of one name merged, split where their walkable parts don't join; and answered that the player nearing the edge turns the bots' orbit round, and the same move again sends them across. Each fence name's area is now its outlines less the steep ground, cut into connected parts; the part the player is in is what the bots wander, its edge a wall they follow round, keeping one side.
