# narrators.lua

Some of beta's playerbots read books aloud (issue 910a). Defines the global
`Narrators`; registers a timer (every `TICK_MS`), the chat event and the
logout event. Reads its books through its own copy of the narrators' library
(`lib/narrator-library.lua`, kept as `Narrators.library`) and cuts long sentences
with `lib/gutenberg-sentences.lua`. Tested by `scripts/test-narrators`.

| Function | Takes | Gives |
|---|---|---|
| `Narrators.is_narrator(p)` | p: a player | true for a bot whose character number is a multiple of `NARRATOR_EVERY` |
| `Narrators.tick()` | nothing (the timer) | each narrator that a real player hears, that is not listening and whose pause is over, says its next line |
| `Narrators.on_chat(event, player, msg, type, lang)` | the chat event | a real player's /say quiets the narrators who hear them for `LISTEN_SECONDS` |
| `Narrators.on_logout(event, player)` | the logout event | a narrator that logs out forgets its reader and its place |
| `Narrators.on_whisper(event, player, msg, type, lang, receiver)` | the whisper event | a real player's whisper to a narrator is kept as a rumour (at most one a second from one player, `RUMOURS_KEPT` kept) and answered; returns false so the whisper goes no further; anything else, nothing |
| `Narrators.keywords(text)` | text | the set of its words of `KEYWORD_LETTERS` letters or more, lower case, common words left out |

`on_chat` also tells, once, a kept rumour whose keyword a real player says
within hearing ("Windmill, you say? I heard someone say: ..."), and forgets
it (issue 910b).

State: `Narrators.state[character number] = { parts = list of lines left of
the current sentence (text), next_at = tick time it may speak again (ms,
integer), quiet_until = tick time it listens until (ms, integer), started =
boolean, rumours = list of { text (text), from (a name, text), keywords =
set of words } }`; `Narrators.last_whisper[character number]` (ms, integer); `Narrators.now` (ms of ticks, integer); `Narrators.broken`
(text: why the library could not start, once it could not; nil otherwise).

Tuning at the top of the file: `NARRATOR_EVERY` (20), `TICK_MS` (2000),
`HEAR_YARDS` (20), `LISTEN_SECONDS` (20), `PAUSE_MS` (3000) and
`PAUSE_PER_CHAR` (60), `CHAT_LINE_BYTES` (255), `RUMOURS_KEPT` (20),
`WHISPER_EVERY_MS` (1000), `KEYWORD_LETTERS` (5).
