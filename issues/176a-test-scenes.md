# 176a - Test Scenes

## Status
- Created: 2026-10-07
- Phase: 1
- Parent: 176 (the cc-test profile)
- Blocked by: 176 (the profile must exist to install scenes into)
- Related: 173w (queued inputs and test characters: the client's half),
  173v (the client's move to its own project), 173e (what the server
  checks), 127 (patch system improvements), 173b3 (the action names
  queues use)
- Priority: Medium (to come back to when the cc-test profile is built)

## Origin

The owner, 2026-10-07, on 176's patching question:

> I'm thinking we could add a patch that runs a test by setting up a
> particular scene. Each one could be in a different location so they
> don't interfere, and then with a cc-test build they could all be tested
> at once, to catch regressions.

On reading the results:

> each character would create log files, as specified in the "test
> patch". These are saved to RAM and evaluated by a traditional testing
> suite, to ensure that they produce correct results. Any discrepancies
> can be picked up by an LLM agent and evaluated, to see if some unrelated
> change is causing them, if that result is desired, and if so, to update
> the test to expect the newly provided result.

On pictures:

> we should be able to "headlessly" generate pictures of scenes, so we
> can create hundreds of these pictures at once for testing purposes.

And the same day, after the custom client's character stood still against
a wall:

> also, we should maybe create a plan to have a series of "queue'd
> inputs" that can be provided to a character when testing? Then, we can
> create several "test characters" at once, and unless we're testing
> rendering, we should be fine to test multiple things at once, if they
> output logs correctly.

> can you write the queued inputs and test characters concepts ideas and
> questions into an issue file for me? We can come back to it later, when
> we implement the new test-patch system for the cc-test profile

## Current Behavior

Not built. Patches only change things: source patches (`patches/B*.sh`),
install setup (`patches/E-patches.sh`) and config values
(`config/patches/C*.sh`), gated per profile. None sets up a situation to
test, and nothing reads a result back.

The custom client is tested two ways, neither playing a sequence of
inputs (173w has the detail): a test program calling its parts directly,
and pictures steered by one-off options (`--walk`, `--dive`, `--goto`,
`--walking` ...), one character, one picture after a fixed settling time.

## Intended Behavior

**A test patch is a scene.** It sets up one situation in a place of its
own, so scenes don't interfere: the creatures and objects there, the
test characters and where they start, what each character does (its
queue of inputs), what each writes down (its log), and what the result
should be. A cc-test build installs every scene; one run plays them all
and catches regressions. Each patch says at its top what it tests, the
way every patch says what it changes.

**Queued inputs.** Each test character gets a queue: a short list of
moments of world-time and what happens at each (an action pressed or
released, a picture taken, a log line written):

```
0.0   press   MOVEFORWARD
2.5   press   JUMP
2.6   release JUMP
4.0   release MOVEFORWARD
4.0   picture ran-into-the-wall.png
5.0   log
```

The actions are the original game's action names (173b3's table), so a
queue reads like the key-bindings list. The queue is played at a fixed
step (20 frames a world-second, as the client's pictures are now), so a
run is the same every time. The client's picture options become queues
(173w).

**Logs.** Each character writes its lines to RAM
(`tmp/shared-memory/test-scenes/<scene>/<character>.log`): world-time,
position, facing, on the ground or swimming or falling, the animation
playing and how far in, what is held. The scene names which of these it
wants and when.

**Checking.** Ordinary test code compares each log with what the scene
expects. A difference goes to an agent, which judges whether an
unrelated change caused it and whether the new result is wanted; if it
is wanted, the agent updates what the test expects (and says so).

**Many test characters at once.** When nothing is drawn, a character
needs only the world's shape (ground, walls, water), its mover and its
animation choice, all of which already work without a window. So many
can run in one go, each with its own queue and log, testing unrelated
things side by side.

**Pictures without a window.** A scene can ask for pictures; the client
draws them off-screen, so hundreds can be taken in one run and compared
with stored references (the client's half, after its move: 173v).

## Suggested Implementation Steps

1. Decide the open questions below.
2. The scene format and where scenes live (one patch file each, gated
   to cc-test), with the scene's place, its setup, its characters'
   queues, their logs, and the expected results.
3. The client's half (173w): the queue reader, the frame loop played
   from a queue, the log, the headless mode with many characters.
4. The server's half: a scene's setup installed by the cc-test build
   (creatures, objects, the test accounts and characters at their
   starting spots).
5. The runner: one command builds cc-test, plays every scene, and
   compares every log with its expected results, listing differences
   for an agent to judge.
6. The first scenes: running into a wall (the run keeps playing); walking
   toggled (the stride halves); a jump's start, loop and landing in
   order; swimming down and up.
7. Headless pictures of scenes, compared with stored references.

## Open Questions

1. **The queue's format:** plain lines as above (simple to read in C,
   like the settings file), or a Lua file (the house language, and
   queues could then loop or compute)?
2. **Who plays a scene's characters:** the custom client, logged into
   the cc-test server (one client process per character, needs the
   network), or the client headless with no server (one process, many
   characters sharing one loaded world, no network needed), or both, in
   that order?
3. **Do test characters in one run meet?** Collide with and see each
   other (testing crowds), or each act as if alone (testing many
   unrelated things at once)?
4. **Who writes the log:** the client (what the player saw), the server
   (mod-ale, what the server believes), or both, compared with each
   other (which would also test 173e's "the server agrees")?
5. **Placing scenes apart:** a fixed list of places, one per scene, or
   each scene choosing its own and the runner checking none overlap?
6. **The client's picture options** once queues exist: keep `--walk` and
   the others as shortcuts, or replace them with `--queue FILE` only?
