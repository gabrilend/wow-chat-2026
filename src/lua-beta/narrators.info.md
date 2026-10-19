# narrators.lua

Some of beta's playerbots read books aloud (issue 910a) and pass on rumours
players whisper to them (issue 910b). Defines the global `Narrators`;
registers a timer (every `TICK_MS`), the chat, whisper and logout events.
Reads its books through its own copy of the narrators' library
(`lib/narrator-library.lua`, kept as `Narrators.library`) and cuts long
sentences with `lib/gutenberg-sentences.lua`. Saves each narrator's place in
the characters database table `beta_910a_narrator_reading` (install step
E061). Tested by `scripts/test-narrators`.

| Function | Takes | Gives |
|---|---|---|
| `Narrators.is_narrator(p)` | p: a player | true for a bot whose character number is a multiple of `NARRATOR_EVERY` |
| `Narrators.tick()` | nothing (the timer) | each narrator that a real player hears, that is not listening and whose pause is over, says its next line. The first time, it starts the narrator's reader and puts it back at its saved place; its place is saved after every new sentence |
| `Narrators.on_chat(event, player, msg, type, lang)` | the chat event | a real player's /say quiets the narrators who hear them for `LISTEN_SECONDS`, and makes them tell a kept rumour the talk names (below) |
| `Narrators.on_logout(event, player)` | the logout event | a narrator that logs out lets its reader and its rumours go from memory; its saved place stays in the database |
| `Narrators.on_whisper(event, player, msg, type, lang, receiver)` | the whisper event | a real player's whisper to a narrator is kept as a rumour (at most one a second from one player, `RUMOURS_KEPT` kept) and answered; returns false so the whisper goes no further; anything else, nothing |
| `Narrators.keywords(text)` | text | the set of its words of `KEYWORD_LETTERS` letters or more, lower case, common words left out |
| `Narrators.retell(text)` | text, a rumour | the rumour as a narrator passes it on, by `Narrators.retelling`: `"verbatim"` the same text; `"changed"` one word swapped for a near one (haunted to cursed, old to ancient, ...), the word chosen with `Narrators.random`; anything else is an error |

Rumours (910b): `on_chat` tells, once, a kept rumour whose keyword a real
player says within hearing ("Windmill, you say? I heard someone say: ..."),
and forgets it. Every other narrator within `HEAR_YARDS` of the teller, on
the same map, overhears it and keeps it, retold, one hop further on, unless
it has held that rumour before; it can tell it in turn. The overhearing is
done after all the tellings of one chat line, so a narrator does not learn a
rumour and tell it back to the same line.

The saved place: `beta_910a_narrator_reading (guid, book, position)`, all
unsigned integers: the narrator's character number, the book's Gutenberg
number, and how many of its sentences it has said. A saved book no longer
built, or a place past the book's end, starts the narrator on the book the
library gave it, from the start. A missing table (E061 not run) or no books
(E059 not run) is said once in the server log, and no narrator reads.

State: `Narrators.state[character number] = { parts = list of lines left of
the current sentence (text), next_at = tick time it may speak again (ms,
integer), quiet_until = tick time it listens until (ms, integer), started =
boolean, rumours = list, oldest first, of { id (integer, shared by every
retelling of one whisper), text (text), from (the whisperer's name, text),
hops (integer, 0 as whispered), keywords = set of words }, known = set of
rumour ids it has held }`; `Narrators.last_whisper[character number]` (ms,
integer); `Narrators.next_rumour` (integer, the last rumour id given);
`Narrators.now` (ms of ticks, integer); `Narrators.broken` (text: why the
narrators could not start, once they could not; nil otherwise).

Settable for tests: `Narrators.retelling` (text, starts as
`RUMOUR_RETELLING`), `Narrators.random` (function n -> 1..n).

Tuning at the top of the file (read it there for the current values):
`NARRATOR_EVERY`, `TICK_MS`, `HEAR_YARDS`, `LISTEN_SECONDS`, `PAUSE_MS` and
`PAUSE_PER_CHAR`, `CHAT_LINE_BYTES`, `RUMOURS_KEPT`, `WHISPER_EVERY_MS`,
`KEYWORD_LETTERS`, `RUMOUR_RETELLING` (`"verbatim"` or `"changed"`;
`"llm"` waits for a model runner, issue 916d, and stops the script with an
error), `READING_TABLE`.
