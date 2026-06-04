# Phase 3: Custom Spell System

## Vision

Migrate all player abilities from WoW's hardcoded spell system to a server-controlled
AIO-based system. This decouples gameplay from Blizzard's client, enabling:

- True custom abilities without DBC modification
- Easier path to custom MMO development on AzerothCore
- Full control over spell behavior, visuals, and balance
- No licensing concerns from modified client data

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          SERVER (Lua/C++)                           │
├─────────────────────────────────────────────────────────────────────┤
│  Spell Definitions     │  Cast State Machine   │  Effect Handlers   │
│  - Cost (mana/runes)   │  - Validate start     │  - Damage/Heal     │
│  - Cast time           │  - Track duration     │  - Apply aura      │
│  - Cooldown            │  - Handle interrupt   │  - Spawn creature  │
│  - Range/targeting     │  - Pushback calc      │  - Visual effect   │
│  - Requirements        │  - Cancel on move     │  - Projectile sim  │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   │ AIO Messages
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          CLIENT (AIO Addon)                         │
├─────────────────────────────────────────────────────────────────────┤
│  Action Buttons        │  Cast Bar             │  Cooldown Display  │
│  - Custom icons        │  - Progress bar       │  - Spiral overlay  │
│  - Custom tooltips     │  - Spell name         │  - Time remaining  │
│  - Click → server      │  - Interrupt on move  │  - GCD tracking    │
│  - State (usable/not)  │  - Interrupt on ESC   │                    │
└─────────────────────────────────────────────────────────────────────┘
```

## Server Components

### Spell Definition Table (Lua)
```lua
CustomSpells = {
    ["frost_bolt"] = {
        name           = "Frost Bolt",
        icon           = "Interface\\Icons\\Spell_Frost_FrostBolt02",
        castTime       = 2.5,
        cooldown       = 0,
        cost           = { mana = 50 },
        range          = 30,
        school         = "frost",
        interruptible  = true,
        movementCancel = true,
        animation      = "SPELL_CAST_DIRECTED",
        onCast         = function(caster, target)
            -- damage calculation, projectile spawn, etc.
        end,
    },
}
```

### Cast State Machine
```
IDLE → CASTING → CAST_COMPLETE → IDLE
         │
         ├── INTERRUPTED (damage pushback, silence)
         ├── CANCELLED (movement, ESC, manual)
         └── FAILED (out of range, LoS, dead target)
```

### Effect System
- Direct damage/healing with school and coefficient
- Aura application (buffs, debuffs, DoTs, HoTs)
- Creature/object spawning (pets, totems, projectiles)
- Forced animations via HandleEmoteCommand
- Sound playback via PlayDirectSound

## Client Components (AIO)

### Custom Action Bar
- Replaces or supplements default action bars
- Each button tied to a custom spell ID
- Shows icon, tooltip, cooldown, usability state
- Sends cast request to server on click

### Cast Bar Frame
- Custom progress bar (not the default cast bar)
- Server sends: spell name, duration, interruptible flag
- Client updates progress, handles local cancel detection
- Movement detection: polls player position, cancels on change
- ESC detection: key hook sends cancel to server

### Cooldown Display
- Spiral cooldown overlay on buttons
- Server sends cooldown duration on cast complete
- Client tracks remaining time locally

## Solvable Problems

### Projectiles
- Spawn invisible creature at caster
- Move creature toward target using MoveTo
- On arrival (distance check), trigger impact effect
- Server spawns visual effect creature at impact point

### Pushback
- Server tracks incoming damage during cast
- Each hit adds pushback time (configurable formula)
- Server sends updated cast duration to client
- Client adjusts progress bar accordingly

### Interrupts
- Server applies "silenced" state on interrupt
- Client greys out affected spell schools
- Lockout duration tracked server-side

### Nameplate Cast Bars
- AIO can modify nameplate frames
- Show custom cast bar on player's nameplate
- Other players see it via AIO sync

### Global Cooldown
- Server enforces GCD on all custom spells
- Client shows GCD sweep on all buttons
- 1.5 second base, haste-modified

## Migration Strategy

### Phase 3a: Infrastructure
- Build core spell definition system
- Build cast state machine
- Build AIO action bar and cast bar
- Test with one simple spell (e.g., "Meditate")

### Phase 3b: Utility Spells
- Migrate non-combat spells first
- Hearthstone, mounts, professions
- Low risk, validates system

### Phase 3c: Basic Combat
- Migrate instant-cast damage/heal spells
- No cast time = no cast bar needed
- Test damage calculation, threat, combat log

### Phase 3d: Cast Time Spells
- Migrate spells with cast times
- Full cast bar implementation
- Movement cancellation, interrupt handling

### Phase 3e: Channeled Spells
- Spells that tick over duration
- Different state machine (CHANNELING state)
- Partial effect on early cancel

### Phase 3f: Projectiles
- Implement projectile simulation
- Visual creature spawning
- Impact detection and effects

### Phase 3g: Complete Migration
- All class abilities migrated
- Remove dependency on Spell.dbc for gameplay
- Client spell data only used for animations/sounds

## Benefits

1. **Full Control**: Every aspect of spells is configurable
2. **Hot Reload**: Change spell behavior without restart
3. **Custom Content**: Create abilities that don't exist in WoW
4. **Balance Tuning**: Adjust numbers in Lua, not DBC
5. **Licensing Clean**: No modified Blizzard data files
6. **Future Proof**: Foundation for non-WoW custom MMO

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Performance (many AIO messages) | Batch updates, delta compression |
| Desync (client/server state) | Server authoritative, client corrects |
| Feel (doesn't feel like WoW) | Careful animation/timing tuning |
| Complexity (maintaining two systems) | Migrate fully, don't half-commit |

## Related Concepts

- 801-808: AIO Framework concepts
- 901-908: Performance and optimization
- 601-608: Visual and aesthetic guidelines

## Related Issues

- 142-custom-spell-system (implementation tracker)
- 141-talent-tier-limit (affects spell availability)
- 140-quest-spells-to-trainers (current system, will be migrated)
