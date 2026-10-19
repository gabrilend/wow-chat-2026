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

**Telling and passing on built 2026-10-18 (homework branch); tested without
a server, not tried in game.** In `src/lua-beta/narrators.lua`: a real
player's whisper to a narrator is kept as a rumour with its keywords (words
of five letters or more, common ones left out), answered in a whisper ("I'll
remember that, and pass it on."), and stopped there, so the bot module does
not also answer; one a second from one player; twenty kept, the oldest
dropped. A real player saying one of a kept rumour's keywords in /say within
hearing makes the narrator tell it ("Windmill, you say? I heard someone say:
...") and forget it.

Travelling, built the same day: every other narrator within hearing of the
teller (the same 20 yards, the same map) overhears the telling and keeps the
rumour, one hop further on, unless it has held that rumour before (each
whisper gets a rumour number that every retelling shares, and each narrator
remembers the numbers it has held). It tells it in turn when it hears talk
of it. The overhearing waits until every narrator has answered the chat line,
so none learns a rumour and tells it back to the same line, and the
remembered numbers keep two narrators from handing one rumour back and
forth forever. How a narrator retells it is the tuning `RUMOUR_RETELLING`:
`"verbatim"` (word for word, the default) or `"changed"` (one word swapped
for a near one by a fixed list, haunted to cursed, old to ancient, north to
east, ... chosen at random among the rumour's words that have one).
`"llm"`, a language model retelling it, is named but stops the script with
an error until a model runner exists (916d).

Rumours live in memory: a narrator's logout, or a restart, forgets the ones
it held, as the owner chose (question 2).

`scripts/test-narrators` checks keeping, telling, the rate limit, and the
travelling in both retelling ways: overheard one hop on, not told back to
the same line, not heard out of earshot, told on later, not learned back by
the teller; and that an unknown way of retelling is an error.

Before this, a whisper to a narrator bot went to the bot module, which might
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
  telephone game) by hearing each other: a narrator near one telling a
  rumour learns it and can tell it later, wherever its questing takes it.
  The owner, 2026-10-18: "I think that any narrator should be able to
  repeat what they've heard. They're just going to be questing around,
  right?" The words change on the way or not, by a setting: "Let's build
  both behaviors in-case players don't want to deal with robots."
  Word for word, or changed by fixed rules (no language model); a third
  way, a model's retelling, waits for 916d.
- The bot module's own answer to the whisper is held back for narrators,
  so the player hears one reply.

## Suggested Implementation Steps

1. The whisper event in beta Lua (`PLAYER_EVENT_ON_WHISPER`, which names
   the receiver): store, answer, rate-limit.
2. Keyword matching on /say near the narrator; tell once, forget.
3. Passing between narrators: after the narrators answer a chat line, each
   telling is overheard by the other narrators within hearing of the
   teller; a rumour number shared by all retellings, and a set of numbers
   each narrator has held, stop double learning. The retelling ways are a
   table by name, so a new way (the model's) is one more entry.
4. Test with stand-ins, as 910a's test does.

## Open Questions

1. How do rumours pass between narrators: when two meet, at a set rate, or
   world-wide at once? And do the words change as they pass (the telephone
   game), or only the speaker? **Answered** 2026-10-18: by overhearing,
   any narrator; both ways, by a setting (above).
2. Should a narrator's rumours be saved like its place in the book, so a
   logout or a restart does not forget what players told it? Today they
   live in memory only. **Answered** 2026-10-19: "no it shouldn't."
   Rumours are memory only, by design: a logout or restart is a natural
   forgetting.
3. Which way of retelling should beta start with, word for word or
   changed? **Answered** 2026-10-19: "word for word for now."
   `RUMOUR_RETELLING` stays `"verbatim"`.
