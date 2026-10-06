# 617r4 - Gearsets on Creatures (the mirror image)

## Status
- Created: 2026-10-05
- Phase: 6
- Parent: 617r (gearset profiles)
- Related: 617f (Sargobras's mirror-image outfits), 155z6 (the Portal's elite heroes), 617t (stand-ins)
- Priority: Low (owner, 2026-10-05: "we should implement that... Not needed now, but it will be.")

## Origin

See 617r: "outfits that can be applied to buddy-bots, player-characters,
stand-ins, or NPCs via the mirror image trick".

## Current Behavior

Not built. The gearset command dresses players and buddies only.

## Intended Behavior

`.gearset <profile> target` dresses the selected creature: the creature
is shown as a player of the record's race wearing the record's items,
the way Sargobras is dressed (617f), so heroes and stand-ins can wear any
profile.

## Suggested Implementation Steps

1. Read how 617f dresses Sargobras and make it take a record.
2. The command's `target` form.

## Open Questions

None yet.
