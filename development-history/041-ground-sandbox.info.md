# 041-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=240&turn=2&fence=2&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=240&turn=2&fence=2&view=fence)
- Commit: f9abac7 (with uncommitted changes to its sources)
- Filed: 2026-10-28 21:17 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 35974750433f7f6d |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 040-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 040-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 040-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 040-ground-sandbox

## What it shows
The Witchwing Slayer area after the stuck measure was changed to the way to the target: many bots ringed white (backing up) along the area's edges and the red patches; the panel: stuck 861 times, backed up 18,046 yards, 716 known walls, 2,120 buffer cells. Backing up now happens, far too often and too far: a bot going round a wall to a target behind it gets little progress toward the target, so detours count as stuck, and the doubling climbs.

## The story so far
The owner (2026-10-28): 'bots are still bumping into walls. they don't seem to be backing up at all', and asked for every version to be committed in this design process. The stuck measure had used the bot's velocity after the walls turned it, so sliding along a wall counted as progress; it now uses the straight way to the target.
