# 506g - Feldowinn Skeleton Borrowing

## Status
- Created: 2026-09-27
- Phase: 5
- Parent: 506
- Blocked by: 506f (a mesh); a stock model reader with bones and
  keyframes (506h reads bones, not yet keyframes)
- Priority: Medium

## Current Behavior

Not built. The reader (`src/tools/model/m2.lua`) reads bones and says
whether they carry keyframes; it doesn't read the keyframes yet. Items
(helms, shoulders, weapons, shields) need no skeleton (one root bone,
506h).

## Intended Behavior

The owner, 2026-09-27: borrowing a skeleton is "a good partway stopping
point because it has separate blockers from the animations" (the
generated animations are 506i). A creature or character mesh takes a stock
model's skeleton and animation set with the same body plan
(world-edit-to-execute W05b's design): each vertex is weighted to the
nearest bones (up to four, smoothed along the surface), and every stock
animation then plays on the new mesh, already named by the game's
animation table and so tied to the abilities that use them.

## Suggested Implementation Steps

1. Read bones' keyframes (the per-sequence track arrays, inline and from
   `.anim` files) in `m2.lua`; test on a stock creature.
2. Fit: scale and place the new mesh over the stock skeleton's rest pose
   (height, limb lengths: the body-plan fit of W05e).
3. Weights: each vertex's nearest bones by distance to the bone segments,
   up to four, normalised to 255; smoothed.
4. Write the skinned model to glTF (skin, joints, animations: the kept
   format), and to M2 for the stock client (506h's writer, extended to
   bones and tracks).
5. Test: a stock creature's own mesh re-weighted to its own skeleton
   plays its stock animations the same (measured by comparing posed
   vertices frame by frame).

## Related Issues

- **506** parent; **506f**; **506h**; **506i**
