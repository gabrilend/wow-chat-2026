# 320 - Traveler Sit-With-Player Behavior

## Status
- Created: 2026-04-07
- Implemented: 2026-04-07
- Phase: 2
- Priority: Medium (v1.0 requirement)
- Status: Implemented (needs testing)

## Current Behavior

When a player sits down near a traveler:
- Traveler stops moving (line 206 in travel.lua checks `player:IsStandState()`)
- Traveler remains standing awkwardly
- When player stands, traveler resumes walking

## Intended Behavior

When a player sits down near a traveler:
- Traveler stops moving
- Traveler sits down too (social mirroring)
- Traveler waits patiently while player is seated
- When player stands up, traveler stands and resumes walking

This creates a natural "let's chat" moment where the world respects your conversation.

## Implementation

Modify `Travel.continueTravelling()` in `src/lua/travel.lua`:

```lua
-- Check player stand state and mirror it
if not player:IsStandState() then
    -- Player sitting - sit with them
    if creature:GetStandState() ~= 1 then
        creature:SetStandState(1)  -- UNIT_STAND_STATE_SIT
    end
    -- Don't move, just check again soon
    creature:RegisterEvent(Travel.continueTravelling, 2000, 1)
    return
else
    -- Player standing - ensure we're standing too
    if creature:GetStandState() ~= 0 then
        creature:SetStandState(0)  -- UNIT_STAND_STATE_STAND
    end
    -- Continue with normal movement below
end
```

## Stand State Constants

From WoW API:
- `0` = UNIT_STAND_STATE_STAND
- `1` = UNIT_STAND_STATE_SIT
- `2` = UNIT_STAND_STATE_SIT_CHAIR
- `3` = UNIT_STAND_STATE_SLEEP
- `4` = UNIT_STAND_STATE_SIT_LOW_CHAIR
- `5` = UNIT_STAND_STATE_SIT_MEDIUM_CHAIR
- `6` = UNIT_STAND_STATE_SIT_HIGH_CHAIR
- `7` = UNIT_STAND_STATE_DEAD
- `8` = UNIT_STAND_STATE_KNEEL

## Edge Cases

| Case | Handling |
|------|----------|
| Player logs out while sitting | Traveler has no nearest player, despawns normally |
| Player dies while sitting | Player no longer sitting (dead state), traveler stands and resumes |
| Multiple players nearby | Use nearest player's state (current behavior) |
| Player sits then moves away | Nearest player check will find different player or none |

## Testing

1. Spawn traveler with `#travel`
2. Wait for traveler to walk nearby
3. Sit down (`/sit`)
4. Verify traveler sits down within 2-4 seconds
5. Stand up (`/stand`)
6. Verify traveler stands and resumes walking

## Files to Modify

- `src/lua/travel.lua` - Add sit mirroring in `continueTravelling()`

## Related Issues

- 100: Route to v1.0 (this is a v1.0 requirement)
- 161: Bot wandering (similar sit state checks for bots)

## Notes

- Pure Lua change, no recompile needed
- Hot-reloadable with `.reload ale`
- Simple social behavior that makes the world feel alive
