# 125 - Player Bot Behavior Commands

## Status: Open

## Current Behavior
- Players control their character manually
- Playerbot behaviors only apply to AI companions
- No way for players to "automate" their own actions

## Intended Behavior
- Chat commands trigger bot-like behaviors on the player's own character
- Player can go "hands off" and let behaviors drive
- Useful for AFK farming, following friends, or just watching

## Why This Feature?
- Sometimes you want to watch your character play itself
- Creates emergent "idle game" moments
- Testing behaviors without spawning bots
- Accessibility: reduce repetitive inputs
- Fun: see what your character does on its own

## Suggested Commands

### Combat Behaviors
| Command | Behavior |
|---------|----------|
| `#hunt` | Enable find-monsters behavior - seek and attack |
| `#flee` | Enable avoid-monsters behavior - run from danger |
| `#stop` | Disable all active behaviors |

### Movement Behaviors
| Command | Behavior |
|---------|----------|
| `#orbit <player>` | Orbit around target player |
| `#follow <player>` | Follow target player |
| `#wander` | Wander randomly like travel NPCs |
| `#home` | Return to bind point |

### Utility Behaviors
| Command | Behavior |
|---------|----------|
| `#rest` | Enable sit-and-rest behavior |
| `#auto` | Enable all behaviors (full autopilot) |
| `#status` | Show which behaviors are active |

## Implementation Steps
1. Create src/lua/player-commands.lua
2. Register PLAYER_EVENT_ON_CHAT handler
3. Parse commands starting with #
4. Toggle behavior flags in player data
5. Behaviors check flags before acting on bots vs players
6. Add IsBot() OR HasBehaviorEnabled() checks

## Behavior Integration

Current behaviors check `player:IsBot()` before acting. Change to:
```lua
function shouldApplyBehavior(unit, behaviorName)
    if unit:IsBot() then return true end

    -- player opted in via chat command
    local enabled = unit:GetData("behavior-" .. behaviorName)
    return enabled == true
end
```

## Safety Considerations
- Player can always override with manual input
- Manual movement cancels wander/orbit
- Combat input cancels hunt/flee
- `#stop` always works immediately
- Behaviors pause in dungeons/raids (configurable)

## Future Enhancements
- Behavior presets (`#preset grind`, `#preset explore`)
- Time limits (`#hunt 10m` - hunt for 10 minutes)
- Conditional triggers (`#hunt when full health`)
- Macro integration

## Related Files
- src/lua/behaviors/*.lua
- src/lua/travel.lua (wander behavior reference)
- docs/playerbots/Playerbot-Commands.md (command style reference)
