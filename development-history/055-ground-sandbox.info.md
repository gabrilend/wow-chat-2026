# 055-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=300&turn=3&fence=2&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=300&turn=3&fence=2&view=fence)
- Commit: 47bb95d (with uncommitted changes to its sources)
- Filed: 2026-10-28 23:00 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 415733fb56ebd60a |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 054-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 054-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 054-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 054-ground-sandbox

## What it shows
Wedges, five minutes, with orbiting in place of backing up: a new 'Stuck check' slider (1 s); bots ringed cyan are orbiting an obstacle; the panel: stuck 516 times (orbits begun 516; the rest of the line runs past the panel's edge), caught by the world 61 times, 124 steps refused, 125 doodads shown, steps turned aside down to 55 a second (185 before), spacing 16.1 yards, 22% of the fence covered in the last minute.

## The story so far
The owner's rule (2026-10-28, 617e16h): the same movement order for a second or more (configurable), snapshot and range check toward the target; less progress than able means stuck; orbit the unpathable obstacle clockwise or counter-clockwise until a forward point is in line of sight, then go on. Backing up gave way to it.
