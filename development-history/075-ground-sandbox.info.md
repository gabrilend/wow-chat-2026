# 075-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=3&fence=2&view=fence&way=paint&paint.UNKNOWN=0.15' --window 1600x1300 (photographed: headless Firefox, 1600x1300, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=3&fence=2&view=fence&way=paint&paint.UNKNOWN=0.15)
- Commit: af27705 (with uncommitted changes to its sources)
- Filed: 2026-10-29 13:07 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | d6ac2d9f64012a90 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/templates/paint-paths.js` | f832d5349ccb17d1 |
| `scripts/generate-ground-sandbox-data` | b7e99ee971272a39 |
| `scripts/generate-ground-sandbox-page` | 29502b7b6f306611 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: unchanged since 074-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 074-ground-sandbox
- `scripts/templates/paint-paths.js`: unchanged since 074-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 074-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 074-ground-sandbox

## What it shows
The Barrens' Witchwing Slayer area after 120 seconds, 36 bots, wedges, 1600 by 1300, Pathfinding painted map with the premium (paint.UNKNOWN=0.15, as the default), a second run: spacing 19.3 yards, covered 26%, turned aside 67 a second.

## The story so far
he painted map (617o8) joined the ground sandbox's ways and was compared
with the five (067-073). These three pictures test the owner's question
on trails: unknown ground costs 15% more than walked ground, which could
draw bots onto each other's tracks and cut their spread. Run against
picture 067 and each other, with the new address settings (paint.UNKNOWN=...).
