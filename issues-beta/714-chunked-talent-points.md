# 714 - Chunked Talent Point System (v1.0)

## Status
- Created: 2026-04-07
- Phase: 2
- Priority: High (v1.0 requirement)

## Current Behavior

Talent points are awarded incrementally:
- 3 talent points per level
- 20 levels × 3 points = 60 total
- Points awarded at every level

Players can:
- Respec talents freely
- Access all talent tree tiers

## Intended Behavior (v1.0)

Talent points awarded in large chunks at specific levels:

| Level | Points Awarded | Total Points |
|-------|----------------|--------------|
| 5 | 10 | 10 |
| 8 | 10 | 20 |
| 11 | 10 | 30 |
| 14 | 10 | 40 |
| 17 | 10 | 50 |
| 20 | 10 | 60 |

**Additional restrictions:**
- No respec (talents are permanent)
- Only first 3 tiers of talent trees accessible

### Why Chunked Points?

- **Meaningful progression moments** - Level 5 feels significant
- **Forced commitment** - No respec means choices matter
- **Simpler decision making** - 6 big decisions vs 60 small ones
- **Tier limit** - Keeps power level appropriate for 1-20 content

## Version Plan

| Version | Talent System |
|---------|---------------|
| v1.0 | Chunked (10 points × 6 levels) + no respec + tier 1-3 only |
| v2.0 | Incremental (3 points × 20 levels) + respec available + all tiers |

The system should support switching between modes via configuration.

## Configuration

```lua
-- In levelling.lua or config
TALENT_MODE = "chunked"  -- or "incremental"

TALENT_CONFIG = {
    chunked = {
        levels = { 5, 8, 11, 14, 17, 20 },
        points_per_grant = 10,
        allow_respec = false,
        max_tier = 3,
    },
    incremental = {
        points_per_level = 3,
        allow_respec = true,
        max_tier = 7,  -- all tiers
    },
}
```

## Suggested Implementation Steps

### Step 1: Modify Talent Point Grants

Update `levelling.lua` to check talent mode:

```lua
-- {{{ grantTalentPoints
-- Awards talent points based on configured mode
function grantTalentPoints(player, newLevel)
    local mode = TALENT_CONFIG[TALENT_MODE]

    if TALENT_MODE == "chunked" then
        -- Check if this level grants points
        for _, grantLevel in ipairs(mode.levels) do
            if newLevel == grantLevel then
                -- Award chunk of points
                local current = player:GetFreeTalentPoints()
                player:SetFreeTalentPoints(current + mode.points_per_grant)
                player:SendBroadcastMessage("You have gained 10 talent points!")
                return
            end
        end
        -- Not a grant level, no points
    else
        -- Incremental mode (current behavior)
        local current = player:GetFreeTalentPoints()
        player:SetFreeTalentPoints(current + mode.points_per_level)
    end
end
-- }}}
```

### Step 2: Disable Respec (Chunked Mode)

Hook talent reset attempts:

```lua
-- {{{ onTalentResetAttempt
-- Block respec in chunked mode
local function onTalentResetAttempt(event, player, cost)
    if TALENT_MODE == "chunked" and not TALENT_CONFIG.chunked.allow_respec then
        player:SendBroadcastMessage("Talent respec is disabled. Choose wisely!")
        return false  -- Block the reset
    end
    return true  -- Allow in incremental mode
end
-- }}}
```

**Note:** Need to verify ALE has a hook for talent reset. If not, may need:
- C++ patch to add hook, OR
- Remove respec NPCs from world, OR
- SQL to disable trainer respec option

### Step 3: Limit Talent Tier Access

Block spending points in tiers 4-7:

```lua
-- {{{ onTalentLearnAttempt
-- Block talents beyond tier 3 in chunked mode
local function onTalentLearnAttempt(event, player, talentId, talentRank)
    if TALENT_MODE == "chunked" then
        local tier = getTalentTier(talentId)
        if tier > TALENT_CONFIG.chunked.max_tier then
            player:SendBroadcastMessage("You cannot learn talents beyond tier 3.")
            return false
        end
    end
    return true
end
-- }}}
```

**Note:** Need to research:
- How to get talent tier from talentId
- What ALE hook fires on talent learn
- May need to build tier lookup table from DBC data

### Step 4: Handle Mode Switching

When switching modes, existing characters need handling:

```lua
-- {{{ recalculateTalentPoints
-- Recalculate points for a player based on current mode
function recalculateTalentPoints(player)
    local level = player:GetLevel()
    local expectedPoints = 0

    if TALENT_MODE == "chunked" then
        for _, grantLevel in ipairs(TALENT_CONFIG.chunked.levels) do
            if level >= grantLevel then
                expectedPoints = expectedPoints + TALENT_CONFIG.chunked.points_per_grant
            end
        end
    else
        expectedPoints = level * TALENT_CONFIG.incremental.points_per_level
    end

    -- Get spent points
    local spent = player:GetSpentTalentPoints()
    local free = expectedPoints - spent

    if free < 0 then
        -- Player has more spent than allowed - need reset
        player:SendBroadcastMessage("Talent mode changed. Your talents have been reset.")
        player:ResetTalents(true)  -- Force reset, no cost
        player:SetFreeTalentPoints(expectedPoints)
    else
        player:SetFreeTalentPoints(free)
    end
end
-- }}}
```

**Server reset preferred** when switching modes to avoid edge cases.

### Step 5: Tier Lookup Table

Build from spell DBC or hardcode known values:

```lua
-- Talent tier by talentId (row in TalentTab)
-- Tier is determined by row position: rows 0-1 = tier 1, rows 2-3 = tier 2, etc.
-- This may need extraction from TalentTab.dbc

TALENT_TIERS = {
    -- [talentId] = tier
    -- TODO: Extract from DBC or research
}

function getTalentTier(talentId)
    return TALENT_TIERS[talentId] or 1
end
```

## Database Considerations

### Existing Characters

When switching from incremental → chunked:
- Characters may have points in tier 4+ talents
- Options:
  1. **Force reset all** (recommended for mode switch)
  2. **Grandfather existing** (messy, inconsistent)
  3. **Block login until reset** (frustrating)

### Storing Mode Per-Character?

For v1.0, mode is server-wide. Future consideration:
- Store talent mode in character data
- Allow per-character mode (legacy characters keep old system)

## Files to Modify

- `src/lua/levelling.lua` - Talent point grant logic
- `src/lua/talent-restrictions.lua` (new) - Respec and tier restrictions
- `config/beta/worldserver.conf` - Add TALENT_MODE setting (optional)

## Testing

1. Create new character, verify no points until level 5
2. Reach level 5, verify 10 points awarded
3. Attempt to spend in tier 4 talent, verify blocked
4. Attempt respec at trainer, verify blocked
5. Level to 8, verify another 10 points
6. Level to 20, verify 60 total points
7. Switch mode to incremental, verify recalculation works
8. Switch back to chunked, verify reset occurs

## Research Needed

- [ ] ALE hook for talent reset attempt
- [ ] ALE hook for talent learn attempt
- [ ] Method to determine talent tier from talentId
- [ ] How to block trainer respec if no hook exists

## Related Issues

- 205: Original talent point implementation
- 141: Talent tier limit (related, may overlap)
- 100: Route to v1.0 (this is a v1.0 requirement)

## Notes

- Server reset is acceptable but not required when switching modes
- Tier 3 limit means ~15 points per tree max (enough for core talents)
- No respec encourages alts and experimentation via new characters
- Chunked grants create "ding moments" that feel more significant
