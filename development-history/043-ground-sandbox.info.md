# 043-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=240&turn=2&fence=2&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=240&turn=2&fence=2&view=fence)
- Commit: 0fe8a1f (with uncommitted changes to its sources)
- Filed: 2026-10-28 21:20 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | cca999aa9e058fa1 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 042-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 042-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 042-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 042-ground-sandbox

## What it shows
The Witchwing Slayer area after a wanderer stuck while crossing or turning aside takes it as its decision point: crossings now decide (83, against 46 before), ringed bots spread through the area rather than along its edge; still 961 times stuck and 13,418 yards backed up, mostly at the red steep patches inside, where a target lies behind the patch and straight progress toward it is impossible however often the bot backs up.

## The story so far
Tuning the back-up rule (617e16h) one committed version at a time. 041: backing up began, far too much; 042: the doubling restarts after any good try, still too much, most at the edge; 043: the edge cases fixed, the rest needs routes round obstacles, the step the owner placed after mapping.
