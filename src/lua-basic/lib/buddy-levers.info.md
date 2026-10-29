# lib/buddy-levers.lua

Pulls a buddy's levers (issue 638): one small thing a buddy can do with its
body, carried out with the server's own commands. The levers themselves are
data (`data/buddy-lever-list.lua`, written by `scripts/generate-buddy-levers`).

## A lever (a record of the list)

| Field    | Type             | Holds |
|---|---|---|
| `id`     | string           | unique name, `emote.bow.at-partner` |
| `kind`   | string           | the way it is done: `text-emote`, `motion`, `stand`, `sheathe`, `face`, `turn`, `hop`, `step`, `approach`, `withdraw`, `circle` |
| `target` | string           | `none`, `partner`, `buddy`, `player`, `creature` |
| `needs`  | list of strings  | `out-of-combat`, `idle` |
| `say`    | string           | what it does, in plain English (the semantic map's input) |
| `values` | table            | the kind's numbers and text: `motion` (Emotes.dbc id, number), `act` (`once`/`stand`/`loop`), `param` (number), `text` (the emote line, `%s` for the target's name), `state`, `turn` (radians), `yards`, `radius`, `dir` (1 clockwise, -1 counter), `away` (0/1), `stop_at` |

## Functions

- `pull(buddy, lever, ctx)` → `true`, or `false, reason` (string).
  `buddy`: a Player. `ctx`: a table, `partner` (Player or nil), `buddies`
  (list of Player: the partner's buddies in the world), `idle` (boolean:
  the buddy isn't being moved by its orders; a game master's pull is
  idle). Finds the target, checks the needs, carries the lever out.
  Refuses: a kind or target no table knows, a need not met, no target
  within 30 yards.
- `index(levers)` → table, lever id → record.
- `WAY_KINDS` → table, kind → true: the kinds `pull` can carry out (the
  test checks every generated lever's kind is among them).

## Notes

- A hop is a real jump (`MoveJump`): upward 7.96 yd/s, forward its length
  over the 0.83 s a jump is in the air.
- Movement levers need `idle`: the bot module plans a buddy's movement
  every moment and would undo a step taken while it follows.
- Tested by `scripts/test-buddy-levers` (every lever pulled on a stand-in).
