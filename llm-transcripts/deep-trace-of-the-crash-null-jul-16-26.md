# Conversation Summary: agent-a7d20009ba59ee641

Generated on: 2026-09-26 12:46:00
Models: claude-opus-4-8

--------------------------------------------------------------------------------

### User Request 1

READ-ONLY deep source analysis in /mnt/mtwo/games/azeroth-core/wow-chat-2026
(mod-playerbots at source-beta/modules/mod-playerbots/src). Goal: find the exact
cause of a null/invalid-pointer crash so we can write a source patch. Do NOT
edit anything.

THE CRASH (captured via gdb, -O2 RelWithDebInfo so line attribution is fuzzy):
  #2 PlayerbotAI::GetBot()                 PlayerbotAI.h:536
  #3 Engine::Init()                        Engine/Engine.cpp:130
  #4 AiFactory::createCombatEngine(...)    Factory/AiFactory.cpp:503
  #5 PlayerbotAI::PlayerbotAI(Player*)     PlayerbotAI.cpp:151  (constructor)
  #6 PlayerbotsMgr::AddPlayerbotData(Player*,bool)  PlayerbotMgr.cpp:1767
  #8 OnBotLoginOperation::Execute() (queued bot login, runs on the MAIN world
  thread via PlayerbotWorldThreadProcessor::ProcessBatch)

Established facts (verify, don't just trust):
- Engine::Init iterates `std::map<std::string,Strategy*> strategies` and calls
  strategy->GetType(), HasTargetExclusions(), InitMultipliers(multipliers),
  InitTriggers(triggers), then iterates strategy->actionNodeFactories.creators.
- Engine::addStrategy only inserts NON-null strategies (guarded by `if
  (Strategy* s = aiObjectContext->GetStrategy(name))`), so a plain null in the
  map is not obviously possible. addStrategiesNoInit is used for the combat set.
- ProcessBatch runs on the main world thread (queued, not parallel).

TASKS — trace precisely and report the most likely faulting object +
mechanism:
1. Read Engine::Init fully (Engine/Engine.cpp) and
   Engine::addStrategy/addStrategiesNoInit/removeStrategy. Determine every
   pointer dereferenced in the Init loop and which could be null/dangling.
2. Trace aiObjectContext->GetStrategy(name): find
   NamedObjectContext/NamedObjectFactory (search Ai/NamedObjectContext.h or
   similar). Does GetStrategy cache created strategies in a per-context map?
   Could it return a dangling pointer (e.g., an object owned/freed elsewhere)?
   Is the strategy object shared across engines or per-context?
3. createAiObjectContext (AiFactory.cpp): is the AiObjectContext per-bot or
   shared? What owns the Strategy objects, and what is their lifetime vs the
   Engine that references them in `strategies`?
4. AddDefaultCombatStrategies (AiFactory.cpp): list every strategy name added
   for the combat engine. Then check whether each of those strategy names is
   actually REGISTERED in the strategy context/factory (grep the
   creators/registration). Is it possible a registered strategy's constructor
   leaves it partially initialized, or that InitTriggers/InitMultipliers deref a
   null trigger/multiplier/value context?
5. Consider the queued-login angle: OnBotLoginOperation::Execute runs during
   World::Update. Is there anything the bot's Player object is missing at that
   point (e.g., not fully in world, GetSession() null, spec/class data not
   loaded) that AddDefaultCombatStrategies/GetPlayerSpecTab/InitTriggers would
   deref? Check GetPlayerSpecTab and any GetSession()/spec usage in the strategy
   init path.
6. The user asks pointedly: "did we remove all the strategies or something?" —
   check whether the strategy registration could be empty/incomplete (e.g., a
   static registration that didn't run, an #ifdef, a build-order issue), and
   whether an empty or partial strategy set would crash vs no-op.

Return: (a) the exact most-likely faulting dereference and object, (b) the
mechanism (null vs dangling vs partial-init vs missing-registration), (c) a
concrete proposed fix location and shape (what a patch would
guard/lock/reorder), (d) confidence level and what single piece of evidence
(e.g., an -O0 backtrace, or a specific value) would confirm it. Concise,
evidence-based, quote key lines with file:line.

--------------------------------------------------------------------------------

### Assistant Response 1

> I'll trace this crash systematically. Let me start by reading the key files.

> Let me find the specific files and read them.

> Now the key file. Let me read PlayerbotAI.h around line 536, and the AiFactory
> around the relevant lines.

> So line 536 (`Player* GetBot() { return bot; }`) simply returns the `bot`
> member. The gdb line attribution at `#2 PlayerbotAI::GetBot()
> PlayerbotAI.h:536` with `#3 Engine::Init() Engine.cpp:130` is fuzzy under -O2.
> Let me look carefully at Engine::Init line 130 and understand what GetBot is
> being called from. Note: Engine::Init itself doesn't call GetBot directly —
> the loop at 123-134 dereferences `strategy` (from the map). Let me look at the
> beginning of AddDefaultCombatStrategies and the strategy registration.

> Now I understand the strategy set. Note the `Reset()` at Engine::Init line 120
> clears `actionNodeFactories.creators`, then the loop at 130 copies each
> strategy's `actionNodeFactories.creators`. The crash frame `#2 GetBot()
> PlayerbotAI.h:536` inlined into `Engine::Init Engine.cpp:130` is telling. Let
> me examine the NamedObjectContext (GetStrategy caching) and Strategy.h, and
> where GetBot could be called during InitTriggers/InitMultipliers or strategy
> construction.

> Critical finding. Look at `NamedObjectContext<T>::create` (lines 98-104):
>
> ```cpp
> virtual T* create(std::string name, PlayerbotAI* botAI) override
> {
>     if (created.find(name) == created.end())
>         return created[name] = NamedObjectFactory<T>::create(name, botAI);
>     return created[name];
> }
> ```
>
> If `NamedObjectFactory<T>::create` returns **nullptr** (name not in creators
> — line 63-64), this caches nullptr into `created[name]`. Now let me look at
> how GetStrategy uses this. Let me find AiObjectContext::GetStrategy.

> The `strategyContexts` is a `SharedNamedObjectContextList<Strategy>` —
> meaning strategies are built into a shared static structure. Let me find
> AiObjectContext definition and GetStrategy.

> Now the key: `strategyContexts` is a `NamedObjectContextList<Strategy>`
> (per-bot context, referencing shared creators/contexts). Its `created` map is
> per-context (per-bot). Let me read the .cpp for GetStrategy, the constructor,
> and BuildAllSharedContexts.

> Now the critical piece — `GetStrategy` ->
> `strategyContexts.GetContextObject(name, botAI)` (NamedObjectContextList,
> lines 205-214 of NamedObjectContext.h):
>
> ```cpp
> T* GetContextObject(const std::string& name, PlayerbotAI* botAI)
> {
>     if (created.find(name) == created.end())
>     {
>         if (T* object = create(name, botAI))
>             return created[name] = object;
>     }
>     return created[name];   // <-- if create returned nullptr, created[name] default-constructs nullptr and returns it
> }
> ```
>
> So `GetStrategy` returns nullptr for an unregistered name. In
> `Engine::addStrategy`, the `if (Strategy* strategy = ...)` guard prevents
> inserting a null. So the `strategies` map should never contain null. That
> matches the "not obviously possible" premise. This points toward a
> **dangling** pointer or a **thread-safety** issue. Let me examine the
> constructor at PlayerbotAI.cpp:151 and PlayerbotMgr.cpp:1767, and the world
> thread processor to understand what's actually happening on login.

> Line 151 is exactly `createCombatEngine`, matching frame #4/#5. Now let me
> look at where `BuildAllSharedContexts` is called — this is critical for task
> 6 (was registration ever run?). And check the world thread processor to
> understand threading.

> This confirms `ProcessBatch` runs on the main world thread (from
> `Update(diff)` during `World::Update`). Operations wrapped in try/catch —
> but a segfault is not a C++ exception, so it crashes. Now the important part:
> `BuildAllSharedContexts()` is called from PlayerbotAIConfig.cpp:750. Let me
> check the context — is it guaranteed to run before any bot login, and is it
> guarded against double-init? Also let me look at the
> `SharedNamedObjectContextList::Add` for a subtle bug.

> `BuildAllSharedContexts` runs once during config Init, before any bot logs in
> — so the registration IS present. The strategy set is not empty (the "did we
> remove all strategies" hypothesis is unlikely — an empty strategy set would
> just no-op the Init loop, not crash). Now let me focus on the actual
> dereference. Frame #2 is `GetBot()` inlined into Engine::Init:130. Line 130 is
> `for (auto &iter : strategy->actionNodeFactories.creators)`. But GetBot
> returns `bot`. Where would GetBot be called from a strategy's
> `actionNodeFactories`? Let me look at Strategy.h and where strategies call
> GetBot, and critically — the InitTriggers/InitMultipliers path and any
> AiObject::GetBot usage. Let me look at the Strategy class and a sample
> strategy that could deref.

> Now the crucial question: how are Strategy objects created and cached, and
> could they be dangling? The `created` map in
> `NamedObjectContextList<Strategy>` is a per-bot member of the per-bot
> `AiObjectContext`. But the `creators` and `contexts` are references into the
> **shared static** `sharedStrategyContexts`. Let me look at `PlayerbotAIAware`
> (holds botAI/GetBot) and the Strategy constructor, and importantly examine
> what happens during bot re-login (does the old AiObjectContext get destroyed
> while a queued op references it?). Let me check PlayerbotMgr.cpp:1767 and
> AddPlayerbotData.

> Now I need to understand the OnBotLoginOperation. Let me look at the
> operations file and how the Player pointer is captured/validated when the
> operation executes on a delayed batch.

> Key observation: `OnBotLoginOperation::Execute` re-resolves `bot` via
> `ObjectAccessor::FindConnectedPlayer(m_botGuid)` — so the Player pointer is
> fresh and valid. `holder->OnBotLogin(bot)` leads to `AddPlayerbotData -> new
> PlayerbotAI(bot) -> createCombatEngine`. So the crash is not a stale Player
> pointer at that level. Let me examine `OnBotLogin` and whether the Player is
> fully in world at this point. Let me also verify `GetSession()` is valid
> (constructor line 148 derefs `bot->GetSession()->GetAccountId()` — that
> would crash earlier). The crash is specifically in Engine::Init:130. Let me
> look at PlayerbotAIAware and GetBot's relationship, and check what `bot` is
> when GetBot is inlined at Engine::Init:130.

> So `Strategy : PlayerbotAIAware` holds `botAI`. The `strategy->GetType()`,
> `HasTargetExclusions()`, `InitMultipliers`, `InitTriggers` in Engine::Init
> deref `strategy`. If a `strategy` in the map is a **dangling** pointer,
> calling `strategy->GetType()` (virtual) would read a garbage vtable and jump
> — but the backtrace shows it landing precisely at GetBot (which returns
> `bot`). Under -O2 with RelWithDebInfo, if `strategy` were a freed object, the
> addresses wouldn't attribute so cleanly. The clean attribution to `GetBot() {
> return bot; }` inlined at Init:130 suggests something is actually calling
> GetBot.
>
> Let me reconsider. Line 130 `for (auto &iter :
> strategy->actionNodeFactories.creators)` — the `creators` is a
> `std::unordered_map`. If `strategy` is a valid object but its
> `actionNodeFactories` was never populated (strategy constructor), iterating an
> empty map is safe. The GetBot inline is suspicious. Let me check: does any
> strategy's **constructor** call GetBot()? The strategy is lazily created
> inside `GetStrategy` during `addStrategy`, which happens right before Init.
> Let me check the DPS/dps assist strategy constructors and combat strategies.
> Let me look at where GetBot is called from strategy constructors or
> InitTriggers.

> The Strategy constructor is simple; it doesn't call GetBot. Now, the line
> attribution "GetBot() PlayerbotAI.h:536" inlined into Init:130 under -O2 is
> almost certainly **misleading** — the compiler collapses the small accessor
> and the loop body, and PC-to-line mapping picks a nearby inlined function. The
> real fault is a **member access on a bad `strategy` pointer** in the Init loop
> (lines 126-133).
>
> Let me now nail down the dangling/threading angle. The key question: is
> `OnBotLogin` (which constructs the PlayerbotAI + engines) ever run
> **concurrently** with something that mutates the shared static contexts, or is
> a PlayerbotAI/AiObjectContext being destroyed on another thread while Init
> runs? Let me look at OnBotLogin and how logout/removal interacts, plus check
> if there is any parallel bot update thread touching engines.

> This confirms the constructor path. Now let me directly investigate the
> strongest lead. The vanilla starter-kit patches (B025) are in the git status
> — this project heavily modifies the playerbots module. The user's question
> "did we remove all the strategies or something?" suggests a **local patch may
> have altered strategy registration**. Let me check the patches and whether the
> strategy registration in `BuildSharedStrategyContexts` might have been
> patched, and whether a strategy referenced by combat could be missing from
> creators. Let me check the base strategy registration.

> The registration (`BuildSharedStrategyContexts`) all correctly call the base
> and add class factories. Registration is intact. So the "did we remove all
> strategies" hypothesis is not the cause — the strategies map is populated.
>
> Let me now check whether this project applies patches to the playerbots
> WorldThread system, and specifically whether the OnBotLogin could be
> re-entered / the map re-inserted. The key remaining suspect: the
> `SharedNamedObjectContextList::Add` builds the `creators` map — but the
> `contexts` vector holds the `NamedObjectContext<Strategy>*`. The **per-bot**
> `NamedObjectContextList<Strategy>::created` caches per bot. That's fine.
>
> Let me reconsider the actual dereference more concretely. Let me disassemble
> the built binary if available, or check the local git patches that touch this
> crash path — those patches are load-bearing per the git status (B017, B025).

> Let me check the B002 login-hook patch (it's the one that changes how bots log
> in — directly relevant to the OnBotLoginOperation queued path) and B017
> (unused variables in playerbots — modified in git status).

> B002 injects `sALE->OnLogin(bot)` into `OnBotLoginInternal`, which is called
> at line 479 of `OnBotLogin` — **after** `AddPlayerbotData` (line 476) which
> is where the PlayerbotAI/engines are constructed. So the ALE hook is not on
> the crash path (the crash is in the constructor at 476/line 1766, before
> OnBotLoginInternal). Good — B002 is not the culprit.
>
> Now, the most important verification: is `OnBotLoginInternal` called and does
> the queued login flow differ from upstream? Let me check whether the
> OnBotLoginOperation is queued from within `OnPlayerLogin`/`sALE` on a **map
> thread** rather than the world thread — and if the world's async loading
> means the bot Player isn't fully in world. Let me look at where
> OnBotLoginOperation is queued.

> This is the critical finding. `HandlePlayerBotLoginCallback` runs as a
> **database async query callback**. Let me verify:
> `HandlePlayerBotLoginCallback` is a DB callback (line 188 called it from
> inside a `.then()`/callback). The bot's
> `WorldSession::HandlePlayerLoginFromDB` is called, then `OnBotLoginOperation`
> is queued to run on the world thread later.
>
> The bot Player is created on line 210, added to world in
> `HandlePlayerLoginFromDB`. Then `OnBotLoginOperation` executes later on the
> world thread and constructs the PlayerbotAI. By that time the Player is fully
> in world (re-resolved via FindConnectedPlayer). So the Player itself is valid.
>
> Now I have enough to reason about the real dereference. The clean line
> attribution to `GetBot()` and `strategy->` in the Init loop under -O2 is the
> key. Let me verify by checking whether a build with debug info exists to
> disassemble, and check the actual `strategyTypeMask |= strategy->GetType()`
> — `GetType()` is the FIRST deref of `strategy` (line 126). Let me look at
> whether there's a compiled binary to confirm which member offset GetBot reads.

> No binary access needed. Let me examine the last piece — whether `strategy`
> in the map could be **dangling** because `ResetStrategies` is called on the
> freshly built engine, or because the shared static strategy `created` cache is
> being cleared/rebuilt. Also, one very important scenario: **the same
> PlayerbotAI is constructed while an old one for the same GUID is being
> destroyed**. Look at `AddPlayerbotData`: if `_playerbotsAIMap` already has an
> entry for the GUID (line 1761-1765), it just `erase`s the iterator from the
> map — **but does not delete the old PlayerbotAI object**. Let me confirm
> whether the erased PlayerbotAI is leaked or deleted elsewhere, and whether the
> shared strategy objects are per-bot.

> Now I have the complete picture of object lifetimes. The `~PlayerbotAI`
> deletes engines and aiObjectContext. The `AiObjectContext` destructor destroys
> its per-bot `NamedObjectContextList<Strategy>` which deletes the per-bot
> `created` strategies. So **strategies are per-bot** (created lazily in the
> per-bot context's `created` map), owned by that bot's `AiObjectContext`,
> referenced by that bot's `Engine.strategies`. Lifetime: strategy dies with the
> AiObjectContext, which the Engine's parent PlayerbotAI also owns. Within a
> single bot, consistent.
>
> The crash is during the **constructor** (frame #5), so the object is
> brand-new; no destruction race within this object. But there's a subtle
> re-login race I should verify. Let me confirm my understanding by checking
> `GetType()` on the combat strategies — specifically whether any combat
> strategy has a broken/pure-virtual situation. But more productively: let me
> verify the actual first deref. Under -O2, `strategy->GetType()` (line 126) is
> a **virtual call**. If `strategy` pointed to a half-constructed or wrong
> object, the vtable dispatch would be the crash — but it landed in GetBot, a
> **non-virtual inline**. This strongly implies the loop reached line 130
> (`strategy->actionNodeFactories.creators`) and something in the loop body
> called GetBot.
>
> Wait — line 130-133 copies creators. Nothing calls GetBot there. Let me
> reconsider: the debug line info under -O2 for an **inlined** function frame #2
> `GetBot()` with caller frame #3 `Engine::Init:130` — this means the compiler
> inlined a call to GetBot() somewhere whose code got scheduled/attributed to
> Init:130. `InitTriggers`/`InitMultipliers` (lines 128-129) are **virtual**
> calls into per-strategy overrides. Let me check whether any combat strategy's
> `InitTriggers` is inlined and calls `botAI->GetBot()`. Let me search combat
> strategy InitTriggers implementations for GetBot.

> These GetBot calls are in trigger `IsActive()`/`Check()` bodies, not in
> InitTriggers. InitTriggers just constructs TriggerNode objects (which store
> trigger *names*, not resolved triggers — the trigger is resolved lazily
> later in ProcessTriggers). So GetBot is not called during Init loop via
> triggers.
>
> Now I'm confident: the "GetBot() at Init:130" attribution is **-O2 debug-line
> noise** — the real fault is dereferencing a bad `strategy` pointer in the
> Init loop (lines 126-130). The compiler placed the faulting instruction's line
> info on an inlined `GetBot` and attributed the frame to Init:130. Since `bot`
> is the first member typically read via `botAI` in these objects, and GetBot is
> `{ return bot; }` reading `bot` at a fixed offset from `this`, the crash is
> really a **read through a bad `this`** — i.e., `strategy` (or `botAI`
> reached through strategy) is a bad pointer.
>
> Let me nail the mechanism definitively by checking the one remaining strong
> candidate: whether `botAI` (the `this->botAI` in the strategy, or the
> PlayerbotAI being constructed) is fully valid when Init runs. The PlayerbotAI
> constructor at line 151 calls createCombatEngine **before**
> `currentEngine`/other members are set — but `bot` is set first (initializer
> list, line 133). So `botAI->GetBot()` returns a valid `bot`. Let me verify
> there's no member of PlayerbotAI read during Init that's uninitialized. Let me
> check the PlayerbotAI member initialization order and whether
> `GetType()`/combat strategies read anything via botAI during construction. Let
> me look at a representative combat strategy GetType and check the
> `DpsAssistStrategy` / generic strategies used by ALL classes ("racials",
> "chat", "default", "formation", "dps assist").

> The registration is intact and populated (StrategyContext,
> AssistStrategyContext, etc.). So strategies are definitely registered — the
> user's "did we remove all strategies" theory is disproven: an empty
> registration would make `addStrategy`'s `if (Strategy* s = GetStrategy(...))`
> guard skip everything, leaving `strategies` empty, and the Init loop would
> simply not execute (no crash). A crash requires the loop to run with a bad
> pointer.
>
> Let me now examine `StrategyContext` to see how these strategies are created
> — critically whether any creator lambda could **return the same shared
> strategy object** or a static, causing double-free/dangling across bots. And
> check the AssistStrategyContext for "dps assist".

> Registration is thoroughly populated. Each creator does `return new
> XxxStrategy(botAI)` (per-bot fresh object). I've verified all the standard
> hypotheses. Let me now look at the one creator pattern that would produce a
> per-bot object with a bad state — and specifically look at the `formation`
> strategy, since `addStrategy("formation", false)` is called for **every**
> class unconditionally (AiFactory.cpp:294), making it always present in the
> combat engine. Let me check whether formation or any creator returns null or a
> static.
>
> Let me look at the creators return pattern and the `formation` registration
> specifically, plus check the git-modified B017 patch since it's in the working
> tree and touches playerbots.

> All creators use `return new XxxStrategy(botAI)` — clean per-bot allocation,
> no statics, no null returns. Registration is complete and correct. This
> definitively rules out the "missing/empty registration" and "null in the map"
> hypotheses.
>
> I now have enough to reach a well-founded conclusion. Let me do one final
> crucial check on the true mechanism — the **re-login / double-construction
> race**. In `AddPlayerbotData` (line 1761-1767), if the GUID already exists in
> `_playerbotsAIMap`, the old `PlayerbotAI*` is **erased from the map but NOT
> deleted** (memory leak), and a new one is constructed. But more importantly
> — this constructs while the Player object may be shared. Let me verify
> whether `OnBotLogin`'s guard (line 471 `playerBots.find`) and this can be
> re-entered. Let me also confirm the initializer-list ordering issue in the
> constructor: `security(bot)` — is `security` declared before
> `aiObjectContext` in the header? Member init order follows **declaration**
> order, not initializer-list order.

> Now I have the definitive picture. Let me verify member declaration order
> matters here: `bot` (632) is declared and initialized FIRST, before
> `aiObjectContext`/`engines`. So when `createCombatEngine` runs (from the
> constructor body, after the initializer list completes), `bot` is fully set.
> `aiObjectContext` was set on line 149 (body). `engines[]` are set on lines
> 151-153 (body). So during `createCombatEngine`, `bot` and `aiObjectContext`
> are valid. No uninitialized-member issue.
>
> Let me do the final targeted check: confirm the `bot` Player is actually
> **added to the world / has spec data** at OnBotLogin time. The constructor's
> `AddDefaultCombatStrategies` calls `GetPlayerSpecTab(player)` →
> `GetTalentMap()`, `GetActiveSpecMask()`. If the Player were loaded but not
> fully initialized, that would crash in GetPlayerSpecTab — but the backtrace
> is in Engine::Init, past strategy addition. Let me verify by re-reading the
> exact call order: `AddDefaultCombatStrategies` (populates `engine->strategies`
> via addStrategiesNoInit) returns, THEN `engine->Init()` (line 502) iterates.
> So GetPlayerSpecTab already succeeded. The Player IS fully loaded.
>
> I've exhausted the null/missing-registration/uninitialized-member paths. All
> point to the map containing a valid, non-null strategy. The remaining viable
> mechanism is a **dangling `botAI`/`this` reached via the strategy**, or the
> -O2 attribution genuinely being the loop dereferencing a corrupted `strategy`.
> Let me check the one thing that can corrupt: whether `Reset()` (called at
> Init:120) and the shared static contexts interact, and whether there's any
> known concurrency: is `PlayerbotWorldThreadProcessor` truly the only thing, or
> do map-update threads also construct bots?

> This is a `WorldScript::OnUpdate` — runs on the main world thread.
> Single-threaded for the login construction path. So it's not a data race on
> the construction itself.
>
> I now have a complete, evidence-based analysis. Let me do one last
> verification of a real dangling scenario that fits a single-threaded model:
> `sPlayerbotAIConfig.combatStrategies` / `ChangeStrategy` at
> AiFactory.cpp:456-459 runs INSIDE AddDefaultCombatStrategies path? No —
> that's in a different function. Let me verify which function contains lines
> 456-459 (the ChangeStrategy call) vs AddDefaultCombatStrategies which ends at
> 496.

> This `ChangeStrategy` at line 456-459 is still within
> `AddDefaultCombatStrategies` (it ends at 496). `ChangeStrategy` parses config
> strings and calls `addStrategy`/`removeStrategy`. This is the last mutation
> before `engine->Init()`. Config-driven strategy names go through the same
> guarded `addStrategy` — so still no null in the map.
>
> I've done thorough tracing. Let me write the final report. Let me do one
> confirming read of the `combatStrategies` / `randomBotCombatStrategies` config
> defaults and the CombatStrategy.h GetType to be complete about the first
> deref.

I have completed a thorough trace. Here is my analysis.

## Crash Analysis: PlayerbotAI constructor / Engine::Init null-deref

## (a) Most-likely faulting dereference and object

**The faulting object is the `Strategy* strategy` pulled from
`Engine::strategies` inside the `Engine::Init()` loop, and the read is a member
access through it that the -O2 debug-line table mislabels as
`PlayerbotAI::GetBot() PlayerbotAI.h:536`.**

The Init loop (`Engine.cpp:123-134`) dereferences `strategy` five ways per
iteration:
```
126  strategyTypeMask   |= strategy->GetType();            // virtual
127  hasTargetExclusions|= strategy->HasTargetExclusions();// virtual
128  strategy->InitMultipliers(multipliers);               // virtual
129  strategy->InitTriggers(triggers);                     // virtual
130  for (auto &iter : strategy->actionNodeFactories.creators)  // <-- frame #3 attributed here
```
`GetBot()` is `{ return bot; }` — a one-instruction load of `bot` at a fixed
offset from a `this`. Under `-O2 RelWithDebInfo` the compiler inlines these tiny
accessors and folds the loop; the PC→line map for the faulting load gets
pinned onto the inlined `GetBot` body and the enclosing frame onto `Init:130`.
The real fault is **a member load through a bad `this`** — either `strategy`
itself is bad, or `botAI` reached *through* the strategy is bad. It is not
literally line 130 copying an `unordered_map`.

Important negative results (all verified, not trusted):
- **Registration is intact and populated.** `BuildAllSharedContexts()` runs once
  at `PlayerbotAIConfig.cpp:750` before any login. `BuildSharedStrategyContexts`
  (`Bot/Engine/BuildSharedStrategyContexts.cpp`) adds `StrategyContext`,
  `MovementStrategyContext`, `AssistStrategyContext`, `QuestStrategyContext`,
  `DungeonStrategyContext`, `RaidStrategyContext`; every creator is `return new
  XxxStrategy(botAI)` (per-bot, non-null, no statics). So the user's "did we
  remove all the strategies?" theory is **disproven** — and an empty set would
  *no-op* the Init loop (`strategies.begin()==end()`), not crash.
- **A plain null in the map is not possible via the normal path.** `addStrategy`
  (`Engine.cpp:355`) only inserts under `if (Strategy* strategy =
  aiObjectContext->GetStrategy(name))`.
- **No uninitialized member.** `bot` is declared first (`PlayerbotAI.h:632`) and
  set in the initializer list; `aiObjectContext` is set at `PlayerbotAI.cpp:149`
  before `createCombatEngine` at line 151. The Player is fully in world
  (re-resolved via `ObjectAccessor::FindConnectedPlayer` in
  `OnBotLoginOperation::Execute`, `PlayerbotOperations.h:495`), and
  `GetPlayerSpecTab`/`GetTalentMap` already succeeded earlier in
  `AddDefaultCombatStrategies` before Init runs.
- **The construction path is single-threaded** (`WorldScript::OnUpdate →
  PlayerbotWorldThreadProcessor::Update → ProcessBatch`, main world thread).

## (b) Mechanism

**Dangling pointer, not null / not partial-init / not missing-registration.**

The strongest concrete mechanism is a **leaked-and-reused / double-login object
identity problem in `AddPlayerbotData`** (`PlayerbotMgr.cpp:1759-1767`):
```
1761  itr = _playerbotsAIMap.find(player->GetGUID());
1762  if (itr != _playerbotsAIMap.end())
1763      _playerbotsAIMap.erase(itr);   // erases map entry — does NOT delete the old PlayerbotAI
1766  PlayerbotAI* botAI = new PlayerbotAI(player);
```
When a bot GUID logs in while a prior `PlayerbotAI` for that GUID still exists,
the old object is orphaned (leaked) rather than deleted, and a *second*
`PlayerbotAI` is constructed on the **same live `Player*`**. Meanwhile the
destroy path is driven independently by `OnDestructPlayer → delete botAI`
(`Playerbots.cpp:312-317`) and by `LogoutPlayer` (`PlayerbotMgr.cpp:407`). If a
stale queued/second `OnBotLoginOperation` runs after (or interleaved with) a
logout/destruct for the same GUID, `new PlayerbotAI(player)` can run while the
corresponding `Player`/context teardown is in flight, so the freshly-created
engine's `strategies` map holds a strategy whose backing `AiObjectContext`
(`strategyContexts.created`, owned by that context, freed in `~AiObjectContext`)
has been torn down — a dangling `strategy` when `Init()` iterates it. Whether
the duplicate arises from a re-login (the leak at 1762) or a logout-in-flight,
the shape is the same: **`Engine::strategies` referencing a strategy owned by an
`AiObjectContext` that is being/has been destroyed.**

Secondary contributor to watch: `NamedObjectContextList::GetContextObject`
(`NamedObjectContext.h:205-214`) will *cache and return* whatever `create()`
yields, including `nullptr`, into `created[name]`; the only reason a null
doesn't reach the map is the guard in `addStrategy`. If any local patch ever
relaxed that guard or an unregistered name is requested, the same crash
signature appears via a genuine null.

## (c) Proposed fix location and shape

Primary guard — make `AddPlayerbotData` own the lifetime it displaces
(`PlayerbotMgr.cpp:1759-1768`):
```
itr = _playerbotsAIMap.find(player->GetGUID());
if (itr != _playerbotsAIMap.end())
{
    delete itr->second;          // <-- currently leaked; delete before erase
    _playerbotsAIMap.erase(itr);
}
```
and add a re-entrancy guard so a duplicate `OnBotLogin`/`AddPlayerbotData` for a
GUID already present is refused rather than reconstructed.
`PlayerbotHolder::OnBotLogin` already has a `playerBots.find` guard
(`PlayerbotMgr.cpp:471`); the `AddPlayerbotData` AI map needs the same "already
present → bail" semantics, and `OnBotLoginOperation::IsValid()`
(`PlayerbotOperations.h:519`) should additionally reject the case where a
`PlayerbotAI` already exists for the GUID.

Defense-in-depth (cheap, and pinpoints future recurrences): in `Engine::Init()`
add a null/validity check in the loop:
```
Strategy* strategy = i->second;
if (!strategy) continue;   // or LOG_ERROR with i->first and the bot name
```
This converts a hard segfault into a logged, survivable event and, if it ever
fires, prints the offending strategy *name* — the single most useful
diagnostic.

## (d) Confidence and the one confirming datum

**Confidence: medium (~60%) on the specific "dangling strategy via
duplicate/leaked PlayerbotAI" mechanism; high (~90%) that the fault is a bad
`strategy` pointer in the `Init` loop rather than a null-in-map or missing
registration.** The `-O2` line attribution is inherently fuzzy, and I could not
disassemble the binary (no build access) to read the exact member offset
`GetBot` loads.

**Single confirming piece of evidence to get, in priority order:**
1. **An `-O0` (or `-Og`) backtrace.** At `-O0`, `GetBot` won't be inlined and
   the frame will resolve to the actual line among `Engine.cpp:126-130` and show
   whether the bad pointer is `strategy` (frame in `Init`) or the strategy's
   `botAI` (frame stepping into a virtual override). This alone disambiguates
   dangling-vs-null-vs-vtable.
2. If a rebuild isn't feasible, in gdb at the crash frame print **`this`** (the
   `Strategy*`) and **`i->second`** for the current map entry, then `p
   *strategy` / `p strategy->_vptr` — a non-heap or poisoned
   (`0xdddddddd`-style) vtable pointer confirms *dangling*; a `0x0` confirms
   *null*.
3. Cross-check by logging in `AddPlayerbotData` whether the
   `_playerbotsAIMap.find` branch (line 1762, the duplicate case) is being hit
   right before crashes — if it is, the leaked/duplicate-construction
   mechanism is confirmed directly.

Key files: `Bot/Engine/Engine.cpp` (Init loop 118-142),
`Bot/Engine/NamedObjectContext.h` (GetContextObject 205-214 caches null),
`Bot/Engine/AiObjectContext.cpp` (per-bot `strategyContexts`, GetStrategy
106-109), `Bot/PlayerbotMgr.cpp` (AddPlayerbotData 1739-1769, OnBotLogin
468-536), `Bot/PlayerbotAI.cpp` (ctor 131-159, dtor 225-238),
`Script/WorldThr/PlayerbotOperations.h` (OnBotLoginOperation 484-524).

--------------------------------------------------------------------------------

