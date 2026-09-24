# 712 - Conditional Custom Class Selector Spawn

Only spawn the custom class selector NPC when valid custom classes exist for the
player's base class.

## Current Behavior

The custom class selector NPC spawns for all players regardless of whether any
custom classes are defined. If a player clicks on the NPC but no custom classes
exist for their base class, they see an empty or confusing menu.

## Intended Behavior

The custom class selector NPC should only spawn when:
1. The `custom-class-json/` directory contains at least one valid class definition
2. At least one of those definitions uses the player's base class as its starting point

If no custom classes exist for the player's chosen base class, the NPC simply
doesn't appear. The player continues with their base class as-is.

### Example Scenarios

**Scenario A: Knight custom class exists (base: Warrior)**
- Warrior player → selector NPC spawns, can choose Knight
- Mage player → selector NPC does NOT spawn (no mage-based customs)

**Scenario B: No custom classes defined at all**
- All players → selector NPC never spawns for anyone

**Scenario C: Multiple custom classes exist**
- Knight (Warrior), Spellblade (Mage), Shadow Priest (Priest)
- Warrior → sees Knight option
- Mage → sees Spellblade option
- Priest → sees Shadow Priest option
- Rogue → no NPC (no rogue-based customs)

## Design Considerations

### Check Timing

The check should happen at spawn time, not at gossip time:
- Don't spawn an NPC the player can't use
- Cleaner than spawning then showing "no options available"
- Reduces confusion and wasted interactions

### Directory Scanning

On server startup or NPC spawn request:
1. Scan `custom-class-json/` for `.json` files
2. Parse each file to extract `base_class` field
3. Build a set of base classes that have custom options
4. Cache this set (don't rescan on every spawn)

### Cache Invalidation

The cache should refresh:
- On server restart (always)
- On `.reload ale` command (if feasible)
- Optionally: file watcher for hot-reload during development

### Spawn Location

The selector NPC spawns near the player in the starting zone. If not spawning:
- Simply don't call the spawn function
- No placeholder NPC, no message - just absence

## Suggested Implementation Steps

1. **Add base class extraction to custom class loader**
   - When loading custom class JSON files, extract and store `base_class`
   - Build table: `CustomClasses.baseClassesWithCustoms = { WARRIOR = true, MAGE = true, ... }`

2. **Modify selector NPC spawn logic**
   - Before spawning, check `CustomClasses.hasCustomsForClass(player:GetClass())`
   - If false, return early without spawning
   - If true, proceed with normal spawn

3. **Handle empty directory case**
   - If `custom-class-json/` is empty or missing, `baseClassesWithCustoms` is empty
   - All checks return false, no NPCs spawn for anyone

4. **Test scenarios**
   - No JSON files → no NPC for any class
   - Knight.json (base: Warrior) only → NPC for Warriors, not others
   - Multiple JSON files → appropriate NPCs per base class

## Configuration

```lua
-- Path to custom class definitions
CUSTOM_CLASS_JSON_DIR = "custom-class-json/"

-- Cached set of base classes with custom options
-- Populated on startup/reload
CustomClasses.baseClassesWithCustoms = {}
```

## Related Concepts

- Concept 312: Custom class definition format
- Concept 155: NPC spawning patterns

## Related Files

- src/lua/custom-classes.lua - Selector NPC spawn logic
- custom-class-json/ - Custom class definition directory

## Related Issues

- Issue 705: custom-class-selection-npc (original implementation; legacy number 155)
- Issue 159: knight-custom-class (first custom class)
- Issue 163: custom-class-lua-format (definition format)

## Stats

- **Phase:** 3
- **Priority:** Low (polish, prevents confusion)
- **Complexity:** Low (simple conditional check)
- **Dependencies:** Custom class system (Phase 2)
