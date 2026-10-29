# 065-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=3&fence=2&view=fence&way=orbit' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=3&fence=2&view=fence&way=orbit)
- Commit: c10d78f (with uncommitted changes to its sources)
- Filed: 2026-10-29 12:01 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 5dcfdb9e513e6402 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | b7e99ee971272a39 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 063-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 064-battleground-sandbox
- `scripts/generate-ground-sandbox-data`: changed since 063-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 063-ground-sandbox

## What it shows
he Barrens' Witchwing Slayer area after 120 seconds, Pathfinding "orbit",
after orbit's walk round was mended: it walks in at its target until the
way is blocked, turns side-on, and hugs what it feels beside it (within
4.5 yards), rounding a corner gently when it no longer feels it; before,
it turned in every step whether it felt anything or not, and walked rings
3 yards across. The green tails cross the fence's middle with fewer tight
knots than the orbit pictures before; a cluster of circling markers sits
at the fence's west side near a red steep patch. The panel: spacing 23.6
yards, fence covered 25%, 0 stopped, stuck 213 times with 940 yards
backed out (the stuck check itself still fires often: about three times a
bot a minute, the owner's open question on loosening it). The panel's new
first line links to the battleground sandbox.

## The story so far
he ground sandbox (617e16) put bots on real ground and compared five
ways to find a path (617o7). The module's offline test found the grid
ways cutting corners (mended on the page, 062-063), then, on the owner's
asking which part to iron out, that the owner's own orbit rule walked in
rings (8 to 10 times flow's steps round a wall); mended in the module
(121 steps round the wall, from 269) and here on the page (065). A
battleground page for two sides (064) was added beside it the same day.
