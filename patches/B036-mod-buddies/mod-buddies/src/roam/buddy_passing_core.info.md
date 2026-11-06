# buddy_passing_core.h

Two walkers passing each other: whether they would meet, how each swerves,
how they greet; and a buddy's round of its clan-mates at login (issue
617e11). Plain arithmetic, no server; checked by `scripts/test-buddy-passing`.
Not yet wired into the server: projecting each roaming buddy's neighbours
every movement update, bending its path, playing the emotes, and the round
at login are the server's part, still to build.

## Numbers

| Name | Value | Meaning |
|---|---|---|
| `HORIZON` | 3 | seconds ahead two walkers are projected |
| `ROOM` | 0.5 | yards kept between two bodies as they pass |
| `EASE` | 4 | yards before and after the meeting point the bend takes |
| `GREET_YARDS` | 5 | as near as two must pass to greet |
| `KNEEL_SECONDS` | 3 | how long the lower kneels |
| `KNEEL_RATIO` | 2 | "at least double its level" |
| `ANSWER_SECONDS` | 0.8 | the second wave, after the first |
| `PAUSE_MIN`, `PAUSE_MAX` | 1, 2 | the pause after a greeting at login |
| `CHAT_CHANCE` | 0.25 | a pause that becomes a chat |
| `CHAT_END` | 0.2 | the chance each /talk emote is the last |
| `TALK_SECONDS` | 2 | one /talk emote |

## Pieces

| Name | What it is |
|---|---|
| `Walker` | `x`, `y`, `vx`, `vy` (yards, yards a second), `radius` (yards, half the roam core's body) |
| `Meeting` | `t` (seconds), `yards`, and where each is then (`ax`, `ay`, `bx`, `by`) |
| `Meet(a, b, horizon)` | -> Meeting: where two straight walkers come nearest within the horizon |
| `Bend` | `needed`, `t`, `offset` (yards, + to the walker's left) |
| `Swerve(a, b, horizon)` | -> Bend: half the shortfall of two bodies and ROOM (all of it past someone standing), away from the other; in line, keep right and pass on the left |
| `BendAt(along, at, offset, ease)` | -> float: the sideways offset along the path, a half-cosine out and back round `at` |
| `Passer` | `level`, `fighting`, `player`, `clan`, `id` |
| `Act` (uint8 enum) | `None`, `Wave`, `Kneel` |
| `Greeting` | `act`, `delay` (seconds after coming level), `seconds` (a kneel's length) |
| `Greet(a, b, yards)` | -> Greeting: what `a` does as it passes `b`: kneel to double its level, wave otherwise (the higher, or the lower id, first); nothing too far, fighting, between clan-mates, or for a player |
| `Do` (uint8 enum) | `Walk`, `Wave`, `Pause`, `Talk` |
| `Step` | `what`, `to` (a clan-mate's id), `seconds` |
| `Mate` | `id`, `x`, `y` |
| `Round(x, y, mates, rng)` | -> vector of Step: the round at login, nearest first, each walked to, waved at, then a pause or now and then a chat |
