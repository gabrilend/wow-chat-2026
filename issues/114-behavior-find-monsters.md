# 114 - Behavior: Find Monsters

## Status: In Progress

## Current Behavior
- Playerbots have default behavior from mod-playerbots
- No custom targeting logic exists
- Bots may attack inappropriate targets

## Intended Behavior
- Bots scan for nearby hostile creatures periodically
- Target selection considers level appropriateness
- Line of sight checking prevents wasted movement
- Movement toward targets happens before engagement
- Configuration via constants at top of script

## Suggested Implementation Steps
1. Create src/lua/behaviors/find-monsters.lua
2. Implement getNearbyCreatures using GetCreaturesInRange
3. Add isLevelAppropriate check with configurable bounds
4. Implement selectTarget with LoS checking
5. Add moveToTarget and engageTarget functions
6. Register periodic scan on bot login
7. Integrate with avoid-monsters for danger awareness

## Implementation Notes

### 2026-03-31 - Initial Implementation
- Created find-monsters.lua with full implementation
- Configuration: SIGHT_RANGE=500, MAX_LEVEL_DIFF_UP=3, MAX_LEVEL_DIFF_DN=10
- LoS checking limited to 20 creatures per scan for performance
- SCAN_INTERVAL=5000ms, ENGAGE_RANGE=30 yards
- Uses Movement.squaredDistance from movement.lua for efficiency

## Related Files
- src/lua/behaviors/find-monsters.lua
- src/lua/movement.lua
- issues/116-behavior-avoid-monsters.md
