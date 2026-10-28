# 635e - Moonfire from a Shared Moon

## Status
- Created: 2026-10-27
- Phase: 6
- Parent: 635
- Blocked by: none
- Related: none yet
- Priority: Medium
- State: plan

## Current Behavior

Moonfire's beam falls from straight above the target, a visual the client
draws from the spell itself. Starfall's stars fall round the druid.

## Intended Behavior

The owner, 2026-10-27: "can we make it so that the origin point of the
moonfire orbits the target? And if there's more balance druids casting
moonfire, it'll come from the same point more often. But, each druid uses
the same "moon" to reflect off of, floating around and orbiting in 3d
space. So long as it doesn't collide with the terrain or doodads, it can be
made to always take a consistent and stable course. Then, with many
moonfire druids, it will look like a near constant blaze. Allies will come
to know how many of them there are based on the strength and consistency
of their beams. Starfall comes from a random direction each time."

- **The moon**: one invisible flying marker per fight (per target, or per
  place; open question), orbiting in three dimensions on a steady course
  that never passes through ground or buildings (checked with the map's
  line-of-sight and height questions).
- **Moonfire's beam** is drawn from the moon to the target, by the moon
  casting a visual-only beam spell at it when a druid's Moonfire lands. The
  damage stays the druid's own spell. Every druid's Moonfire uses the same
  moon, so many druids make a near-constant beam from one moving point.
- **Starfall** draws its stars from a random direction each cast.

## Suggested Implementation Steps

1. Find a beam visual in the client's spell visuals that reads as
   moonlight (a visual-only spell, no effect), and the client's own
   Moonfire visual to hide or keep.
2. The orbit as a pure function (time → a point on a tilted circle round
   the target), clear of ground and buildings, with a test.
3. The hook on Moonfire landing; then Starfall.

## Open Questions

1. **Keep the client's own beam from above**, or hide it so only the
   moon's beam shows? Hiding it means changing the spell's visual in the
   server's spell data, which the client also reads (a client patch if
   the client's copy must change too).
2. **One moon per target, or one per place?** One per target makes each
   target's beam its own; one per place makes the whole fight share one.
