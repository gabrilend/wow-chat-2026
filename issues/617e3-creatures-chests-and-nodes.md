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

## Suggested Implementation Steps

1. In the roam action (617e1): look for the nearest unclaimed chest or
   usable node within the pull distance; set it as a one-off waypoint.
2. The claim list per owner, cleared when the object is looted or gone.
3. In game at Fargodeep Mine: a buddy with mining walks to a copper vein
   it passes 40 yards away, mines it, and carries on round. Also: two
   clanmates near one vein, only one goes; a vein up a ledge the bot module
   won't open on arrival is given up after 30 s (one warning) and skipped
   for 10 minutes.

## Open Questions

- (2026-10-02) A vein above or below the buddy by more than about 3 yards
  passes the detour's look but the bot module won't open it on arrival
  (its height test is for arm's reach), so the buddy walks there, stands
  30 s, and gives up. In a mine with levels this may happen often. Patch
  the bot module's height test for buddies, accept it, or skip such nodes
  from the start (losing the ones a path really climbs to)?
- (2026-10-02) A detour drops the lap's current waypoint instead of
  returning to it afterwards; the bearing and Y are kept, so the lap goes
  on from the object. Is that what "the lap resumes after" meant?

## Related Issues

- **617e** parent; **617e1**; **617e2**; **617k** professions
