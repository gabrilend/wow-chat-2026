# 620h - Bot Rules Test Scene

## Status
- Created: 2026-10-14
- Phase: 6
- Parent: 620
- Blocked by: 620b, 620c, 620d, 620e, 620f, 620g
- Related: 176 (cc-test profile), 176a (test scenes), 617t2 (the Ragefire
  stand-in scene, a scene with bots in it)
- Priority: Low until its blockers are built; then it is 620's proof

## Origin

Written with 620 (owner, 2026-10-14). Each of 620's pieces is tried by
hand in its own issue; this gathers them into one run that can be repeated
after every bot module update.

## Current Behavior

No scene places an alt bot or a random bot. The cc-test profile (176)
runs stock rules with the buddy module and no random bots; the scene
system (176a) can place characters and script them. Basic itself cannot
run scenes.

## Intended Behavior

One scripted run, with no person at the keyboard, that:

1. Logs in a human test character and adds one of its other characters as
   an alt bot; places two random bots nearby.
2. Asks the kind of each character (620a) and checks all five answers.
3. Levels the alt bot to 10: one wandering Sargobras appears behind it,
   the bot asks him and chooses, its clan is founded, its buddy arrives
   (620b, 620c).
4. Has a random bot invite a buddy, offer it a trade, and challenge it to
   a duel: all refused quietly (620d).
5. Sends the alt bot to train at a Visiting Mentor (620e).
6. Runs the bot module's gear and maintenance shortcuts on the alt bot and
   checks the result against basic's rules (620f).
7. Writes a receipt: each step, passed or failed, with what it saw.

The run's last act is the receipt in `output/goodbye` (house rule), with
the counts of steps run and passed, and the screenshots it takes filed
under `development-history/`.

## Suggested Implementation Steps

1. Decide where it runs (see open question) and add a scene file in the
   176a format.
2. Each step reads the server's state by GM command or database query,
   never by trusting what the bot says.
3. A run script, and its receipt read back by a test in the build's test
   list.

## Open Questions

- **Basic or cc-test?** Most of what is tested is basic's rules (620f,
  620g), which cc-test does not have; but scenes run on cc-test. Should
  cc-test gain a "basic rules" switch for this scene, or should basic gain
  the scene runner?
