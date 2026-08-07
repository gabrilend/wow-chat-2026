# Playerbot Bot-Login Strategy Guard Patch (B026)

## Overview

Fixes a segfault on the queued bot-login path, where a second `PlayerbotAI` is
constructed for a `Player` that already has one, orphaning the first without
deleting it. The orphan's `AiObjectContext` is torn down, and the fresh
engine's `strategies` map is left holding a pointer to a strategy owned by that
dead context — a dangling read the moment `Engine::Init` iterates.

Two changes, in two files:

1. **The actual fix** — `PlayerbotsMgr::AddPlayerbotData` deletes the stale AI
   before reconstructing, instead of erasing the map entry and leaking it.
2. **Defense in depth** — `Engine::Init` skips and names a null strategy
   instead of dereferencing it, so any future corruption on this path is a log
   line rather than a crash.

Applies to mod-playerbots. Written 2026-07-16 against module rev `93aaea3d`.

## The Crash

The faulting stack, on the main world thread shortly after startup:

```
OnBotLoginOperation::Execute
  -> PlayerbotsMgr::AddPlayerbotData
    -> new PlayerbotAI
      -> AiFactory::createCombatEngine
        -> Engine::Init          <-- faults iterating `strategies`
```

The `-O2` build mislabels the program counter as `PlayerbotAI::GetBot()`, which
is misleading — the fault is in the map iteration, not that accessor. Building
with `scripts/compile --debug` resolves the frame correctly.

## Root Cause

`PlayerbotsMgr::AddPlayerbotData` handles the "this GUID already has an AI"
case by erasing the map entry **without deleting the object**:

```cpp
_playerbotsAIMap.erase(itr);
```

Two things then go wrong together:

- The orphaned `PlayerbotAI` is never destroyed, but its `AiObjectContext` is
  torn down as part of the surrounding lifecycle. Strategies owned by that
  context become dead objects.
- The freshly-constructed engine's `strategies` map can still reference one of
  them, so `Engine::Init` reads freed memory.

**Why the duplicate add happens at all:** the world-thread login queue has no
GUID dedupe, and the per-holder `playerBots` guard does not cover the global
`_playerbotsAIMap`. Two `OnBotLoginOperation`s that resolve to different
holders can therefore both reach `AddPlayerbotData` for a single GUID.

## Why Delete-Before-Reconstruct Is Safe

This is the load-bearing argument for the patch, established by ownership
analysis. `_playerbotsAIMap`, on the singleton `PlayerbotsMgr`, is the **sole
owner** of every `PlayerbotAI*`:

- The `Player` holds no back-pointer. Every accessor (`GET_PLAYERBOT_AI`)
  re-looks-up by GUID, so no stale raw pointer survives elsewhere.
- Every deletion path — `OnDestructPlayer` via `~Player`, and
  `DisablePlayerBot` — fetches the pointer *from the map*. Once the entry is
  gone, nothing can reach the object to re-delete it.
- `~PlayerbotAI` self-unregisters through `RemovePlayerBotData(GUID)`, so
  deleting the stale AI already clears its own slot.

So the sequence is: delete the stale AI (its destructor erases the slot), then
erase by GUID as an idempotent guarantee that the slot is clear before the
`emplace` assertion. No double-free is reachable.

## Files to Modify

### 1. `modules/mod-playerbots/src/Bot/PlayerbotMgr.cpp`

In `PlayerbotsMgr::AddPlayerbotData`, inside the branch opened by
`_playerbotsAIMap.find(player->GetGUID());`, replace the leaking erase.

Scope the edit to that branch — an identical `erase(itr)` exists in the
GUID-removal path and must be left alone.

**Before:**

```cpp
            _playerbotsAIMap.erase(itr);
```

**After:**

```cpp
            // >>> B026 duplicate-login fix BEGIN
            // Duplicate add for a live GUID (two OnBotLoginOperations resolving to
            // different holders; the queue has no dedupe). The old AI was orphaned
            // here (erased, never deleted), leaving Engine::Init to read a strategy
            // owned by a torn-down context. Delete the stale AI — its dtor
            // (~PlayerbotAI -> RemovePlayerBotData) self-erases the slot by GUID —
            // then erase-by-GUID idempotently so the slot is clear before emplace.
            LOG_WARN("playerbots", "AddPlayerbotData: duplicate PlayerbotAI for GUID {} — reclaiming stale AI (B026)", player->GetGUID().ToString().c_str());
            PlayerbotAIBase* stale = itr->second;
            delete stale;
            _playerbotsAIMap.erase(player->GetGUID());
            // <<< B026 duplicate-login fix END
```

### 2. `modules/mod-playerbots/src/Bot/Engine/Engine.cpp`

In the `Engine::Init` loop, insert immediately **before** the unique line
`strategyTypeMask |= strategy->GetType();` — that is, right after
`Strategy* strategy = i->second;`. Anchoring on `strategyTypeMask` keeps the
insertion inside `Init` only; the same `i->second` idiom appears in other loops.

**Insert:**

```cpp
        // >>> B026 dangling-strategy guard BEGIN
        // A strategy in this engine map should never be null (addStrategy only
        // inserts non-null). If it is, the map was corrupted on the bot-login
        // path. Skip + name it instead of dereferencing into a segfault, so any
        // future recurrence is a logged event rather than a crash.
        if (!strategy)
        {
            LOG_ERROR("playerbots", "Engine::Init: null strategy {} in engine map — skipping (bot AI state corrupted)", i->first.c_str());
            continue;
        }
        // <<< B026 dangling-strategy guard END
```

## Reversal

Both edits are marker-wrapped so the inverse locates them exactly:

- **Engine.cpp** — delete the marker range (the guard is a pure insertion).
- **PlayerbotMgr.cpp** — replace the marker range with the original
  `_playerbotsAIMap.erase(itr);`, so the tree round-trips to upstream HEAD.

## Witness

- `Engine.cpp` contains `B026 dangling-strategy guard`
- `PlayerbotMgr.cpp` contains `B026 duplicate-login fix`

The probe reports "needs applying" when **either** is absent, mirroring the
apply function's two independently-guarded halves.

## Composition with B027

B026 and B027 edit the same `Engine::Init` loop at different anchors and
compose in either order. B026 anchors on `strategyTypeMask |=`; B027 anchors on
the `InitMultipliers` call.

They address **different faults that happen to share a crash site**. B026's
duplicate-login trigger never fired during the 2026-07-21/22 diagnostic
sessions that produced B027 — those found a separate, upstream construction
fault where the strategy facade is corrupt at birth. B027 keeps a redundant
null skip so either patch stands alone.

See `docs/patches/playerbot-engine-init-facade-guard.md` and issue 308.

## Build Instructions

```bash
./scripts/compile --profile vanilla
```

B026 is registered in `PHASE_BEGIN_PATCHES` for release, beta, and vanilla, so
the build applies it before compiling and reverts it afterward.

For crash work on this path, build with `--debug` — the `-O2` build misreports
the faulting frame.

## Related

- `issues/308-playerbot-engine-init-stale-facade-crash.md` — the sibling fault
  at the same site, with the full diagnostic trail.
- `patches/B026-playerbots-bot-login-strategy-guard.sh` — the mechanical
  implementation of this document.
