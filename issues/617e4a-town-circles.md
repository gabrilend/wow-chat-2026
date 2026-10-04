# 617e4a - Town Circles: Towns Found From the People in Them

## Status
- Created: 2026-10-03
- Phase: 6
- Parent: 617e4
- Blocked by: 617e4 (the town visit)
- Related: 617o3 (towns baked ahead of time), 617e (town or country decides
  a buddy's behaviour)
- Priority: High (in a starting valley buddies never do town things)

## Origin

The owner, 2026-10-03: "the starting zones I noticed treat the entire
valley as one area, but there's a clear 'town' and 'wilderness' area in
each. Do you have any suggestions for how to get them to do 'town'
behaviors when the player is in town, and 'adventuring' when the player
is doing so?" Of three suggestions, the first: "great sounds good. Can you
find other similar clusters of helpful NPCs? I know there's plenty, like
the Bulwark in Tirisfal Glades..." And for placing circles by hand: "if
you can spawn a whisp NPC that stands at the radius chosen, at every point
of the circle, and disappears after 15 seconds. When I say 'a wisp' what I
mean is however many wisps it'd take to fully define the circle."

## Current Behavior

**Written 2026-10-03; the generator run (163 circles), the server's part
syntax-checked, not yet built or run.** `scripts/generate-buddy-town-circles`
writes `sql/basic/db_world.src/31-buddy-town-circles.{apply,revert}.sql`
(install step E050 copies it in); `buddies_town_circles.cpp` reads the
circles at startup, answers `BuddyTownCircleArea` (the 10-yard hold kept
per player), which `BuddyTownArea` now asks first, and gives game masters
`.buddy town here <radius>`, `.buddy town show` and `.buddy town remove`,
each drawing the circle in wisps (one every 3 yards round the edge, at
most 240, friendly and untouchable, gone after 15 seconds). A circle's
town is the area its middle stands in (Ammen Vale's camp: Crash Site,
area 3527). Left as found: a few 3-person clusters beside a bigger circle
(Coldridge, Aldrassil, the Valley of Trials), which hand-placed circles
can replace.

Before this:
A buddy is in town when its owner stands in an area the client's area
table flags as a town or capital (`BuddyAreaIsTown`, the shared rule in
`roam/buddy_town_rules.h`), or in a building inside one
(`BuddyTownArea`, `buddies_roam_ground.cpp`). The starting valleys are
left out on purpose (they are flagged as towns, but are mostly
countryside), so a valley's camp of trainers and shops is never a town,
and neither is any camp or quest hub the table doesn't flag (the Bulwark,
Sentinel Hill).

## Intended Behavior

- **Circles found from the people**: every cluster of at least 3 helpful
  people standing within 35 yards of each other (trainers, vendors,
  repairers, flight masters, innkeepers, bankers, auctioneers; hidden
  stand-ins left out) gets a circle: its middle the cluster's middle, its
  radius the farthest member plus 15 yards. Circles that overlap or come
  within 25 yards of each other are one town, redrawn round all their
  people. Generated, not hand-written: `scripts/generate-buddy-town-circles`
  writes them to the world table `buddy_town_circle` (install step E050).
  First run, 2026-10-03: 163 circles from 2,956 helpers, among them the
  Crash Site (Ammen Vale's camp), Northshire, Deathknell, Coldridge, the
  Valley of Trials, Camp Narache, Sunstrider Isle, Aldrassil, Brill, the
  Bulwark, Goldshire, Razor Hill, Sentinel Hill and Booty Bay.
- **In town**: an owner inside a circle is in town (its buddies run the
  town visit); they stay in town until 10 yards outside it, so standing at
  the edge doesn't flicker. Flagged towns stay towns as before.
- **Placed by hand**: `.buddy town here <radius>` (game masters) adds a
  circle where the game master stands; `.buddy town show` draws the
  nearest circle; `.buddy town remove` removes the nearest hand-placed
  one. Drawing a circle: wisps, as many as it takes to outline it (one
  every 3 yards round the edge), standing for 15 seconds. Hand-placed
  circles are kept by the generator (it reads them back from the table
  and writes them into the project's SQL), so re-running it after placing
  keeps them across a reinstall.

## Suggested Implementation Steps

1. The generator (clusters, merging, names from the area table, the SQL
   with the hand-placed rows kept); the install step.
2. `buddies_town_circles.cpp`: the circles read at startup and after a
   change; "which circle is this player in", with the 10-yard hold; the
   commands and the wisps.
3. `BuddyTownArea` asks the circles first; a circle's town is the area its
   middle stands in.

## Related Issues

- **617e4** parent; **617o3**; **617e**
