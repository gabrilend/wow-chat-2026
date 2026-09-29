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
Chests and nodes: not built.

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
   it passes 40 yards away, mines it, and carries on round.

## Related Issues

- **617e** parent; **617e1**; **617e2**; **617k** professions
