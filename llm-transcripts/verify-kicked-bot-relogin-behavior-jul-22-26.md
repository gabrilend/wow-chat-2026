# Conversation Summary: agent-aa379971029da1f21

Generated on: 2026-09-26 12:46:04
Models: claude-haiku-4-5-20251001

--------------------------------------------------------------------------------

### User Request 1

Focused code-reading task in
/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/.
Search breadth: medium.

Context: An external tool will force-logout ("kick" via the core .kick command)
some RANDOM bots managed by RandomPlayerbotMgr, after first lowering
maxRandomBots/minRandomBots (via config reload) so the module's target count is
at or below the post-kick online count. I must know whether the module will
RE-LOGIN a kicked bot anyway.

Answer precisely, quoting code with file:line:

1. In src/Bot/RandomPlayerbotMgr.cpp, RandomPlayerbotMgr::ProcessBot(uint32 bot)
   (~line 1336+): walk EVERY branch. When the bot's "add" event is still valid
   (GetEventValue(bot,"add") != 0) but the Player is NOT online (kicked), does
   this function log the bot back in (AddPlayerBot / login call)? Quote the
   branch.

2. In UpdateAIInternal (~283-464): which set of bot ids does the ProcessBot loop
   iterate (currentBots? GetBots()?), and is that loop gated by onlineBotCount
   vs maxAllowedBotCount, or does it run regardless? Quote the loop and any
   gating around it (lines ~407-460).

3. When a bot's WorldSession is kicked/logged out externally, which
   mod-playerbots hook runs (search for OnPlayerLogout / OnLogout /
   LogoutPlayerBot in PlayerbotsMgr / PlayerbotsPlayerScript / PlayerbotMgr),
   and does anything remove the bot id from RandomPlayerbotMgr::currentBots or
   write a "logout" event? Quote it.

4. GetEventValue / SetEventValue (RandomPlayerbotMgr.cpp): does GetEventValue
   read from the database each call or from an in-memory cache (eventCache)?
   When is the cache loaded from the playerbots_random_bots table (server start
   only, or per lookup)? Quote the relevant code. I need to know whether an
   EXTERNAL sql UPDATE to playerbots_random_bots (e.g. expiring a bot's "add"
   event) would be observed by a running server.

5. AddRandomBots() (the function that logs bots in when below target): which
   candidate list does it draw from — does it prefer bots in currentBots,
   arbitrary ids from the random-bot account pool, or ids with valid "add"
   events? Could a just-kicked bot (still holding a valid "add" event) be chosen
   again? Quote key lines.

Return raw structured notes with file:line citations and short verbatim quotes.
No prose padding.

--------------------------------------------------------------------------------

### Assistant Response 1

> I'll conduct a thorough read-only search of the RandomPlayerbotMgr code to
> answer your questions precisely.

> Now let me read the main RandomPlayerbotMgr files:

> Now let me read more of RandomPlayerbotMgr.cpp, particularly around ProcessBot
> and the event cache functions:

> Let me continue reading to find OnPlayerLogout and related logout logic:

> Now let me read the OnPlayerLogout function:

> Now let me search for where the module script hooks are registered:

> Let me check the script hook:

> Perfect! Now let me verify the key facts with grep for the specific lines
> around AddPlayerBot and ProcessBot logic:

> Now let me look at the UpdateAIInternal loop around line 407-460:

> Perfect! Now let me check the AddRandomBots function more carefully,
> particularly around the "tryLoginBot" lambda and what checks happen before
> login:

> Excellent! Now let me search for where the event cache is loaded on startup to
> confirm when it's populated:

> Perfect. Now let me verify the OnPlayerbotLogout hook that was shown at line
> 460-472 in Playerbots.cpp:

> Good! Now let me check what OnPlayerLogout does to currentBots:

> Now let me verify what GetBots() does at the start of UpdateAIInternal:

Perfect! Now I have all the information I need. Let me compile my findings:

## FINDINGS

Based on my thorough code review of the RandomPlayerbotMgr module:

## 1. **ProcessBot(uint32 bot) - Re-login of kicked bots (lines 1336-1444)**

When a bot is kicked (Player not online but "add" event still valid):

**Line 1342-1361:** The function checks if `GetEventValue(bot, "add")` is
non-zero (still valid). If valid but Player is offline:
- **Line 1364-1387:** If `!player` (bot is not in world), it calls
  `AddPlayerBot(botGUID, 0)` at **line 1366**
- This DOES RE-LOGIN the bot regardless of kick

**Quote (line 1336-1387):**
```cpp
bool RandomPlayerbotMgr::ProcessBot(uint32 bot)
{
    ObjectGuid botGUID = ObjectGuid::Create<HighGuid::Player>(bot);
    Player* player = GetPlayerBot(botGUID);
    PlayerbotAI* botAI = player ? GET_PLAYERBOT_AI(player) : nullptr;

    uint32 isValid = GetEventValue(bot, "add");
    if (!isValid)
    {
        // ... logout logic ...
        return false;
    }

    uint32 randomTime;
    if (!player)
    {
        AddPlayerBot(botGUID, 0);  // <-- RE-LOGINS KICKED BOT
```

## 2. **UpdateAIInternal loop - which bots iterate (lines 283-464)**

The loop iterates over **`availableBots`**, which is populated at **line 313**
from `currentBots`:
```cpp
GetBots();                                    // line 312
std::list<uint32> availableBots = currentBots; // line 313
```

**Gating:** The loop runs **regardless** of onlineBotCount vs
maxAllowedBotCount. The first loop (lines 417-429) processes ONLINE bots; the
second loop (lines 439-451) processes OFFLINE bots to log them in.

**Quote (lines 312-451):**
```cpp
GetBots();
std::list<uint32> availableBots = currentBots;
uint32 availableBotCount = availableBots.size();
uint32 onlineBotCount = playerBots.size();

// ... gating applies only to loginBots calculation (406-412), not the loop itself ...

if (!availableBots.empty())
{
    // Update bots
    for (auto bot : availableBots)
    {
        if (!GetPlayerBot(bot))
            continue;
        if (ProcessBot(bot))
            updateBots--;
        if (!updateBots)
            break;
    }

    if (loginBots && botLoading.empty())
    {
        // Log in bots
        for (auto bot : availableBots)
        {
            if (GetPlayerBot(bot))
                continue;
            if (ProcessBot(bot))
                loginBots--;
            if (!loginBots)
                break;
        }
    }
}
```

## 3. **Module hooks for logout (Playerbots.cpp)**

When a bot's WorldSession is kicked/logged out externally:

**Hook: `OnPlayerbotLogout()` in Playerbots.cpp at line 460-473:**
```cpp
void OnPlayerbotLogout(Player* player) override
{
    // ...
    sRandomPlayerbotMgr.OnPlayerLogout(player);  // line 472
}
```

**Called function at RandomPlayerbotMgr.cpp line 2511-2532:**
```cpp
void RandomPlayerbotMgr::OnPlayerLogout(Player* player)
{
    DisablePlayerBot(player->GetGUID());
    // ... resets master for other bots ...
    std::vector<Player*>::iterator i = std::find(players.begin(), players.end(), player);
    if (i != players.end())
        players.erase(i);
}
```

**CRITICAL:** This hook does **NOT** remove the bot from `currentBots` or set a
"logout" event. The bot's "add" event remains valid.

## 4. **GetEventValue/SetEventValue - cache behavior (lines 2222-2346)**

**Event cache behavior:**

**FindEvent (lines 2222-2269):** The cache is per-bot and **loads on first
access**:
```cpp
CachedEvent* RandomPlayerbotMgr::FindEvent(uint32 bot, std::string const& event)
{
    BotEventCache& cache = eventCache[bot];
    
    // Load once
    if (!cache.loaded)
    {
        cache.events.clear();
        PlayerbotsDatabasePreparedStatement* stmt = ...
        if (PreparedQueryResult result = PlayerbotsDatabase.Query(stmt))
        {
            do
            {
                // ... populate cache from playerbots_random_bots table ...
                cache.events.emplace(fields[0].Get<std::string>(), std::move(e));
            } while (result->NextRow());
        }
        cache.loaded = true;  // line 2252
    }
```

**Cache load timing:** 
- **NOT** on server start
- **Per-lookup** - the cache for a specific bot_id loads the FIRST time
  `GetEventValue(bot_id, ...)` is called
- Once loaded (`cache.loaded = true`), subsequent calls for that bot use the
  in-memory cache
- Expired events are removed from cache (line 2264), but DB is only re-queried
  if cache.loaded is false

**Result:** An external SQL UPDATE to `playerbots_random_bots` while the server
runs will **NOT** be observed by a running server if that bot's cache has
already been loaded. The cache persists until the bot is reset or the server
reloads (line 2386 shows `eventCache.clear()` only happens on `rndbot reset`
command).

## 5. **AddRandomBots() - candidate selection (lines 639-820)**

The function draws from **arbitrary ids from the random-bot account pool**, NOT
from currentBots or bots with valid "add" events.

**tryLoginBot lambda at lines 737-758:**
```cpp
auto tryLoginBot = [&](const CharacterInfo& charInfo) -> bool
{
    if (GetEventValue(charInfo.guid, "add") ||      // line 739: REJECT if "add" exists
        GetEventValue(charInfo.guid, "logout") ||
        GetPlayerBot(charInfo.guid) ||
        std::find(currentBots.begin(), currentBots.end(), charInfo.guid) != currentBots.end() ||
        (sPlayerbotAIConfig.disableDeathKnightLogin && charInfo.rClass == CLASS_DEATH_KNIGHT))
    {
        return false;  // line 745
    }

    SetEventValue(charInfo.guid, "add", 1, add_time);  // line 753: Creates new "add" event
    SetEventValue(charInfo.guid, "logout", 0, 0);      // line 754: Clears "logout"
    currentBots.push_back(charInfo.guid);              // line 755: Adds to list
    return true;
};
```

**Key point:** AddRandomBots **explicitly rejects** (line 739) any bot that
already has a valid "add" event. A just-kicked bot holding a valid "add" event
**cannot be chosen again**.

However, characters are iterated from a freshly-loaded list (lines 699-734 fetch
all chars from selected accounts), so if no "add" event exists, the bot could be
chosen. But a kicked bot still holding its "add" event is immune to re-selection
via AddRandomBots.

---

## SUMMARY

**Will a kicked bot re-login?**

**YES**. The module will re-login a kicked bot via `ProcessBot()` at line 1366
(`AddPlayerBot(botGUID, 0)`), because:
1. The bot's "add" event remains valid after external kick (no hook clears it)
2. ProcessBot checks only `GetEventValue(bot, "add")` validity, not actual
   online status
3. If valid and offline, it logs back in unconditionally

**To prevent re-login:** The external tool must either:
- Expire the bot's "add" event (SQL UPDATE playerbots_random_bots SET
  valid_in=0)
- Clear the event cache (SQL DELETE or set lastChangeTime < NowSeconds)
- Call `SetEventValue(bot, "add", 0, 0)` from code

**Cache persistence:** External SQL changes are invisible to the running server
until that bot's cache expires or is explicitly cleared.

--------------------------------------------------------------------------------

