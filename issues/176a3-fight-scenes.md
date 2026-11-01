# 176a3 - Fight Scenes: the Forward Pass Against the Bot Module's Way

## Status
- Created: 2026-10-31
- Phase: 1 (the build and its tests)
- Parent: 176a (test scenes)
- Related: 625n (the fight's forward pass, what these test), 632 (buddies
  wait for a rez: the release rule the fallen hold by), 617t (stand-ins,
  who fight here), 617e17 (the army: how stand-ins are brought)
- Priority: High
- State: in progress (written and compiler-checked; waiting for the
  owner's compile; not yet run)

## Origin

The owner, 2026-10-31, word for word:

> let's build a test scene in the cc-test profile. I think that's the
> right place... anyway it should just be two bots fighting a monster. The
> monster should be level 45 and the bots should be level 40. Then, have
> one of the bots use the playerbots style combat style, and have the
> other do the new system.
>
> after that, build a second test that is more focused on party
> mechanics. Make one boss monster level 65 and 3 buddy-bots at level 60.
> They should fight the boss monster, and if any of them are slain then
> they wait until either the boss dies, or the entire party dies. When the
> fight ends, they are all reset and it runs again, but any randomization
> we apply can be re-applied.
>
> then, we should make another test scene that's the same, except at
> level 30 and 35 instead of 60 and 65. This is to test what happens with
> fewer abilities.
>
> we can also do one at 15 and 20, for the earliest dungeon experience.

## Current Behavior

**Written 2026-10-31, compiler-checked for cc-test, waiting for the
owner's compile:** `buddies_scenes.cpp` in the buddy module, with three
small hooks elsewhere: the release rule asks `BuddySceneHolds` first
(`buddies_release.cpp`), the forward pass asks `BuddySceneForwardPass`
whom it plays for and `BuddySceneIsBoss` whether the monster is a boss
(`buddies_forward_pass.cpp`), and the loader registers it.

- `.buddy scene <duel|party60|party30|party15> [redraw]` starts a scene
  where the game master stands; `.buddy scene` says how it stands;
  `.buddy scene stop` ends it.
- **duel**: two damage stand-ins of one class at 40 against a level-45
  monster; the first fights the bot module's way, the second with the
  forward pass. **party60/30/15**: a tank, a healer and a damage stand-in
  at 60, 30 or 15 against an elite of 65, 35 or 20, counted as a boss by
  the forward pass, all three with it.
- **The monster** is the lowest-entry plain humanoid warrior of exactly
  the scene's level and rank in the world's own creatures (no script,
  attackable), summoned 12 yards ahead and made hostile to everyone, so
  every round meets the same one.
- **A round**: the stand-ins brought (kept ones reused, as the army does),
  in one party, raised if dead, full health and power, cooldowns cleared,
  out of combat, placed round the start at a random angle each, set to
  stay; a fresh monster attacks with every stand-in on its threat list.
  The fallen lie where they fell until the monster dies, the whole party
  falls, or 10 minutes pass. Then a line per stand-in is written to
  `LogsDir/buddies-scenes/<scene>.tsv` (round, seconds, how it ended, name,
  class, forward pass or not, damage dealt and taken, healing done, fell,
  the monster's health left) and a summary told to the game master; after
  5 seconds the next round begins.
- **Randomness drawn again each round** (the agent's reading of "any
  randomization we apply can be re-applied"): the start angles always;
  with `redraw`, the stand-ins themselves (new classes in the same roles,
  the duel's two again of one class).
- `Buddies.ForwardPass` must be 1 for the forward pass to play at all; the
  command says so when it isn't. The forward pass now plays for stand-ins
  as well as buddies (a scene's say first).

Not yet: run in game; a tool that reads the records and compares the two
ways round by round.

## Intended Behavior

As the owner's words above: the same fights, again and again, written
down, so the forward pass can be judged against the bot module's way, in
a party and alone, at four levels of abilities.

## Suggested Implementation Steps

1. (Done) The scenes, their command and the hooks.
2. In game on cc-test: each scene for a few rounds; read the records.
3. A tool reading `buddies-scenes/*.tsv`: per scene and way, rounds won,
   seconds to win, damage dealt and taken, falls.

## Open Questions

1. "Any randomization we apply can be re-applied": is drawing the start
   places again each round (always) and the stand-ins themselves (with
   `redraw`) what you meant, or should something else be drawn again (the
   stand-ins' talents and gear, the monster)?
