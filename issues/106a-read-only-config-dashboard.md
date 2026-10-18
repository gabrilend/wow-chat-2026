# 106a: Read-Only Config Dashboard

## Status
- [ ] Open
- [ ] In Progress
- [ ] Completed

## Parent Issue

This is a sub-issue of 106-ingame-config-control-board (Phase 1 of 3).

## Current Behavior

No in-game visibility into server configuration. Players and admins must:
1. Exit the game
2. Open config files in a text editor
3. Search through hundreds of options to find relevant settings

## Intended Behavior

Chat commands and NPC interface for browsing configuration values:
1. `.config` - Show help message with available commands
2. `.config list` - Display all configuration categories
3. `.config show <category>` - Display settings within a category
4. NPC "Configuration Terminal" with gossip menu for mouse-driven browsing

## Configuration Categories to Expose

### Game Rates
- XP rates
- Loot rates
- Reputation rates
- Honor rates

### Ambush System (src/lua/)
- DELAY_PERIODIC_SPAWN_CREATURE (currently 40s)
- DELAY_PERIODIC_SPAWN_TRAVELLER (currently 130s)
- DELAY_PERIODIC_SPAWN_TREASURE (currently 100s)
- Ambush distance min/max
- Max ambushers per player

### Playerbots
- Bot spawn settings
- AI behavior toggles
- Party formation rules

### Server Settings
- Max players
- MOTD
- Realm settings

## Suggested Implementation Steps

1. Create `src/lua/config-board.lua` with skeleton structure
2. Define configuration registry (category -> keys -> current values)
3. Register chat command handler for `.config`
4. Implement `.config list` to enumerate categories
5. Implement `.config show <category>` to display values
6. Create NPC entry in database for Configuration Terminal
7. Implement gossip menu handlers for browsing
8. Test all read operations in-game

## Technical Approach

### Lua Script Structure
```lua
-- src/lua/config-board.lua

ConfigBoard = {}
ConfigBoard.categories = {}

-- {{{ ConfigBoard.registerCategory
function ConfigBoard.registerCategory(name, settings)
    ConfigBoard.categories[name] = settings
end
-- }}}

-- {{{ ConfigBoard.getCategories
function ConfigBoard.getCategories()
    local result = {}
    for name, _ in pairs(ConfigBoard.categories) do
        table.insert(result, name)
    end
    table.sort(result)
    return result
end
-- }}}

-- {{{ ConfigBoard.getValue
function ConfigBoard.getValue(category, key)
    local cat = ConfigBoard.categories[category]
    if not cat then return nil, "Unknown category" end
    local setting = cat[key]
    if not setting then return nil, "Unknown setting" end
    return setting.getter()
end
-- }}}

-- {{{ ConfigBoard.getSettings
function ConfigBoard.getSettings(category)
    local cat = ConfigBoard.categories[category]
    if not cat then return nil, "Unknown category" end
    local result = {}
    for key, setting in pairs(cat) do
        result[key] = {
            value = setting.getter(),
            description = setting.description,
            modifiable = setting.setter ~= nil
        }
    end
    return result
end
-- }}}
```

### Chat Command Format
```
.config                     - Show help
.config list                - List categories
.config show rates          - Show rate settings
.config show ambush         - Show ambush timing settings
```

### NPC Gossip Flow
1. Player interacts with Configuration Terminal NPC
2. Main menu shows category list
3. Selecting category shows settings with current values
4. Back button returns to category list

## Validation Criteria

- [ ] `.config` displays help text
- [ ] `.config list` shows all 4 categories
- [ ] `.config show <category>` displays settings with values
- [ ] NPC spawns and responds to interaction
- [ ] Gossip menu navigates correctly between categories
- [ ] All Lua ambush settings readable
- [ ] Server rates readable via WorldDBQuery or config API

## Dependencies

- 101-verify-server-startup (need running server to test)
- 103-document-configuration-options (helps identify what to expose)

## Related Documents

- docs/scripting.md (Eluna API reference)
- src/lua/periodic_events.lua (contains timing constants to expose)

## Notes

This sub-issue is read-only. No modification capability is included - that comes
in 106b. Focus on clean data access patterns that 106b can extend.

Consider: Use a registration pattern so other Lua scripts can register their
own configurable values with ConfigBoard.
