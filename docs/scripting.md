# ALE Lua Scripting Guide

## Overview

The AzerothCore Lua Engine (ALE) provides a LuaJIT-based scripting interface
for AzerothCore, allowing custom game logic without modifying C++ source code.
ALE is the active Lua engine for the `release` and `beta` profiles; the
legacy `alpha` profile still uses the older mod-eluna for historical
compatibility with wow-chat-1.

## Script Location

Scripts are loaded from the profile-local install tree:

```
installed-files-{profile}/bin/lua_scripts/
├── custom/         # Project-specific scripts (symlinked from src/lua/)
└── extensions/     # Shared utility scripts
```

## Event Registration

Scripts register handlers for server events:

```lua
-- {{{ RegisterPlayerEvent
local function OnPlayerLogin(event, player)
    player:SendBroadcastMessage("Welcome to the server!")
end
-- }}}

RegisterPlayerEvent(3, OnPlayerLogin)  -- PLAYER_EVENT_ON_LOGIN = 3
```

## Common Event Types

### Player Events
| ID | Constant | Description |
|----|----------|-------------|
| 3  | PLAYER_EVENT_ON_LOGIN | Player enters world |
| 4  | PLAYER_EVENT_ON_LOGOUT | Player leaves world |
| 6  | PLAYER_EVENT_ON_LEVEL_CHANGE | Player gains/loses level |
| 9  | PLAYER_EVENT_ON_KILL_PLAYER | Player kills another player |
| 12 | PLAYER_EVENT_ON_CHAT | Player sends chat message |
| 74 | PLAYER_EVENT_ON_SELL_ITEM | Player sells item to vendor (added by B006) |

### Creature Events
| ID | Constant | Description |
|----|----------|-------------|
| 1 | CREATURE_EVENT_ON_ENTER_COMBAT | Creature enters combat |
| 2 | CREATURE_EVENT_ON_LEAVE_COMBAT | Creature leaves combat |
| 4 | CREATURE_EVENT_ON_DIED | Creature dies |
| 9 | CREATURE_EVENT_ON_GOSSIP_HELLO | Player interacts with creature |

### Server Events
| ID | Constant | Description |
|----|----------|-------------|
| 1  | SERVER_EVENT_ON_STARTUP | Server starts |
| 14 | SERVER_EVENT_ON_CHAT_SEND | Any chat message sent |

## Object Methods

### Player Object
```lua
player:GetName()                    -- Returns player name
player:GetLevel()                   -- Returns current level
player:GetGUID()                    -- Returns unique identifier
player:SendBroadcastMessage(msg)    -- Send system message
player:Teleport(mapId, x, y, z, o)  -- Move player
player:AddItem(itemId, count)       -- Give item
player:GetGroup()                   -- Returns Group object or nil
```

### Creature Object
```lua
creature:GetEntry()                  -- Returns creature template ID
creature:GetName()                   -- Returns creature name
creature:Say(text, lang)             -- Creature speaks
creature:MoveTo(x, y, z)             -- Move creature
creature:CastSpell(target, spellId)  -- Cast spell
```

### Unit Object (extensions added by B007)
```lua
unit:SetWalk(true)        -- Toggle walking animation
unit:IsWalking()
unit:IsHostileTo(other)
unit:IsFriendlyTo(other)
```

### Group Object
```lua
group:GetMembers()  -- Returns table of Player objects
group:GetLeader()   -- Returns leader Player
group:IsFull()      -- Returns boolean
```

## Database Queries

```lua
-- {{{ QueryWorldDatabase
local result = WorldDBQuery("SELECT entry, name FROM creature_template LIMIT 5")
if result then
    repeat
        local entry = result:GetUInt32(0)
        local name  = result:GetString(1)
        print(entry, name)
    until not result:NextRow()
end
-- }}}
```

Available query functions:
- `WorldDBQuery(sql)` - Query acore_world
- `CharDBQuery(sql)`  - Query acore_characters
- `AuthDBQuery(sql)`  - Query acore_auth
- `WorldDBExecute(sql)` - Execute without result

## Async Capture (across event boundaries)

Userdata references (Player, Creature, etc.) can be invalidated between
the time a callback is registered and the time it fires. Closures crossing
async/event boundaries must capture **names or GUIDs as plain values**, then
re-resolve via `GetPlayerByName` / `GetPlayerByGUID` at callback time.
Invalidated userdata is still truthy and will crash on method call.

## Script Organization

Recommended structure:

```
lua_scripts/custom/
├── init.lua      # Loads other scripts
├── commands/     # Custom chat commands
├── events/       # Event handlers by category
├── npcs/         # NPC-specific scripts
└── utils/        # Shared utility functions
```

## Debugging

### Print to server console
```lua
print("Debug message")
```

### Reload Lua without restarting the server
```
.reload ale
```

## Best Practices

1. Use vimfolds for function organization
2. Keep scripts focused on a single responsibility
3. Avoid blocking operations in event handlers
4. Use `WorldDBExecute` for writes, queries for reads
5. Test scripts in isolation before integration
