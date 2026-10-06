# 155z4 - The Demon Tide

## Status
- Created: 2026-10-04
- Phase: 1
- Parent: 155z (the Dark Portal front)
- Blocked by: 155z2
- Priority: Medium

## Origin

See 155z (the owner's words, 2026-10-04, quoted in full there).

## Current Behavior

Not built. The stock Stair of Destiny has scripted demon waves of fixed
kinds.

## Intended Behavior

Demons climb the causeway continually, in three sizes:

- imp size;
- character size + 10%;
- overlord size: between 2 and 15 times character size (a random scale in
  that range per overlord).

Size is the creature's display scale, and a larger demon takes a wider
lane. When lanes are claimed, larger demons have priority, but a large one
displaces no more than a few smaller ones from their lanes; the rest keep
theirs. Demons fight only what is directly ahead of them, as the allies do
(155z5).

## Suggested Implementation Steps

1. The three sizes as data (creature entries per size, scale ranges).
2. Lane claiming by size with the displacement cap.
3. A steady arrival rate at the causeway's foot.

## Open Questions

1. The displacement cap ("a few": three?), and the share of each size.
