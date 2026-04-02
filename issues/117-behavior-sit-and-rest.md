# 117 - Behavior: Sit and Rest

## Status: In Progress

## Current Behavior
- Bots have no downtime behavior
- No visible resting when low on resources
- Appears robotic and unnatural

## Intended Behavior
- Bots sit when health/mana is low and out of combat
- Eat food and drink when available
- Stand up when regenerated or threat detected
- Creates natural pacing in gameplay

## Suggested Implementation Steps
1. Create src/lua/behaviors/sit-and-rest.lua
2. Check health/mana thresholds
3. Check for out of combat state
4. Set sit state via SetStandState
5. Attempt to use food/drink from inventory
6. Monitor for combat or full resources
7. Return to standing state when ready

## Configuration
- REST_HEALTH_PCT: threshold to start resting
- REST_MANA_PCT: mana threshold for casters
- STAND_HEALTH_PCT: threshold to resume activity
- STAND_MANA_PCT: mana resume threshold

## Implementation Notes

### 2026-03-31 - Initial Implementation
- Created sit-and-rest.lua with full behavior
- needsRest: checks health/mana against thresholds
- isFullyRecovered: determines when to stand
- findConsumable: searches bags for food/drink
- useConsumable: uses items for faster recovery
- sit/stand: manages stand state
- checkAndRest: main logic with danger awareness (calls AvoidMonsters)
- Integrates with avoid-monsters for flee while resting
- Registers periodic check on bot login

## Related Files
- src/lua/behaviors/sit-and-rest.lua
- src/lua/behaviors/avoid-monsters.lua
- src/lua/movement.lua
- docs/ale/ (for stand state constants)
