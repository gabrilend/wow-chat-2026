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
- (Answered 2026-10-23) **Every Outland town:** asked whether this covers
  only Thrallmar, Honor Hold and Shattrath (Outland's people were never
  removed: about 1,475 service NPCs stand across its towns): "let's scale
  them all, then." Every friendly Outland creature, as the design above
  says.
- (Answered 2026-10-23) **The rule: +4, as the monsters:** asked for a
  radius and median-or-maximum: "just give it +4 like we do with the other
  creatures." So no measuring of nearby threats: every friendly Outland
  creature gets E032's step, +4, or +6 when it stands only on the Isle.

**Built 2026-10-23, install step E070, waiting for an install**
(`patches/E070-basic-outland-folk-plus-four/`): every template standing
only in Outland or on the Isle that E032 didn't raise, apart from world
bosses, critters, invisible triggers, 155f's dungeon templates, E069's
four demons and the project's own creatures, raised by +4 (+6 when all
its spawns are on the Isle). 1,391 templates when built, 45 of them on
the Isle; the Dark Portal's defenders go from 68 to 72. Levels before are
saved for the revert. Tested on the real world database (applied twice,
reverted, every level back); the post-install checker has a check for it.
This replaces the generator and radius rule sketched above.
