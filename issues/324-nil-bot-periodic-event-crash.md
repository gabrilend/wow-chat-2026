# 324 - Nil Bot Periodic Event Crash

## Status
- Created: 2026-04-08
- Phase: 2
- Priority: High

## Root Cause (IDENTIFIED)

**Playerbots do not trigger `PLAYER_EVENT_ON_LOGIN` (event 3).**

The playerbots module logs bots in through its own C++ code path (autologin, random bots), which does not call the ALE Lua hooks. This means `InitialLogin` in `periodic_events.lua` is never called for bots.

Evidence:
- `[PeriodicEvents] Registered behavior events for bot:` message never appears in Server.log
- Bots log in and stand at spawn position doing nothing
- Global `CreateLuaEvent` timers (like `Gestures.proximityCheck`) iterate `GetPlayersInWorld()` which includes bots
- When those timers try to call methods on bot references that were never initialized, they fail

## Current Behavior

Multiple Lua behavior scripts crash with:
```
lua_scripts/custom/behaviors/find-monsters.lua:28: attempt to call method 'GetPosition' (a nil value)
lua_scripts/custom/behaviors/gestures.lua:73: attempt to call method 'GetPosition' (a nil value)
lua_scripts/custom/behaviors/bot-wander.lua:275: attempt to call method 'GetPosition' (a nil value)
```

The errors spam repeatedly in Server.log.

## Root Cause

Eluna timer system stores references to bot/player objects. When a bot logs out or despawns:
1. The underlying C++ WorldObject is deleted
2. The Lua userdata still exists but is invalid
3. Timer fires and passes the stale reference
4. Calling methods on invalid userdata fails with "nil value" error

The periodic_events.lua attempts validation:
```lua
function PeriodicBotFindMonsters(eventID, delay, repeats, bot)
    if not bot:IsBot() then return end  -- THIS CAN CRASH TOO
```

But this validation itself can fail if the bot reference is invalid.

## Intended Behavior

Periodic events should gracefully handle invalid bot references:
1. Check if reference is nil before calling any methods
2. Check if underlying object is still valid
3. Cancel the periodic event if bot is gone
4. No errors in logs for expected logout/despawn scenarios

## Affected Files

- `src/lua/periodic_events.lua` - All PeriodicBot* functions
- `src/lua/behaviors/find-monsters.lua:28` - getNearbyCreatures
- `src/lua/behaviors/gestures.lua:73` - getNPCsInRange
- `src/lua/behaviors/bot-wander.lua:275` - checkAntiClump

## Suggested Implementation

### Option 1: Nil check wrapper (simple)

Add explicit nil check at start of every periodic function:

```lua
function PeriodicBotFindMonsters(eventID, delay, repeats, bot)
    if not bot then return end  -- ADD THIS
    if not bot:IsBot() then return end
    if not bot:IsAlive() then return end
```

### Option 2: pcall wrapper (robust)

Wrap method calls in pcall to catch any failure:

```lua
function safeGetPosition(obj)
    local ok, x, y, z = pcall(function()
        return obj:GetPosition()
    end)
    if ok then
        return x, y, z
    else
        return nil, nil, nil
    end
end
```

### Option 3: Track bot validity (proper)

Use PLAYER_EVENT_ON_LOGOUT to unregister periodic events:

```lua
local botTimers = {}  -- guid -> {eventId1, eventId2, ...}

function OnBotLogout(event, player)
    local guid = player:GetGUID()
    if botTimers[guid] then
        for _, eventId in ipairs(botTimers[guid]) do
            RemoveEventById(eventId)
        end
        botTimers[guid] = nil
    end
end
```

## Recommendation

**No fallbacks. Make the pipeline work correctly.**

The real fix: Patch mod-playerbots to call `sALE->OnLogin(bot)` when bots log in.
Bots should be treated exactly the same as players.

### Patch: mod-playerbots ALE Integration

See: `docs/patches/playerbots-ale-login-hook.md`

## Error Observations

### 2026-04-08 - Initial discovery

Found in `/tmp/wow-chat-2/logs-beta/Server.log`:
- Hundreds of repeated GetPosition nil errors
- Multiple behavior files affected
- Occurs when bots log out while periodic timers are active

## Related Issues
- 160 - Periodic events system
- 164 - Bot mode orchestration
