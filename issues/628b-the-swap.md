# 628b - The Swap: the Baked Body Wanders, the Player Body Comes Back

## Status
- Created: 2026-10-17
- Phase: 6
- Parent: 628 (buddies wander as baked NPCs)
- Blocked by: 628a (the bake)
- Related: 617e1 and 617e2 (buddy roaming: the state the swap watches),
  617a5 (buddies hidden and locked: how a buddy is already kept out of
  sight), 164 (per-player unselectable creatures)
- Priority: Medium

## Origin

See 628 (the owner's words, 2026-10-17, quoted in full there).

## Current Behavior

Not built. A roaming buddy is always its player body.

## Intended Behavior

- **Into the baked body** when the buddy is roaming with nothing on: out
  of combat, in no group with a player, on no errand that needs a player
  (selling, training, a trade, boarding a ship), not in a battleground or
  dungeon. Its creature appears where it stands, facing the same way;
  its player body is hidden and can't be selected (628's question 1
  decides whether it stays logged in).
- **Walking.** The creature walks the buddy's roaming route at the
  buddy's speed (628's question 2 decides which of the two leads).
- **Back to the player body** the moment anything happens: an enemy
  attacks or comes within its aggro reach, a player groups with it, its
  owner calls it (the proximity party, 617c2), an errand starts, a
  conversation needs the real buddy (628c). The player body appears at
  the creature's spot and the creature goes.
- **No flicker.** A buddy that just came back to its player body stays
  in it for a while (a number, beside the other buddy timings) before it
  may bake again.

## Suggested Implementation Steps

1. The test for "nothing on", from the buddy module's existing state
   (roaming, combat, group, errands).
2. Swap in, swap out, on one buddy; trace lines for each swap and why.
3. Tuning: the stay-a-while time.
4. Measure the server's update time, player bodies against baked bodies,
   with 50 buddies roaming.

## Open Questions

1. How long should a buddy stay in its player body after something
   happened before it may bake again?
