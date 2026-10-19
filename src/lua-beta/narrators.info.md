# narrators.lua

Some of beta's playerbots read books aloud (issue 910a). Defines the global
`Narrators`; registers a timer (every `TICK_MS`), the chat event and the
logout event. Reads its books through the narrators' library
(`lib/narrator-library.lua`, the global `Library`) and cuts long sentences
with `lib/gutenberg-sentences.lua`. Tested by `scripts/test-narrators`.

| Function | Takes | Gives |
|---|---|---|
| `Narrators.is_narrator(p)` | p: a player | true for a bot whose character number is a multiple of `NARRATOR_EVERY` |
| `Narrators.tick()` | nothing (the timer) | each narrator that a real player hears, that is not listening and whose pause is over, says its next line |
| `Narrators.on_chat(event, player, msg, type, lang)` | the chat event | a real player's /say quiets the narrators who hear them for `LISTEN_SECONDS` |
| `Narrators.on_logout(event, player)` | the logout event | a narrator that logs out forgets its reader and its place |

State: `Narrators.state[character number] = { parts = list of lines left of
the current sentence (text), next_at = tick time it may speak again (ms,
integer), quiet_until = tick time it listens until (ms, integer), started =
boolean }`; `Narrators.now` (ms of ticks, integer); `Narrators.broken`
(text: why the library could not start, once it could not; nil otherwise).

Tuning at the top of the file: `NARRATOR_EVERY` (20), `TICK_MS` (2000),
`HEAR_YARDS` (20), `LISTEN_SECONDS` (20), `PAUSE_MS` (3000) and
`PAUSE_PER_CHAR` (60), `CHAT_LINE_BYTES` (255).
