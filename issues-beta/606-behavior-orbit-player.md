# 606 - Behavior: Orbit Player

## Status: In Progress

## Current Behavior
- Bots follow player directly or stand still
- No natural social spacing
- Feels unnatural when grouped

## Intended Behavior
- Bots maintain dynamic positions around player
- Orbit creates natural formation
- Distance adjusts based on combat/travel state
- Social opportunities emerge from positioning

## Suggested Implementation Steps
1. Create src/lua/behaviors/orbit-player.lua
2. Use Movement.getOrbitPosition for positioning
3. Calculate orbit slot based on party position
4. Adjust radius based on combat state
5. Smooth position transitions
6. Avoid clumping with other bots

## Configuration
- ORBIT_RADIUS_IDLE: distance when out of combat
- ORBIT_RADIUS_COMBAT: closer during combat
- ORBIT_SPEED: angular movement speed
- REPOSITION_THRESHOLD: distance to trigger movement

## Implementation Notes

### 2026-03-31 - Initial Implementation
- Created orbit-player.lua with full positioning logic
- getLeader: finds party leader or nearest player
- getOrbitSlot: calculates bot's position in formation
- getOrbitAngle: distributes bots evenly around circle
- getOrbitRadius: adjusts radius based on combat/travel state
- calculateTargetPosition: main position calculation with time drift
- avoidClumping: pushes bots apart when too close
- updatePosition: main loop with danger/rest checks
- Integrates with avoid-monsters for flee behavior
- Respects sit-and-rest state (doesn't move resting bots)

## Related Files
- src/lua/behaviors/orbit-player.lua
- src/lua/behaviors/avoid-monsters.lua
- src/lua/behaviors/sit-and-rest.lua
- src/lua/movement.lua (getOrbitPosition already exists)
- docs/playerbots/
