# 116 - Behavior: Avoid Monsters

## Status: In Progress

## Current Behavior
- Bots and wandering NPCs have no danger awareness
- Entities may walk into active combat or hostile creatures
- No threat evaluation exists

## Intended Behavior
- Track nearby hostile creatures and their threat level
- Evaluate danger based on level difference and numbers
- Flee behavior when overwhelmed (health low, outnumbered)
- Called by find-monsters before engagement decisions
- Used by travel.lua wanderers to avoid combat areas

## Suggested Implementation Steps
1. Create src/lua/behaviors/avoid-monsters.lua
2. Implement getDangerLevel scoring system
3. Track nearby combat via GetUnitsInCombatWith or similar
4. Calculate escape vector (opposite direction of threats)
5. Provide shouldFlee(unit) API for other behaviors
6. Integrate with find-monsters targeting decisions
7. Add wanderer avoidance in travel.lua continueTravelling

## Configuration
- DANGER_RADIUS: range to check for threats
- FLEE_HEALTH_PCT: health threshold to trigger flee
- OUTNUMBER_THRESHOLD: enemy count triggering flee
- LEVEL_DANGER_WEIGHT: how much level diff affects danger score

## Implementation Notes

### 2026-03-31 - Initial Implementation
- Created avoid-monsters.lua with full API
- getDangerScore: calculates threat level per creature (level diff, combat, elite/boss)
- getTotalDanger: sums danger from all nearby hostiles
- getEscapeVector: weighted centroid calculation for flee direction
- shouldFlee: decision logic (low health, outnumbered, extreme danger)
- getFleePosition: calculates safe escape coordinates
- flee: executes movement away from danger
- isAreaDangerous: for travel.lua wanderers to check paths
- getSafeDirection: finds angle avoiding danger (used by wanderers)
- Configuration at top with vertical alignment

## Related Files
- src/lua/behaviors/find-monsters.lua
- src/lua/behaviors/avoid-monsters.lua
- src/lua/travel.lua
- src/lua/movement.lua
