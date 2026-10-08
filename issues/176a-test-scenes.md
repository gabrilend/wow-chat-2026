# 176a - Test Scenes

## Status
- Created: 2026-10-07
- Phase: 1
- Parent: 176 (the cc-test profile)
- Blocked by: 176 (the profile must exist to install scenes into)
- Sub-issues: 176a1 (a full Alterac Valley match)
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

**Each scene has its own run script.** The owner, 2026-10-08: "They
should call the custom client when their each individual run script is
run, from the scripts/connect-parameters.json directory." Running a
scene's script starts the custom client, which connects to the server
its own `scripts/connect-parameters.json` names, and plays that one
scene.

**Test patches are also the world, and they are shared.** The owner,
2026-10-08: "you can connect to my server, which is running all of the
test patches that we're building into the world functionality for the
newly created project that is... my server, wow-chat-2026, but which
will be shared so anyone can run those test patches if they want. or run
some of them and replace others with others, their own design
perhaps..." A scene is both a test and a piece of the playable world.
The owner's server runs all of them. Anyone else can run the same set,
choose some and leave others out, or put their own scenes in place of
ours. So each scene must stand on its own: installed or left out by
itself, with nothing else breaking.

**A test patch, and later a cc-patch.** Asked whether one scene can be
both a repeatable test and a live world, the owner, 2026-10-08: "ya the
test-patches might later be converted nearly identically to cc-patches,
which are patches designed for the custom-client's specific test server
that could be implemented on other servers idempotently." So a scene
takes two forms, built from nearly the same file:
- **The test patch:** a sealed copy, started the same way every run with
  no one let in, so its logs can be compared with what is expected.
- **The cc-patch:** the same scene as part of the playable world, open to
  players. It is written so it can be applied to any other server too,
  and applying it a second time changes nothing (idempotent, as every
  patch in this project's patch system already is).
A tool makes each cc-patch from its test patch (owner, 2026-10-08:
"built by tool, tool bugfixes by hand."): the cc-patches are never
written by hand; a mistake in one is fixed in the tool, by hand, and the
cc-patch made again.

**The client chooses its server.** The connection settings
(`scripts/connect-parameters.json`) belong to the client, as the
original's `realmlist.wtf` does (owner, 2026-10-08: "Let the client
determine who they connect to. Suddenly, freedom everywhere.").

**Alone first, then all together.** The owner, 2026-10-08: "we should
always run each test individually, validate that it performed correctly,
then run the next. Then, at the end, we run them all at once." The runner
plays each scene by itself and checks it before starting the next; the
run of every scene at once comes last, and passes only if each scene
passed alone.

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
5. The runner: one command builds cc-test, plays each scene alone
   through its own run script and checks it, then plays every scene at
   once and checks them all, listing differences for an agent to judge.
6. The first scene: a full Alterac Valley match (176a1). Then: running into a wall (the run keeps playing); walking
   toggled (the stride halves); a jump's start, loop and landing in
   order; swimming down and up.
7. Headless pictures of scenes, compared with stored references.

## Sub-issues

- 176a1 - a full Alterac Valley match: 40 stand-ins a side, players
  added on top, their pathfinding checked first.

## Open Questions

1. (Answered 2026-10-08) **The queue's format:** "lua file with
   coroutines encouraged." A queue is a Lua file. A character's actions
   are written as a coroutine: it presses, waits, checks, and goes on,
   so a queue can loop and compute, not only list moments. The plain
   lines shown above are the idea, not the format.
2. (Answered 2026-10-08) **Who plays a scene's characters:** "the
   server does when it's public. if you're doing the pure singleplayer
   version it doesn't need to connect to the internet at all, so it
   doesn't even load those modules. They can even be deleted if the user
   wants. however it also loads some slight single-player modification
   patches, but that's for a future phase don't worry about it for now."
   On a public server the server plays the scene's characters. The pure
   single-player version never touches the network: the modules for it
   are not loaded, and a player may delete them. Its single-player
   patches belong to a later phase.
3. (Answered 2026-10-08) **Do test characters in one run meet?** "um.
   yes?" They see each other and collide, and they move around each
   other in a fight (the owner, 2026-10-08):

   > also they give each other space in combat and make darts forward
   > when critting and dodges make them jump back. Parry usually moves
   > them to the side and when they interrupt or are interrupted they'll
   > move a little bit to apply repositioning (to a more tactical
   > advantage in relation to the other characters around them and the
   > environment they're at.) Also if they're in danger they'll fall
   > back, but they try to do so as a pack, losing ground as steadily as
   > possible while keeping their area clear of foes.

   Combat footwork, for stand-ins and buddies alike:
   - keep space from each other while fighting;
   - a critical hit: a dart forward;
   - a dodge: a jump back;
   - a parry: a step to the side;
   - interrupting or being interrupted: a short move to a better spot,
     judged against the characters around them and the ground;
   - in danger: fall back together as a pack, giving ground as steadily
     as they can while keeping their own area clear of enemies.
   The footwork has its own plan: 619 (combat footwork), a patch to
   the playerbots module.
4. (Answered 2026-10-08) **Who writes the log:** both, compared line by
   line, "for the debug step, during the validation process of the
   compilation phase." Comparing the client's log with the server's is
   part of the build's checking step, while debugging; an ordinary run
   keeps one log.
5. **Placing scenes apart:** asked again 2026-10-08 (the first wording
   was unclear). The owner's answer described how the Alterac Valley
   scene keeps its own players apart in time and space (barred gates,
   a held line, an invisible wall; 176a1). Alterac Valley is also an
   instance, its own copy of the map, so no scene outside it can share
   its ground. Still open for scenes in the open world. Each scene needs its own patch of ground, so that, for
   example, a stand-in walking out of the Alterac Valley cave doesn't
   walk into another scene's creatures. Who picks where a scene goes:
   one list of places, written by us, with a scene given one of them; or
   each scene names its own place, and the runner stops if two scenes'
   places overlap?
6. (Answered 2026-10-08) **The client's picture options:** "depends on
   if they're implemented performantly, but in general we should have
   movement pathfinding co-routines for things like 'orbit your foe by N
   percent' or 'turn while walking that way' or 'jump onto this
   calculated-as-doable-for-you ledge.' etc. Then we can use them in the
   mechanisms we use to pilot the buddy-bots and stand-ins." Whether the
   one-off options stay depends on whether they run fast enough as
   queues. Above them sits a library of movement coroutines (orbit a
   foe by a share of a circle, turn while walking, jump onto a ledge
   worked out as reachable for this character), which queues use, and
   which also steer buddies and stand-ins.
