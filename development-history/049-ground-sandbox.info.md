# 049-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=300&turn=2&fence=2&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=300&turn=2&fence=2&view=fence)
- Commit: c6d5bd9 (with uncommitted changes to its sources)
- Filed: 2026-10-28 21:53 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | a3e5ba825aceb968 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 048-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 048-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 048-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 048-ground-sandbox

## What it shows
After the counter was renamed: 103 moves to the emptiest sector in five minutes; bots per sector now 1 to 7; paths through the middle and out to the area's sides; 53 fights done; the fence covered 18% in the last minute. Every sector meets at the middle, so bots near it count in whichever sector their bearing gives.

## The story so far
The owner (2026-10-28): bots get stuck in little cocoons; staying in the same quadrant too long means they aren't circulating; they should spread out dynamically through the sub-zone (617e16k). The area is now cut into eight sectors by bearing; a bot in one sector over 30 seconds walks to the emptiest other sector, through buffers.
