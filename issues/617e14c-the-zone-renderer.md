# 617e14c - The Zone Renderer

## Status
- Created: 2026-10-27
- Phase: 6
- Parent: 617e14
- Blocked by: 617e14b
- Related: 617e14a (the record it draws), 617e7 (the GIF encoder it can
  use: the gif-generator project's)
- Priority: High
- State: built 2026-10-27 (one picture, and the animation); every zone at once not yet

## Current Behavior

**Built 2026-10-27**: `scripts/render-zone` draws one zone at one moment
from a positions record (617e14a's, or the spread record of 617e13): the
zone's sub-zones in their tints, filling a picture of the screen's size
(1920 x 1080 by default, the zone fitted and centred, north up), every
character in the zone a dot (players white, buddies coloured by owner,
other bots grey), with a tail of its last positions fading behind it. It
writes a PNG to `tmp/shared-memory/zone-frames/`. `scripts/test-render-zone`
draws a made-up record and checks the dots are where the record puts them.
`scripts/animate-zone` draws a stretch of the record, a frame every 5
seconds of it (one worker per processor), and joins the frames into a
GIF with ImageMagick: Feldowinn's 10-minute walk in the Eastern
Plaguelands (the spread record, 2026-10-27) made 131 frames at 960 x 540
in 5 seconds, 1.1 MB.

## Intended Behavior

- One picture per zone, the whole screen used (the owner: "one map per
  zone, with the entire screen used to visualize").
- A dot per character, a tail behind it: the pattern of movement, not only
  where everyone is ("the pattern of bots").
- Frames over a stretch of time made into an animation.

## Suggested Implementation Steps

1. One frame (done).
2. Frames to an animation (done: ImageMagick joins them; the gif-generator
   project's encoder, 617e7's, is the other way, not needed).
3. Every zone at once (`--all`): each zone with anyone in it, one picture.

## Open Questions

1. The screen's size: 1920 x 1080 is ours. What is the owner's?
