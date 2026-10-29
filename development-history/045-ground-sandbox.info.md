# 045-ground-sandbox

## What made it
- scripts/generate-ground-sandbox-page --screenshot 'continent=1&zone=The%20Barrens&theme=night%20sea&sim=180&turn=2&fence=4' (photographed: headless Firefox, 1600x900, file:///mnt/kaun/wow-chat-2026/docs/HTML/ground-sandbox.html#continent=1&zone=The%20Barrens&theme=night%20sea&sim=180&turn=2&fence=4)
- Commit: dff82b5 (with uncommitted changes to its sources)
- Filed: 2026-10-28 21:33 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/templates/ground-sandbox.html` | 66712e1a81ca5a5b |
| `scripts/templates/ground-decode.js` | dba89933b746be94 |
| `scripts/generate-ground-sandbox-data` | 112d6512921268f3 |
| `scripts/generate-ground-sandbox-page` | 94faab27e336ad13 |

## What changed since the previous picture
- `scripts/templates/ground-sandbox.html`: changed since 044-ground-sandbox
- `scripts/templates/ground-decode.js`: unchanged since 044-ground-sandbox
- `scripts/generate-ground-sandbox-data`: unchanged since 044-ground-sandbox
- `scripts/generate-ground-sandbox-page`: unchanged since 044-ground-sandbox

## What it shows
The same view after the area became the player's own monster cluster (with any same-monster clusters touching it): the panel reads 'Zhevra Runner (41 spawns; part 1 of 2, 103,056 sq yd walkable)', 41 spawns where it was 83, but the same walkable area: the cluster itself is about 900 yards across, its spawns chained within 90 yards of each other.

## The story so far
Two fences (617e16j): the sub-zone cut (044) did little in a zone's generic sub-zone; the owner chose the player's own monster cluster as the limit. The cluster is now the area, and its size depends on how spawns are chained into clusters, the granularity the owner asked to be careful about.
