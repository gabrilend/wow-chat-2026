# battleground-front.lua

The rules for bots holding a front in a battleground (issue 629 and its
sub-issues 629a-629d), as plain arithmetic: no server object touched.
`scripts/test-battleground-front` checks each rule and whole matches;
`scripts/generate-battleground-front-gifs` draws matches from above. The
buddy module's C++ is meant to be ported from this and compared against
it, as the roaming core was.

Positions are (u, v) in yards in the front's own frame: u across the
front (0 to `width`), v along the push (0 at side a's home, `depth` at
side b's). Side a pushes toward +v, side b toward -v.

## Functions

| Function | Takes | Gives |
|---|---|---|
| `Front.rand(seed)` | seed: integer | a function: `r()` a number in [0, 1), `r(n)` a whole number 1..n; the same seed, the same sequence |
| `Front.axis(heading)` | heading: radians counter-clockwise from the map's north | ax, ay: the unit direction side a pushes (Alterac Valley's Alliance: heading pi, pushes south) |
| `Front.to_world(front, u, v)` | front: `{ ox, oy, ax, ay }` (side a's home-edge left corner, push axis); u, v | x, y in map yards |
| `Front.borders(objectives, width)` | objectives: list of `{ name, x, y, holder, neighbours }`; width: yards | list of borders `{ from, to, mx, my, ax, ay, width, length }`, one per neighbouring pair not held by the same side; an unknown neighbour is an error |
| `Front.new_deck(n, r)` | n: branches at a fork; r: from `Front.rand` | a deck `{ n, order, next }` |
| `Front.deal(deck, r)` | a deck | the next branch (1..n); two branches flip like a switch, three or more are a shuffled deck dealt without replacement |
| `Front.section_of(o, u)` | o: tuning; u | section number 1..`sections` |
| `Front.pick_section(o, counts, u)` | counts: allies per section | the section with the fewest, a tie to the nearest |
| `Front.help_moves(o, counts)` | counts: allies per section | moves `{ from, to }` (2 per needy section served), and how many sections were needy |
| `Front.shelter_spot(o, fu, fv, mu, mv)` | foe's and melee ally's positions | u, v where a struck ranged bot stands: behind the ally on the foe's line, inside its casting reach |
| `Front.new_match(opts)` | opts: overrides of `Front.DEFAULTS`, plus `per_side`, `ranged_share`, `seed` | a match `{ o, r, bots, tick, stats }` |
| `Front.road_path(m, bot)` | a match and one bot | the bot's path to the front: three points, its two forks dealt from its own decks |
| `Front.tick(m)` | a match | advances half a second: graveyard wave, each bot moves or fights, the fallen counted, help sent |
| `Front.counts(m, side)` | side: "a" or "b" | allies on the line per section (the living only) |
| `Front.line_positions(m)` | a match | each side's line: the average v of its bots on the line (nil with none) |

## Structures

- **Tuning** (`Front.DEFAULTS`, copied into `m.o`): numbers only. Times
  are in ticks of half a second, distances in yards. `help_order` is the
  one text setting: `"worst last"` or `"worst first"` (629 question 2);
  anything else is an error.
- **Bot**: `id` integer; `side` "a"/"b"; `role` "melee"/"ranged"; `u`, `v`
  numbers; `hp` number; `state` one of "dead", "roads", "line",
  "through" (broke through and healing); `section` integer or nil; `path`
  list of `{u, v}`; `at` integer (next path point); `decks` table fork
  number → deck; `join_yards` number (3-6 strides); `facing` radians;
  `struck_by` the bot that hit it last tick, or nil; `broke` boolean.
- **Stats** (`m.stats`): `kills = { a, b }`; `moves` (help moves made);
  `crowded_needs` (times two or more sections were short at once, the
  only times `help_order` changes anything); `shelters`; `backsteps`;
  `breakthroughs`; `joins`; `deals`.

## What the matches have shown (run the tools for today's numbers)

- With each bot keeping its own place across its section, a line of 20 a
  side is so even that two sections are almost never short at once, so
  the two help orders play out the same; at 40 a side (Alterac Valley's
  size) they start to differ. `scripts/test-battleground-front` prints
  the counts.
- Breakthroughs have not happened in any match so far: the lines are
  too even for a bot to get past every foe.
- Backsteps are frequent; "need is great" (629d question 1) is the knob.
