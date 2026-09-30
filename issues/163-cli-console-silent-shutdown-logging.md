# 163 - Log Why the Console Thread Shuts the World Down

## Status: Open

## Current Behavior

`CliRunnable.cpp` (`source-beta/src/server/apps/worldserver/CommandLine/CliRunnable.cpp`)
runs a dedicated thread that reads worldserver console commands from
`stdin`. Two of its branches call `World::StopNow(SHUTDOWN_EXIT_CODE)` —
which halts the entire worldserver — with no log line before either:

- Line 197-201, the non-interactive/"redirected input (pipe)" branch:
  `if (!std::getline(std::cin, command)) { World::StopNow(...); break; }`
- Line 236-239, the interactive/`readline` branch's EOF check:
  `else if (feof(stdin)) { World::StopNow(...); }`

Observed once this session: a basic-profile worldserver, launched by hand
in a real terminal (confirmed not backgrounded, not run through any
non-interactive tool), reached `ready...`, logged
`mod-buddies: roster tables present; buddies are ON`, then immediately
printed `Halting process...` and shut down cleanly — no error, no
segfault, nothing in `Server.log` or `Errors.log` explaining why. One of
the two branches above is almost certainly what fired, but there is
currently no way to tell which, or why `stdin` read as closed/failed in a
session the owner confirms was a real, foreground terminal — ruling out
the two most common causes (backgrounding, and non-interactive tool
execution) of this class of AzerothCore footgun.

**Found 2026-09-29 — the console was never the cause.** Run under `gdb`
with a hardware watchpoint on the server's stop flag
(`World::_stopEvent`), the backtrace showed the stop coming from startup:
Zangarmarsh's outdoor-PvP graveyard asks for a new creature spawn id,
and `ObjectMgr::GenerateCreatureSpawnId` refuses any id at or above
16777215 — it logs "Creature spawn id overflow!!" and stops the world.
The next id is MAX(creature.guid)+1, and basic's world database held
nine custom spawns past the cap: the eight valley Sargobras (617b,
61700001-61700008) and the Acherus Sargobras (718, 71800001), numbered by
the issue-times-100000 convention, which only fits for issues below 168.
They were renumbered to issue-times-10000 (6170001-6170008, 7180001), in
their generator and SQL, and `scripts/validate-basic-state` now checks
that no creature or gameobject spawn id reaches the cap. The overflow
line *was* in Server.log (mid-load, line ~778), not near the
`Halting process...` at the end, which is why it was missed.

Reusable trap, kept at `tmp/shared-memory/stop-hunt/stop-hunt.gdb`
(RAM; recreate from this description): catch SIGINT/SIGTERM/SIGHUP/SIGQUIT
printing `$_siginfo._sifields._kill.si_pid`, then after `starti`,
`watch -l *(long*)&World::_stopEvent` with `bt` in its commands.

**Earlier on 2026-09-29, after B039 was compiled in:** the shutdown reproduced
(Server.log, 12:47) and neither B039 line printed. Only the second line
exists in a Linux binary — the `getline` branch is inside
`#if AC_PLATFORM == AC_PLATFORM_WINDOWS` — and the installed binary does
contain it (`grep -a "console input closed" bin/worldserver`). So the
console thread's EOF path is **ruled out** as the cause. (It likely can
never fire on Linux anyway: `readline` reads the file descriptor
directly, so the C library's end-of-file flag that `feof(stdin)` checks
is never set.)

Also ruled out: a timed `.server shutdown N` (would log
`Server shutdown in N`), playerbots' delete-bot-accounts stop
(`DeleteRandomBotAccounts = 0`), the startup-failure stops in
`Main.cpp`, ObjectMgr, MapMgr etc. (each logs an error first), and
`scripts/worldserver`'s squatter `pkill` (its unquoted `*` expands into
several paths, so `pkill` rejects the extra patterns and kills nothing;
and the pattern names an absolute path, while the server's command line
is `./worldserver`).

What remains are the stops that log nothing at `Info`: a `SIGINT` or
`SIGTERM` reaching the process (`SignalHandler` in `Main.cpp`), or a
`.server exit` / `.server shutdown 0` command arriving by SOAP, an
in-game GM, or a Lua `RunCommand`. Neither SOAP user in reach sends
those (bot-governor never does; the sibling neuron project sends
`server shutdown 5`, which would have logged, or a `kill` to a PID it
manages).

## Intended Behavior

Both branches log, at `LOG_ERROR` level under the same
`server.worldserver` category `Main.cpp` already uses for
`"Halting process..."`, before calling `StopNow`:

- The pipe branch logs that `getline` failed, plus `std::cin`'s `eof()`
  and `fail()` state.
- The interactive branch logs that `stdin` hit `feof()`.

This turns the next occurrence from a silent, source-diving mystery into
one line in `Server.log` that says exactly which of the two paths fired
and, for the first, what state the stream was actually in.

## Suggested Implementation Steps

1. A B-patch (source patch, reversible, applied before compile and
   reverted after — see the `upstream-patch-system` skill) that inserts
   one `LOG_ERROR` call immediately before each of the two `StopNow()`
   calls in `CliRunnable.cpp`, matching that file's existing indentation
   and this codebase's logging convention (`LOG_ERROR("category.sub",
   "msg with {}", arg)` — no `printf`, no `sLog->`).
2. Idempotent apply/unapply, same shape as the project's other single-file
   sed-based B-patches (e.g. B001): a `grep -q` guard before the `sed -i`
   so a second `apply` run is a no-op, and `unpatch` reverses the exact
   insertion.
3. Register it in `patches/patches.sh` wherever the other `source-beta`-
   targeting B-patches for this profile are listed.
4. No test beyond `scripts/test-source-patches` and
   `scripts/test-patched-syntax` (round-trip and compiler-syntax checks) —
   this only adds logging, so there is nothing behavioral to assert.
5. Next time the silent shutdown reproduces, the log line itself answers
   the open question below; until then it stays open.

## Open Questions

- **Why does `stdin` read as closed in a real, foreground, non-backgrounded
  terminal?** Ruled out so far: backgrounding, non-interactive tool
  execution (e.g. Claude Code's own shell), and a debug/gdb-wrapped launch
  (the installed binary is `RelWithDebInfo`, and `scripts/worldserver`
  only wraps under `--debug` or a `Debug`-stamped build, neither of which
  applied here). No daemonization code exists in `Main.cpp` to explain it
  either. Answering this fully needs the log line this issue adds, from a
  reproduction.
  *Answered 2026-09-29: stdin was never the cause; see Current Behavior.
  Replaced by the question below.*
- **Keep B039?** Its one Linux line guards a path that likely can't fire
  (readline never sets the stdio end-of-file flag). Keep it as a cheap
  witness, or drop it and close this issue as "cause found elsewhere"?
- *(Answered 2026-09-29, spawn-id overflow — see Current Behavior.)*
  **Who sends the stop — a signal or a command?** Two ways to find out
  without a recompile: run the server under `gdb` with
  `handle SIGINT SIGTERM stop print`; when it stops,
  `print $_siginfo._sifields._kill.si_pid` names the sending process.
  And uncomment `Appender.GM` / `Logger.commands.gm` in
  `worldserver.conf` so any `.server exit` is logged with who sent it. A compiled answer would
  be a B-patch logging the signal number and sender in `SignalHandler`
  and a log line in `.server exit`.

## Related Files

- `source-beta/src/server/apps/worldserver/CommandLine/CliRunnable.cpp`
- `source-beta/src/server/apps/worldserver/Main.cpp` (prints
  `"Halting process..."` once `WorldUpdateLoop()` returns — the effect of
  either `StopNow()` call, not its cause)
- `patches/patches.sh`
