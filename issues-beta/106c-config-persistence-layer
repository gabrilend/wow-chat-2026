# 106c: Config Persistence Layer

## Status
- [ ] Open
- [ ] In Progress
- [ ] Completed

## Parent Issue

This is a sub-issue of 106-ingame-config-control-board (Phase 3 of 3).

## Current Behavior

After 106b, configuration can be viewed and modified at runtime, but:
1. Changes are lost on server restart
2. No way to save current configuration
3. No backup/restore capability
4. Must manually edit files to make permanent changes

## Intended Behavior

Persistence layer for configuration changes:
1. `.config save` - Write current settings to config files
2. `.config reload` - Reload settings from files (discard runtime changes)
3. `.config backup` - Create timestamped backup of current configs
4. `.config restore <backup>` - Restore from a previous backup
5. Automatic backup before any save operation

## Suggested Implementation Steps

1. Create backup directory structure (`config-backups/`)
2. Implement config file parser (read existing .conf files)
3. Implement config file writer (preserve comments, update values)
4. Add `.config save` command with pre-save backup
5. Add `.config reload` command to re-read from files
6. Add `.config backup` for manual backup creation
7. Add `.config backup list` to show available backups
8. Add `.config restore <name>` to restore from backup
9. Extend NPC gossip with save/backup options
10. Test round-trip: modify -> save -> restart -> verify

## Technical Approach

### Backup Directory Structure
```
config-backups/
├── 2025-01-29_14-30-00/
│   ├── worldserver.conf
│   ├── authserver.conf
│   └── manifest.txt       # What was backed up and why
├── 2025-01-29_15-45-00/
│   └── ...
└── latest -> 2025-01-29_15-45-00/  # Symlink to most recent
```

### Lua Implementation
```lua
-- {{{ ConfigBoard.save
function ConfigBoard.save()
    -- Create backup first
    local backupPath, err = ConfigBoard.backup("pre-save")
    if not backupPath then
        return false, "Backup failed: " .. err
    end

    -- Write each config file
    for category, settings in pairs(ConfigBoard.categories) do
        local file = ConfigBoard.categoryToFile(category)
        if file then
            local success, err = ConfigBoard.writeConfigFile(file, category)
            if not success then
                return false, "Failed to write " .. file .. ": " .. err
            end
        end
    end

    return true, "Configuration saved (backup at " .. backupPath .. ")"
end
-- }}}

-- {{{ ConfigBoard.backup
function ConfigBoard.backup(reason)
    local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
    local backupDir = CONFIG_BACKUP_DIR .. "/" .. timestamp

    -- Create directory
    os.execute("mkdir -p " .. backupDir)

    -- Copy config files
    local files = {"worldserver.conf", "authserver.conf"}
    for _, file in ipairs(files) do
        local src = CONFIG_DIR .. "/" .. file
        local dst = backupDir .. "/" .. file
        os.execute("cp " .. src .. " " .. dst)
    end

    -- Write manifest
    local manifest = io.open(backupDir .. "/manifest.txt", "w")
    manifest:write("Backup created: " .. timestamp .. "\n")
    manifest:write("Reason: " .. (reason or "manual") .. "\n")
    manifest:close()

    -- Update latest symlink
    os.execute("ln -sfn " .. backupDir .. " " .. CONFIG_BACKUP_DIR .. "/latest")

    return backupDir
end
-- }}}

-- {{{ ConfigBoard.reload
function ConfigBoard.reload()
    -- Re-read config files and update runtime values
    for category, settings in pairs(ConfigBoard.categories) do
        local file = ConfigBoard.categoryToFile(category)
        if file then
            ConfigBoard.loadFromFile(file, category)
        end
    end
    return true, "Configuration reloaded from files"
end
-- }}}
```

### Config File Parsing Strategy

Preserve original file structure (comments, ordering, whitespace) while updating values:

```lua
-- {{{ ConfigBoard.writeConfigFile
function ConfigBoard.writeConfigFile(filepath, category)
    local lines = {}
    local file = io.open(filepath, "r")

    for line in file:lines() do
        local key, value = line:match("^(%w+)%s*=%s*(.+)$")
        if key and ConfigBoard.categories[category][key] then
            -- Update this line with new value
            local newValue = ConfigBoard.getValue(category, key)
            line = key .. " = " .. tostring(newValue)
        end
        table.insert(lines, line)
    end
    file:close()

    -- Write back
    file = io.open(filepath, "w")
    for _, line in ipairs(lines) do
        file:write(line .. "\n")
    end
    file:close()

    return true
end
-- }}}
```

### Chat Command Format
```
.config save                - Save all changes to config files
.config reload              - Reload from files (discard changes)
.config backup              - Create manual backup
.config backup list         - Show available backups
.config restore <name>      - Restore from backup
```

### NPC Gossip Persistence Options
- "Save Current Configuration" (with confirmation)
- "Reload From Files" (with warning about losing changes)
- "Backup Management" submenu
  - "Create Backup"
  - "View Backups"
  - "Restore Backup" (shows list)

## Validation Criteria

- [ ] `.config save` creates backup before writing
- [ ] Saved values persist across server restart
- [ ] Comments in config files preserved after save
- [ ] `.config reload` restores file values
- [ ] `.config backup` creates timestamped directory
- [ ] `.config backup list` shows all backups
- [ ] `.config restore` correctly restores previous state
- [ ] NPC interface provides all persistence options
- [ ] Error handling for file permission issues

## Dependencies

- 106a-read-only-config-dashboard (base infrastructure)
- 106b-runtime-config-modifications (settings to persist)

## Related Documents

- docs/scripting.md
- installed-files/etc/worldserver.conf
- installed-files/etc/authserver.conf

## Notes

File I/O from Lua requires careful error handling. Eluna's `io` library may have
restrictions. Test file operations early to identify any sandbox limitations.

The config file parser must handle:
- Comments (lines starting with #)
- Empty lines
- Inline comments (value # comment)
- Quoted string values
- Multi-line values (if any exist)

Consider: For Lua script settings (like ambush timers), persistence might mean
writing to a separate `config-overrides.lua` file that gets loaded after the
main scripts, overriding default values.

Security: Only allow admins (GM level 3+) to use save/restore commands.
Read-only commands from 106a might be available to all players.
