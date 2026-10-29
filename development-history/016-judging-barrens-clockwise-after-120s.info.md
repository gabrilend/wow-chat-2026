# 016-judging-barrens-clockwise-after-120s

## What made it
- scripts/judge-run barrens-largest-clockwise (variant at commit d1ce350301), its picture after 120 simulated seconds (filed later from tmp/shared-memory; fingerprints are of today's files)
- Commit: 8660325 (with uncommitted changes to its sources)
- Filed: 2026-10-28 17:26 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/judge-run` | 4a8e1b655146197d |
| `src/lua-basic/data/judge-variants.lua` | bf12b7fca86e6776 |
| `scripts/templates/fish-sandbox.html` | 491a770b447085b2 |

## What changed since the previous picture
- `scripts/judge-run`: unchanged since 015-judging-barrens-clockwise-after-60s
- `src/lua-basic/data/judge-variants.lua`: unchanged since 015-judging-barrens-clockwise-after-60s
- `scripts/templates/fish-sandbox.html`: unchanged since 015-judging-barrens-clockwise-after-60s

## What it shows
Close up on the Barrens' largest fence (Venture Co. Supervisor, 17 spawns), night sea theme, after 120 s: the yellow fence outline and its fainter padding, the white player dot, and 36 green bots with dotted tails sweeping clockwise round it. The panel adds a Live players switch (off). Circling counts: 27 of 36 at 60 s, 30 at 120 s, 28 at 240 s; spacing 6.2, 6.0 and 4.9 yd.

## The story so far
On 2026-10-28 came the fish-school sandbox: the whole world map in a browser page, zoomable, with 36 bots flocking clockwise inside fences drawn round where each kind of monster spawns. Firefox runs it headless, with the settings in the page's address, so a picture can be taken without anyone at the screen. Then the judging machinery: a run plays one variant of the flock for a set time and keeps pictures at fixed moments, for the owner to judge by eye (and, later, a picture judge that agrees with her). The owner, 2026-10-28: 'I can manually judge for now but we should build the judgement machinery'.
