# Conversation Summary: agent-a9f7cdd533fd5b85d

Generated on: 2026-09-26 12:46:03
Models: claude-haiku-4-5-20251001

--------------------------------------------------------------------------------

### User Request 1

Research task in /mnt/mtwo/games/azeroth-core/wow-chat-2026 (a WoW 3.3.5a
AzerothCore private server project with mod-playerbots). Search breadth: very
thorough.

I need to know how to control the RANDOM BOT POPULATION of mod-playerbots AT
RUNTIME (without restarting the server), via server console commands (the kind
that can be sent through SOAP or the RA remote console).

Look in:
1. docs/playerbots/ — module documentation
2. source-beta/modules/mod-playerbots/ — the actual module source (look for
   the command table registration, e.g. files like PlayerbotCommandScript,
   RandomPlayerbotMgr, PlayerbotMgr, and config PlayerbotAIConfig)
3. installed-files-vanilla/etc/modules/playerbots.conf or the .dist version —
   config keys

Report:
A. The exact console command syntax for anything that changes the number of
active random bots at runtime (e.g. subcommands of "playerbots" / "npcbots" /
"rndbot" — things like setting MaxRandomBots live, adding/removing bots,
logging out bots). For each command: exact syntax, what it does, and whether it
works from the server console (not just in-game chat).
B. How the module decides to log bots IN and OUT over time (which config keys:
MinRandomBots, MaxRandomBots, RandomBotUpdateInterval, etc., and which manager
class enforces the band — cite file:line).
C. Any existing notion of "idle" bots in the module (bots not in combat, not in
a group with a real player, not in a dungeon) — how could one identify idle
bots from the outside (database tables like acore_playerbots tables, or commands
that list bots and their state).
D. Whether MaxRandomBots/MinRandomBots changes take effect via a config-reload
command (e.g. "reload config" / "playerbots reload") without restart — cite
evidence.

Return findings as structured notes with file:line citations. Raw data, no prose
padding.

--------------------------------------------------------------------------------

### Assistant Response 1

> I'll conduct a thorough search of the mod-playerbots module to answer your
> questions about runtime control of random bot population.

> Let me check the key documentation and source files.

> Now let me search for the console command registration and look at the key
> source files.

> Now let me find the RandomPlayerbotMgr implementation to see the actual
> command handling:

> Let me continue reading and also look at the UpdateAIInternal method:

> Now let me search for where the config keys are read and check the
> PlayerbotAIConfig:

> Let me search for minRandomBots and maxRandomBots in the config:

> Good! Now let me check the database schema and look for the event table that
> stores the bot_count:

> Now let me look for the SetEventValue and GetEventValue implementations:

> Excellent! Now let me check the database schema for the playerbots_random_bots
> table:

> Let me search for the playerbots_random_bots table definition:

> Perfect! Now let me check the randomBotCountChangeMinInterval and
> randomBotCountChangeMaxInterval to understand the timing:

> Let me look for the timing parameters:

> Now let me check for any database tables that track idle bots:

> Now let me look for "idle" or bot activity status tracking:

> Let me get more detail on idle bot definition:

> Perfect! Now let me look for how to check bot status from the database or
> commands. Let me also search for any documentation on Idle state:

> Now let me check the PlayerbotAIConfig for the minRandomBots and maxRandomBots
> initialization:

Perfect! Now I have all the information I need. Let me compile the findings:

## FINDINGS REPORT

**A. Console Command Syntax for Runtime Bot Population Control**

**File:**
`/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/Script/PlayerbotCommandScript.cpp:48`

Command registration:
```
{"rndbot", HandleRandomPlayerbotCommand, SEC_GAMEMASTER, Console::Yes},
```

Handler implementation:
`/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp:2367-2487`

**Available commands (from HandlePlayerbotConsoleCommand):**

1. `.playerbots rndbot stats` - Prints bot statistics (levels, classes, roles,
   zones)
   - Line 2391-2396: Calls `sRandomPlayerbotMgr.PrintStats()`

2. `.playerbots rndbot update` - Triggers full UpdateAIInternal() tick
   - Line 2404-2408: Processes bot logins/logouts and updates

3. `.playerbots rndbot reload` - Reloads playerbots.conf config file
   - Line 2398-2402: Calls `sPlayerbotAIConfig.Initialize()`

4. `.playerbots rndbot reset` - Clears playerbots_random_bots table (requires
   server restart)
   - Line 2383-2389: Deletes all random bot events from database

5. Batch bot manipulation commands (each accepts bot name pattern with wildcard
   `%`):
   - `.playerbots rndbot init [name]` - Re-rolls bot
   - `.playerbots rndbot clear [name]` - Resets bot to starting level
   - `.playerbots rndbot level[up] [name]` - Increases level by 1
   - `.playerbots rndbot refresh [name]` - Revives and resets, rerolls gear
   - `.playerbots rndbot teleport [name]` - Teleports to level-appropriate area
   - `.playerbots rndbot revive [name]` - BUGGED (doubles bot count)
   - `.playerbots rndbot grind [name]` - BUGGED (crashes server)
   - `.playerbots rndbot change_strategy [name]` - Re-rolls RPG/grinding split

**Works from server console:** YES - All use `Console::Yes` flag (line 48)

**B. How the Module Manages Bot Population (Min/Max)**

**Config keys:**
`/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/conf/playerbots.conf.dist:88-89`
```
AiPlayerbot.MinRandomBots = 500
AiPlayerbot.MaxRandomBots = 500
```

**Initialization:**
`/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/PlayerbotAIConfig.cpp:226-227`
```
minRandomBots = sConfigMgr->GetOption<int32>("AiPlayerbot.MinRandomBots", 500);
maxRandomBots = sConfigMgr->GetOption<int32>("AiPlayerbot.MaxRandomBots", 500);
```

**Manager that enforces the band:** `RandomPlayerbotMgr::UpdateAIInternal()` -
`/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp:283-464`

**How it works (lines 302-373):**
- Line 302: Reads current `maxAllowedBotCount` from event cache:
  `GetEventValue(0, "bot_count")`
- Lines 303-310: If invalid or out of range, picks random value between
  `minRandomBots` and `maxRandomBots`, stores in cache with TTL
  (randomBotCountChangeMinInterval to randomBotCountChangeMaxInterval)
- Lines 363-373: If current online count < maxAllowedBotCount, calls
  `AddRandomBots()` to login more
- Line 330: Sets next check delay based on update interval

**Related timing config keys:**
`/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/conf/playerbots.conf.dist:1360-1383`
```
AiPlayerbot.RandomBotUpdateInterval = 20 (seconds between update cycles)
AiPlayerbot.RandomBotCountChangeMinInterval = 1800 (min 30 min before recount)
AiPlayerbot.RandomBotCountChangeMaxInterval = 7200 (max 2 hours before recount)
AiPlayerbot.RandomBotsPerInterval = 60 (max bots to login/logout per cycle)
```

**Database table for state:**
`/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/data/sql/playerbots/base/playerbots_random_bots.sql`
```sql
playerbots_random_bots (id, owner, bot, time, validIn, event, value, data)
-- owner=0, bot=0, event="bot_count" stores the current MaxRandomBots live value
-- Bot lifecycle events: add, logout, randomize, teleport, dead, revive, etc.
```

**C. Idle Bot Definition & Identification**

**Definition:**
`/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp:1492-1505`
```cpp
// A bot is IDLE when it has no travel target or travel state is IDLE
bool idleBot = false;
if (TravelTarget* target = botAI->GetAiObjectContext()->GetValue<TravelTarget*>("travel target")->Get()) {
    if (target->getTravelState() == TravelState::TRAVEL_STATE_IDLE) {
        idleBot = true;
    }
}
else {
    idleBot = true;
}
```

**From outside (via console/database):**

1. **Bot activity status (active vs inactive):**
   `/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp:2746`
   - Query: `botAI->AllowActivity()` - returns true if bot is forced active per
     rules

2. **Forced-active rules (always stay active):**
   `/mnt/mtwo/games/azeroth-core/wow-chat-2026/docs/playerbots/Playerbot-Configuration.md:38-50`
   - Bot in battleground, instance, or raid
   - Bot in combat not in party
   - Real player in same zone
   - Bot in guild with real player
   - Real player is master
   - Real player leads group
   - In BG queue or LFG queue
   - Real player within 150 yards (configurable:
     AiPlayerbot.BotActiveAloneForceWhenInRadius)
   - Real player on friends list
   - More than 10 other bots within sight distance

3. **Database query for bot state:**
   `/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/data/sql/playerbots/base/playerbots_random_bots.sql`
   - Table: `acore_playerbots.playerbots_random_bots`
   - Query: `SELECT * FROM playerbots_random_bots WHERE owner=0 AND
     event='logout'` (logged-out bots)
   - Query: `SELECT * FROM playerbots_random_bots WHERE owner=0 AND event='add'`
     (pending login)
   - No dedicated "idle" column—idle status computed at runtime from bot state

4. **Command to list bot states:** `.playerbots rndbot stats` - outputs
   active/dead/combat/moving/mounted/resting bots

**D. Config Reload Without Restart**

**Command:** `.playerbots rndbot reload`

**Implementation:**
`/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp:2398-2402`
```cpp
if (cmd == "reload") {
    sPlayerbotAIConfig.Initialize();
    return true;
}
```

**Effect on MinRandomBots/MaxRandomBots:** YES, takes effect immediately

**How:**
1. `sPlayerbotAIConfig.Initialize()` re-reads all config keys from
   playerbots.conf (line 2400)
2. Calls `sConfigMgr->GetOption<int32>("AiPlayerbot.MinRandomBots", 500)` and
   `MaxRandomBots` again (PlayerbotAIConfig.cpp:226-227)
3. On next `UpdateAIInternal()` cycle (every `RandomBotUpdateInterval` seconds),
   the new min/max bounds are enforced (line 303-310 RandomPlayerbotMgr.cpp)

**Evidence:** The "reload" command does not require a server restart; it
directly calls the config initializer. Changes to `MinRandomBots` and
`MaxRandomBots` in the config file are picked up and applied within the next
update cycle (default 20 seconds).

**Caveat:** Changing only the config file without calling `reload` command has
NO effect—the in-memory config object (`sPlayerbotAIConfig`) must be
explicitly re-initialized.

--------------------------------------------------------------------------------

