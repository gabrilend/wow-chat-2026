# 715 - Linear Ability Scaling

## Status: Open

## Phase: 3 (Prerequisite for seamless tome system)

## Current Behavior

WoW abilities use a rank system with discrete power jumps:
- Rejuvenation R1 (level 8): 32 HP over 12 sec, 25 mana
- Rejuvenation R2 (level 14): 56 HP over 12 sec, 65 mana
- Rejuvenation R3 (level 20): 116 HP over 12 sec, 105 mana

Problems:
1. Power spikes at rank-up levels create jarring difficulty transitions
2. Learning a spell "early" via tome gives you an underpowered version
3. Learning a spell "late" gives you an overpowered version
4. Custom classes must carefully balance which ranks to include at which levels
5. The tome system (issue 405) is complicated by rank management

## Intended Behavior

### Linear Scaling Formula

Every ability has 80 versions (levels 1-80), each balanced for that exact level:
- Rejuvenation (level 5): scaled for level 5 encounters
- Rejuvenation (level 12): scaled for level 12 encounters
- Rejuvenation (level 47): scaled for level 47 encounters

The scaling formula for each stat:
```
value_at_level = base_value + (max_value - base_value) * ((level - 1) / 79)
```

Where:
- `base_value` = the stat at level 1
- `max_value` = the stat at level 80
- Linear interpolation between them

### Example: Rejuvenation

| Level | Healing Total | Mana Cost | Spell ID |
|-------|---------------|-----------|----------|
| 1     | 20            | 15        | 9000001  |
| 5     | 40            | 30        | 9000005  |
| 10    | 65            | 50        | 9000010  |
| 15    | 95            | 70        | 9000015  |
| 20    | 125           | 90        | 9000020  |
| ...   | ...           | ...       | ...      |
| 80    | 500           | 350       | 9000080  |

### Spell ID Allocation

Reserve a contiguous block of spell IDs for scaled versions:
```
Base spell ID range: 9,000,000 - 9,999,999 (1 million IDs)

Formula: scaled_spell_id = BASE_OFFSET + (spell_family_index * 100) + level

Example for spell family "rejuvenation" (index 0):
  Level 1:  9000001
  Level 80: 9000080

Example for spell family "renew" (index 1):
  Level 1:  9000101
  Level 80: 9000180

Example for spell family "holy_light" (index 2):
  Level 1:  9000201
  Level 80: 9000280
```

This allows ~10,000 spell families with 100 levels each.

### Custom Class Integration

Custom class definitions reference spell families, not specific spell IDs:
```lua
-- Old format (issue 163):
knight.abilities[139]  = { level = 8,  cost = 1500, school = 1 }  -- Renew R1
knight.abilities[6074] = { level = 14, cost = 2500, school = 1 }  -- Renew R2

-- New format with linear scaling:
knight.abilities["renew"] = {
    unlock_level = 8,   -- First available at level 8
    cost = 1500,        -- Training cost (copper)
    school = 1          -- Spellbook category
}
-- Player at level 8 learns "Renew (Level 8)" - spell ID 9000108
-- Player at level 12 learns "Renew (Level 12)" - spell ID 9000112
-- (if they didn't have it before)
```

### Tome System Integration

With linear scaling, the tome system becomes trivially simple:
1. Inscriptionist creates "Tome of Renew" (family-based, not rank-based)
2. Tome sold to vendor → enters "renew" pool
3. Player opens chest → tome appears if "renew" in their class
4. Player uses tome → learns Renew at THEIR CURRENT LEVEL
5. No rank checking, no level validation against spell requirements
6. The spell they learn is always balanced for their level

### Base Class Equivalence

Eventually, base classes (Warrior, Paladin, etc.) will use the same format as custom classes:
```lua
-- src/custom-classes/warrior.lua
warrior = {}
warrior.name = "Warrior"
warrior.description = "A mighty melee combatant."
warrior.stat_growth = "warrior"

warrior.abilities = {}
warrior.abilities["heroic_strike"] = { unlock_level = 1, cost = 0, school = 1 }
warrior.abilities["charge"]        = { unlock_level = 4, cost = 500, school = 1 }
warrior.abilities["rend"]          = { unlock_level = 4, cost = 500, school = 1 }
-- etc
```

This means:
- No special-casing for "real" classes vs custom classes
- All classes use the same progression system
- All classes benefit from linear scaling
- Tome pools are unified (a Warrior's Heroic Strike tome can go to custom class that has it)

## Implementation Steps

### Phase A: Spell Data Generation

1. Enumerate all learnable player abilities in WoW 3.3.5a
   - Extract from Spell.dbc using existing tools
   - Filter to player-usable abilities (not NPC-only, not items)
   - Group by spell family (all ranks of same spell)

2. Define scaling parameters for each spell family
   - Base values (level 1 equivalent)
   - Max values (level 80 equivalent)
   - Which fields to scale (damage, healing, mana cost, duration, etc.)

3. Generate 80 versions of each spell
   - Use Spell.dbc as template
   - Calculate scaled values using linear formula
   - Assign sequential spell IDs from reserved range

4. Output to DBC files
   - Spell.dbc - spell definitions
   - SpellEffect.dbc - damage/healing values
   - SpellCastTimes.dbc - cast times (may not need scaling)
   - SpellPower.dbc - mana/rage/energy costs

### Phase B: Spell Family Mapping

5. Create spell family registry
   - Maps family names to spell ID ranges
   - Maps original spell IDs to families (for backwards compat)
   - Lua table + SQL table for runtime lookup

6. Update custom class format (issue 163)
   - Change from spell_id keys to family keys
   - Add unlock_level field
   - Update parser and validator

### Phase C: Runtime Integration

7. Update spell learning logic
   - When player should learn spell, calculate level-appropriate spell ID
   - Use formula: `BASE_OFFSET + (family_index * 100) + player_level`
   - Replace any lower-level versions in spellbook

8. Update tome system (issue 405)
   - Simplify to family-based pools
   - Remove rank tracking entirely
   - Tome use = learn spell at current level

9. Handle level-up spell upgrades
   - On level up, scan player's abilities
   - For each ability, check if new level version exists
   - Auto-learn new version, remove old version
   - Player always has level-appropriate spells

### Phase D: Testing and Balancing

10. Create test characters at various levels
    - Verify spell power feels appropriate for level
    - Check mana costs are sustainable
    - Ensure no broken interactions

11. Balance pass
    - Adjust base/max values as needed
    - Test in actual gameplay scenarios
    - Get player feedback

## Technical Considerations

### DBC Editing

Requires DBC editing tools:
- MPQ extraction (if not already done)
- DBC editing library (Python, C++, or similar)
- MPQ repacking for client distribution

**Client-side requirement**: Players need updated DBC files to see spell tooltips.
Server can teach the spells regardless, but tooltips will be wrong without client patch.

Options:
1. Custom MPQ patch distributed to players
2. Use addon to override tooltip display (limited)
3. Accept broken tooltips (not ideal)

### Spell ID Range

The 9,000,000+ range should be safe:
- WoW 3.3.5a highest spell ID is around 80,000
- Custom module spells typically use 100,000-999,999
- 9,000,000+ is well clear of conflicts

### Performance

80 versions × 1000 spells = 80,000 new spell records
- DBC files will be larger
- Server memory usage increases slightly
- Spell lookup should remain O(1) with ID indexing

### Backwards Compatibility

Old spell IDs (139, 6074, etc.) should still work:
- NPCs that cast original spells unaffected
- Items that teach original spells unaffected
- Only player learning is redirected to scaled versions

## Scaling Parameters

### What to Scale

| Field | Scale? | Notes |
|-------|--------|-------|
| Base damage | Yes | Linear with level |
| Bonus damage | Yes | Linear with level |
| Healing | Yes | Linear with level |
| Mana cost | Yes | Linear with level, proportional to player mana pool |
| Duration | Maybe | Some spells, not all |
| Cooldown | No | Usually fixed |
| Range | No | Usually fixed |
| Cast time | No | Usually fixed |

### Scaling Reference Points

Use level 80 max-rank versions as the "max" reference:
- Rejuvenation R15 (level 80): healing = 1690, mana = 586
- Use this as max_value for healing and mana
- Calculate base_value as max_value / some_factor (e.g., 25x)

Alternative: Use empirical data from leveling experience
- What feels right at level 10?
- What feels right at level 40?
- Fit linear curve to those points

## Future Expansion

### Level 80+ Support

By scaling to 80, we leave room for expansion:
- If cap increases to 85, add spell IDs 81-85 to each family
- Linear formula still works: `(level - 1) / (max_level - 1)`
- Just need to regenerate DBCs with new max

### Non-Linear Scaling

Linear scaling is simple but may not feel right:
- Early levels might feel weak
- Late levels might feel overpowered

Future options:
- Exponential curve
- Piecewise linear (different slopes per bracket)
- Hand-tuned values per level

For v1, linear is good enough. Can refine later.

## Related Issues

- 151 - Ability tome system (simplified by linear scaling)
- 163 - Custom class Lua format (updated to use spell families)
- 142 - Custom spell system (may overlap, merge considerations)

## Files to Create

- `scripts/generate-scaled-spells.lua` - Spell generation script
- `data/spell-families.lua` - Family → spell ID mapping
- `data/scaling-parameters.lua` - Base/max values per family
- `data/dbc/Spell_scaled.dbc` - Generated spell records
- `docs/linear-scaling.md` - Design documentation

## Notes

This is a significant undertaking but provides massive simplification:
- Eliminates rank system complexity
- Makes tome system trivial
- Unifies base/custom class handling
- Creates smooth progression curve
- Enables "learn any spell at any level" design

The DBC editing requirement is the main hurdle. Once that tooling exists,
generating 80k spell records is straightforward scripting.
