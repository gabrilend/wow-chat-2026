# world-boss-countdown.lua (issue 155j)

When a dead world boss is due back: pure arithmetic, no server calls. Used by
`src/lua-basic/world-boss-respawn.lua`; tested by
`scripts/test-world-boss-countdown`.

## Values

| Name | Type | Meaning |
|---|---|---|
| `PASS_SECONDS` | number (5) | one pass of the countdown, in seconds |
| `BASE_SECONDS` | number (9000) | the wait with nobody there: 2.5 hours |
| `TOKEN_PERCENT` | number (1) | each moment token holds the boss back this % of a pass |

## Functions

- `Countdown.pass(elapsed, tokens, players) -> elapsed, tokens`
  One pass: `elapsed` (seconds since death, integer) grows by a pass;
  `tokens` (integer) grows by `players` (integer >= 0, the players present
  in the boss's area this pass).
- `Countdown.held_back(tokens) -> seconds`
  What the tokens add to the wait (`tokens x PASS x PERCENT / 100`). The one
  line to change if a token's worth changes.
- `Countdown.due(elapsed, tokens) -> boolean`
  Due when `elapsed >= BASE + held_back(tokens)`. 100 or more players
  present every pass: never due.
