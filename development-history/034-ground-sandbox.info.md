# 034-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=240&turn=2&fence=2&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=240&turn=2&fence=2&view=fence)
- Commit: cf0a306 (with uncommitted changes to its sources)
- Filed: 2026-10-28 21:01 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | ae8118fbad955bac |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 47187b0abf6f6e73 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 033-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 033-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 033-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 033-ground-sandbox

## What it shows
The page as first built with the stuck rule: broken. An edit to the panel's measures left an 'else' without its 'if', so the page's main script didn't run; the picture shows the page without its simulation. Kept: the syntax check that ran before it logged the error but didn't stop the picture, and was changed to stop it.

## The story so far
The owner (2026-10-28) saw the bots getting stuck on obstacles and gave the rule (617e16h): moving at full speed without progress means stuck; back up, try again, twice as far each time, mapping the space until routes can be found over it. Each bot now measures its progress each second, backs up 2, 4, 8... yards when stuck, and every cell a bot stands in, or got stuck facing, goes onto one map the zone's bots share.
