# 047-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=240&turn=2&fence=2&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=240&turn=2&fence=2&view=fence)
- Commit: a974d62 (with uncommitted changes to its sources)
- Filed: 2026-10-28 21:46 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 315ca08e1bc579d1 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 046-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 046-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 046-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 046-ground-sandbox

## What it shows
The Witchwing Slayer area, now in the sub-zone The Dry Hills (its squares shaded faint white), after the caught test became the owner's: inputs against position, the world refusing steps into doodads the bots don't know. Few red marks, where steps were refused; the panel: caught 445 times, 28,960 steps refused by the world, 131 known walls (716 before, most of them false), 5,128 yards backed up. A refused bot pushes on for the rest of its second before it learns.

## The story so far
The owner (2026-10-28) asked what the red pixels were (false walls from detours counted as stuck), and gave the rule: compare the line from where a bot was N moments ago with the moves it put in; less means the world held it back; mark it, disprefer the track that led there, walk round; others learn it. Bots now steer by steep ground and the learned map only, and the world refuses steps into doodads.
