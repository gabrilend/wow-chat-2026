# 173w - Queued Inputs and Test Characters

*Continues in the W client (`/mnt/mtwo/games/azeroth-core/custom-client/`), since the move on 2026-10-07 (173v): issue 109. This issue stays as the record of how the client began; its paths are as they were then.*

## Status
- Created: 2026-10-07
- Phase: 1
- Parent: 173 (the custom client)
- Related: 173b3 (key bindings: the action names a script would use),
  173e (what the server checks), 176 (the cc-test server profile, to log
  test characters into), 173v (the move to its own project: this goes
  with it), 173i and 173q (what the first scripts would test: moving,
  walls)
- Part of: 176a (test scenes): the queued inputs and test characters
  are how a scene's characters are driven. The concepts and the open
  questions are kept there; this issue is the client's half of the work.
- Priority: Medium

## Origin

The owner, 2026-10-07, after seeing her stand still against a wall:

> also, we should maybe create a plan to have a series of "queue'd
> inputs" that can be provided to a character when testing? Then, we can
> create several "test characters" at once, and unless we're testing
> rendering, we should be fine to test multiple things at once, if they
> output logs correctly.

## Current Behavior

Tests of the client's behaviour come in two kinds, neither of which
plays a sequence of inputs:
- **The test program** (`tests/test_client.c`, `build-custom-client
  --test`) calls each part directly with made-up input: the mover gets
  "forward held" for so many steps on a made-up ground. Fast, no window,
  but it never runs the client's own frame loop.
- **Pictures** (`--shot`) run the real loop with a window, steered by a
  fixed set of options, each a hard-wired part of the loop: `--walk S`
  holds forward, `--dive S` then holds X, `--wait S` waits, `--goto X Y`
  moves her once at one second, `--walking` starts walking, `--pose`
  holds an animation. Each new thing to try needs a new option in
  `main.c`. Only one character, and only one picture at the end, after a
  fixed 3 seconds of settling. The run report is printed text, not a log
  a test can read line by line.

Running into a wall showed the gap (2026-10-07): a picture can't be
taken mid-run, so "she runs on the spot against a wall" could only be
checked by a unit test of the speed, not by watching the loop do it.

## Intended Behavior

**A queue of inputs per character.** A short text file lists, in time
order, what is pressed, released or done, each line at a moment of
world-time:

```
0.0   press   MOVEFORWARD
2.5   press   JUMP
2.6   release JUMP
4.0   release MOVEFORWARD
4.0   picture ran-into-the-wall.png
5.0   log
```

The actions are the original's action names (173b3's table), so a
script reads like the key-bindings list, and works the same once keys
can be rebound. The client's own frame loop plays the queue at a fixed
step (20 frames a world-second, as pictures do now), so a run is the
same every time.

**The picture options become queues.** `--walk`, `--dive`, `--wait`,
`--goto`, `--walking` each turn into a few queue lines; the loop has one
way to be steered instead of one branch per option.

**Logs a test can read.** Each character writes one line per logged
moment to `tmp/shared-memory/custom-client-tests/<character>.log`: the
world-time, position, facing, on the ground or swimming or falling, the
animation playing and how far into it, and what is held. A test is then
the queue plus checks on the log ("by 4.0 her x stopped growing; her
animation was still the run").

**Several test characters at once.** When nothing is being drawn, a run
needs only the world's shape (ground, walls, water) and each character's
mover and animation choice, all of which already work without a window
(the test program uses them). So a headless run loads the world once and
moves many characters through it, each with its own queue and log. When
rendering is the thing tested, one character, with a window, as now.

**Later, against a server.** With networking (173e) and the cc-test
profile (176), the same queues could drive several real logged-in test
characters, one client process each, and the server's view of them
compared with the client's logs.

## Suggested Implementation Steps

1. The queue reader: the file's lines into (time, verb, action, values),
   refused line by line with the line number and why, as the settings
   file is (173b1). A test of it.
2. The frame loop takes its held actions from the queue (when given one)
   instead of the keys; the picture options rewritten as queue lines,
   with the reference pictures compared before and after.
3. The log: one line per `log` verb (and, optionally, every frame), in
   the RAM tier.
4. A headless mode: no window, the world's shape loaded (ground, the
   doodads' and buildings' solid shapes, water), many characters each
   with its queue and log. A test running two at once: one into a wall,
   one walking across a slope, checked from their logs.
5. The first real checks as queues: running into a wall plays the run
   at its pace; walking toggled halves the stride; a jump's start, loop
   and landing in order.
6. With 173e and 176: the same queues driving logged-in test characters.

## Open Questions

Kept with the rest of the test-scene questions in 176a (owner,
2026-10-07: "We can come back to it later, when we implement the new
test-patch system for the cc-test profile"). As first asked here:

1. **The queue's format:** plain lines as above (simple to read in C,
   like the settings file), or a Lua file (the house language, and
   queues could then loop or compute)?
2. **Several characters:** in one headless process sharing one loaded
   world (cheap, many at once, but not a real client each), or one
   client process per character (closer to the real thing, needs the
   network for them to matter to each other), or both, in that order?
3. **In one headless run, do the test characters meet?** Should they
   collide with and see each other (testing crowds), or each act as if
   alone (testing many unrelated things at once, as the message
   suggests)?
4. **The picture options:** once they are queues, keep `--walk` and the
   others as shorthands, or replace them with `--queue FILE` only?
