# 910c - Stopping for Listeners

## Status
- Created: 2026-10-18
- Phase: 9
- Parent: 910 (wandering narrator system)
- Blocked by: 910a (narrators read aloud)
- Related: 908 (narrator audience facing)
- Priority: Medium

## Origin

See 910, "Core Identity" ("Stop moving when a player/bot sits within 5
yards") and "Movement Behaviors", steps 2, 4 and 11.

## Current Behavior

Not built. Narrator bots wander and fight by the bot module's rules while
they read (910a).

## Intended Behavior

- A narrator stops wandering while a player or bot sits within 5 yards of
  it, faces its listeners (908), and goes on its way when nobody is
  sitting near it any more.
- Its walking patterns while reading (910's orbit, midpoint walk, pacing)
  are for this issue to choose among.

## Suggested Implementation Steps

1. Find whether beta Lua can hold a playerbot still (its strategies, or
   movement calls on the bot) or whether the bot module needs a change.
2. The sitting check near each narrator, from 910a's timer.
3. Facing (908).

## Open Questions

1. Which of 910's walking patterns matter for the first version?
