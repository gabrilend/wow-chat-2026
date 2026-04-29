# 106b: Runtime Config Modifications

## Status
- [ ] Open
- [ ] In Progress
- [ ] Completed

## Parent Issue

This is a sub-issue of 106-ingame-config-control-board (Phase 2 of 3).

## Current Behavior

After 106a, configuration can be viewed but not modified. Changes still require:
1. Editing config files manually
2. Restarting the server to apply changes

## Intended Behavior

Runtime modification of hot-reloadable settings:
1. `.config set <category>.<key> <value>` - Modify a setting
2. Changes take effect immediately (no restart)
3. Visual feedback on success/failure
4. NPC gossip interface for mouse-driven modifications
5. Validation prevents invalid values

## Hot-Reloadable Settings

### Lua Script Variables (always hot-reloadable)
- DELAY_PERIODIC_SPAWN_CREATURE
- DELAY_PERIODIC_SPAWN_TRAVELLER
- DELAY_PERIODIC_SPAWN_TREASURE
- Ambush distance parameters
- Max ambushers per player

### Server Settings (via `.reload config`)
- Some worldserver.conf values support hot-reload
- Game rates may be adjustable via server commands

### Database-Backed Settings
- Any setting stored in database can be changed live
- Consider moving key settings to a config table

## Suggested Implementation Steps

1. Extend ConfigBoard with setValue method
2. Add setter functions to registered settings
3. Implement validation for each setting type (number ranges, enums)
4. Register `.config set` chat command handler
5. Parse `category.key value` syntax
6. Call appropriate setter with validation
7. Return success/failure message to player
8. Extend NPC gossip with "Modify" options
9. Add confirmation dialogs for changes
10. Test modifications persist during session

## Technical Approach

### Lua Script Extension
```lua
-- {{{ ConfigBoard.setValue
function ConfigBoard.setValue(category, key, value)
    local cat = ConfigBoard.categories[category]
    if not cat then return false, "Unknown category" end

    local setting = cat[key]
    if not setting then return false, "Unknown setting" end
    if not setting.setter then return false, "Setting is read-only" end

    -- Validate
    if setting.validator then
        local valid, err = setting.validator(value)
        if not valid then return false, err end
    end

    -- Apply
    local success, err = pcall(setting.setter, value)
    if not success then return false, "Failed to apply: " .. tostring(err) end

    return true, "Setting updated"
end
-- }}}

-- {{{ ConfigBoard.registerSetting (extended)
function ConfigBoard.registerSetting(category, key, opts)
    -- opts = { getter, setter (optional), validator (optional), description }
    if not ConfigBoard.categories[category] then
        ConfigBoard.categories[category] = {}
    end
    ConfigBoard.categories[category][key] = opts
end
-- }}}
```

### Chat Command Format
```
.config set ambush.spawn_delay 60      - Set ambush delay to 60s
.config set rates.xp 2.0               - Set XP rate to 2x
.config set ambush.max_count 5         - Set max ambushers to 5
```

### Validation Examples
```lua
-- Number in range
function validateRange(min, max)
    return function(value)
        local num = tonumber(value)
        if not num then return false, "Must be a number" end
        if num < min or num > max then
            return false, "Must be between " .. min .. " and " .. max
        end
        return true
    end
end

-- Enum value
function validateEnum(options)
    return function(value)
        for _, opt in ipairs(options) do
            if value == opt then return true end
        end
        return false, "Must be one of: " .. table.concat(options, ", ")
    end
end
```

### NPC Gossip Modification Flow
1. Player selects a category
2. Player selects a setting
3. Shows current value and input prompt
4. Player enters new value
5. Confirmation dialog: "Change X from Y to Z?"
6. Apply change and show result

## Validation Criteria

- [ ] `.config set` command parses arguments correctly
- [ ] Invalid category/key returns helpful error
- [ ] Read-only settings reject modification attempts
- [ ] Validators catch out-of-range values
- [ ] Successful changes reflected in `.config show`
- [ ] Lua timing variables actually change game behavior
- [ ] NPC modification interface works end-to-end
- [ ] Changes survive within session (until server restart)

## Dependencies

- 106a-read-only-config-dashboard (provides base infrastructure)

## Related Documents

- docs/scripting.md
- src/lua/periodic_events.lua
- src/lua/ambush.lua

## Notes

Changes made here are session-only. They will be lost on server restart.
Persistence comes in 106c.

Important: Some settings may have side effects or require coordination.
For example, changing spawn delays might need to reset existing timers.
Document any such requirements in the setter implementation.

Consider: Log all configuration changes with timestamp and who made them,
for debugging and audit purposes.
