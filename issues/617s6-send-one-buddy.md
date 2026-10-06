# 617s6 - Send One Buddy

## Status
- Created: 2026-10-04
- Phase: 6
- Parent: 617s (the compass formation)
- Blocked by: 617s2
- Priority: High

## Origin

See 617s (the owner's words, 2026-10-04, quoted in full there).

## Current Behavior

Not built. The bot module's `rtsc` saves clicked spots and sends bots ("rtsc save #", "rtsc go #", addressable as @tank and so on).

## Intended Behavior

The owner names who goes and clicks where (owner, 2026-10-04): "@party or
@name to pick one specifically and @1 or @2 to select the first or second
character in your party and also we should be able to do as many as we
want at the same time." So: `@party` (every buddy in the group), `@<name>`,
`@<n>` (the n-th character of the party, in the party list's order), and
several at once (`@1,3`, `@Pozeta,Muspo`); each one picked goes to the
clicked spot and holds there until told to follow, and its ring slot
stays empty meanwhile (617s1 matches the rest without it).

**Built as our own, beside the bot module's `rtsc`, made as different as
possible so the two can be watched side by side** ("Try to distinguish
yourself from their implementation in as many ways as you can"):

| | `rtsc` (bot module) | ours |
|---|---|---|
| choosing the spot | a click spell, saved under a number, then "go" | one click sends at once, nothing saved |
| several sent | to one saved spot, piling up | spread on a small arc round the click (`lib/buddy-arc.lua`), each its own place |
| the way there | straight moves | the navigation mesh, the route drawn ahead |
| at the spot | stands | faces the way the owner faced when clicking |
| return | "rtsc go" again, or follow | `@... follow`, or walking 40 yards away from them |

## Suggested Implementation Steps

1. Read the bot module's `rtsc` (its click spell and its saved spots) and
   write down exactly what it does, as the table's left column.
2. Ours in `mod-buddies`: the addressing, the click (a spell of our own),
   the arc, the hold, the return.
3. Watch both in game.

## Open Questions

None beyond the parent's.
