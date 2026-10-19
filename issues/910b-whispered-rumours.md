# 910b - Whispered Rumours

## Status
- Created: 2026-10-18
- Phase: 9
- Parent: 910 (wandering narrator system)
- Blocked by: 910a (narrators read aloud)
- Priority: Medium

## Origin

See 910, "Rumor Mechanics" and steps 5-8. The owner, 2026-10-18: "players
need to be able to whisper to them."

## Current Behavior

Not built. A whisper to a narrator bot goes to the bot module, which may
answer it by its own rules.

## Intended Behavior

- **Telling.** A player whispers a narrator; it keeps the message as a
  rumour, with its keywords (the longer words, common ones left out), and
  answers in a whisper that it will remember. At most one a second from
  one player (910's rate limit).
- **Passing on.** When anyone speaks in /say near a narrator and a keyword
  of a kept rumour is in what they said, the narrator tells it, in /say,
  in its own words around the player's ("Abandoned farm, you say? I heard
  ..."), and then forgets it: a rumour is told once.
- **Travelling.** Narrators share rumours among themselves (910's
  telephone game): how, and whether the words change on the way, is for
  this issue to settle.
- The bot module's own answer to the whisper is held back for narrators,
  so the player hears one reply.

## Suggested Implementation Steps

1. The whisper event in beta Lua (`PLAYER_EVENT_ON_WHISPER`, which names
   the receiver): store, answer, rate-limit.
2. Keyword matching on /say near the narrator; tell once, forget.
3. Settle and build how rumours pass between narrators.
4. Test with stand-ins, as 910a's test does.

## Open Questions

1. How do rumours pass between narrators: when two meet, at a set rate, or
   world-wide at once? And do the words change as they pass (the telephone
   game), or only the speaker?
