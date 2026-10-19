# 1202b - The Performers Walk the Stage

## Status
- Created: 2026-10-17
- Phase: 12
- Parent: 1202 (the robot stage show)
- Blocked by: nothing
- Related: `docs/roaming-pattern.md`, `scripts/test-roam-pattern`,
  1201a (the pattern's third implementation, in Squirrel)
- Priority: Medium

## Current Behavior

The roaming pattern has a JavaScript implementation
(`docs/HTML/buddy-roaming/roam-pattern.js`) that runs the gallery's
playable scenes, held to the Lua one by `scripts/test-roam-pattern`. It
knows open ground, caves and dungeons, not a stage.

## Intended Behavior

The stage floor of each scene (1202a) is the pattern's area (a union of
rectangles, in yards scaled to the stage). The robots use the pattern
unchanged:

- **Wandering** between lines, as buddies roam: no robot stands still
  for long, none walks off the floor, they keep apart (the pattern's
  spacing).
- **Gathering** at a clicked thing: it becomes the waypoint (the
  owner's waypoint rule in the pattern), and the robots form round it
  facing the audience, not with their backs to the children.
- **Exits and entrances** between acts: walking off to the wings
  (two rectangles beyond the arch), and back.

Facing the audience is the one rule a stage adds; it is added to the
JavaScript as a final turn after each step, not to the pattern, which
stays the same in all three languages.

## Suggested Implementation Steps

1. Load a scene's stage area into `roam-pattern.js` as an area.
2. The gather-at-a-waypoint and face-the-audience behaviour.
3. Wings and entrances.
4. Seeded runs drawn as a strip of frames, checked like the gallery's:
   no robot off the floor, none overlapping another, all facing front
   after gathering.
