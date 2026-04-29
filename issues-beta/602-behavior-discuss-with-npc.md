# 602 - Behavior: Discuss with NPC

## Status: Open

## Current Behavior
- Playerbots do not interact with wandering NPCs from travel.lua
- No conversation or trade logic exists
- Social opportunities are missed

## Intended Behavior
- When a wandering NPC (from travel.lua) passes nearby, bots may approach
- Bots initiate conversation via gossip system or emotes
- Trade interaction can occur (purchase supplies)
- Creates social atmosphere and emergent gameplay

## Suggested Implementation Steps
1. Create src/lua/behaviors/discuss-with-npc.lua
2. Detect travel.lua NPCs via entry ID or flag
3. Random chance to approach on detection
4. Move to NPC using Movement helpers
5. Trigger interaction (gossip open, emote, or trade)
6. Configure approach distance and interaction chance

## Dependencies
- travel.lua must be functional
- Wandering NPCs must spawn successfully

## Related Files
- src/lua/travel.lua
- src/lua/movement.lua
- docs/playerbots/
