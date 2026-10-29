# 007-zone-render-eastern-plaguelands

## What made it
- scripts/render-zone, Eastern Plaguelands (0-139), 1920x1080, a recorded moment of 2026-10-27 01:20:50 with 120 s tails (filed 2026-10-28 from tmp/shared-memory; the fingerprints are of the files as they are now)
- Commit: 8660325 (with uncommitted changes to its sources)
- Filed: 2026-10-28 17:26 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/render-zone` | 89d0b6dab60aca39 |
| `assets/zone-maps/0-139.lua` | 69be2856f73ea5b8 |

## What changed since the previous picture
- `scripts/render-zone`: first picture that names it
- `assets/zone-maps/0-139.lua`: first picture that names it

## What it shows
The Eastern Plaguelands from above on a grey ground: the zone's squares in three muted colours by sub-zone kind (brown, green, slate blue), blocky edges. Upper left, inside a small brown area, five dots: one white (the player) and four blue (buddies), with short dotted tails of where they walked.

## The story so far
The owner asked (2026-10-27) to see the world from above: a map per zone with the buddies drawn on it, about 36 bots at once, as a benchmark a judge can pass or fail. The zone data (each zone's squares, from the game's map files) and a renderer that draws a recorded stretch of positions came first.
