# Phase 7 Progress: Character Identity (Custom Classes)

## Effect

Players can create unique classes. Choose any abilities.

## Status: Partial

## Goal

Allow players to define their own classes by selecting abilities from any
base class. Custom class definitions use a Lua format, are validated
automatically, and spawn personalized trainers.

---

## Issues

Ordered by narrative arc: ability sources → custom-class definition
format → selection UI → talent system → custom-class implementations.

### Ability sources (where abilities come from)
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 701 | quest-spells-to-trainers | Implemented | Quest-learned abilities now trainable. Pattern for ability acquisition. |
| 702 | custom-spell-system | Open | New spells beyond base game. Blocks 706. |
| 703 | proc-gem-system | Open | Item-triggered abilities. |
| 715 | linear-ability-scaling | Open | Level-based spell scaling. (Phase 4 prerequisite for tome system.) |

### Custom-class definition format (the data model)
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 709 | custom-class-lua-format | Open | Definition file format. **Keystone.** Blocks 711, 706, 706+. |
| 711 | custom-class-configuration-schema | Open | Validation rules. Depends on 709. |

### Selection UI
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 705 | custom-class-selection-npc | Implemented | Race-specific selector NPCs. |
| 712 | conditional-class-selector-spawn | Open | Only spawn 705 if customs exist. Depends on 709 for detection. |

### Talent system
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 707 | aio-tiered-talent-trainers | Open | Talent training interface. |
| 713 | custom-talent-interface | Open | In-game talent UI (AIO addon). |
| 714 | chunked-talent-points | Open | 10 points at levels 5/8/11/14/17/20. Blocks 707. |
| 708 | talent-tree-analysis-script | Open | Tooling for talent-tree design. |
| 717 | universal-weapon-skills-talent-tradeoff | Open | Every class wields every weapon; talent training 3x slower in exchange. Modifies 714 award cadence. |

### Custom-class implementations (depend on 709)
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 704 | low-level-class-identity | Open | Class feel at early levels. |
| 706 | knight-custom-class | Open | Example custom class. Depends on 709, 702. |
| 710 | custom-class-resource-bars | Open | Custom UI elements (mana, rage, energy, custom). |

## Completed: 0/16 (2 Implemented)

---

## Completion Criteria

- [x] Quest-learned abilities available at trainers instead
- [x] Class selection NPC spawns (race-specific appearances)
- [ ] Custom classes defined in Lua files with rich structure
- [ ] Selector only appears if customs exist for player's base class
- [ ] Custom class abilities trainable from dynamic trainers
- [ ] Talents organized into schools (talent trees)
- [ ] Custom talent interface functional
- [ ] Proc gem system for item-triggered effects
- [ ] Knight example class fully implemented

---

## Key Files

- `src/lua/custom-classes.lua` - Class selection and trainer logic
- `src/custom-class-json/` - Custom class definition files (rename pending)
- `sql/custom/db_world/custom-class-selector-npcs.sql` - NPC definitions
- `sql/custom/db_world/quest-spells-to-trainers.sql` - Trainer ability data

---

## Dependencies

- Phase 1 (foundation) - ALE and AIO must work
- Phase 5 (travelers) - Trainers spawn as travelers

---

## Custom Class Lua Format (163)

### Basic Structure

```lua
knight = {}

-- Metadata
knight.name        = "Knight"
knight.description = "A holy bodyguard who protects allies."
knight.stat_growth = "paladin"  -- Base class restriction

-- Schools = Talent Trees
knight.schools = {}
knight.schools[1] = "Vitality"    -- Healing
knight.schools[2] = "Dedication"  -- Protection
knight.schools[3] = "Valor"       -- Damage

-- Abilities (spell_id → {level, cost, school})
knight.abilities = {}
knight.abilities[57330] = { level = 6, cost = 1000, school = 3 }

-- Talents (spell_id → {max_ranks, tier, tree, requires})
knight.talents = {}
knight.talents[13854] = { max_ranks = 5, tier = 1, tree = 2 }

-- Proficiencies
knight.weapons = { known = {54, 160}, learnable = {200} }
knight.armor   = { known = {8737}, learnable = {750} }
```

### Key Design Decisions

1. **Schools = Talent Trees** - Single definition, dual purpose
2. **stat_growth = base class** - Only Paladins can choose Knight
3. **Explicit ranks** - Each spell rank is separate entry
4. **Talent prerequisites** - `requires` must be MAXED to unlock

---

## Class Selection Flow

1. Player creates character with base class (e.g., Paladin)
2. At level 1, selector NPC appears (race-appropriate model)
3. Selector shows custom classes available for base class
4. Player picks custom class or keeps base class
5. Dynamic trainer spawns with custom abilities
6. Player trains abilities as they level

### Race-Specific Selectors (155)

| Entry | Race | Name |
|-------|------|------|
| 900001 | Human | Mysterious Guide |
| 900002 | Orc | Spirit Walker |
| 900003 | Dwarf | Ironforge Sage |
| 900004 | Night Elf | Dreamweaver |
| 900005 | Undead | Dark Advisor |
| 900006 | Tauren | Earthmother's Voice |
| 900007 | Gnome | Mechanical Oracle |
| 900008 | Troll | Loa Speaker |
| 900010 | Blood Elf | Sin'dorei Mystic |
| 900011 | Draenei | Naaru Touched |

---

## rmail Integration (Reference)

Custom classes can be submitted externally via rmail, allowing players to
design classes outside the game and have them validated automatically.
See **Phase 10** for the full rmail treatment with design philosophy.

### Service Details

| Service | Port | Address |
|---------|------|---------|
| Custom Classes | 4662 | `wow.ritzmenardi.com/classes` |

### Submission Flow

Players submit custom class definitions via rmail:

```
to: wow.ritzmenardi.com/classes
subject: CLASS: knight

knight = {}
knight.name        = "Knight"
knight.description = "A holy bodyguard"
knight.stat_growth = "paladin"

knight.schools = {}
knight.schools[1] = "Vitality"
-- ... rest of class definition
```

### Server Processing

1. rmail `on_receive` hook parses the message
2. Lua parser validates the class definition (sandboxed, no execution)
3. Validation checks:
   - All spell IDs exist in spell.dbc
   - Talent prerequisites are valid
   - Base class restriction is valid
   - No duplicate entries
4. Response sent: `ACCEPTED: knight` or `REJECTED: knight` with errors
5. Valid classes loaded on next server restart (or hot-reload)

### Why rmail for Classes?

```
THOUGHT: Design happens outside the game.

Building a custom class is creative work. Spreadsheets, notes,
planning. The WoW client isn't a good editor for this.

rmail lets you design in your preferred environment:
- Text editor with syntax highlighting
- Version control for iterations
- Share drafts with friends for feedback
- Submit when ready

The game validates. The game loads. But the design happens elsewhere.
```

For the full WHY behind rmail, see Phase 10's "Thoughts" sections.

---

## Notes

### Quest Spells to Trainers (140)

Problem: Some abilities only obtainable via quests.
Solution: Add these abilities to class trainers.

Affected classes:
- Warrior: Defensive Stance, Berserker Stance
- Paladin: Redemption, Sense Undead
- Hunter: Tame Beast
- Rogue: Poisons
- Shaman: Totems
- Warlock: Summons
- Druid: Forms

### Conditional Selector Spawn (304)

Selector NPC should NOT spawn if:
- No custom classes exist for player's base class
- `custom-class-json/` directory is empty

Implementation: Scan directory on server start, cache which base classes
have customs. Check cache before spawning selector.

### Custom Talent Interface (345)

AIO addon for talent selection:
- Three trees (schools) side by side
- Click to spend points
- Visual prerequisite lines
- Integration with chunked talent system (Phase 8)

---

## Related Phases

- **Phase 5** - Dynamic trainers spawn as travelers
- **Phase 8** - Chunked talent points, tier limits
- **Phase 10** - rmail infrastructure (class submission uses port 4662)
