# 308 - Playerbot Engine::Init Corrupt-Facade Crash

**Phase:** 3 (Danger - Ambush System / Playerbot login lifecycle)
**Effect:** The world server survives the random-bot login burst, and every bot
keeps its full strategy set (racials, potions, chat) despite an upstream
construction fault.
**Status:** In progress (repair patch written, needs build + verification)

---

## Current Behavior

Upstream mod-playerbots (module rev `93aaea3d`, on core rev `52f58186a533`
of the Playerbot branch, both 2026-07-10) constructs a fixed subset of each
bot's strategy objects with a **corrupt facade argument** — the back-pointer each strategy keeps to its owning bot AI.
The victims are always the strategies at positions 1, 9 and 17 of the strategy
registration order (`racials`, `chat`, `potions`), for every bot, every class,
every login.

Consequences without intervention: the first strategy whose trigger-init
dereferences the facade (`racials`) segfaults the main world thread during the
first login burst, before any bot finishes logging in. An earlier revision of
patch B027 guarded the dereference by *skipping* mismatched strategies, which
kept the server alive but silently stripped racial abilities, combat potions,
and chat handling from every bot (~2,300 skips per boot).

### Diagnostic findings (live-debugger sessions, 2026-07-21/22)

The corruption was cornered with four instrumented boots (breakpoints,
hardware watchpoints, creators-map dissection, instruction-level audit):

- The corrupt value is present **at construction**: a constructor breakpoint
  with a register-verified `this` reads garbage in the facade field at birth
  (nulls, ASCII/UTF-16 string fragments).
- A **hardware write-watchpoint** armed on the field at construction never
  fires afterward — the field is born wrong and never touched again. There is
  no later heap stomp on it.
- Everything else was exonerated with direct evidence: the per-bot context and
  its facade member are healthy at the moment of failure; the shared creators
  map is healthy (correct creator targets, one uniform trampoline, no
  duplicate keys); every source *and* machine-code hop of the serving chain
  preserves the argument correctly.
- The stride-8 victim pattern and the string-fragment garbage indicate a
  mechanical upstream fault in how those creator entries are invoked at bot
  login. The exact upstream mechanism was not pinned; chasing it further was
  judged not worth it since the bug is upstream's, not ours.

## Intended Behavior

The engine is built for exactly one bot, inside that bot AI's constructor, so
the engine's facade is **deterministically the correct value** for every
strategy in its map. When `Engine::Init` meets a strategy whose facade does
not match, it should **repair the strategy in place** — write the engine
facade over the corrupt value, log one warning naming the strategy — and then
initialize it normally. Null strategies are still skipped with an error.

The result: no crash, no lost behaviors, and a log line per repair so the
fault stays visible until upstream fixes it. The repair is safe because (1)
the objects are real, correctly-typed strategies whose constructors ran, (2)
only the facade field is wrong, and (3) the watchpoint evidence shows the
field is written exactly once, so a repair cannot be undone later.

This supersedes the earlier skip design: skipping protected the server but
degraded the bots; repairing protects both.

## Suggested Implementation Steps

1. Extend the shared facade base (`PlayerbotAIAware`) with a public getter and
   a narrowly-scoped setter (the setter exists only for this repair; comment
   it as such).
2. In `Engine::Init`, before the strategy trigger/multiplier initialization:
   skip null strategies with an error; repair facade mismatches with a warning
   via the setter, then fall through to normal initialization.
3. Package as reversible source patch **B027** anchored on the unique
   `InitMultipliers` call (covers both facade-using calls; composes with B026,
   which edits a different anchor in the same loop).
4. Build the active profile, restart, and confirm: login burst completes, the
   playerbots log shows `repairing it with the engine facade` warnings instead
   of skips, and bots visibly use racials/potions/chat behaviors.
5. Once trust is established, optionally downgrade the repair warning to debug
   level to reduce log volume.

## Relevant Files / Symbols

- `modules/mod-playerbots/src/Bot/Engine/Engine.cpp` — `Engine::Init` (repair
  site)
- `modules/mod-playerbots/src/Bot/Engine/PlayerbotAIAware.h` — facade base,
  gains the accessors
- `modules/mod-playerbots/src/Ai/Base/StrategyContext.h` — the registration
  order that fixes the victim positions (1, 9, 17)
- `modules/mod-playerbots/src/Ai/Base/Strategy/RacialsStrategy.cpp` — first
  dereference of the corrupt facade (the original crash site)
- Patch doc: `docs/patches/playerbot-engine-init-facade-guard.md`
- Patch script: `patches/B027-playerbots-engine-init-facade-guard.sh`
- Diagnostic harness used: `scripts/debug-run.sh` (crash backtraces) plus
  session-local gdb catchers (temporary, `/tmp/pb-catch*.py`, not kept)

## Related

- **306** — Nil Bot Periodic Event Crash (ALE login hook; ruled out early —
  that was a recoverable Lua error, not this segfault).
- **B026** — bot-login Engine::Init crash guard for the duplicate-login
  trigger; sibling patch at the same crash site, different trigger. Its
  delete-before-reconstruct never fired during these diagnostics; its
  null-strategy guard remains useful and B027 keeps a redundant null skip so
  either patch stands alone.
- **Upstream report:** the diagnostic trail in the patch doc is sufficient to
  file against mod-playerbots (module rev `93aaea3d`): corrupt facade at
  construction, stride-8 victim selection, watchpoint-clean afterward. Worth
  filing when convenient.
- **Pinned (2026-07-22, per user direction):** the build substrate is frozen
  until further notice at exactly the diagnosed revisions — core
  `52f58186a533` and mod-playerbots `93aaea3d` — via `PROFILE_COMMIT` and
  `PROFILE_MODULE_COMMITS` in `scripts/install` and `scripts/update`
  (beta/release/vanilla; they share one source tree so they pin together).
  Un-pin both maps together once upstream fixes the corrupt-facade
  construction and the repair warnings stop appearing on a test build.
- **Verified working (2026-07-22):** first post-repair boot: 139 bot logins,
  exactly 417 repair warnings (3 per bot, once each, none repeated), zero
  skips, zero crashes, server stable. Repair coverage audit: every live-bot
  strategy fetch goes through the engine map, and everything in the engine
  map passes the repaired `Engine::Init` (runtime additions use
  `init = true`); the only bypass is a config-time enumeration in the travel
  manager that touches no live bots.
