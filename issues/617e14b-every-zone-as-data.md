# 617e14b - Every Zone as Data

## Status
- Created: 2026-10-27
- Phase: 6
- Parent: 617e14
- Related: 617e7 (`scripts/generate-barrens-data`: one zone, the same sources)
- Priority: High
- State: built 2026-10-27

## Current Behavior

**Built 2026-10-27**: `scripts/generate-zone-maps [--map M]` reads the
server's map files (each ~33-yard square's sub-zone label) and the client's
area table (names, and which area is inside which), and writes one file
per zone, `assets/zone-maps/<map>-<zone>.lua` (ocean squares left out
since 2026-10-28, read from the map files' water section: the sea along a
coast carries the coast's label, and drew as great rectangles; that left
81 zones with land, from 196): the zone's name, its box of
squares, each square's sub-zone, the sub-zones' names, and each
sub-zone's tint, chosen so touching sub-zones differ (617e7's six tints of
grey, darker and nudged toward red, green or blue). A square's zone is the
top of its sub-zone's parent chain. `scripts/test-zone-maps` checks the
files against the map files.

## Intended Behavior

As above: every zone of the continents (maps 0, 1, 530, 571), and any
instance map asked for, as plain data the renderer reads.

## Suggested Implementation Steps

1. The generator (done), per map, one worker per map.
2. Its test (done).

## Open Questions

- None.
