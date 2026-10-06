# 155z1 - Outland's Folk Scaled to Their Threats

## Status
- Created: 2026-10-04
- Phase: 1
- Parent: 155z (the Dark Portal front)
- Blocked by: None
- Priority: Medium
- Related: 155k (the +4 for Outland's monsters, and the generator that sorts friend from foe by faction)

## Origin

See 155z (the owner's words, 2026-10-04, quoted in full there).

## Current Behavior

Not built. 155k raises every hostile and neutral Outland creature by four
levels (six on the Isle) and leaves the friendly ones stock, so a Honor
Hold or Thrallmar guard, a vendor or a townsperson is several levels below
the monsters around its own town.

## Intended Behavior

"roughly scaled to the threats they are to diminish ... It should be an
even fight." Each friendly Outland creature (the generator's "friendly"
set: not in 155k's hostile or neutral lists) is raised to the level of the
threat near where it stands: the median level (after 155k) of the hostile
creatures spawned within a fixed radius of its spawn point, never below
its stock level. A guard among level-66 boars and demons fights at 66.
Health, damage and armour follow the level by the server's own
per-level tables, so "an even fight" means a level match, not hand tuning.
A friendly creature with no hostile spawn within the radius is left stock.

## Suggested Implementation Steps

1. Generator (beside `scripts/generate-basic-outland-world-levels-sql`):
   for every friendly spawn in Outland, the median level of hostile spawns
   within the radius, from the world database; writes a SQL block of
   (creature template, new level) rows; a template spawned in several
   places takes the highest.
2. Apply/revert SQL in `sql/basic/db_world.src/`, saved originals,
   exact-revert checksum in `scripts/test-basic-sql-in-ram`.
3. A check in `scripts/validate-basic-state`: no friendly Outland template
   below the median threat around it.

## Open Questions

1. The radius (say 60 yards), and median or maximum of the threats?
