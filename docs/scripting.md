# Eluna Lua Scripting Guide

## Overview

Eluna provides a LuaJIT-based scripting interface for AzerothCore, allowing custom
game logic without modifying C++ source code.

## Script Location

Scripts are loaded from:
```
installed-files/bin/lua_scripts/
├── custom/         # Project-specific scripts
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
| 3 | PLAYER_EVENT_ON_LOGIN | Player enters world |
| 4 | PLAYER_EVENT_ON_LOGOUT | Player leaves world |
| 6 | PLAYER_EVENT_ON_LEVEL_CHANGE | Player gains/loses level |
| 9 | PLAYER_EVENT_ON_KILL_PLAYER | Player kills another player |
| 12 | PLAYER_EVENT_ON_CHAT | Player sends chat message |

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
| 1 | SERVER_EVENT_ON_STARTUP | Server starts |
| 14 | SERVER_EVENT_ON_CHAT_SEND | Any chat message sent |

## Object Methods

### Player Object
```lua
player:GetName()           -- Returns player name
player:GetLevel()          -- Returns current level
player:GetGUID()           -- Returns unique identifier
player:SendBroadcastMessage(msg)  -- Send system message
player:Teleport(mapId, x, y, z, o)  -- Move player
player:AddItem(itemId, count)     -- Give item
player:GetGroup()          -- Returns Group object or nil
```

### Creature Object
```lua
creature:GetEntry()        -- Returns creature template ID
creature:GetName()         -- Returns creature name
creature:Say(text, lang)   -- Creature speaks
creature:MoveTo(x, y, z)   -- Move creature
creature:CastSpell(target, spellId)  -- Cast spell
```

### Group Object
```lua
group:GetMembers()         -- Returns table of Player objects
group:GetLeader()          -- Returns leader Player
group:IsFull()             -- Returns boolean
```

## Database Queries

```lua
-- {{{ QueryWorldDatabase
local result = WorldDBQuery("SELECT entry, name FROM creature_template LIMIT 5")
if result then
    repeat
        local entry = result:GetUInt32(0)
        local name = result:GetString(1)
        print(entry, name)
    until not result:NextRow()
end
-- }}}
```

Available query functions:
- `WorldDBQuery(sql)` - Query acore_world
- `CharDBQuery(sql)` - Query acore_characters
- `AuthDBQuery(sql)` - Query acore_auth
- `WorldDBExecute(sql)` - Execute without result

## Script Organization

Recommended structure:
```
lua_scripts/custom/
├── init.lua           # Loads other scripts
├── commands/          # Custom chat commands
├── events/            # Event handlers by category
├── npcs/              # NPC-specific scripts
└── utils/             # Shared utility functions
```

## Debugging

### Print to server console
```lua
print("Debug message")
```

### Validator: list registered events
Run in worldserver console:
```
eluna stats
```

## Best Practices

1. Use vimfolds for function organization
2. Keep scripts focused on single responsibility
3. Avoid blocking operations in event handlers
4. Use WorldDBExecute for writes, queries for reads
5. Test scripts in isolation before integration
