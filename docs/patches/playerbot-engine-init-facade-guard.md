# Playerbot Engine::Init Facade Repair Patch

## Overview

Stops a `SIGSEGV` that kills `worldserver` during the first random-bot login
burst, and restores full behavior to the affected bots.

On every bot login, upstream mod-playerbots constructs a handful of strategy
objects with a **corrupt facade argument** — the `PlayerbotAI*` back-pointer
each strategy stores. The objects are real, correctly-typed strategies built by
their real constructors; only the facade value they receive is garbage (nulls,
ASCII/UTF-16 string fragments). The first strategy whose trigger-init
dereferences the facade (`RacialsStrategy::InitTriggers` calls
`botAI->GetBot()`) segfaults the world thread.

This patch adds facade accessors to the shared base and, in `Engine::Init`,
detects any strategy whose facade does not match the engine facade and
**repairs it in place** before initialization. The engine is only ever
constructed inside its owning `PlayerbotAI` constructor, so the engine facade
is deterministically the correct value.

Implemented as reversible source patch **B027**
(`patches/B027-playerbots-engine-init-facade-guard.sh`). See issue 308 for the
full diagnostic trail.

## Diagnostic evidence (2026-07-21/22, live-debugger sessions)

- The corrupt value is present **at construction**: a breakpoint in the
  strategy constructor (with a register-verified `this`) reads garbage in the
  facade field at birth.
- A **hardware write-watchpoint** on the field, armed at construction, never
  fires afterward — nothing overwrites it later; it is born wrong.
- Every layer of the serving chain was audited at source *and* instruction
  level and preserves the argument correctly (`GetStrategy` →
  `GetContextObject` → `create` → `std::function` plumbing). The shared
  creators map is healthy at the moment of failure (correct targets, one
  uniform trampoline, no duplicate keys).
- The victims sit at a fixed stride in the strategy registration order
  (positions 1, 9, 17: `racials`, `chat`, `potions`), the same for every bot
  and every class — a mechanical upstream fault, not a property of these
  strategies.
- Affected upstream revision: mod-playerbots module `93aaea3d` on core
  `52f58186a533` (Playerbot branch, both 2026-07-10). The root cause inside
  upstream remains unpinned; this patch contains the damage deterministically.
  The project pins both revisions (scripts/install + scripts/update commit
  maps) until upstream ships a fix.

## Why the repair is safe

1. The engine facade is provably the live, correct owner (engines are built
   inside the owning bot AI constructor).
2. The strategy objects are correctly constructed apart from this one field
   (real constructors run; virtual dispatch works; names report correctly).
3. The watchpoint evidence shows the field is written exactly once (at birth)
   — the repair cannot be undone by a later stomp.
4. Repairing (rather than skipping) restores racials/potions/chat behaviors
   that the skip variant silently removed from every bot.

## Files to Modify

### 1. `modules/mod-playerbots/src/Bot/Engine/PlayerbotAIAware.h`

Add public accessors for the stored facade. Insert immediately **after** the
constructor line:

```cpp
    PlayerbotAIAware(PlayerbotAI* botAI) : botAI(botAI) {}
```

Insert:

```cpp
    // >>> B027 facade accessor BEGIN
    // Public read access to the stored PlayerbotAI facade so sibling
    // PlayerbotAIAware subclasses (Engine vs Strategy) can compare facades
    // without friendship. Used by Engine::Init to detect a strategy built
    // against a corrupt facade before dereferencing it (issue 308).
    PlayerbotAI* GetAI() const { return botAI; }
    // SetAI exists solely for the Engine::Init facade repair (issue 308):
    // upstream sometimes constructs strategies with a corrupt facade
    // argument; the engine rewrites it with the known-correct owner before
    // first use. Do not use it anywhere else.
    void SetAI(PlayerbotAI* ai) { botAI = ai; }
    // <<< B027 facade accessor END
```

### 2. `modules/mod-playerbots/src/Bot/Engine/Engine.cpp`

In `Engine::Init`, insert the guard immediately **before** the unique
`InitMultipliers` call (`GetType()`/`HasTargetExclusions()` above it return
constants, so this anchor covers **both** facade-using calls in the loop):

```cpp
        strategy->InitMultipliers(multipliers);
```

Insert before it:

```cpp
        // >>> B027 stale-facade guard BEGIN
        // This engine is built for ONE bot: its live facade is this->GetAI(),
        // the PlayerbotAI under construction right now (provably valid, since
        // engines are only built inside that ctor). Every strategy here must
        // carry that same facade. Upstream sometimes constructs a strategy
        // with a corrupt facade argument (issue 308: garbage at birth, always
        // the same registration positions; a hardware watchpoint proved the
        // field is never written after construction). Dereferencing it
        // (RacialsStrategy does botAI->GetBot()) SIGSEGVs the world thread.
        // The object itself is real and correctly typed -- only the facade
        // is wrong, and the correct value is deterministically the engine
        // facade. So REPAIR it and initialize normally, keeping the bot
        // fully functional. B026 guards the null case; keep a skip for that.
        if (!strategy)
        {
            LOG_ERROR("playerbots", "Engine::Init: null strategy {} in engine map, skipping (B027, issue 308)", i->first.c_str());
            continue;
        }
        if (strategy->GetAI() != this->GetAI())
        {
            LOG_WARN("playerbots",
                "Engine::Init: strategy {} was constructed with a corrupt bot facade, "
                "repairing it with the engine facade (B027, issue 308)",
                i->first.c_str());
            strategy->SetAI(this->GetAI());
        }
        // <<< B027 stale-facade guard END
```

## Composition with B026

B026 edits the same `Engine::Init` loop, inserting a null-strategy guard
**before** `strategyTypeMask |= strategy->GetType();`. B027 anchors on the
distinct, unique `strategy->InitMultipliers(multipliers);` line and preserves
it, so the two patches are order-independent and never touch each other's
text. B027's own null check is deliberately redundant with B026 so B027 also
stands alone.

## Usage / Verification

Rebuild the active profile, restart, and watch the playerbots log:

- Expect `repairing it with the engine facade (B027, issue 308)` warnings
  (roughly a dozen per bot login) — each one is a strategy healed instead of
  lost.
- The login burst must complete with no segfault, and bots now genuinely run
  `racials`, `potions`, and `chat` behaviors.
- If the volume of repair warnings becomes noise once trust is established,
  downgrade the LOG_WARN to LOG_DEBUG in the patch and rebuild.

## Build Instructions

```bash
./scripts/compile            # or ./scripts/azerothcore update
```
