# 018-judging-barrens-clockwise-strip

## What made it
- scripts/judge-run barrens-largest-clockwise (variant at commit d1ce350301): the three moments side by side, the strip the owner judges from (filed later; fingerprints are of today's files)
- Commit: 8660325 (with uncommitted changes to its sources)
- Filed: 2026-10-28 17:26 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/judge-run` | 4a8e1b655146197d |
| `src/lua-basic/data/judge-variants.lua` | bf12b7fca86e6776 |
| `scripts/templates/fish-sandbox.html` | 491a770b447085b2 |

## What changed since the previous picture
- `scripts/judge-run`: unchanged since 017-judging-barrens-clockwise-after-240s
- `src/lua-basic/data/judge-variants.lua`: unchanged since 017-judging-barrens-clockwise-after-240s
- `scripts/templates/fish-sandbox.html`: unchanged since 017-judging-barrens-clockwise-after-240s

## What it shows
One long strip of three frames, 60 s, 120 s and 240 s, left to right: the same fence and swirl each time, the arms of the swirl tightening toward the player by the third (spacing 6.2 to 4.9 yd).

## The story so far
On 2026-10-28 came the fish-school sandbox: the whole world map in a browser page, zoomable, with 36 bots flocking clockwise inside fences drawn round where each kind of monster spawns. Firefox runs it headless, with the settings in the page's address, so a picture can be taken without anyone at the screen. Then the judging machinery: a run plays one variant of the flock for a set time and keeps pictures at fixed moments, for the owner to judge by eye (and, later, a picture judge that agrees with her). The owner, 2026-10-28: 'I can manually judge for now but we should build the judgement machinery'.
