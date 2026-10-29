# 021-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=1&fence=0&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=120&turn=1&fence=0&view=fence)
- Commit: 61645b6 (with uncommitted changes to its sources)
- Filed: 2026-10-28 17:40 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 533f47df406c6eff |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 15aad026ffe4d823 |
| `scripts/generate-ground-sandbox-page` | 47187b0abf6f6e73 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: first picture that names it
- `scripts/templates/ground-decode.js`: first picture that names it
- `scripts/generate-ground-sandbox-data`: first picture that names it
- `scripts/generate-ground-sandbox-page`: first picture that names it

## What it shows
The Barrens, night sea, close on the Venture Co. Supervisor fence after 120 s, 50 degree limit: most of the fence and the land around is red (too steep) in thick bands; the 36 bots are a tight green knot in a small dark pocket, trapped; the panel: 0 of 36 circling, fence covered 1%, 365 steps turned aside a second, fence open 56%, 21,776 doodads in the zone.

## The story so far
The owner called the fish-school sandbox delightful but not quite it, and asked (2026-10-28) for an archived copy and a new one on the world's real ground: slopes over a limit unpathable, doodads avoided (issue 617e16c). The sandbox was archived and committed; a new tool reads every zone's heights from the map files and every collision box from the server's collision files; a new page shades the hills, paints ground steeper than a slider's limit red, and turns the bots aside from both. The first picture: the ground works, and the fence is a mistake of its own: two thirds of these Supervisors stand 100-170 yards under the ground, inside Boulder Lode Mine, so the fence is a mine and the red is the hill above it.
