# 042-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=240&turn=2&fence=2&view=fence' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=240&turn=2&fence=2&view=fence)
- Commit: 249eab2 (with uncommitted changes to its sources)
- Filed: 2026-10-28 21:18 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 78b680785a02c38c |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 041-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 041-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 041-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 041-ground-sandbox

## What it shows
The Witchwing Slayer area after the doubling was made to start again after any try that isn't stuck, and arriving within 4 yards no longer judged: still many ringed (backing) bots, most on the area's edge; stuck 968 times, 16,462 yards backed up, 735 known walls. Wanderers crossing aim 10 yards ahead, and at the edge that point is outside the area, so they meet the edge again and again.

## The story so far
Tuning the back-up rule (617e16h) one committed version at a time, at the owner's asking. 041: judged against the way to the target, backing up began, far too much.
