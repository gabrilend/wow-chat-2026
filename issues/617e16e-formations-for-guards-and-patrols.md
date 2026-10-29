# 617e16e - Formations for Guards and Patrols

## Status
- Created: 2026-10-28
- Phase: 6
- Parent: 617e16 (the fish-school sandbox)
- Related: 617e16c (the ground sandbox, where it is tried), 617e16d (the
  wanderers), 617e1 (the buddies' own follow formations: the arc and the
  single file), and the owner's hero-less-moba
  (`/home/ritz/programming/ai-stuff/hero-less-moba/src/052-formations.lua`,
  its waves marching out already in ranks)
- Priority: Medium
- State: in progress

## Origin

The owner, 2026-10-28:

> also, they should possibly move in formation... there's a game
> somewhere that we worked on, it may or may not have llm-transcripts file.
> Can you find it? It had an orange and blue and gray background, with
> orange and blue interface elements and gameplay. It was sorta like a
> MoBA. It was really cool actually! I wanna work on that. Anyway, can we
> add formations, for things like guards or patrols? They should just be
> shapes that the system treats rigidly, or allows to rotate.

The game is hero-less-moba (its renderer's team colours: orange
0.96/0.66/0.24, blue 0.36/0.78/0.93, a grey third; transcripts Sep 1-15,
2026). Its formations hold each body's place in the lane's own
coordinates (distance along, distance across), so a rank bends round a
corner without tearing apart: the idea a patrol walking a curved route
here can borrow.

## Current Behavior

**Built 2026-10-28 in the ground sandbox** (steps 1-4; pictures 026,
027): Formation (none, line, column, wedge, ring, square; 3 yards
apart), Formed (how many of the bots, 3-16), Shape turns (turning, or
rigid: front always north). The anchor patrols round the fence at three
quarters of its depth, 3 yards a second; with no fence it keeps 8 yards
from the player. Members steer to their places, slowing as they arrive
and hurrying when behind (up to 1.5 times the flock's speed), keep only a
body's width apart, and go round steep ground and doodads like everyone.
Drawn in the fence's lit colour; the panel gives their average distance
from their places (2.6-3.0 yards in the pictures). Not built: step 5,
formations in the world.

## Intended Behavior

- **A formation is a shape**: a list of places (offsets in yards from an
  anchor point), named: line abreast, column, wedge, ring, square.
- **Rigid or turning**, the owner's two: a **rigid** formation keeps its
  shape's orientation whatever way it walks (a guard post's square that
  always faces north); a **turning** one rotates the shape so its front
  faces where the anchor is heading (a patrol's wedge, point first).
- **The anchor walks a route**: for a patrol, round its fence's edge (a
  little inside it), at walking pace; for a guard post, it stands.
- **The members hold their places**: each steers to its place (the
  anchor plus its offset, turned or not), with the same ground rules as
  everyone (steep ground and doodads turned aside from), catching up
  faster when behind.
- In the sandbox: a formation control on the panel (none, or one of the
  shapes), how many bots form it (the rest wander as before), and the
  rigid or turning choice.

## Suggested Implementation Steps

1. The shapes as data (offsets) in the ground sandbox's page.
2. The patrol's anchor: a route round the fence edge, its heading.
3. Members' steering to their places, through the same turn-aside.
4. Panel controls, address settings for headless pictures, pictures
   filed.
5. Later, for the buddies themselves: the same shapes for guards and
   patrols in the world (with 617e1's follow formations).

## Open Questions

1. Who forms up in the world, later: buddies standing guard for their
   partner (617's guarding), the monsters' own patrols, or both?
