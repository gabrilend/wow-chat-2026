# 617e3 - Creatures, Chests and Gathering Nodes

## Status
- Created: 2026-09-27
- Phase: 6
- Parent: 617e
- Blocked by: 617e1, 617e2
- Priority: High

## Current Behavior

**The monsters' part built 2026-09-27, compile-checked, not yet run.** The
roam action (`buddies_roam_strategy.cpp`, `MobsNear`) hands the core, at
each waypoint pick, the creatures within 60 yards that would attack the
buddy on sight: alive, nobody's pet, not a critter or civilian or immune
to players, not already fighting, not tapped by another player, hostile
and aggressive toward the buddy, and worth experience to it; each with the
server's own aggro radius for the pair (`Creature::GetAggroRange`: 20
yards, a yard less per level the buddy is above it, 5 to 45). The core
bends the trip through the first such radius on the way (617e2's nudge).

**Seen in game 2026-10-03: neutral monsters are never fought.** Every
monster in Ammen Vale (Vale Moth, Volatile Mutation, Mutated Root Lasher,
Blood Elf Scout, Mutated Owlkin, Nestlewood Owlkin) is of the neutral
"Creature" faction (7): yellow, never attacking first. The "hostile and
aggressive" test above drops all of them, grind is off (617e1), and a
neutral monster never starts a fight, so a level-1 buddy there (Mozonn,
Constine's paladin) has nothing to be nudged toward and nothing that
attacks it: it walked to the area's middle (stored at about 23 yards from
the Ammen Vale graveyard, which is why it looked like it was heading for
the graveyard) and moved back and forth near it. Starting zones are
mostly neutral monsters, so this is the common case at low level, not an
edge.

**Decided 2026-10-03 (the owner), not yet built: neutral monsters join
the steering.** A neutral monster worth experience is treated like a
hostile one for the nudge (option 1 of three offered; not grind, which
drops the circuit and beelines to anything within 100 yards). The owner:
"we should dynamically calculate the radius, and steer the buddy-bot to
the edge of that circle. It'll be different depending on the bot level and
the monster and maybe some other things. Then they should start casting
spells or charging in to fight or stealthing up or whatever the class the
buddy-bot is does. Once the monster is slain, they continue on their
circuit." So:
- the radius is worked out per buddy and monster, as the aggro radius is
  for a hostile one (level difference, the monster's own reach); a
  neutral monster has no aggro radius of its own to read, so the formula
  is ours to write (an open question: which inputs beyond the two levels);
- the buddy is steered to the edge of that circle, not into it;
- at the edge it opens the fight the way its class does (the bot module's
  class strategies: a pull spell, a charge, stealth first), which a
  neutral monster otherwise never gives it the chance to do;
- after the kill, the circuit carries on from where it bent.

**Chests and nodes built 2026-10-02, syntax-checked, not yet compiled or
tried in game** (same file, "the detour" and "the clan's claims"). Every
2 seconds (`DETOUR_LOOK_MS`) a roaming buddy not on a detour looks through
the objects the bot module already sees (its "nearest game objects", 100
yards; the bot module doesn't test line of sight there, so the detour
does) for the nearest one farther than the bot module's loot reach (15)
and within `DETOUR_YARDS` (45), in the owner's area, which it could open:
a chest-type object (chests and herb and ore nodes all are), spawned,
closed and idle, read as worth looting by the bot module's own loot
reading (`LootObject`: quest-only chests it doesn't need are skipped; the
lock gives skill, skill level or key), its key carried, the skill known
and high enough (never fishing), and for mining a pick by the core's
tool-category test (165, which also accepts the army knife and hammer
picks). The bot module's height test (about 3 yards) is left out at
range, since a node up a slope would fail it; it still applies on
arrival. The object is claimed for the clan (per owner; a claim lapses
after 30 s), marked tried for 10 minutes, and becomes the buddy's only
path point; the pinwheel's bearing and Y are untouched, and the old
waypoint is dropped, so the next pick carries the lap on from the object.
Within loot reach roaming stands aside for the bot module's loot and
gather actions (which outrank it). The detour ends, letting go of the
claim, when the object is opened or gone, or after `DETOUR_GIVE_UP_MS`
(30 s, logged as a warning with the yards still short). Numbers in
`docs/balance-updates.md`.

**Unreachable nodes moved, built 2026-10-02, syntax-checked and its table
tested in RAM (`scripts/test-basic-sql-in-ram`, every step and check
passing), not yet compiled or tried in game.** Before a detour to a herb or
ore node (never a chest), the roam action asks the walking map for a path
(`NodeReachable`, the server's own path search). The buddy's own spot is
asked first, because the search answers "straight line" both for "no walking
map here" and, for players, for "the far end is off the walkable ground"
(`PathGenerator::BuildPolyPath`): a buddy off the map, a search cut short by
its length limit, or a node in water gives no verdict and the detour goes
ahead. A node off the walkable ground, with no path, or whose best path ends
more than `NODE_REACH_YARDS` (3) from it is handed to the node keeper
(`buddies_nodes.cpp`, `BuddyRetireNode`) and the buddy looks again 2 seconds
later. On the world's thread, after the map updates, the keeper:
- **retires** every spawn at the spot (all of a spot pool's ore or herb
  variants) in `buddy_retired_node` (characters database, added to
  `04-buddy-roster.sql` beside the other buddy tables, E042) and in memory;
- **moves** the node: within its spawn group (the zone's mother pool when
  the spot is a spot pool, else the spawn's own pool), the nearest member on
  the same map that is not up and not retired is spawned and the old one
  despawned, through the pool's own despawn-one and spawn-one steps with the
  pool manager's active record kept in step (the manager has no public
  "spawn this member" call; its read-only accessors and those steps are
  used, see the file's header for why that is sound);
- **leaves it in place** when the group has no free spot, or the spawn is in
  no pool; a retired spot left up is skipped by every buddy's detour;
- **keeps retired spots out**: at startup every retired spot the pools put
  up is moved off; a node entering a map at a retired spot later (a respawn
  roll picked it) is queued and moved.
Logs: a warning per retirement (spot, node, the buddy's path verdict, where
the node went); a later move as information; a pool out of reachable spots
as an error once per run. Known limit: a node standing in a map tile with no
navigation data would read as "off the walkable ground" and be retired;
counted 2026-10-02, no herb or ore spawn on basic stands in such a tile
(every one of the type-3 spawns whose lock needs Herbalism or Mining has
its `.mmtile`), so the limit is theoretical today. To recount after the
map data or the spawns change: read the herb/mining lock ids out of
`Lock.dbc` (a lock slot of type 2 whose index is 2 or 3), take each such
spawn's square by the server's rule (`int(32 - x / 533.333)`, the same for
y), and look for `data-files/mmaps/MMMXXYY.mmtile`.

The owner, 2026-09-27: "Don't forget about creatures, treasure chests,
and profession gathering nodes."

Playerbots already has the three behaviours (617e1): `grind` attacks what
is worth experience within 100 yards and in sight; `loot` opens corpses and
chests, and `gather` herb and ore nodes, but only within 15 yards of the
bot, with the skill and tool checks.

## Intended Behavior

- **Creatures**: a roaming buddy fights what its roaming brings it near
  ("they try and fight the same creatures in the same area that you do
  [...] as if the NPC bot was fighting in that particular area on their
  own", 617e). `grind` does the choosing and fighting; roaming resumes
  after.
- **Chests and nodes**: seen while roaming (within the 100 yards
  playerbots already looks) but farther than the 15 it will walk, a chest,
  or a node the buddy has the skill and tool for, becomes the buddy's next
  waypoint, once; the pinwheel's own bearing and Y are kept, so the lap
  resumes after.
- Two buddies don't go for the same chest or node: the first to claim it
  keeps it.
- Numbers to tune (balance file): how far a chest or node may pull a
  buddy off its lap.
- **Unreachable nodes are moved, for good** (Ritz, 2026-10-02: "if it's
  path can't find a route to a location that is within 3 yards, then we
  should despawn the ore node and create a new ore node at the nearest
  spawn spot, and remove the impossible node from the list of nodes that
  can spawn."): before walking, the detour asks the navigation mesh for a
  path ending within 3 yards of the node (the bot module's arm's reach). No
  such path: the node is despawned, the same kind of node appears at the
  nearest unoccupied spawn spot of its own spawn group, and the impossible
  spot is recorded so it never spawns again, for anyone, across restarts.
  Chests are not moved (only herb and ore nodes). Each removal is logged
  with the spot, the node, and where its replacement went.

## Suggested Implementation Steps

1. In the roam action (617e1): look for the nearest unclaimed chest or
   usable node within the pull distance; set it as a one-off waypoint.
2. The claim list per owner, cleared when the object is looted or gone.
3. In game at Fargodeep Mine: a buddy with mining walks to a copper vein
   it passes 40 yards away, mines it, and carries on round. A vein up an
   unclimbable ledge is moved to the nearest free spot of its group, logged,
   and does not come back after a restart. Also: two
   clanmates near one vein, only one goes; a vein up a ledge the bot module
   won't open on arrival is given up after 30 s (one warning) and skipped
   for 10 minutes.

## Open Questions

- (Answered 2026-10-02) A vein the buddy can't path to within 3 yards of:
  moved to the nearest spawn spot of its group and its own spot retired
  (Intended Behavior). Known cost: a spot a player could reach by jumping,
  but the navigation mesh can't, is retired too.
- (Answered 2026-10-02) A node whose spawn group has no other free spot is
  left in place, logged, and skipped by buddies (Ritz: "that's fine").
- (Answered 2026-10-02) Nodes in tiles without navigation data: there are
  none on basic (counted, Current Behavior), so no rule is needed yet.
- (2026-10-02) **Sweeping ahead of time** (Ritz: "isn't this something we
  could cache ahead of time? Pre-process like, right now?"): either a
  one-time GM sweep inside the server, using its own pathfinder from a
  nearby open-ground spot (road, graveyard, flight point) to every herb and
  ore spawn, or a standalone tool reading the map files with the same
  pathfinding library. Which, and what counts as "the open ground" a node
  must connect to?
- (2026-10-02) A detour drops the lap's current waypoint instead of
  returning to it afterwards; the bearing and Y are kept, so the lap goes
  on from the object. Is that what "the lap resumes after" meant?

## Related Issues

- **617e** parent; **617e1**; **617e2**; **617k** professions
