# lib/boss-spell-schedule.lua

Which spells a boss's fight script casts, on whom and how often, read
from the script's C++ source without running it (issue 155f1). Returns
its table: `local Sched = dofile(".../boss-spell-schedule.lua")`.

| Function | Takes | Gives |
|---|---|---|
| `Sched.find_file(dir, name)` | dir: the scripts folder (text); name: a creature's script name (text) | the source file that defines it (text), or nil; every `.cpp` under dir is read into memory on the first call |
| `Sched.read(path, name)` | path: that file (text); name: the script name, to read only its own block (text) | `{ casts, notes }`: casts a list of `{ spell, target, first, every, late }` (spell number; target "tank", "area", "random", "self" or "other"; first and every in seconds, every nil for a single cast; late true when it only starts below some health); notes a list of texts saying what could not be read |

Reads the scheduler style (`Schedule(t, [..](TaskContext c) { DoCast...; c.Repeat(t2); })`)
and the events style (`events.ScheduleEvent(EVENT_X, t)` with
`case EVENT_X: ... events.Repeat(t2); break;`). Times: `10s`, `9100ms`,
`2min`, `randtime(a, b)` (the middle), two times (the middle), bare
numbers as milliseconds; heroic choices take the normal mode's. Timers
kept in variables, phases and spells chosen at run time are not read and
are said in the notes.

Used by `scripts/tank-damage-taken`.
