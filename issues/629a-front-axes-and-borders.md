# 629a - Front Axes and Borders

## Status
- Created: 2026-10-17
- Phase: 6
- Parent: 629 (battleground fronts)
- Blocked by: None
- Related: 176a1 (Alterac Valley's objectives), 176a2c (Arathi Basin's
  places and crossings, as data)
- Priority: Medium

## Origin

See 629 (the owner's words, 2026-10-17, quoted in full there): "always
fight for territory to the north. Or rather, on the (right angle to
equator) axis displaced by orientation" / "make a determinant axis for
each "border" between one or more objective".

## Current Behavior

Not built. No battleground has a recorded heading, and no objective
knows its neighbours.

## Intended Behavior

**A battleground's axis.** Each battleground has one heading, written
once as data: the north-south line of the map (at right angles to the
equator), turned by the battleground's own orientation. Each side pushes
along it, toward the other's home: in Alterac Valley the Alliance south,
the Horde north. A position's place on the front is its distance along
that axis; its place along the line is its distance across it.

**Borders between objectives.** Objectives (Alterac Valley's towers,
bunkers and graveyards; Arathi Basin's five bases) are points, written
once as data with their neighbours. Each pair of neighbours held by
different sides (or one unheld) has a border: the line midway between
them, at right angles to the line joining them. Its axis is that joining
line, pointing from each side's objective toward the other's. A bot
fights on the border its objective of the moment lies on.

**The fronts move.** When an objective changes hands, the borders round
it are recomputed (the ones it shared with a now-friendly neighbour
vanish; new ones appear toward the next enemy objectives).

Front: its axis (a direction, two numbers), its middle point (x, y), its
width (yards, how far the line runs across the axis), and the two sides'
objectives at its ends.

## Suggested Implementation Steps

1. The data: each battleground's heading; each objective's position and
   neighbours (Arathi Basin's from 176a2c's place table).
2. The borders from the data and who holds what: plain geometry, tested
   without a server; drawn over a map picture for the owner.
3. The recompute on capture.

## Open Questions

1. Is a single-axis front used anywhere once borders exist (Warsong
   Gulch, open fields in Alterac Valley between objectives), or do
   borders replace the battleground axis everywhere?
