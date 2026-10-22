# 632 - A Dead Buddy Releases, and Walks Back to Its Body

## Status
- Created: 2026-10-22
- Phase: 6
- Related: 617e (buddy area adventuring), 617e1 (the roam strategy),
  617e4 (towns: the exploring grid and distance maps)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-22:

> buddy-bots in ghost-mode (after 1-10 seconds after they die they click
> "release spirit" unless there's a person nearby who maybe can rez them
> alive and on their side. If so, then they wait. Anyway once they
> release, they should wander back to revive themselves. They should use
> sine-wave arcs to pathfind and try to roll down or straight up tangent
> line to hills.

## Current Behavior

A dead buddy does what the bot module's death handling does (release,
run back, or be revived by the module's own rules), with its stock
timing; nothing checks for someone nearby who could resurrect it, and
the run back is the module's straight path.

## Intended Behavior

- **Dying:** a dead buddy waits a random 1 to 10 seconds, then releases
  its spirit, unless someone who could resurrect it is near and friendly
  (a player or bot of its side who knows a resurrection spell, alive,
  open question 1 on how near). Then it waits (open question 2 on how
  long).
- **The walk back:** as a ghost it walks from the graveyard back to its
  body and revives there. Its path is not a straight line: it weaves in
  gentle side-to-side arcs (a sine wave along the way), and on slopes it
  goes straight down or straight up a hill, or along it (open question 3),
  rather than diagonally.

## Suggested Implementation Steps

1. Answer the open questions.
2. The release: on death, a timer of 1-10 s; when it ends, a check for a
   friendly resurrector within range; release, or wait and check again.
3. The path: the server's pathfinding gives the way; the buddy walks it
   as a series of points pushed sideways by a sine of the distance
   travelled (an amplitude and a wavelength, at the top of the code),
   each pushed point checked for ground (no pushing off cliffs or into
   walls; the exploring grid of 617e4 knows walkable cells where one
   exists).
4. Slopes: where the ground rises or falls steeply, the sideways push is
   turned along the slope's direction (straight up or down the hill) for
   that stretch.
5. Tests: the path shaper on a made-up flat field and a hill: the points
   weave, stay on ground, and go straight up the hill.

## Open Questions

1. **Who counts as able to resurrect:** a player character of its side
   knowing a resurrection spell (priest, paladin, shaman, druid in or out
   of combat), within how many yards (say 40)?
2. **How long it waits** for that someone before releasing anyway (if it
   never comes)?
3. **"Roll down or straight up tangent line to hills":** straight down
   and straight up the slope (along the steepest direction), or along the
   hill's side, level, the way a road winds around it?
