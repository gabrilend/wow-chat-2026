# 176a3 - Fight Scenes: the Forward Pass Against the Bot Module's Way

## Status
- Created: 2026-10-31
- Phase: 1 (the build and its tests)
- Parent: 176a (test scenes)
- Related: 625n (the fight's forward pass, what these test), 632 (buddies
  wait for a rez: the release rule the fallen hold by), 617t (stand-ins,
  who fight here), 617e17 (the army: how stand-ins are brought)
- Priority: High
- State: in progress (the scenes and their frames written and
  compiler-checked for cc-test and basic, waiting for the owner's compile;
  the frames checker committed; not yet run; the charts not started)

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

Then, the same day, word for word:

> we don't need the in-game summary. Also, we're less interested in the
> result of the fight, and more on the system that creates it - can we
> create comprehensive logging that shows at each "frame" the exact status
> of the combatants? We will then use these logs to create a mesh of
> curves, one chart for each combatant, that show their dynamism.

> I mean, ability choices and such. We're trying to attach
> non-linearities to their combat mechanics, and if it played out the
> same way everytime, then we aren't building it correctly.

> I don't need to see the scenes. I want to see the curves we create, and
> possibly a live viewer for them in-game through an addon or something,
> but that can come later. For now, we just need the data.

## Current Behavior

**Written 2026-10-31, compiler-checked for cc-test, waiting for the
owner's compile:** `buddies_scenes.cpp` in the buddy module, with small
hooks elsewhere: the release rule asks `BuddySceneHolds` first
(`buddies_release.cpp`); the forward pass asks `BuddySceneForwardPass`
whom it plays for and `BuddySceneIsBoss` whether the monster is a boss,
and gives each frame its view of a combatant (`BuddyForwardPassFrame`,
`buddies_forward_pass.cpp`); the loader registers it.

- `.buddy scene <duel|party60|party30|party15> [redraw]` starts a scene
  where the game master stands; `.buddy scene` says how it stands and
  where its files are; `.buddy scene stop` ends it.
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
  falls, or 10 minutes pass; after 5 seconds the next round begins.
- **The frames** (the owner's "at each frame the exact status of the
  combatants"): every half second of a fight, one line per combatant (each
  stand-in in seat order, then the monster) appended to
  `LogsDir/buddies-scenes/<scene>-frames.tsv` (on cc-test,
  `logs-cc-test/buddies-scenes/`), flushed each frame so it can be read
  while the scene runs. Its columns, named in the file's header line under
  a "# made by" line:
  - the frame: the server's clock, round, frame number, seconds into the
    round;
  - who: name, stand-in or monster, seat, class, role, forward pass or not;
  - its state: alive, in combat, health and maximum, power kind, power and
    maximum, position and facing, moving, yards to the monster (the
    monster: to whom it attacks), whom it has selected and whom it swings
    at, the spell it is casting or channelling and the milliseconds left,
    every aura on it (spell, name, stacks, seconds left, who cast it,
    helpful or harmful), the monster's threat on it;
  - running totals this round: damage dealt and taken, healing done;
  - its choices: the spells it cast since the last frame and on whom
    (triggered casts, such as procs, left out);
  - the forward pass's view (`fp-` columns, "-" when it has none): how old
    its last step is, trash or boss, the fight's time left, the party's
    shortfall, this member's incoming damage and healing a second, time to
    death, health short of the fight's end, its healer seat (holder, dry),
    whether the seats are short, the tank's room for one more enemy, every
    answer's lean away from 1, and the buffs it hands out and to whom.
- **The rounds**: one line per stand-in per round in
  `LogsDir/buddies-scenes/<scene>.tsv` (how it ended, the damage dealt
  and taken, healing, fell, the monster's health left). Nothing is told in
  game; the game master hears only troubles (a stand-in not brought, no
  monster).
- **Checking the files**: `scripts/check-scene-frames [FILE...]` (Lua)
  reads them: every line as wide as the header, and per combatant its
  rounds, frames, lowest health, falls, casts a round, and how many
  different orders of casts across the rounds; a stand-in that cast the
  same spells in the same order every round is pointed out (the owner: "if
  it played out the same way everytime, then we aren't building it
  correctly"). Its quick test, `scripts/test-scene-frames` (8 checks), runs
  it on made-up files.
- **Randomness drawn again each round** (the agent's reading of "any
  randomization we apply can be re-applied", and the owner's "ability
  choices and such"): the start angles always; with `redraw`, the
  stand-ins themselves (new classes in the same roles, the duel's two
  again of one class); the choices themselves, through the forward pass's
  leans drawn through the talent draw's random factor (625n, 625).
- `Buddies.ForwardPass` must be 1 for the forward pass to play at all; the
  command says so when it isn't. The forward pass plays for stand-ins as
  well as buddies (a scene's say first).

Not yet: run in game; the charts (one per combatant, from the frames; a
viewer page first, an in-game viewer later, the owner: "that can come
later. For now, we just need the data").

## Intended Behavior

As the owner's words above: the same fights, again and again, each
combatant's state written down every frame, so the system that makes the
fights (the forward pass's curves, the choices they lean) can be seen as
one chart per combatant, in a party and alone, at four levels of
abilities, beside the bot module's way. Data first; the charts and a
live viewer come after.

## Suggested Implementation Steps

1. (Done) The scenes, their command and the hooks.
2. (Done) The frames, and `scripts/check-scene-frames` with its test.
3. In game on cc-test: each scene for a few rounds; check the frames.
4. The charts: a page drawing one chart per combatant from a frames file
   (health, power, threat, time to death, leans over time), kept apart
   from the writing (data made in one place, viewed in another).
5. Later: a live viewer in game (an addon reading what the server sends).

## Open Questions

1. "Any randomization we apply can be re-applied": is drawing the start
   places again each round (always) and the stand-ins themselves (with
   `redraw`) what you meant, or should something else be drawn again (the
   stand-ins' talents and gear, the monster)?
   **Answered 2026-10-31:** "I mean, ability choices and such. We're trying
   to attach non-linearities to their combat mechanics, and if it played
   out the same way everytime, then we aren't building it correctly." The
   choices are drawn (the forward pass's leans through the talent draw's
   random factor), and the frames checker points out a stand-in whose
   rounds all cast alike.
