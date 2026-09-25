# 153c - Triple the Critter Density

## Status
- Created: 2026-09-03
- Phase: 1
- Parent: 153
- Depends: 153b (a world with only critters left in it)

## Origin

> triple the number of critters in the world

## Current Behavior

Critters are ordinary static creature spawns. Each row in the `creature` table
is one animal at one fixed position, with a `spawntimesecs` respawn delay, and
`creature_template.type = 8` marks it as a critter. There is no density knob:
the population is exactly the set of rows, and AzerothCore has no multiplier
config for ambient creatures the way it has `Rate.Creature.*` for their stats.

After 153b runs, the critters are the only creatures left, so their count is
the entire living population of the world.

Get the current figure rather than trusting one written here:

```sql
SELECT COUNT(*) FROM creature c
JOIN   creature_template t ON t.entry = c.id1
WHERE  t.type = 8;
```

## Intended Behavior

Three times as many, spread the way the originals are spread.

The important word is *spread*. Tripling by putting three rabbits on the same
spot produces a world with the same emptiness between the same clumps, only
now each clump is a pile. What the brief asks for — a world that reads as
inhabited when you cross it — is three times the *encounter rate*, which means
three times the positions, not three times the bodies per position.

So each existing critter spawn becomes three spawns: the original, untouched,
plus two new ones scattered within a short radius of it. The scatter radius is
the design decision. Too small and it is a pile; too large and critters end up
in the lake, inside a rock, or on the wrong side of a cliff.

### Where the copies go

The scatter has to respect terrain, which means each new position needs its
`z` read from the map rather than copied from the original. The travel and
ambush systems already solve exactly this problem — `movement.lua` holds the
angle-and-distance position helpers, and both callers validate the result by
comparing the map height against the origin's and abandoning the position if
the difference is too large. That validation is the part worth reusing; the
constants are not, because a critter can live on a slope that an ambushing
monster should not spawn on.

### Why this is generated, not hand-written

Per project practice, a table of tens of thousands of rows is not something
anyone maintains. The deliverable is a **generator** that reads the current
critter spawns out of the world database and emits the scattered copies as
SQL. It is re-runnable: if the base spawn set ever changes, the multiplier is
regenerated rather than patched. The SQL it produces is a build artifact.

The generator also needs to be idempotent, or at least detectably so, because
running it twice produces nine times the critters and nothing warns you. The
straightforward guard is to give generated rows a distinguishable `guid` range
and have the generator delete that range before it writes.

## Suggested Implementation Steps

1. **Read the existing spawn set** — guid, entry, map, position, orientation,
   spawn timer, phase — for every creature whose template type is 8.

2. **Pick the scatter radius, and pick it by walking.** Spawn two test copies
   at several candidate radii in a starting zone and look at the result before
   committing to a number. This is a feel decision and the SQL cannot make it.

3. **Generate two copies per original**, each at a random angle and a random
   distance within the radius, each with its `z` resolved against the map and
   rejected if the height differs from the original's by more than a tolerance.
   A rejected position is re-rolled a bounded number of times and then skipped —
   a critter that cannot be placed is not an error worth stopping for, but the
   count of skips is worth printing, because a high skip rate means the radius
   is wrong for the terrain.

4. **Write into a reserved guid range** and delete that range first, so a
   second run replaces rather than compounds.

5. **Verify the multiplier and the distribution separately.** The count is a
   `SELECT COUNT(*)` and proves nothing about placement. The distribution
   check is a query for how many generated critters share a position with
   another to within a few yards — a high number means the scatter collapsed.

6. **Check what it costs the server.** Three times the creatures is three times
   the creature objects the grid system holds, updates and sends to clients.
   Critters are cheap individually and this is the only population left in the
   world, so the budget is almost certainly there — but measure it on a loaded
   zone rather than assuming, because "cheap" and "cheap times thirty thousand"
   are different claims.

## Affected Files (anticipated)

- a new generator under `src/tools/`, and the SQL it emits into `sql/explore/`
- `docs/balance-updates.md` — the scatter radius and the multiplier are knobs,
  and per project practice knob-turning is recorded there rather than in an
  issue file

## Related Issues

- **153b** the world emptied to critters — must run first
- **210 / 302** ambush spawn queue and spawn debugging — the existing worked
  examples of placing a creature at a computed position and validating terrain
- **151** bot population governor — the other population number in the profile

## Open Questions

- **Is three the number, or is three the first guess?** The brief says triple.
  Tripling a population that is already dense in Elwynn and sparse in Desolace
  keeps that ratio, which may not be what "more alive" means. A per-zone
  target density is a different and harder design.
- **Do the copies share the original's respawn timer?** Copying it means three
  critters vanish and reappear together, which reads as a glitch. Jittering the
  timers costs nothing and looks better.
- **Should the copies vary in species?** A copy of a rabbit is a rabbit. A
  zone whose critters were 90% one species now has three times as much of that
  species. Substituting a zone-appropriate alternative for some copies would
  read as more varied, at the cost of needing a per-zone species table.
- **What happens in instances?** Same question 153b raises. If instanced maps
  keep their critters, do they get tripled too?
