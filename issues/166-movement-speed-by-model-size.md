# 166 - Movement Speed by Model Size

## Status
- Created: 2026-10-04
- Phase: 1
- Priority: Medium
- Related: 155 (basic profile; recorded the 80% run-speed decision), 155b
  (profile config gates; fixed the run-speed key)
- Related files: `config/patches/C003-run-speed-80-percent.sh`,
  `scripts/generate-basic-race-class-data` (already reads ChrRaces.dbc),
  `data-files/dbc/{ChrRaces,CreatureDisplayInfo,CreatureModelData}.dbc`

## Origin

Verbatim, 2026-10-04:

> oh hey we should change the movement speed of different models depending
> on their model size, not some arbitrary number. The current config value
> (80% speed I think) is ideal for Blood Elf F
>
> Tauren, being the largest, should move the fastest and farthest.
>
> *plainsstriding*

Follow-up decisions, verbatim, 2026-10-04:

> the height factors won't be accurate because we need to assess their
> gait, which relies mostly on their hips and shoulders. However, a crude
> scaling is alright for now, until we can implement the full version in a
> cleanup pass.

> more auras is more things to keep track of always. We gotta build a
> server patch to add a short dispatch table that is placed between input
> and movement that routes the function arguments to the right call site.
> Then, we can have one walking method or function for each race and
> gender, with hard-coded at compile time "default" movement speeds.

> walking speed should scale with leg length and torso posture positioning

## Current Behavior

Not built yet. Every player character runs at one speed. The config-value step
`C003-run-speed-80-percent.sh` writes the worldserver setting for player
move speed (`Rate.MoveSpeed.Player`, a number) as 0.85 (0.8 until 2026-10-12), on every profile but cc-test.
Gnome and tauren cover the same ground per second.

## Intended Behavior

A character's run speed follows its body. The female blood elf stays at
today's 0.85 (0.8 until 2026-10-12: "can we increase the movement speed
for blood elf females to 0.85 instead of 0.8?"; until this issue is built
everyone runs at it, "0.85 for everyone, let's see how it feels"), as the
reference body. Larger bodies run faster (tauren
fastest), and smaller ones run slower.

**Where the speed is decided (the metal).** The server does not move a
player's body step by step: the game client does, at the speed the server
last told it. The server recalculates that speed from scratch whenever a
speed effect changes (mounting, sprinting, a slow, entering water), by
multiplying a base rate by the active speed effects, then sends the result
to the client. That recalculation is the "between input and movement"
point: every change of speed passes through it, and nothing else decides
how fast a body moves. A speed set from Lua would be overwritten by the
next recalculation, and a hidden speed aura per race is one more thing to
track forever (owner, 2026-10-04: "more auras is more things to keep track
of always"); neither is used.

**The dispatch table (source patch).** A B-patch puts a short table into
that recalculation, indexed by race and sex (two small integers make one
index; no if-else chain). Each entry routes to that body's walking
function, which receives the same arguments the recalculation has (the
kind of movement: walk, run, swim, flight; the rate computed so far, a
number) and returns the rate for this body. Each function starts with a
compile-time default speed factor for its race and sex. Bots are players
too, so playerbots move by the same table. Creatures are not routed (they
have their own per-creature speeds).

**Mounted, the mount's body counts.** Owner, 2026-10-04: "mounts scale
with the size of the mount." A mounted player moves by the mount's
walking function, not their own: the dispatch table is indexed by the
mount's display when mounted (its model's height, from the same data
files), by race and sex otherwise. A gnome on a kodo rides as fast as a
tauren on a kodo.

**Phase 1, crude: height.** The defaults come from a generator, not typed
by hand. The race table (ChrRaces.dbc) names each race's male and female
display, the display (CreatureDisplayInfo.dbc) names a model and a scale,
and the model (CreatureModelData.dbc) has a collision height. Height =
collision height x display scale; factor = height / blood-elf-female
height, through the chosen curve. The generator writes the defaults into a
header the patch compiles in.

**Phase 2, the full version (cleanup pass): gait.** Walking speed follows
leg length and torso posture (owner, 2026-10-04), and gait "relies mostly
on their hips and shoulders". The model files (M2) carry a skeleton; the
hip and shoulder bones' heights at rest give leg length (hip to ground)
and posture (how far forward the shoulders sit over the hips: a hunched
tauren or troll versus an upright human). A later generator reads those
bones and replaces the height-based defaults; the walking functions and
the dispatch table stay as they are, only their numbers change.

## Suggested Implementation Steps

1. Write the generator: read the three DBC files and print, per race and
   sex, the display id (integer), collision height (number), display scale
   (number), height (number) and factor (number) under the linear and
   square-root curves. Read the table before choosing the curve.
2. Have the generator write the defaults header (race, sex, factor).
3. Write the B-patch, apply and unapply by the upstream-patch-system rules:
   the dispatch table and one walking function per race and sex, called
   from the speed recalculation for players only, multiplying on top of
   C003's 0.85.
4. Test: the patch round-trips byte-identically (`scripts/test-source-patches`);
   after the owner's compile, for each race and sex, the run speed the
   server sends after login, after mounting and dismounting, and after a
   slow wears off equals 0.85 x factor.
5. Cleanup pass (phase 2 above): a bone-reading generator for leg length
   and posture, writing the same header.

## Open Questions

1. Linear or square-root curve for phase 1? Linear makes gnomes very slow
   (about half speed); square root follows real legs better.
2. "fastest and farthest": does "farthest" mean jump distance, or more
   endurance, or only speed?
3. Male and female of the same race differ in height (tauren and draenei
   most). The table has a row for each; should they really differ?
4. The project notes say a grown-up module scales player models by level,
   but no such module is in the current source tree. If one returns, should
   speed follow the scaled body as it levels?
5. Every profile, as C003 is, or only some?
6. Walk speed and swim speed too, or only running?
