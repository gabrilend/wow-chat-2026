# 033-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=20&turn=2&fence=4&view=fence&start=far' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=20&turn=2&fence=4&view=fence&start=far)
- Commit: e9e6c67 (with uncommitted changes to its sources)
- Filed: 2026-10-28 20:42 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 861a0fd440a857f9 |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 47187b0abf6f6e73 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 032-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 032-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 032-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 032-ground-sandbox

## What it shows
The catch-up test with the bots started 1.2 times the catch-up distance away: 1 caught up; the bots are inside the Zhevra Runner fence within 100 yards of its middle, swirling round the player, 5 fights going, 7 done.

## The story so far
The owner (2026-10-28) asked for real monsters in the sandbox, the bots standing at each as long as a level-appropriate stand-in would take to kill it; for the bots to appear within 100 yards of the pocket when the player is a quarter of the continent away; and for bots walled off from the pocket to be moved onward (617e16g). Every monster spawn of both continents was written out with its health and respawn time; a fight lasts its health over a stand-in's damage a second at its level.
