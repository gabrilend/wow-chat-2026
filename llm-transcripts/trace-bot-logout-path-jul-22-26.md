# Conversation Summary: agent-afca1dacd0fa59d99

Generated on: 2026-09-26 12:46:04
Models: claude-haiku-4-5-20251001

--------------------------------------------------------------------------------

### User Request 1

Focused code-reading task in
/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/.
Search breadth: medium.

Context: RandomPlayerbotMgr::UpdateAIInternal() in
src/Bot/RandomPlayerbotMgr.cpp (~lines 283-464) enforces a bot population band.
AddRandomBots() logs bots in when online < target. I need the LOGOUT side.

Questions:
1. In UpdateAIInternal (or functions it calls), what happens when the number of
   online random bots EXCEEDS the allowed count (maxAllowedBotCount)? Which
   function logs out the excess (name + file:line)? How many per cycle?
2. Around src/Bot/RandomPlayerbotMgr.cpp:1492-1505 there is an "idleBot" check
   using TravelTarget / TRAVEL_STATE_IDLE. What function contains this code,
   what does it do with idle bots (e.g. prefer them for logout), and under what
   conditions is it called? Quote the surrounding logic.
3. Is there a console-capable command to force-logout a SPECIFIC bot by name?
   Check src/Script/PlayerbotCommandScript.cpp for the full command table (all
   subcommands and their Console::Yes/No flags), and check whether "playerbots
   bot remove <name>" works from the console for random bots that have no
   master. Cite the handler (PlayerbotMgr / PlayerbotHolder LogoutPlayerBot
   etc.) file:line.
4. What per-bot event TTLs govern how long a random bot stays in-world before
   cycling out ("add" event / randomBotInWorldTime or similar config keys)? Cite
   file:line and config key names + defaults.

Return raw structured notes with file:line citations, quoting the relevant code
blocks briefly.

--------------------------------------------------------------------------------

### Assistant Response 1

> I'll conduct a focused search of the RandomPlayerbotMgr system to answer your
> questions about bot population management, idle bot handling, logout
> mechanics, and bot lifetime configuration.

> Now let me search for the specific functions and configurations you asked
> about:

> Let me get the full UpdateAIInternal function and search for bot removal
> logic:

> Now let me search for the bot removal/logout logic when exceeding
> maxAllowedBotCount:

> Let me search more broadly for logout mechanisms:

> Let me search for ProcessBot and the idle bot function:

> Now let me search for the function name containing this code:

> Now let me search for the command script for bot removal:

> Now let me check PlayerbotMgr for the command handler:

> Now let me search for configuration keys related to bot TTLs and event
> timings:

> Now let me search for the event handling and how "add" event works:

> Now let me look at SetEventValue and GetEventValue to understand the event
> system:

> Now let me check if there's logic to logout bots when they exceed the maximum:

> Let me search more carefully for excess bot logout logic:

> Let me check the PlayerbotMgr file for logout functions:

> Now let me check for any mechanism that automatically logs out excess bots.
> Let me look at UpdateAIInternal more carefully for any logout logic:

> Now let me look at configuration defaults to find the time-to-live settings:

> Perfect! Now let me check the header file to see all the timeout-related
> fields:

> Now let me search for the RandomBotCommandScript to confirm console
> capabilities:

> Let me check what the rndbot command provides:

> Now let me check if there's command for specific bot removal in PlayerbotMgr
> console handler:

> The usage message shows "add/remove" but let me check if they're actually
> implemented:

> The console command doesn't appear to support specific add/remove. Let me
> confirm what commands are supported through playerbots bot command:

> Perfect! Now I have the information. Let me check if there's any automatic
> excess bot removal:

> Let me check the header for LogoutAllBots and see if there's an excess removal
> function:

> Let me search for the method declarations in the header:

> Perfect! Let me check the full header section around ProcessBot:

Excellent! Now I have comprehensive information. Let me create a summary with
all the findings:

## Focused Code Search Report: RandomPlayerbotMgr Bot Population Management

## Question 1: Excess Bot Logout Logic

**Finding:** There is NO automatic mechanism to log out excess bots when
`onlineBotCount > maxAllowedBotCount`.

**Analysis:**
- `/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp:283-464`
  (`UpdateAIInternal`) contains the main population control loop.
- Lines 302-310: Reads or randomizes `maxAllowedBotCount` from event cache.
- Lines 315, 407-411: Only checks if `onlineBotCount < maxAllowedBotCount` to
  trigger login via `AddRandomBots()`.
- Lines 363-373: Only calls `AddRandomBots()` when below threshold; no logout
  logic when above.
- The function processes bots via `ProcessBot(bot)` (lines 417-429, 439-451) but
  this is for updates, not excess removal.

**Conclusion:** Excess bots remain logged in until they naturally logout via the
"logout" event TTL (see Question 4). There is no active trimming of excess
population.

---

## Question 2: Idle Bot Check & Preferred Logout Logic

**Function:** `bool RandomPlayerbotMgr::ProcessBot(Player* bot)`  
**File:Line**
`/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp:1446-1564`

**Idle Bot Logic (lines 1492-1561):**

```cpp
// only randomize and teleport idle bots
bool idleBot = false;
if (TravelTarget* target = botAI->GetAiObjectContext()->GetValue<TravelTarget*>("travel target")->Get())
{
    if (target->getTravelState() == TravelState::TRAVEL_STATE_IDLE)
    {
        idleBot = true;
    }
}
else
{
    idleBot = true;  // No travel target => idle
}

if (idleBot)
{
    // Randomize bot (lines 1508-1540)
    // Teleport bot (lines 1550-1560)
}
```

**What it does with idle bots:**
- Randomizes appearance/gear if event timer `"randomize"` expires (line
  1509-1540, calls `Randomize(bot)`)
- Teleports to random zone if event timer `"teleport"` expires (line 1550-1560,
  calls `RandomTeleportForLevel(bot)`)
- Does NOT prefer idle bots for logout; idle detection is used for activity
  cycling, not removal

**When called:** Every cycle in `UpdateAIInternal` via `ProcessBot()` loop
(lines 417-429) for bots that are online.

**Conditions:** Only executed if bot has `TRAVEL_STATE_IDLE` or no travel target
defined.

---

## Question 3: Force-Logout Command by Name (Console & In-Game)

**Command Available:** YES, for in-game players; **NO, NOT from console for
random bots by name**

### In-Game Command (for Masters or GMMs):
```
/playerbots bot remove <BOTNAME>
```
**Handler:** `PlayerbotHolder::ProcessBotCommand()`  
**File:Line:**
`/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/Bot/PlayerbotMgr.cpp:715-725`

```cpp
else if (cmd == "remove" || cmd == "logout" || cmd == "rm")
{
    if (!ObjectAccessor::FindPlayer(guid))
        return "player is offline";

    if (!GetPlayerBot(guid))
        return "not your bot";  // Rejects random bots (no master)

    LogoutPlayerBot(guid);
    return "ok";
}
```

**Logout Implementation:** `PlayerbotHolder::LogoutPlayerBot(ObjectGuid guid)`  
**File:Line:**
`/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/Bot/PlayerbotMgr.cpp:349-411`

**Console Commands for Random Bots:**
- **Available:** `/playerbots rndbot <command>` is `Console::Yes` (line 48 of
  PlayerbotCommandScript.cpp)
- **Subcommands:** `stats`, `update`, `reset`, `init`, `refresh`, `teleport`,
  `revive`, `grind`, `levelup`, `clear`, `change_strategy`
- **NO specific bot removal subcommand** — the usage message (line 2377) lists
  "add/remove" but they're not actually implemented in the handler.

**File:Line:**
`/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp:2367-2487`
(HandlePlayerbotConsoleCommand)

**Conclusion:**
- `playerbots bot remove <name>` works in-game for player-owned bots only
  (checks `GetPlayerBot(guid)` at line 720), **not for random bots** (which have
  no master).
- No console command exists to force-logout a specific random bot by name.

---

## Question 4: Per-Bot Event TTLs Governing Logout Cycle

**Primary TTL: `"add"` Event Validity Period**

**Config Keys & Defaults:**
```cpp
AiPlayerbot.MinRandomBotInWorldTime = 2 * HOUR       (7200 seconds)
AiPlayerbot.MaxRandomBotInWorldTime = 14 * 24 * HOUR (1209600 seconds)
AiPlayerbot.PermanentlyInWorldTime  = 1 * YEAR       (31536000 seconds, if periodic on/off disabled)
```

**File:Line:**
`/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/PlayerbotAIConfig.cpp:233-246`

**How TTL is Set:**

1. **At login:**
   `/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp:748-754`
```cpp
uint32 add_time = sPlayerbotAIConfig.enablePeriodicOnlineOffline
                    ? urand(sPlayerbotAIConfig.minRandomBotInWorldTime,
                            sPlayerbotAIConfig.maxRandomBotInWorldTime)
                    : sPlayerbotAIConfig.permanentlyInWorldTime;

SetEventValue(charInfo.guid, "add", 1, add_time);  // set "add" event to valid for add_time seconds
SetEventValue(charInfo.guid, "logout", 0, 0);     // clear any prior logout event
```

2. **At logout check:**
   `/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp:1336-1361`
```cpp
bool RandomPlayerbotMgr::ProcessBot(uint32 bot)
{
    ...
    uint32 isValid = GetEventValue(bot, "add");  // line 1342
    if (!isValid)
    {
        if (!player || !player->GetGroup())
        {
            // Log out bot (lines 1347-1357)
            LogoutPlayerBot(botGUID);
        }
        return false;
    }
    ...
}
```

3. **Secondary TTL for "logout" event:**
   `/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp:1431-1441`
```cpp
uint32 logout = GetEventValue(bot, "logout");
if (player && !logout && !isValid)
{
    LOG_DEBUG("playerbots", "Bot #{} {}:{} <{}>: log out", ...);
    LogoutPlayerBot(botGUID);
    currentBots.remove(bot);
    SetEventValue(bot, "logout", 1,
                  urand(sPlayerbotAIConfig.minRandomBotInWorldTime, 
                        sPlayerbotAIConfig.maxRandomBotInWorldTime));
    return true;
}
```

**Other Related TTLs:**
- `minRandomBotRandomizeTime` / `maxRandomBotRandomizeTime` (lines 235-236):
  Controls when idle bot is re-randomized (default 2hr–14d)
- `minRandomBotTeleportInterval` / `maxRandomBotTeleportInterval` (lines
  243-244): Controls teleport refresh cycle (default 1hr–5hr)
- `minRandomBotReviveTime` / `maxRandomBotReviveTime` (lines 241-242): Dead bot
  revival delay (default 1min–5min)

**File:Line Summary:**
- Config defaults:
  `/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/PlayerbotAIConfig.cpp:233-246`
- Config keys:
  `/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/PlayerbotAIConfig.h:155-160`
- TTL applied at login:
  `/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp:748-754`
- TTL checked at cycle:
  `/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp:1342-1361`

--------------------------------------------------------------------------------

