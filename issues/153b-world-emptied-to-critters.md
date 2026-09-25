# 153b - The World Emptied to Critters

## Status
- Created: 2026-09-03
- Phase: 1
- Parent: 153
- Depends: 153a (a database to strip), 203 (the precedent, completed)

## Origin

> All NPCs should be removed from the world, except critters.

## Current Behavior

A stock AzerothCore world database carries tens of thousands of static
creature spawns. Counted by creature type on the live world database:

```sql
SELECT t.type, COUNT(*) AS spawns
FROM   creature c
JOIN   creature_template t ON t.entry = c.id1
GROUP  BY t.type
ORDER  BY spawns DESC;
```

The type column is the creature's family, and type **8 is Critter** — rabbits,
squirrels, frogs, prairie dogs, the ambient animals with a handful of hit
points that exist to make a field look inhabited. Run the query to get the
current numbers rather than trusting a figure written here; at the time of
writing critters accounted for a five-figure minority of the total.

**Issue 203 has already done most of this work.** It is completed, and its
effect was "the world database contains no static creature spawns except
spirit healers and critters." Its SQL is the starting point, not something to
rewrite.

## Intended Behavior

The same removal as 203, on the explore profile's own database, with one
further deletion and one deliberate exception.

**Further deletion: the spirit healers go too.** 203 kept them because a
survival profile needs resurrection, and dying is a thing that happens there.
Explore has nothing hostile in it, so a spirit healer is a robed figure
standing in a graveyard for no reason. If it turns out a character can still
die — falling, drowning, drowning being the likely one — the healers come back
and this decision reverses. See Open Questions.

**Deliberate exception: the two profession trainers.** 153d puts herbalism and
mining trainers into the world, but as *travellers* — spawned near the player
by the travel system, not as static spawns. So nothing changes here: the
static removal is total, and the trainers arrive by a different door.

**Not touched: gameobjects.** Herb nodes and ore veins are gameobjects, not
creatures, and they are the entire point of this profile. Counted the same
way:

```sql
SELECT COUNT(DISTINCT t.entry) AS node_types, COUNT(*) AS spawns
FROM   gameobject g
JOIN   gameobject_template t ON t.entry = g.id
WHERE  t.type = 3;
```

Type 3 is the chest type, which is what a herb node and an ore vein both are
mechanically. That population stays exactly as it is. So does everything else
in the gameobject table — mailboxes, doors, campfires, the scenery.

## Suggested Implementation Steps

1. **Read 203's SQL rather than writing new SQL.** It is in the completed
   issue's record and in `source-beta/data/sql/custom/db_world/`. Find it,
   read what it actually deletes, and confirm its critter predicate is a
   `creature_template.type = 8` test rather than a hand-listed set of entries —
   a hand-listed set will have drifted.

2. **Apply it to the explore world database only.** The other four profiles'
   databases are untouched. This is the first real test of whether 153a's
   database separation actually holds.

3. **Decide the spirit healers, then delete or keep in one statement**, so the
   decision is visible in the SQL rather than implied by its absence.

4. **Verify by counting, not by looking.** After the strip, the creature table
   should contain critters and nothing else:

   ```sql
   SELECT t.type, COUNT(*) FROM creature c
   JOIN creature_template t ON t.entry = c.id1 GROUP BY t.type;
   ```

   One row, type 8. Any other row is something the strip missed.

5. **Walk a starting zone and look.** The count can be right while the
   experience is wrong — a zone with its guards gone but its buildings, torches
   and campfires intact reads as abandoned rather than as wilderness, which may
   or may not be the intent. This is the check the SQL cannot do.

## Affected Files (anticipated)

- a new SQL file under the explore profile's SQL directory, derived from 203's
- `sql/explore/` and whatever loads it at install time

## Related Issues

- **203** drop all creatures except spirit healers (completed) — the source of
  this issue's SQL and most of its thinking
- **153c** triple critter density — runs immediately after this and is
  meaningless before it
- **153d** the two trainers, which arrive as travellers rather than as spawns
- **902 / 903** dungeon room spawn zones and contextual creature spawns —
  both assume a world where things spawn; neither applies here

## Open Questions

- **Do spirit healers stay?** Depends entirely on whether a character can die
  in this profile. Falling damage and drowning are both still live in a world
  with nothing hostile in it, and the fall-damage multiplier is set to 10x by
  `config/patches/C004-fall-damage-10x.sh` — which, if inherited, makes death
  by cliff a routine event and spirit healers essential. Check whether that
  patch is gated to explore before deleting anything.
- **What happens to the buildings?** Every town is still standing, with its
  doors, forges, mailboxes and cooking fires, and nobody in it. Is an empty
  Stormwind the intended texture of this profile, or should the gameobjects go
  too and leave only landscape?
- **Do critters in dungeons and instances count?** The strip is world-wide.
  Instances contain critters as well as their bosses, and an instance emptied
  of everything but rats is a strange object. Leave instanced maps alone, or
  strip them the same way?
- **Are there hostile critters?** Type 8 is a family, not a disposition. If any
  type-8 creature is flagged hostile, the "nothing attacks you" premise has a
  hole in it. Query `creature_template.faction` across type 8 before assuming.
