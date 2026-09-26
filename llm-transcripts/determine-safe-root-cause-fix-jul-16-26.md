# Conversation Summary: agent-ae7d02e6abc8071bc

Generated on: 2026-09-26 12:46:01
Models: claude-opus-4-8

--------------------------------------------------------------------------------

### User Request 1

READ-ONLY lifecycle analysis in /mnt/mtwo/games/azeroth-core/wow-chat-2026
(mod-playerbots at source-beta/modules/mod-playerbots/src). Goal: determine the
SAFE root-cause fix for a dangling-pointer crash so it can be applied in ONE
compilation (no build-twice loop). Do NOT edit anything.

THE BUG (already traced, medium confidence): PlayerbotsMgr::AddPlayerbotData
(Bot/PlayerbotMgr.cpp:1739-1769), the isBotAI branch:
    itr = _playerbotsAIMap.find(player->GetGUID());
    if (itr != _playerbotsAIMap.end())
        _playerbotsAIMap.erase(itr);      // erases the entry but NEVER deletes the old PlayerbotAI (leak)
    PlayerbotAI* botAI = new PlayerbotAI(player);   // a SECOND PlayerbotAI on the same live Player
This is suspected to leave a fresh engine's `strategies` map referencing a
Strategy owned by an AiObjectContext being torn down → dangling read in
Engine::Init.

I need to decide between two candidate fixes and confirm the SAFE one:
  (A) delete itr->second BEFORE erase (fix the leak + reclaim the old AI), or
  (B) refuse-duplicate: if an AI already exists for the GUID, bail without
  reconstructing.

ANSWER THESE with file:line evidence:

1. DOUBLE-FREE SAFETY OF (A): Read the PlayerbotAI destruction paths —
   PlayerbotHolder::LogoutPlayer (Bot/PlayerbotMgr.cpp around 407),
   OnDestructPlayer / the delete-botAI site in
   modules/mod-playerbots/src/Playerbots.cpp (around 312), and the second
   `_playerbotsAIMap.erase(itr)` at ~PlayerbotMgr.cpp:1778 (what function is
   that, and does it delete?). Determine: do these deletion paths obtain the
   PlayerbotAI pointer FROM _playerbotsAIMap (so once AddPlayerbotData erases
   the entry, nothing can re-find and re-delete it → delete-before-erase is
   safe), or do they hold/cache the pointer elsewhere (e.g., a Player member set
   in the PlayerbotAI ctor) that would dangle if AddPlayerbotData deletes it?

2. Does the Player object hold a raw back-pointer to its PlayerbotAI? Look at
   GET_PLAYERBOT_AI / PlayerbotsMgr::GetPlayerbotAI and the PlayerbotAI
   constructor/destructor — is the AI stored ONLY in _playerbotsAIMap, or also
   on the Player (a member/holder) that other code dereferences? This decides
   whether deleting the old AI dangles anything.

3. CORRECTNESS OF (B): Does a bot's PlayerbotAI persist across logout, or is it
   deleted on logout (so on a normal relogin the map is already empty and the
   duplicate branch is only hit in the racy/erroneous case)? Trace
   LogoutPlayer/OnDestructPlayer to see if they erase the AI map entry. If they
   do, then reaching the duplicate branch in AddPlayerbotData means a genuine
   double-add (bug) and bailing (B) is safe/correct; if they DON'T, keeping a
   stale AI via (B) would be wrong.

4. CAN THE DUPLICATE EVEN HAPPEN? Read Script/WorldThr/PlayerbotOperations.h
   (OnBotLoginOperation::Execute ~484-524, IsValid ~519) and
   PlayerbotWorldThreadProcessor (QueueOperation/ProcessBatch) — can two
   OnBotLoginOperation for the same GUID be queued, or one run while a
   logout/destruct for that GUID is pending? Is there any existing dedupe?

5. RECOMMENDATION: State the single SAFEST fix (or safe combination) with the
   EXACT C++ to insert and where, that resolves the dangling without risking a
   double-free/use-after-free, suitable to ship in one build. If neither (A) nor
   (B) is provably safe from static reading, say so and give the minimal
   defensive change that is.

Be concise, decisive, evidence-based (quote file:line).

--------------------------------------------------------------------------------

### Assistant Response 1

> I'll analyze the PlayerbotAI lifecycle to determine the safe fix. Let me start
> by reading the key files.

> Playerbots.cpp is at a different path than the prompt stated. Let me find the
> actual files.

> Found them. Let me read the key files: Playerbots.cpp (OnDestructPlayer), the
> operations header, the world thread processor, and the GET_PLAYERBOT_AI macro
> definition.

> Now let me read OnBotLogin (which calls AddPlayerbotData), the
> GET_PLAYERBOT_AI macro, the PlayerbotAI constructor/destructor, and the world
> thread processor's queue/dedupe logic.

> Now let me read the critical pieces: GetPlayerbotAI/GetPlayerbotMgr (already
> saw GetPlayerbotAI at 1791), the OnBotLogin function, the PlayerbotAI
> constructor/destructor, and check whether Player holds any back-pointer.

> Now I have OnBotLogin. Key finding: at line 471, OnBotLogin already dedupes
> via `playerBots`, but that guards the `playerBots` map, not
> `_playerbotsAIMap`. Let me check the PlayerbotAI constructor/destructor for a
> Player back-pointer, and GetPlayerbotMgr.

> Player.h has NO PlayerbotAI member — confirming the AI is stored ONLY in
> `_playerbotsAIMap`. Let me read the ctor/dtor to confirm no other caching, and
> check the world thread processor for dedupe.

> This is the crucial finding. The destructor at line 236-237: `if (bot)
> PlayerbotsMgr::instance().RemovePlayerBotData(bot->GetGUID(), true);` — the
> dtor itself erases the map entry by GUID. This is the key to double-free
> analysis. Let me now check the world thread processor for dedupe, and verify
> the OnDestructPlayer path fully.

> Confirmed: the queue is a plain FIFO with NO dedupe by GUID. Two
> `OnBotLoginOperation`s for the same GUID can both be queued and both pass
> `IsValid()` (which only checks the player is connected). So a duplicate add is
> possible.
>
> Now let me verify: does `OnBotLogin`'s `playerBots` guard (line 471) actually
> protect against the duplicate reaching `AddPlayerbotData`? And critically —
> is the same `PlayerbotHolder` used for both operations? If two operations
> resolve to the same holder, the `playerBots.find` guard blocks the second. Let
> me check whether RandomPlayerbotMgr and per-master PlayerbotMgr share
> `playerBots`, and confirm `IsValid`/`FindConnectedPlayer` for the duplicate
> scenario. Let me also double-check the `_playerbotsAIMap` is shared (single
> `PlayerbotsMgr` singleton) while `playerBots` is per-holder.

> Confirmed the architecture:
> - `_playerbotsAIMap` is a member of the SINGLETON `PlayerbotsMgr` — global,
>   single copy for all bots.
> - `playerBots` is per-`PlayerbotHolder` (each `PlayerbotMgr` and the
>   `RandomPlayerbotMgr` has its own).
>
> So the `OnBotLogin` guard at line 471 (`playerBots.find`) only dedupes within
> ONE holder. Two operations resolving to DIFFERENT holders (e.g., one to
> RandomPlayerbotMgr, one to a master's PlayerbotMgr) would each pass their own
> `playerBots` guard and both reach `AddPlayerbotData` on the shared singleton
> map — the exact duplicate path. Let me verify the second erase path
> (RemovePlayerBotData already read at 1771) does NOT delete, and confirm
> LogoutPlayer deletes the AI. Let me check LogoutPlayer around 340-410 for the
> actual delete site, and how the bot Player dtor triggers OnDestructPlayer.

Now I have the complete picture. `OnDestructPlayer` is called from
`Player::~Player()` at line 429-431, and it calls `GetPlayerbotAI(player)`
(which reads from `_playerbotsAIMap`) then deletes it. This confirms all
deletion paths obtain the pointer FROM the map.

Let me verify one last thing: the `RemovePlayerBotData` at 1778 does NOT delete
(only erases), and confirm `LogoutPlayer(true)` in the WorldSession is what
destroys the bot Player (triggering the dtor → OnDestructPlayer). I have
enough evidence. Let me confirm the second erase context and the delete-in-dtor
interaction once more by re-reading RemovePlayerBotData — already have it
(lines 1771-1789): it only `erase`s, never `delete`s.

I now have complete evidence for all five questions.

## Analysis Complete — Findings

All file paths below are under
`/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/`.

## The ownership model (foundation for everything)

- **`_playerbotsAIMap` is the SOLE owner** of every `PlayerbotAI*`. It lives on
  the singleton `PlayerbotsMgr` (`Bot/PlayerbotMgr.h:124`, single instance via
  `instance()` at `:102-104`). One global copy for all bots.
- **The `Player` object holds NO back-pointer to its `PlayerbotAI`.**
  `GET_PLAYERBOT_AI(player)` (`Script/Playerbots.h:31`) is a macro for
  `sPlayerbotsMgr.GetPlayerbotAI(player)`, which does
  `_playerbotsAIMap.find(player->GetGUID())` (`Bot/PlayerbotMgr.cpp:1801-1806`).
  There is no `PlayerbotAI*` member on `Player` (confirmed: grep of `Player.h`
  finds none). Every accessor in the codebase reaches the AI through this map
  lookup.
- The `PlayerbotAI` ctor (`Bot/PlayerbotAI.cpp:131-138`) stores only `bot` (the
  `Player*`); it does NOT register itself anywhere except by the caller
  emplacing it into the map at `Bot/PlayerbotMgr.cpp:1767`.

## Q1 — Double-free safety of (A): SAFE

Every deletion path obtains the pointer FROM `_playerbotsAIMap`, so once
`AddPlayerbotData` erases the entry, nothing can re-find and re-delete the old
object:

- **`OnDestructPlayer`** (`Script/Playerbots.cpp:312-321`, fired from
  `Player::~Player()` at `src/server/game/Entities/Player/Player.cpp:429-431`):
  `botAI = GetPlayerbotAI(player)` → map lookup → `delete botAI`. If the
  entry was already erased, it gets `nullptr` and does nothing.
- **`LogoutPlayer`** (`Bot/PlayerbotMgr.cpp:401-409`): does NOT delete the AI
  directly — it calls `botWorldSessionPtr->LogoutPlayer(true)` which destroys
  the bot `Player`, and the `Player` dtor fires `OnDestructPlayer` (the path
  above). So still map-sourced.
- **`DisablePlayerBot`** (`:417, :446`): `botAI = GET_PLAYERBOT_AI(bot)` → map
  lookup → `delete botAI`. Map-sourced.
- **The second `_playerbotsAIMap.erase(itr)` at `:1778`** is
  `PlayerbotsMgr::RemovePlayerBotData` (`:1771-1789`). It only `erase`s the map
  slot — it never `delete`s. It is called *by the `~PlayerbotAI` destructor
  itself* (`Bot/PlayerbotAI.cpp:236-237`) to self-unregister.

Critical mechanism making (A) safe: **the `~PlayerbotAI` destructor calls
`RemovePlayerBotData(bot->GetGUID(), true)` (`Bot/PlayerbotAI.cpp:236-237`),
which erases the entry.** So `delete itr->second` inside `AddPlayerbotData`
triggers an erase-by-GUID of the same slot. Order matters — see Q5.

No path caches the pointer on the `Player` or elsewhere. **(A) cannot
double-free.**

## Q2 — Player back-pointer: NONE

Confirmed above. The AI is stored ONLY in `_playerbotsAIMap`. Deleting the old
AI dangles nothing, because no other object holds the raw pointer — every
consumer re-looks-up by GUID at use time.

## Q3 — Correctness of (B): the AI IS deleted on logout, so the map is normally empty on relogin

- Normal logout destroys the bot `Player` (`LogoutPlayer(true)` at
  `Bot/PlayerbotMgr.cpp:407`) → `~Player` → `OnDestructPlayer` → `delete
  botAI` → `~PlayerbotAI` → `RemovePlayerBotData` erases the map entry
  (`Bot/PlayerbotAI.cpp:236-237`).
- Therefore reaching the duplicate branch in `AddPlayerbotData` (`:1761-1765`)
  means a genuine double-add on a still-live Player — a bug state, not a
  normal relogin. So **(B)'s premise (bail on duplicate) is not semantically
  wrong** — but see Q5 for why (B) alone is weaker.

## Q4 — Can the duplicate happen? YES, and the existing guard has a hole

- The world-thread queue (`Script/WorldThr/PlayerbotWorldThreadProcessor.cpp`)
  is a plain FIFO with **NO GUID dedupe**. `QueueOperation` (`:35-68`) just
  pushes; `ProcessBatch` (`:70-158`) pops and runs. Two `OnBotLoginOperation`
  for the same GUID can both be queued.
- `OnBotLoginOperation::IsValid()` (`Script/WorldThr/PlayerbotOperations.h:519`)
  only checks `FindConnectedPlayer(m_botGuid) != nullptr` — it does NOT check
  whether an AI already exists. Both duplicates pass.
- There IS a partial dedupe: `OnBotLogin` bails if
  `playerBots.find(bot->GetGUID())` hits (`Bot/PlayerbotMgr.cpp:471-474`). **But
  `playerBots` is per-`PlayerbotHolder`** (`Bot/PlayerbotMgr.h:60`), while
  `_playerbotsAIMap` is the global singleton. `OnBotLoginOperation::Execute`
  (`PlayerbotOperations.h:492-513`) resolves `holder` to *either*
  `RandomPlayerbotMgr::instance()` *or* a specific master's `PlayerbotMgr`
  depending on `m_masterAccountId` and master presence. **Two operations that
  resolve to different holders each pass their own `playerBots` guard and both
  call `AddPlayerbotData` on the shared map** — the exact
  duplicate-construction path. This is the realistic trigger (e.g., a bot
  transitioning between random-pool and a master, or a racy
  master-login/logout).

## Q5 — RECOMMENDATION: ship the combination (A) + a dedupe guard, in one build

Neither (A) nor (B) alone is ideal:
- **(A) alone** fixes the leak and the dangling read but has one ORDER TRAP:
  because `~PlayerbotAI` calls `RemovePlayerBotData` which erases by GUID
  (`Bot/PlayerbotAI.cpp:236-237`), you must `delete` the old AI **while it is
  still the map's entry, then let its own dtor do the erase** — do NOT
  `erase(itr)` first and then `delete`, and do NOT `delete` a copy after
  erasing, or you fight the self-unregister. Cleanest: delete first, let the
  dtor erase, then re-find/emplace.
- **(B) alone** stops the crash but silently keeps a stale AI bound to a
  possibly-different holder, and leaks nothing new but masks the root cause.

**Safest single-build fix — make `AddPlayerbotData`'s isBotAI branch
delete-then-reconstruct, respecting the self-erasing dtor.** Replace the isBotAI
branch (`Bot/PlayerbotMgr.cpp:1761-1767`):

```cpp
    else
    {
        // The PlayerbotAI destructor self-unregisters from _playerbotsAIMap
        // (see PlayerbotAI::~PlayerbotAI -> RemovePlayerBotData), so delete the
        // stale AI FIRST and let its dtor erase the slot. Erasing the iterator
        // ourselves before delete would leave the dtor erasing an already-gone
        // key (harmless) but risks a leaked engine/context if we ever stopped
        // deleting. A duplicate here means a double-add (two OnBotLoginOperations
        // resolving to different holders) - reclaim, don't leak, don't dangle.
        std::unordered_map<ObjectGuid, PlayerbotAIBase*>::iterator itr = _playerbotsAIMap.find(player->GetGUID());
        if (itr != _playerbotsAIMap.end())
        {
            PlayerbotAIBase* stale = itr->second;
            delete stale;                       // ~PlayerbotAI erases its own map slot by GUID
            _playerbotsAIMap.erase(player->GetGUID());  // idempotent: no-op if dtor already erased
        }
        PlayerbotAI* botAI = new PlayerbotAI(player);
        ASSERT(_playerbotsAIMap.emplace(player->GetGUID(), botAI).second);
    }
```

The trailing `erase(player->GetGUID())` is a belt-and-suspenders idempotent
no-op (the base `PlayerbotAIBase` dtor may not run `RemovePlayerBotData` if the
object were ever constructed via the `PlayerbotMgr` side; here it is always a
`PlayerbotAI`, whose dtor does erase — so the explicit erase just guarantees
the slot is clear before `emplace`, keeping the `ASSERT` valid).

Apply the identical delete-before-reconstruct pattern to the `!isBotAI`
(`PlayerbotMgr`) branch at `:1749-1755` for symmetry (it has the same leak),
though the crash you traced is the AI branch.

This one change: (1) plugs the leak, (2) reclaims the old
engines/`AiObjectContext` (`Bot/PlayerbotAI.cpp:225-234`) so no stale
`Strategy`/context is left half-torn-down for `Engine::Init` to read, and (3)
keeps the map single-owner and consistent. It is provably free of double-free
from static reading because the pointer exists in exactly one place and the
dtor's self-erase is idempotent with the explicit erase.

If you want defense-in-depth without touching lifecycle, additionally
short-circuit `OnBotLoginOperation::IsValid()` (`PlayerbotOperations.h:519`) to
also skip when an AI already exists — but that is optional hardening, not
required for the fix.

--------------------------------------------------------------------------------

