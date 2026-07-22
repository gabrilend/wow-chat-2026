# Conversation Summary: 848716dd-6f3d-4efa-89ea-fbf890462fc8

Generated on: 2026-07-22 13:46:43

--------------------------------------------------------------------------------

### User Request 1

hi can you read the server logs and tell me if any of them had any errors?


--------------------------------------------------------------------------------

### Assistant Response 1

I'll find the server logs first. Let me look in the likely locations.


The active profile is **vanilla**. The freshest logs are in `tmp/logs-vanilla/`
(updated 20:06). Let me look at those plus the server/error logs.


The `installed-files-vanilla/bin/` logs are stale (from a `shadow` config, MySQL
access denied). The live logs in `tmp/logs-vanilla/` are the ones to check. Let
me read those.


Now let me check the Playerbots.log (the largest file) for actual errors, and
scan for any severe markers across all the live logs.


The "exception" hits are false positives — they're item names like "Enchant
Chest - Exceptional Stats". Let me confirm the Playerbots log tail looks like
normal operation and check whether the servers are still running.


I read the live logs for the active **vanilla** profile (`tmp/logs-vanilla/`).
Here's the verdict:


## No real errors — everything logged is benign


**Auth.log** — Clean. Connected to MySQL fine, all four realms registered.


**Server.log** (worldserver) — Started cleanly, `World Initialized In 0 Minutes 55 Seconds`, reached `ready...`. The only non-info lines are all harmless:

- `Can't set process priority class, error: Permission denied` — just means it wasn't launched as root. Cosmetic.

- `StartHeroicPlayerLevel` (55) and `RecruitAFriend.MaxLevel` (60) failed validation, defaults used — because they exceed the vanilla level cap of 40, so the engine clamps them.

- ~12 `Level X ... in lfg_dungeon_rewards can never be reached` lines — same root cause: dungeon reward tiers above level 40.


**Errors.log** — 220 lines, but **all of them are the same two benign data-validation complaints**, not runtime errors:

- Retail quests whose `RequiredSkillPoints` (210–450) exceed this profile's profession skill cap of 200 → "quest can't be done."

- Skill conditions referencing skill values above 200 → "skipped."


Both are AzerothCore noticing that stock retail content doesn't fit your reduced
caps. Expected, not a fault.


**Playerbots.log** — Normal operation (bots cycling through random-bot updates). No errors.


## One thing worth noting


The **worldserver process is not currently running** — only `authserver` is
up. The Server.log ends cleanly (no crash, no shutdown error), so it looks like
it was stopped normally rather than dying. If you expected it to still be up,
that's the thing to look at — but it's not something the logs are flagging as
an error.


Every "error"-shaped line in these logs traces back to the vanilla profile's
level-40 / skill-200 caps meeting retail content built for level 80 / skill 450.
If you want, I can filter those out of the log at write time so `Errors.log`
only shows things that actually matter.


--------------------------------------------------------------------------------

### User Request 2

ah here's what happened:


---------------------------------------

mod-playerbots initialized

---------------------------------------

>> Loaded playerbots config in 41597 ms


Playerbots: ListSpellsAction caches initialized

Playerbots World Thread Processor initialized


WORLD: World Initialized In 0 Minutes 55 Seconds


AzerothCore rev. 52f58186a533+ 2026-07-10 08:24:30 -0700 (Playerbot branch)
(Unix, RelWithDebInfo, Static) (worldserver-daemon) ready...

Calendar deletion of old events.

Guild Daily Cap reset.

AC> PlayerbotWorldThreadProcessor initialized

/home/ritz/games/azeroth-core/wow-chat-2026/scripts/worldserver: line 190: 28288
Segmentation fault ./worldserver



--------------------------------------------------------------------------------

### Assistant Response 2

A segfault right after `ready...` — the server fully initialized, then
crashed. Let me dig into what happened. Let me look at the launch script and
hunt for a crash dump / core file.


The build is RelWithDebInfo, so the crash catcher didn't run — it went
straight to `./worldserver` with no backtrace captured. And `core_pattern` is
just `core` with none written (core dumps likely disabled via ulimit). But the
crash location is a strong hint: it died right after `AC>
PlayerbotWorldThreadProcessor initialized` — a **playerbots** component.
There's also an existing issue that looks directly relevant. Let me read it and
confirm core-dump availability.


Let me confirm exactly how to re-run it to capture a backtrace, since that's the
actionable next step.


So *that's* the real event — the worldserver **segfaulted at startup**, right
after it finished initializing. Here's what I can and can't tell you.


## What happened


The server got all the way through init to `ready...`, then the **playerbots
world-thread processor** fired its first update tick (`AC>
PlayerbotWorldThreadProcessor initialized`) and crashed. The final lines in
`Playerbots.log` are the random-bot update loop iterating players (`Including
non-random bot player … into random bot update`) — so it died **inside
mod-playerbots' first bot-update pass**, not in core worldserver code. That's a
C++ segfault, not a Lua error.


## Why I can't name the exact line yet


Two things conspired to throw away the evidence:

- **No core dump** — `ulimit -c` is `0`, so the kernel wrote nothing even though `core_pattern` is set.

- **No backtrace** — this is a `RelWithDebInfo` build, and your launcher only auto-runs the crash catcher for `Debug` builds. It went straight to `./worldserver`, so nothing caught the fault.


So the logs tell us *where in the lifecycle* it died (playerbots first tick) but
not *which instruction*. Anyone who tells you the precise cause from these logs
alone is guessing.


## How to actually catch it


Your launcher already has the tool for this. gdb is installed (17.2), so re-run
with the catcher:


```bash

./scripts/worldserver --debug

```


That runs the same binary under gdb and, on the crash, dumps a full backtrace
(crashing thread + all threads) to:


```

tmp/debug-vanilla/worldserver-<timestamp>-backtrace.txt

```


Since it crashes seconds after `ready...`, you won't have to wait long. Send me
that file and I can point at the actual frame.


## One lead worth holding


There's an existing issue — *"Nil Bot Periodic Event Crash"* — describing
bots that enter the world-player list but aren't fully initialized when a
periodic pass touches them. Its documented fix (firing the ALE login hook for
bots) is marked **"needs application"** — i.e. possibly not actually built
into this binary. That's a *plausible* match for "crash on the first bot-update
tick," but it described a Lua nil error rather than a segfault, so I won't
commit to it until the backtrace confirms the frame.


Want me to check whether that playerbots login-hook patch is actually present in
the current `source-beta` tree / this build while you grab the backtrace?


--------------------------------------------------------------------------------

### User Request 3

There's an existing issue — "Nil Bot Periodic Event Crash" — describing bots
that enter the world-player list but aren't fully initialized

when a periodic pass touches them. Its documented fix (firing the ALE login hook
for bots) is marked "needs application" — i.e. possibly

not actually built into this binary. That's a plausible match for "crash on the
first bot-update tick," but it described a Lua nil error

rather than a segfault, so I won't commit to it until the backtrace confirms the
frame.



this seems critical, can you look into it while I generate the debug logs?


--------------------------------------------------------------------------------

### Assistant Response 3

I'll investigate whether that ALE-login-hook patch is actually present in this
build while you generate the backtrace. Let me trace it from patch doc → patch
script → source tree → built binary.


Important nuance: the source tree round-trips clean (patches revert after
build), so the hook being absent from `source-beta` right now tells us nothing
— I need to check whether **B002 was applied during the build that made this
binary**. Let me read the patch, check it's in the active list, and grep the
build log.


Now this is getting substantive. B002 was **silently broken until a 2026-07-16
retarget** — upstream moved `OnBotLoginInternal` to a different file, the old
sed anchor vanished, and the hook stopped injecting entirely. The retarget is
sitting **uncommitted** in your working tree. Two things decide whether it's
relevant: (1) does the *new* anchor actually exist in the pristine source, or
did the retarget also silently no-op, and (2) was the running binary built
before or after the retarget. There's also a **B026 "bot-login crash guard"** in
the list I should read. Let me nail all three.


**Found it.** B026's header describes *exactly* our crash — and it's not B002/issue-306 at all:


> "worldserver segfaults shortly after startup on the queued bot-login path
(main world thread): OnBotLoginOperation::Execute → AddPlayerbotData → new
PlayerbotAI → AiFactory::createCombatEngine → **Engine::Init, faulting while
iterating the engine's `strategies` map**"


That's a hard segfault, at startup, on the bot-login path, main world thread —
matching your crash right after `PlayerbotWorldThreadProcessor initialized`.
B002/issue-306 was the wrong suspect (that's a *recoverable* Lua nil error, not
a segfault) — good that I didn't commit to it.


The decisive question now: **was B026 actually compiled into this binary?**
Because it also adds a defensive Engine::Init guard that turns this exact fault
into a *log line* instead of a segfault — and we saw no such log line, we saw
a real segfault. Two checks settle it: (1) did the build actually apply B026,
and (2) do B026's sed anchors even exist in the pristine source (the trap that
silently broke B002).


The user says the debug run is done — that's the priority. Let me read the
backtrace and, in parallel, run the definitive check on whether B026 is actually
compiled into the binary (its log-string literals will be in the binary if it
was).


Critical correction: **B026 _is_ compiled into this binary** — its log strings
(`reclaiming stale AI (B026)`, `Engine::Init: null strategy…`) are present,
and the B002 ALE `OnLogin` hook is wired in too. So both patches made it in, yet
it still crashed. Theorizing is over — the backtrace is here (225 KB, all
threads). Let me read the actual crash frame.


Thread 1 (the **main thread**) took the SIGSEGV. Let me read the actual stack
frames of the crashing thread.


There it is — ground truth. The crash is **exactly** the path B026 documents,
and it fires **despite B026 being compiled in**:


```

#0 RacialsStrategy::InitTriggers   RacialsStrategy.cpp:30   → Player* bot = botAI->GetBot();   ← faults

#1 Engine::Init                    Engine.cpp:140           strategy=0x…fc40  i.first="racials"

#2 AiFactory::createCombatEngine   AiFactory.cpp:502

#3 PlayerbotAI::PlayerbotAI        PlayerbotAI.cpp:151

#4 PlayerbotsMgr::AddPlayerbotData PlayerbotMgr.cpp:1788

#5 PlayerbotHolder::OnBotLogin     PlayerbotMgr.cpp:481

#6 OnBotLoginOperation::Execute    PlayerbotOperations.h:511

#7 PlayerbotWorldThreadProcessor::ProcessBatch  (batch of 60 logins)

```


So B026 correctly *diagnosed* the path but its fix did **not** prevent this
crash. And I can already see why the defensive guard didn't catch it: the
strategy pointer is **non-null** (`0x…fc40`), so B026's `if (!strategy)` guard
passes — but the fault is one level deeper, inside `strategy->InitTriggers()`
dereferencing a dangling `botAI`, at Engine.cpp:**140**, whereas B026's guard
sits at the `strategy->GetType()` line (Engine.cpp:126). Wrong dereference
guarded.


The decisive question: did B026's *actual* fix (the delete-before-reconstruct)
even run for this bot, or is this a different origin for the dangling pointer?
Let me check whether the B026 warning fired, and read the two faulting sites.


Decisive findings:


- **B026's real fix never fired** — the `reclaiming stale AI (B026)` warning is absent from both logs, and **0 bots logged in** before the crash. So this is **not** the duplicate-login race B026 targets — it dies on the *very first* bot in the first batch.

- `RacialsStrategy.cpp:30` is `Player* bot = botAI->GetBot();` — `botAI` is the `Strategy` base member set at construction. The fault is that pointer being bad.


So B026 is simply *not engaged* here (its fix is for a second, duplicate login;
its null-guard is at the wrong dereference and the pointer is non-null anyway).
Let me read the `Engine::Init` loop to see where the "racials" strategy — and
its `botAI` — actually comes from. That's the true root cause.


One more crucial tell from that `Engine::Init` loop: strategies run in
`std::map` (alphabetical) order — `boost, cast time, chat, default, duel,
potions, **racials**`. It crashed on **racials**, meaning the *earlier*
strategies' `InitTriggers` ran fine with a valid `botAI`. So it's not that the
whole PlayerbotAI is bad — specifically the **racials** strategy instance
carries a bad `botAI`. That points to racials being a *shared/cached* strategy
object rather than one freshly built for this bot. Let me confirm how "racials"
is created.


Checked — the backtrace is conclusive. Here's the whole picture.


## What actually crashed


`SIGSEGV on Thread 1 (the main world thread)`, during the **first batch of
random-bot logins** (60 queued, **zero completed**):


```

#0 RacialsStrategy::InitTriggers   RacialsStrategy.cpp:30   Player* bot = botAI->GetBot();   ← fault

#1 Engine::Init                    Engine.cpp:129           strategy "racials"

#2 AiFactory::createCombatEngine   AiFactory.cpp:502

#3 PlayerbotAI::PlayerbotAI (ctor) PlayerbotAI.cpp:151

#4 PlayerbotsMgr::AddPlayerbotData PlayerbotMgr.cpp:1788    ← constructing a fresh AI

#5 PlayerbotHolder::OnBotLogin     PlayerbotMgr.cpp:481     ← holder = RandomPlayerbotMgr

#6 OnBotLoginOperation::Execute    PlayerbotOperations.h:511

#7 PlayerbotWorldThreadProcessor::ProcessBatch

```


It faults dereferencing `botAI` — a `Strategy` base-class back-pointer to the
owning `PlayerbotAI`. That pointer is pointing at freed/garbage memory.


## Ruling out the two suspects


**B002 / issue-306 (ALE login hook)** — not it. That was always a *recoverable* Lua nil error, not a segfault. And it's genuinely fixed: the `OnLogin` symbol and `MOD_ALE` wiring are compiled into the binary. Your instinct that it "seemed critical" was reasonable, but it's a different bug.


**B026 (bot-login strategy guard)** — *this* is the patch that targets this crash path, and it **is compiled into the binary** (I confirmed its log strings are present). But it does **not** stop this crash, for two independent reasons:


1. **Its real fix never engages.** B026 fixes a *duplicate*-login race — a
second `PlayerbotAI` built for a GUID that already had one. Its telltale warning
`reclaiming stale AI (B026)` is **absent from both logs**, and **0 bots logged
in** before the crash. This dies on the *first* login of the *first* bot.
Different trigger.

2. **Its defensive guard is at the wrong dereference.** B026 inserts `if
(!strategy) continue;` before `strategy->GetType()` at Engine.cpp:126. But (a)
the fault is three lines later at `strategy->InitTriggers()` (line 129), and (b)
the strategy pointer is **non-null** (`0x…fc40`) — it's the strategy's
*internal* `botAI` that's dangling. A null check can't catch a use-after-free.


## The real root cause


Strategies aren't built fresh in the engine — they're pulled from the bot's
`aiObjectContext` via `GetStrategy(name)` (Engine.cpp:355), and each is `new
RacialsStrategy(botAI)` where `botAI` comes from **the context**
(StrategyContext.h:150). The engine in frame #2 is initialized from an
`aiObjectContext` whose `botAI` points at a **destroyed** `PlayerbotAI`. Every
strategy it lazily creates inherits that dangling pointer; `Engine::Init` then
faults at **the first strategy whose `InitTriggers` immediately dereferences
`botAI`** — which, in `std::map` order, is `racials` (the earlier ones —
boost, chat, default… — have trivial or non-dereferencing trigger init, so
they slid past).


This is the *same "dangling strategy owned by a dead context"* family B026 named
— but reached through a path B026's `AddPlayerbotData` dedup doesn't cover (no
duplicate, so its delete-before-reconstruct never runs). So either the context
is being reused from an earlier torn-down AI for this bot via an uncovered
route, or the context's `botAI` isn't repointed to the live facade before
strategies are pulled. Pinning which needs a read of the `PlayerbotAI` ctor +
how `aiObjectContext` is obtained — one more layer down.


This is a **mod-playerbots bug on this branch** (rev `52f58186a533`, Playerbot
branch, 2026-07-10), not something our patches introduced — they just don't
yet cover it.


## Where I'd go next — your call


1. **Immediate unblock (operational):** these are `RandomPlayerbotMgr`
auto-logins, so the server can't finish boot while they fire. Turning down the
startup burst (`AiPlayerbot.RandomBotAutologin = 0`, or a low
`RandomBotMinLevel`/count) in `playerbots.conf` should let the world come up
while we fix the real bug. Fastest path to a running server.

2. **Real fix (new patch, e.g. B027):** ensure the `aiObjectContext`'s `botAI`
is the live facade before the engine initializes strategies — i.e. don't let a
first-login engine build off a stale context. I'd write an issue file first
(this is a feature-grade fix, not a one-line bugfix), then extend the patch set.
I'll need to read `PlayerbotAI.cpp:151` and the context-creation path to target
it precisely.

3. **Bisect upstream:** if this started recently, a playerbots commit around
2026-07-10 regressed context/AI lifetime on the login path; pinning to the prior
known-good commit sidesteps it until upstream fixes it.


Want me to start with #1 to get you a bootable server, then open an issue and
dig into #2? I haven't changed anything yet.


--------------------------------------------------------------------------------

### User Request 4

2. Real fix (new patch, e.g. B027): ensure the aiObjectContext's botAI is the
live facade before the engine initializes strategies — i.e.

don't let a first-login engine build off a stale context. I'd write an issue
file first (this is a feature-grade fix, not a one-line

bugfix), then extend the patch set. I'll need to read PlayerbotAI.cpp:151 and
the context-creation path to target it precisely.



let's try this, then if it doesn't work, let's try this:


3. Bisect upstream: if this started recently, a playerbots commit around
2026-07-10 regressed context/AI lifetime on the login path;

pinning to the prior known-good commit sidesteps it until upstream fixes it.


--------------------------------------------------------------------------------

### Assistant Response 4

Let's do option 2 the right way — but first I need to *precisely* understand
the ownership, because the fix has to target the exact point where the context's
`botAI` diverges from the live facade. Let me read the constructor, the factory,
and the context lifecycle before writing anything.


The construction flow is clear now: at `PlayerbotAI.cpp:149` the context is
created with `this` (the live facade), then `:151` builds the engine from it. On
a clean first construction the context's `botAI` *is* the live facade — so the
dangling pointer means `createAiObjectContext` is handing back a
**shared/cached** context, not a fresh one. That's the crux. Let me read it and
the context's object-caching.


The caching model is now clear — `NamedObjectContext` has a `shared` flag, and
cached objects persist on the context. If the strategy context is **shared
across bots**, the first bot's `RacialsStrategy` (holding that bot's `botAI`)
gets cached, and after that bot's AI is destroyed the cached strategy dangles
for every later bot. Let me confirm whether the strategy context is actually
shared and how `GetStrategy` resolves.


Almost there. The per-bot `NamedObjectContextList` creates strategies fresh with
the bot's `botAI` — so the dangling pointer only makes sense if `GetStrategy`
resolves "racials" through a **`shared` context whose `created` cache persists
across bots**. The deciding file is `AiObjectContext.h` — how `GetStrategy`
resolves and which `botAI` it feeds the creator. Let me read it.


The ownership is actually **per-bot and should be safe**: `AiObjectContext`
holds a per-instance `strategyContexts` with its own cache, created fresh with
the live facade at `PlayerbotAI.cpp:149`. So a naive "set botAI = facade" fix
would be a no-op — the defect is subtler (a stale/torn-down facade reaching
this path, exactly B026's family but not via the dedup it guards).


That reshapes the right fix: a **guard + diagnostic at the actual faulting
site** — in `Engine::Init`, before `InitTriggers`, verify each strategy's
stored `botAI` matches the engine's live facade; skip-and-log on mismatch
instead of segfaulting. That both keeps the server up *and* tells us the exact
nature of the bad pointer on recurrence (which decides whether option 3 is
needed). Let me nail the exact accessors before writing, and read the
patch-system skill.


--------------------------------------------------------------------------------

### User Request 5


--------------------------------------------------------------------------------

### Assistant Response 5

The API picture is nearly complete: `Engine : PlayerbotAIAware` stores the live
facade as `botAI` (Engine.cpp:17), and each `Strategy : PlayerbotAIAware` stores
its own `botAI` (protected, PlayerbotAIAware.h:18). The guard needs to compare
`strategy`'s botAI against the engine's facade — a **safe pointer comparison**
(no deref) that detects a strategy built off a foreign/torn-down facade. Two
things to confirm before I write: whether there's already a public accessor for
`botAI` (else the patch must add one), and what `botAI` `GetStrategy` actually
feeds the creator. Plus I need to check for duplicate issues and the next issue
ID.


Everything needed is confirmed. Two decisive results:


1. **`AiObjectContext::GetStrategy` feeds the creator the context's own
`botAI`** (AiObjectContext.cpp:108) — which on a clean first construction *is*
the live facade. And a clean logical consequence falls out: the engine's facade
(`this->botAI`) is the `PlayerbotAI` currently under construction, so it's
**provably valid**. Therefore a crash at `botAI->GetBot()` can *only* happen
when `strategy->botAI ≠ engine facade` — a stale/foreign facade on the
strategy. A guard comparing those two pointers is thus **necessary and
sufficient** to stop this exact segfault, whatever upstream mechanism produced
the stale strategy.


2. **`PlayerbotAIAware` has no public accessor** — so the patch must add a
tiny `GetAI()` getter, then guard in `Engine::Init` at the unique
`strategy->InitTriggers(triggers);` line (129).


Before I write anything: B026 already fixes "the bot-login Engine::Init crash"
— my fix targets the *same crash site* via a different cause. Per your "build
history vertically" rule I must not spawn a horizontal duplicate. Let me find
B026's issue file and the 306/332 lineage.


B026 has **no issue file and no patch doc** (it was created Jul 16, still
untracked) — the recent bot-login-crash patches got ahead of their
documentation. And there's no issue 332 despite the references. So there's
nothing to vertically extend for the Engine::Init crash specifically; I'll
create a new Phase-3 issue (same subsystem as 306) that documents the
Engine::Init crash *family* — noting B026 handled the duplicate-login trigger
and B027 handles the residual stale-facade trigger. Let me pick the next free
Phase-3 ID and confirm patches.sh wiring for B026 so B027 slots in beside it.


Next free Phase-3 ID is **308**. Let me read the `patches.sh` structure — how
B-files are sourced, the apply runner, and the `patch_needs_applying_*`
convention — so B027 wires in cleanly beside B026.


--------------------------------------------------------------------------------

### User Request 6


--------------------------------------------------------------------------------

### Assistant Response 6

No response requested.


--------------------------------------------------------------------------------

### User Request 7

please continue


--------------------------------------------------------------------------------

### Assistant Response 7

Let me read the runner section of `patches.sh` to see how patches are applied
and how `needs_applying` is used, so B027 matches conventions exactly.


The wiring model is clear: patches self-guard via markers; the profile lists
select them; `patch_needs_applying_*` is an optional dry-run helper. B027 will
touch two files (`PlayerbotAIAware.h` add accessor, `Engine.cpp` add the guard).
Since **B026 also edits `Engine.cpp`'s Init loop**, I must pick a non-colliding,
unique anchor. Let me verify anchor uniqueness and check that the early strategy
calls (GetType/InitMultipliers) are botAI-safe so I place the guard early
enough.


Key result: `strategy->InitTriggers(triggers);` is **unique** (line 129, and
it's the exact faulting call) — that's my anchor, cleanly independent of
B026's anchor at 126. (`Strategy* strategy = i->second;` is *not* unique —
appears at 80/125/504 — so I'm avoiding it.) Two last idiom checks before
writing: confirm `fmt::ptr` and a `GetAI()` accessor name are consistent with
the module.


Confirmed: `GetAI()` is unused module-wide (clean to add, no clash), but
`fmt::ptr` isn't used either — so I'll keep the log to the strategy name
(compile-safe, and the name is the actionable datum). `LOG_ERROR` is available
in Engine.cpp. And critically — B026's inserted comments avoid apostrophes
because the `sed` insert is single-quoted; I'll do the same.


I have everything. Writing the four artifacts now: issue file first (per your
rules), then patch doc, patch script, and the `patches.sh` wiring.


Now the patch doc with the exact code changes:


Now the B027 patch script, mirroring B026's structure (sourced module, vimfolds,
marker-wrapped, idempotent, exact-inverse). I'm anchoring on the clean `:
botAI(botAI) {}` (no regex-special chars) and the unique
`strategy->InitTriggers(triggers);`, and keeping the inserted comments
apostrophe-free since the `sed` is single-quoted:


Now wire B027 into `patches.sh` — add it to the release/beta/vanilla lists
(mirroring B026's placement) and add the `patch_needs_applying_B027` helper.


Now add the `patch_needs_applying_B027` dry-run helper, grouped with the other
mod-playerbots checks:


All artifacts are written. Before handing off to a slow compile, I want to prove
the patch actually *matches and round-trips* — the silent-no-op anchor failure
(exactly what bit B002) is the thing to catch now, not after a wasted build. Let
me dry-run apply→unapply against throwaway copies of the two files
(non-destructive; the real source tree is untouched).


Accessor is clean and correctly indented. Now the Engine.cpp guard insertion,
idempotency, and the round-trip:


Clean placement, valid C++, idempotent. One improvement worth making: the guard
currently sits *after* `InitMultipliers` (line 128), so a stale strategy still
runs `InitMultipliers` before the check. The observed crash is in
`InitTriggers`, but guarding before *both* Init calls is strictly safer. Let me
check if `InitMultipliers` is a unique anchor so I can move the guard one line
earlier.


`InitMultipliers` is unique (line 128) — good anchor. Let me confirm
`GetType`/`HasTargetExclusions` (lines 126-127, which still run before that
anchor) don't dereference `botAI`, so moving the guard there fully covers the
dangerous calls.


Confirmed — `GetType()` returns a constant and `HasTargetExclusions()` returns
`false`; neither touches `botAI`. The dangerous calls are `InitMultipliers` and
`InitTriggers`. So anchoring the guard before `InitMultipliers` (line 128)
covers **both**, which is strictly safer than my current placement. Let me
retarget the anchor in the patch script and doc, then re-verify.


Let me fix the two remaining `InitTriggers` references (composition note in the
doc, and the script header) to say `InitMultipliers`:


Now the full round-trip verification with the corrected anchor — fresh
sandbox, apply → check → idempotency → **unapply must restore pristine**
(the exact-inverse assertion):


All invariants pass: anchors match once, idempotent, guard now covers both
`InitMultipliers` and `InitTriggers`, and the round-trip is **exact** (both
files restore identical). One more thing to prove since B026 and B027 both edit
`Engine.cpp` — that they **compose** (apply together, both round-trip). Let me
test both orders:


Composition verified in **both** apply orders — B026's null guard and B027's
stale-facade guard coexist cleanly, both dangerous calls (`InitMultipliers` +
`InitTriggers`) are covered, and `Engine.cpp` round-trips clean either way. Let
me do a final sanity check that I never touched the real source tree and show
exactly what changed:


The `source-beta/modules/mod-playerbots` tree has leftover modified files —
but note these are in the **disposable, gitignored** module tree (its own git
repo), not the project repo. They're patch residue from the last build that
didn't cleanly revert; the next build's `reset_source_trees` pre-flight
hard-resets them before applying fresh patches. Let me confirm my two target
files specifically are pristine (so my anchor analysis was against clean
source):


Everything checks out. Both target files are pristine (my anchor analysis was
sound); the 24 dirty files are harmless last-build residue in the disposable
module tree that `reset_source_trees` wipes at the next build.


## Option 2 is built and verified — ready for your compile


**What I created** (nothing committed; source tree untouched):

- `issues/308-playerbot-engine-init-stale-facade-crash.md` — the behavior/root-cause spec

- `docs/patches/playerbot-engine-init-facade-guard.md` — the exact code changes

- `patches/B027-playerbots-engine-init-facade-guard.sh` — the reversible patch

- `patches/patches.sh` — B027 added to release/beta/vanilla lists + `needs_applying` helper


**What B027 does.** `Engine` and every `Strategy` both store a `PlayerbotAI*` facade. The engine is built for one bot with the *live, under-construction* facade — which is provably valid — so a strategy whose facade differs is stale/foreign, and that mismatch is the **only** way the `botAI->GetBot()` dereference can fault. B027 adds a public `GetAI()` accessor to `PlayerbotAIAware`, then in `Engine::Init` skips + logs any strategy whose facade ≠ the engine's, right before the two facade-using calls (`InitMultipliers`/`InitTriggers`). A hard segfault becomes a named log line, and the login burst completes.


**Verification I ran** (non-destructive, in `/tmp`):

- Both anchors match **exactly once** (no silent no-op — the B002 failure mode)

- **Idempotent** (apply×2 = one block each)

- **Exact round-trip** (unapply restores both files byte-identical)

- **Composes with B026** in both apply orders — the two guards coexist, `Engine.cpp` round-trips clean either way


**Build it when ready** (you run the compile):

```bash

./scripts/compile # or ./scripts/azerothcore update

```

Then start worldserver.


**How to read the outcome — this is the branch point to option 3:**

- **Boots, no crash, no B027 log lines** → clean fix; issue 308 resolvable.

- **Boots, *with* `Engine::Init: strategy <name> carries a stale or foreign bot facade` lines** → fixed *and* it just told us the mechanism (which strategy, how often). Send me those lines; they confirm whether the stale facade is worth a deeper upstream fix.

- **Still crashes** (guard never fired) → the fault isn't a facade mismatch, so we go to **option 3**: pin mod-playerbots (`52f58186a533`, 2026-07-10) to a prior known-good commit. The debug-run harness (`./scripts/worldserver --debug`) will give a fresh backtrace to confirm.


One small housekeeping note: your convention says new docs get added to
`docs/table-of-contents.md`. I left that alone since the existing
`docs/patches/*` don't appear to be indexed there — say the word if you want
it added.


--------------------------------------------------------------------------------

### User Request 8

alright the server is compiled and the worldserver is running. It hasn't
finished booting yet - can you examine the compile logs, then set a short timer
if the worldserver isn't done yet, to re-examine the boot logs and move forward?


--------------------------------------------------------------------------------

### Assistant Response 8

Let me check the compile log confirmed B027 applied, and see how far the
worldserver has gotten in booting.


The worldserver is running (PID 16251) but still mid-boot — it's at "Loading
TalentSpecs...", early in the ~41s playerbots init, well before the first
bot-login batch where it crashed last time. The build log doesn't echo `[B027]`
(patch-runner output goes to console, not this log — same as B002/B026
earlier), so let me confirm B027 made it into the binary the definitive way
(`strings`), and launch a bounded background watcher that wakes me when the boot
resolves.


**B027 is confirmed live in the running binary** — the exact guard log string (`Engine::Init: strategy {} carries a stale or foreign bot facade … (B027, issue 308)`) is compiled in, and the binary is freshly built (17:39:55 today). So the guard will fire if a stale-faced strategy shows up.


**Current state:** worldserver (PID 16251) is mid-boot at "Loading TalentSpecs" — early in the ~41s playerbots init, still short of the first bot-login batch where it segfaulted last time.


**Watcher launched** (background, bounded ~200s). It will wake me the moment the boot resolves into one of:

- **process dies** → crashed again (guard didn't cover it → we pivot to option 3);

- **reaches "World Initialized" and survives the bot-login window** → boot complete;

- **timeout** → still grinding, I'll re-check.


No separate timer needed — the harness re-invokes me automatically when the
watcher exits. I'll examine the boot logs then (including whether any B027
skip-lines fired, which is the diagnostic payload) and report back.


--------------------------------------------------------------------------------

### User Request 9

<task-notification>

<task-id>b0y5cvxna</task-id>

<tool-use-id>toolu_01VEA2kBaM62HYajAqW2D94J</tool-use-id>

<output-file>/tmp/claude-1000/-mnt-mtwo-games-azeroth-core-wow-chat-2026/848716dd-6f3d-4efa-89ea-fbf890462fc8/tasks/b0y5cvxna.output</output-file>

<status>completed</status>

<summary>Background command "Launch bounded background boot watcher" completed
(exit code 0)</summary>

</task-notification>


--------------------------------------------------------------------------------

### Assistant Response 9

The watcher finished — let me read its verdict.


Survived the crash point. Now the important part — let me confirm it's fully
up and, critically, whether the B027 guard actually *fired* (caught stale
strategies) or whether the crash simply didn't recur. That distinction is the
diagnostic payload.


**The crash is fixed — the server is up and stable.** It reached `ready...` (World Initialized in 1m36s, Debug build so slower), the process is alive, and world update ticks are running. And the guard **actively fired** — this wasn't the crash merely failing to recur.


But the diagnostic payload is significant: **2,292 skip lines**, only ever on
three strategies — `chat`, `potions`, `racials`. That's pervasive, not a rare
race. Let me quantify it and confirm the mechanism before reporting fully.


Let me get the final mechanistic data point — the `StrategyContext` base
constructor's `shared` flag — then I'll report the full picture.


The server booted cleanly and is **stable** — reached `ready...`, process
alive, world ticks running, and critically: **zero segfaults this run** (grep
for segfault/terminate/assert came back empty). Errors.log holds only the usual
benign data warnings. The crash is fixed.


And the guard didn't just passively avoid the crash — it **actively caught the
fault and told us exactly what it is.**


## The diagnostic payoff


Across **185 bot logins**, the guard fired **2,292 times**, on exactly three
strategies:


| strategy | skips |

|----------|------:|

| `chat` | 1336 |

| `racials` | 480 |

| `potions` | 480 |


Every other strategy (`default`, `cast time`, `duel`, `boost`, `aoe`, …)
passed with a valid facade. So this is **not** a rare race — it's **systemic
and specific**: those three strategies *consistently* arrive at `Engine::Init`
carrying a facade that belongs to a different or already-freed bot AI.


## What this means


- **Stability: solved.** The segfault is gone; the server runs. Option 2 did its job.

- **But B027 is currently a safety net catching a real, ongoing bug** — not the root-cause cure. Because it skips those strategies, the affected bots boot **alive but behaviorally degraded**: no racial abilities, no combat potion use, no chat behaviors. Stability-safe (nothing depends on them; `default` is never skipped), but not free.

- The "shared strategy context" idea I floated earlier is **not** the mechanism — `StrategyContext` is registered non-shared. So *why* these three specific strategies always carry a stale facade is a genuine lifetime bug still to be pinned — but it's now sharply scoped to three named creators instead of an opaque crash.


One health note: there was a single **150-second world-tick stall** at startup
(`Update time diff: 150377ms, 0 players online`) — the bot-login burst plus
2,292 `LOG_ERROR` writes. One-time and non-fatal, but if B027 stays long-term,
that per-skip logging will spam continuously as bots cycle.


## Where I'd go next (your call — I haven't touched anything further)


1. **Pin the real lifetime bug** now that it's localized to
`chat`/`potions`/`racials`: trace how those three creators end up with a foreign
facade (why them and not `default`). That's the fix that makes bots whole again
*and* retires the skips — and it's effectively the deeper end of option 3.

2. **Use the server as-is** if degraded bot behavior is acceptable for now —
it's stable and playable.

3. **Quiet the guard** (downgrade to `LOG_DEBUG` or rate-limit) once you've seen
enough, so it stops flooding the log every bot cycle.


I'd also like to update issue 308's *current behavior* to record this verified
result (crash fixed; guard fires pervasively on three strategies) — but per
your "don't do anything unless I tell you to," I'll hold until you say go. Want
me to start on #1?


--------------------------------------------------------------------------------

### User Request 10

<local-command-caveat>Caveat: The messages below were generated by the user
while running local commands. DO NOT respond to these messages or otherwise
consider them in your response unless the user explicitly asks you
to.</local-command-caveat>


--------------------------------------------------------------------------------

### User Request 11

<command-name>/model</command-name>

<command-message>model</command-message>

<command-args></command-args>


--------------------------------------------------------------------------------

### User Request 12

<local-command-stdout>Set model to [1mFable 5[22m and saved as your default
for new sessions</local-command-stdout>


--------------------------------------------------------------------------------

### User Request 13

hi can you figure this bug out for me?


- The "shared strategy context" idea I floated earlier is not the mechanism —
StrategyContext is registered non-shared. So why these three specific strategies
always carry a stale

facade is a genuine lifetime bug still to be pinned — but it's now sharply
scoped to three named creators instead of an opaque crash


--------------------------------------------------------------------------------

### Assistant Response 13

The model switch is noted — continuing the hunt. The data signature is the
key: **every** bot gets stale facades on **exactly** those three names, starting
from the *very first* login (the original crash hit bot #1 before any bot had
logged in). That means the three strategy objects were created **before any real
bot existed** — during config load — and are being **shared** across all
bots. Something singleton-shaped is hiding in how those three are created. Let
me read the actual creator bodies and the config-time pre-warm code.


No signal line — the file's shape is different than expected. Let me look at
it directly:


The trap is set. While it boots, here's where the investigation stands:


## Status of the hunt


**Eliminated by direct reading** (every link of the serving chain, on pristine source, plus all patches that touch these files):

- Creator functions — all three are plain `new XStrategy(botAI)`, stateless, single registration each

- Constructor chains — `Strategy(botAI) : PlayerbotAIAware(botAI)`, forwarded correctly through `PassThroughStrategy`; exactly one facade member in the hierarchy

- Per-bot context — freshly `new`'d in the AI constructor for every class (I read the whole switch; no shared fallback)

- Config-driven strategies — `RandomBotCombatStrategies = ""` (empty, and the trio isn't named anywhere in the active conf)

- Our patches — B019/B021 are inert warning fixes; B026/B027 were already audited composed


That's a genuine paradox: statically, the strategy handed to `Engine::Init`
**must** carry the engine's own facade — yet exactly
`chat`/`potions`/`racials` arrive foreign, for every bot, starting *inside bot
#1's constructor*.


**So the answer is dynamic**, and the instrumented boot now running will catch it red-handed with two tripwires:

- every **birth** of a `RacialsStrategy` (who constructed it, with which facade, full caller chain)

- every **guard hit** (which object, its facade vs the engine's, and whether the per-bot cache already contained it)


The one datum I most want: whether a `RacialsStrategy` gets constructed **during
config load** — before any bot exists. If yes, the caller frames in that first
`[CTOR]` record point straight at the culprit that's somehow feeding shared
objects into per-bot engines.


I'll report the verdict as soon as the catchpoints fire.


--------------------------------------------------------------------------------

### User Request 14

<task-notification>

<task-id>bcp3xz2wr</task-id>

<tool-use-id>toolu_01W8w7zhea9pWGFFK9sGgp8Y</tool-use-id>

<output-file>/tmp/claude-1000/-mnt-mtwo-games-azeroth-core-wow-chat-2026/848716dd-6f3d-4efa-89ea-fbf890462fc8/tasks/bcp3xz2wr.output</output-file>

<status>completed</status>

<summary>Background command "Wait for catchpoint data from instrumented run"
completed (exit code 0)</summary>

</task-notification>


--------------------------------------------------------------------------------

### Assistant Response 14

The tripwires fired — reading the catch:


Quick fix to the watchpoint's value-printing (it had a broken placeholder), then
stop round 1 and launch round 2:


Round 2 is booting (about 2½ minutes to ready, then the login burst trips the
wires). While it runs, the state of play:


## What round 1 proved


The stale-facade theory was wrong in an important way. The three strategies
aren't inheriting a *dead bot's* facade — they're being **born with garbage**:


| strategy | facade value at construction | what it actually is |

|----------|------------------------------|---------------------|

| racials | `0x2073616820676e69` | ASCII `"ing has "` — a string fragment |

| chat | `0x68` | ASCII `'h'` |

| potions | `0x100000000` | two 32-bit ints (1, 0) |


That's not a lifetime bug — that's **memory corruption or an uninitialized
read**, dressed up to look like one. And the maddening part: these creations
happen through the *same* per-bot context, on the *same* call path, interleaved
with creations that receive the correct facade — the value is good, then
garbage, then good again within one constructor sequence. A fixed heap member
can't do that on its own.


## What round 2 will decide


Two rival explanations, and the instrumentation splits them cleanly:


1. **Heap stomp** — another thread transiently writes string data over the
context's facade field. The hardware watchpoint fires on the illegal write and
prints the *stomper's* backtrace and thread. Case closed.

2. **In-flight corruption** — the member is fine, but the argument gets
clobbered between `GetStrategy` reading it and the creator using it
(cross-thread stack interference — plausible fallout from upstream's
2026-07-10 world-thread-processor refactor). Then no stomp fires, and the ctor
record will show `GetStrategy this->botAI = good` while `botAI-arg = garbage`
— proving the corruption happens mid-call.


Either way, the next notification should carry the culprit's name.


--------------------------------------------------------------------------------

### User Request 15

<task-notification>

<task-id>b98uqyods</task-id>

<tool-use-id>toolu_01SYs2xxsAZNrPnScrggi6p3</tool-use-id>

<output-file>/tmp/claude-1000/-mnt-mtwo-games-azeroth-core-wow-chat-2026/848716dd-6f3d-4efa-89ea-fbf890462fc8/tasks/b98uqyods.output</output-file>

<status>completed</status>

<summary>Background command "Wait for round-2 stomp/guard evidence" completed
(exit code 0)</summary>

</task-notification>


--------------------------------------------------------------------------------

### Assistant Response 15

Round 2 tripped — reading the verdict:


Round 3 is booting (~2½ min). Recap of the evidence chain while it runs:


## The narrowing


| Round | Question | Answer |

|-------|----------|--------|

| 1 | Are the strategies shared or stale? | Neither — **born with garbage
facades** (ASCII fragments, tiny ints) |

| 2 | Is the context member stomped? | **No** — hardware watchpoint silent;
member is perfect in `GetStrategy`'s own frame, same thread |

| 2 | Where does the value die? | **Inside the `std::function` invocation** —
between `create()` and `StrategyContext::racials` receiving its argument |

| grep | Why these three names? | **Insertion stride** — registrations #1, #9,
#17 in the creators map; every 8th entry, not a property of the strategies |


The garbage shapes (UTF-16 text remnants, `'o','k'` bytes, plain null) are what
an **unwritten argument register** picks up — the trampoline calls the right
function but never loads the argument. That's the signature of a corrupted or
mismatched `_M_invoker` slot in the stored function object.


Round 3 dumps every entry of the live creators map — target, manager, invoker
pointers with symbol names. If the bad entries carry a different invoker than
the good ones (or point into non-code memory), we'll have the exact 8 corrupted
bytes and, from their contents, a strong lead on who wrote them. Then the fix
conversation is short: either a real upstream bug we patch precisely, or — if
the pointers implicate build inconsistency — a clean rebuild test before
anything else.


--------------------------------------------------------------------------------

### User Request 16

<task-notification>

<task-id>bogsz7xtw</task-id>

<tool-use-id>toolu_01KDgjKgoFcjM7xwgPmN2reZ</tool-use-id>

<output-file>/tmp/claude-1000/-mnt-mtwo-games-azeroth-core-wow-chat-2026/848716dd-6f3d-4efa-89ea-fbf890462fc8/tasks/bogsz7xtw.output</output-file>

<status>completed</status>

<summary>Background command "Wait for round-3 creators map dump" completed (exit
code 0)</summary>

</task-notification>


--------------------------------------------------------------------------------

### Assistant Response 16

The map dump is in — reading the dissection:


Cut ranges were off — I got tails and neighbors. Precise ranges this time:


Round 4 is booting. The state of the hunt, compressed:


## Where five rounds of evidence have led


**Exonerated, with machine-level proof:** every line of C++ in the serving chain *and* every instruction of its compiled code — `GetStrategy` → `GetContextObject` → `create` → `std::function` plumbing — all preserve the facade argument perfectly. The shared creators map is healthy at the moment of failure. No duplicates, no torn nodes, one clean trampoline.


**The reframe:** my earlier "born with garbage" readings came from constructor-*entry* breakpoints — exactly where gdb can read unspilled parameter slots and lie. Discard those, and the trustworthy facts (the compiled B027 guard firing, the original segfault, heap-member reads) point to a **heap stomp after construction**: strategies are built *correctly*, then something overwrites their facade field with string data in the microseconds before `Engine::Init` checks them.


**Why always `chat`/`potions`/`racials`:** bot login allocates the same objects, same sizes, same order, every time — so the same *relative heap chunks* neighbor the overrunning buffer on every bot. The victims aren't chosen by name; they're chosen by *address arithmetic*. Deterministic corruption masquerading as a logic bug. (It also means B026's duplicate-login story may have been this same overflow wearing a different costume.)


**Round 4's trap** watches the freshly built victim's own field — armed the instant the object exists, when the base constructor has already stored the good pointer. First write after that *is* the culprit, full backtrace attached. One bonus read at arm-time (`facade@birth`) confirms construction was clean.


If the trap lands, we'll have the offending function red-handed — then the fix
is a targeted B028 upstream-style patch (and an upstream report with a beautiful
evidence trail).


--------------------------------------------------------------------------------

### User Request 17

how about, since this isn't our bug but instead is upstream's, how about when we
initialize these bots we just supply the required datastructures, hard-coded
because they're the same every time?


--------------------------------------------------------------------------------

### Assistant Response 17

Before I answer that — round 4 may have already caught the stomper, which
would sharpen everything. Quick check:


Now the guard block — mismatch heals and falls through; null still skips:


Now the patch doc and issue file, updated to the repair design:


Now re-verify the revised patch — full round-trip plus B026 composition, same
harness as before:


Done — your approach is implemented, verified, and ready to build.


## What changed: B027 is now *guard-and-repair* instead of *guard-and-skip*


Your idea, refined by one fact: the correct facade can't be a literal hard-coded
constant because it differs per bot (each bot's own AI object) — but the
**repair rule** is constant and known at the repair site. The engine is only
ever built inside its owning bot AI's constructor, so `Engine::Init` always
knows the true facade. The revised guard:


- **null strategy** → skip with an error (unchanged, redundant with B026 by design)

- **facade mismatch** → one `LOG_WARN` naming the strategy, **write the correct facade over the garbage**, then initialize normally


So instead of every bot silently losing racials, combat potions, and chat
handling (~2,300 skips per boot), the poisoned strategies get healed at the door
and work as upstream intended.


**Why round 4 makes this provably safe:** the field is corrupt *at birth* and the hardware watchpoint proved *nothing ever writes it afterward* — so a repair at init can't be undone by a later stomp. And the objects are genuinely the right classes built by their real constructors — only that one field is wrong.


**Updated artifacts** (all verified: single anchor match, idempotent, exact round-trip, composes with B026 in both orders):

- `patches/B027-…facade-guard.sh` — repair logic + a narrowly-scoped `SetAI` accessor (commented "do not use anywhere else")

- `docs/patches/playerbot-engine-init-facade-guard.md` — full diagnostic evidence + the exact code, ready to replay on any fork and to serve as the upstream bug report

- `issues/308…` — current/intended behavior rewritten to the repair design, with the fallback (pin upstream pre-2026-07-10) recorded


The diagnostic server is stopped and the port is free. Compile when ready:


```bash

./scripts/compile

```


**What to expect in the log:** `…repairing it with the engine facade (B027, issue 308)` warnings — roughly a dozen per bot login — replacing the old skip errors. Each one is a healed strategy. Success looks like: clean boot, no segfault, and shamans actually War Stomping / bots drinking potions / responding to chat. If the warning volume gets old once trust is established, say the word and I'll downgrade it to debug level.


One loose end worth keeping in the back pocket: the *upstream* root cause is
still unpinned (we contained it, per your call). The patch doc's evidence trail
— corrupt at birth, stride-8 victims, watchpoint-clean afterward, rev
`52f58186a533` — is ready to file against mod-playerbots whenever you feel
like it.


--------------------------------------------------------------------------------

### User Request 18

One loose end worth keeping in the back pocket: the upstream root cause is still
unpinned (we contained it, per your call). The patch doc's evidence trail —
corrupt at birth,

stride-8 victims, watchpoint-clean afterward, rev 52f58186a533 — is ready to
file against mod-playerbots whenever you feel like it.


we should pin wow-chat-2026 to this commit until further notice. Also, let's try
and see if the bug is fixed. the compilation is done and the first worldserver
start logs are in.


kinda looks like the repair is happening every time. Can you examine the exactly
point when the strategies are checked in our code to see if we need to make
repairs more? maybe it's missing there! where is it missing? anyway can you
check the whatchamacallit


--------------------------------------------------------------------------------

### Assistant Response 18

Three things: pin the module, verify the fix in the new logs, and audit whether
the repair net has holes (other places strategies are consumed without passing
through our repair point). Starting with the logs and the repair-coverage
question in parallel:


All three asks are done. The summary:


## 1. The bug is fixed — verified by the numbers


139 logins → **exactly 417 repairs (139 × 3), zero skips, zero crashes**,
boot to `ready...` in 1m11s, server stable. And your "repair is happening every
time" observation is the system working as designed: upstream corrupts the three
strategies **at every bot's construction**, so every fresh login needs its own
three repairs. The proof the repair *sticks*: each strategy is repaired exactly
once and never again — the skip era logged ~12 lines per bot because every
`Init` re-pass re-hit the same broken objects; now later passes find them
healthy and stay silent. Relogging bots will each log three more — that's the
expected steady state until upstream fixes their constructor path.


## 2. The coverage audit — no missing repair sites


You asked where else the check might be missing. I traced every consumer of
strategies:


- **All live-bot fetches** (`PlayerbotAI::GetStrategy`, pull-strategy lookups, target-value lookups) pull from the **engine map** — and nothing enters the engine map without passing `Engine::Init`, our repair point.

- **Runtime additions** (chat commands, toggles, instance strategies) use `addStrategy` with `init = true` by default → immediate `Init` → repaired before first use.

- **The batched adds** (`addStrategiesNoInit`) are always followed by an explicit `Init()` in every factory path.

- The **only bypass** is the travel manager's config-time enumeration sweep — it touches dummy data before any real bot exists, never live bots.


So the single repair point covers the entire live surface. One net, fully
strung.


## 3. Pinned until further notice


One correction while doing it: `52f58186a533` is the **core** tree's revision;
the module's own HEAD is **`93aaea3d`** (both 2026-07-10). The pin freezes both,
using the pin machinery the scripts already had:


- `PROFILE_COMMIT` → core `52f58186a533` for beta/release/vanilla (they share one source tree, so they must pin together; alpha untouched)

- `PROFILE_MODULE_COMMITS` → `mod-playerbots = 93aaea3d` for the same three profiles

- Mirrored in **both** `scripts/install` and `scripts/update`, with comments recording the why, the sibling-pin relationship, and the un-pin condition (upstream fixes the corrupt-facade construction; repair warnings vanish on a test build)


From now on, `update` will check out these exact revisions instead of pulling
— the diagnosed-and-contained ground can't shift under you. Issue 308 and the
patch doc now carry the corrected revision attribution, the pin record, and the
verification numbers.


Loose ends, in order of value: issue 308 could be marked complete and committed
whenever you're satisfied with play-testing (bots should now visibly War Stomp,
drink combat potions, and answer chat commands — worth a quick in-game poke);
the upstream report against `93aaea3d` remains packaged in the patch doc for
whenever you feel like filing it; and if the repair warnings get chatty once
trust is earned, one word and I'll drop them to debug level.


--------------------------------------------------------------------------------
