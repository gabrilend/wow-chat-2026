# 118 - Behavior: Travel to Unique Lands

## Status: Open

## Current Behavior
- Bots stay in their immediate area
- No exploration or cross-zone travel
- World feels static

## Intended Behavior
- Bots occasionally travel to nearby zones
- Exploration based on level-appropriate areas
- Creates dynamic population across the world
- May discover new hunting grounds or resources

## Suggested Implementation Steps
1. Create src/lua/behaviors/travel-to-unique-lands.lua
2. Define zone destination data per level range
3. Select random appropriate destination
4. Plan path using waypoint data (from issue 110)
5. Execute long-distance travel over time
6. Handle zone transitions and instance portals
7. Return home behavior or continue wandering

## Configuration
- TRAVEL_CHANCE: chance per interval to initiate travel
- TRAVEL_INTERVAL: how often to check for travel
- RETURN_HOME_CHANCE: chance to return vs continue exploring

## Dependencies
- Issue 110: Random spawn point feature (waypoint data)
- Movement system must handle long distances

## Related Files
- src/lua/movement.lua
- assets/waypoint_data (from smart_scripts backup)
