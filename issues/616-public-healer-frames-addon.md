# 616 - Public Healer Frames Addon (AIO)

## Status
- Created: 2026-04-06
- Phase: 3
- Priority: High
- Depends: AIO module installation, mod-ale

## Current Behavior
- Standard healer addons (HealBot, VuhDo, Grid2) only show party/raid members
- No way to see health of nearby players not in your group
- In this project's "public world" design, healers often need to heal strangers/bots
- Client cannot detect nearby players without server assistance

## Intended Behavior
A healer addon that shows health bars for ALL nearby players/bots within healing range,
regardless of group membership. Server sends player data via AIO; client displays frames.

### Core Features

| Feature | Description |
|---------|-------------|
| Dynamic player list | Server tracks players within range, sends to client |
| Click-to-cast | Configurable spells per click type (left, right, middle, shift+, ctrl+, alt+) |
| Target action | "target" keyword to just target without casting |
| Color schemes | Solid green, gradient (green→red), class colors |
| Party highlight | Visual distinction for party/raid members |
| Configurable limit | Max number of frames shown (default: 20) |
| Range fade | Bars fade/disappear when player leaves range |

### Color Scheme Options

```
┌──────────────────────────────────────────────────────────────┐
│ SOLID GREEN                                                   │
│ ████████████████████████████████████████  100% HP            │
│ ████████████████████████████████████████   50% HP            │
│ ████████████████████████████████████████   10% HP            │
│ (Same green color at all health levels)                      │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ GRADIENT (Green → Red)                                        │
│ ████████████████████████████████████████  100% = #00FF00     │
│ ██████████████████████                     50% = #FFFF00     │
│ ████████                                   25% = #FF8000     │
│ ███                                        10% = #FF0000     │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ CLASS COLORS                                                  │
│ ████████████████  Warrior (#C79C6E)                          │
│ ████████████████  Paladin (#F58CBA)                          │
│ ████████████████  Priest  (#FFFFFF)                          │
│ ████████████████  Mage    (#69CCF0)                          │
└──────────────────────────────────────────────────────────────┘
```

## Technical Research

### Why Server Involvement is Required

Standard WoW client can only detect:
- Party/raid members (UnitHealth, GetRaidRosterInfo)
- Target and focus (via targeting)
- Nameplates (limited API, no click-to-cast)

To see nearby strangers, server must:
1. Query `GetPlayersInRange()` periodically
2. Build list of: GUID, name, health, maxHealth, class, isInParty
3. Send via AIO to client
4. Client renders frames with this data

### SecureActionButton and Combat Lockdown

[HealBot Help Wiki](https://healbot.dpm15.net/wiki/doku.php/using:uilockdown) explains:

> UI Lockdown is not a HealBot-specific issue. It was introduced to stop addons from
> casting any spell on any player with a single button click. Blizzard introduced
> SecureUnitButtonTemplate, which allows protected frames to cast predefined spells
> on predefined units during combat.

**Restrictions during combat:**
- Cannot programmatically show/hide/resize/move protected frames
- Cannot change frame attributes (like target unit)
- If a player leaves, their unitid slot shows stale data until combat ends

**Our Challenge:**
- Dynamic player list means frames appear/disappear as players enter/leave range
- During combat, new players CAN'T be added as click targets
- Frames can update visually (health bars) but not functionally (click action)

**Proposed Solution:**
- Pre-allocate N frames at combat start (e.g., 20 slots)
- Server sends player data into these slots
- Empty slots show "---" or hide visually but remain allocated
- When combat ends, frames can be reassigned
- Accept limitation: new players entering range during combat can't be click-healed until combat ends

### Click-to-Cast Configuration

```lua
-- User configures in addon settings
PublicHealer.ClickBindings = {
    ["LeftButton"]       = "Lesser Heal",      -- spell name or ID
    ["RightButton"]      = "Renew",
    ["MiddleButton"]     = "target",           -- special: just target
    ["Shift-LeftButton"] = "Flash Heal",
    ["Ctrl-LeftButton"]  = "Greater Heal",
    ["Alt-LeftButton"]   = "Dispel Magic",
    ["Shift-RightButton"]= "Prayer of Mending",
}
```

### Hover + Keybind Targeting (Macro Approach)

The addon can't directly intercept keyboard presses during combat, but we can provide
a macro guide for users. When hovering over a frame:

```
/cast [@mouseover,exists] Flash Heal; Flash Heal
```

This casts on the unit under the cursor if hovering a valid unit frame.

**Documentation to provide:**
1. Sample macros for each healing class
2. How to bind macros to action bar slots
3. Keybind those slots to keyboard keys (1-5, F1-F5, etc.)
4. Result: hover over frame, press key, heal that target

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          SERVER (Lua)                                │
├─────────────────────────────────────────────────────────────────────┤
│  PublicHealer.UpdateNearby(player)                                   │
│  - Every 0.5s, query GetPlayersInRange(healRange)                   │
│  - Build table: {guid, name, hp, maxHp, class, inParty}             │
│  - Send via AIO.Msg():AddPacket("PH_UPDATE", data):Send(player)     │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   │ AIO Messages (0.5s interval)
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          CLIENT (AIO Addon)                          │
├─────────────────────────────────────────────────────────────────────┤
│  Frame Pool (20 SecureUnitButton frames)                            │
│  - Each frame: health bar, name text, class icon                    │
│  - Click handlers: SetAttribute("macrotext", "/cast [@unit] Spell") │
│  - Out of combat: reassign units dynamically                         │
│  - In combat: update visual only, keep existing assignments          │
└─────────────────────────────────────────────────────────────────────┘
```

### Server-Side Data Structure

```lua
-- Sent via AIO every tick
local nearbyData = {
    [1] = { guid = "0x123", name = "Healgood", hp = 800, maxHp = 1000, class = 5, inParty = true },
    [2] = { guid = "0x456", name = "Tankhard", hp = 2000, maxHp = 3500, class = 1, inParty = false },
    [3] = { guid = "0x789", name = "Dpsfast",  hp = 600, maxHp = 800,  class = 4, inParty = false },
    -- ...up to configured limit
}
```

### Client Frame Structure

```lua
-- {{{ CreateHealerFrame
-- Creates a single SecureUnitButton for healing
local function CreateHealerFrame(index)
    local frame = CreateFrame("Button", "PublicHealerFrame"..index,
                              PublicHealerContainer, "SecureUnitButtonTemplate")
    frame:SetSize(150, 25)
    frame:SetPoint("TOPLEFT", 0, -25 * (index - 1))

    -- Health bar (can update in combat)
    frame.healthBar = CreateFrame("StatusBar", nil, frame)
    frame.healthBar:SetAllPoints()
    frame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.healthBar:SetMinMaxValues(0, 1)

    -- Name text
    frame.nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.nameText:SetPoint("LEFT", 5, 0)

    -- Class icon
    frame.classIcon = frame:CreateTexture(nil, "OVERLAY")
    frame.classIcon:SetSize(20, 20)
    frame.classIcon:SetPoint("RIGHT", -5, 0)

    return frame
end -- }}}
```

## Implementation Steps

### Step 1: Install AIO Module
- Clone [Rochet2/AIO](https://github.com/Rochet2/AIO)
- Copy AIO_Server to `lua_scripts/`
- Copy AIO_Client to client `Interface/AddOns/`
- Test basic server→client message

### Step 2: Server-side Player Tracking
- Create `src/lua/public-healer-server.lua`
- Periodic event every 500ms per player
- Query nearby players/bots within configurable range
- Send condensed data via AIO

### Step 3: Client-side Frame Pool
- Create AIO addon `PublicHealer/`
- Pre-create 20 SecureUnitButton frames
- Register AIO handler for `PH_UPDATE` messages
- Update frames with received data

### Step 4: Click-to-Cast System
- Out of combat: SetAttribute("unit", guid) and SetAttribute("macrotext", ...)
- In combat: visual updates only
- Support "target" action for targeting without casting

### Step 5: Color Schemes
- Implement solid green, gradient, and class color modes
- User selects via /publichealer config
- Gradient uses linear interpolation: green(100%) → yellow(50%) → red(0%)

### Step 6: Party Highlighting
- Server sends `inParty` flag
- Client shows border glow or icon for party members
- Different border color or thickness

### Step 7: Configuration UI
- /publichealer to open config
- Set click bindings
- Set color scheme
- Set max frames
- Set range

### Step 8: Macro Guide Documentation
- Write `docs/addons/public-healer-macros.md`
- Sample macros for each healer class
- Keybinding instructions
- Mouseover healing explanation

### Step 9: API for Other Addons
- Expose `PublicHealer.GetNearbyPlayers()` on server
- Document in `docs/addons/public-healer-api.md`
- Allow other addons to query nearby player data

## Configuration Options

```lua
PublicHealer.Config = {
    -- Behavior
    maxFrames        = 20,           -- max players shown
    updateInterval   = 500,          -- ms between server updates
    healRange        = 40,           -- yards (typical max heal range)

    -- Visuals
    colorScheme      = "gradient",   -- "solid", "gradient", "class"
    frameWidth       = 150,
    frameHeight      = 25,
    partyHighlight   = true,         -- glow for party members
    partyBorderColor = {0.3, 1, 0.3}, -- green glow

    -- Click bindings
    clickBindings    = {
        ["LeftButton"]       = "Lesser Heal",
        ["RightButton"]      = "Renew",
        ["MiddleButton"]     = "target",
        ["Shift-LeftButton"] = "Flash Heal",
    },
}
```

## Edge Cases

| Case | Handling |
|------|----------|
| More players than frames | Show closest/lowest HP, configurable priority |
| Player dies | Show with 0 HP, grey bar, still targetable for rez |
| Player phases/teleports | Remove from list on server, fade on client |
| Combat starts mid-update | Freeze frame assignments, allow visual updates |
| No AIO addon installed | Server detects, shows warning message |
| Extremely crowded area | Hard cap at maxFrames, prioritize party then low HP |

## Performance Considerations

| Concern | Mitigation |
|---------|------------|
| 500ms updates for many players | Only update changed data (delta) |
| Many frames to render | Use frame recycling, hide unused |
| Server query cost | GetPlayersInRange is cheap in ALE |
| AIO message size | Compress: use class ID not name, short keys |

## Related Resources

### AIO Framework
- [AIO Documentation](http://rochet2.github.io/AIO)
- [AIO GitHub](https://github.com/Rochet2/AIO)
- [AIO Transmog Example](https://github.com/DanieltheDeveloper/azerothcore-transmog-3.3.5a)

### Existing Healer Addons (Reference)
- [HealBot Continued](https://www.curseforge.com/wow/addons/heal-bot-continued)
- [VuhDo](https://www.curseforge.com/wow/addons/vuhdo)
- [VuhDo Comprehensive Guide](https://www.icy-veins.com/forums/topic/11805-vuhdo-a-comprehensive-guide/)
- [HealBot Combat Lockdown](https://healbot.dpm15.net/wiki/doku.php/using:uilockdown)

### WoW 3.3.5a Addon Resources
- [NoM0Re Addon Collection](https://github.com/NoM0Re/WoW-3.3.5a-Addons)
- [TrinityCore Addons](https://github.com/TrinityCore/wow_335a_addons)

## Files to Create

| File | Purpose |
|------|---------|
| `src/lua/addons/public-healer-server.lua` | Server-side tracking and AIO sending |
| `client-addons/PublicHealer/PublicHealer.lua` | AIO client addon main file |
| `client-addons/PublicHealer/Config.lua` | Configuration and bindings |
| `client-addons/PublicHealer/Frames.lua` | Frame pool and rendering |
| `docs/addons/public-healer-guide.md` | User guide |
| `docs/addons/public-healer-macros.md` | Mouseover macro guide |
| `docs/addons/public-healer-api.md` | API documentation for other addons |

## Testing Plan

1. Install AIO, verify basic message passing
2. Server sends dummy data, client shows frames
3. Walk near/away from players, frames appear/disappear
4. Test click-to-cast out of combat
5. Enter combat, verify frames freeze but update visually
6. Test combat ends, frames reassign correctly
7. Test all three color schemes
8. Test party highlighting
9. Test with 50+ nearby players (stress test)
10. Test macro-based mouseover healing

## Related Issues

- 142: Custom spell system (shares AIO infrastructure)
- 161: Bot wandering (bots are heal targets)
- 132: Healer ping-pong behavior (related healer coordination)

## Related Concepts

- Concept 801-808: AIO Framework
- Concept 401-420: Combat coordination
- Concept 601-608: Visual guidelines

## Notes

- This is the first "public world" healer tool - healing strangers is core gameplay
- Combat lockdown is the main technical challenge; accept the limitation
- The API exposure lets future addons (e.g., threat meters) use the same data
- Consider adding "priority" system: party > low HP > alphabetical
- Mouseover macros are the most responsive method, worth documenting well
