# Public Healer API Documentation

This document describes the server-side and client-side APIs exposed by the
Public Healer addon for use by other addons.

## Server-Side API (Lua)

### PublicHealer.GetNearbyPlayers(player, range)

Returns a table of players/bots near the specified player.

**Parameters:**
- `player` (Player) - The player to search around
- `range` (number, optional) - Search range in yards (default: 40)

**Returns:**
Table of player data:
```lua
{
    [1] = {
        guid    = "0x0123456789ABCDEF",  -- Player GUID as hex string
        name    = "Healgood",            -- Character name
        hp      = 800,                   -- Current health
        maxHp   = 1000,                  -- Maximum health
        class   = 5,                     -- Class ID (1=Warrior, 2=Paladin, etc.)
        inParty = true,                  -- Is in same party/raid as searcher
        level   = 15,                    -- Character level
        x       = 1234.5,                -- World X position
        y       = 5678.9,                -- World Y position
    },
    -- ...more players
}
```

**Example:**
```lua
-- {{{ Example: Get low-health players
local function GetLowHealthPlayers(player, threshold)
    local nearby = PublicHealer.GetNearbyPlayers(player, 40)
    local lowHP = {}

    for _, p in ipairs(nearby) do
        local pct = p.hp / p.maxHp
        if pct < threshold then
            table.insert(lowHP, p)
        end
    end

    return lowHP
end
-- }}}
```

### PublicHealer.RegisterUpdateCallback(callback)

Registers a function to be called whenever the nearby player list updates.

**Parameters:**
- `callback` (function) - Function to call with (player, nearbyData)

**Example:**
```lua
-- {{{ Example: Log when players enter/leave range
local lastCount = {}

PublicHealer.RegisterUpdateCallback(function(player, nearbyData)
    local guid = player:GetGUIDLow()
    local count = #nearbyData

    if lastCount[guid] ~= count then
        print(player:GetName() .. " now has " .. count .. " players nearby")
        lastCount[guid] = count
    end
end)
-- }}}
```

### PublicHealer.GetConfig()

Returns the current server-side configuration.

**Returns:**
```lua
{
    maxFrames       = 20,
    updateInterval  = 500,
    healRange       = 40,
}
```

### Class ID Reference

| ID | Class |
|----|-------|
| 1 | Warrior |
| 2 | Paladin |
| 3 | Hunter |
| 4 | Rogue |
| 5 | Priest |
| 6 | Death Knight |
| 7 | Shaman |
| 8 | Mage |
| 9 | Warlock |
| 11 | Druid |

## Client-Side API (AIO Addon)

### AIO Message Format

The server sends `PH_UPDATE` messages via AIO:

```lua
-- Server sends:
AIO.Msg():Add("PH_UPDATE", nearbyData):Send(player)

-- Client receives:
AIO.RegisterHandler("PH_UPDATE", function(player, nearbyData)
    -- nearbyData is the same table format as GetNearbyPlayers
end)
```

### PublicHealer.GetFrame(index)

Returns the frame object at the specified index (1-20).

**Example:**
```lua
local frame = PublicHealer.GetFrame(1)
if frame.unitGuid then
    print("Frame 1 is showing: " .. frame.unitName)
end
```

### PublicHealer.GetFrameByGuid(guid)

Returns the frame showing the specified player GUID, or nil.

### PublicHealer.SetColorScheme(scheme)

Changes the color scheme.

**Parameters:**
- `scheme` (string) - One of: "solid", "gradient", "class"

### PublicHealer.SetClickBinding(button, action)

Sets a click binding.

**Parameters:**
- `button` (string) - Click identifier (e.g., "LeftButton", "Shift-RightButton")
- `action` (string) - Spell name, spell ID, or "target"

**Example:**
```lua
PublicHealer.SetClickBinding("LeftButton", "Lesser Heal")
PublicHealer.SetClickBinding("Shift-LeftButton", "Flash Heal")
PublicHealer.SetClickBinding("MiddleButton", "target")
```

## Integration Examples

### Custom Threat Addon

Use the nearby player data to show threat on those units:

```lua
-- Server side
local function UpdateThreatDisplay(player)
    local nearby = PublicHealer.GetNearbyPlayers(player, 40)

    for _, p in ipairs(nearby) do
        local target = GetPlayerByGUID(p.guid)
        if target then
            -- Get threat info and send to client
        end
    end
end
```

### Smart Heal Priority

Modify healing priority based on role:

```lua
-- Sort nearby players by healing priority
local function SortByHealPriority(nearbyData)
    table.sort(nearbyData, function(a, b)
        -- Tanks first (warriors/paladins/druids with tank spec)
        local aIsTank = (a.class == 1 or a.class == 2 or a.class == 11)
        local bIsTank = (b.class == 1 or b.class == 2 or b.class == 11)

        if aIsTank ~= bIsTank then
            return aIsTank
        end

        -- Then by HP percentage
        local aPct = a.hp / a.maxHp
        local bPct = b.hp / b.maxHp
        return aPct < bPct
    end)

    return nearbyData
end
```

### Distance-Based Frame Opacity

Fade frames based on distance from healer:

```lua
-- Client side, in update handler
AIO.RegisterHandler("PH_UPDATE", function(player, nearbyData)
    for i, data in ipairs(nearbyData) do
        local frame = PublicHealer.GetFrame(i)
        if frame and data.distance then
            -- Fade to 50% at max range
            local alpha = 1.0 - (data.distance / 80) * 0.5
            frame:SetAlpha(math.max(0.5, alpha))
        end
    end
end)
```

## Event Hooks

### PUBLICHEALER_NEARBY_CHANGED

Fired when the nearby player list changes (client-side).

```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("PUBLICHEALER_NEARBY_CHANGED")
frame:SetScript("OnEvent", function(self, event, count)
    print("Now tracking " .. count .. " nearby players")
end)
```

### PUBLICHEALER_COMBAT_LOCKDOWN

Fired when combat lockdown affects the addon (client-side).

```lua
frame:RegisterEvent("PUBLICHEALER_COMBAT_LOCKDOWN")
frame:SetScript("OnEvent", function(self, event, inCombat)
    if inCombat then
        print("Frames locked - new players can't be added")
    else
        print("Frames unlocked - reassigning")
    end
end)
```

## Limitations

1. **Combat Lockdown**: During combat, new players cannot be assigned to click-heal
   frames. Visual updates (health bars) continue, but click actions remain on
   pre-combat targets.

2. **Update Interval**: Server updates every 500ms by default. Fast-moving players
   may appear/disappear with slight delay.

3. **Range Limit**: The healing range is configurable but capped at 100 yards for
   performance reasons.

4. **Frame Limit**: Maximum 20 frames to prevent UI clutter and performance issues.

## Related Documentation

- [Public Healer User Guide](public-healer-guide.md)
- [Public Healer Mouseover Macros](public-healer-macros.md)
- [AIO Framework Documentation](http://rochet2.github.io/AIO)
