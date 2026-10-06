# 617r1 - Gearsets Keyed by Talent Shape

## Status
- Created: 2026-10-05
- Phase: 6
- Parent: 617r (gearset profiles)
- Blocks: 617r2, 617r3, 617r5
- Priority: High

## Origin

Verbatim, 2026-10-05:

> can you do gear profiles? For example a ret paladin who has half a tree
> of holy would want spellpower, while a ret paladin who has half a tree
> of prot would want dodge and parry.

## Current Behavior

Built 2026-10-05, tested offline (`scripts/test-gearsets`, 2532
checks); not yet run in game. `lib/gearsets.lua` reads each profile's
`keys` list and walks it (`record(profile, who)`); `nearest_shape` and
`points_of` work out a shape from spent points. `elite` was re-filed by
`scripts/rekey-gearsets-by-shape` (one-off): each of the seven outfits
copied to the three shapes led by the tree it was made for (21 records;
the even shape gets none); `vanilla-starter` is keyed `class, race`.
The gearset command finds a character's shape from its spent points, or,
for a buddy with none spent, its planned shape (roster), else shape 7.

## Intended Behavior

A gearset record is found by **talent shape**: the class plus one of the
ten shapes buddies are already planned in (`data/buddy-talent-data.lua`,
`shapes`: thirds of the points per tree, e.g. shape 1 "2/3 first tree,
1/3 second", shape 7 "1/3 each", shape 8 "all first tree"; the shape id
is the position, stored in `buddy_roster.profile`). So "2/3 Retribution,
1/3 Holy" and "2/3 Retribution, 1/3 Protection" are different keys and
can wear different gear.

The shape key is one integer: class id x 100 + shape id (a paladin's
shape 3 is 203). Each profile declares its keys, in the order they are
looked up, from:

| Key | Value | Found as |
|---|---|---|
| `shape` | class x 100 + shape id | exactly |
| `class` | class id | exactly (for gear worn before talents, the starter kit) |
| `race` | race id | exactly |
| `level` | the lowest level a record is for | the highest key at or below the character's level |

`elite` becomes keyed by `shape, race` (each outfit filed under every
shape whose largest share is the tree it was made for, so nothing is
lost); `vanilla-starter` stays `class, race`.

## Suggested Implementation Steps

1. `lib/gearsets.lua`: profiles declare `keys` (a list); `record(profile,
   who)` walks them with `who = { class, shape, race, level }`.
2. A character's shape: a buddy's from its roster row; anyone else's
   from 617r3 (until then, the shape nearest its spent points, or shape
   7 with none spent, the owner's rule).
3. Convert `elite` by a tool (each record copied to the shapes whose
   main tree it was made for).
4. Tests: lookup by each key kind; a missing key is named, never a near
   match.

## Open Questions

None.
