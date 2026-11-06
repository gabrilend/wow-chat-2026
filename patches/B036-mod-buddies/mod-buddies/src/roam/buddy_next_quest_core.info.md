# buddy_next_quest_core.h

The next best quest for an owner, and the buddies leaning toward it (issue
617e18): "the buddy-bots should stand on their arc in the direction of the
next best quest to work on". Plain arithmetic over plain tables (the
quests, their givers, enders and objective spots, the owner's log, done
quests and explored places), no server; checked by
`scripts/test-buddy-next-quest`. Not yet wired into the server: reading
the world and character tables, choosing again when the log changes or
the owner moves far, the switch, and `.buddy next` are the server's part,
still to build.

## Pieces

| Name | What it is |
|---|---|
| `Settings` | `grayBelow` 6, `yardsPerLevel` 60, `togetherRadius` 60, `togetherYards` 40, `chainYards` 100, `beckonYards` 5 |
| `Quest` | `id`, `name`, `level`, `minLevel`, `prev` (0: none), `giver`, `ender`, `objectives`: the world database's facts, positions on one map |
| `LogEntry`, `Owner` | the owner's `level`, `at`, `done` quests, and `log` (each quest's objective spots `left`; none left: waits to be handed in) |
| `Place` | `name`, `at`, `explored`: the explored areas the server keeps per character |
| `Hint` | `kind` (None, Log, HandIn, Take, Explore), `quest`, `place`, `target`, `cost`, `bearing` (radians, owner to target) |
| `Choose(o, quests, places, s)` | -> Hint: the next best thing to do |
| `LeanPlaces(owner, bearing, n, fs)` | -> the arc follow's places (617e13), on the owner's side facing the target |
| `Beckon(owner, target, s)` | -> the spot one buddy steps to while the owner stands still |
| `Compass(bearing)`, `Words(h, o, quests, places)` | the hint in words, only when a buddy is whispered "where next?" |

## The choice, as `Choose` makes it

| Tier | Target | Passed over |
|---|---|---|
| 1. quests in the log | the nearest objective left; none left: the ender (HandIn) | gray quests, quests the tables don't know |
| 2. quests to take | the giver | done, in the log, the quest before not done, under `minLevel`, gray |
| 3. time to move on | the nearest place not explored | explored places |
| 4. nothing | no hint | |

Within a tier the lowest cost wins: yards walked to the target, plus
`yardsPerLevel` for each level off the owner's, less `togetherYards` for
each other objective or giver (of quests in the log or to take, not gray)
within `togetherRadius` of the target, less `chainYards` when the quest
has a quest before it. Gray: `grayBelow` or more levels under the owner.
