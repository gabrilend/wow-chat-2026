# 162 - Neuron Control-Plane Bridge

## Status: In Progress

## Current Behavior

`scripts/call-neuron` exists: a hard-coded-`${DIR}` wrapper (`--dir` and
`--neuron-dir` overrides) that forwards every argument to the sibling
checkout's own `scripts/neuron`. `scripts/demo-neuron-encounter` exists on
top of it: given `--place` and either a creature search (`--type`/`--level`/
`--name`, prints neuron's own `world.creatures` output verbatim) or an
explicit `--creature <entry>`, it previews a `world.spawn` plan by default
and requires `--apply` to actually place anything.
`src/lua-basic/neuron-spawn.lua`'s `NeuronSpawn.at` exists, parses under
LuaJIT, and mirrors `Spawn.script`'s ground-probe-then-`PerformIngameSpawn`
sequence line for line — but per the Open Questions below, it is **not**
called by neuron's generator, so `world.spawn` itself is unchanged.

Before this: `../wow-chat-neuron/` was a sibling checkout (its
`config/deployment.lua` already hard-codes
`root = "/mnt/mtwo/games/azeroth-core/wow-chat-2026"`, and it holds its own
sandbox database set, `acore_*_neuron`, inside this project's MySQL
instance) that nothing in this project called into. Pulling one of its
levers meant knowing its absolute path and its CLI's flag shapes by heart.

Separately, neuron's one built creation operation, `world.spawn`
(`../wow-chat-neuron/src/049-spawn.lua`), still writes a **new one-shot Lua
file** into `lua_scripts/custom/` for every creature it places, each one
inlining its own copy of the ground-probe-then-`PerformIngameSpawn`
sequence — unchanged by this issue, for the reason above. That sequence has
no shared definition anywhere else — not in neuron, not in this project (this
project's own
`ambush.lua` spawns through a different primitive, `player:SpawnCreature`,
so it is not the same code path and cannot simply be pointed at).

## Intended Behavior

Three additions, kept deliberately small and independent of each other so
none has to wait on the others:

1. **`scripts/call-neuron`** — a thin wrapper, hard-coded `${DIR}` per house
   convention, that resolves the sibling neuron checkout
   (`$(dirname "${DIR}")/wow-chat-neuron` by default, overridable) and
   forwards every argument to its `scripts/neuron`. Lets any script in this
   project (a test, a phase demo, an admin session) pull a neuron lever
   without knowing where neuron lives.

2. **`scripts/demo-neuron-encounter`** — one concrete use built on the
   wrapper: given a place fragment and a creature search (type/level/name),
   it resolves the place, picks a matching creature kind, and previews a
   `world.spawn` (via `neuron spawn --plan`) — a themed encounter ready to
   drop into a phase demo or a QA session. Defaults to plan-only; applying
   requires an explicit `--apply` flag, because `world.spawn`'s own undo
   column reads "none yet" — there is no receipt-based way to take back what
   it places, and a wrapper that hid that would be lying about the risk.

3. **`src/lua-basic/neuron-spawn.lua`** — `NeuronSpawn.at(entry, mapId, x, y,
   z, orientation, permanent)`, the same ground-probe-then-`PerformIngameSpawn`
   sequence `Spawn.script` in `../wow-chat-neuron/src/049-spawn.lua` currently
   generates inline, factored into one place instead of re-derived by every
   one-shot file neuron writes. This is **not** wired into neuron's
   generator in this pass — see Open Questions — so `world.spawn`'s existing,
   already-unverified behavior is untouched.

## Suggested Implementation Steps

1. `scripts/call-neuron` — DIR resolution, `--dir` override, exec-forward to
   the sibling's `scripts/neuron` with all remaining arguments.
2. `scripts/demo-neuron-encounter` — built on 1; composes `places`,
   `creatures`, and `spawn --plan`; requires `--apply` to drop `--plan`.
3. `src/lua-basic/neuron-spawn.lua` — `NeuronSpawn.at(...)`, matching
   `Spawn.script`'s existing math and refusal message exactly, so the two
   are provably the same computation even while they remain two copies.
   Marked unverified against a live worldserver, same as the file it mirrors
   (no session that touched either has had a worldserver up).

## Candidate Neuron Operations (not built — ideas only)

Noted here rather than built, and not written into neuron's own `issues/`
tree in this pass. If any of these get built, they belong there, declared
the way `world.spawn` is, with their own hands/kind/params:

- **`world.trigger_ambush`** — force this project's ambush system
  (`src/lua-beta/ambush.lua`'s `Ambush.spawnAndAttackPlayer`) to fire for a
  named player immediately, instead of waiting out the random-walk timer.
  Useful for demoing or QA-ing the ambush system on demand. Would need a
  `resident` hand and a way to address one online player's existing
  Lua-side event registration, which is a different shape than `world.spawn`
  ever reaches (that call creates a creature; this would reach into another
  player's already-running state).
- **`character.soul_status`** — read where a death knight's sacrificed soul
  currently sits in the Acherus rotation (`src/lua-basic/death-knight-souls.lua`,
  table `basic_718_souls`). A `cold`, read-only op — the table is already
  plain SQL, so this is close to `world.roster` in shape.
- **`party.buddy_sync`** — read or nudge a buddy roster's state
  (`buddy_roster`, `buddy_clan` tables, issues 617a-617l). Whether this is
  one operation or several (read vs. reassign) is exactly the kind of
  question the vocabulary's own design notes says has to be answered "at
  the level of the whole set," not per-operation.

## Decisions (owner, 2026-09-29)

- **`neuron-spawn.lua` stays where it is, unwired, on purpose.** It lives
  only under `src/lua-basic/`, which the active `.profile` (`vanilla`) does
  not load, and `../wow-chat-neuron/src/049-spawn.lua` keeps generating its
  own inline copy of the same logic rather than calling it. That stays true
  until `.profile` is switched to `basic` for testing whether that profile's
  current batch of source is usable end to end — at which point this file
  starts loading, and wiring neuron's `Spawn.script` to call
  `NeuronSpawn.at` becomes safe to revisit. Nothing here does that
  switch — it is a deliberate no-op, kept only as "a spot to connect wires
  to and from" for later.
- **`scripts/demo-neuron-encounter` keeps `--apply` as built.** Plan-only by
  default; placing anything for real (and there is currently no way to
  automatically undo it — `world.spawn`'s own Undo column reads "none yet")
  requires typing `--apply` explicitly. It is a manual admin tool run by
  hand, not anything unattended.

## Related Files

- `../wow-chat-neuron/README.md`, `../wow-chat-neuron/docs/vocabulary.txt`
- `../wow-chat-neuron/src/049-spawn.lua`, `../wow-chat-neuron/src/033-mechanisms/037-resident.lua`
- `../wow-chat-neuron/config/deployment.lua` (already points at this project)
- `../wow-chat-neuron/issues/607-world-spawn.md`,
  `../wow-chat-neuron/issues/700-mechanisms-one-shape-for-four-hands.md`
- `src/lua-beta/ambush.lua` (a different, non-shareable spawn primitive —
  documented above so nobody tries to unify them by accident)
- `patches/E-patches.sh` (`patch_E001_lua_script_symlinks`, the per-profile
  Lua directory rule this issue's open question turns on)
